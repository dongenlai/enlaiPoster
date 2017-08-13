/*----------------------------------------------------------------
// 模块名：logger
// 模块描述：通用日志模块
//----------------------------------------------------------------*/

#include "logger.h"
#include "mutex.h"

CLogger g_logger;  //全局变量

pthread_mutex_t* g_logger_mutex = NULL;

CLogger::CLogger() : m_socket(0)
{
    memset(&m_toAddr, 0, sizeof(m_toAddr));
}


CLogger::~CLogger()
{
    ::close(m_socket);
}

void CLogger::InitCfg(CCfgReader& cfg)
{
    char szLogger[16] = "logger";

    m_toAddr.sin_family = AF_INET;
    m_toAddr.sin_addr.s_addr = inet_addr(cfg.GetValue(szLogger, "ip").c_str());
    m_toAddr.sin_port = htons(atoi(cfg.GetValue(szLogger, "port").c_str()));
        
    m_socket = socket(AF_INET, SOCK_DGRAM, 0);
    MogoSetNonblocking(m_socket);
}

void CLogger::SendLog(const char * pMsg, size_t len)
{
    if(g_logger_mutex == NULL)
    {
        ::sendto(m_socket, pMsg, len, 0, (struct sockaddr *)&m_toAddr, sizeof(m_toAddr));
    }
    else
    {
        //dbmgr的多线程日志要加锁
        CMutexGuard gm(*g_logger_mutex);
        ::sendto(m_socket, pMsg, len, 0, (struct sockaddr *)&m_toAddr, sizeof(m_toAddr));
    }
}

//获得当前时间的格式化的时分秒毫秒 HH:MM:SS.UUUUUU
void _get_time_hmsu_head(char* s, size_t n)
{
    struct timeval tv;
    if(gettimeofday(&tv, NULL)==0)
    {
        time_t& t = tv.tv_sec;
        struct tm* tm2 = localtime(&t);

        snprintf(s, n, "%02d:%02d:%02d.%06d", tm2->tm_hour, tm2->tm_min, tm2->tm_sec, tv.tv_usec);
    }
    else
    {
        snprintf(s, n, "??:??:??.??????");
    }
}

template <size_t size>
void _Log(char (&strDest)[size], const char* section, const char* key, const char* msg, va_list& ap)
{
    static const char _hmsu_head[] = "17:04:10.762177";
    enum {_hmsu_head_size = sizeof(_hmsu_head)+1,};

    char szHmsu[32];
    memset(szHmsu, 0, 32);

    _get_time_hmsu_head(szHmsu, sizeof(szHmsu));

    int n1 = snprintf(strDest, (int)size, "%s  [%s][%s]", szHmsu, section, key);
    if(n1 > 0 && n1 < (int)size)
    {
        int n2 = vsnprintf(strDest+n1, (int)size-n1, msg, ap);
        if(n2 > 0 && (n1+n2)<(int)size)
        {
            strDest[n1+n2] = '\0';
        }

    }
}

void Log2Udp(const char* section, const char* key, const char* msg, va_list& ap, int nFileType = 0)
{
    char szTmp[MAX_LOG_BUFF_SIZE];
    memset(szTmp, 0, MAX_LOG_BUFF_SIZE * sizeof(char));

    _Log(szTmp, section, key, msg, ap);

    g_logger.SendLog(szTmp, strlen(szTmp));
}

void LogDebug(const char* key, const char* msg, ...)
{
    va_list ap;
    memset(&ap, 0, sizeof ap);

    va_start(ap, msg);
    Log2Udp("DEBUG   ", key, msg, ap);
    va_end(ap);
}

void LogInfo(const char* key, const char* msg, ...)
{
    va_list ap;
    memset(&ap, 0, sizeof ap);

    va_start(ap, msg);
    Log2Udp("INFO    ", key, msg, ap);
    va_end(ap);
}

void LogWarning(const char* key, const char* msg, ...)
{
    va_list ap;
    memset(&ap, 0, sizeof ap);

    va_start(ap, msg);
    Log2Udp("WARNING ", key, msg, ap);
    va_end(ap);
}

void LogError(const char* key, const char* msg, ...)
{
    va_list ap;
    memset(&ap, 0, sizeof ap);

    va_start(ap, msg);
    Log2Udp("ERROR   ", key, msg, ap);
    va_end(ap);
}

void LogCritical(const char* key, const char* msg, ...)
{
    va_list ap;
    memset(&ap, 0, sizeof ap);

    va_start(ap, msg);
    Log2Udp("CRITICAL", key, msg, ap);
    va_end(ap);
}

void LogScript(const char* level, const char* msg, ...)
{
    va_list ap;
    memset(&ap, 0, sizeof ap);

    va_start(ap, msg);
    Log2Udp("SCRIPT  ", level, msg, ap);
    va_end(ap);
}

void Error(const char* level, const char* msg, ...)
{
    va_list ap;
    memset(&ap, 0, sizeof ap);

    va_start(ap, msg);
    Log2Udp("ERROR  ", level, msg, ap, 1);
    va_end(ap);
}
