#ifndef __WORLD__BASE__HEAD__
#define __WORLD__BASE__HEAD__

#include "util.h"
#include "rpc_mogo.h"
#include "exception.h"
#include "epoll_server.h"


class CMailBoxManager
{
    public:
        CMailBoxManager();
        ~CMailBoxManager();
    public:
        // throw exception
        bool init(CCfgReader& cfg);
    public:
        inline list<CMailBox*>& GetMailboxs()
        {
            return m_mbs;
        }
    private:
        list<CMailBox*> m_mbs;
};

class world
{
    public:
        world();
        virtual ~world();
    public:
        virtual void Clear();
        virtual int init(const char* pszEtcFile);
        virtual int OnFdClosed(int fd);
        virtual int FromRpcCall(CPluto& u);
        virtual void OnThreadRun();
        virtual void OnServerStart();
        //判断一个IP的连接是否可以连进来该进程
        virtual bool IsCanAcceptedClient(const string& strClientAddr)
        {
            return true;
        }
    protected:
        //关闭服务器
        virtual int ShutdownServer(T_VECTOR_OBJECT* p);
        //检查一个rpc调用是否合法
        virtual bool CheckClientRpc(CPluto& u);
    protected:
        void InitMailboxMgr();
        void InitTrustedClient();
    public:
		uint32_t GetMailboxId();
        CMailBox* GetServerMailbox(uint32_t nServerId);
        void SetServer(CEpollServer* s);
        CEpollServer* GetServer();
        //根据server_id获取服务器绑定端口
		uint16_t GetServerPort(uint32_t sid);
        //判断一个客户端连接的地址是否来自于可信任地址列表
        bool IsTrustedClient(const string& strClientAddr);
        //将指定的 pluto 发给 对应的服务器mailbox
        bool PushPlutoToMailbox(uint32_t nServerId, CPluto* u);

        inline CRpcUtil& GetRpcUtil()
        {
            return m_rpc;
        }
        inline CCfgReader* GetCfgReader()
        {
            return m_cfg;
        }
        inline CMailBoxManager& GetMbMgr()
        {
            return m_mbMgr;
        }
    public:
        template<typename T1>
		void RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1);

        template<typename T1, typename T2>
		void RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2);

        template<typename T1, typename T2, typename T3>
		void RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3);

        template<typename T1, typename T2, typename T3, typename T4>
		void RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4);

        template<typename T1, typename T2, typename T3, typename T4, typename T5>
		void RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5);

        template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
		void RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6);
    protected:
        CCfgReader* m_cfg;
        set<string> m_trustedClients;
        CRpcUtil m_rpc;
        CEpollServer* the_server;
        CMailBoxManager m_mbMgr;
};


//从VOBJECT*中读取字段
#define VOBJECT_GET_SSTR(p) *(p->vv.s)
#define VOBJECT_GET_STR(p) p->vv.s->c_str()
#define VOBJECT_GET_U8(p) p->vv.u8
#define VOBJECT_GET_U16(p) p->vv.u16
#define VOBJECT_GET_U32(p) p->vv.u32
#define VOBJECT_GET_U64(p) p->vv.u64
#define VOBJECT_GET_I8(p) p->vv.i8
#define VOBJECT_GET_I16(p) p->vv.i16
#define VOBJECT_GET_I32(p) p->vv.i32
#define VOBJECT_GET_I64(p) p->vv.i64
#define VOBJECT_GET_F32(p) p->vv.f32
#define VOBJECT_GET_EMB(p) p->vv.emb
#define VOBJECT_GET_BLOB(x) (x->vv.p)


template<typename T1>
void world::RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1)
{
    if(nServerId == GetMailboxId())
    {
        //本进程
        CPluto* u = new CPluto;
        m_rpc.Encode(*u, msg_id, p1);
        GetServer()->AddLocalRpcPluto(u);
    }
    else
    {
        CMailBox* mb = GetServerMailbox(nServerId);
        if(mb)
        {
            mb->RpcCall(m_rpc, msg_id, p1);
        }
        else
        {
            LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
        }
    }
}

template<typename T1, typename T2>
void world::RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
{
    if(nServerId == GetMailboxId())
    {
        //本进程
        CPluto* u = new CPluto;
        m_rpc.Encode(*u, msg_id, p1, p2);
        GetServer()->AddLocalRpcPluto(u);
    }
    else
    {
        CMailBox* mb = GetServerMailbox(nServerId);
        if(mb)
        {
            mb->RpcCall(m_rpc, msg_id, p1, p2);
        }
        else
        {
            LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
        }
    }
}

template<typename T1, typename T2, typename T3>
void world::RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
{
    if(nServerId == GetMailboxId())
    {
        //本进程
        CPluto* u = new CPluto;
        m_rpc.Encode(*u, msg_id, p1, p2, p3);
        GetServer()->AddLocalRpcPluto(u);
    }
    else
    {
        CMailBox* mb = GetServerMailbox(nServerId);
        if(mb)
        {
            mb->RpcCall(m_rpc, msg_id, p1, p2, p3);
        }
        else
        {
            LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
        }
    }
}

template<typename T1, typename T2, typename T3, typename T4>
void world::RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
{
    if(nServerId == GetMailboxId())
    {
        //本进程
        CPluto* u = new CPluto;
        m_rpc.Encode(*u, msg_id, p1, p2, p3, p4);
        GetServer()->AddLocalRpcPluto(u);
    }
    else
    {
        CMailBox* mb = GetServerMailbox(nServerId);
        if(mb)
        {
            mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4);
        }
        else
        {
            LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
        }
    }
}

template<typename T1, typename T2, typename T3, typename T4, typename T5>
void world::RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
{
    if(nServerId == GetMailboxId())
    {
        //本进程
        CPluto* u = new CPluto;
        m_rpc.Encode(*u, msg_id, p1, p2, p3, p4, p5);
        GetServer()->AddLocalRpcPluto(u);
    }
    else
    {
        CMailBox* mb = GetServerMailbox(nServerId);
        if(mb)
        {
            mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4, p5);
        }
        else
        {
            LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
        }
    }
}

template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
void world::RpcCall(uint32_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
{
    if(nServerId == GetMailboxId())
    {
        //本进程
        CPluto* u = new CPluto;
        m_rpc.Encode(*u, msg_id, p1, p2, p3, p4, p5, p6);
        GetServer()->AddLocalRpcPluto(u);
    }
    else
    {
        CMailBox* mb = GetServerMailbox(nServerId);
        if(mb)
        {
            mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4, p5, p6);
        }
        else
        {
            LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
        }
    }
}


#endif
