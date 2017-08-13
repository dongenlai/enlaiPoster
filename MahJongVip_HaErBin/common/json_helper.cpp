#include "json_helper.h"
#include "my_stl.h"
#include "util.h"

AutoJsonHelper::AutoJsonHelper(string& strJson)
{
    m_json = cJSON_Parse(strJson.c_str());           
}

AutoJsonHelper::~AutoJsonHelper()
{
    if(NULL != m_json)
    {
        cJSON_Delete(m_json);
    }  
}

bool AutoJsonHelper::GetJsonIntItem(const string & node_name, int & result)
{
    result = 0;

    cJSON* obj_find = FindJsonOjbectByKey(node_name);
    if(NULL == obj_find)
        return false;
    if (cJSON_Number != obj_find->type)
        return false;

    result = obj_find->valueint;
    return true;
}

cJSON* AutoJsonHelper::FindJsonOjbectByKey(const string & node_name)
{
    if(NULL == m_json)
    {
        return NULL;
    }
    if (cJSON_Object != m_json->type)
        return NULL;

    cJSON* obj_find = m_json;
    list<string> l = SplitString(node_name, '.');
    if (l.size() < 1)
        return NULL;

    list<string>::const_iterator iter = l.begin();
    for(; iter != l.end(); ++iter)
    {
        obj_find = cJSON_GetObjectItem(obj_find, iter->c_str());
        if (NULL == obj_find)
            return NULL;
    }

    return obj_find;
}

cJSON* FindJsonOjbectBy1Key(cJSON* pJson, const string & node_name)
{
    if(NULL == pJson)
        return NULL;
    if (cJSON_Object != pJson->type)
        return NULL;
    if (node_name.length() < 1)
        return NULL;

    return cJSON_GetObjectItem(pJson, node_name.c_str());
}

void FindJsonItemStrValue(cJSON* pJson, const string & node_name, string& retStr)
{
    retStr = "";
    cJSON* pJsonFind = FindJsonOjbectBy1Key(pJson, node_name);
    if (NULL == pJsonFind)
        return;
    if (cJSON_String != pJsonFind->type)
        return;
    if (NULL == pJsonFind->valuestring)
        return;

    retStr = pJsonFind->valuestring;
}

void FindJsonItemStrValueForObject(cJSON* pJson, const string & node_name, string& retStr)
{
    retStr = "";
    cJSON* pJsonFind = FindJsonOjbectBy1Key(pJson, node_name);
    if (NULL == pJsonFind)
        return;
    if (cJSON_Object != pJsonFind->type)
        return;

    char* pJsStr = cJSON_PrintUnformatted(pJsonFind);
    if(!pJsStr)
        return;
    retStr = pJsStr;
    cJSON_free(pJsStr);
}

void FindJsonItemIntValue(cJSON* pJson, const string & node_name, int& retInt)
{
    retInt = 0;
    cJSON* pJsonFind = FindJsonOjbectBy1Key(pJson, node_name);
    if (NULL == pJsonFind)
        return;
    if (cJSON_Number != pJsonFind->type)
        return;

    retInt = pJsonFind->valueint;
}

void FindJsonItemInt64Value(cJSON* pJson, const string & node_name, int64_t& retInt64)
{
    retInt64 = 0;
    cJSON* pJsonFind = FindJsonOjbectBy1Key(pJson, node_name);
    if (NULL == pJsonFind)
        return;
    if (cJSON_Number != pJsonFind->type)
        return;

    retInt64 = (int64_t)pJsonFind->valuedouble;
}

cJSON* FindJsonItemArrayValue(cJSON* pJson, const string & node_name)
{
    cJSON* pJsonFind = FindJsonOjbectBy1Key(pJson, node_name);
    if (NULL == pJsonFind)
        return NULL;
    if (cJSON_Array != pJsonFind->type)
        return NULL;

    return pJsonFind;
}