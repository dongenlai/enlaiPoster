#ifndef __EPOLL_GAMEAREA_HEAD__
#define __EPOLL_GAMEAREA_HEAD__

#include "epoll_server.h"


class CEpollGameAreaServer : public CEpollServer
{
    public:
        CEpollGameAreaServer();
        ~CEpollGameAreaServer();

    protected:
        int HandlePluto();

};


#endif
