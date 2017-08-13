// ConsoleApplication1.cpp : �������̨Ӧ�ó������ڵ㡣
//

#include "stdafx.h"
#include <vector>
#include <iostream>
#include "mjLogic.h"
#include "type_card.h"

using std::vector;
using namespace std;
using std::cout;
using std::string;

const std::string CAPTION_MJName[27] = {
	"һ��", "����", "����", "����", "����", "����", "����", "����", "����", //����
	//0     1     2     3     4     5     6     7     8
	"һ��", "����", "����", "�ı�", "���", "����", "�߱�", "�˱�", "�ű�", //����
	//9    10    11    12    13    14    15    16    17
	"һ��", "����", "����", "����", "����", "����", "����", "����", "����" //����
};

enum TMJCardSuit
{
	mjcsError = 0,
	mjcsCharacter,   // ����
	mjcsDot,		 // ����	
	mjcsBam,		 //	����bamboo
	mjcsWind,        // ����
	mjcsDragon,      // ����
	mjcsFlower       // ����
};

vector<TMJFanZhongItem> g_mjFanZhongVector;

int _tmain(int argc, _TCHAR* argv[])
{
	system("mode con:cols=100 lines=1000");

	bool isZiMo = false;
	int x = int(isZiMo);
	cout << isZiMo << "  xxx  " << x << endl;

	g_mjFanZhongVector.push_back(TMJFanZhongItem(0, 6, "��һɫ"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(1, 3, "������"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(2, 1, "ƽ��"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(3, 1, "������ǰ��"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(4, 1, "����"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(5, 2, "����"));
	
	CMJLogicMgr mjLogicMgr;

	int cardAry[13] = { 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 13, 14, 15 };
	int cardCnt[27];
	for (int i = 0; i < 27; i++)
		cardCnt[i] = 0;
	for (int i = 0; i < 13; i++)
	{
		cardCnt[cardAry[i]]++;
	}

	vector<TMJMingPaiItem> mingPaiCard;
	mingPaiCard.push_back(TMJMingPaiItem(0, 0, 1, mjaDaMingGang, 1));

	vector<int> cardCountVec(cardCnt, cardCnt+27);
	vector<vector<int>> zuHeVecVec;

	int calcCount = 0;
	for (int i = 0; i < 27; i++)
	{
		cardCountVec[i]++;

		if (mjLogicMgr.isHuPai(cardCountVec))
		{
			cout << CAPTION_MJName[i] << endl;
		}
		calcCount += mjLogicMgr.getRunCount();
		cout << "i: " << mjLogicMgr.getRunCount() << endl;

		cardCountVec[i]--;
	}

	cout << "end: " << calcCount << endl;


	if (mjLogicMgr.isHuPai(cardCountVec))
	{
		cout << "huPai: " << mjLogicMgr.getRunCount() << endl;
		mjLogicMgr.getZuHeList(zuHeVecVec);

		for (auto it = zuHeVecVec.begin(); it != zuHeVecVec.end(); it++)
		{
			for (auto itt = (*it).begin(); itt != (*it).end(); itt ++)
			{
				cout << CAPTION_MJName[(*itt)].c_str();
			}
			cout << ", ";
		}

		vector<int> fanZhongList(6, 0);
		mjLogicMgr.calcFanZhong(zuHeVecVec, mingPaiCard, true, fanZhongList);

		cout << endl << "�㷬�� ";
		int sumScores = 0;
		for (size_t i = 0; i < fanZhongList.size(); i++)
		{
			sumScores += g_mjFanZhongVector[i].point * fanZhongList[i];
			if (fanZhongList[i] > 0)
			{
				cout << g_mjFanZhongVector[i].name << "; ";
			}
		}
		cout << endl << "�ܷ���: " << sumScores << " ��";
	}
	else
	{
		cout << "noHuPai: " << mjLogicMgr.getRunCount();
	}



	getchar();
	return 0;
}

