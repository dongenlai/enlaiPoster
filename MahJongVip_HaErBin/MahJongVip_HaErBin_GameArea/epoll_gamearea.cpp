/*----------------------------------------------------------------
// 模块描述：区域服务网络处理
//----------------------------------------------------------------*/

#include "epoll_gamearea.h"
#include "world_gamearea.h"
#include "signal.h"

CEpollGameAreaServer::CEpollGameAreaServer() : CEpollServer()
{

}

CEpollGameAreaServer::~CEpollGameAreaServer()
{

}

int CEpollGameAreaServer::HandlePluto()
{
    CEpollServer::HandlePluto();

    return 0;
}


///////////////////////////////////////////////////////////////////////////




