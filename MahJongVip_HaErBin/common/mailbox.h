#ifndef __MAILBOX_HEAD__
#define __MAILBOX_HEAD__

#include <string>
#include <map>
#include <list>
#include <time.h>
#include "win32def.h"
#include "pluto.h"
#include "rpc_mogo.h"
#include "memory_pool.h"


using std::string;
using std::list;

struct MailBoxConfig
{
    uint8_t m_serverType;           //服务器类型:cell/base/login...
    string m_strRemoteIp;           //原程ip
    uint16_t m_unRemotePort;        //原程port
    //string m_strLocalMsgPath;       //本地消息队列路径
};

class CMailBox
{
    public:
        CMailBox(uint32_t uid, EFDTYPE fdtype, const char* pszAddr, uint16_t unPort);
        ~CMailBox();

        // 这里重载一是提升效率，二是CPluto有他的野指针，防止内存错误。
        void * operator new(size_t size);
        void operator delete(void* p, size_t size);
    private:
        static MemoryPool *memPool;
        static void expandMemoryPool();
        static MyLock m_lock;
        void ClearData();
    public:
        //根据配置初始化
        bool init(const MailBoxConfig& cfg);
        //
        int ConnectServer(int epfd);
        int SendAll();
        void PushPluto(CPluto* u);
		char* GetClientIP();

    public:
        inline bool IsConnected() const
        {
            return m_bConnected;
        }

        inline void SetConnected(bool c = true)
        {
            m_bConnected = c;
        }

        inline void SetLastPackTime()
        {
            m_lastPackTime.SetNowTime();
        }

        inline uint32_t GetNoPackPassMs()
        {
            return m_lastPackTime.GetPassMsTick();
        }

        inline uint8_t GetAuthz() const
        {
            return m_uAuthz;
        }

        inline void SetAuthz(uint8_t n)
        {
            m_uAuthz = n;
        }

        inline void SetFd(int fd)
        {
            m_fd = fd;
        }

        inline int GetFd() const
        {
            return m_fd;
        }

        inline EFDTYPE GetFdType() const
        {
            return m_fdType;
        }

        inline const string& GetIp() const
        {
            return m_ip;
        }

        inline uint16_t GetServerPort() const
        {
            return m_serverPort;
        }

        inline CPluto* GetRecvPluto()
        {
            return m_curReceivePluto;
        }

        inline void SetRecvPluto(CPluto* u)
        {
            m_curReceivePluto = u;
        }

        inline uint32_t GetMailboxId() const
        {
            return m_id;
        }

        inline void SetServerMbType(uint16_t t)
        {
            m_unServerMbType = t;
        }

        inline uint16_t GetServerMbType() const
        {
            return m_unServerMbType;
        }

        //发送队列是否为空
        inline bool IsSendEmpty() const
        {
            return m_tobeSend.empty();
        }

        inline void SetDeleteFlag()
        {
            m_bDeleteFlag = true;
        }

        inline bool IsDelete() const
        {
            return m_bDeleteFlag;
        }
#ifdef __WEBSOCKET_CLIENT
        inline bool IsFirstPluto() const
        {
            return m_isFirstPluto;
        }
        
        inline void ResetIsFirstPluto()
        {
            m_isFirstPluto = false;
        }

        inline bool IsWebsocket() const
        {
            return m_isWebsocket;
        }

        inline void SetIsWebsocket()
        {
            m_isWebsocket = true;
        }

        // 返回false需要断开连接
        bool PushRecvWsPluto(CPluto* u);
#endif
    public:
        template<typename T1>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1);

        template<typename T1, typename T2>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2);

        template<typename T1, typename T2, typename T3>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3);

        template<typename T1, typename T2, typename T3, typename T4>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4);

        template<typename T1, typename T2, typename T3, typename T4, typename T5>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5);

        template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6);

        template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6, const T7& p7);
    public:
        uint32_t m_id;
        bool m_bConnected;
        
        int m_fd;
        EFDTYPE m_fdType;
        string m_ip;
        uint16_t m_serverPort;
        CCalcTimeTick m_connectdTime;
        bool m_bFirstConnect;
        CCalcTimeTick m_lastPackTime;
        bool m_bDeleteFlag;                 //标记之后,pluto包不再处理
        CPluto* m_curReceivePluto;          //析构函数要处理释放指针
        list<CPluto*> m_tobeSend;
        uint16_t m_unServerMbType;
        int m_nSendPos;                     //当send阻塞的时候,记录下次接着发送的位置
#ifdef __WEBSOCKET_CLIENT
        bool m_isFirstPluto;                //是否为第一个数据包，websocket第一个数据包是 "GET "， 对第一个数据包特殊处理
        bool m_isWebsocket;                 //是否为websocket协议，websocket协议数据包格式不一样, 接收和发送模式都不一样
        int m_wsRecvLen;                    //websocket帧列表总的接收长度
        list<CPluto*> m_wsRecvPlutoList;    //接收的websocket帧列表，为了合并帧用
#endif
    private:
        uint8_t m_uAuthz;          //是否已经通过认证

        CMailBox(const CMailBox&);
        CMailBox& operator=(const CMailBox&);
};

template<typename T1>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1);

    PushPluto(u);

    return true;
}

template<typename T1, typename T2>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2);

    PushPluto(u);

    return true;
}

template<typename T1, typename T2, typename T3>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3);

    PushPluto(u);

    //PrintHex16(u->GetRecvBuff(), u->GetLen());

    return true;
}

template<typename T1, typename T2, typename T3, typename T4>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3, p4);

    PushPluto(u);

    return true;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3, p4, p5);

    PushPluto(u);

    return true;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3, p4, p5, p6);

    PushPluto(u);

    return true;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6, const T7& p7)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3, p4, p5, p6, p7);

    PushPluto(u);

    return true;
}


#endif
