/*----------------------------------------------------------------
// 模块描述：区域服务器管理器网络处理
//----------------------------------------------------------------*/

#include "epoll_areamgr.h"
#include "world_areamgr.h"
#include "signal.h"

CEpollAreaMgrServer::CEpollAreaMgrServer() : CEpollServer()
{

}

CEpollAreaMgrServer::~CEpollAreaMgrServer()
{

}

int CEpollAreaMgrServer::HandlePluto()
{
    CEpollServer::HandlePluto();

    return 0;
}


///////////////////////////////////////////////////////////////////////////




