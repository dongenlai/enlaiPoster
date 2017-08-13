#include "epoll_areamgr.h"
#include "world_areamgr.h"
#include "world_select.h"
#include "debug.h"
#include "signal.h"
#include "world.h"
#include "pluto.h"
#include "util.h"
#include "http.h"
#include <curl/curl.h> 

world* g_pTheWorld = new CWorldAreaMgr();

static void free_curl_handle_data(void * arg)
{
    curl_easy_cleanup((CURL*)arg);
}

bool InitThreadPostCurlPrivateData()
{
    // 初始化线程私有数据
    CURL* pThreadCurl = curl_easy_init();
    if (!pThreadCurl)
    {
        LogError("InitThreadPostCurlPrivateData", "curl_easy_init failed");
        return false;
    }
    int nRet = pthread_setspecific(g_curl_post_thread_key, (void *)pThreadCurl);
    if (nRet) {
        LogError("InitThreadPostCurlPrivateData", "pthread_setspecific failed: %d\n", nRet);
        return false;   
    }

    return true;
}


int main(int argc, char* argv[])
{
    if(argc < 3)
    {
        printf("Usage:%s etc_fn server_id \n", argv[0]);
        return -1;
    }

    srand((unsigned int)time(NULL));

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

    curl_global_init(CURL_GLOBAL_ALL);
    // pthread_key_create only once
    nRet = pthread_key_create(&g_curl_post_thread_key, free_curl_handle_data);
    if (nRet) {
        printf("pthread_key_create failed: %d\n", nRet);
        return false;
    }
    if(!InitThreadPostCurlPrivateData())
        return -3;

    CEpollAreaMgrServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&the_world);
    the_world.SetServer(&s);

    uint16_t unPort = the_world.GetServerPort(nServerId);
    s.Service("", unPort);

    curl_global_cleanup();
}
