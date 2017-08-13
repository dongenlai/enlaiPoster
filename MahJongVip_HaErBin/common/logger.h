#ifndef __LOGGER__HEAD__
#define __LOGGER__HEAD__

#include "win32def.h"
#include "my_stl.h"
#include "net_util.h"
#include "cfg_reader.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <time.h>
#include <string>
#include <map>
#include <fstream>
#include <iostream>
#include <ostream>
#include <sys/time.h>

using std::ofstream;
using std::ostream;
using std::ios;


class CLogger
{
    public:
        CLogger();
        ~CLogger();

    public:
        void InitCfg(CCfgReader& cfg);
        void SendLog(const char * pMsg, size_t len);
    private:
        int m_socket;
        struct sockaddr_in m_toAddr;
};

enum {MAX_LOG_BUFF_SIZE = 1024,};

//extern void Log(const char* section, const char* key, const char* msg, va_list& ap);
extern void LogDebug(const char* key, const char* msg, ...);
extern void LogInfo(const char* key, const char* msg, ...);
extern void LogWarning(const char* key, const char* msg, ...);
extern void LogError(const char* key, const char* msg, ...);
extern void LogCritical(const char* key, const char* msg, ...);
extern void LogScript(const char* level, const char* msg, ...);

extern void Error(const char* level, const char* msg, ...);

extern CLogger g_logger;

//g_logger对应的线程锁
extern pthread_mutex_t* g_logger_mutex;


#endif
