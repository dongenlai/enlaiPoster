#include "db_task.h"
#include "epoll_dbmgr.h"
#include "world_dbmgr.h"
#include "world_select.h"
#include "debug.h"
#include "signal.h"
#include "world.h"
#include "pluto.h"
#include "util.h"
#include "http.h"
#include <curl/curl.h> 

world* g_pTheWorld = new CWorldDbMgr();
CWorldDbMgr& g_worldDbmgr = (CWorldDbMgr&)(*g_pTheWorld);

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

void* RunDbTask(void* arg)
{
    if(!InitThreadPostCurlPrivateData())
        return NULL;

    CDbTask t(g_worldDbmgr);
    t.Run();
    return NULL;
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

    //初始化锁
    g_logger_mutex = new pthread_mutex_t;
    if(!g_pluto_recvlist.InitMutex() || !g_pluto_sendlist.InitMutex()
        || pthread_mutex_init(g_logger_mutex, NULL) != 0 )
    {
        printf("pthead_mutext_t init error:%d,%s\n", errno, strerror(errno));
        return -1;
    }
    
    world& the_world = *GetWorld();
    int nRet = the_world.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("world init error:%d\n", nRet);
        return nRet;
    }

    // 应该在程序开始时调用初始化函数. 虽然不调用这个初始化函数, libcurl会在curl_easy_init()函数中自动调用. 但在多线程处理时, 可能会出现多次自动调用的情况
    curl_global_init(CURL_GLOBAL_ALL);
    // pthread_key_create only once
    nRet = pthread_key_create(&g_curl_post_thread_key, free_curl_handle_data);
    if (nRet) {
        printf("pthread_key_create failed: %d\n", nRet);
        return false;
    }
    // dbmgr主线程不会调用curl的函数

    CEpollDbMgrServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&the_world);
    the_world.SetServer(&s);

    // 处理数据包线程
    vector<pthread_t> pid_list;
    {
        pthread_t pid;
        int len = g_worldDbmgr.GetTaskThreadCount();
        for(int i=0; i<len; ++i)
        {
            if(pthread_create(&pid, NULL, RunDbTask, NULL) != 0)
            {
                printf("pthread_create error:%d,%s\n", errno, strerror(errno));
                return -2;
            }
            pid_list.push_back(pid);
        }
    }

    uint16_t unPort = the_world.GetServerPort(nServerId);
    s.Service("", unPort);
    // 防止监听失败时，服务无法停止。
    g_bShutdown = true;

    // 等待所有线程结束
    for(size_t i = 0; i < pid_list.size(); ++i)
    {
        if(pthread_join(pid_list[i], NULL) != 0)
        {
            printf("pthread_join error:%d,%s\n", errno, strerror(errno));
            return -3;
        }
    }

    curl_global_cleanup();
}
