// 游戏进行中的各种麻将牌数据的管理器

#ifndef __MJ_DATA_MGR__HEAD__
#define __MJ_DATA_MGR__HEAD__

#include "type_card.h"
#include "type_area.h"

class CGameTable;
class CTableUser;
class CMJActionMgr;
class CMJDataMgr
{
public:
	CMJDataMgr();
	~CMJDataMgr();
	void init(CGameTable* aParentTable, CMJActionMgr* mjActionMgr);

	bool canMoPai(int place) const;
	bool canChuPai(CTableUser* pTUser, int cardId) const;
	bool canChiPai(CTableUser* pTUser, int cardId, int order) const;
	bool canPengPai(CTableUser* pTUser, int cardId) const;
	bool canDaMingGang(CTableUser* pTUser, int cardId) const;
	bool canJiaGang(CTableUser* pTUser, int cardId) const;
	bool canAnGang(CTableUser* pTUser, int cardId) const;
    bool canTingPai(CTableUser* pTUser, int decCardId, bool needExpandStr, bool isProcTing, string& retStr);

    bool canTingChiPai(CTableUser* pTUser, int cardId, int order, int& cardId00, int& cardId01);
    bool canTingAfterChiPai(CTableUser* pTUser, int cardId, int cardId00, int cardId01, int decCardId, bool needExpandStr, bool isProcTing, string& retStr);
    bool canTingAfterPengPai(CTableUser* pTUser, int cardId, int decCardId, bool needExpandStr, bool isProcTing, string& retStr);

	int canHuPai(CTableUser* pTUser, bool isZiMo) const;

	void procZhuaPai(int eastPlace, int startPlace, int remainderCol);
	bool procMoPai(int place);
	bool procChuPai(int place, int cardId);
	bool procChiPai(int place, int cardId, int order);
	bool procPengPai(int place, int cardId);
	bool procDaMingGang(int place, int cardId);
	bool procJiaGang(int place, int cardId);
	bool procAnGang(int place, int cardId);
	bool procTingPai(int place, int cardId);
    bool procTingChiPai(int place, const string& expandStr);
    bool procTingPengPai(int place, const string& expandStr);
	bool procHuPai(int place, int cardId);

	int getRemaindCount(int place, int cardId);
	void updateAction();
	void beginXingPai();
	void checkUserTing2CalcScore();
	void RoundStopClearData();
private:
	void sendPengGangPacket(int place, int lastChuPaiPlace, int cardId, TMJActionName mjAction);
	void sendErrorActionRespPacket(int place, int errorCode, const string errorStr);
	void calcTingInfo(CTableUser* pTUser);
	bool getSelfCardByChiCard(int cardId, int order, int& card00, int& card01) const;

	void addAHuPaiInfo(int winnerPlace, int paoPlace, bool isZiMo, int cardId, const vector<int>& fanZhongList);
	void calcFanZhongInfo(int place, int paoPlace, bool isZiMo, int huType, int lastCardId,
        const vector<int>& allCardCountAry, const vector<int>& shouCardAry, const vector<vector<int>>& shouPaiCard,
        vector<int>& fanZhongList, const TTableRuleInfo &tableRule);
	void calcLoserFanZhongInfo(int place, vector<int>& fanZhongList);

	void debugActionMsg(int place, TMJActionName mjAction, int cardId);

    int getMJCountZhuoPaiAndMingPai(int cardId);

    void procMoBaoPai();
private:
	CMJDeck* FMJDeck;						                // 一副麻将牌
	CMJPaiQiang* FMJPaiQiang;							    // 牌墙
	CMJZhuoPai* FMJZhuoPai;									// 桌牌
	CMJMingPai* FMJMingPai;									// 明牌
	CMJShouPai* FMJShouPai;								    // 手牌
	vector<int> FMJHasHuPai;								// 已经胡掉的牌

	CGameTable* FParentTable;
	CMJActionMgr* FMJActionMgr;

	int FCurrPlace;											// 当前玩家
	int FLastChuPaiPlace;									// 刚刚出牌的玩家
	int FLastCardID;                                        // 最近的相关牌(出、摸)
	int FHuCountCurrAction;
	int FMaxHuPlace;										// 胡牌的相对最大位置（用于一炮多响后，判断下一个动作的位置）
	int FHuPlace;											// 胡牌的位置（用于一炮多响后，判断下一个动作的位置）

    int FBaoPaiCardID;                                      // 宝牌

	friend class CGameTable;
	friend class CMJActionMgr;
};



#endif