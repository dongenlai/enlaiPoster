/*----------------------------------------------------------------
// 模块描述：数据服务网络处理
//----------------------------------------------------------------*/

#include "epoll_dbmgr.h"
#include "world_dbmgr.h"
#include "signal.h"

CPlutoList g_pluto_recvlist;
CPlutoList g_pluto_sendlist;
bool g_bShutdown = false;

CEpollDbMgrServer::CEpollDbMgrServer() : CEpollServer()
{

}

CEpollDbMgrServer::~CEpollDbMgrServer()
{

}

void CEpollDbMgrServer::AddRecvMsg(CPluto* u)
{
    //LogDebug("CEpollDbMgrServer::AddRecvMsg", "u.GenLen()=%d", u->GetLen());
    g_pluto_recvlist.PushPluto(u);
}

int CEpollDbMgrServer::HandleSendPluto()
{
    enum { SEND_COUNT = 1000, };
    CPluto* u;
    int i = 0;
    while(u = g_pluto_sendlist.PopPluto())
    {
        // 判断fd是否存在, 这里和接收同一个线程，fd列表不用加锁
        CMailBox* mb = GetFdMailbox(u->GetDstFd());
        if(mb)
        {
            //LogDebug("CEpollDbMgrServer::HandleSendPluto", "u.GenLen()=%d", u->GetLen());
            u->SetMailbox(mb);
            mb->PushPluto(u);
        }
        else
        {
            // 目的fd已经断开，需要释放数据包内存
            LogDebug("CEpollDbMgrServer::HandleSendPluto", "fd=%d not exists", u->GetDstFd());
            delete u;
        }
        //每次只发送一定条数
        if(++i > SEND_COUNT)
        {
            break;
        }
    }

    return CEpollServer::HandleSendPluto();
}


///////////////////////////////////////////////////////////////////////////




