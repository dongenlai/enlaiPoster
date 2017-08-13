#ifndef __TYPE__CARD__HEAD__
#define __TYPE__CARD__HEAD__

#include "stdafx.h"
#include <vector>
#include <string>

using std::vector;
using std::string;

// �齫�Ƶĸ��ֶ���,��ΪӢ���뷨��ɬ�Ѷ�������רҵ�ʻ��ú���ƴ��(�齫�ǹ��⣬����)
// ע�������ϵ����ܰ���������(���˳�,���˸�)��С����(�ֳƼӸ�)
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

// ��������
struct TMJMingPaiItem
{
	TMJMingPaiItem();
	TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, int cardId);
	TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, vector<int>& dataVector);
	TMJMingPaiItem(const TMJMingPaiItem& other);
	~TMJMingPaiItem();

	int rPlace;					 // ˭������
	vector<int> rAryData;        // ������
	TMJActionName rMJAction;	 // ������ʽ������
	int rLastCardId;			 // �γ��ƴ���������(�����ܽ�����)
	int rLastPlace;				 // �γ��ƴ����Ǹ���(�������ܵ��Ǹ���)
};

#endif