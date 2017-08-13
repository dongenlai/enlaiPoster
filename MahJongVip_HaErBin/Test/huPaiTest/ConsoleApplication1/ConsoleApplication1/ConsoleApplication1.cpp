// ConsoleApplication1.cpp : 定义控制台应用程序的入口点。
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
	"一万", "二万", "三万", "四万", "五万", "六万", "七万", "八万", "九万", //万子
	//0     1     2     3     4     5     6     7     8
	"一饼", "二饼", "三饼", "四饼", "五饼", "六饼", "七饼", "八饼", "九饼", //饼子
	//9    10    11    12    13    14    15    16    17
	"一条", "二条", "三条", "四条", "五条", "六条", "七条", "八条", "九条" //条子
};

enum TMJCardSuit
{
	mjcsError = 0,
	mjcsCharacter,   // 万子
	mjcsDot,		 // 饼子	
	mjcsBam,		 //	条子bamboo
	mjcsWind,        // 风牌
	mjcsDragon,      // 箭牌
	mjcsFlower       // 花牌
};

vector<TMJFanZhongItem> g_mjFanZhongVector;

int _tmain(int argc, _TCHAR* argv[])
{
	system("mode con:cols=100 lines=1000");

	bool isZiMo = false;
	int x = int(isZiMo);
	cout << isZiMo << "  xxx  " << x << endl;

	g_mjFanZhongVector.push_back(TMJFanZhongItem(0, 6, "清一色"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(1, 3, "碰碰胡"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(2, 1, "平胡"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(3, 1, "自摸门前清"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(4, 1, "明杠"));
	g_mjFanZhongVector.push_back(TMJFanZhongItem(5, 2, "暗杠"));
	
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

		cout << endl << "算番： ";
		int sumScores = 0;
		for (size_t i = 0; i < fanZhongList.size(); i++)
		{
			sumScores += g_mjFanZhongVector[i].point * fanZhongList[i];
			if (fanZhongList[i] > 0)
			{
				cout << g_mjFanZhongVector[i].name << "; ";
			}
		}
		cout << endl << "总番数: " << sumScores << " 番";
	}
	else
	{
		cout << "noHuPai: " << mjLogicMgr.getRunCount();
	}



	getchar();
	return 0;
}

