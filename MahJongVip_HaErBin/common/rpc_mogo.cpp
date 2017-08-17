/*----------------------------------------------------------------
// 模块名：rpc_mogo
// 模块描述：rpc 打包，解包等
//----------------------------------------------------------------*/

#include "rpc_mogo.h"
#include "util.h"
#include "world.h"
#include "world_select.h"
#include "pluto.h"
#include "mailbox.h"

class CEntityCell;
class CEntityBase;

_SEntityDefMethods::_SEntityDefMethods()
{
    m_argsType = new T_VECTOR_VTYPE_OBJECT();
}

_SEntityDefMethods::~_SEntityDefMethods()
{
    ClearContainer(*m_argsType);
    delete m_argsType;
}

void _SEntityDefMethods::PushPack(VTYPE vt, const char * vtName, T_VECTOR_VTYPE_OBJECT* o)
{
    switch (vt)
    {
        case V_OBJ_STRUCT:
        case V_OBJ_ARY:
        {
            if (NULL == o)
            {
                LogWarning("_SEntityDefMethods::PushPack", "NULL == o");
                return;
            }
            break;
        }
        default:
        {
            if (NULL != o)
            {
                LogWarning("_SEntityDefMethods::PushPack", "NULL != o");
                return;
            }

            break;
        }
    }

    VTYPE_OJBECT* pItem = new VTYPE_OJBECT();
    pItem->vt = vt;
    if (NULL != vtName)
        pItem->vtName = vtName;
    else
        pItem->vtName = "";
    pItem->o = o;

    m_argsType->push_back(pItem);
}

CRpcUtil::CRpcUtil()
{
    this->InitInnerMethods();
}

//初始化内嵌(非自定义)的方法
void CRpcUtil::InitInnerMethods()
{
#ifdef __WEBSOCKET_CLIENT
    // to websocket client  非websocket的发送格式不用设计，发什么格式就是什么
    {
        T_VECTOR_VTYPE_OBJECT* pvo1 = NULL; // 第1层
        T_VECTOR_VTYPE_OBJECT* pvo2 = NULL; // 第2层
        T_VECTOR_VTYPE_OBJECT* pvo3 = NULL; // 第3层
		T_VECTOR_VTYPE_OBJECT* pvo4 = NULL; // 第3层

        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        p->PushPack(V_INT32, "userState");
		p->PushPack(V_STR, "ip");
        // begin baseInfo:{}
        pvo1 = CreateUserBaseInfoStruct();
        p->PushPack(V_OBJ_STRUCT, "baseInfo", pvo1);
        // end baseInfo
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_LOGIN_RESP, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        // begin baseInfo:{}
        pvo1 = CreateUserBaseInfoStruct();
        p->PushPack(V_OBJ_STRUCT, "baseInfo", pvo1);
        // end baseInfo
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_UPDATE_USERINFO_RESP, p));


        p = new _SEntityDefMethods;
        p->PushPack(V_UINT32, "tick");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_ONTICK_RESP, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        p->PushPack(V_INT32, "userState");
        p->PushPack(V_INT32, "vipRoomType");
        p->PushPack(V_INT32, "discardDelay");
        p->PushPack(V_INT32, "waitDongZuoDelay");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_SIT_RESP, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        p->PushPack(V_INT32, "chatType");
        p->PushPack(V_INT32, "isSplit");
        p->PushPack(V_INT32, "packOrder");
        p->PushPack(V_STR, "chatMsg");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_CHAT_RESP, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_READY_RESP, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        p->PushPack(V_INT32, "isTrust");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_TRUST_RESP, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_SWAP_CARD_RESP, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "code");
		p->PushPack(V_STR, "msg");
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_SEL_DEL_SUIT_RESP, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        // begin cards:[]
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_INT32);
        p->PushPack(V_OBJ_ARY, "curCards", pvo1);           // cur left cards 这里是为了客户端出牌的时候先扔掉牌，根据返回包再处理，防止卡牌出现
        // end cards
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_DISCARD_RESP, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "code");
		p->PushPack(V_STR, "msg");
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_QUEST_CTRL_TABLE_RESP, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "code");
		p->PushPack(V_STR, "msg");
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_LEAVE_RESP, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "code");
		p->PushPack(V_STR, "msg");
		p->PushPack(V_STR, "tingInfo");
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_GET_TINGINFO_RESP, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "code");
		p->PushPack(V_STR, "msg");
		// 再发一次手牌同步一下
		pvo3 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo3, V_INT32);
		p->PushPack(V_OBJ_ARY, "selfCards", pvo3);
		// 自己的动作列表 [{}]
		pvo2 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo2, V_INT32, "a");   // actionName
		PushItemToVector(pvo2, V_STR, "e");		// expandStr
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);             
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_ERROR_ACTION_RESP, p));

        //////////////////////////////////////////////////////////////////////////
        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "tableHandle");
        p->PushPack(V_INT32, "tbState");                    // table State
        p->PushPack(V_INT32, "chairIndex");
        p->PushPack(V_INT32, "isReady");                    // self is ready
        p->PushPack(V_INT32, "tuserState");                 // self tableUse1r State
        p->PushPack(V_INT32, "ZScore");                     // 积分局用到，这个人的开局后积分多少
        p->PushPack(V_INT32, "baseScore");
        p->PushPack(V_INT32, "minBean");
        p->PushPack(V_INT32, "curRound");
        p->PushPack(V_INT32, "maxRound");
        p->PushPack(V_STR, "tableNum");
		p->PushPack(V_INT32, "eastP");						// 东风位置
		p->PushPack(V_INT32, "userCount");

        // 房间规则
        p->PushPack(V_INT32, "isChunJia");                 // self tableUse1r State
        p->PushPack(V_INT32, "isLaizi");                     // 积分局用到，这个人的开局后积分多少
        p->PushPack(V_INT32, "isGuaDaFeng");
        p->PushPack(V_INT32, "isSanQiJia");
        p->PushPack(V_INT32, "isDanDiaoJia");
        p->PushPack(V_INT32, "isZhiDuiJia");
        p->PushPack(V_INT32, "isZhanLiHu");
        p->PushPack(V_INT32, "isMenQing");               // 是否带站立胡
        p->PushPack(V_INT32, "isAnKe");                  // 是否带暗刻
        p->PushPack(V_INT32, "isKaiPaiZha");             // 是否带开牌炸
        p->PushPack(V_INT32, "isBaoZhongBao");           // 是否带宝中宝
        p->PushPack(V_INT32, "isHEBorHeiLongJiang");               // 0：哈尔滨 or 1：大庆玩法 
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_BEGINGAME_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "chairIndex");                 // 方位只是显示用，通知id是主要的，这样不容易出错
        p->PushPack(V_INT32, "isReady");                    // other is ready
        p->PushPack(V_INT32, "tuserState");                 // other tableUser State
        p->PushPack(V_INT32, "ZScore");                     // 积分局用到，这个人的开局后积分多少
		p->PushPack(V_STR, "ip");							// 玩家的ip
        // begin baseInfo:{}
        pvo1 = CreateUserBaseInfoStruct();
        p->PushPack(V_OBJ_STRUCT, "baseInfo", pvo1);
        // end baseInfo
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_OTHER_ENTER_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "userId");
		p->PushPack(V_INT32, "place");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_OTHER_LEAVE_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "code");
        p->PushPack(V_STR, "msg");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_FORCE_LEAVE_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "userId");
        p->PushPack(V_INT32, "chatType");
        p->PushPack(V_INT32, "isSplit");
        p->PushPack(V_INT32, "packOrder");
        p->PushPack(V_STR, "chatMsg");
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_OTHER_CHAT_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "userId");                     // who is ready
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_OTHER_READY_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "userId");                     // who
		p->PushPack(V_INT32, "place");                     // who
        p->PushPack(V_INT32, "tuserState");                 // other tableUser State
        p->PushPack(V_INT64, "bean");                       // bean changed when offline return
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_OTHER_STATE_NOTIFY, p));

        p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "tbState");                // table State
        p->PushPack(V_INT32, "curPlace");               // 当前轮到谁
        p->PushPack(V_INT32, "decTimeCount");           // 倒计时
		p->PushPack(V_INT32, "tS");						// timeState 时钟状态
		p->PushPack(V_INT32, "eastP");					// 东风位置
		p->PushPack(V_INT32, "bankerP");			    // 庄家位置，起手拿14张牌的玩家
		p->PushPack(V_INT32, "lastChuPaiPlace");		// 上次出牌玩家
		p->PushPack(V_INT32, "lastChuPaiCard");			// 上次出牌
		p->PushPack(V_INT32, "hasSwaped");			    // 自己是否已经换牌了。
		p->PushPack(V_INT32, "SDirect");				// 换牌的方向
		// 局数信息
		p->PushPack(V_INT32, "curR");					// 当前进行的局数
		p->PushPack(V_INT32, "totalR");					// 总共的局数
        p->PushPack(V_INT32, "isMoPai");				// 是否已经摸宝了 1:已经摸了 0:没有
		p->PushPack(V_INT32, "peopleNum");
 		// 各玩家牌墙
		p->PushPack(V_INT32, "startP");					// 牌墙起手摸牌位置
		p->PushPack(V_INT32, "PQCurrP");		        // 牌墙当前摸牌位置
			pvo3 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo3, V_INT32);
		p->PushPack(V_OBJ_ARY, "leftWallCount", pvo3);  // 剩余牌墙数量
		p->PushPack(V_OBJ_ARY, "wallCount", pvo3);      // 起始牌墙数量
  		// 自己的手牌
  			pvo3 = new T_VECTOR_VTYPE_OBJECT();
  			PushItemToVector(pvo3, V_INT32);
  		p->PushPack(V_OBJ_ARY, "selfCards", pvo3);
		// 自己在换牌阶段换出了什么牌
			pvo3 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo3, V_INT32);
		p->PushPack(V_OBJ_ARY, "selfGetSwapCds", pvo3);
  		// 自己的动作列表 [{}]
  			pvo2 = new T_VECTOR_VTYPE_OBJECT();
  			PushItemToVector(pvo2, V_INT32, "a");   // actionName
  			PushItemToVector(pvo2, V_STR, "e");		// expandStr
  			pvo1 = new T_VECTOR_VTYPE_OBJECT();
  			PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
  		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
 		// 各玩家的明牌列表 [{"data": [{}]}] -- 
  			pvo4 = new T_VECTOR_VTYPE_OBJECT();
  			PushItemToVector(pvo4, V_INT32, "a");             // actionName
			PushItemToVector(pvo4, V_INT32, "lP");			  // lastPlace 谁打出的牌
			PushItemToVector(pvo4, V_STR, "c");        
  			pvo3 = new T_VECTOR_VTYPE_OBJECT();
  			PushItemToVector(pvo3, V_OBJ_STRUCT, NULL, pvo4);
  			pvo2 = new T_VECTOR_VTYPE_OBJECT();
  			PushItemToVector(pvo2, V_OBJ_ARY, "data", pvo3);  
  			pvo1 = new T_VECTOR_VTYPE_OBJECT();
  			PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
  		p->PushPack(V_OBJ_ARY, "mingPai", pvo1);
   		// 各玩家的桌牌列表
    		pvo3 = new T_VECTOR_VTYPE_OBJECT();
    		PushItemToVector(pvo3, V_INT32);
    		pvo2 = new T_VECTOR_VTYPE_OBJECT();
    		PushItemToVector(pvo2, V_OBJ_ARY, "data", pvo3);   // actionName
    		pvo1 = new T_VECTOR_VTYPE_OBJECT();
    		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
    	p->PushPack(V_OBJ_ARY, "zhuoPai", pvo1);
   		// 各玩家的 gameInfo [{}]
			pvo3 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo3, V_INT32);
			pvo2 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo2, V_INT32, "userId");
			PushItemToVector(pvo2, V_INT32, "cardCount");       // 断线返回只发送数量，计算结果后，显示结果状态断线就直接删除用户了，不会返回
			pvo1 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "users", pvo1);              // 每个玩家信息
			m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_SYN_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "userId");                     // who
        p->PushPack(V_INT32, "isTrust");                    // 是否托管了
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_OTHER_TRUST_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "dice0");                  // 第一个骰子的值1-6
		p->PushPack(V_INT32, "dice1");                  // 第二个骰子的值1-6
		p->PushPack(V_INT32, "eastP");					// 东风位置
		p->PushPack(V_INT32, "bankerP");			    // 庄家位置，起手拿14张牌的玩家
		p->PushPack(V_INT32, "curRound");
		p->PushPack(V_INT32, "maxRound");
		p->PushPack(V_INT32, "startP");					// 牌墙起手摸牌位置
		p->PushPack(V_INT32, "PQCurrP");		        // 牌墙当前摸牌位置
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_INT32);
		p->PushPack(V_OBJ_ARY, "leftWallCount", pvo1);  // 剩余牌墙数量
		p->PushPack(V_OBJ_ARY, "wallCount", pvo1);      // 起始牌墙数量
		// begin cards:[]
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_INT32);
        p->PushPack(V_OBJ_ARY, "cards", pvo1);              // 自己的牌
        // end cards
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_DEALCARD_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "wP");				// wallPlace 当前牌墙玩家
        p->PushPack(V_INT32, "wC");				// wallCount 当前牌墙剩余的牌数量
        p->PushPack(V_INT32, "flag");			// 0:首次产生宝牌  1：换宝
        p->PushPack(V_INT32, "lastBaoCardID");	// 如果为换宝，则为被换掉的宝牌
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_MO_BAO_NOTIFY, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "dice");
		p->PushPack(V_INT32, "swapDirction");
		p->PushPack(V_INT32, "decTimeCount");
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_INT32);
		p->PushPack(V_OBJ_ARY, "cards", pvo1);              // 自己的牌
		p->PushPack(V_OBJ_ARY, "addCards", pvo1);           // addCards
		p->PushPack(V_OBJ_ARY, "delCards", pvo1);           // delCards
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_SWAP_CARD_NOTIFY, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "p");              // dongZuoPlace, 碰杠玩家
		p->PushPack(V_INT32, "c");				// 吃的那张牌
		p->PushPack(V_INT32, "order");		    // 吃顺序， 0：X23， 1：1X3, 2:12X
		p->PushPack(V_INT32, "a");				// actionName
		p->PushPack(V_INT32, "lP");				// lastPlace 谁打出的牌
		p->PushPack(V_INT32, "cP");				// currPlace 当前玩家
		p->PushPack(V_INT32, "tS");				// timeState 时钟状态
		p->PushPack(V_INT32, "dT");				// dicTime 倒计时
		// 自己的动作列表
		pvo2 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo2, V_INT32, "a");   // actionName
		PushItemToVector(pvo2, V_STR, "e");		// expandStr
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
		m_methodsToWsClient.insert(make_pair(MGSID_CLIENT_G_CHI_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "p");              // dongZuoPlace, 听吃玩家
        p->PushPack(V_INT32, "c");				// 吃的那张牌
        p->PushPack(V_INT32, "order");		    // 吃顺序， 0：X23， 1：1X3, 2:12X
        p->PushPack(V_INT32, "a");				// actionName
        p->PushPack(V_INT32, "chuP");			// chuPlace 谁打出的牌被吃了
        p->PushPack(V_INT32, "cc");				// chu card 出的牌
        p->PushPack(V_INT32, "lP");				// lastPlace 谁打出的牌
        p->PushPack(V_INT32, "cP");				// currPlace 当前玩家
        p->PushPack(V_INT32, "tS");				// timeState 时钟状态
        p->PushPack(V_INT32, "dT");				// dicTime 倒计时
        // 自己的动作列表
        pvo2 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo2, V_INT32, "a");   // actionName
        PushItemToVector(pvo2, V_STR, "e");		// expandStr
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
        p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
        m_methodsToWsClient.insert(make_pair(MGSID_CLIENT_G_TING_CHI_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "p");              // dongZuoPlace, 听碰玩家
        p->PushPack(V_INT32, "c");				// 碰的那张牌
        p->PushPack(V_INT32, "a");				// actionName
        p->PushPack(V_INT32, "chuP");			// chuPlace 谁打出的牌被吃了
        p->PushPack(V_INT32, "cc");				// chu card 出的牌
        p->PushPack(V_INT32, "lP");				// lastPlace 谁打出的牌
        p->PushPack(V_INT32, "cP");				// currPlace 当前玩家
        p->PushPack(V_INT32, "tS");				// timeState 时钟状态
        p->PushPack(V_INT32, "dT");				// dicTime 倒计时
        // 自己的动作列表
        pvo2 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo2, V_INT32, "a");   // actionName
        PushItemToVector(pvo2, V_STR, "e");		// expandStr
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
        p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
        m_methodsToWsClient.insert(make_pair(MGSID_CLIENT_G_TING_PENG_NOTIFY, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "p");   // place
		// 杠出去的牌
			pvo1 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo1, V_INT32);
		p->PushPack(V_OBJ_ARY, "gangCards", pvo1);              
		// 自己的动作列表
			pvo2 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo2, V_INT32, "a");   // actionName
			PushItemToVector(pvo2, V_STR, "e");		// expandStr
			pvo1 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_SPECIAL_GANG_NOTIFY, p));

		p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "p");              // 听牌玩家
        p->PushPack(V_INT32, "c");				// card 出的牌
        p->PushPack(V_INT32, "cP");				// currPlace 当前玩家
        p->PushPack(V_INT32, "tS");				// timeState 时钟状态
        p->PushPack(V_INT32, "dT");				// dicTime 倒计时
		// 自己的动作列表
		pvo2 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo2, V_INT32, "a");   // actionName
		PushItemToVector(pvo2, V_STR, "e");		// expandStr
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_TING_PAI_NOTIFY, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "p");              // moPaiPlace, 摸牌玩家
	 	p->PushPack(V_INT32, "c");				// card 摸到的牌
		p->PushPack(V_INT32, "g");				// isGangMo 是否是杠后补张
		p->PushPack(V_INT32, "wP");				// wallPlace 当前牌墙玩家
		p->PushPack(V_INT32, "wC");				// wallCount 当前牌墙剩余的牌数量
		p->PushPack(V_INT32, "cP");				// currPlace 当前玩家
		p->PushPack(V_INT32, "tS");				// timeState 时钟状态
		p->PushPack(V_INT32, "dT");				// dicTime 倒计时
			// 自己的动作列表
			pvo2 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo2, V_INT32, "a");   // actionName
			PushItemToVector(pvo2, V_STR, "e");		// expandStr
			pvo1 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
		m_methodsToWsClient.insert(make_pair(MGSID_CLIENT_G_MO_PAI_NOTIFY, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "p");              // chuPaiPlace, 出牌玩家
		p->PushPack(V_INT32, "c");				// card 出的牌
		p->PushPack(V_INT32, "cP");				// currPlace 当前玩家
		p->PushPack(V_INT32, "tS");				// timeState 时钟状态
		p->PushPack(V_INT32, "dT");				// dicTime 倒计时
		// 自己的动作列表
			pvo2 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo2, V_INT32, "a");   // actionName
			PushItemToVector(pvo2, V_STR, "e");		// expandStr
			pvo1 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
		m_methodsToWsClient.insert(make_pair(MGSID_CLIENT_G_CHU_PAI_NOTIFY, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "p");              // dongZuoPlace, 碰杠玩家
		p->PushPack(V_INT32, "c");				// 碰杠的那张牌
		p->PushPack(V_INT32, "a");				// actionName
		p->PushPack(V_INT32, "lP");				// lastPlace 谁打出的牌
		p->PushPack(V_INT32, "cP");				// currPlace 当前玩家
		p->PushPack(V_INT32, "tS");				// timeState 时钟状态
		p->PushPack(V_INT32, "dT");				// dicTime 倒计时
		// 自己的动作列表
			pvo2 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo2, V_INT32, "a");   // actionName
			PushItemToVector(pvo2, V_STR, "e");		// expandStr
			pvo1 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
		m_methodsToWsClient.insert(make_pair(MGSID_CLIENT_G_PENG_GANG_NOTIFY, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "p");              // 胡牌玩家
		p->PushPack(V_INT32, "isZiMo");		    // 是否自摸
		p->PushPack(V_INT32, "lP");				// 如果不是自摸，点炮玩家
		p->PushPack(V_INT32, "lC");				// 所胡牌(炮牌或者自己摸到的牌，客户端要放到胡牌串里)
		p->PushPack(V_INT32, "huCount");        // 这个一炮几响， 
		p->PushPack(V_INT32, "cP");				// currPlace 当前玩家
		p->PushPack(V_INT32, "tS");				// timeState 时钟状态
		p->PushPack(V_INT32, "dT");				// dicTime 倒计时
		p->PushPack(V_INT32, "isQ");			// 是否是抢杠胡牌，如果是抢杠胡牌，要还原抢杠数据
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_INT32);
		p->PushPack(V_OBJ_ARY, "zScores", pvo1);  // 当前分数
		// 玩家当前的分数

		// 自己的动作列表
			pvo2 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo2, V_INT32, "a");   // actionName
			PushItemToVector(pvo2, V_STR, "e");		// expandStr
			pvo1 = new T_VECTOR_VTYPE_OBJECT();
			PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
			p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_HU_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "U0");                 
		p->PushPack(V_INT32, "U1");                 
		p->PushPack(V_INT32, "U2");                
		p->PushPack(V_INT32, "U3");     
		p->PushPack(V_INT32, "p");             // currPlace
		p->PushPack(V_INT32, "dT");			   // decTimeCount	
		// 自己的动作列表
		pvo2 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo2, V_INT32, "a");   // actionName
		PushItemToVector(pvo2, V_STR, "e");		// expandStr
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "mjAction", pvo1);              // 每个玩家信息
        // end cards
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_SEL_DEL_SUIT_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "discardUserId");               // 谁出牌了【第一次为-1，表示仅通知谁出牌】
        p->PushPack(V_INT32, "leftCardCount");              // 出牌后剩余多少张，，第一次没用
        // begin cards:[]
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_INT32);
        p->PushPack(V_OBJ_ARY, "cards", pvo1);              // 出的什么牌，第一次没用
        // end cards
        p->PushPack(V_INT32, "curUserId");                  // 当前轮到谁出牌了，-1表示完成出牌流程，要等待
        p->PushPack(V_INT32, "curMulti");                   // 当前倍数变成了多少，炸弹会翻倍
        p->PushPack(V_INT32, "decTimeCount");               // 倒计时多少秒，完成的情况下，这个字段没用
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_DISCARD_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "baseScore");                  // 底注
		p->PushPack(V_INT32, "curRound");                   // 当前局
        p->PushPack(V_INT32, "baoCardID");                  // 宝
		// begin 玩家的分数信息 [{}]
		pvo2 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo2, V_INT32, "sumFans");			// 本局的得失番数
		PushItemToVector(pvo2, V_INT32, "incZScore");		// 玩家增长的分数
		PushItemToVector(pvo2, V_INT32, "ZScore");			// 玩家游戏进行到现在的分数
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "scores", pvo1);              // 每个玩家信息
		// end 玩家的分数信息 [{}]
		// begin 自己的得失番信息 [{}]
		pvo3 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo3, V_INT32);
		pvo2 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo2, V_INT32, "isWinner");
		PushItemToVector(pvo2, V_INT32, "isZiMo");
		PushItemToVector(pvo2, V_INT32, "otherPlace");
		PushItemToVector(pvo2, V_INT32, "scores");
        PushItemToVector(pvo2, V_INT32, "huCardId");
		PushItemToVector(pvo2, V_OBJ_ARY, "fanZhong", pvo3);
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "result0", pvo1);              // 每个玩家信息
		p->PushPack(V_OBJ_ARY, "result1", pvo1);              // 每个玩家信息
		p->PushPack(V_OBJ_ARY, "result2", pvo1);              // 每个玩家信息
		p->PushPack(V_OBJ_ARY, "result3", pvo1);              // 每个玩家信息

		// end 自己的得失番信息
		// begin 所有玩家的牌
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_INT32);
		p->PushPack(V_OBJ_ARY, "cards0", pvo1);              
		p->PushPack(V_OBJ_ARY, "cards1", pvo1);              // 自己的牌
		p->PushPack(V_OBJ_ARY, "cards2", pvo1);              // 自己的牌
		p->PushPack(V_OBJ_ARY, "cards3", pvo1);              // 自己的牌
		// end 所有玩家的牌
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_RESULT_NOTIFY, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "isForceLeave");
		p->PushPack(V_INT32, "needShow");
		p->PushPack(V_INT32, "createPlace");
		pvo2 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo2, V_INT32, "cntZiMoHu");			// 自摸胡次数
		PushItemToVector(pvo2, V_INT32, "cntZhuoPaoHu");		// 捉炮胡次数
		PushItemToVector(pvo2, V_INT32, "cntDianPao");			// 点炮次数
		PushItemToVector(pvo2, V_INT32, "cntMingGang");			// 明杠次数
		PushItemToVector(pvo2, V_INT32, "cntAnGang");			// 暗杠次数
		PushItemToVector(pvo2, V_INT32, "ZScore");				// 积分 
		PushItemToVector(pvo2, V_INT32, "userId");				// 玩家的id
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "countInfo", pvo1);              // 每个玩家的统计信息
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_END_ROUND, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "ctrlCode");                  // 0: 询问是否同意散桌， 1： 告知玩家散桌
		p->PushPack(V_INT32, "userId");                    // ctrlCode=0 表示请求散桌玩家，ctrlCode=1 表示本次应答玩家玩家
		p->PushPack(V_INT32, "isAgree");                   // ctrlCode=0 时无意义，ctrlCode=1 表示玩家是否同意
		p->PushPack(V_INT32, "decTimeCount");              // 散桌倒计时
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_DISBAND_TABLE_NOTIFY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "bltType");                    // 公告类型
        p->PushPack(V_STR, "btlMsg");                       // 公告消息
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_BULLETIN_NOTIFY, p));

        p = new _SEntityDefMethods;
        pvo2 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo2, V_INT32, "userId");
        PushItemToVector(pvo2, V_INT64, "incSpecialGold");
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
        p->PushPack(V_OBJ_ARY, "consumeSpecialGold", pvo1);
        m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_CONSUME_SPECIAL_GOLD_NOTIFY, p));

		p = new _SEntityDefMethods;
		m_methodsToWsClient.insert(make_pair(MSGID_CLIENT_G_DO_READY_NOTIFY, p));
    }
#endif

    //client -> gamearea
    {
        T_VECTOR_VTYPE_OBJECT* pvo1 = NULL; // 第1层
		T_VECTOR_VTYPE_OBJECT* pvo2 = NULL; // 第1层
		T_VECTOR_VTYPE_OBJECT* pvo3 = NULL; // 第1层

        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->PushPack(V_STR, "accessToken");
        p->PushPack(V_STR, "mac");
        p->PushPack(V_INT32, "whereFrom");              // 0未知，1表示PC，2表示手机
        p->PushPack(V_INT32, "version");                // 客户端版本号
        m_methods.insert(make_pair(MSGID_CLIENT_LOGIN, p));

        p = new _SEntityDefMethods;
        m_methods.insert(make_pair(MSGID_CLIENT_UPDATE_USERINFO, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_UINT32, "tick");                  // client Mstick 服务端会原样返回，客户端可以计算网速
        m_methods.insert(make_pair(MSGID_CLIENT_ONTICK, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_FLOAT64, "jingdu");               // 经度   0.0表示未知位置
		p->PushPack(V_FLOAT64, "weidu");                // 纬度   0.0表示未知位置
		p->PushPack(V_INT32, "isFind");                 // 是否为查找
		p->PushPack(V_INT32, "selScore");               // 创建桌子：选择的底分
		p->PushPack(V_INT32, "totalRound");             // 创建桌子：最多玩多少局
		p->PushPack(V_INT32, "vipRoomType");            // 创建桌子：桌子的类型是什么（1是金币局，2是记分局,台费由所有人出，3是记分局，台费由房主承担）

        p->PushPack(V_INT32, "isChunJia");              // 是否为纯夹
        p->PushPack(V_INT32, "isLaizi");                // 是否带红中癞子	
        p->PushPack(V_INT32, "isGuaDaFeng");			// 是否带刮大风
        p->PushPack(V_INT32, "isSanQiJia");				// 是否带三期夹	
        p->PushPack(V_INT32, "isDanDiaoJia");           // 是否带单吊夹
        p->PushPack(V_INT32, "isZhiDuiJia");            // 是否带支对胡    
        p->PushPack(V_INT32, "isZhanLiHu");             // 是否带站立胡
        p->PushPack(V_INT32, "isMenQing");              // 是否带站立胡
        p->PushPack(V_INT32, "isAnKe");                 // 是否带站立胡
        p->PushPack(V_INT32, "isKaiPaiZha");            // 是否带站立胡
        p->PushPack(V_INT32, "isBaoZhongBao");           // 是否带宝中宝
        p->PushPack(V_INT32, "isHEBorHeiLongJiang");     // 0:哈尔滨玩法 1：黑龙江玩法
		p->PushPack(V_INT32, "isJiQiRen");

		p->PushPack(V_STR, "tableNum");                  // 查找的桌子序号
		m_methods.insert(make_pair(MSGID_CLIENT_SIT, p));

        //p = new _SEntityDefMethods;
        //p->PushPack(V_FLOAT64, "jingdu");               // 经度   0.0表示未知位置
        //p->PushPack(V_FLOAT64, "weidu");                // 纬度   0.0表示未知位置
        //p->PushPack(V_INT32, "isFind");                 // 是否为查找
        //p->PushPack(V_INT32, "selScore");               // 创建桌子：选择的底分
        //p->PushPack(V_INT32, "totalRound");             // 创建桌子：最多玩多少局
        //p->PushPack(V_INT32, "vipRoomType");            // 创建桌子：桌子的类型是什么（1是金币局，2是记分局,台费由所有人出，3是记分局，台费由房主承担）
        //p->PushPack(V_STR, "tableNum");                 // 查找的桌子序号
        //m_methods.insert(make_pair(MSGID_CLIENT_SIT, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "chatType");
        p->PushPack(V_INT32, "isSplit");
        p->PushPack(V_INT32, "packOrder");
        p->PushPack(V_STR, "chatMsg");                  // 消息
        m_methods.insert(make_pair(MSGID_CLIENT_CHAT, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT64, "i64param");               // int64参数，德州扑克带入金额可以用到
        m_methods.insert(make_pair(MSGID_CLIENT_READY, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "isTrust");                // 是否托管，0取消托管，1托管
        m_methods.insert(make_pair(MSGID_CLIENT_G_TRUST, p));

        p = new _SEntityDefMethods;
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_INT32);
		p->PushPack(V_OBJ_ARY, "cards", pvo1);
        m_methods.insert(make_pair(MSGID_CLIENT_G_SWAP_CARD, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "delSuit");
		m_methods.insert(make_pair(MSGID_CLIENT_G_SEL_DEL_SUIT, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "cardId");
		m_methods.insert(make_pair(MSGID_CLIENT_G_CHU, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "mjAction");// dongzuoName
		p->PushPack(V_STR, "eS");		 // expandStr	
		m_methods.insert(make_pair(MSGID_CLIENT_G_MJ_ACTION, p));

        p = new _SEntityDefMethods;
        // begin cards:[]
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_INT32);
        p->PushPack(V_OBJ_ARY, "cards", pvo1);          // 出的牌，需要倒序排列，不排列的直接返回出牌失败，减少排序的频率
        // end cards
        m_methods.insert(make_pair(MSGID_CLIENT_G_DISCARD, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_INT32, "ctrlCode");   // 0: 请求散桌， 1：应答其他玩家的散桌需求
		p->PushPack(V_INT32, "isAgree");    // ctrlCode=0 时无意义， 等于1时表示是否同意其他玩家散桌
		m_methods.insert(make_pair(MSGID_CLIENT_QUEST_CTRL_TABLE, p));

		p = new _SEntityDefMethods;
		m_methods.insert(make_pair(MSGID_CLIENT_QUEST_LEAVE, p));

		p = new _SEntityDefMethods;
		m_methods.insert(make_pair(MSGID_CLIENT_GET_TINGINFO, p));


		// "data": [{"gangFlag":0,"cards":""},{"gangFlag":2,"cards":"27,28,29,31,32"}]
		p = new _SEntityDefMethods;
		// 自己的动作列表
		pvo2 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo2, V_INT32, "gangFlag");   
		PushItemToVector(pvo2, V_STR, "cards");		
		pvo1 = new T_VECTOR_VTYPE_OBJECT();
		PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
		p->PushPack(V_OBJ_ARY, "data", pvo1);              // 每个玩家信息
		m_methods.insert(make_pair(MSGID_CLIENT_G_SPECIAL_GANG, p));
    }

    //all app
    {
        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->PushPack(V_UINT8);
        m_methods.insert(make_pair(MSGID_ALLAPP_SHUTDOWN_SERVER, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_INT32, "areaId");                     // 区域Id
        p->PushPack(V_INT32, "bltType");                    // 公告类型
        p->PushPack(V_STR, "btlMsg");                       // 公告消息
        m_methods.insert(make_pair(MSGID_CLIENT_BULLETIN_NOTIFY, p));
    }

    //AreaMgr
	{
		_SEntityDefMethods* p = new _SEntityDefMethods;
		p->PushPack(V_INT32);		// gameServerId
		p->PushPack(V_INT32);		// gameRoomId
		p->PushPack(V_UINT32);      // onlinenum
		p->PushPack(V_INT32);       // cpuUseRate
		p->PushPack(V_INT64);		// usedMemorySize
		p->PushPack(V_INT64);		// leftMemorySize
		p->PushPack(V_INT32);		// usedDeskCount
		p->PushPack(V_INT32);		// status
		//p->PushPack(V_INT32);       // area_num
		//p->PushPack(V_STR);         // ip
		//p->PushPack(V_UINT16);      // port
		//p->PushPack(V_INT32);       // table_count
		m_methods.insert(make_pair(MSGID_AREAMGR_UPDATE_AREA, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_UINT32);      //taskid
		p->PushPack(V_INT32);		// gameSeverId
		p->PushPack(V_INT32);		// areaNum
		p->PushPack(V_INT32);		// isMaster
		p->PushPack(V_INT32);		// masterFsId
		p->PushPack(V_INT32);		// gameRoomId
		p->PushPack(V_INT64);		// totalMemorySize
		p->PushPack(V_INT32);		// maxPlayers
		p->PushPack(V_INT32);		// deskCount
		p->PushPack(V_STR);			// gameServerIp
		p->PushPack(V_UINT16);		// gameServerPort
		p->PushPack(V_STR);			// maxJingDu
		p->PushPack(V_STR);			// minJingDu
		p->PushPack(V_STR);			// maxWeiDu
		p->PushPack(V_STR);			// minWeiDu
		p->PushPack(V_STR);			// minBean	
		m_methods.insert(make_pair(MSGID_AREAMGR_START_REPORT, p));
	}

	// areamgr->gamearea 
	{
		_SEntityDefMethods* p = new _SEntityDefMethods;
		p->PushPack(V_UINT32);          //taskid
		p->PushPack(V_INT32);           //retCode 0=success
		p->PushPack(V_STR);             //retErrorMsg
		p->PushPack(V_INT32);           //fsId
		p->PushPack(V_INT32);           //gameServerId
		m_methods.insert(make_pair(MSGID_AREA_START_REPORT_CALLBACK, p));
	}

    //dbmgr
    {
        T_VECTOR_VTYPE_OBJECT* pvo1 = NULL; // 第1层
        T_VECTOR_VTYPE_OBJECT* pvo2 = NULL;

        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->PushPack(V_UINT32);          //taskid
        p->PushPack(V_INT32);           //userId
        p->PushPack(V_STR);             //accesstoken, 可选，有这个就不用userID了。
		p->PushPack(V_INT32);			//gameLock
		p->PushPack(V_INT32);			//gameRoomId
        m_methods.insert(make_pair(MSGID_DBMGR_READ_USERINFO, p));
            
        p = new _SEntityDefMethods;
        p->PushPack(V_UINT32);          //taskid
        p->PushPack(V_UINT32);          //serverId
		p->PushPack(V_INT32);			//gameRoomId
		p->PushPack(V_INT32);			//isLockGameRoom
        p->PushPack(V_STR);             //openSeriesNum
        p->PushPack(V_STR);             //gameStartMsStamp
        p->PushPack(V_INT32);           //basescore
        p->PushPack(V_INT32);           //roundFee
        p->PushPack(V_INT32);           //isVipRoomEnd vip包房是否结束 
		p->PushPack(V_STR);           //tableId 桌号
		p->PushPack(V_INT32);           //curInning 当前局数
        //begin scorelist [{userId IsFlee WinOrLose}]
        pvo2 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo2, V_INT32);            //userId
        PushItemToVector(pvo2, V_UINT8);            //isFlee
        PushItemToVector(pvo2, V_INT32);            //bean
        // struct
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
        // array
        p->PushPack(V_OBJ_ARY, "", pvo1);
        //end scorelist
        m_methods.insert(make_pair(MSGID_DBMGR_REPORT_SCORE, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_UINT32);              //taskId  
        p->PushPack(V_UINT32);              //serverId
		p->PushPack(V_INT32);				//gameRoomId
        p->PushPack(V_INT32);               //tableHandle
        p->PushPack(V_STR);                 //openSeriesNum
        //begin scorelist [{userId consumeNum}]
        pvo2 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo2, V_INT32);        //userId
        PushItemToVector(pvo2, V_INT32);        //consumeNum
        PushItemToVector(pvo2, V_STR);          //remark
        //struct
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
        //array
        p->PushPack(V_OBJ_ARY, "", pvo1);
        //end consume specialGold list
        m_methods.insert(make_pair(MSGID_DBMGR_CONSUME_SPECIAL_GOLD, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_UINT32);					// taskId
		p->PushPack(V_INT32);					// gameRoomId
		p->PushPack(V_INT32);					// userId
		p->PushPack(V_INT32);					// type
		m_methods.insert(make_pair(MSGID_DBMGR_LOCK_GAMEROOM, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_UINT32);					// taskId
        p->PushPack(V_UINT32);					// serverId
        p->PushPack(V_INT32);					// gameRoomId
        p->PushPack(V_STR);						// openSeriesNum
        p->PushPack(V_STR);						// openSeriesNums
        p->PushPack(V_INT32);					// vipRoomType
        p->PushPack(V_STR);						// tableId
        p->PushPack(V_INT32);					// innings
        p->PushPack(V_STR);						// fstStartMsStamp
        p->PushPack(V_STR);						// gameEndMsStamp
        //begin scorelist [{userId IsFlee WinOrLose}]
        pvo2 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo2, V_INT32);        // userId
        PushItemToVector(pvo2, V_STR);			// userName
        PushItemToVector(pvo2, V_INT32);        // totalScore
        // struct
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
        // array
        p->PushPack(V_OBJ_ARY, "", pvo1);
        //end scorelist
        m_methods.insert(make_pair(MSGID_DBMGR_REPORT_TOTAL_SCORE, p));
		p = new _SEntityDefMethods;
		p->PushPack(V_UINT32);              // taskId  
		p->PushPack(V_INT32);               // flag（1：开桌，2：退桌退房卡，3：退桌不退房卡，4：清除所有游戏房间）
		p->PushPack(V_INT32);				// playTypeId
		p->PushPack(V_INT32);				// gameRoomId
		p->PushPack(V_INT32);				// gameServerId
		p->PushPack(V_INT32);				// userId
		p->PushPack(V_STR);					// tableNum
		p->PushPack(V_INT32);				// maxRound
		p->PushPack(V_INT32);				// specialGold
		p->PushPack(V_INT32);				// vipRoomType
		p->PushPack(V_STR);					// option (房间玩法选项字符串)
		m_methods.insert(make_pair(MSGID_DBMGR_REPORT_TABlE_MANAGER, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_UINT32);              // taskId
		p->PushPack(V_STR);					// tableId
		p->PushPack(V_INT32);				// userId（房主的userId）
		p->PushPack(V_INT32);				// playTypeId
		p->PushPack(V_INT32);				// status
		m_methods.insert(make_pair(MSGID_DBMGR_REPORT_TABLE_START, p));
    }
 
    //dbmgr->gamearea
    {
        T_VECTOR_VTYPE_OBJECT* pvo1 = NULL; // 第1层
        T_VECTOR_VTYPE_OBJECT* pvo2 = NULL;

        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->PushPack(V_UINT32);          //taskid
        p->PushPack(V_INT32);           //retCode 0=success
        p->PushPack(V_STR);             //retErrorMsg
        p->PushPack(V_INT32);           //userId
        p->PushPack(V_INT32);           //userType
        p->PushPack(V_INT64);           //score
        p->PushPack(V_INT64);           //bean
        p->PushPack(V_STR);             //userName
        p->PushPack(V_STR);             //nickName
        p->PushPack(V_INT32);           //sex
        p->PushPack(V_INT32);           //level
        p->PushPack(V_INT32);           //faceId
        p->PushPack(V_STR);             //faceUrl
        p->PushPack(V_INT64);           //specialGold
		p->PushPack(V_STR);				//lastLoginIP
		p->PushPack(V_INT32);			//isVip
        m_methods.insert(make_pair(MSGID_AREA_READ_USERINFO_CALLBACK, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_UINT32);          //taskid
        p->PushPack(V_INT32);           //retCode 0=success
        p->PushPack(V_STR);             //retErrorMsg
        //begin scorelist [{userId score bean incScore incBean experience level}]
        pvo2 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo2, V_INT32);            //userId
        PushItemToVector(pvo2, V_INT64);            //score
        PushItemToVector(pvo2, V_INT64);            //bean
        PushItemToVector(pvo2, V_INT64);			//specialGold
        PushItemToVector(pvo2, V_INT64);            //incScore
        PushItemToVector(pvo2, V_INT64);            //incBean
        PushItemToVector(pvo2, V_INT32);            //experience
        PushItemToVector(pvo2, V_INT32);            //level
        PushItemToVector(pvo2, V_STR);              //expands
        // struct
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
        // array
        p->PushPack(V_OBJ_ARY, "", pvo1);
        //end scorelist
        m_methods.insert(make_pair(MSGID_AREA_REPORT_SCORE_CALLBACK, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_UINT32);                      //taskId
        p->PushPack(V_INT32);                       //retCode  0 = success
        p->PushPack(V_STR);                         //retErrorMsg
        //begin report consume specialGold  [{userId specialGold}]
        pvo2 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo2, V_INT32);            //userId
        PushItemToVector(pvo2, V_INT64);            //specialGold
        //struct
        pvo1 = new T_VECTOR_VTYPE_OBJECT();
        PushItemToVector(pvo1, V_OBJ_STRUCT, NULL, pvo2);
        //array
        p->PushPack(V_OBJ_ARY, "", pvo1);
        //end report consume specialGold list
        m_methods.insert(make_pair(MSGID_AREA_CONSUME_SPECIAL_GOLD_CALLBACK, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_UINT32);						// taskId
		p->PushPack(V_INT32);						// retCode
		p->PushPack(V_STR);							// retErrorMsg
		m_methods.insert(make_pair(MSGID_AREA_LOCK_GAMEROOM_CALLBACK, p));

        p = new _SEntityDefMethods;
        p->PushPack(V_UINT32);						// taskId
        p->PushPack(V_INT32);						// retCode
        p->PushPack(V_STR);							// retErrorMsg
        m_methods.insert(make_pair(MSGID_AREA_REPORT_TOTAL_SCORE_CALLBACK, p));
		p = new _SEntityDefMethods;
		p->PushPack(V_UINT32);						// taskId
		p->PushPack(V_INT32);						// retCode
		p->PushPack(V_STR);							// retErrorMsg
		m_methods.insert(make_pair(MSGID_AREA_REPORT_TABlE_MANAGER_CALLBACK, p));

		p = new _SEntityDefMethods;
		p->PushPack(V_UINT32);						// taskId
		p->PushPack(V_INT32);						// retCode
		p->PushPack(V_STR);							// retErrorMsg
		m_methods.insert(make_pair(MSGID_AREA_REPORT_TABLE_START_CALLBACK, p));
    }
}

void CRpcUtil::PushItemToVector(T_VECTOR_VTYPE_OBJECT* vct, VTYPE t, const char* vtName/*= NULL*/, T_VECTOR_VTYPE_OBJECT* o /*= NULL*/)
{
    VTYPE_OJBECT* pItem = new VTYPE_OJBECT();
    pItem->vt = t;
    if(NULL != vtName)
        pItem->vtName = vtName;
    if(NULL != o)
        pItem->o = o;
    vct->push_back(pItem);
}

T_VECTOR_VTYPE_OBJECT* CRpcUtil::CreateUserBaseInfoStruct()
{
    T_VECTOR_VTYPE_OBJECT* pvo1 = new T_VECTOR_VTYPE_OBJECT();
    PushItemToVector(pvo1, V_INT32, "userId");
    PushItemToVector(pvo1, V_INT32, "userType");
    PushItemToVector(pvo1, V_INT64, "score");
    PushItemToVector(pvo1, V_INT64, "bean");
    PushItemToVector(pvo1, V_STR, "userName");
    PushItemToVector(pvo1, V_STR, "nickName");
    PushItemToVector(pvo1, V_INT32, "sex");
    PushItemToVector(pvo1, V_INT32, "level");
    PushItemToVector(pvo1, V_INT32, "faceId");
    PushItemToVector(pvo1, V_STR, "faceUrl");
    PushItemToVector(pvo1, V_INT64, "specialGold");

    return pvo1;
}

CRpcUtil::~CRpcUtil()
{
    ClearMap(m_methods);
}

T_VECTOR_OBJECT* CRpcUtil::Decode(CPluto& u)
{
    u.Decode();
    pluto_msgid_t msg_id = u.GetMsgId();

    map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
    if(iter != m_methods.end())
    {
        T_VECTOR_VTYPE_OBJECT* refs = iter->second->m_argsType;
        int len = refs->size();
        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT();
        ll->reserve(len);

        for(int i = 0; i < len; i++)
        {
            VOBJECT* v = new VOBJECT;
            u.FillVObject((*refs)[i], *v);
            ll->push_back(v);

            if(u.GetDecodeErrIdx() > 0)
            {
                break;
            }
        }
        return ll;
    }

    return NULL;
}

#ifdef __WEBSOCKET_CLIENT
bool CRpcUtil::RpcEncodeJsonToPluto(AutoJsonHelper& aJs, CPluto& u)
{
    int tmpInt = 0;
    if (!aJs.GetJsonIntItem("action", tmpInt))
    {
        LogInfo("RpcEncodeJsonToPluto", "not action");
        return false;
    }

    pluto_msgid_t msgId = tmpInt;
    map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msgId);
    if(iter != m_methods.end())
    {
        T_VECTOR_VTYPE_OBJECT* refs = iter->second->m_argsType;
        int len = refs->size();
        u.EndRecv(0);
        u.Encode(msgId);
        for(int i = 0; i < len; i++)
        {
            if (!u.EncodeJsonToPluto((*refs)[i], aJs.GetJsonPtr(), NULL, u))
                return false;
        }

        u << EndPluto;

        return true;
    }

    return false;
}

bool CRpcUtil::RpcDecodePlutoToJson(cJSON* pJs, CPluto& u)
{
    pluto_msgid_t msgId = u.GetMsgId();
    map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methodsToWsClient.find(msgId);
    if(iter != m_methodsToWsClient.end())
    {
        cJSON_AddItemToObject(pJs, "action", cJSON_CreateNumber((double)msgId));

        T_VECTOR_VTYPE_OBJECT* refs = iter->second->m_argsType;
        int len = refs->size();
        u.Decode();
        for(int i = 0; i < len; i++)
        {
            if (!u.DecodePlutoToJson((*refs)[i], pJs, true, u))
                return false;
        }

        return true;
    }

    return false;
}
#endif


