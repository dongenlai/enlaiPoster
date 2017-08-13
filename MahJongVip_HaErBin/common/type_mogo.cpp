/*----------------------------------------------------------------
// 模块名：type_mogo
// 模块描述：def相关数据类型定义。
//----------------------------------------------------------------*/


#include "type_mogo.h"
#include "pluto.h"
#include "util.h"
#include "world_select.h"
#include "logger.h"

uint32_t g_taskIdAlloctor;


VOBJECT::VOBJECT()
{
    vt = V_TYPE_ERR;
    memset(&vv, 0, sizeof(vv));
}

VOBJECT::~VOBJECT()
{
    switch(vt)
    {
    case V_STR:
        {
            if (NULL != vv.s)
                delete vv.s;
            break;
        }
    case V_OBJ_STRUCT:
    case V_OBJ_ARY:
        {
            if (NULL != vv.oOrAry)
            {
                ClearContainer(*vv.oOrAry);
                delete vv.oOrAry;
            }
            break;
        }
    }

    vt = V_TYPE_ERR;
}


VTYPE_OJBECT::VTYPE_OJBECT()
{
    vt = V_TYPE_ERR;
    o = NULL;
}


VTYPE_OJBECT::~VTYPE_OJBECT()
{
    switch (vt)
    {
    case V_OBJ_STRUCT:
    case V_OBJ_ARY:
        {
            if (NULL != o)
            {
                ClearContainer(*o);
                delete o;
            }
            break;
        }
    }
}


SUserBaseInfo::SUserBaseInfo()
{
    Clear();
}

void SUserBaseInfo::Clear()
{
    userId = INVALID_USERID;
    userType = 0;
    score = 0;
    bean = 0;
    userName = "";
    nickName = "";
    sex = 0;
    level = 0;
    faceId = 0;
    faceUrl = "";
    specialGold = 0;
	gameRoomLockStatus = 0;
	ip = "";
	isVip = 0;
}

void SUserBaseInfo::CopyFrom(SUserBaseInfo& src)
{
    userId = src.userId;
    userType = src.userType;
    score = src.score;
    bean = src.bean;
    userName = src.userName;
    nickName = src.nickName;
    sex = src.sex;
    level = src.level;
    faceId = src.faceId;
    faceUrl = src.faceUrl;
    specialGold = src.specialGold;
	ip = src.ip;
	isVip = src.isVip;
}

void SUserBaseInfo::WriteToPluto(CPluto& p)
{
    p << userId << userType << score << bean << userName << nickName << sex << level << faceId << faceUrl << specialGold;
}

void SUserBaseInfo::ReadFromJson(cJSON* pJsObj)
{
    FindJsonItemIntValue(pJsObj, "userId", userId);
    FindJsonItemIntValue(pJsObj, "userType", userType);
    FindJsonItemInt64Value(pJsObj, "score", score);
    FindJsonItemInt64Value(pJsObj, "bean", bean);
    FindJsonItemStrValue(pJsObj, "userName", userName);
    FindJsonItemStrValue(pJsObj, "nickName", nickName);
    FindJsonItemIntValue(pJsObj, "sex", sex);
    FindJsonItemIntValue(pJsObj, "level", level);
    FindJsonItemIntValue(pJsObj, "faceId", faceId);
    FindJsonItemStrValue(pJsObj, "faceUrl", faceUrl);
    FindJsonItemInt64Value(pJsObj, "specialGold", specialGold);
	FindJsonItemStrValue(pJsObj, "lastLoginIP", ip);
	FindJsonItemIntValue(pJsObj, "vip", isVip);
}

void SUserBaseInfo::ReadFromVObj(T_VECTOR_OBJECT& o, int& index)
{
    userId = o[index++]->vv.i32;
    userType = o[index++]->vv.i32;
    score = o[index++]->vv.i64;
    bean = o[index++]->vv.i64;
    userName = *o[index++]->vv.s;
    nickName = *o[index++]->vv.s;
    sex = o[index++]->vv.i32;
    level = o[index++]->vv.i32;
    faceId = o[index++]->vv.i32;
    faceUrl = *o[index++]->vv.s;
    specialGold = o[index++]->vv.i64;
	ip = *o[index++]->vv.s;
	isVip = o[index++]->vv.i32;
}

SCisScoreReportRetItem::SCisScoreReportRetItem() : userId(-1), score(0), bean(0), specialGold(0), \
    incScore(0), incBean(0), experience(0), level(0), expands()
{

}


void SCisScoreReportRetItem::WriteToPluto(CPluto& p)
{
    p << userId << score << bean << specialGold << incScore << incBean
        << experience << level << expands;
}

void SCisScoreReportRetItem::ReadFromJson(cJSON* pJsObj)
{
    FindJsonItemIntValue(pJsObj, "userId", userId);
    FindJsonItemInt64Value(pJsObj, "score", score);
    FindJsonItemInt64Value(pJsObj, "bean", bean);
    FindJsonItemInt64Value(pJsObj, "specialGold", specialGold);
    FindJsonItemInt64Value(pJsObj, "incScore", incScore);
    FindJsonItemInt64Value(pJsObj, "incBean", incBean);
    FindJsonItemIntValue(pJsObj, "experience", experience);
    FindJsonItemIntValue(pJsObj, "level", level);
    FindJsonItemStrValueForObject(pJsObj, "expands", expands);
}

void SCisScoreReportRetItem::ReadFromVObj(T_VECTOR_OBJECT& o, int& index)
{
    userId = o[index++]->vv.i32;
    score = o[index++]->vv.i64;
    bean = o[index++]->vv.i64;
    specialGold = o[index++]->vv.i64;
    incScore = o[index++]->vv.i64;
    incBean = o[index++]->vv.i64;
    experience = o[index++]->vv.i32;
    level = o[index++]->vv.i32;
    expands = *(o[index++]->vv.s);
}

SCisSpecialGoldComsumeRetItem::SCisSpecialGoldComsumeRetItem() : userId(-1), specialGold(0)
{

}

void SCisSpecialGoldComsumeRetItem::WriteToPluto(CPluto& p)
{
    p << userId << specialGold;
}

void SCisSpecialGoldComsumeRetItem::ReadFromJson(cJSON* pJsObj)
{
    FindJsonItemIntValue(pJsObj, "userId", userId);
    FindJsonItemInt64Value(pJsObj, "specialGold", specialGold);
}

void  SCisSpecialGoldComsumeRetItem::ReadFromVObj(T_VECTOR_OBJECT& o, int& index)
{
    userId = o[index++]->vv.i32;
    specialGold = o[index++]->vv.i64;
}

SUserActiveInfo::SUserActiveInfo()
{
    Clear();
}

void SUserActiveInfo::CopyFrom(SUserActiveInfo& src)
{
    fd = src.fd;
    userState = src.userState;
    tableHandle = src.tableHandle;
    chairIndex = src.chairIndex;
    whereFrom = src.whereFrom;
    mac = src.mac;
	ip = src.ip;
}

void SUserActiveInfo::Clear()
{
    fd = -1;
    userState = EUS_NONE;
    tableHandle = -1;
    chairIndex = -1;
    whereFrom = 0;
    mac = "";
	ip = "";
    jingDu = 0.0;
    weiDu = 0.0;
    enterTableTick = 0;
}

CAreaTaskItemBase::CAreaTaskItemBase(pluto_msgid_t msgId, uint32_t timeoutMs): m_msgid(msgId), m_addTime(), m_timeoutMs(timeoutMs)
{
    m_taskId = g_taskIdAlloctor++;
}

CAreaTaskItemBase::~CAreaTaskItemBase()
{

}

CAreaTaskReadUserInfo::CAreaTaskReadUserInfo(pluto_msgid_t msgId, int clientFd): \
    CAreaTaskItemBase(msgId, 10*1000), m_clientFd(clientFd)
{

}

CAreaTaskReadUserInfo::~CAreaTaskReadUserInfo()
{

}

CAreaTaskReportScore::CAreaTaskReportScore(int tableHandle): CAreaTaskItemBase(MSGID_DBMGR_REPORT_SCORE, 15*1000), m_tableHandle(tableHandle)
{

}

CAreaTaskReportScore::~CAreaTaskReportScore()
{

}

CAreaTaskConsumeSpecialGold::CAreaTaskConsumeSpecialGold(int tableHandle) : CAreaTaskItemBase(MSGID_DBMGR_CONSUME_SPECIAL_GOLD, 15 * 1000), m_tableHandle(tableHandle)
{

}

CAreaTaskConsumeSpecialGold::~CAreaTaskConsumeSpecialGold()
{

}

CAreaTaskReportTotalScore::CAreaTaskReportTotalScore(int tableHandle) : CAreaTaskItemBase(MSGID_DBMGR_REPORT_TOTAL_SCORE, 15 * 1000), m_tableHandle(tableHandle)
{

}

CAreaTaskReportTotalScore::~CAreaTaskReportTotalScore()
{

}

CAreaTaskReportTableManager::CAreaTaskReportTableManager(int tableHandle, int flag, int clientFd) :
CAreaTaskItemBase(MSGID_DBMGR_REPORT_TABlE_MANAGER, 15 * 1000),
m_tableHandle(tableHandle), m_flag(flag), m_clientFd(clientFd)
{

}

CAreaTaskReportTableManager::~CAreaTaskReportTableManager()
{

}

CAreaTaskReportTableStart::CAreaTaskReportTableStart(int tableHandle) :
CAreaTaskItemBase(MSGID_DBMGR_REPORT_TABLE_START, 15 * 1000),
m_tableHandle(tableHandle)
{

}

CAreaTaskReportTableStart::~CAreaTaskReportTableStart()
{

}

CAreaTaskStartReport2FS::CAreaTaskStartReport2FS() :CAreaTaskItemBase(MSGID_AREAMGR_START_REPORT, 15 * 1000)
{

}

CAreaTaskStartReport2FS::~CAreaTaskStartReport2FS()
{

}

CAreaTaskLockOrUnlockUser::CAreaTaskLockOrUnlockUser() :CAreaTaskItemBase(MSGID_DBMGR_LOCK_GAMEROOM, 15 * 1000)
{

}

CAreaTaskLockOrUnlockUser::~CAreaTaskLockOrUnlockUser()
{

}

SUserInfo::SUserInfo(): baseInfo(), activeInfo()
{

}

void SUserInfo::CopyFrom(SUserInfo& src)
{
    baseInfo.CopyFrom(src.baseInfo);
    activeInfo.CopyFrom(src.activeInfo);
}

void SUserInfo::Clear()
{
    baseInfo.Clear();
    activeInfo.Clear();
}





