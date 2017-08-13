#ifndef __HTTP_HEAD__
#define __HTTP_HEAD__

#include <string>

extern pthread_key_t g_curl_post_thread_key;

extern int http_post(const char* url,const char*  params, std::string& result);

#endif

