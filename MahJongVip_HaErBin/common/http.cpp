#include "win32def.h"
#include "http.h"
#include "logger.h"
#include <stdio.h> 
#include <curl/curl.h> 
#include <string> 
#include <string.h>

using namespace std;

pthread_key_t g_curl_post_thread_key;   // 为了多线程调用curl

size_t write_string( void *buffer, size_t size, size_t nmemb, void *userp )
{
    int segsize = size * nmemb;
    *(string*) userp += string((char*) buffer);
    return segsize;
}

void set_share_handle(CURL* curl_handle)
{
    static CURLSH* share_handle = NULL;
    if (!share_handle)
    {
        share_handle = curl_share_init();
        curl_share_setopt(share_handle, CURLSHOPT_SHARE, CURL_LOCK_DATA_DNS);
    }
    curl_easy_setopt(curl_handle, CURLOPT_SHARE, share_handle);
    curl_easy_setopt(curl_handle, CURLOPT_DNS_CACHE_TIMEOUT, 60 * 5);
}



int GetUrl_new(const char* url, string& result)
{
    CURL *curl;
    CURLcode ret;
    string tmp;
    curl = curl_easy_init();
    set_share_handle(curl);

    if (!curl)
    {
        //LogError("reqUrl","couldn't init curl\n"); 
        return -1;
    }

    /* Tell curl the URL of the file we're going to retrieve */
    curl_easy_setopt(curl, CURLOPT_URL, url);
    //curl_easy_setopt(curl, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);

    /* Tell curl that we'll receive data to the function write_data, and 
    * also provide it with a context pointer for our error return. 
    */
    // curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *) &tmp);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_string);
    //curl_easy_setopt( curl, CURLOPT_TIMEOUT, 10 );
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L); //多线程必须屏蔽该信号
    curl_easy_setopt(curl, CURLOPT_DNS_USE_GLOBAL_CACHE, 1);
    //curl_easy_setopt(curl, CURLOPT_RESOLVE, host);


    /* Allow curl to perform the action */
    ret = curl_easy_perform(curl);

    /* Emit the page if curl indicates that no errors occurred */
    if (ret == 0) result = tmp;
    else
    {
        char a[16] ={0};
        sprintf(a, "error: %d\n", ret);
        result = a;
    }

    curl_easy_cleanup(curl);

    return ret;
}


int GetUrl(const char* url, string& result)
{
    return GetUrl_new(url, result);
}

/* 
* Simple curl application to read the index.html file from a Web site. 
*/
int reqUrl(const char* url)
{
    string result;
    return GetUrl_new(url, result);
}



//url  :"http://postit.example.com/moo.cgi");
//params: name=daniel&project=curl

int http_post(const char* url,const char*  params, string& result)
{
    CURL *curl;
    CURLcode ret;
    string tmp;

    /* get a curl handle */ 
    curl = (CURL *)pthread_getspecific(g_curl_post_thread_key);
    if(curl) {

        /* First set the URL that is about to receive our POST. This URL can
        just as well be a https:// URL if that is what should receive the
        data. */ 
        curl_easy_setopt(curl, CURLOPT_URL, url);

        // 连接复用
        /* enable TCP keep-alive for this transfer */
        curl_easy_setopt(curl, CURLOPT_TCP_KEEPALIVE, 1L);
        /* keep-alive idle time to 120 seconds */
        curl_easy_setopt(curl, CURLOPT_TCP_KEEPIDLE, 120L);
        /* interval time between keep-alive probes: 60 seconds */
        curl_easy_setopt(curl, CURLOPT_TCP_KEEPINTVL, 60L);

        /* Now specify the POST data */ 
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, params);

        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *) &tmp);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_string);

        /* Perform the request, res will get the return code */ 
        ret = curl_easy_perform(curl);

        /* Check for errors */ 

        if (ret == CURLE_OK) result = tmp;
        else
        {
            char a[16] ={0};
            sprintf(a, "error: %d\n", ret);
            result = a;
        }
    }
    else
    {
        LogInfo("http_post", "not found curl");
    }
    
    return 0;
}



