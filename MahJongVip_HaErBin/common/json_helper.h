#ifndef __JSON_HELPER__
#define __JSON_HELPER__


#include <string>
#include <stdint.h>
#include "cjson.h"
using namespace std;


//json解析类, 局部变量可以自动释放
class AutoJsonHelper 
{
public:
    AutoJsonHelper(string& strJson);
    ~AutoJsonHelper();

    inline cJSON* GetJsonPtr() const
    {
        return m_json;
    }
public:
    //获取子节点的int值, int64要用double表示，强转int64
    bool GetJsonIntItem(const string & node_name, int & result);
private:
    //获取多级子节点的节点 {"access_token":{"name1":"xxx"},"tabSeries":"xxx"}: ("access_token","name1")="xxx"
    //key不区分大小写, 如果类型不一致，查不到结果 
    //node_name多级以.分割
    cJSON* FindJsonOjbectByKey(const string & node_name);
private:
    cJSON* m_json;
};

//获取单个nodename的节点
extern cJSON* FindJsonOjbectBy1Key(cJSON* pJson, const string & node_name);
extern void FindJsonItemStrValue(cJSON* pJson, const string & node_name, string& retStr);
extern void FindJsonItemStrValueForObject(cJSON* pJson, const string & node_name, string& retStr);
extern void FindJsonItemIntValue(cJSON* pJson, const string & node_name, int& retInt);
extern void FindJsonItemInt64Value(cJSON* pJson, const string & node_name, int64_t& retInt64);
extern cJSON* FindJsonItemArrayValue(cJSON* pJson, const string & node_name);


#endif
