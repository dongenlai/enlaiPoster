#include "win32def.h"
#include "time.h"
#include "db_task.h"
#include "world_dbmgr.h"


CDbTask::CDbTask(CWorldDbMgr& w) : m_world(w)
{

}

CDbTask::~CDbTask()
{

}

void CDbTask::Run()
{
    for(;;)
    {
        CPluto* u = g_pluto_recvlist.PopPluto();
        if(u == NULL)
        {
            usleep(50000);
        }
        else
        {
            m_world.FromRpcCall(*u);
            delete u;
        }

        if(g_bShutdown)
        {
            //如果设置了退出标记并且已经没有数据需要处理,则退出
            if(g_pluto_recvlist.Empty())
            {
                LogInfo("db_task.quit", "pid=%d", (int)pthread_self());

                break;
            }
        }
    }
}

