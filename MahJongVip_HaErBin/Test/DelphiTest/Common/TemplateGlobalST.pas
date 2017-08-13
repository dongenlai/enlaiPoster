{*************************************************************************}
{                                                                         }
{  单元说明: 游戏全局类型                                                 }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  单元用途:                                                              }
{                                                                         }
{   声明全局的结构体、常量                                                }
{                                                                         }
{*************************************************************************}

unit TemplateGlobalST;

interface

uses
  Messages, TemplateCardGlobalST;

const
  WM_MYREFRESH_GAME = WM_USER + 100;                        // post refress game message
  WM_MYSHOW_IS_AGREE = WM_USER + 101;                       // is agree clear table
  CINVALID_TIME_COUNT = -1;                                 // 无效计时
  CINVALID_ID = -1;                                         // 无效ID
  CINVALID_PLACE = -1;                                      // 无效位置
  CINVALID_INDEX = -1;                                      // 无效下标
  CTEMPLATE_MIN_USER_COUNT = 4;                             // 游戏最少人数 3人
  CTEMPLATE_MAX_USER_COUNT = 4;                             // 游戏最大人数 3人
  CMIN_BOMB_COUNT = 1;                                      // 最少炸弹个数
  CMAX_BOMB_COUNT = 12;                                     // 最多炸弹个数
  CMAX_CARD_SCORE = 250;                                    // 牌最高评分
  CMAX_DEAL_COUNT = 2000;                                   // 最多发牌次数

  CPACKET_ANSWER_DEAL_CARD = $01;                           // 通知发牌
  CPACKET_ANSWER_START_DECLARE = $02;                       // 通知开始叫分
  CPACKET_QUEST_DECLARE = $03;                              // 请求叫分
  CPACKET_ANSWER_DECLARE = $03;                             // 通知叫分
  CPACKET_ANSWER_LORD_INFO = $04;                           // 通知地主信息
  CPACKET_ANSWER_START_DISCARD = $05;                       // 通知开始出牌
  CPACKET_QUEST_DISCARD = $06;                              // 请求出牌
  CPACKET_ANSWER_DISCARD = $06;                             // 通知出牌
  CPACKET_ANSWER_SHOW_RESULT = $07;                         // 通知显示游戏结果
  CPACKET_QUEST_TRUST = $08;                                // 请求托管
  CPACKET_ANSWER_TRUST = $08;                               // 通知托管状态改变

type

  // 游戏状态： 没有在游戏中、等待用户Ready、 发牌、叫分
  // 出牌、
  TTemplateGameState = (tgsNotPlaying, tgsWaitUserReady, tgsDealCard, tgsDeclareScore,
    tgsDiscard, tgsCalcResult, tgsShowResult);

  // 游戏方位
  TTemplatePlace = 0..CTEMPLATE_MAX_USER_COUNT - 1;

  // 用户状态    没有人、 正常有人、掉线、逃跑
  TTemplateUserState = (tusNoPlayer, tusNormal, tusOffline, tusEscape);

  // Boolean游戏规则类型     是否胜者叫分
  TTemplateBoolGameRuleType = (tbgrtIsWinnerFirstDeclare);

  // 整数游戏规则的类型        准备时间                   发牌时间
  // 叫分时间     第一次出牌时间 出牌时间   超时出牌次数
  // 超时托管出牌时间   用户托管出牌时间
  // 显示游戏结果时间
  TTemplateIntGameRuleType = (tigrtReadyMaxTimeCount, tigrtDealMaxTimeCount,
    tigrtDeclareMaxTimeCount, tigrtFirDiscardMaxTimeCount, tigrtDiscardMaxTimeCount, tigrtTimeOutMaxCount,
    tigrtTimeOutTrustDiscardTimeCount, tigrtUserTrustDiscardTimeCount,
    tigrtShowResultTimeCount);

  // Int64游戏规则类型,测试用，没有实现逻辑        最少游戏豆  最多游戏豆
  TTemplateInt64GameRuleType = (ti64grtMinBean, ti64grtMaxBean);

  // 叫分类型  不叫，1，2，3分
  TLordDeclareScore = 0..3;

  // 春天类型      没有      春天         反春
  TLordSpringType = (lstNone, lstSpring, lstUnSpring);

  // 托管类型         没有托管 用用选择托管  超时托管  逃跑托管
  TLordTrustedType = (lttNone, lttUserOpt, lttTimeOut, lttEscape);

  // 基本信息
  TTemplateUserBaseInfo = record
    Place: Integer;                         // 位置  初始化后不可以改写
    UserState: TTemplateUserState;          // 用户状态
    LoginID: Int64;                         // 用户ID
    IsReady: Boolean;                       // 是否Ready
    Sex: Byte;                              // 客户端存储的Sex 0:女 1:男 2:保密
    IsRobot: Boolean;                       // 服务端专用，是否是机器人，如果是，则发送明牌
  end;

  // 游戏信息
  TTemplateUserGameInfo = record
    ShowHideInfo: Boolean;                  // 是否显示隐藏信息，当游戏快要结束的时候要显示的
    CardAry: TGameCardAry;                  // 手中的牌，需要隐藏信息
    TrustedType: TLordTrustedType;          // 是否托管状态
    DeclareScore: Byte;                     // 叫分多少 High(Byte)表示没有叫过分
    LastDiscard: TGameCardAry;              // 上次出的牌  如果不出，长度是0
    DiscardTimeOutCount: Integer;           // 出牌超时次数
    TotalPassCount: Byte;                   // 过牌的次数

    TotalDiscardCount: Byte;                // 服务端专用 一局的出牌次数，不包括不出。用于确定春天与反春
    LastTurnCard: TGameCardAry;             // 客户端专用，保存上一轮的牌
  end;

  // 一局得分信息
  PTemplateScoreReportInfo = ^TTemplateScoreReportInfo;
  TTemplateScoreReportInfo = record
    Place: Integer;                         // 方位
    LoginID: Int64;                         // 用户ID
    IncScore: Int64;                        // 用户得分，不包括房间倍数
  end;
  TTemplateScoreReportInfoAry = array of TTemplateScoreReportInfo;

  // 得分统计信息
  TTemplateUserScoreStatInfo = record
    LastIncScore: Int64;                    // 上局得分（不包括房间倍数）
    TotalIncScore: Int64;                   // 进入游戏后总得分（不包括房间倍数）
    Win: Integer;                           // 进入游戏后总赢局数
    Lose: Integer;                          // 进入游戏后总输局数
    Peace: Integer;                         // 进入游戏后总平局数
  end;

  // 游戏用户信息
  PTemplateUserInfo = ^TTemplateUserInfo;
  TTemplateUserInfo = record
    BaseInfo: TTemplateUserBaseInfo;        // 基本信息
    GameInfo: TTemplateUserGameInfo;        // 游戏信息，比如牌等
    ScoreInfo: TTemplateUserScoreStatInfo;  // 得分信息，如上局得分，得分统计等
  end;
  TTemplateUserInfoAry = array[TTemplatePlace] of TTemplateUserInfo;

  // Boolean游戏规则信息
  TTemplateBoolGameRule = record
    CurValue: Boolean;                                  // 当前规则数值
    GameRuleName: string;                               // 规则名称
    DefValue: Boolean;                                  // 默认值
  end;
  TTemplateBoolGameRuleAry = array[TTemplateBoolGameRuleType] of TTemplateBoolGameRule;

  // 整数游戏规则信息
  TTemplateIntGameRule = record
    CurValue: Integer;                                  // 当前规则数值
    GameRuleName: string;                               // 规则名称
    MinValue: Integer;                                  // 最小值
    MaxValue: Integer;                                  // 最大值
    DefValue: Integer;                                  // 默认值
  end;
  TTemplateIntGameRuleAry = array[TTemplateIntGameRuleType] of TTemplateIntGameRule;

  // Int64 游戏规则信息
  TTemplateInt64GameRule = record
    CurValue: Int64;                                    // 当前规则数值
    GameRuleName: string;                               // 规则名称
    MinValue: Int64;                                    // 最小值
    MaxValue: Int64;                                    // 最大值
    DefValue: Int64;                                    // 默认值
  end;
  TTemplateInt64GameRuleAry = array[TTemplateInt64GameRuleType] of TTemplateInt64GameRule;


  // 下面定义游戏的数据包

  // 通知发牌
  TPacketAnswerDealCard = record
    PacketType: Byte;
    CurGameState: TTemplateGameState;
    DecTimeCount: Integer;
    UserCard: array[TTemplatePlace] of TGameCardAry;
  end;

  // 通知开始叫分
  TPacketAnswerStartDeclare = record
    PacketType: Byte;
    CurGameState: TTemplateGameState;
    DecTimeCount: Integer;
    DeclarePlace: Integer;
    MinScore: Byte;  
  end;

  // 请求叫分
  TPacketQuestDeclareScore = record
    PacketType: Byte;                             // 消息类型
    Place: Integer;                               // 叫分方位
    Score: Byte;                                  // 叫多少分，0表示不叫
  end;

  // 通知某个玩家叫分
  TPacketAnswerDeclareScore = record
    PacketType: Byte;                             // 消息类型
    Place: Integer;                               // 叫分方位
    Score: Byte;                                  // 叫多少分，0表示不叫
    CurBaseScore: Byte;                           // 当前底分是多少
    CurPlayPlace: Integer;                        // 当前玩家
  end;

  // 通知地主信息
  TPacketAnswerLordInfo = record
    PacketType: Byte;                             // 消息类型
    LandLordPlace: Integer;                       // 地主方位
    BaseScore: Byte;                              // 底分
    RemainCard: TGameCardAry;                     // 底牌信息
  end;

  // 通知开始出牌
  TPacketAnswerStartDiscard = record
    PacketType: Byte;                             // 消息类型
    CurGameState: TTemplateGameState;             // 游戏状态
    DecTimeCount: Integer;                        // 倒计时
    DiscardPlace: Integer;                        // 当前谁出牌
    LastDiscardPlace: Integer;                    // 上次出牌的方位 不包括不出
    LastCardType: TLordCardType;                  // 上次出牌牌型 不包括不出
  end;

  // 请求出牌
  TPacketQuestDiscard = record
    PacketType: Byte;                             // 消息类型
    Place: Integer;                               // 出牌方位
    CardAry: TGameCardAry;                        // 出的牌
  end;

  // 通知某个玩家开始出牌
  TPacketAnswerDiscard = record
    PacketType: Byte;                             // 消息类型
    DiscardPlace: Integer;                        // 出牌方位
    CurPlayPlace: Integer;                        // 当前谁出牌
    CardType: TLordCardType;                      // 出牌牌型
    CardAry: TGameCardAry;                        // 出的牌
    RocketMultiple: Byte;                         // 火箭倍数
    BombMultiple: Integer;                        // 当前的炸弹倍数
  end;

  // 通知显示游戏结果
  TPacketAnswerShowResult = record
    PacketType: Byte;                                           // 包类型
    CurGameState: TTemplateGameState;                           // 游戏状态
    WinnerPlace: Integer;                                       // 赢家方位
    BaseScore: Byte;                                            // 底分
    RocketMultiple: Byte;                                       // 火箭倍数
    BombMultiple: Integer;                                      // 炸弹倍数
    SpringType: TLordSpringType;                                // 春天类型
  end;

  // 请求托管
  TPacketQuestTrust = record
    PacketType: Byte;                             // 消息类型
    Place: Integer;                               // 方位
    IsQuestTrust: Boolean;                        // 是否是请求托管，否表示取消托管
  end;

  // 通知某个玩家的托管状态
  TPacketAnswerTrust = record
    PacketType: Byte;                             // 消息类型
    TrustPlace: Integer;                          // 方位
    CurTrustType: TLordTrustedType;               // 当前托管状态是什么
  end;

implementation

end.
