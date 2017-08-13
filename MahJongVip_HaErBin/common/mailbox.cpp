/*----------------------------------------------------------------
// 模块名：mailbox
// 模块描述：对服务器的发送缓冲区的封装： mailbox
//----------------------------------------------------------------*/
#include "mailbox.h"
#include "util.h"
#include "epoll_server.h"
#include "memory_pool.h"
#include "world_select.h"
#include "cjson.h"
#include "net_util.h"


MemoryPool* CMailBox::memPool = NULL;
MyLock CMailBox::m_lock;

void CMailBox::ClearData()
{
    if(m_curReceivePluto)
    {
        delete m_curReceivePluto;
        m_curReceivePluto = NULL;
    }

    ClearContainer(m_tobeSend);
#ifdef __WEBSOCKET_CLIENT
    ClearContainer(m_wsRecvPlutoList);
#endif
}

CMailBox::CMailBox(uint32_t uid, EFDTYPE fdtype, const char* pszAddr, uint16_t unPort)
    : m_bConnected(false), m_fd(0), m_fdType(fdtype), m_connectdTime(), m_bFirstConnect(true), m_lastPackTime(),
      m_ip(pszAddr), m_serverPort(unPort), m_id(uid), m_curReceivePluto(NULL),
      m_unServerMbType(SERVER_NONE), m_uAuthz(MAILBOX_CLIENT_UNAUTHZ), m_nSendPos(0), m_bDeleteFlag(false)
#ifdef __WEBSOCKET_CLIENT
      ,m_isFirstPluto(true), m_isWebsocket(false), m_wsRecvLen(0)
#endif
{
    
}

CMailBox::~CMailBox()
{
    ClearData();
}

void * CMailBox::operator new(size_t size)
{
    //判断请求的size是否与对象size相等
    if(size != sizeof(CMailBox))
    {
        LogWarning("CMailBox new", "size != sizeof(CMailBox)");
        return ::operator new(size);
    }

    m_lock.Lock();

    if (NULL == memPool)
    {
        expandMemoryPool();
    }

    MemoryPool *head = memPool;
    memPool = head->next;

    m_lock.Unlock();

    //LogDebug("CMailBox new", "");

    return head;
}

void CMailBox::operator delete(void* p, size_t size)
{
    //判断要释放的空间是否合法
    if(NULL == p)
    {
        return;
    }

    //判断请求的size是否与对象size相等
    if(size != sizeof(CMailBox))
    {
        LogWarning("CMailBox delete", "size != sizeof(CMailBox)");

        ::operator delete(p);
        return;
    }

    m_lock.Lock();

    MemoryPool *head = (MemoryPool *)p;
    head->next = memPool;
    memPool = head;

    m_lock.Unlock();

    //LogDebug("CMailBox delete", "");
}

void CMailBox::expandMemoryPool()
{
    size_t size = (sizeof(CMailBox) > sizeof(MemoryPool *)) ? sizeof(CMailBox) : sizeof(MemoryPool *);

    MemoryPool *runner = (MemoryPool *) new char[size];
    memPool = runner;

    // 分配足够的数量
    for (int i=0; i<MAX_FILE_HANDLE_COUNT; i++)
    {
        runner->next = (MemoryPool *) new char[size];
        runner = runner->next;
    }

    runner->next = NULL;
}

//根据配置初始化
bool CMailBox::init(const MailBoxConfig& cfg)
{
    return true;
}

int CMailBox::ConnectServer(int epfd)
{
    // 调用这个函数，说明连接没有了。
    SetConnected(false);
    // 清理脏数据，防止下次接收出错
    ClearData();

    if (!m_bFirstConnect && (m_connectdTime.GetPassMsTick() < 5 * 1000))
    {
        return -1;
    }

    if(m_fd > 0)
    {
        epoll_ctl(epfd, EPOLL_CTL_DEL, m_fd, NULL);
        ::close(m_fd);
    }

    m_fd = MogoSocket();
    if(m_fd <= 0)
    {
        ERROR_RETURN2("ConnectServer MogoSocket Failed");
    }
    MogoSetNonblocking(m_fd);

    //修改rcvbuf和sndbuf
    enum{ _BUFF_SIZE = 174760 };
    MogoSetBuffSize(m_fd, _BUFF_SIZE, _BUFF_SIZE);

    struct epoll_event ev;
    memset(&ev, 0, sizeof ev);
    ev.events = EPOLLIN | EPOLLOUT | EPOLLET;
    ev.data.fd = m_fd;

    if(epoll_ctl(epfd, EPOLL_CTL_ADD, m_fd, &ev) == -1)
    {
        ERROR_RETURN2("ConnectServer Failed to epoll_ctl_add connect fd");
    }

    int nRet = MogoConnect(m_fd, GetIp().c_str(), GetServerPort());
    if(nRet != 0 && errno != EINPROGRESS)
    {
        ERROR_RETURN2("ConnectServer Failed to connect");
    }

    m_bFirstConnect = false;
    m_connectdTime.SetNowTime();
    return 0;
}

char* CMailBox::GetClientIP()
{
	struct sockaddr_in client_addr;
	socklen_t addr_len = sizeof(client_addr);
	if (getpeername(m_fd, (struct sockaddr *)&client_addr, &addr_len) == 0)
	{
		char *clientAddr = inet_ntoa(client_addr.sin_addr);
		return clientAddr;
	}
	return NULL;
}

int CMailBox::SendAll()
{
    if(IsConnected())
    {
        if(IsConnected())
        {
            while(!m_tobeSend.empty())
            {
                CPluto* u = m_tobeSend.front();
                int nSendWant = (int)u->GetLen()-m_nSendPos;        //期待发送的字节数
                int nSendRet = ::send(m_fd, u->GetBuff()+m_nSendPos, nSendWant, 0);
                //PrintHexPluto(*u);
                if(nSendRet != nSendWant)
                {
					uint32_t mbid = GetMailboxId();

                    //error handle
                    LogWarning("CMailBox::sendAll error", "mb=%d;%d_%d,%d;%s", mbid, u->GetLen(), nSendRet, 
                        errno, strerror(errno));

                    if(mbid == 0 && GetAuthz() != MAILBOX_CLIENT_TRUSTED)
                    {
                        //客户端连接不重发了,直接关掉
                        return -1;
                    }

                    if(nSendRet >= 0)
                    {
                        //阻塞了,留到下次继续发送                        
                        m_nSendPos += nSendRet;
                        return 0;
                    }
                    else
                    {
                        if(errno == EINPROGRESS || errno == EAGAIN )
                        {
                            //阻塞了,留到下次继续发送                        
                            return 0;
                        }
                    }

                    //判断,如果是客户端则关闭,如果是其他服务器,通知管理器退出
                    //保留消息包,等待重发
                    //何时选择退出? //todo
                    return -1;
                }

                m_tobeSend.pop_front();
                delete u;
                m_nSendPos = 0;
            }

        }
    }

    return 0;
}

void CMailBox::PushPluto(CPluto* u)
{
    CPluto* up = u;

#ifdef __WEBSOCKET_CLIENT
    if (m_isWebsocket)
    {
        // CLOSE是关闭fd之前发送的, 走不到这里
        switch(u->GetWsOpCode())
        {
            case WS_OPCODE_GET:
            {
                // 不需要处理 GET直接发送文本就可以
                break;
            }
            case WS_OPCODE_PONG:
            {
                up = new CPluto(0xA, u->GetBuff(), u->GetLen());
                delete u;

                break;
            }
            default:
            {
                //普通数据包，需要转换成websocket模式
                cJSON* pJs = cJSON_CreateObject();

                if (!GetWorld()->GetRpcUtil().RpcDecodePlutoToJson(pJs, *u) || u->GetDecodeErrIdx() > 0)
                {
                    LogError("CMailBox::PushPluto", "RpcDecodePlutoToJson error msgId=%d", u->GetMsgId());

                    cJSON_Delete(pJs);
                    delete u;

                    GetWorld()->GetServer()->CloseFdFromServer(GetFd());
                    
                    return;
                }
                else
                {
                    char* pJsStr = cJSON_PrintUnformatted(pJs);
                    up = new CPluto(0x1, pJsStr, strlen(pJsStr));

                    //LogInfo("PushPluto:", pJsStr);

                    cJSON_free(pJsStr);
                    cJSON_Delete(pJs);
                    delete u;
                }
            }
        }
    }
#endif

    m_tobeSend.push_back(up);
}

#ifdef __WEBSOCKET_CLIENT
bool CMailBox::PushRecvWsPluto(CPluto* u)
{
    CEpollServer* eps = GetWorld()->GetServer();

    switch(u->GetWsOpCode())
    {
        case WS_OPCODE_DATA_END:
        {
            m_wsRecvLen += u->GetLen();
            if (m_wsRecvLen > PLUTO_CLIENT_MSGLEN_MAX)
                return false;
            m_wsRecvPlutoList.push_back(u);

            // 1个完整包完成，进行合并处理
            CMailBox* mb = NULL;
            CPluto* unew = new CPluto(m_wsRecvLen);
            int pos = 0;
            list<CPluto*>::iterator iter = m_wsRecvPlutoList.begin();
            for(; iter != m_wsRecvPlutoList.end(); ++iter)
            {
                CPluto* p = *iter;
                memcpy(unew->GetRecvBuff() + pos, p->GetRecvBuff(), p->GetLen());
                pos += p->GetLen();

                if (NULL == mb)
                    mb = p->GetMailbox();
            }
            unew->SetWsOpCode(WS_OPCODE_DATA);
            unew->SetLen(m_wsRecvLen);
            unew->SetMailbox(mb);
            unew->SetSrcFd(u->GetSrcFd());
            eps->AddRecvMsg(unew);

            ClearContainer(m_wsRecvPlutoList);
            m_wsRecvLen = 0;
            return true;
        }
        case WS_OPCODE_CLOSE:
        case WS_OPCODE_PING:
        case WS_OPCODE_GET:
        {
            //单帧在外面判断长度
            eps->AddRecvMsg(u);
            return true;
        }
        case WS_OPCODE_DATA:
        {
            // 第1个帧，说明分片处理了，条件是原来的片已经结束了
            if (m_wsRecvLen != 0)
                return false;
            if (m_wsRecvPlutoList.size() != 0)
                return false;

            m_wsRecvLen += u->GetLen();
            if (m_wsRecvLen > PLUTO_CLIENT_MSGLEN_MAX)
                return false;
            m_wsRecvPlutoList.push_back(u);

            return true;
        }
        case WS_OPCODE_DATA_NEXT:
        {
            m_wsRecvLen += u->GetLen();
            if (m_wsRecvLen > PLUTO_CLIENT_MSGLEN_MAX)
                return false;
            m_wsRecvPlutoList.push_back(u);

            return true;
        }
    }

    return false;
}
#endif
///////////////////////////////////////////////////////////////////////////////



