#ifndef __EPOLL_DBMGR_HEAD__
#define __EPOLL_DBMGR_HEAD__

#include "epoll_server.h"


class CEpollDbMgrServer : public CEpollServer
{
    public:
        CEpollDbMgrServer();
        ~CEpollDbMgrServer();
    public:
        void AddRecvMsg(CPluto* u);
    protected:
        int HandleSendPluto();

        inline int HandlePluto()
        {
            return 0;
        }

};


#endif
