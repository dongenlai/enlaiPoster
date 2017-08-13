#ifndef __EPOLL_AREAMGR_HEAD__
#define __EPOLL_AREAMGR_HEAD__

#include "epoll_server.h"


class CEpollAreaMgrServer : public CEpollServer
{
    public:
        CEpollAreaMgrServer();
        ~CEpollAreaMgrServer();

    protected:
        int HandlePluto();

};


#endif
