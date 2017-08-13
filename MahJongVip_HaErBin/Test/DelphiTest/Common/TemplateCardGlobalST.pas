{*************************************************************************}
{                                                                         }
{  ��Ԫ˵��: ��ȫ������                                                   }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  ��Ԫ��;:                                                              }
{                                                                         }
{   ������ȫ�ֵĽṹ�塢����                                              }
{                                                                         }
{*************************************************************************}

unit TemplateCardGlobalST;

interface

const
  CSUOHA_CARD_COUNT = 5;

type
  // �ƻ�ɫ  û�С����顢÷�������ġ����ҡ������Ʊ�
  TCardColor = (sccNone = 0, sccDiamond = 1, sccClub = 2, sccHeart = 3, sccSpade = 4,
    sccJoker = 5, sccBack = 6);
    
  // �ƴ�С  û�С�A12...KA12С������
  TCardValue = (scvNone = 0, scvA = 1, scv2 = 2, scv3 = 3, scv4 = 4, scv5 = 5,
    scv6 = 6, scv7 = 7, scv8 = 8, scv9 = 9, scv10 = 10, scvJ = 11, scvQ = 12, scvK = 13,
    scvBA = 14, scvB2 = 15, scvSJoker = 16, scvBJoker = 17);
  TLordCardValue = scv3..scvB2;

  // ������������
  TCardTypeAnimation = (ctaNone, ctaRocket, ctaBomb, ctaPlane, cta1Series, cta2Series);

  // �Ƶ���������      ������    ���մ�С     ���ո���
  TLordCardSortType = (lcstNone, lcstByValue, lcstByCount);

  // һ����
  TGameCard = record
    Color: TCardColor;
    Value: TCardValue;
  end;
  TGameCardAry = array of TGameCard;
  TGameCardAryAry = array of TGameCardAry;

  // ��ɨ���б�
  TCardScanItem = record
    Card: TGameCard;                      // �ƴ�С
    Count: Integer;                       // ������
    Index: Integer;                       // Card��ԭ�����е�����
  end;
  TCardScanItemAry = array of TCardScanItem;

  // ���� 0X0M0Y0N��ʽ X����������ΪM�ģ���Y����һ�������ĳ���ΪN���ƣ����嶨�����Ԫ���
  PCardTypeNum = ^TCardTypeNum;
  TCardTypeNum = record
    X: Byte;
    M: Byte;
    Y: Byte;
    N: Byte;
  end;
  
  // ����         
  TLordCardType = record
    TypeNum: TCardTypeNum;                            // ����
    TypeValue: TGameCard;                             // ���ʹ�С �ǻ����ʱ��������ը�����ƴ�С�Ǵ���
  end;

  // ���������͵�˳���ܸı� ��������������Ҫ�Ķ������߼�
  // �������      ���        ը��      3˳        ��˳        ˫˳       3��        ����      ����
  TSplitCardType = (sctRocket, sctBomb, sct3Series, sct1Series, sct2Series, sctThree, sctPair, sctSingle);
  // �����
  TSplitCardItem = record
    CardType: TLordCardType;
    CardAry: TGameCardAry;
    TakesCard: TGameCardAry;
  end;
  TSplitCardAry = array of TSplitCardItem;
  TSplitCardAryAry = array[TSplitCardType] of TSplitCardAry;

const
  CSH_BACK_CARD: TGameCard = (Color: sccBack; Value: scvNone);              // �������
  CSH_NONE_CARD: TGameCard = (Color: sccNone; Value: scvNone);              // ����
  CLD_NONE_TYPE_NUM: TCardTypeNum = (X: 0; M: 0; Y: 0; N: 0);               // �յ�����
  CSPLIT_CARD_TYPE_MSG: array[TSplitCardType] of string = ('���', 'ը��', '3˳', '��˳', '˫˳', '3��', '����', '����');
  CCARD_COLOR_MSG: array[TCardColor] of string = ('û��', '����', '÷��', '����', '����', '', '�Ʊ�');
  CCARD_VALUE_MSG: array[TCardValue] of string = ('', 'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A', '2', 'С��', '����');

implementation


{						���ͼ���ֵ����

0X0M0Y0N��ʽ X����������ΪM�ģ���Y����һ�������ĳ���ΪN��
		        ����(Cards_Type)		  ��ֵ(Cards_Value)           ����:
����:		    01010000					    CCard.Value(��ֵ)              1
һ��:		    01020000							CCard.Value(��ֵ)			         2
���:		    01020000							CCard.Value(��ֵ)			         2
����:		    01030000							CCard.Value(��ֵ)			         3

����һ:	   01030101						 ���ŵ�Card.Value(��ֵ)		       4
����:		    01040000							CCard.Value(��ֵ)			         4

��˳:		    05010000							��С�Ƶ�Card.Value(��ֵ)       5
����һ��:   01030102							���ŵ�Card.Value(��ֵ)		      5

��˳:		    06010000							��С�Ƶ�Card.Value(��ֵ)       6
˫˳:		    03020000						  ��С�Ƶ�Card.Value(��ֵ)       6
��˳:	      02030000							��С�Ƶ�Card.Value(��ֵ)       6
�Ĵ�����:   01040201						  ���ŵ�Card.Value(��ֵ)		      6

��˳:		    07010000							��С�Ƶ�Card.Value(��ֵ)       7

��˳:		    08010000							��С�Ƶ�Card.Value(��ֵ)       8
˫˳		    04020000						  ��С�Ƶ�Card.Value(��ֵ)       8
��˳������: 02030202						   ��С���ŵ�Card.Value(��ֵ)     8
�Ĵ�����:	  01040202						  ���ŵ�Card.Value(��ֵ)		      8

��˳:		    09010000							��С�Ƶ�Card.Value(��ֵ)       9
��˳:		    03030000						  ��С���ŵ�Card.Value(��ֵ)     9

��˳:		    10010000							��С�Ƶ�Card.Value(��ֵ)      10
˫˳:		    05020000						  ��С�Ƶ�Card.Value(��ֵ)      10
��˳������: 02030202						   ��С���ŵ�Card.Value(��ֵ)    10

��˳:		    11010000							��С�Ƶ�Card.Value(��ֵ)      11

��˳:		    12010000							��С�Ƶ�Card.Value(��ֵ)      12
˫˳:		    06020000						  ��С���Ƶ�Card.Value(��ֵ)    12
��˳:		    04030000						  ��С���ŵ�Card.Value(��ֵ)    12
��˳����:	  03030301						  ��С���ŵ�Card.Value(��ֵ)    12

˫˳		    07020000					    ��С���Ƶ�Card.Value(��ֵ)    14

��˳������: 03030302						   ��С���ŵ�Card.Value(��ֵ)    15
��˳:		    05030000						  ��С���ŵ�Card.Value(��ֵ)    15

˫˳		    08020000					    ��С���Ƶ�Card.Value(��ֵ)    16
��˳���ĵ�: 04030401					     ��С���ŵ�Card.Value(��ֵ)    16

˫˳		    09020000					    ��С���Ƶ�Card.Value(��ֵ)    18
��˳		    06030000						  ��С���ŵ�Card.Value(��ֵ)    18

˫˳		    10020000					    ��С���Ƶ�Card.Value(��ֵ)    20
��˳���嵥: 05030501					     ��С���ŵ�Card.Value(��ֵ)    20
��˳���Ķ�: 04030402					     ��С���ŵ�Card.Value(��ֵ)    20

ע�⣺��������ţ�������ը������ 01040000

}

end.
