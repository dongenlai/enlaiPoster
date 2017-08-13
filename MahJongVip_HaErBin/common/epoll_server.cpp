/*----------------------------------------------------------------
// 模块名：epoll_server
// 模块描述：epoll 相关。
//----------------------------------------------------------------*/

#include "epoll_server.h"
#include "net_util.h"
#include "util.h"
#include "world.h"

CEpollServer::CEpollServer() : m_epfd(0), m_fds(), the_world(NULL), \
    m_unMailboxId(0), m_bShutdown(false), m_unMaxPlutoCount(0)
{

}

CEpollServer::~CEpollServer()
{
    ClearMap(m_fds);
    ClearContainer(m_mb4del);
    ClearContainer(m_recvMsgs);
    m_mb4reconn.clear();
    ClearMap(m_serverMbs);
}

int CEpollServer::StartServer(const char* pszAddr, uint16_t unPort)
{
    m_strAddr.assign(pszAddr);
    m_unPort = unPort;

    int fd = MogoSocket();
    if(fd <= 0)
    {
        ERROR_RETURN2("Failed to create socket");
    }

    MogoSetNonblocking(fd);

    //修改rcvbuf和sndbuf
    enum{ _BUFF_SIZE = 174760 };
    MogoSetBuffSize(fd, _BUFF_SIZE, _BUFF_SIZE);

    int n = MogoBind(fd, pszAddr, unPort);
    if(n != 0)
    {
        printf("bind fail, fd=%d;pszAddr=%s;unPort=%d\n", fd, pszAddr, unPort);
        ERROR_RETURN2("Failed to bind");
    }

    n = MogoListen(fd, 20);
    if(n != 0)
    {
        ERROR_RETURN2("Failed to listen");
    }

    m_epfd = epoll_create(MAX_EPOLL_SIZE);
    if(m_epfd == -1)
    {
        ERROR_RETURN2("Failed to epoll_create");
    }

    struct epoll_event ev;
    memset(&ev, 0, sizeof ev);
    ev.events = EPOLLIN | EPOLLOUT;
    ev.data.fd = fd;

    if(epoll_ctl(m_epfd, EPOLL_CTL_ADD, fd, &ev) == -1)
    {
        ERROR_RETURN2("Failed to epoll_ctl_add listen fd");
    }

    AddFdAndMb(fd, FD_TYPE_SERVER, pszAddr, unPort);

    LogDebug("start_server", "%s:%d,success.", m_strAddr.c_str(), m_unPort);
    return 0;
}

int CEpollServer::ConnectMailboxs(const char* pszCfgFile)
{
    list<CMailBox*>& mbs = GetWorld()->GetMbMgr().GetMailboxs();

    list<CMailBox*>::iterator iter = mbs.begin();
    for(; iter != mbs.end(); ++iter)
    {
        CMailBox* pmb = *iter;
		uint32_t tmpId = pmb->GetMailboxId();
        if(m_unMailboxId == tmpId)
        {
            // 这里把监听ip改成外网ip，为了上报给AreaMgr
            m_strAddr = pmb->GetIp();
        }
        else
        {
            m_serverMbs.insert(make_pair(tmpId, pmb));

            int nRet = pmb->ConnectServer(m_epfd);
            if(nRet != 0)
            {
                return nRet;
            }

            AddFdAndMb(pmb->GetFd(), pmb);

            LogDebug("try_to_connect_mailbox", "server=%s;port=%d",
                pmb->GetIp().c_str(), pmb->GetServerPort());
        }
    }
    
    return 0;
}

int CEpollServer::Service(const char* pszAddr, unsigned int unPort)
{
    int nRet = StartServer(pszAddr, unPort);
    if(nRet != 0)
    {
        return nRet;
    }

    nRet = ConnectMailboxs("");
    if(nRet != 0)
    {
        return nRet;
    }

    GetWorld()->OnServerStart();

    struct epoll_event events[MAX_EPOLL_SIZE];
    enum { _EPOLL_TIMEOUT = 50, };
    CCalcTimeTick time_prof;

    while (!m_bShutdown)
    {
        int nfds = epoll_wait(m_epfd, events, MAX_EPOLL_SIZE, _EPOLL_TIMEOUT);
        if (nfds == -1)
        {
            if (errno == EINTR)
            {
                continue;
            }
            else
            {
                ERROR_RETURN2("Failed to epoll_wait");
                break;
            }
        }

        uint64_t nTimeEpoll = time_prof.GetPassNsTick();
        time_prof.SetNowTime();

        for (int n = 0; n < nfds; ++n)
        {
            int fd = events[n].data.fd;
            CMailBox* mb = GetFdMailbox(fd);
            if(mb == NULL)
            {
                //todo
                continue;
            }
            EFDTYPE tfd = mb->GetFdType();

            switch(tfd)
            {
                case FD_TYPE_SERVER:
                {
                    HandleNewConnection(fd);
                    break;
                }
                case FD_TYPE_ACCEPT:
                {
                    HandleFdEvent(fd, events[n].events, mb);
                    break;
                }
                case FD_TYPE_MAILBOX:
                {
                    HandleMailboxEvent(fd, events[n].events, mb);
                    break;
                }
                default:
                {
                    //FD_TYPE_ERROR
                    break;
                }
            }

        }
        uint64_t nTimeEvent = time_prof.GetPassNsTick();
        time_prof.SetNowTime();

        //处理包
        this->HandlePluto();
        uint64_t nTimeHdlRecv = time_prof.GetPassNsTick();
        time_prof.SetNowTime();

        // 处理定时调用逻辑
        GetWorld()->OnThreadRun();

        //发送响应包
        this->HandleSendPluto();
        uint64_t nTimeHdlSend = time_prof.GetPassNsTick();
        time_prof.SetNowTime();

        //与其他服务通讯：重连tcp
        this->HandleMailboxReconnect();

        //真正删除无用的mailbox
        ClearContainer(m_mb4del);

        // lld longlong   llu unsigned long long
        //LogInfo("time_prof_1", "epoll=%d;event=%llu;recv=%llu;send=%llu", nTimeEpoll, nTimeEvent, nTimeHdlRecv, nTimeHdlSend);
    }

    OnShutdownServer();

    return 0;
}

int CEpollServer::CheckUserTimeout()
{
    int count = 0;
    list<int> listDel;
    for (map<int, CMailBox*>::iterator it = m_fds.begin(); it != m_fds.end(); ++it)
    {
        CMailBox* mb = it->second;
        if (mb->GetFdType() == FD_TYPE_ACCEPT)
        {
            if (mb->GetNoPackPassMs() > 60 * 1000)
                listDel.push_back(it->first);
        }
    }

    while (!listDel.empty())
    {
        int fd = listDel.front();
        CloseFdFromServer(fd);
        listDel.pop_front();
        ++count;
    }

    return count;
}

void CEpollServer::OnShutdownServer()
{
    LogInfo("goto_shutdown", "shutdown after 2 seconds.");
    sleep(2);
}

int CEpollServer::HandleNewConnection(int fd)
{
    struct sockaddr_in their_addr;
    socklen_t their_len = sizeof(their_addr);
    int new_fd = accept(fd, (struct sockaddr *) &their_addr, &their_len);

    LogInfo("HandleNewConnection", "new tcp client fd=%d curFdsSize=%u", new_fd, m_fds.size());

    if (new_fd < 0)
    {
        if(errno == EAGAIN)
        {
            ERROR_PRINT2("Failed to accept new connection,try EAGAIN\n")
            return -1;
        }
        else
        {
            ERROR_PRINT2("Failed to accept new connection")
            return -2;
        }
    }

    //一般linux设置每个进程打开文件数为1024,这个设置正好符合游戏的最大连接数
    enum{ MAX_ACCEPT = MAX_FILE_HANDLE_COUNT-20, };
    if(m_fds.size() >= MAX_ACCEPT)
    {
        ::close(new_fd);
        LogWarning("max_connection", "closed=%d", new_fd);
        return -3;
    }

    char* pszClientAddr = inet_ntoa(their_addr.sin_addr);
    uint16_t unClientPort = ntohs(their_addr.sin_port);

    if (!this->GetWorld()->IsCanAcceptedClient(pszClientAddr))
    {
        ::close(new_fd);
        LogWarning("can not accepted client", "connected from %s:%d;assigned socket is:%d", pszClientAddr, unClientPort, new_fd);
        return -4;
    }

    //LogInfo("new_connection", "connected from %s:%d, assigned socket is:%d", pszClientAddr, unClientPort, new_fd);

    MogoSetNonblocking(new_fd);
    struct epoll_event ev;
    memset(&ev, 0, sizeof ev);

    ev.events = EPOLLIN | EPOLLET;
    ev.data.fd = new_fd;
    if (epoll_ctl(m_epfd, EPOLL_CTL_ADD, new_fd, &ev) < 0)
    {
        ERROR_PRINT2("Failed to epoll_ctl_add new accepted socket");
        return -3;
    }
    this->OnNewFdAccepted(new_fd, their_addr);

    return 0;
}

int CEpollServer::HandleMailboxEvent(int fd, uint32_t event, CMailBox* pmb)
{
    if(pmb != NULL)
    {
        if(!pmb->IsConnected())
        {
            int nConnErr = 0;
            socklen_t _tl = sizeof(nConnErr);
            //可写之后判断
            if(getsockopt(fd, SOL_SOCKET, SO_ERROR, &nConnErr, &_tl) == 0)
            {
                if(nConnErr == 0)
                {
                    pmb->SetConnected();
                    LogInfo("CEpollServer::HandleMailboxEvent", "connected_2_mb mb fd = %d connected severName = %s, port = %d,", fd, pmb->GetIp().c_str(),pmb->GetServerPort());
                }
                else
                {
                    LogInfo("CEpollServer::HandleMailboxEvent", "connect_2_mb connect %s:%d error:%d,%s", pmb->GetIp().c_str(),
                            pmb->GetServerPort(), nConnErr, strerror(nConnErr));

                    //CMailBox::ConnectServer已经close和删除事件了。
                    RemoveFd(fd);

                    return 0;
                }
            }
            else
            {
                return -2;
            }
        }

        if(event & EPOLLIN)
        {
            return this->HandleFdEvent(fd, event, pmb);
        }
        else
        {
            return 0;
        }
    }

    //todo,assert??
    //如果服务器的某一个进程退出之后,是否需要关闭所有服务器进程
    return -1;
}

int CEpollServer::HandleFdEvent(int fd, uint32_t event, CMailBox* mb)
{
    int ret = 0;
    do
    {
        if (mb->GetAuthz() == MAILBOX_CLIENT_UNAUTHZ || mb->GetAuthz() == MAILBOX_CLIENT_AUTHZ)
        {
            //如果连接来自客户端，则需要限制其待处理的Pluto数量
            map<int, uint32_t>::const_iterator iter = this->m_fd2Plutos.find(fd);

            if(iter != this->m_fd2Plutos.end() && iter->second >= this->m_unMaxPlutoCount)
            {
                LogWarning("CEpollServer::HandleFdEvent", "Pluto Too Much..., fd=%d;mb->GetAuthz()=%d;mb->GetServerName()=%s;mb->GetServerPort()=%d;iter->second=%d;m_unMaxPlutoCount=%d", 
                                                                              fd, mb->GetAuthz(), mb->GetIp().c_str(), mb->GetServerPort(), iter->second, this->m_unMaxPlutoCount);
                //如果客户端发上来的待处理包数量过多，直接踢掉线
                CloseFdFromServer(fd);
                return -2;
            }
        }

        ret = this->HandleMessage(fd, mb);
    }
    while (ret == -4);

    if(ret < 0)
    {
        CloseFdFromServer(fd);
        return -1;
    }

    return 0;
}

void CEpollServer::WsCheckSendClosePluto(int fd)
{
#ifdef __WEBSOCKET_CLIENT
    CMailBox* mb = GetFdMailbox(fd);
    if (NULL != mb)
    {
        if (mb->IsWebsocket())
        {
            // close包也不加mask
            static const uint8_t szClose[] = {0x88, 0x00};
            ::send(fd, szClose, sizeof(szClose), 0);
        }
    }
#endif
}

//服务器主动关闭一个socket
void CEpollServer::CloseFdFromServer(int fd)
{
    // 不存在的没必要删除
    map<int, CMailBox*>::const_iterator iter = m_fds.find(fd);
    if(iter == m_fds.end())
    {
        return;
    }

    this->OnFdClosed(fd);
    WsCheckSendClosePluto(fd);
    epoll_ctl(m_epfd, EPOLL_CTL_DEL, fd, NULL);
    ::close(fd);
    RemoveFd(fd);
}

//连接其他服务器mailbox会直接调用这个方法
void CEpollServer::AddFdAndMb(int fd, CMailBox* pmb)
{
    pmb->SetFd(fd);

    map<int, CMailBox*>::iterator iter = m_fds.lower_bound(fd);
    if(iter != m_fds.end() && iter->first == fd)
    {
        //异常情况,有一个老的mb未删除
        CMailBox* p2 = iter->second;
        if (p2 != pmb)
        {
            delete p2;
            iter->second = pmb;
        }
        
        LogWarning("CEpollServer::addFdAndMb_err", "desc=old_fd_mb;fd=%d", fd);
    }
    else
    {
        //正常情况
        m_fds.insert(iter, make_pair(fd, pmb));
    }

    //LogDebug("CEpollServer::addFdAndMb", "fd=%d;fd_type=%d;addr=%s;port=%d;authz=%d", fd, pmb->GetFdType(), pmb->GetIp().c_str(), pmb->GetServerPort(), pmb->GetAuthz());
}

//来自客户端的连接会直接调用这个方法
void CEpollServer::AddFdAndMb(int fd, EFDTYPE efd, const char* pszAddr, uint16_t unPort)
{
    CMailBox* pmb = new CMailBox(0, efd, pszAddr, unPort);

    //来自可信任客户端地址的连接,免认证
    if(this->GetWorld()->IsTrustedClient(pmb->GetIp()))
    {
        LogDebug("CEpollServer::AddFdAndMb", "client_trusted, serverName=%s", pmb->GetIp().c_str());
        pmb->SetAuthz(MAILBOX_CLIENT_TRUSTED);
    }

    //设置已连接标记
    pmb->SetConnected();

    AddFdAndMb(fd, pmb);
}

void CEpollServer::RemoveFd(int fd)
{
    map<int, CMailBox*>::iterator iter = m_fds.find(fd);
    if(iter == m_fds.end())
    {
        return;
    }

    CMailBox* pmb = iter->second;
    
    //LogDebug("CEpollServer::removeFd", "fd=%d;fd_type=%d;addr=%s;port=%d", fd, pmb->GetFdType(), pmb->GetIp().c_str(), pmb->GetServerPort());

    if(pmb->GetFdType() == FD_TYPE_ACCEPT)
    {
        pmb->SetDeleteFlag();    //先标记不真正delete
        m_mb4del.push_back(pmb);
        m_fds.erase(iter);
        return;
    }
    else if (pmb->GetFdType() == FD_TYPE_MAILBOX)
    {
        // 判断是否可以立即重连
        int nRet = pmb->ConnectServer(m_epfd);
        if(nRet != 0)
        {
            LogInfo("CEpollServer::RemoveFd","reconnect_failed");
            m_mb4reconn.push_back(pmb);
            m_fds.erase(iter);
            return;
        }
        int new_fd = pmb->GetFd();
        if(fd == new_fd)
            LogInfo("CEpollServer::RemoveFd","reconnect_same_fd old=%d;new=%d", fd, new_fd);
        else
            LogInfo("CEpollServer::RemoveFd","reconnect_diff_fd old=%d;new=%d", fd, new_fd);

        m_fds.erase(iter);
        AddFdAndMb(new_fd, pmb);
    }
}

int CEpollServer::HandleMailboxReconnect()
{
    if(m_mb4reconn.empty())
    {
        return 0;
    }

    for(int i = (int)m_mb4reconn.size()-1; i >= 0; --i)
    {
        CMailBox* pmb = m_mb4reconn[i];
        int nRet = pmb->ConnectServer(m_epfd);
        if(nRet == 0)
        {
            m_mb4reconn.erase(m_mb4reconn.begin()+i);
            AddFdAndMb(pmb->GetFd(), pmb);
        }
    }

    return 0;
}

EFDTYPE CEpollServer::GetFdType(int fd)
{
    map<int, CMailBox*>::const_iterator iter = m_fds.find(fd);
    if(iter == m_fds.end())
    {
        return FD_TYPE_ERROR;
    }
    else
    {
        return iter->second->GetFdType();
    }
}

CMailBox* CEpollServer::GetFdMailbox(int fd)
{
    map<int, CMailBox*>::const_iterator iter = m_fds.find(fd);
    if(iter == m_fds.end())
    {
        return NULL;
    }
    else
    {
        return iter->second;
    }
}


bool CEpollServer::SendPlutoByFd(int fd, CPluto* pu)
{
    CMailBox* mb = GetFdMailbox(fd);
    if(!mb)
    {
        LogError("CEpollServer::SendPlutoByFd", "find fdMailBox failed");
        delete pu;
        return false;
    }
    if(FD_TYPE_ACCEPT != mb->GetFdType())
    {
        LogError("CEpollServer::SendPlutoByFd", "fd type error");
        delete pu;
        return false;
    }

    mb->PushPluto(pu);
    return true;
}

int CEpollServer::OnNewFdAccepted(int new_fd, sockaddr_in& addr)
{
    char* pszClientAddr = inet_ntoa(addr.sin_addr);
    uint16_t unClientPort = ntohs(addr.sin_port);

    AddFdAndMb(new_fd, FD_TYPE_ACCEPT, pszClientAddr, unClientPort);
    return 0;
}

int CEpollServer::OnFdClosed(int fd)
{
    the_world->OnFdClosed(fd);

    return 0;
}

//直接接收数据至pluto,不需要先接收到buff再copy
int CEpollServer::HandleMessage(int fd, CMailBox* mb)
{
#ifdef __WEBSOCKET_CLIENT
    if (mb->IsWebsocket())
    {
        return HandleMessageWebsocket(fd, mb);
    }
#endif
    int nLen = -1;
    CPluto* u = mb->GetRecvPluto();
    if(u == NULL)
    {
        //创建包头缓存
        u = new CPluto(PLUTO_MSGLEN_HEAD);
        u->SetLen(0);
        mb->SetRecvPluto(u);
        // 继续循环
        return -4;
    }
    else
    {
        char* szBuff = u->GetRecvBuff();
        int nLastLen = u->GetLen();     //上次接收到的数据长度
        if(nLastLen < PLUTO_MSGLEN_HEAD)
        {
            //包头未收完
            int nWanted = PLUTO_MSGLEN_HEAD - nLastLen;
            nLen = ::recv(fd, szBuff+nLastLen, nWanted, 0);
            if(nLen > 0)
            {
                if(nLen == nWanted)
                {
#ifdef __WEBSOCKET_CLIENT
                    if (IsPlutoHeaderGet(szBuff))
                    {
                        u->SetLen(PLUTO_MSGLEN_HEAD);

                        if (mb->GetFdType() != FD_TYPE_ACCEPT)
                        {
                            LogWarning("HandleMessage error", "GetFdType not client");
                            return -1;
                        }

                        LogInfo("CEpollServer::HandleMessage", "websocket client fd=%d", fd);

                        mb->SetIsWebsocket();
                        return HandleMessageWebsocket(fd, mb);
                    }
#endif
                    int nMsgLen = sz_to_uint32((unsigned char*)szBuff);
                    int result = this->CheckPlutoHeadSize(fd, mb, nMsgLen);
                    if (result < 0)
                    {
                        return result;
                    }

                    CPluto* u2 = new CPluto(nMsgLen);
                    memcpy(u2->GetRecvBuff(), szBuff, PLUTO_MSGLEN_HEAD);
                    u2->SetLen(PLUTO_MSGLEN_HEAD);
                    mb->SetRecvPluto(u2);
                    delete u;

                    return -4;
                }
                else
                {
                    //仍然未接收完
                    u->SetLen(nLastLen+nLen);
                    return nLen;
                }
            }
        }
        else
        {
            int nWanted = u->GetBuffSize() - nLastLen;
            nLen = ::recv(fd, szBuff+nLastLen, nWanted, 0);
            if(nLen > 0)
            {
                if(nLen == nWanted)
                {
                    //接收完整
                    u->EndRecv(nLastLen+nLen);
                    u->SetMailbox(mb);
                    u->SetSrcFd(fd);
                    AddRecvMsg(u);
                    mb->SetRecvPluto(NULL); //置空

                    //print_hex_pluto(*u);
                    //可能还有其他包要处理

                    return -4;
                }
                else
                {
                    //接收不完整,留到下次接着处理
                    u->SetLen(nLastLen+nLen);
                    return nLen;
                }
            }
        }
    }

    if(nLen == 0)
    {
        //client close
    }
    else
    {
        if(errno == EAGAIN)
        {
            return 0;
        }
        LogWarning("handle_message_err", "failed, %d,'%s'",errno, strerror(errno));
    }

    return -1;
}

#ifdef __WEBSOCKET_CLIENT
/*  The following is websocket data frame:

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-------+-+-------------+-------------------------------+
     |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
     |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
     |N|V|V|V|       |S|             |   (if payload len==126/127)   |
     | |1|2|3|       |K|             |                               |
     +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
     |     Extended payload length continued, if payload len == 127  |
     + - - - - - - - - - - - - - - - +-------------------------------+
     |                               |Masking-key, if MASK set to 1  |
     +-------------------------------+-------------------------------+
     | Masking-key (continued)       |          Payload Data         |
     +-------------------------------- - - - - - - - - - - - - - - - +
     :                     Payload Data continued ...                :
     + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
     |                     Payload Data continued ...                |
     +---------------------------------------------------------------+
*/
int CEpollServer::HandleMessageWebsocket(int fd, CMailBox* mb)
{
    int nLen = -1;
    CPluto* u = mb->GetRecvPluto();
    if(u == NULL)
    {
        //创建包头缓存
        u = new CPluto(WS_PLUTO_MSGLEN_HEAD);
        u->SetLen(0);
        mb->SetRecvPluto(u);
        // 继续循环
        return -4;
    }
    else
    {
        char* szBuff = u->GetRecvBuff();
        int nLastLen = u->GetLen();     //上次接收到的数据长度

        if (!mb->IsFirstPluto())
        {
            if(nLastLen < WS_PLUTO_MSGLEN_HEAD)
            {
                //包头未收完
                int nWanted = WS_PLUTO_MSGLEN_HEAD - nLastLen;
                nLen = ::recv(fd, szBuff+nLastLen, nWanted, 0);
                if(nLen > 0)
                {
                    if(nLen == nWanted)
                    {
                        uint8_t b1 = *(uint8_t*)(void*)szBuff;
                        uint8_t b2 = *(uint8_t*)(void*)(szBuff + 1);

                        bool isEnd = (b1 >> 7) > 0;
                        uint8_t opCode = b1 & 0xF;
                        bool hasMask = (b2 >> 7) > 0;
                        uint8_t dataLen = b2 & 0x7F;

                        switch (opCode)
                        {
                            case 0:
                            {
                                if (isEnd)
                                    u->SetWsOpCode(WS_OPCODE_DATA_END);
                                else
                                    u->SetWsOpCode(WS_OPCODE_DATA_NEXT);
                                break;
                            }
                            case 1:
                            case 2:
                            {
                                if (isEnd)
                                    u->SetWsOpCode(WS_OPCODE_DATA_END);
                                else
                                    u->SetWsOpCode(WS_OPCODE_DATA);
                                break;
                            }
                            case 8:
                            case 9:
                            {
                                if (!isEnd)
                                {
                                    LogWarning("HandleMessageWebsocket_err", "opCode 8-9 not End!");
                                    return -1;
                                }
                                u->SetWsOpCode(opCode);
                                break;
                            }
                            default:
                            {
                                // 未知格式
                                LogWarning("HandleMessageWebsocket_err", "opCode unknown!");
                                return -1;
                            }
                        }

                        int headerLen = WS_PLUTO_MSGLEN_HEAD;
                        if (hasMask)
                            headerLen += 4;
                        switch (dataLen)
                        {
                            case 0x7E:
                            {
                                headerLen += 2;
                                if (hasMask)
                                    u->SetWsMaskPos(WS_PLUTO_MSGLEN_HEAD + 2);
                                break;
                            }
                            case 0x7F:
                            {
                                // 单帧长度大于maxWord，没有这么大的包
                                LogWarning("HandleMessageWebsocket_err", "dataLen too long!");
                                return -1;
                            }
                            default:
                            {
                                u->SetWsDataLen(dataLen);

                                if (hasMask)
                                    u->SetWsMaskPos(WS_PLUTO_MSGLEN_HEAD);
                                break;
                            }
                        }
                        u->SetWsHeaderLen(headerLen);
                        u->SetLen(nLastLen+nLen);

                        // 特殊情况处理，整个包只有2个字节包头
                        if (u->GetWsDataLen() >=0 && (u->GetLen() >= (uint32_t)(u->GetWsHeaderLen() + u->GetWsDataLen())))
                        {
                            if (opCode != 8 && opCode != 9)
                            {
                                LogWarning("HandleMessageWebsocket_err", "only header!");
                                return -1;
                            }

                            //接收完毕
                            if (u->GetWsDataLen() > 0)
                            {
                                u->WsMask();
                                memcpy(szBuff, szBuff + u->GetWsHeaderLen(), u->GetWsDataLen());
                            }
                            u->EndRecv(u->GetWsDataLen());
                            u->SetMailbox(mb);
                            u->SetSrcFd(fd);

                            bool isAddSuccess = mb->PushRecvWsPluto(u);
                            if (isAddSuccess)
                            {
                                mb->SetRecvPluto(NULL);
                                return -4;
                            }
                            else
                            {
                                LogWarning("HandleMessageWebsocket_err", "PushRecvWsPluto failed1!");
                                return -1;
                            }
                        }

                        // 判断内存是否够用
                        if (u->GetBuffSize() < (uint32_t)u->GetWsHeaderLen())
                        {
                            CPluto* u2 = new CPluto(u->GetWsHeaderLen());

                            u2->SetWsHeaderLen(u->GetWsHeaderLen());
                            u2->SetWsOpCode(u->GetWsOpCode());
                            u2->SetWsMaskPos(u->GetWsMaskPos());
                            u2->SetWsDataLen(u->GetWsDataLen());
                            
                            memcpy(u2->GetRecvBuff(), szBuff, u->GetLen());
                            u2->SetLen(u->GetLen());
                            mb->SetRecvPluto(u2);
                            delete u;
                        }
                        return -4;
                    }
                    else
                    {
                        //仍然未接收完
                        u->SetLen(nLastLen+nLen);
                        return nLen;
                    }
                }
            }
            else if (nLastLen < u->GetWsHeaderLen())
            {
                //包头未收完
                int nWanted = u->GetWsHeaderLen() - nLastLen;
                nLen = ::recv(fd, szBuff+nLastLen, nWanted, 0);
                if(nLen > 0)
                {
                    if(nLen == nWanted)
                    {
                        int wsOpCode = u->GetWsOpCode();
                        // 获取data大小，大小在头部的已经处理完了
                        if (u->GetWsDataLen() < 0)
                        {
                            u->SetWsDataLen(sz_to_uint16_big_endian((uint8_t *)(szBuff + WS_PLUTO_MSGLEN_HEAD)));
                            if (u->GetWsDataLen() > PLUTO_CLIENT_MSGLEN_MAX)
                            {
                                LogWarning("HandleMessageWebsocket_err", "tWsDataLen too long!");
                                return -1;
                            }
                        }

                        u->SetLen(nLastLen+nLen);
                        // 特殊情况处理，只有包头，没有data
                        if (u->GetLen() >= (uint32_t)(u->GetWsHeaderLen() + u->GetWsDataLen()))
                        {
                            if (wsOpCode != 8 && wsOpCode != 9)
                            {
                                LogWarning("HandleMessageWebsocket_err", "only header!");
                                return -1;
                            }

                            //接收完毕
                            if (u->GetWsDataLen() > 0)
                            {
                                u->WsMask();
                                memcpy(szBuff, szBuff + u->GetWsHeaderLen(), u->GetWsDataLen());
                            }
                            u->EndRecv(u->GetWsDataLen());
                            u->SetMailbox(mb);
                            u->SetSrcFd(fd);

                            bool isAddSuccess = mb->PushRecvWsPluto(u);
                            if (isAddSuccess)
                            {
                                mb->SetRecvPluto(NULL);
                                return -4;
                            }
                            else
                            {
                                LogWarning("HandleMessageWebsocket_err", "PushRecvWsPluto failed2!");
                                return -1;
                            }
                        }

                        // 判断内存是否够用
                        if (u->GetBuffSize() < (uint32_t)(u->GetWsHeaderLen() + u->GetWsDataLen()))
                        {
                            CPluto* u2 = new CPluto(u->GetWsHeaderLen() + u->GetWsDataLen());

                            u2->SetWsHeaderLen(u->GetWsHeaderLen());
                            u2->SetWsOpCode(u->GetWsOpCode());
                            u2->SetWsMaskPos(u->GetWsMaskPos());
                            u2->SetWsDataLen(u->GetWsDataLen());

                            memcpy(u2->GetRecvBuff(), szBuff, u->GetLen());
                            u2->SetLen(u->GetLen());
                            mb->SetRecvPluto(u2);
                            delete u;
                        }

                        return -4;
                    }
                    else
                    {
                        //仍然未接收完
                        u->SetLen(nLastLen+nLen);
                        return nLen;
                    }
                }
            }
            else
            {
                int nWanted = u->GetBuffSize() - nLastLen;
                nLen = ::recv(fd, szBuff+nLastLen, nWanted, 0);
                if(nLen > 0)
                {
                    if(nLen == nWanted)
                    {
                        u->SetLen(nLastLen+nLen);

                        //接收完毕
                        if (u->GetWsDataLen() > 0)
                        {
                            u->WsMask();
                            memcpy(szBuff, szBuff + u->GetWsHeaderLen(), u->GetWsDataLen());
                        }
                        u->EndRecv(u->GetWsDataLen());
                        u->SetMailbox(mb);
                        u->SetSrcFd(fd);

                        bool isAddSuccess = mb->PushRecvWsPluto(u);
                        if (isAddSuccess)
                        {
                            mb->SetRecvPluto(NULL);
                            return -4;
                        }
                        else
                        {
                            LogWarning("HandleMessageWebsocket_err", "PushRecvWsPluto failed3!");
                            return -1;
                        }

                        return -4;
                    }
                    else
                    {
                        //接收不完整,留到下次接着处理
                        u->SetLen(nLastLen+nLen);
                        return nLen;
                    }
                }
            }
        }
        else
        {
            // websocket第一个http包特殊处理
            if (!IsPlutoHeaderGet(szBuff))
                return -1;

            if (u->GetBuffSize() < HTTP_MSGLEN_MAX)
            {
                // +1为了保证buffer结束后，有个'\0'
                CPluto* u2 = new CPluto(HTTP_MSGLEN_MAX + 1);
                memcpy(u2->GetRecvBuff(), szBuff, u->GetLen());
                u2->SetLen(u->GetLen());
                mb->SetRecvPluto(u2);
                delete u;

                return -4;
            }

            int nWanted = HTTP_MSGLEN_MAX - nLastLen;
            if (nWanted <= 0)
            {
                LogWarning("HandleMessageWebsocket_err", "Http Get bigger than %d", HTTP_MSGLEN_MAX);
                return -1;
            }

            nLen = ::recv(fd, szBuff+nLastLen, nWanted, 0);
            if (nLen > 0)
            {
                char * szEndPos = GetPlutoReceiveEndPos(szBuff, nLastLen + nLen);
                if (NULL != szEndPos)
                {
                    //方便字符串查找
                    szBuff[nLastLen + nLen] = '\0';
                    //接收完毕
                    u->EndRecv(szEndPos - szBuff);
                    u->SetMailbox(mb);
                    u->SetSrcFd(fd);
                    u->SetWsOpCode(WS_OPCODE_GET);

                    mb->ResetIsFirstPluto();
                    bool isAddSuccess = mb->PushRecvWsPluto(u);

                    if (isAddSuccess)
                    {
                        mb->SetRecvPluto(NULL);
                        return -4;
                    }
                    else
                    {
                        LogWarning("HandleMessageWebsocket_err", "PushRecvWsPluto failed4!");
                        return -1;
                    }
                }
                else
                {
                    u->SetLen(nLastLen + nLen);
                    return nLen;
                }
            }
        }
    }

    if(nLen == 0)
    {
        //client close
    }
    else
    {
        if(errno == EAGAIN)
        {
            return 0;
        }
        LogWarning("HandleMessageWebsocket_err", "failed, %d,'%s'",errno, strerror(errno));
    }

    return -1;
}
#endif

void CEpollServer::AddRecvMsg(CPluto* u)
{
    m_recvMsgs.push_back(u);

    //每收到一个包就把该连接上的包数量累加1
    if (!u)
    {
        return;
    }
    CMailBox* mb = u->GetMailbox();
    if (mb)
    {
        int fd = mb->GetFd();
        map<int, uint32_t>::iterator iter = this->m_fd2Plutos.find(fd);
        if (iter != this->m_fd2Plutos.end())
        {
            iter->second++;
        }
        else
        {
            this->m_fd2Plutos.insert(make_pair(fd, 1));
        }
    }
}

int CEpollServer::HandlePluto()
{
    while(!m_recvMsgs.empty())
    {
        CPluto* u = m_recvMsgs.front();
        m_recvMsgs.pop_front();

        world* w = GetWorld();
        w->FromRpcCall(*u);
        delete u;
    }

    //处理完以后直接清空掉
    this->m_fd2Plutos.clear();
    return 0;
}

int CEpollServer::HandleSendPluto()
{
    list<int> ls4del;
    map<int, CMailBox*>::iterator iter = m_fds.begin();
    for(; iter != m_fds.end(); ++iter)
    {
        CMailBox* mb = iter->second;
        int n = mb->SendAll();
        if(n != 0)
        {
            //发送失败需要关闭的连接
            ls4del.push_back(mb->GetFd());
        }
    }

    //关闭连接
    while(!ls4del.empty())
    {
        int fd = ls4del.front();
        CloseFdFromServer(fd);
        ls4del.pop_front();
    }

    return 0;
}

void CEpollServer::SetWorld(world* w)
{
    this->the_world = w;

    this->m_unMaxPlutoCount = atoi(w->GetCfgReader()->GetOptValue("params", "max_pluto_count", "100").c_str());
}

world* CEpollServer::GetWorld()
{
    return the_world;
}

void CEpollServer::Shutdown()
{
    m_bShutdown = true;
    LogInfo("recv_shutdown", "...");
}

int CEpollServer::CheckPlutoHeadSize(int fd, CMailBox* mb, uint32_t nMsgLen)
{
    if(nMsgLen < PLUTO_FILED_BEGIN_POS)
    {
        LogWarning("CEpollServer::CheckPlutoHeadSize", "handle_message_err message_length_err,size=%d,min=%d", nMsgLen, PLUTO_FILED_BEGIN_POS);
        return -2;
    }
    if(mb->GetAuthz() != MAILBOX_CLIENT_TRUSTED)
    {
        if(nMsgLen > PLUTO_CLIENT_MSGLEN_MAX)
        {
            LogWarning("CEpollServer::CheckPlutoHeadSize", "handle_message_err max_message_length,size=%d,max=%d, ip = %s", nMsgLen, PLUTO_CLIENT_MSGLEN_MAX, mb->GetIp().c_str());
            return -3;
        }
    }
	else
	{
		// 服务端连接限制6MB包
		if (nMsgLen > 100 * PLUTO_CLIENT_MSGLEN_MAX)
		{
			LogWarning("CEpollServer::CheckPlutoHeadSize", "handle_message_err MAILBOX_CLIENT_TRUSTED max_message_length,size=%d,max=%d, ip = %s", nMsgLen, 100 * PLUTO_CLIENT_MSGLEN_MAX, mb->GetIp().c_str());
			return -3;
		}
	}

    return 0;
}

////////////////////////////////////////////////////////////////////////////////////////////
