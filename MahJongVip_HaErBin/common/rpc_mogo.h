#ifndef __RPC__MOGO__HEAD__
#define __RPC__MOGO__HEAD__

#include "type_mogo.h"
#include "pluto.h"
#include "logger.h"
#include "json_helper.h"


enum MSGID_ENUM_TYPE
{
    //area发给客户端的包
    MSGID_CLIENT_LOGIN_RESP                 = 1,                                    //账号登录结果
    MSGID_CLIENT_UPDATE_USERINFO_RESP       = 2,                                    //刷新用户信息结果
    MSGID_CLIENT_ONTICK_RESP                = 3,                                    //心跳包回应
    MSGID_CLIENT_SIT_RESP                   = 4,                                    //sit response
    MSGID_CLIENT_CHAT_RESP                  = 5,                                    //table chat response
    MSGID_CLIENT_READY_RESP                 = 6,                                    //ready response
    MSGID_CLIENT_G_TRUST_RESP               = 7,                                    //game trusteeship response
    MSGID_CLIENT_G_SWAP_CARD_RESP           = 8,                                    //game declare response
    MSGID_CLIENT_G_DISCARD_RESP             = 9,                                    //game discard response
	MSGID_CLIENT_G_SEL_DEL_SUIT_RESP        = 10,
	MSGID_CLIENT_QUEST_CTRL_TABLE_RESP      = 11,									// 请求散桌或者应答其他玩家的散桌请求 应答
	MSGID_CLIENT_G_LEAVE_RESP				= 12,									// 客户端请求主动离开请求的应答
	MSGID_CLIENT_G_GET_TINGINFO_RESP		= 13,									// 客户端请求听牌信息的应答
	MSGID_CLIENT_G_ERROR_ACTION_RESP	    = 14,									// 错误动作回应

    MSGID_CLIENT_BEGINGAME_NOTIFY           = 21,                                   //begin game notify
    MSGID_CLIENT_OTHER_ENTER_NOTIFY         = 22,                                   //other user enter table notify
    MSGID_CLIENT_OTHER_LEAVE_NOTIFY         = 23,                                   //other user leave table notify
    MSGID_CLIENT_FORCE_LEAVE_NOTIFY         = 24,                                   //force self leave table notify
    MSGID_CLIENT_OTHER_CHAT_NOTIFY          = 25,                                   //other user chat msg notify
    MSGID_CLIENT_OTHER_READY_NOTIFY         = 26,                                   //other user ready notify
    MSGID_CLIENT_OTHER_STATE_NOTIFY         = 27,                                   //other user state change notify
    MSGID_CLIENT_G_SYN_NOTIFY               = 28,                                   //syn self game notify
    MSGID_CLIENT_G_OTHER_TRUST_NOTIFY       = 29,                                   //other user trusteeship notify
    MSGID_CLIENT_G_DEALCARD_NOTIFY          = 30,                                   //deal card notify
    MSGID_CLIENT_G_MO_BAO_NOTIFY            = 31,                                   // 摸宝通知
    MSGID_CLIENT_G_SEL_DEL_SUIT_NOTIFY      = 32,                                   // 通知缺牌开局
    MSGID_CLIENT_G_DISCARD_NOTIFY           = 33,                                   // discard notify 通知所有的人
    MSGID_CLIENT_G_RESULT_NOTIFY            = 34,                                   // game result notify
    MSGID_CLIENT_G_CONSUME_SPECIAL_GOLD_NOTIFY = 35,                                // 通知所有人房卡的消费情况
	MSGID_CLIENT_G_SWAP_CARD_NOTIFY         = 36,                                   // 通知所有人换牌信息
	MGSID_CLIENT_G_MO_PAI_NOTIFY	        = 37,                                   // 摸牌
	MGSID_CLIENT_G_CHU_PAI_NOTIFY           = 38,                                   // 出牌
	MGSID_CLIENT_G_PENG_GANG_NOTIFY         = 39,                                   // 碰杠 
	MSGID_CLIENT_G_HU_NOTIFY                = 40,									// 胡牌
	MSGID_CLIENT_G_END_ROUND				= 41,									// 约局结束的通知
	MSGID_CLIENT_DISBAND_TABLE_NOTIFY       = 42,									// 询问玩家是否同意散桌
	MGSID_CLIENT_G_CHI_NOTIFY				= 43,									// 吃牌
    MGSID_CLIENT_G_TING_CHI_NOTIFY          = 44,									// 听吃
    MGSID_CLIENT_G_TING_PENG_NOTIFY         = 45,									// 听碰
	MSGID_CLIENT_G_SPECIAL_GANG_NOTIFY      = 46,									// 特殊杠
	MSGID_CLIENT_G_TING_PAI_NOTIFY          = 47,									// 听牌
	MSGID_CLIENT_G_DO_READY_NOTIFY			= 48,									// 通知客户端发送ready消息包（56号包），以避免在结算阶段，用户断线重连之后，游戏无法继续进行

    MSGID_CLIENT_BULLETIN_NOTIFY            = 49,                                   //公告

    //area接收客户端包
    MSGID_CLIENT_MIN                        = 50,                                   //范围判断用
    MSGID_CLIENT_LOGIN                      = 51,                                   //客户端登录验证
    MSGID_CLIENT_UPDATE_USERINFO            = 52,                                   //客户端刷新用户信息
    MSGID_CLIENT_ONTICK                     = 53,                                   //心跳消息
    MSGID_CLIENT_SIT                        = 54,                                   //sit: create table or find table
    MSGID_CLIENT_CHAT                       = 55,                                   //chat in table
    MSGID_CLIENT_READY                      = 56,                                   //ready for game
    MSGID_CLIENT_G_TRUST                    = 57,                                   //game trusteeship
    MSGID_CLIENT_G_SWAP_CARD                = 58,                                   // GAME SWAP CARDS
    MSGID_CLIENT_G_DISCARD                  = 59,                                   //game discard
    MSGID_CLIENT_G_SEL_DEL_SUIT				= 60,									// 选择缺牌
	MSGID_CLIENT_G_CHU                      = 61,
	MSGID_CLIENT_G_MJ_ACTION                = 62,   
	MSGID_CLIENT_QUEST_CTRL_TABLE           = 63,									// 请求散桌或者应答其他玩家的散桌需求
	MSGID_CLIENT_QUEST_LEAVE				= 64,									// 客户端请求离开（仅第一局有用）
	MSGID_CLIENT_GET_TINGINFO				= 65,									// 玩家获取听牌信息
	MSGID_CLIENT_G_SPECIAL_GANG				= 66,									// 特殊杠牌
	MSGID_CLIENT_MAX                        = 67,                                   // 范围判断用

    //暂定100以下的是客户端和服务器的交互包
    MAX_CLIENT_SERVER_MSGID                 = 100,

    MSGID_ALLAPP_SHUTDOWN_SERVER            = 500,                                  //关闭服务器通知

    MSGID_AREAMGR_UPDATE_AREA               = MSGTYPE_AREAMGR + 1,                  //刷新区域服务器信息，tcp断开的时候，自动删除
	MSGID_AREAMGR_START_REPORT				= MSGTYPE_AREAMGR + 2,					//游戏服务器启动时，向FS发送游戏服务的相关信息，以便FS进行分流处理

    MSGID_DBMGR_READ_USERINFO               = MSGTYPE_DBMGR + 1,                    //读取用户信息
    MSGID_DBMGR_REPORT_SCORE                = MSGTYPE_DBMGR + 2,                    //积分上报
    MSGID_DBMGR_CONSUME_SPECIAL_GOLD        = MSGTYPE_DBMGR + 3,                    //特殊币的消费
	MSGID_DBMGR_LOCK_GAMEROOM				= MSGTYPE_DBMGR + 4,					//给用户加/解锁
	MSGID_DBMGR_REPORT_TOTAL_SCORE			= MSGTYPE_DBMGR + 5,					//牌局最后的总分信息
	MSGID_DBMGR_REPORT_TABlE_MANAGER		= MSGTYPE_DBMGR + 6,					//用于多开逻辑，创建桌子时上报，询问是否能创建桌子；销毁桌子时上报，告知后台是否需要退回房卡，并消除多开玩家的一个房间累加
	MSGID_DBMGR_REPORT_TABLE_START			= MSGTYPE_DBMGR + 7,					//上报桌子开始的状态

    MSGID_AREA_READ_USERINFO_CALLBACK       = MSGTYPE_AREA + 1,                     //dbmgr返回给area读取用户信息数据包
    MSGID_AREA_REPORT_SCORE_CALLBACK        = MSGTYPE_AREA + 2,                     //dbmgr返回给area积分上报结果
    MSGID_AREA_CONSUME_SPECIAL_GOLD_CALLBACK = MSGTYPE_AREA + 3,                    //dbmgr返回给area特殊币消耗的结果
	MSGID_AREA_START_REPORT_CALLBACK		= MSGTYPE_AREA + 4,						//areamgr返回给area启动时上报的返回信息
	MSGID_AREA_LOCK_GAMEROOM_CALLBACK		= MSGTYPE_AREA + 5,						//dbmgr返回给area的给用户加/解锁的返回信息
	MSGID_AREA_REPORT_TOTAL_SCORE_CALLBACK	= MSGTYPE_AREA + 6,						//dbmgr返回给area总分上报结果
	MSGID_AREA_REPORT_TABlE_MANAGER_CALLBACK = MSGTYPE_AREA + 7,					//dbmgr返回给area是否上报成功
	MSGID_AREA_REPORT_TABLE_START_CALLBACK	= MSGTYPE_AREA + 8,						//dbmgr返回给area是否上报成功
};


enum
{
    MAILBOX_CLIENT_UNAUTHZ = 0,         //来自于客户端的连接,未验证
    MAILBOX_CLIENT_AUTHZ = 1,           //来自于客户端的连接,已验证
    MAILBOX_CLIENT_TRUSTED = 0xf,       //来自于服务器端的可信任连接
};

enum EFDTYPE
{
    FD_TYPE_ERROR = 0,
    FD_TYPE_SERVER = 1,
    FD_TYPE_MAILBOX = 2,
    FD_TYPE_ACCEPT = 3,
};

enum ERPCERR
{    
    ERR_RPC_UNKNOWN_MSGID = -99,   //未知msgid
    ERR_RPC_DECODE        = -98,   //解包错误
    ERR_RPC_LOGIC         = -97,   //逻辑错误
};

//检查rpc解包是否出错
#define CHECK_RPC_DECODE_ERR(u) \
    {\
        if(u.GetDecodeErrIdx()>0)\
        {\
            return ERR_RPC_DECODE;\
        }\
    }

//检查并获取rpc中的一个字段
#define CHECK_AND_GET_RPC_FIELD(u, field_var, field_type) \
    field_type field_var;\
    u >> field_var;\
    if(u.GetDecodeErrIdx()>0)\
    {\
        return ERR_RPC_DECODE;\
    }


//检查并获取rpc中的一个c_str字段
#define CHECK_AND_GET_RPC_FIELD_CSTR(u, field_var) \
    string _tmp_##field_var;\
    u >> _tmp_##field_var;\
    if(u.GetDecodeErrIdx()>0)\
    {\
        return ERR_RPC_DECODE;\
    }\
    const char* field_var = _tmp_##field_var.c_str();

struct _SEntityDefMethods
{
    uint8_t m_nServerId;   //base/cell/client
    bool m_bExposed;       //客户端是否可以调用
    string m_funcName;
    T_VECTOR_VTYPE_OBJECT* m_argsType;

    _SEntityDefMethods();
    ~_SEntityDefMethods();

    void PushPack(VTYPE vt, const char * vtName = NULL, T_VECTOR_VTYPE_OBJECT* o = NULL);
};

class CRpcUtil
{
    public:
        CRpcUtil();
        ~CRpcUtil();

    private:
        //初始化内嵌(非自定义)的方法
        void InitInnerMethods();
        void PushItemToVector(T_VECTOR_VTYPE_OBJECT* vct, VTYPE t, const char* vtName= NULL, T_VECTOR_VTYPE_OBJECT* o = NULL);
        T_VECTOR_VTYPE_OBJECT* CreateUserBaseInfoStruct();
    public:
        template<typename T1>
        void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1);
        template<typename T1, typename T2>
        void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2);
        template<typename T1, typename T2, typename T3>
        void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3);
        template<typename T1, typename T2, typename T3, typename T4>
        void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4);
        template<typename T1, typename T2, typename T3, typename T4, typename T5>
        void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5);
        template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
        void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6);
        template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7>
        void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6, const T7& p7);
    public:
        T_VECTOR_OBJECT* Decode(CPluto& u);
#ifdef __WEBSOCKET_CLIENT
        bool RpcEncodeJsonToPluto(AutoJsonHelper& aJs, CPluto& u);
        bool RpcDecodePlutoToJson(cJSON* pJs, CPluto& u);
#endif
    private:
        map<pluto_msgid_t, _SEntityDefMethods*> m_methods;
#ifdef __WEBSOCKET_CLIENT
        map<pluto_msgid_t, _SEntityDefMethods*> m_methodsToWsClient;
#endif
};

template<typename T1>
void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1)
{
    u.Encode(msg_id) << p1 << EndPluto;
}

template<typename T1, typename T2>
void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
{
    u.Encode(msg_id) << p1 << p2 << EndPluto;
}

template<typename T1, typename T2, typename T3>
void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
{
    u.Encode(msg_id) << p1 << p2 << p3 << EndPluto;
}

template<typename T1, typename T2, typename T3, typename T4>
void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
{
    u.Encode(msg_id) << p1 << p2 << p3 << p4 << EndPluto;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5>
void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
{
    u.Encode(msg_id) << p1 << p2 << p3 << p4 << p5 << EndPluto;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
{
    u.Encode(msg_id) << p1 << p2 << p3 << p4 << p5 << p6 << EndPluto;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7>
void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6, const T7& p7)
{
    u.Encode(msg_id) << p1 << p2 << p3 << p4 << p5 << p6 << p7 << EndPluto;
}

#endif
