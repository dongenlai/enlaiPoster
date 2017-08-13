#ifndef __DB_TASK_HEAD__
#define __DB_TASK_HEAD__

#include "pluto.h"
#include <list>
#include <pthread.h>

class CWorldDbMgr;

extern CPlutoList g_pluto_recvlist;
extern CPlutoList g_pluto_sendlist;
extern CWorldDbMgr& g_worldDbmgr;
extern bool g_bShutdown;


class CDbTask
{
    public:
        CDbTask(CWorldDbMgr& w);
        ~CDbTask();

    public:
        void Run();
    private:
        CWorldDbMgr& m_world;
};


#endif
