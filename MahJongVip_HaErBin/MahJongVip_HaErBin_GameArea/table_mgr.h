#ifndef __TABLE__MGR__HEAD__
#define __TABLE__MGR__HEAD__

#include "win32def.h"
#include "util.h"
#include "memory_pool.h"
#include "json_helper.h"
#include "type_mogo.h"
#include "mailbox.h"
#include "type_area.h"
#include "epoll_server.h"
#include "type_card.h"
#include "mjDataMgr.h"
#include "mjActionMgr.h"
#include <stdlib.h>
#include <list>
using std::list;
#include <inttypes.h>


// 入座用户状态
enum
{
    tusNone = 0, 
    tusWaitNextRound = 1,           // 等待下一局游戏【可变人数游戏用到】【百家乐等百人游戏除外，游戏中进入也可以下注】
    tusNomal = 2, 
    tusOffline = 3, 
    tusFlee = 4,
};

// 桌子状态
enum
{
    tbsNone = 0,                    // 等待准备 或显示上一局结果，给客户端一定时间去显示结果, 这时可以正常离开游戏
    tbsDealCard = 1,                // 打骰子/拿牌/，属于游戏中了，
    tbsDiscard = 2,                 // 出牌
    tbsCalcResult = 3,              // 计算结果，上报积分的过程，游戏的最后一个阶段
	tbsShowTheLastCard = 4,			// 显示最后一张出牌
};

//桌子类型
enum
{
    vrtNone = 0,                        //桌子没有类型
    vrtBean = 1,                        //桌子的类型是金币局
    vrtScoreAllPay = 2,                 //桌子的类型是记分局，桌费由每个人平分
    vrtScoreOnePay = 3,                 //桌子的类型是记分局，桌费由房主承担
};

// 选漂类型
enum
{
	tptNone = 0,						// 桌子的选漂类型为定漂
	tptZiXuanPiao = 1,						// 桌子的选漂类型为自选漂
};

struct TMJHuPaiInfoItem;
struct TMJTingPaiInfoItem;
class CTableUser
{
public:
    CTableUser();
    ~CTableUser();

    void Clear();
	void RoundStopClearData();
	int getPiaoType();
public:
    int ustate;
	bool isRobot;
    int isReady;                    // 定义成int为了方便发包
    int isTrust;
	int manualTrust;				// 玩家主动点击的托管
    uint32_t readyOrLeaveTick;
    SUserInfo userInfo;
    CPlayerUserInfo player;
	int agreeEnd;                        // 是否同意了解散房间

	vector<int> selSwapCards;			 // 选择的换牌ID
	vector<int> getSwapCards;			 // 换牌阶段得到的牌的ID
	TMJCardSuit selDelSuit;				 // 选择的缺牌
	bool hasHu;							 // 是否已经胡牌	

	bool hasTing;						 // 是否已经听牌	 server only
	bool hasKaiMen;						 // 是否开门
	bool isHuaZhu;						 // 是否是花猪     server only
	vector<int> willHuCardID;			 // 玩家可以胡牌的牌列表  server only
	vector<int> hasHuCardID;			 // 玩家已经胡过的牌的列表  server only
	vector<TMJHuPaiInfoItem> huPaiInfo;  // 赢局信息   
	int winFan;                          // 总赢番数，正为赢，负为输  server only
	int piaoType;						 // 玩家每局开始的时候选择的漂的类型(0：无漂，1：漂1，2：漂2)

	int moCount4SpecialGang;                 // 玩家是否可以特殊杠

	int countZiMoHu;					 // 统计信息：自摸胡次数
	int countDianPaoHu;					 // 统计信息：点炮胡次数
	int countDianPao;					 // 统计信息：点炮次数
	int countMingGang;					 // 统计信息：明杠次数
	int countAnGang;					 // 统计信息：暗杠次数

    bool isSwaped;                  // server only 是否换牌
	int maxCardId;		            // server only 最大番种分数时所胡的牌
	vector<int> maxFanZhongInfo;    // server only 最大番种
    uint32_t offlineTick;           // server only
    int discardCount;               // server only 过牌几次牌
    uint32_t lastDiscardTick;       // server only 上次出牌的时间
	uint32_t lastQuestDisbandTick;  // server only 上次请求散桌时间
	uint32_t lastLeaveTimeTick;		// server only 上次在准备阶段断线的时间

	bool haveHuPass;				// 玩家是否有pass胡牌

	vector<TMJTingPaiInfoItem> tingPaiInfoArr;		// 听牌信息存储     
};

class CGameTable
{
public:
    CGameTable(int handle);
    ~CGameTable();

    int ProcClientChat(T_VECTOR_OBJECT* p, int chairIndex);
    int ProcClientReady(T_VECTOR_OBJECT* p, int chairIndex);
    int ProcClientTrust(T_VECTOR_OBJECT* p, int chairIndex);
    int ProcClientSwapCards(T_VECTOR_OBJECT* p, int chairIndex);
	int ProcClientSelDelSuit(T_VECTOR_OBJECT* p, int chairIndex);
	int procClientChu(T_VECTOR_OBJECT* p, int chairIndex);
	int procClientMJAction(T_VECTOR_OBJECT* p, int chairIndex);
	int ProcClientCtrlTable(T_VECTOR_OBJECT* p, int chairIndex);
	int ProcClientLeaveTable(T_VECTOR_OBJECT* p, int chairIndex);
	int ProcClientGetTingInfo(T_VECTOR_OBJECT* p, int chairIndex);
	int ProcClientSpecialGang(T_VECTOR_OBJECT* p, int chairIndex);
    void OnReportScoreError(int code, const char* errorMsg);
    void OnReportScoreSuccess(T_VECTOR_OBJECT* p, int index);
    void OnReportConsumeSpecialGoldError(T_VECTOR_OBJECT* p, int index);
    void OnReportConsumeSpecialGoldSuccess(T_VECTOR_OBJECT* p, int index);
    void OnReportTotalScoreCallBack(int code, const char* errorMsg);

    bool CheckRunTime();
    void SetNotActive();
	bool EnterTable(SUserInfo* pUser, int chairIndex, bool isRobot);            // 入座，可能是断线返回
	void RobotEnterTable();							                    // 机器人 进入房间
    bool LeaveTable(int userId);                                                // 离开座位，可能引起断线
    CTableUser* OnlyNomalLeaveTable(int userId, bool& mayOffline);              // 只可以正常离开，不会引起断线

    void ClientUpdateUserInfo(SUserBaseInfo& baseInfo, int chairIndex);
    void SendStartGameNotify(int chairIndex);
    int GetEmptyChairAry(int* chairAry);
	int GetEmptyChairIndex();

	void DoUserTrust(CTableUser* pTUser, int isTrust, int ignoreUserId);
	void endXingPaiCalcResult();

	void debugTotalScore();
	void writeTotalScore2Pluto(CPluto* pu);

	CTableUser* FindUserById(int userId);                   // 根据id查找用户，入座的用户
	CTableUser* FindUserByChairIndex(int chairIndex);       // 根据index查找用户，包括未入座的用户
	CTableUser* FindSitUserByChairIndex(int chairIndex);    // 根据index查找用户，不包括未入座的用户

	void GenerateOptionStr();
    void SetTableRule(TTableRuleInfo tableRule);            // 设置房间规则

    inline int GetHandle() const
    {
        return m_handle;
    }
    inline bool GetIsActive() const
    {
        return m_isActive;
    }
    inline int GetTstate() const
    {
        return m_tstate;
    }
    inline bool IsGaming()
    {
        return m_tstate >= tbsDealCard;
    }
    inline int GetCurUserCount() const
    {
        return m_sitUserList.size();
    }
    inline bool IsChairIndexValid(int chairIndex)
    {
        return (chairIndex >= 0) && (chairIndex < MAX_TABLE_USER_COUNT);
    }
	inline bool isCardValid(int cardId)
	{
		return(cardId >= 0) && (cardId < MJDATA_TYPE_COUNT);
	}
    inline bool HasFd(CTableUser* pTUser)
    {
        return (pTUser->ustate != tusNone && pTUser->ustate <= tusNomal);
    }
    inline int GetCurBaseScore() const
    {
        return m_curBaseScore;
    }
    inline void SetCurBaseScore(int baseScore)
    {
        m_curBaseScore = baseScore;
    }
    inline int GetMinBean() const
    {
        return m_minBean;
    }
    inline void SetMinBean(int minBean)
    {
        m_minBean = minBean;
    }
    inline int GetCreateUserId() const
    {
        return m_createUserId;
    }
    inline void SetCreateUserId(int userId)
    {
        m_createUserId = userId;
    }
    inline int GetMaxRound() const
    {
        return m_maxRound;
    }
    inline void SetMaxRound(int maxRound)
    {
        m_maxRound = maxRound;
        m_curRound = 1;
    }
    inline string GetTableNum() const
    {
        return m_tableNum;
    }
    inline void SetTableNum(string& tableNum)
    {
        m_tableNum = tableNum;
    }
    inline int GetMinSpecialGold() const
    {
        return m_minSpecialGold;
    }
    inline void SetMinSpecialGold(int minSpecialGold)
    {
        m_minSpecialGold = minSpecialGold;
    }
    inline int GetVipRoomType() const
    {
        return m_vipRoomType;
    }
    inline void SetVipRoomType(int roomType)
    {
        m_vipRoomType = roomType;
    }
    inline bool GetIsConsumeSpecialGold() const
    {
        return m_isConsumeSpecialGold;
    }
    inline void SetIsConsumeSpecialGold(bool isConsumeSpecialGold)
    {
        m_isConsumeSpecialGold = isConsumeSpecialGold;
    }
	inline bool isHuUser(int place) const
	{
		if ((place < 0) || (place >= 4))
			return false;
		return m_userList[place]->hasHu;
	}
	inline bool isCurrUserHasHu() const
	{
		return isHuUser(m_mjDataMgr.FCurrPlace);
	}
	inline bool isEndGame() 
	{
		return m_mjDataMgr.FMJDeck->isHuangPai();
	}
	inline uint32_t GetDisBandInterval()
	{
		if (0 == m_lastDisbandTime)
			return 2000000000;
		else
			return (GetNowMsTick() - m_lastDisbandTime) / 1000;
	}
	inline bool GetIsCreated()
	{
		return m_isCreated;
	}
	inline void SetIsCreated(bool isCreated)
	{
		LogInfo("CGameTable::SetIsCreated", "isCreated = %d", isCreated);
		m_isCreated = isCreated;
	}
	inline const string& GetOptionStr()
	{
		return m_optionStr;
	}
private:
    void RunTime();
    void RobotAction();
    void SetIsActive();
    void ClearTableUser(int errCode, const char* errMsg);
    void NoUserClearData();
    void RoundStopClearData();
    void AddGameRound();
	void AddUser(SUserInfo* pUser, int chairIndex, bool isRebot);
    void ClearUser(CTableUser* pTUser);                     // 清理用户，彻底离开桌子  外层不能用m_sitUserList循环
    CMailBox* GetTUserMailBox(CTableUser* pTUser);          // 获得mailbox，机器人和断线用户是NULL
    void ClearTotalScore();
    void CheckMayClearTotalScore();
    int32_t GetUserTotalScore(int userId);
    void AddUserTotalScore(int userId, int64_t incScore);
    
    void SendBroadTablePluto(CPluto* pu, int ignoreUserId); // pu will be deleted
    void SendPlutoToUser(CPluto* pu, CTableUser* pTUser);   // pu will be send or will be deleted if not find mailbox
    void SendForceLeaveNotify(CTableUser* pTUser, int code, const char* errorMsg);

    void DoUserReady(CTableUser* pTUser);
	void DoUserSwapCard(CTableUser* pTUser, vector<int>& selCardList);
	void DoUserDisbandTable(CTableUser* pTUser, int ctrlCode, int isAgree);
    void CheckCanDealCard();
    void StartDiscard();
    void StartReportScore();
    void StartConsumeSpecialGold();
	void StartReportTotalScore();
	void ReportTableStartState();

	void CheckAllUserAgreeClearTable();
	void endQuestDisband();
	void DisBandTable(int needShowEndRound);

	void startSwapCard();
	void swapUserCard();
	void startSelDeleterCard();
	void StartSelectPiaoTypeByUser();

    void SendUserStateNotify(int userId, int place, int tuserState, int64_t& bean);
	void SendRoundResult2User();
	void SendEndRound2User(int isForceLeave, int needShowEndRound);
    inline bool CanLeaveWhenGaming(CTableUser* pTUser)
    {
        // 百家乐：没下注可以直接离开
        // 梭哈：下局才进入游戏可以离开
        return (pTUser->ustate < tusNomal);
    }
	inline int getEastPlace()
	{
		return m_eastPlace;
	}
	void UnlockUser(CTableUser* pTUser);
private:
    int m_handle;
    bool m_isActive;
    char m_gameStartMsStamp[100];
    char m_fstStartMsStamp[100];							// 第一局开始的时间
    uint32_t m_endGameTick;
    CCalcTimeTick m_lastRunTick;
    int m_tstate;
    vector<CTableUser*> m_userList;
    map<int, CTableUser*> m_sitUserList;                    // userId和用户的映射，用id查找用户方便，用m_userList的内存
    int m_decTimeCount;                                     // 倒计时
    string m_openSeriesNums;								// 一桌游戏所有牌局的串号信息

	bool m_isQuestDisband;									// 是否在询问散桌中
	int m_questDisbandUserId;
	int m_decTimeQuestDisband;								// 散桌询问倒计时

	//CCalcTimeTick m_lastDisbandTime;						// 上一次散桌的时刻
	uint32_t m_lastDisbandTime;

    int m_curBaseScore;                                     // 桌子底分多少 会变化
    int m_minBean;                                          // 进入条件
    int m_createUserId;                                     // 创建者
    int m_maxRound;                                         // 最多玩多少局
    string m_tableNum;                                      // 桌号
    int m_roundFee;                                         // 本局收费
    int m_curRound;                                         // 当前是第几局 0表示不能再玩了。
    int m_clearRemainSec;                                   // 都离开后，还剩余多少秒才清理桌子。
    int m_minSpecialGold;									// 进入计分局的条件
    int m_vipRoomType;                                      // 当前的游戏是金币局还是记分局（0初始化，为1是金币局，为2是记分局（局费人人平摊），3为记分局（房主承担局费））
    bool m_isConsumeSpecialGold;                            // 金币局是否已经付过局费（true 付过，false 没付过）
    map<int, int64_t> m_totalScore;                         // 总分统计

    TTableRuleInfo m_tableRule;                             // 桌子规则

	CMJActionMgr m_mjActionMgr;								// 麻将动作管理器
	CMJDataMgr m_mjDataMgr;									// 麻将数据管理器
	vector<int> m_diceValue;								// 2副骰子的牌
	int m_eastPlace;										// 东风位置
	int m_bankerPlace;										// 庄家位置 -- 起手摸14张牌的玩家
	int m_startZhuaPlace;									// 起始抓牌的牌墙位置
	int m_startReaminedPaiQiangCnt;							// 		
	int m_swapDirection;									// 换牌方向，0：对家换牌，1：上家拿下家，2：下家拿上家
	bool m_isCreated;										// 是不是已经被创建
	bool m_hasReportScore;									// 是否已经上报过单局成绩（上报过则说明已经进行过游戏并扣过房卡）
	string m_optionStr;										// 房间玩法选项字符串（用于房间多开上报）

	friend class CMJDataMgr;
};

class CGameTableMgr
{
public:
    CGameTableMgr();
    ~CGameTableMgr();

    void RunTime();
    void OnUserOffline(int userId);

    //CGameTable* GetUserCreateTable(int userId);
    CGameTable* GetUserTable(int userId, int& chairIndex);
    CGameTable* GetPUserTable(SUserInfo* pUser, int& chairIndex);
    CGameTable* CreateTable(SUserInfo* pUser, TTableRuleInfo aTableRule, int selScore, int maxRound, int vipRoomType, int& retCode, string& errMsg);
    bool AddSitUser(int userId, int tableHandle, int chairIndex);
    bool RemoveSitUser(int userId);
    //bool RemoveUserCreateTable(int userId);
	void ReportToTableManager(CGameTable* pTable, int flag, int clientFd);

    inline CGameTable* GetTableByHandle(int handle)
    {
        if(handle >= 0 && handle < (int)m_tablelist.size())
            return m_tablelist[handle];
        else
            return NULL;
    }
    inline int GetActiveTableCount() const
    {
        return m_activeTableCount;
    }
	inline int GetSitUserCount() const
	{
		return m_sitAllUserList.size();
	}
private:
    bool FindSitUser(int userId, int& retTableHandle, int&retChairIndex);
private:
    vector<CGameTable*> m_tablelist;
	int m_randomTableHandle[MAX_USE_TABLE_COUNT];
	int m_createIdx;
    int m_activeTableCount;
    map<int, uint32_t> m_sitAllUserList;                // value为桌子和座位的合并值 (chairIndex<<16) | (tablehandle & 0xFFFF), 断线返回也可以从这里查找
    //map<int, int> m_userId2CreateTable;                 // userId和他创建的桌子的对应关系
};


#endif