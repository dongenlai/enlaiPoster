#ifndef __TYPE__MOGO__HEAD__
#define __TYPE__MOGO__HEAD__

#include "win32def.h"
#include "util.h"
#include "memory_pool.h"
#include "json_helper.h"
#include <stdlib.h>
#include <list>
using std::list;
#include <inttypes.h>

#define MS_PER_SEC 1000
#define INVALID_USERID -1
#define INVALID_INDEX -1
typedef float float32_t;
typedef double float64_t;
class CPluto;


typedef uint32_t TENTITYID;
typedef uint64_t TDBID;
typedef uint16_t TENTITYTYPE;
typedef uint32_t TSPACEID;
typedef unsigned short T_INTEREST_SIZE;
typedef int32_t int32;
typedef uint32_t uint32;
typedef uint16_t pluto_msgid_t;

struct VOBJECT;

enum VTYPE
{
    V_TYPE_ERR      = -1,

    V_OBJ_STRUCT    = 1,        // 结构体
    V_STR           = 2,
    V_INT8          = 3,
    V_UINT8         = 4,
    V_INT16         = 5,
    V_UINT16        = 6,
    V_INT32         = 7,
    V_UINT32        = 8,
    V_INT64         = 9,
    V_UINT64        = 10,
    V_FLOAT32       = 11,
    V_FLOAT64       = 12,
    V_OBJ_ARY       = 13,       // 数组
};

enum EUserState
{
    EUS_NONE        = 0,
    EUS_AUTHED      = 1,
    EUS_INTABLE     = 2,
};

struct VTYPE_OJBECT;
typedef vector<VTYPE_OJBECT*> T_VECTOR_VTYPE_OBJECT;
struct VTYPE_OJBECT
{
    VTYPE vt;                   // Item的类型
    string vtName;              // 该类型对应json的名称
    T_VECTOR_VTYPE_OBJECT* o;   // 如果是V_OBJ_ARY，第1个元素表示数组元素的类型 如果是V_OBJ_STRUCT，这里保存每个元素的类型

    VTYPE_OJBECT();
    ~VTYPE_OJBECT();
};

struct VOBJECT;
typedef vector<VOBJECT*> T_VECTOR_OBJECT;

union VVALUE
{
    string* s;
    T_VECTOR_OBJECT* oOrAry;

    uint8_t u8;
    uint16_t u16;
    uint32_t u32;
    uint64_t u64;
    int8_t i8;
    int16_t i16;
    int32_t i32;
    int64_t i64;
    float32_t f32;
    float64_t f64;
};

struct VOBJECT
{
    VTYPE vt;
    VVALUE vv;

    VOBJECT();
    ~VOBJECT();
};
    
// 用户基本信息
struct SUserBaseInfo
{
    int userId;
    int userType;
    int64_t score;
    int64_t bean;
    string userName;
    string nickName;
    int sex;
    int level;
    int faceId;
    string faceUrl;
    int64_t specialGold;
	int32_t gameRoomLockStatus;
	string ip;
	int isVip;					// 是不是能代开房间

    SUserBaseInfo();
    void Clear();
    void CopyFrom(SUserBaseInfo& src);
    void WriteToPluto(CPluto& p);
    void ReadFromJson(cJSON* pJsObj);
    void ReadFromVObj(T_VECTOR_OBJECT& o, int& index);
};

// 变化信息
struct SUserActiveInfo
{
    int fd;
    int userState;
    int tableHandle;
    int chairIndex;
    int whereFrom;
    string mac;
	string ip;
    float64_t jingDu;
    float64_t weiDu;
    uint32_t enterTableTick;                    // 进入桌子Ms， 结束一局就是结束时刻了

    SUserActiveInfo();
    void CopyFrom(SUserActiveInfo& src);
    void Clear();
};

// card用户信息
struct SUserInfo
{
    SUserBaseInfo baseInfo;
    SUserActiveInfo activeInfo;
    int tmpInt;                               // 临时int变量

    SUserInfo();
    void CopyFrom(SUserInfo& src);
    void Clear();
};

struct SCisScoreReportRetItem
{
    int userId;
    int64_t score;
    int64_t bean;
    int64_t specialGold;
    int64_t incScore;
    int64_t incBean;
    int experience;
    int level;
    string expands;

    SCisScoreReportRetItem();
    void WriteToPluto(CPluto& p);
    void ReadFromJson(cJSON* pJsObj);
    void ReadFromVObj(T_VECTOR_OBJECT& o, int& index);
};

struct SCisSpecialGoldComsumeRetItem
{
    int userId;
    int64_t specialGold;

    SCisSpecialGoldComsumeRetItem();
    void WriteToPluto(CPluto& p);
    void ReadFromJson(cJSON* pJsObj);
    void ReadFromVObj(T_VECTOR_OBJECT& o, int& index);
};

extern uint32_t g_taskIdAlloctor;
class CAreaTaskItemBase
{
public:
    CAreaTaskItemBase(pluto_msgid_t msgId, uint32_t timeoutMs);
    virtual ~CAreaTaskItemBase();
private:
    uint32_t m_taskId;
    pluto_msgid_t m_msgid;
    uint32_t m_timeoutMs;
    CCalcTimeTick m_addTime;
public:
    inline uint32_t GetTaskId() const
    {
        return m_taskId;
    }

    inline pluto_msgid_t GetMsgId() const
    {
        return m_msgid;
    }

    inline bool IsTimeout()
    {
        return (m_addTime.GetPassMsTick() >= m_timeoutMs);
    }
};

class CAreaTaskReadUserInfo: public CAreaTaskItemBase
{
public:
    CAreaTaskReadUserInfo(pluto_msgid_t msgId, int clientFd);
    ~CAreaTaskReadUserInfo();
private:
    int m_clientFd;                         // client socket fd
public:
    inline int GetClientFd() const
    {
        return m_clientFd;
    }
};

class CAreaTaskReportScore: public CAreaTaskItemBase
{
public:
    CAreaTaskReportScore(int tableHandle);
    ~CAreaTaskReportScore();
private:
    int m_tableHandle;
public:
    inline int GetTableHandle() const
    {
        return m_tableHandle;
    }
};

class CAreaTaskConsumeSpecialGold : public CAreaTaskItemBase
{
public:
    CAreaTaskConsumeSpecialGold(int tableHandle);
    ~CAreaTaskConsumeSpecialGold();
private:
    int m_tableHandle;
public:
    inline int GetTableHandle() const
    {
        return m_tableHandle;
    }
};

class CAreaTaskReportTotalScore : public CAreaTaskItemBase
{
public:
    CAreaTaskReportTotalScore(int tableHandle);
    ~CAreaTaskReportTotalScore();
private:
    int m_tableHandle;
public:
    inline int GetTableHandle() const
    {
        return m_tableHandle;
    }
};

class CAreaTaskReportTableManager : public CAreaTaskItemBase
{
public:
	CAreaTaskReportTableManager(int tableHandle, int flag, int clientFd);
	~CAreaTaskReportTableManager();
private:
	int m_tableHandle;
	int m_flag;
	int m_clientFd;
public:
	inline int GetTableHandle() const
	{
		return m_tableHandle;
	}
	inline int GetFlag() const
	{
		return m_flag;
	}
	inline int GetClientFd() const
	{
		return m_clientFd;
	}
};

class CAreaTaskReportTableStart : public CAreaTaskItemBase
{
public:
	CAreaTaskReportTableStart(int tableHandle);
	~CAreaTaskReportTableStart();
private:
	int m_tableHandle;
public:
	inline int GetTableHandle() const
	{
		return m_tableHandle;
	}
};

class CAreaTaskStartReport2FS :public CAreaTaskItemBase
{
public:
	CAreaTaskStartReport2FS();
	~CAreaTaskStartReport2FS();
private:

};

class CAreaTaskLockOrUnlockUser :public CAreaTaskItemBase
{
public:
	CAreaTaskLockOrUnlockUser();
	~CAreaTaskLockOrUnlockUser();
};

// 自动指针，为了用栈自动释放new的内存
template<class _Ty>
class auto_new1_ptr
{
public:
    // explicit表示必须显式构造，赋值构造不行
    explicit auto_new1_ptr(_Ty *_Ptr)
        : _Myptr(_Ptr)
    {    // construct from object pointer
    }

    ~auto_new1_ptr()
    {    // destroy the object
        if(NULL != _Myptr)
            delete _Myptr;
    }

    // 可能存在一定情况下释放的情况
    void OverridePtr(_Ty *_Ptr)
    {
        _Myptr = _Ptr;
    }
private:
    _Ty *_Myptr;
};

// 自动指针，为了用栈自动释放new的数组内存
template<class _Ty>
class auto_new_array_ptr
{
public:
    explicit auto_new_array_ptr(_Ty *_Ptr)
        : _Myptr(_Ptr)
    {    // construct from object pointer
    }

    ~auto_new_array_ptr()
    {    // destroy the object
        if(NULL != _Myptr)
            delete [] _Myptr;
    }

    // 可能存在一定情况下释放的情况
    void OverridePtr(_Ty *_Ptr)
    {
        _Myptr = _Ptr;
    }
private:
    _Ty *_Myptr;
};


template < template <typename ELEM,
            typename ALLOC = std::allocator<ELEM>
            > class TC
            >
void ClearTListObject(TC<VOBJECT*, std::allocator<VOBJECT*> >* c1)
{
    ClearContainer(*c1);
    delete c1;
}


template<typename T>
void CopyEntityIdSet(const T& from, T& to)
{
    typename T::const_iterator it = from.begin();
    for(; it != from.end(); ++it)
    {
        to.insert(*it);
    }
}


#endif
