#ifndef __UTIL__HEAD__
#define __UTIL__HEAD__

#include "win32def.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <ctype.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <list>
#include "exception.h"

#include <dirent.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/time.h>
#include <unistd.h>

using std::cout;
using std::endl;
using std::string;
using std::vector;
using std::map;
using std::ios;
using std::list;


extern string& Ltrim(string& s);
extern string& Rtrim(string& s);

inline string& Trim(string& s)
{
    return Rtrim(Ltrim(s));
}

//删除字符串左边的空格
extern char* Ltrim(char* p);

//删除字符串右边的空格
extern char* Rtrim(char* p);

//删除字符串两边的空格
inline char* Trim(char* s)
{
    return Rtrim(Ltrim(s));
}

// aes解密
extern void AesDecryptStr(const string& base64Str, const string& aesKey, string& retStr);
//获得字符串的md5值
extern void GetStrMd5(const string& src, string& retStr);
//比较一个字符串的大写是否匹配一个大写的字符串
extern bool UpperStrCmp(const char* src, const char* desc);
//4字节包头是否为 GET+空格
extern bool IsPlutoHeaderGet(const char* szHeader);
//http数据包是否接收完毕 从尾部查找4字节结束符合
extern char * GetPlutoReceiveEndPos(char* szBuffer, int nLen);

// vector --> string
template<typename T> void Vector2Str(vector<T>& src, bool isConcat, char DelimChar, string& dest)
{
	std::stringstream ss;
	typename vector<T>::iterator it;
	for (it = src.begin(); it != src.end(); it++)
	{
		if (isConcat && (it != src.end() - 1))
			ss << *it << DelimChar;
		else
			ss << *it;
	}
	dest = ss.str();
}

//按照分隔符nDelim拆分字符串
extern list<string> SplitString(const string& s1, int nDelim);
extern void SplitString(const string& s1, int nDelim, list<string>& ls);
extern void SplitStringToVector(const string& s1, int nDelim, vector<string>& ls);
extern void SplitStringToMap(const string& s1, int nDelim1, char nDelim2, map<string, string>& dict);

//替换string中第一次出现的某个部分
extern string& xReplace(string& s1, const char* pszSrc, const char* pszRep);

//判断一个字符串是否全部由数字字符组成
extern bool IsDigitStr(const char* pszStr);
//根据字符串获得区域编号
int GetAreaNumBy6TableNum(string& tableNum, int& tableHandle);
//根据桌子handle获得桌子编号
string GetTableNumByHandle(int areaNum, int tableHandle);

//测试文件strFileName是否存在
extern bool IsFileExist(const char* pszFileName);
extern bool IsFileExist(const string& strFileName);

extern int get_distance(double weidu1, double jingdu1, double weidu2, double jingdu2);        // weidu: 纬度(-90..90)  jingdu：经度(-180..180) ret:单位米

//用于清理一个指针容器
template <typename TP,
            template <typename ELEM,
            typename ALLOC = std::allocator<ELEM>
            > class TC
            >
void ClearContainer(TC<TP, std::allocator<TP> >& c1)
{
    while(!c1.empty())
    {
        typename TC<TP>::iterator iter = c1.begin();
        delete *iter;
        *iter = NULL;
        c1.erase(iter);
    }
}

//用于清理一个map,第二个类型为指针
template<typename T1, typename T2,
            template <class _Kty,
            class _Ty,
            class _Pr = std::less<_Kty>,
            class _Alloc = std::allocator<std::pair<const _Kty, _Ty> >
            > class M
            >
void ClearMap(M<T1, T2, std::less<T1>, std::allocator<std::pair<const T1, T2> > >& c1)
{
    typename M<T1, T2>::iterator iter = c1.begin();
    for(; iter!=c1.end(); ++iter)
    {
        delete iter->second;
        iter->second = NULL;
    }
    c1.clear();
}

extern int GetRandomRange(int min, int max);  // include min and max
extern bool IsFix100Rate(int rate);
extern uint32_t GetNowMsTick();
extern uint32_t GetNowMsTickNot0();
extern uint32_t GetMsTickDiff(uint32_t oldMs, uint32_t newMs);
extern uint64_t GetTimeStampInt64Ms();

class CCalcTimeTick
{
    public:
        CCalcTimeTick();
        ~CCalcTimeTick();

    private:
        void GetNowTick(struct timespec& tm);
        uint32_t GetMsTickByTime(struct timespec& tm);
        uint64_t GetUsTickByTime(struct timespec& tm);
        uint64_t GetNsTickByTime(struct timespec& tm);
    public:
        //获取当前时间和上次的流逝毫秒
        uint32_t GetPassMsTick();
        //获取当前时间和上次的流逝微秒
        uint64_t GetPassUsTick();
        //获取当前时间和上次的流逝纳秒
        uint64_t GetPassNsTick();
        //设置当前时间为tick
        void SetNowTime();
        //添加毫秒
        void AddMsTick(uint32_t add);
        //减少毫秒
        void DecMsTick(uint32_t dec);
    private:
        //毫秒数
        uint32_t m_msTick;
        //微秒数
        uint64_t m_usTick;
        //纳秒数
        uint64_t m_nsTick;
};

class MyLock
{
    pthread_mutex_t m_Mutex; 
public :
    MyLock( ){ pthread_mutex_init( &m_Mutex , NULL );} ;
    ~MyLock( ){ pthread_mutex_destroy( &m_Mutex) ; } ;
    void Lock( ){ pthread_mutex_lock(&m_Mutex); } ;
    void Unlock( ){ pthread_mutex_unlock(&m_Mutex); } ;
};


#endif
