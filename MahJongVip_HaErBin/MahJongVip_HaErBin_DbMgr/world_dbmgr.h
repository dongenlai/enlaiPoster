#ifndef __WORLD_DBMGR_HEAD__
#define __WORLD_DBMGR_HEAD__

#include "world.h"
#include "pluto.h"


class CWorldDbMgr : public world
{
    public:
        CWorldDbMgr();
        ~CWorldDbMgr();

        inline uint8_t GetTaskThreadCount() const
        {
            return m_task_thread_count;
        }
    public:
        int init(const char* pszEtcFile);
        int FromRpcCall(CPluto& u);
        bool IsCanAcceptedClient(const string& strClientAddr);
        int OnFdClosed(int fd);
    protected:
        // 检测包类型
        bool CheckClientRpc(CPluto& u);
    private:
        // 数据包处理
        int ReadUserInfo(T_VECTOR_OBJECT* p, int srcFd);
        int ScoreReport(T_VECTOR_OBJECT* p, int srcFd);
        int ConsumeSpecialGold(T_VECTOR_OBJECT* p, int srcFd);
		int LockOrUnLockUser(T_VECTOR_OBJECT* p, int srcFd);
		int TotalScoreReport(T_VECTOR_OBJECT* p, int srcFd);
		int ReportToTableManager(T_VECTOR_OBJECT* p, int srcFd);
		int ReportTableStartState(T_VECTOR_OBJECT* p, int srcFd);

        // 从cis获得用户信息字符串
		void CisGetUserInfo(int userId, int gameLock, int gameRoomId, string& retStr);
    private:
        CWorldDbMgr(const CWorldDbMgr&);
        CWorldDbMgr& operator=(const CWorldDbMgr&);

        uint8_t m_task_thread_count;
        string m_cis_url;
        string m_cis_key;
        string m_aes_key;
};


#endif
