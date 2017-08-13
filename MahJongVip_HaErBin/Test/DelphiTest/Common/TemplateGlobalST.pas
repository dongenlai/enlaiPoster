{*************************************************************************}
{                                                                         }
{  ��Ԫ˵��: ��Ϸȫ������                                                 }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  ��Ԫ��;:                                                              }
{                                                                         }
{   ����ȫ�ֵĽṹ�塢����                                                }
{                                                                         }
{*************************************************************************}

unit TemplateGlobalST;

interface

uses
  Messages, TemplateCardGlobalST;

const
  WM_MYREFRESH_GAME = WM_USER + 100;                        // post refress game message
  WM_MYSHOW_IS_AGREE = WM_USER + 101;                       // is agree clear table
  CINVALID_TIME_COUNT = -1;                                 // ��Ч��ʱ
  CINVALID_ID = -1;                                         // ��ЧID
  CINVALID_PLACE = -1;                                      // ��Чλ��
  CINVALID_INDEX = -1;                                      // ��Ч�±�
  CTEMPLATE_MIN_USER_COUNT = 4;                             // ��Ϸ�������� 3��
  CTEMPLATE_MAX_USER_COUNT = 4;                             // ��Ϸ������� 3��
  CMIN_BOMB_COUNT = 1;                                      // ����ը������
  CMAX_BOMB_COUNT = 12;                                     // ���ը������
  CMAX_CARD_SCORE = 250;                                    // ���������
  CMAX_DEAL_COUNT = 2000;                                   // ��෢�ƴ���

  CPACKET_ANSWER_DEAL_CARD = $01;                           // ֪ͨ����
  CPACKET_ANSWER_START_DECLARE = $02;                       // ֪ͨ��ʼ�з�
  CPACKET_QUEST_DECLARE = $03;                              // ����з�
  CPACKET_ANSWER_DECLARE = $03;                             // ֪ͨ�з�
  CPACKET_ANSWER_LORD_INFO = $04;                           // ֪ͨ������Ϣ
  CPACKET_ANSWER_START_DISCARD = $05;                       // ֪ͨ��ʼ����
  CPACKET_QUEST_DISCARD = $06;                              // �������
  CPACKET_ANSWER_DISCARD = $06;                             // ֪ͨ����
  CPACKET_ANSWER_SHOW_RESULT = $07;                         // ֪ͨ��ʾ��Ϸ���
  CPACKET_QUEST_TRUST = $08;                                // �����й�
  CPACKET_ANSWER_TRUST = $08;                               // ֪ͨ�й�״̬�ı�

type

  // ��Ϸ״̬�� û������Ϸ�С��ȴ��û�Ready�� ���ơ��з�
  // ���ơ�
  TTemplateGameState = (tgsNotPlaying, tgsWaitUserReady, tgsDealCard, tgsDeclareScore,
    tgsDiscard, tgsCalcResult, tgsShowResult);

  // ��Ϸ��λ
  TTemplatePlace = 0..CTEMPLATE_MAX_USER_COUNT - 1;

  // �û�״̬    û���ˡ� �������ˡ����ߡ�����
  TTemplateUserState = (tusNoPlayer, tusNormal, tusOffline, tusEscape);

  // Boolean��Ϸ��������     �Ƿ�ʤ�߽з�
  TTemplateBoolGameRuleType = (tbgrtIsWinnerFirstDeclare);

  // ������Ϸ���������        ׼��ʱ��                   ����ʱ��
  // �з�ʱ��     ��һ�γ���ʱ�� ����ʱ��   ��ʱ���ƴ���
  // ��ʱ�йܳ���ʱ��   �û��йܳ���ʱ��
  // ��ʾ��Ϸ���ʱ��
  TTemplateIntGameRuleType = (tigrtReadyMaxTimeCount, tigrtDealMaxTimeCount,
    tigrtDeclareMaxTimeCount, tigrtFirDiscardMaxTimeCount, tigrtDiscardMaxTimeCount, tigrtTimeOutMaxCount,
    tigrtTimeOutTrustDiscardTimeCount, tigrtUserTrustDiscardTimeCount,
    tigrtShowResultTimeCount);

  // Int64��Ϸ��������,�����ã�û��ʵ���߼�        ������Ϸ��  �����Ϸ��
  TTemplateInt64GameRuleType = (ti64grtMinBean, ti64grtMaxBean);

  // �з�����  ���У�1��2��3��
  TLordDeclareScore = 0..3;

  // ��������      û��      ����         ����
  TLordSpringType = (lstNone, lstSpring, lstUnSpring);

  // �й�����         û���й� ����ѡ���й�  ��ʱ�й�  �����й�
  TLordTrustedType = (lttNone, lttUserOpt, lttTimeOut, lttEscape);

  // ������Ϣ
  TTemplateUserBaseInfo = record
    Place: Integer;                         // λ��  ��ʼ���󲻿��Ը�д
    UserState: TTemplateUserState;          // �û�״̬
    LoginID: Int64;                         // �û�ID
    IsReady: Boolean;                       // �Ƿ�Ready
    Sex: Byte;                              // �ͻ��˴洢��Sex 0:Ů 1:�� 2:����
    IsRobot: Boolean;                       // �����ר�ã��Ƿ��ǻ����ˣ�����ǣ���������
  end;

  // ��Ϸ��Ϣ
  TTemplateUserGameInfo = record
    ShowHideInfo: Boolean;                  // �Ƿ���ʾ������Ϣ������Ϸ��Ҫ������ʱ��Ҫ��ʾ��
    CardAry: TGameCardAry;                  // ���е��ƣ���Ҫ������Ϣ
    TrustedType: TLordTrustedType;          // �Ƿ��й�״̬
    DeclareScore: Byte;                     // �зֶ��� High(Byte)��ʾû�нй���
    LastDiscard: TGameCardAry;              // �ϴγ�����  ���������������0
    DiscardTimeOutCount: Integer;           // ���Ƴ�ʱ����
    TotalPassCount: Byte;                   // ���ƵĴ���

    TotalDiscardCount: Byte;                // �����ר�� һ�ֵĳ��ƴ���������������������ȷ�������뷴��
    LastTurnCard: TGameCardAry;             // �ͻ���ר�ã�������һ�ֵ���
  end;

  // һ�ֵ÷���Ϣ
  PTemplateScoreReportInfo = ^TTemplateScoreReportInfo;
  TTemplateScoreReportInfo = record
    Place: Integer;                         // ��λ
    LoginID: Int64;                         // �û�ID
    IncScore: Int64;                        // �û��÷֣����������䱶��
  end;
  TTemplateScoreReportInfoAry = array of TTemplateScoreReportInfo;

  // �÷�ͳ����Ϣ
  TTemplateUserScoreStatInfo = record
    LastIncScore: Int64;                    // �Ͼֵ÷֣����������䱶����
    TotalIncScore: Int64;                   // ������Ϸ���ܵ÷֣����������䱶����
    Win: Integer;                           // ������Ϸ����Ӯ����
    Lose: Integer;                          // ������Ϸ���������
    Peace: Integer;                         // ������Ϸ����ƽ����
  end;

  // ��Ϸ�û���Ϣ
  PTemplateUserInfo = ^TTemplateUserInfo;
  TTemplateUserInfo = record
    BaseInfo: TTemplateUserBaseInfo;        // ������Ϣ
    GameInfo: TTemplateUserGameInfo;        // ��Ϸ��Ϣ�������Ƶ�
    ScoreInfo: TTemplateUserScoreStatInfo;  // �÷���Ϣ�����Ͼֵ÷֣��÷�ͳ�Ƶ�
  end;
  TTemplateUserInfoAry = array[TTemplatePlace] of TTemplateUserInfo;

  // Boolean��Ϸ������Ϣ
  TTemplateBoolGameRule = record
    CurValue: Boolean;                                  // ��ǰ������ֵ
    GameRuleName: string;                               // ��������
    DefValue: Boolean;                                  // Ĭ��ֵ
  end;
  TTemplateBoolGameRuleAry = array[TTemplateBoolGameRuleType] of TTemplateBoolGameRule;

  // ������Ϸ������Ϣ
  TTemplateIntGameRule = record
    CurValue: Integer;                                  // ��ǰ������ֵ
    GameRuleName: string;                               // ��������
    MinValue: Integer;                                  // ��Сֵ
    MaxValue: Integer;                                  // ���ֵ
    DefValue: Integer;                                  // Ĭ��ֵ
  end;
  TTemplateIntGameRuleAry = array[TTemplateIntGameRuleType] of TTemplateIntGameRule;

  // Int64 ��Ϸ������Ϣ
  TTemplateInt64GameRule = record
    CurValue: Int64;                                    // ��ǰ������ֵ
    GameRuleName: string;                               // ��������
    MinValue: Int64;                                    // ��Сֵ
    MaxValue: Int64;                                    // ���ֵ
    DefValue: Int64;                                    // Ĭ��ֵ
  end;
  TTemplateInt64GameRuleAry = array[TTemplateInt64GameRuleType] of TTemplateInt64GameRule;


  // ���涨����Ϸ�����ݰ�

  // ֪ͨ����
  TPacketAnswerDealCard = record
    PacketType: Byte;
    CurGameState: TTemplateGameState;
    DecTimeCount: Integer;
    UserCard: array[TTemplatePlace] of TGameCardAry;
  end;

  // ֪ͨ��ʼ�з�
  TPacketAnswerStartDeclare = record
    PacketType: Byte;
    CurGameState: TTemplateGameState;
    DecTimeCount: Integer;
    DeclarePlace: Integer;
    MinScore: Byte;  
  end;

  // ����з�
  TPacketQuestDeclareScore = record
    PacketType: Byte;                             // ��Ϣ����
    Place: Integer;                               // �зַ�λ
    Score: Byte;                                  // �ж��ٷ֣�0��ʾ����
  end;

  // ֪ͨĳ����ҽз�
  TPacketAnswerDeclareScore = record
    PacketType: Byte;                             // ��Ϣ����
    Place: Integer;                               // �зַ�λ
    Score: Byte;                                  // �ж��ٷ֣�0��ʾ����
    CurBaseScore: Byte;                           // ��ǰ�׷��Ƕ���
    CurPlayPlace: Integer;                        // ��ǰ���
  end;

  // ֪ͨ������Ϣ
  TPacketAnswerLordInfo = record
    PacketType: Byte;                             // ��Ϣ����
    LandLordPlace: Integer;                       // ������λ
    BaseScore: Byte;                              // �׷�
    RemainCard: TGameCardAry;                     // ������Ϣ
  end;

  // ֪ͨ��ʼ����
  TPacketAnswerStartDiscard = record
    PacketType: Byte;                             // ��Ϣ����
    CurGameState: TTemplateGameState;             // ��Ϸ״̬
    DecTimeCount: Integer;                        // ����ʱ
    DiscardPlace: Integer;                        // ��ǰ˭����
    LastDiscardPlace: Integer;                    // �ϴγ��Ƶķ�λ ����������
    LastCardType: TLordCardType;                  // �ϴγ������� ����������
  end;

  // �������
  TPacketQuestDiscard = record
    PacketType: Byte;                             // ��Ϣ����
    Place: Integer;                               // ���Ʒ�λ
    CardAry: TGameCardAry;                        // ������
  end;

  // ֪ͨĳ����ҿ�ʼ����
  TPacketAnswerDiscard = record
    PacketType: Byte;                             // ��Ϣ����
    DiscardPlace: Integer;                        // ���Ʒ�λ
    CurPlayPlace: Integer;                        // ��ǰ˭����
    CardType: TLordCardType;                      // ��������
    CardAry: TGameCardAry;                        // ������
    RocketMultiple: Byte;                         // �������
    BombMultiple: Integer;                        // ��ǰ��ը������
  end;

  // ֪ͨ��ʾ��Ϸ���
  TPacketAnswerShowResult = record
    PacketType: Byte;                                           // ������
    CurGameState: TTemplateGameState;                           // ��Ϸ״̬
    WinnerPlace: Integer;                                       // Ӯ�ҷ�λ
    BaseScore: Byte;                                            // �׷�
    RocketMultiple: Byte;                                       // �������
    BombMultiple: Integer;                                      // ը������
    SpringType: TLordSpringType;                                // ��������
  end;

  // �����й�
  TPacketQuestTrust = record
    PacketType: Byte;                             // ��Ϣ����
    Place: Integer;                               // ��λ
    IsQuestTrust: Boolean;                        // �Ƿ��������йܣ����ʾȡ���й�
  end;

  // ֪ͨĳ����ҵ��й�״̬
  TPacketAnswerTrust = record
    PacketType: Byte;                             // ��Ϣ����
    TrustPlace: Integer;                          // ��λ
    CurTrustType: TLordTrustedType;               // ��ǰ�й�״̬��ʲô
  end;

implementation

end.
