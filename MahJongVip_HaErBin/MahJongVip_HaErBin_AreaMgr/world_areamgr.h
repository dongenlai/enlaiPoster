#ifndef __WORLD_AREAMGR_HEAD__
#define __WORLD_AREAMGR_HEAD__

#include "world.h"
#include "pluto.h"

class CWorldAreaMgr : public world
{
    public:
        CWorldAreaMgr();
        ~CWorldAreaMgr();

    public:
        int init(const char* pszEtcFile);
        int FromRpcCall(CPluto& u);
        void OnThreadRun();
        void OnServerStart();
        bool IsCanAcceptedClient(const string& strClientAddr);
        int OnFdClosed(int fd);
    protected:
        // 检测包类型
        bool CheckClientRpc(CPluto& u);
    private:
        // area定时发送,刷新信息
        int UpdateArea(T_VECTOR_OBJECT* p, int srcFd);
        // 发送公告
        int SendBulletin(T_VECTOR_OBJECT* p);
        // 上报区域列表
        void ReportAreaServerList();
		// 向fs上报游戏服务器启动时状态
		int ReportGameAreaStart2Fs(T_VECTOR_OBJECT* p, int srcFd);
    private:
        string m_post_serverlist_url;               // 向分发网站提交serverlist的地址
		string m_post_ontick_url;					// 向分发网站提交心跳包的地址
		map<int, string> m_fd2areainfo;             // fd和区域信息的关联关系
        CCalcTimeTick m_reportTime;                 // 上报时间

        CWorldAreaMgr(const CWorldAreaMgr&);
        CWorldAreaMgr& operator=(const CWorldAreaMgr&);
};




#endif
