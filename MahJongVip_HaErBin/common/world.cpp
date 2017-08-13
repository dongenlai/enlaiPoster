/*----------------------------------------------------------------
// 模块名：world
// 模块描述：消息转发， mailbox 列表维护， 部分消息触发等
//----------------------------------------------------------------*/

#include "my_stl.h"
#include "util.h"
#include "world.h"
#include "debug.h"
#include "epoll_server.h"
#include "sha1.h"
#include "base64.h"
#include "json_helper.h"
#include <termios.h>

CMailBoxManager::CMailBoxManager()
{

}

CMailBoxManager::~CMailBoxManager()
{
}

bool CMailBoxManager::init(CCfgReader& cfg)
{
    int nServerCount = SERVER_MAILBOX_RESERVE_SIZE;
    for(int i = 1; i <= nServerCount; ++i)
    {
        char szServer[16];
        memset(szServer, 0, sizeof(szServer));
        snprintf(szServer, sizeof(szServer), "server_%d", i);

        const string& strServerType = cfg.GetOptValue(szServer, "type", "");
        if(strServerType.empty())
        {
            LogInfo("init_cfg", "end section:%s", szServer);
            break;;
        }

        int nServerID = atoi(cfg.GetValue(szServer, "id").c_str());

        int nServerType;
        if(strServerType.compare("areamgr") == 0)
        {
            nServerType = SERVER_AREAMGR;
        }
        else if(strServerType.compare("dbmgr") == 0)
        {
            nServerType = SERVER_DBMGR;
        }
        else if(strServerType.compare("area") == 0)
        {
            nServerType = SERVER_AREA;
        }
        else
        {
            ThrowException(-1, "unknown server type:%s", strServerType.c_str());
        }

        CMailBox* mb = new CMailBox(nServerID, FD_TYPE_MAILBOX, cfg.GetValue(szServer, "ip").c_str(), \
                                    atoi(cfg.GetValue(szServer, "port").c_str()));
        mb->SetServerMbType(nServerType);
        m_mbs.push_back(mb);
    }

    return true;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

world::world(): m_cfg(NULL), m_rpc(), \
    the_server(NULL), m_mbMgr()
{

}

world::~world()
{
    delete m_cfg;
    this->Clear();
}

void world::Clear()
{
}

void world::InitMailboxMgr()
{
    m_mbMgr.init(*m_cfg);
}

uint16_t world::GetServerPort(uint32_t sid)
{
    list<CMailBox*>& mbs = m_mbMgr.GetMailboxs();
    list<CMailBox*>::iterator iter = mbs.begin();
    for(; iter != mbs.end(); ++iter)
    {
        CMailBox* pmb = *iter;
        if(pmb->GetMailboxId() == sid)
        {
            return pmb->GetServerPort();
        }
    }

    return 0;
}

void world::InitTrustedClient()
{
    const string& strTrusted = m_cfg->GetValue("clients", "trusted");
    list<string> l = SplitString(strTrusted, ',');
    list<string>::const_iterator iter = l.begin();
    for(; iter != l.end(); ++iter)
    {
        m_trustedClients.insert(*iter);
    }
}

int world::init(const char* pszEtcFile)
{
    m_cfg = new CCfgReader(pszEtcFile);
    try
    {
        g_logger.InitCfg(*m_cfg);
        InitMailboxMgr();
        InitTrustedClient();
    }
    catch(const CException& e)
    {
        LogDebug("world::init().error", "%s", e.GetMsg().c_str());
        return -1;
    }

    return 0;
}

int world::OnFdClosed(int fd)
{
    return 0;
}

uint32_t world::GetMailboxId()
{
    CEpollServer* p = GetServer();
    if (p)
    {
        return p->GetMailboxId();
    }
    else
    {
        return 0;
    }
}

CMailBox* world::GetServerMailbox(uint32_t nServerId)
{
    CEpollServer* s = GetServer();
    if(s)
    {
        return s->GetServerMailbox(nServerId);
    }

    return NULL;
}

void world::SetServer(CEpollServer* s)
{
    this->the_server = s;
	uint32_t nServerId = the_server->GetMailboxId();
#ifdef __WEBSOCKET_CLIENT
    LogInfo("world::SetServer websocket_client", "nServerId=%d", nServerId);
#else
    LogInfo("world::SetServer", "nServerId=%d", nServerId);
#endif
}

CEpollServer* world::GetServer()
{
    return the_server;
}

bool world::IsTrustedClient(const string& strClientAddr)
{
    return m_trustedClients.find(strClientAddr) != m_trustedClients.end();
}

bool world::CheckClientRpc(CPluto& u)
{
    CMailBox* mb = u.GetMailbox();
    if(!mb)
    {
        //如果没有mb,是从本进程发来的包
        return true;
    }
    if(mb->IsDelete())
    {
        //已标记del的mb,其所有的包不再处理
        return false;
    }
    uint8_t authz = mb->GetAuthz();
    if(authz == MAILBOX_CLIENT_TRUSTED || FD_TYPE_MAILBOX == mb->GetFdType())
    {
        return true;
    }
    else
    {
        return false;
    }
}

#define SHA1_LEN 20
//encode client_key array into server_key array.
string key_gen(const char *client_key)
{
    unsigned char result[SHA1_LEN];

    sha1_buffer (client_key, strlen(client_key), result);
    return base64_encode (result, SHA1_LEN);
}

string websocket_handshake(string & Sec_WebSocket_Key)
{
    string client_key = Sec_WebSocket_Key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    string sKey = key_gen (client_key.c_str());    //generate the server's response key

    char buffer[200];
    snprintf(buffer, sizeof(buffer), 
        "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: %s\r\n\r\n", sKey.c_str());
    string sRet(buffer);

    return sRet;
}

int world::FromRpcCall(CPluto& u)
{
#ifdef __WEBSOCKET_CLIENT
    CMailBox* mb = u.GetMailbox();
    if (!mb)
        return 0;

    if (mb->IsWebsocket())
    {
        switch(u.GetWsOpCode())
        {
            case WS_OPCODE_DATA:
            {
                // 转换string到pluto
                string* pJsonStr = new string(u.GetBuff(), u.GetLen());
                AutoJsonHelper aJs(*pJsonStr);
                delete pJsonStr;

                if (!m_rpc.RpcEncodeJsonToPluto(aJs, u))
                {
                    LogInfo("FromRpcCall", "RpcEncodeJsonToPluto error");
                    GetServer()->CloseFdFromServer(mb->GetFd());
                    return -1;
                }

                // u的内容被被改成正常tcp数据包了。
                return 1;
            }
            case WS_OPCODE_CLOSE:
            {
                GetServer()->CloseFdFromServer(mb->GetFd());
                return -1;
            }
            case WS_OPCODE_PING:
            {
                CPluto* usend = new CPluto;
                usend->SetWsOpCode(WS_OPCODE_PONG);
                const char* szPong = "pong";
                usend->OverrideBuffer(szPong, strlen(szPong));
                mb->PushPluto(usend);

                // 处理完毕，子类不需要再处理
                return -1;
            }
            case WS_OPCODE_GET:
            {
                // 分析get数据
                const char* p1 = strcasestr(u.GetBuff(), "Sec-WebSocket-Key");
                if (NULL == p1)
                {
                    GetServer()->CloseFdFromServer(mb->GetFd());
                    return -1;
                }
                p1 = strstr(p1, ":");
                if (NULL == p1)
                {
                    GetServer()->CloseFdFromServer(mb->GetFd());
                    return -1;
                }
                const char* p2 = strstr(p1, "\r\n");
                if (NULL == p2)
                {
                    GetServer()->CloseFdFromServer(mb->GetFd());
                    return -1;
                }
                // 得到key
                string key(p1 + 1, (p2 - p1 - 1));
                key = Trim(key);
                if (key.length() < 1)
                {
                    GetServer()->CloseFdFromServer(mb->GetFd());
                    return -1;
                }
                //LogInfo("FromRpcCall", "Sec-WebSocket-Key client=%s", key.c_str());
                string retStr = websocket_handshake(key);
                // 返回数据包
                CPluto* usend = new CPluto(retStr.length());
                usend->SetWsOpCode(WS_OPCODE_GET);
                usend->OverrideBuffer(retStr.c_str(), retStr.length());
                mb->PushPluto(usend);

                return -1;
            }
            default:
            {
                LogInfo("FromRpcCall", "unknown opcode=%d", u.GetWsOpCode());
                return -1;
            }
        }
    }
#endif
    return 1;
}


void world::OnThreadRun()
{
    // 线程的定时调用
}


void world::OnServerStart()
{
    // 服务器启动事件
}

int world::ShutdownServer(T_VECTOR_OBJECT* p)
{
    LogInfo("world::shutdown_server", "");

    //设置服务器退出标记
    GetServer()->Shutdown();

    return 0;
}

bool world::PushPlutoToMailbox(uint32_t nServerId, CPluto* u)
{
    if(GetMailboxId() == nServerId)
    {
        //本服务器
        GetServer()->AddLocalRpcPluto(u);
    }
    else
    {
        CMailBox* mb = GetServerMailbox(nServerId);
        if(mb)
        {
            mb->PushPluto(u);
        }
    }

    return true;
}

