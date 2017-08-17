#ifndef __WORLD_GAMEAREA_HEAD__
#define __WORLD_GAMEAREA_HEAD__

#include "world.h"
#include "pluto.h"
#include "util.h"
#include "table_mgr.h"

class CWorldGameArea : public world
{
    public:
        CWorldGameArea();
        ~CWorldGameArea();
    public:
        int init(const char* pszEtcFile);
        int FromRpcCall(CPluto& u);
        void OnThreadRun();
        void OnServerStart();
        int OnFdClosed(int fd);
    private:
        int ProcClientLogin(T_VECTOR_OBJECT* p, int srcFd);
        int ProcClientUpdateUserInfo(T_VECTOR_OBJECT* p, int srcFd);
        int ProcReadUserInfoCallback(T_VECTOR_OBJECT* p);
        int ProcScoreReportCallback(T_VECTOR_OBJECT* p);
        int ProcConsumeSpecialGoldCallBack(T_VECTOR_OBJECT *p);
        int ProcTotalScoreReportCallBack(T_VECTOR_OBJECT *p);
		int ProcStartReportCallBack(T_VECTOR_OBJECT *p);
		int ProcLockOrUnlockReportCallBack(T_VECTOR_OBJECT *p);
		int ProcReportToTableManagerCallBack(T_VECTOR_OBJECT *p);
		int ProcReportTableStartCallBack(T_VECTOR_OBJECT *p);
        int ProcClientOnTick(T_VECTOR_OBJECT* p, int srcFd);
        int ProcClientSit(T_VECTOR_OBJECT* p, int srcFd);
        int ClientLoginResponse(int clientFd, int32_t retCode, const char* retErrorMsg);
        int ClientUpdateUserInfoResponse(int clientFd, int32_t retCode, const char* retErrorMsg);
        bool CheckClientRpc(CPluto& u);
        void CheckTaskListTimeOut();
        void ReportAreaInfoToMgr();
        int SendBulletin(T_VECTOR_OBJECT* p);
		void ReportStart2FS();
		void ClientSitResponse(int retCode, int tableHandle, int clientFd);
    public:
        inline SUserInfo* FindUserById(int userId)
        {
            map<int, SUserInfo*>::iterator iter = m_userId2userInfo.find(userId);
            if (m_userId2userInfo.end() == iter)
                return NULL;
            else
                return iter->second;
        }
        inline SUserInfo* FindUserByFd(int fd)
        {
            map<int, SUserInfo*>::iterator iter = m_fd2userInfo.find(fd);
            if(m_fd2userInfo.end() == iter)
                return NULL;
            else
                return iter->second;
        }

        inline void AddTask(CAreaTaskItemBase* pTask)
        {
            m_taskList.insert(make_pair(pTask->GetTaskId(), pTask));
        }
    private:
        map<int, SUserInfo*> m_fd2userInfo;                     //socket fd和userInfo的关联关系
        map<int, SUserInfo*> m_userId2userInfo;                 //userId和userInfo的关联关系
        map<uint32_t, CAreaTaskItemBase*> m_taskList;           //任务列表
        CCalcTimeTick m_checkTaskTime;                          //检测任务超时
        CCalcTimeTick m_reportNumTime;                          //定时上报服务器信息
        CCalcTimeTick m_checkUserTimeoutTime;                   //定时检测用户是否超时无数据包
		CCalcTimeTick m_checkReadRobotUserInfoTime;             //定时检测是否需要读取机器人信息

        CWorldGameArea(const CWorldGameArea&);
        CWorldGameArea& operator=(const CWorldGameArea&);

		bool m_tryReportStart2FS;								// 开启服务器时，上报游戏服务信息给FS
		
		bool m_hasReportStart2TableMgr;							// 开启服务时，上报清除该服务器下的所有多开信息
};




#endif
