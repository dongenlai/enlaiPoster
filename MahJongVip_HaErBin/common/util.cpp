/*----------------------------------------------------------------
// 模块名：util
// 模块描述：常用函数集合
//----------------------------------------------------------------*/

#include "win32def.h"
#include "logger.h"
#include "util.h"
#include "md5.h"
#include "base64.h"
#include <stdarg.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <openssl/aes.h>
#include <math.h>
#include <limits.h>

using namespace std;



string& Ltrim(string& s)
{
    int (*func)(int) = isspace;

    string::iterator iter;
    iter = find_if(s.begin(), s.end(), not1(ptr_fun(func)));
    s.erase(s.begin(), iter);

    return s;
}


string& Rtrim(string& s)
{
    int (*func)(int) = isspace;

    string::reverse_iterator iter;
    iter = find_if(s.rbegin(), s.rend(), not1(ptr_fun(func)));
    s.erase(iter.base(), s.end());

    return s;
}


bool IsDigitStr(const char* pszStr)
{
    if(pszStr == NULL)
    {
        return false;
    }

    size_t nLen = strlen(pszStr);
    for(size_t i = 0; i < nLen; ++i)
    {
        if(!isdigit(pszStr[i]))
        {
            return false;
        }
    }

    return true;
}

int GetAreaNumBy6TableNum(string& tableNum, int& tableHandle)
{
    tableHandle = -1;
    if (tableNum.size() != 6)
        return -1;
    if (!IsDigitStr(tableNum.c_str()))
        return -1;
    int numAry[6];
    for (int i = 0; i < 6; ++i)
    {
        numAry[i] = tableNum[i] - '0';
    }
    for (int i = 0; i < 3; ++i)
    {
        numAry[i] = ((numAry[i] + 10) - (numAry[3 + i] * 7 % 10)) % 10;
    }
    int ret = numAry[0] * 100 + numAry[1] * 10 + numAry[2];
    tableHandle = numAry[3] * 100 + numAry[4] * 10 + numAry[5];
    return ret;
}

string GetTableNumByHandle(int areaNum, int tableHandle)
{
    int numAry[6];
    for (int i = 3 - 1; i >= 0; --i)
    {
        numAry[i] = areaNum % 10;
        areaNum /= 10;
    }
    for (int i = 6 - 1; i >= 3; --i)
    {
        numAry[i] = tableHandle % 10;
        tableHandle /= 10;
    }
    for (int i = 0; i < 3; ++i)
    {
        numAry[i] = (numAry[i] + (numAry[3 + i] * 7 % 10)) % 10;
    }

    string ret = "123456";
    for (int i = 0; i < 6; ++i)
    {
        ret[i] = numAry[i] + '0';
    }

    return ret;
}


bool IsFileExist(const string& strFileName)
{
    return IsFileExist(strFileName.c_str());
}

bool IsFileExist(const char* pszFileName)
{
    bool bExist = false;

    ifstream iFile(pszFileName, ios::in);
    if(iFile.is_open())
    {
        bExist = true;
        iFile.close();
    }

    return bExist;
}

#define PI                      3.14159265
#define EARTH_RADIUS            6378137.0               //地球近似半径

// 求弧度
double radian(double d)
{
    return d * PI / 180.0;   //角度1˚ = π / 180
}

//计算距离 0.0,0.0 和任何点的距离都是 maxint
int get_distance(double weidu1, double jingdu1, double weidu2, double jingdu2)
{
    if(0.0 == weidu1 && 0.0 == jingdu1)
        return INT_MAX;
    if(0.0 == weidu2 && 0.0 == jingdu2)
        return INT_MAX;

    double radLat1 = radian(weidu1);
    double radLat2 = radian(weidu2);
    double a = radLat1 - radLat2;
    double b = radian(jingdu1) - radian(jingdu2);

    double dst = 2 * asin((sqrt(pow(sin(a / 2), 2) + cos(radLat1) * cos(radLat2) * pow(sin(b / 2), 2) )));
    dst = dst * EARTH_RADIUS;

    return (int)dst;
}

//替换string中第一次出现的某个部分
string& xReplace(string& s1, const char* pszSrc, const char* pszRep)
{
    string::size_type nPos1 = s1.find(pszSrc);
    if(nPos1 == string::npos)
    {
        return s1;
    }

    s1.replace(nPos1, strlen(pszSrc), pszRep);
    return s1;
}

//删除字符串右边的空格
char* Rtrim(char* p)
{
    if(p==NULL)
    {
        return p;
    }

    size_t n = strlen(p);
    if(n==0)
    {
        return p;
    }

    char* q = p + n - 1;

    while(isspace(*q))
    {
        --q;
    }

    *(q+1) = '\0';

    return p;
}

//删除字符串左边的空格
char* Ltrim(char* p)
{
    if(p==NULL)
    {
        return p;
    }

    char* q = p;

    while(isspace(*q))
    {
        ++q;
    }

    if(p!=q)
    {
        while(*p++ = *q++) {}
    }

    return p;
}

void AesDecryptStr(const string& base64Str, const string& aesKey, string& retStr)
{
    retStr = "";
    if(base64Str.size() < 1 || aesKey.size() < 1)
        return;

    char* buffer = new char[base64Str.size()];
    int retLen = 0;
    base64_decode(base64Str, (unsigned char*)buffer, retLen);
    string srcStr(buffer, retLen);
    delete [] buffer;

    AES_KEY aesK;  
    if(AES_set_decrypt_key((const unsigned char*)aesKey.c_str(), 128, &aesK) < 0)  
        return;  

    int len=srcStr.size();  
    if (len % AES_BLOCK_SIZE != 0)
        return;
    retStr.resize(len);
    unsigned char ivec[16] = {0x12,0x34,0x56,0x78,0x55,0x26,0x32,0x62,0x12,0x34,0x56,0x78,0x73,0x79,0x45,0x46};
    unsigned char* out = (unsigned char*)retStr.c_str();
    AES_cbc_encrypt((unsigned char*)srcStr.c_str(), out, len, &aesK, ivec, AES_DECRYPT);
    unsigned char fill = out[len-1];
    for(int i = len - fill; i < len; i++)
    {
        if (out[i] != fill)
        {
            retStr = "";
            return;
        }
    }
    retStr.resize(len - fill);
}

void GetStrMd5(const string& src, string& retStr)
{
    CMd5 tmpMd5(src);
    retStr = tmpMd5.toString();
}

//比较一个字符创的大写是否匹配一个大写的字符串
//也可以用strcasecmp
bool UpperStrCmp(const char* src, const char* dest)
{
    if( strlen(src) != strlen(dest) )
    {
        return false;
    }
    if(src && dest)
    {
        for(;;)
        {
            char c1 = *src;
            char c2 = *dest;
            if( toupper(c1) == toupper(c2) )
            {
                ++src;
                ++dest;
            }
            else
            {
                return false;
            }
        }
        return true;
    }

    //src和dest任一个为NULL,都认为false
    return false;
}

bool IsPlutoHeaderGet(const char* szHeader)
{
    return (0 == strncasecmp(szHeader, "GET ", 4));
}

char * GetPlutoReceiveEndPos(char* szBuffer, int nLen)
{
    for(char * i = szBuffer + nLen - 4; i >= szBuffer; i--)
    {
        // 字节流0D0A0D0A
        if (0x0a0d0a0d == (*(uint32_t*)(void*)i))
            return i;
    }

    return NULL;
}

//按照分隔符nDelim拆分字符串
list<string> SplitString(const string& s1, int nDelim)
{
    list<string> l;

    size_t nSize = s1.size()+1;
    char* pszTemp = new char[nSize];
    memset(pszTemp, 0, nSize);

    istringstream iss(s1);
    while(iss.getline(pszTemp, (std::streamsize)nSize, nDelim))
    {
        if(strlen(Rtrim(pszTemp))>0)
        {
            l.push_back(pszTemp);
        }
        memset(pszTemp, 0, nSize);
    }

    delete [] pszTemp;
    pszTemp = NULL;

    return l;
}


void SplitString(const string& s1, int nDelim, list<string>& ls)
{
    ls.clear();

    size_t nSize = s1.size()+1;
    char* pszTemp = new char[nSize];
    memset(pszTemp, 0, nSize);

    istringstream iss(s1);
    while(iss.getline(pszTemp, (std::streamsize)nSize, nDelim))
    {
        if(strlen(Rtrim(pszTemp))>0)
        {
            ls.push_back(pszTemp);
        }
        memset(pszTemp, 0, nSize);
    }

    delete [] pszTemp;
    pszTemp = NULL;

    return;
}

void SplitStringToVector(const string& s1, int nDelim, vector<string>& ls)
{
    ls.clear();

    size_t nSize = s1.size()+1;
    char* pszTemp = new char[nSize];
    memset(pszTemp, 0, nSize);

    istringstream iss(s1);
    while(iss.getline(pszTemp, (std::streamsize)nSize, nDelim))
    {
        if(strlen(Rtrim(pszTemp))>0)
        {
            ls.push_back(pszTemp);
        }
        memset(pszTemp, 0, nSize);
    }

    delete [] pszTemp;
    pszTemp = NULL;

    return;
}

void SplitStringToMap(const string& s1, int nDelim, char nDelim2, map<string, string>& dict)
{
    dict.clear();

    size_t nSize = s1.size()+1;
    char* pszTemp = new char[nSize];
    memset(pszTemp, 0, nSize);

    istringstream iss(s1);
    while(iss.getline(pszTemp, (std::streamsize)nSize, nDelim))
    {
        if(strlen(Rtrim(pszTemp))>0)
        {
            string s2(pszTemp);
            string::size_type nn = s2.find(nDelim2);
            if(nn != string::npos)
            {
                dict.insert(make_pair(s2.substr(0, nn), s2.substr(nn+1)));
            }
        }
        memset(pszTemp, 0, nSize);
    }

    delete[] pszTemp;

    return;
}

int GetRandomRange(int min, int max)
{
    if(max < min)
        max = min;

    return rand() % (max - min + 1) + min;
}

bool IsFix100Rate(int rate)
{
    return GetRandomRange(0, 100 - 1) < rate;
}

uint32_t GetNowMsTick()
{
    struct timespec tm;
    clock_gettime(CLOCK_MONOTONIC, &tm);
    return (uint32_t)(tm.tv_sec * 1000 + tm.tv_nsec / 1000000);
}

uint32_t GetNowMsTickNot0()
{
    uint32_t Result = GetNowMsTick();
    if(0 == Result)
        Result = 1;

    return Result;
}

uint32_t GetMsTickDiff(uint32_t oldMs, uint32_t newMs)
{
    return (newMs - oldMs);
}

uint64_t GetTimeStampInt64Ms()
{
    struct timeval tv;

    if(0 == gettimeofday(&tv, NULL))
    {
        return tv.tv_sec * 1000 + tv.tv_usec / 1000;
    }
    else
    {
        LogError("GetTimeStampInt64Ms", "gettimeofday(&tv, NULL) failed");
        return 0;
    }
}

uint64_t _GetNanoSecMax1Sec()
{
    // 获得小于1秒的纳秒
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_nsec;
}

//linux下用gettimeofday来计算时间

CCalcTimeTick::CCalcTimeTick()
{
    SetNowTime();
}

CCalcTimeTick::~CCalcTimeTick()
{
}

void CCalcTimeTick::GetNowTick(struct timespec& tm)
{
    clock_gettime(CLOCK_MONOTONIC, &tm);
}

uint32_t CCalcTimeTick::GetMsTickByTime(struct timespec& tm)
{
    return (uint32_t)(tm.tv_sec * 1000 + tm.tv_nsec / 1000000);
}

uint64_t CCalcTimeTick::GetUsTickByTime(struct timespec& tm)
{
    return (tm.tv_sec * 1000000 + tm.tv_nsec / 1000);
}

uint64_t CCalcTimeTick::GetNsTickByTime(struct timespec& tm)
{
    return (tm.tv_sec * 1000000000 + tm.tv_nsec);
}

void CCalcTimeTick::SetNowTime()
{
    struct timespec curtime;
    this->GetNowTick(curtime);
    m_msTick = GetMsTickByTime(curtime);
    m_usTick = GetUsTickByTime(curtime);
    m_nsTick = GetNsTickByTime(curtime);
}

void CCalcTimeTick::AddMsTick(uint32_t add)
{
    m_msTick += add;
}

void CCalcTimeTick::DecMsTick(uint32_t dec)
{
    m_msTick -= dec;
}

uint32_t CCalcTimeTick::GetPassMsTick()
{
    struct timespec curtime;
    this->GetNowTick(curtime);

    return (GetMsTickByTime(curtime) - m_msTick);
}

uint64_t CCalcTimeTick::GetPassUsTick()
{
    struct timespec curtime;
    this->GetNowTick(curtime);

    return (GetUsTickByTime(curtime) - m_usTick);
}

uint64_t CCalcTimeTick::GetPassNsTick()
{
    struct timespec curtime;
    this->GetNowTick(curtime);

    return (GetNsTickByTime(curtime) - m_nsTick);
}
