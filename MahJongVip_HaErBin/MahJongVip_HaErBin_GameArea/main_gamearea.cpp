#include "epoll_gamearea.h"
#include "world_gamearea.h"
#include "global_var.h"
#include "debug.h"
#include "signal.h"
#include "world.h"
#include "pluto.h"
#include "util.h"
#include "http.h"
#include "type_mogo.h"

int main(int argc, char* argv[])
{
    if(argc < 3)
    {
        printf("Usage:%s etc_fn server_id \n", argv[0]);
        return -1;
    }

    srand((unsigned int)time(NULL));
    g_taskIdAlloctor = rand();

    //命令行参数,依次为: 配置文件路径,server_id
    const char* pszEtcFn = argv[1];
	uint32_t nServerId = (uint32_t)atoi(argv[2]);

    signal(SIGPIPE, SIG_IGN);
    CDebug::Init();
    
    world& the_world = *GetWorld();
    int nRet = the_world.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("world init error:%d\n", nRet);
        return nRet;
    }

    CEpollGameAreaServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&the_world);
    the_world.SetServer(&s);

    uint16_t unPort = the_world.GetServerPort(nServerId);
    s.Service("", unPort);

    delete g_pTheWorld;
    delete g_config_area;
    delete g_table_mgr;
    delete g_logic_mgr;
}
