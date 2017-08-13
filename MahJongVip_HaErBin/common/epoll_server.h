#ifndef __EPOLL_SERVER_HEAD__
#define __EPOLL_SERVER_HEAD__


#include <sys/epoll.h>
#include <time.h>
#include "win32def.h"
#include "util.h"
#include "net_util.h"
#include "mailbox.h"
#include "pluto.h"

class world;

enum
{
    MAX_FILE_HANDLE_COUNT = 1024,
    MAX_EPOLL_SIZE = 9999,
    CLIENT_TIMEOUT = 20,
    OTHERSERVER_TIMEOUT = 5,
};


class CEpollServer
{
    public:
        CEpollServer();
        virtual ~CEpollServer();
    public:
        virtual void AddRecvMsg(CPluto* u);
    protected:
        virtual int CheckPlutoHeadSize(int fd, CMailBox* mb, uint32_t nMsgLen);
        virtual int HandleNewConnection(int fd);
        virtual int HandleMailboxEvent(int fd, uint32_t event, CMailBox* mb);
        virtual int HandleFdEvent(int fd, uint32_t event, CMailBox* mb);
        virtual int HandleMessage(int fd, CMailBox* mb);
#ifdef __WEBSOCKET_CLIENT
        virtual int HandleMessageWebsocket(int fd, CMailBox* mb);
#endif
        virtual int HandleMailboxReconnect();
        virtual int HandlePluto();
        virtual int HandleSendPluto();
        virtual int OnNewFdAccepted(int new_fd, sockaddr_in& addr);
        virtual int OnFdClosed(int fd);
        //停止了服务器之后,进程退出之前的一个回调方法
        virtual void OnShutdownServer();
    public:
        int StartServer(const char* pszAddr, uint16_t unPort);
        void Shutdown();
        int Service(const char* pszAddr, unsigned int unPort);
        int CheckUserTimeout();
        //服务器主动关闭一个socket
        void CloseFdFromServer(int fd);
        //
        void SetWorld(world* w);
        world* GetWorld();
        int ConnectMailboxs(const char* pszCfgFile);
        CMailBox* GetFdMailbox(int fd);
        bool SendPlutoByFd(int fd, CPluto* pu);

        inline void SetMailboxId(uint32_t mid)
        {
            m_unMailboxId = mid;
        }
        inline uint32_t GetMailboxId() const
        {
            return m_unMailboxId;
        }
        inline CMailBox* GetServerMailbox(uint32_t nServerId)
        {
            map<uint32_t, CMailBox*>::iterator iter = m_serverMbs.find(nServerId);
            if(m_serverMbs.end() != iter)
            {
                return iter->second;
            }
            else
            {
                return NULL;
            }
        }
        inline void AddLocalRpcPluto(CPluto* u)
        {
            m_recvMsgs.push_back(u);
        }
        inline void GetServerIpPort(string& ip, uint16_t& port)
        {
            ip = m_strAddr;
            port = m_unPort;
        }
    protected:
        void AddFdAndMb(int fd, CMailBox* pmb);
        void AddFdAndMb(int fd, EFDTYPE efd, const char* pszAddr, uint16_t unPort);
        void RemoveFd(int fd);
        EFDTYPE GetFdType(int fd);
    private:
        void WsCheckSendClosePluto(int fd);
    protected:
        int m_epfd;
        map<int, CMailBox*> m_fds;
        list<CPluto*> m_recvMsgs;
        string m_strAddr;
        uint16_t m_unPort;
        vector<CMailBox*> m_mb4reconn;
        map<uint32_t, CMailBox*> m_serverMbs;       //服务器组件的mailbox
        uint32_t m_unMailboxId;
        world* the_world;
        bool m_bShutdown;
        list<CMailBox*> m_mb4del;         //待删除的mailbox
        map<int, uint32_t> m_fd2Plutos;    //记录每一个连接上待处理的Pluto数量
        uint32_t m_unMaxPlutoCount;
};



#endif
