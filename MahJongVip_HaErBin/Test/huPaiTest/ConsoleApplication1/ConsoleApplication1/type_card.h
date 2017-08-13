#ifndef __TYPE__CARD__HEAD__
#define __TYPE__CARD__HEAD__

#include "stdafx.h"
#include <vector>
#include <string>

using std::vector;
using std::string;

// 麻将牌的各种动作,因为英文译法晦涩难懂，大量专业词汇用汉语拼音(麻将是国粹，哈哈)
// 注：广义上的明杠包括大明杠(别人出,本人杠)和小明杠(又称加杠)
enum TMJActionName
{
	mjaError,
	mjaPass,
	mjaMo,
	mjaChi,
	mjaPeng,
	mjaDaMingGang,
	mjaChu,
	mjaAnGang,
	mjaJiaGang,
	mjaBuHua,
	mjaTing,
	mjaHu,
	mjaCount
};

// 明牌数据
struct TMJMingPaiItem
{
	TMJMingPaiItem();
	TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, int cardId);
	TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, vector<int>& dataVector);
	TMJMingPaiItem(const TMJMingPaiItem& other);
	~TMJMingPaiItem();

	int rPlace;					 // 谁的数据
	vector<int> rAryData;        // 牌数据
	TMJActionName rMJAction;	 // 何种形式的明牌
	int rLastCardId;			 // 形成牌串的那张牌(吃碰杠进的牌)
	int rLastPlace;				 // 形成牌串的那个人(被吃碰杠的那个人)
};

#endif