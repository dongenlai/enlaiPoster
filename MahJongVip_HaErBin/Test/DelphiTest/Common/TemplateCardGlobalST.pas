{*************************************************************************}
{                                                                         }
{  单元说明: 牌全局类型                                                   }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  单元用途:                                                              }
{                                                                         }
{   声明牌全局的结构体、常量                                              }
{                                                                         }
{*************************************************************************}

unit TemplateCardGlobalST;

interface

const
  CSUOHA_CARD_COUNT = 5;

type
  // 牌花色  没有、方块、梅花、红心、黑桃、王、牌背
  TCardColor = (sccNone = 0, sccDiamond = 1, sccClub = 2, sccHeart = 3, sccSpade = 4,
    sccJoker = 5, sccBack = 6);
    
  // 牌大小  没有、A12...KA12小王大王
  TCardValue = (scvNone = 0, scvA = 1, scv2 = 2, scv3 = 3, scv4 = 4, scv5 = 5,
    scv6 = 6, scv7 = 7, scv8 = 8, scv9 = 9, scv10 = 10, scvJ = 11, scvQ = 12, scvK = 13,
    scvBA = 14, scvB2 = 15, scvSJoker = 16, scvBJoker = 17);
  TLordCardValue = scv3..scvB2;

  // 牌型声音类型
  TCardTypeAnimation = (ctaNone, ctaRocket, ctaBomb, ctaPlane, cta1Series, cta2Series);

  // 牌的排序类型      不排序    按照大小     按照个数
  TLordCardSortType = (lcstNone, lcstByValue, lcstByCount);

  // 一张牌
  TGameCard = record
    Color: TCardColor;
    Value: TCardValue;
  end;
  TGameCardAry = array of TGameCard;
  TGameCardAryAry = array of TGameCardAry;

  // 牌扫描列表
  TCardScanItem = record
    Card: TGameCard;                      // 牌大小
    Count: Integer;                       // 牌数量
    Index: Integer;                       // Card在原来牌中的索引
  end;
  TCardScanItemAry = array of TCardScanItem;

  // 牌型 0X0M0Y0N格式 X个连续长度为M的，和Y个不一定连续的长度为N的牌，具体定义见单元最后
  PCardTypeNum = ^TCardTypeNum;
  TCardTypeNum = record
    X: Byte;
    M: Byte;
    Y: Byte;
    N: Byte;
  end;
  
  // 牌型         
  TLordCardType = record
    TypeNum: TCardTypeNum;                            // 牌型
    TypeValue: TGameCard;                             // 牌型大小 是火箭的时候，牌型是炸弹，牌大小是大王
  end;

  // 下面拆分类型的顺序不能改变 ！！！，否则需要改动出牌逻辑
  // 拆分类型      火箭        炸弹      3顺        单顺        双顺       3条        对子      单牌
  TSplitCardType = (sctRocket, sctBomb, sct3Series, sct1Series, sct2Series, sctThree, sctPair, sctSingle);
  // 拆分牌
  TSplitCardItem = record
    CardType: TLordCardType;
    CardAry: TGameCardAry;
    TakesCard: TGameCardAry;
  end;
  TSplitCardAry = array of TSplitCardItem;
  TSplitCardAryAry = array[TSplitCardType] of TSplitCardAry;

const
  CSH_BACK_CARD: TGameCard = (Color: sccBack; Value: scvNone);              // 背面的牌
  CSH_NONE_CARD: TGameCard = (Color: sccNone; Value: scvNone);              // 空牌
  CLD_NONE_TYPE_NUM: TCardTypeNum = (X: 0; M: 0; Y: 0; N: 0);               // 空的牌型
  CSPLIT_CARD_TYPE_MSG: array[TSplitCardType] of string = ('火箭', '炸弹', '3顺', '单顺', '双顺', '3条', '对子', '单牌');
  CCARD_COLOR_MSG: array[TCardColor] of string = ('没有', '方块', '梅花', '红心', '黑桃', '', '牌背');
  CCARD_VALUE_MSG: array[TCardValue] of string = ('', 'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A', '2', '小王', '大王');

implementation


{						牌型及牌值定义

0X0M0Y0N格式 X个连续长度为M的，和Y个不一定连续的长度为N的
		        牌型(Cards_Type)		  牌值(Cards_Value)           牌数:
单牌:		    01010000					    CCard.Value(面值)              1
一对:		    01020000							CCard.Value(面值)			         2
火箭:		    01020000							CCard.Value(面值)			         2
三张:		    01030000							CCard.Value(面值)			         3

三带一:	   01030101						 三张的Card.Value(面值)		       4
四张:		    01040000							CCard.Value(面值)			         4

单顺:		    05010000							最小牌的Card.Value(面值)       5
三带一对:   01030102							三张的Card.Value(面值)		      5

单顺:		    06010000							最小牌的Card.Value(面值)       6
双顺:		    03020000						  最小牌的Card.Value(面值)       6
三顺:	      02030000							最小牌的Card.Value(面值)       6
四带二单:   01040201						  四张的Card.Value(面值)		      6

单顺:		    07010000							最小牌的Card.Value(面值)       7

单顺:		    08010000							最小牌的Card.Value(面值)       8
双顺		    04020000						  最小牌的Card.Value(面值)       8
三顺带二单: 02030202						   最小三张的Card.Value(面值)     8
四带二对:	  01040202						  四张的Card.Value(面值)		      8

单顺:		    09010000							最小牌的Card.Value(面值)       9
三顺:		    03030000						  最小三张的Card.Value(面值)     9

单顺:		    10010000							最小牌的Card.Value(面值)      10
双顺:		    05020000						  最小牌的Card.Value(面值)      10
三顺带二对: 02030202						   最小三张的Card.Value(面值)    10

单顺:		    11010000							最小牌的Card.Value(面值)      11

单顺:		    12010000							最小牌的Card.Value(面值)      12
双顺:		    06020000						  最小对牌的Card.Value(面值)    12
三顺:		    04030000						  最小三张的Card.Value(面值)    12
三顺带三:	  03030301						  最小三张的Card.Value(面值)    12

双顺		    07020000					    最小对牌的Card.Value(面值)    14

三顺带三对: 03030302						   最小三张的Card.Value(面值)    15
三顺:		    05030000						  最小三张的Card.Value(面值)    15

双顺		    08020000					    最小对牌的Card.Value(面值)    16
三顺带四单: 04030401					     最小三张的Card.Value(面值)    16

双顺		    09020000					    最小对牌的Card.Value(面值)    18
三顺		    06030000						  最小三张的Card.Value(面值)    18

双顺		    10020000					    最小对牌的Card.Value(面值)    20
三顺带五单: 05030501					     最小三张的Card.Value(面值)    20
三顺带四对: 04030402					     最小三张的Card.Value(面值)    20

注意：火箭是两张，但是是炸弹，是 01040000

}

end.
