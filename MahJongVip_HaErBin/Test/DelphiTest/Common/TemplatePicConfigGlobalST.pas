{*************************************************************************}
{                                                                         }
{  单元说明: 配置全局类型                                                 }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  单元用途:                                                              }
{                                                                         }
{   声明配置全局的结构体、常量                                            }
{                                                                         }
{*************************************************************************}

unit TemplatePicConfigGlobalST;

interface

uses
  Types, Graphics, Classes, TemplateGlobalST;

const
  CCONFIG_INI_FILE_NAME = 'GameImage.ini';                               // 配置文件名
  
  CCONFIG_MAIN_FRAME = 'MainFrame';                                     // 主框架配置名称
  CCONFIG_PANEL_GAMECLIENT = 'PanelGameClient';                         // 游戏区域
  CCONFIG_PANEL_USERINFO = 'PanelUserInfo';                             // 用户区域
  CCONFIG_TABLE_BACK = 'TableBack';                                     // 桌布配置
  CCONFIG_USER_LIST = 'UserList';                                       // 用户列表
  CCONFIG_SELECT_USER_INFO = 'SelectUserInfo';                          // 选中用户的信息
  CCONFIG_SCROLL_BAR = 'ScrollBar';                                     // 滚动条
  CCONFIG_PANEL_GAME_AD = 'PanelGameAd';                                // 游戏广告栏
  CCONFIG_PANEL_PROP = 'PanelProp';                                     // 游戏道具栏
  CCONFIG_PLUGIN_CHAT = 'PluginChat';                                   // 聊天框
  CCONFIG_PLUGIN_MENU = 'PluginMenu';                                   // 弹出菜单配置
  CCONFIG_PLUGIN_DIALOG = 'PluginDialog';                               // 确认框
  CCONFIG_PLUGIN_SETTING = 'PluginSetting';                             // 设置框
  CCONFIG_PLUGIN_ACTION = 'PluginAction';                               // 动作框

  CCONFIG_SETTING_HAVE_SOUND = 'CheckBoxHaveSound';                     // 是否有音效
  CCONFIG_SETTING_HAVE_BACK_MUSIC = 'CheckBoxHaveBackMusic';            // 是否有背景音乐
  
  CCONFIG_IMAGELIST_CHAT_SEND = 'ImageListChatSend';                    // 聊天框发送按钮图片列表
  CCONFIG_IMAGELIST_CHAT_EMOTION = 'ImageListChatEmotion';              // 聊天框表情按钮图片列表
  CCONFIG_IMAGELIST_CHAT_SHOUT = 'ImageListChatShout';                  // 聊天框大厅广播按钮图片列表
  CCONFIG_IMAGELIST_CHAT_ACTION = 'ImageListChatAction';                // 聊天框动作按钮图片列表
  CCONFIG_IMAGELIST_EMOTION_PIC = 'ImageListEmotionPic';                // 聊天框表情图片列表
  CCONFIG_IMAGELIST_DLG_BUTTON = 'ImageListDialogButton';               // 对话框按钮
  CCONFIG_IMAGELIST_DLG_CLOSE = 'ImageListDialogClose';                 // 对话框关闭按钮

  CCONFIG_BUTTON_LOGO = 'ButtonLogo';                                   // Logo按钮
  CCONFIG_BUTTON_SETTING = 'ButtonSetting';                             // 设置按钮
  CCONFIG_BUTTON_SNAP_SHOT = 'ButtonSnapShot';                          // 截图按钮
  CCONFIG_BUTTON_MIN = 'ButtonMin';                                     // 最小化按钮
  CCONFIG_BUTTON_CLOSE = 'ButtonClose';                                 // 关闭按钮


  // 下面是游戏区域的配置
  CCONFIG_BUTTON_READY = 'ButtonReady';                                 // Ready按钮
  CCONFIG_BUTTON_BET_RAISE = 'ButtonBetRaise';                          // 加注按钮配置
  CCONFIG_BUTTON_BET_FORMAT = 'ButtonBet%s';                            // 下注按钮配置

  CCONFIG_IMAGE_USER_READY = 'ImageUserReady';                          // 用户Ready图片的配置
  CCONFIG_IMAGE_USER_BET_CHIP = 'ImageUserBetChip';                     // 用户已经下注图片的配置
  CCONFIG_TIMER_NUMBER = 'TimerNumber';                                 // 计时器
  CCONFIG_GAME_USER_INFO = 'GameUserInfo';                              // 用户信息框
  CCONFIG_SH_PNG_CARD_FORMAT = 'PngCard%s';                             // 牌的配置
  CCONFIG_SH_PNG_CARD_POS = 'PngCardPos';                               // 牌的摆放位置
  CCONFIG_LABEL_ROUND_MAX_BET = 'PicLabelRoundMaxBet';                  // 最大注额，即封顶
  CCONFIG_LABEL_BASE_BET = 'PicLabelBaseBet';                           // 底注标签
  CCONFIG_IMAGE_GAME_SCORE = 'ImageGameScore';                          // 得分信息
  CCONFIG_IMAGE_WINNER_FLAG = 'ImageWinnerFlag';                        // 赢家标志

  CCONFIG_ANIMATION_SHUFFLE = 'AnimationShuffle';                       // 洗牌动画配置
  CCONFIG_ANIMATION_STAR = 'AnimationStar';                             // 星星配置
  CCONFIG_ANIMATION_CHIP_PIC = 'AnimationChipPic';                      // 筹码动画配置
  CCONFIG_WAVE_NUMBER = 'WaveNumber';                                   // 波形数字配置
  CCONFIG_ANIMATION_DEAL = 'AnimationDeal';                             // 发牌动画
  CCONFIG_ANIMATION_DRAW_CHIP = 'AnimationDrawChip';                    // 收筹码动画

  CCONFIG_COFFER_DLG = 'CofferDlg';                                     // 保险箱配置
  CCONFIG_SOUND = 'Sound';                                              // 声音配置      
type

  // 主框架配置
  TConfigMainFrame = record
    TransColor: TColor;                   // 透明颜色
    BorderTop: Integer;                   // 上边边框高度
    BorderBottom: Integer;                // 下边边框高度
    BorderLeft: Integer;                  // 左边边框宽度
    BorderRight: Integer;                 // 右边边框宽度
  end;

  // 位置和大小配置
  TConfigPosAndSize = record
    Left: Integer;                        // 左边位置
    Top: Integer;                         // 上边位置
    Width: Integer;                       // 宽度
    Height: Integer;                      // 高度
  end;

  // 位置配置
  TConfigControlPos = record
    Left: Integer;                        // 左边位置
    Top: Integer;                         // 上边位置
  end;
  TConfigControlPosFixAry = array[TTemplatePlace] of TConfigControlPos;

  // 宽度和高度
  TConfigWidthHeight = record
    Width: Integer;
    Height: Integer;
  end;

  // 左边和宽度
  TConfigLeftWidth = record
    Left: Integer;
    Width: Integer;
  end;

  // 字体配置
  TConfigFontColorSize = record
    FontColor: TColor;
    FontSize: Integer;
    IsBold: Boolean;
  end;

  // Int范围
  TIntegerRange = record
    Min: Integer;
    Max: Integer;
  end;

  // 用户列表颜色配置
  TConfigUserListColor = record
    HeaderFontColor: TColor;
    UserListColor: TColor;
    ListItemBackColor: TColor;
    ListItemFontColor: TColor;
    SelectBackColor: TColor;
    SelectFontColor: TColor;
    SelfInfoBackColor: TColor;
    SelfInfoFontColor: TColor;
    SelfSelectBackColor: TColor;
    SelfSelectFontColor: TColor;
  end;

  // 用户列表列宽度
  TConfigUserListColumnWidth = record
    ColUserIDWidth: Integer;
    ColNickNameWidth: Integer;
    ColLevelWidth: Integer;
    ColBeanWidth: Integer;
    ColScoreWidth: Integer;
    ColGoldWidth: Integer;
  end;

  // 用户列表配置
  TConfigUserList = record
    PosSize: TConfigPosAndSize;
    Color: TConfigUserListColor;
    ColWidth: TConfigUserListColumnWidth;
  end;

  // 选中用户配置
  TConfigSelectUserInfo = record
    PosSize: TConfigPosAndSize;
    FacePosSize: TConfigPosAndSize;
    FontColor: TColor;
    FontSize: Integer;
    //LabelPosSize: array[TPluginUserColumn] of TConfigPosAndSize;
  end;

  // 可以拉伸的图片配置
  TConfigStrechPic = record
    CenterX: Integer;
    CenterY: Integer;
    TransparentColor: TColor;
  end;

  // 视图配置
  TConfigViewSpace = record
    LeftSpace: Integer;
    TopSpace: Integer;
    RightSpace: Integer;
    BottomSpace: Integer;
  end;

  // 输入框配置
  TConfigInputSpace = record
    LeftSpace: Integer;
    RightSpace: Integer;
    Height: Integer;
    BottomSpace: Integer;
  end;

  // 聊天按钮的位置
  TConfigChatBtnPos = record
    RightSpace: Integer;
    BottomSpace: Integer;
  end;

  // 聊天框配置
  TConfigPluginChat = record
    PosSize: TConfigPosAndSize;
    Stetch: TConfigStrechPic;
    ViewColor: TColor;
    ViewSpace: TConfigViewSpace;
    InputColor: TColor;
    InputSpace: TConfigInputSpace;
    SendPos: TConfigChatBtnPos;
    EmotionPos: TConfigChatBtnPos;
    ShoutPos: TConfigChatBtnPos;
    ActionPos: TConfigChatBtnPos;
    //TextColor: array[0..CChatTextColorCount-1] of TColor;
  end;

  // 图片列表配置
  TConfigImageList = record
    TransColor: TColor;                       // 透明颜色
    SmallWidth: Integer;                      // 小图片的宽度
    SmallHeight: Integer;                     // 小图片的高度
    Interval: Integer;                        // 图片间隙
  end;

  // 表情图片列表配置
  TConfigImageListEmotionPic = record
    ImageList: TConfigImageList;
    HintMsg: TStringList;
  end;

  TConfigPngImageList = record
    SmallWidth: Integer;                      // 小图片的宽度
    SmallHeight: Integer;                     // 小图片的高度
    Interval: Integer;                        // 图片间隙
  end;

  // Png图片按钮图片列表配置
  TConfigPngButton = record
    ImageList: TConfigPngImageList;           // 图片列表配置
    Pos: TConfigControlPos;                   // 按钮位置
    Hint: string;                             // 提示信息
  end;

  // Png动画帧的配置
  TConfigPngFrame = record
    FrameInterval: Integer;                   // 每帧播放间隔
    FrameLeft: string;                        // 帧的左边位置，格式：帧:Left;帧:Left...
    FrameTop: string;                         // 帧的上边位置，格式：帧:Top;帧:Top...
    FramePlayCount: string;                   // 帧的播放次数，格式：帧:次数;帧:次数...
  end;

  // 菜单配置
  TConfigPluginMenu = record
    Stetch: TConfigStrechPic;
    ViewSpace: TConfigViewSpace;
    CommonTextColor: TColor;
    LineColor: TColor;
    SelectColor: TColor;
    SelectTextColor: TColor;
  end;

  // 对话框配置
  TConfigPluginDlg = record
    PosSize: TConfigPosAndSize;
    Stetch: TConfigStrechPic;
    FontColor: TColor;
    FontSize: Integer;
    Caption: string;
    TitleColor: TColor;
    TitleLeft: Integer;
    TitleTop: Integer;
    TitleRight: Integer;
    TitleHeight: Integer;
    TitleShadowColor: TColor;
    ButtonBottomSpace: Integer;
    CloseRight: Integer;
    CloseTop: Integer;
  end;

  // 设置框配置
  TConfigPluginSetting = record
    DlgCfg: TConfigPluginDlg;
  end;

  // 设置框中的CheckBox配置
  TConfigSettingCheckBox = record
    PosSize: TConfigPosAndSize;
    Caption: string;
    Color: TColor;
  end;

  // 动作框配置
  TConfigPluginAction = record
    DlgCfg: TConfigPluginDlg;
    EditorViewSpace: TConfigViewSpace;
    EditorBackColor: TColor;
    EditorFontColor: TColor;
  end;

  // 用户开始显示配置
  TConfigImageUserReady = record
    Pos: TConfigControlPosFixAry;
  end;

  // 有哪些用户信息
  TConfigGameUserInfoType =(cgsitNickName, cgsitID, cgsitBean, cgsitBetBean);
  TConfigUserInfoPosAndSizeAry = array[TConfigGameUserInfoType] of TConfigPosAndSize;

  // 显示的游戏用户信息
  TGameUserInfo = record
    UserInfo: array[TConfigGameUserInfoType] of string;
  end;

  // 用户信息
  TConfigGameUserInfo = record
    HidePos: TConfigControlPosFixAry;                                         // 隐藏的位置
    ShowPos: TConfigControlPosFixAry;                                         // 显示的位置
    MoveStep: TConfigControlPosFixAry;                                        // 每次移动的步长
    MoveInterval: Integer;                                                    // 移动时间间隔
    LabelFont: TConfigFontColorSize;                                          // 标签的字体
    UserInfoFont: TConfigFontColorSize;                                       // 用户信息的字体
    UserInfoLabel: array[TConfigGameUserInfoType] of string;                  // 标签是什么
    LabelPosSize: TConfigUserInfoPosAndSizeAry;                               // 标签的区域
    UserInfoPosSize: TConfigUserInfoPosAndSizeAry;                            // 用户信息的区域
    OfflineNickName: string;                                                  // 掉线时显示的昵称
    EscapeNickName: string;                                                   // 逃跑时显示的昵称
  end;

  // 自己用户信息的配置
  TConfigSelfGameUserInfo = record
    PosSize: TConfigPosAndSize;
    LabelFont: TConfigFontColorSize;                                          // 标签的字体
    UserInfoFont: TConfigFontColorSize;                                       // 用户信息的字体
    UserInfoLabel: array[TConfigGameUserInfoType] of string;                  // 标签是什么
    LabelPosSize: TConfigUserInfoPosAndSizeAry;                               // 标签的区域
    UserInfoPosSize: TConfigUserInfoPosAndSizeAry;                            // 用户信息的区域
  end;

  // 动画的配置
  TConfigPngAnimation = record
    ImageList: TConfigPngImageList;
    Frame: TConfigPngFrame;
  end;
  TConfigPngAnimationFixAry = array[TTemplatePlace] of TConfigPngAnimation;

  // 洗牌动画配置
  TConfigAnimationShuffle = record
    Pos: TConfigControlPos;
    Animation: TConfigPngAnimation;
  end;

  // 星星动画配置
  TConfigAnimationStar = record
    PosSize: TConfigPosAndSize;                                   // 位置和大小
    CenterPos: TConfigControlPos;                                 // 中心位置
    MinInterval: TConfigWidthHeight;                              // 最少间距
    Animation: TConfigPngAnimation;                               // 左边星星动画配置
  end;

  // 筹码的显示方式
  PConfigShowChip = ^TConfigShowChip;
  TConfigShowChip = record
    BetBean: Int64;                                               // 用多大的筹码表示
    Count: Integer;                                               // 用几个表示
    IsSmallChip: Boolean;                                         // 计算出来的：是否是小筹码
    ChipIndex: Integer;                                           // 计算出来的：筹码的下标
  end;
  TConfigShowChipAry = array of TConfigShowChip;
  
  // 小筹码
  TConfigChipSmallItem = record
    BetBean: Int64;                                               // 该筹码代表的游戏豆
    ShowChip: TConfigShowChipAry;                                 // 该筹码怎么表示
  end;
  TConfigChipSmallItemAry = array of TConfigChipSmallItem;        // 从大到小排序

  // 大筹码
  TConfigChipBigItem = record
    BetBean: Int64;                                               // 该筹码代表的游戏豆
    ShowChip: TConfigShowChipAry;                                 // 该筹码怎么表示
    ImageList: TConfigPngImageList;                               // 图片列表配置
  end;
  TConfigChipBigItemAry = array of TConfigChipBigItem;            // 从大到小排序

  // 筹码移动配置
  TConfigChipMove = record
    StepRange: TIntegerRange;
    StartShowStepRate: array of Integer;
    StartRandomRect: TConfigPosAndSize;
    EndRandomRect: TConfigPosAndSize;
  end;

  // 筹码动画用到的配置
  TConfigAnimationChipPic = record
    MaxChipCount: Integer;                                      // 一种筹码的最多数量
    SmallChip: TConfigChipSmallItemAry;                         // 小筹码的配置
    BigChip: TConfigChipBigItemAry;                             // 大筹码的配置
    FrameInterval: Integer;                                     // 动画时间间隔
    SmallChipMove: TConfigChipMove;                             // 小筹码的移动配置
    BigChipMove: TConfigChipMove;                               // 大筹码的移动配置
    BeginCenterPos: TConfigControlPosFixAry;                    // 不同方位开始移动的中心位置
    EndCenterPos: TConfigControlPosFixAry;                      // 不同方位结束移动的中心位置
  end;

  // 波的配置 A*Cos(B*x) + C 
  TConfigWave = record
    WaveInterval: Integer;                                      // 波的变化时间间隔
    WaveMulti: Double;                                          // 波的倍数，对应A
    WaveRate: Double;                                           // 波的变换速度，对应B
    WaveOffSet: Double;                                         // 波的偏移量，对应C
    InitOffSet: Integer;                                        // 初始的位置
    InitAngle: Integer;                                         // 波的初始角度
    IncAngle: Integer;                                          // 每次波动的角度
    NumAngle: Integer;                                          // 每个数字代表的角度
    UnitAngle: Integer;                                         // 每个单位代表的角度
    WaveTotalAngle: Integer;                                    // 总共多少角度    
  end;

  // 波形数字配置
  TConfigWaveNumber = record
    PosSize: TConfigPosAndSize;                                 // 位置和大小
    ImageList: TConfigPngImageList;                             // 数字图片列表配置
    UnitAry: TInt64DynArray;                                    // 有哪些单位，从大到小排序
    Wave: TConfigWave;                                          // 波的配置  
  end;

  // 得分框配置
  TConfigImageGameScore = record
    Pos: TConfigControlPos;                                                   // 位置
    LabelFont: TConfigFontColorSize;                                          // 标签的字体
    UserInfoFont: TConfigFontColorSize;                                       // 用户信息的字体
    UserInfoLabel: array[TConfigGameUserInfoType] of string;                  // 标签是什么
    LabelPosSize: TConfigUserInfoPosAndSizeAry;                               // 标签的区域
    UserInfoPosSize: TConfigUserInfoPosAndSizeAry;                            // 用户信息的区域
    CardPos: TConfigControlPos;                                               // 牌的位置
    WinnerFlagPos: TConfigControlPos;                                         // 赢家标志的位置
    NickNamePos: TConfigLeftWidth;                                            // 昵称位置
    BetBeanPos: TConfigLeftWidth;                                             // 下注位置
    ScorePos: TConfigLeftWidth;                                               // 积分位置
    BeanPos: TConfigLeftWidth;                                                // 游戏豆位置
    ItemTop: Integer;                                                         // 列表项位置
    ItemInterval: Integer;                                                    // 列表项间隔
    ItemFont: TConfigFontColorSize;                                           // 列表项字体
    SelfFont: TConfigFontColorSize;                                           // 自己得分的字体
  end;

  // 数字配置
  TConfigPicNumber = record
    Pos: TConfigControlPos;                                       // 位置
    ImageList: TConfigPngImageList;                               // 图片列表配置
    Decimal: Integer;                                             // 数字显示多少位
    PicInterval: Integer;                                         // 数字的间隙
  end;

  // 倒计时配置
  TConfigTimerNumber = record
    ReadyPos: TConfigControlPos;                                    // Ready倒计时位置
    BetPosAry: TConfigControlPosFixAry;                             // 下注时倒计时位置
    NumCfg: TConfigPicNumber;                                       // 数字配置
  end;

  // 图片Edit
  TConfigPicEdit = record
    Pos: TConfigControlPos;                                         // 位置
    MaxTextLen: Integer;                                            // 最多输入多少字符
    TextSpace: TConfigViewSpace;                                    // 文本的边距
    CommFont: TConfigFontColorSize;                                 // 正常的字体
    DisableFontColor: TColor;                                       // 变灰的字体颜色
    SelectBgColor: TColor;                                          // 选中的背景色
    SelectFontColor: TColor;                                        // 选中的字体颜色
  end;

  // 牌的配置
  TCardArrangeType = (catHorizontal, catVertical);                  // 牌是横向还是纵向
  TConfigPngCard = record
    CardImageList: TConfigPngImageList;                             // 牌的图片列表配置
    CardInterval: array[TCardArrangeType] of Integer;               // 牌的间距 要保证间距大于0
    BackInterval: array[TCardArrangeType] of Integer;               // 都是背面的时候牌的间距 要保证间距大于0
    SelectedInterval: Integer;                                      // 牌选中的时候的间距  要保证间距大于0
  end;

  // 梭哈牌的配置
  TConfigShPngCard = record
    SelfUser: TConfigPngCard;
    OtherUser: TConfigPngCard;
    SelfUserBig: TConfigPngCard;
    OtherUserBig: TConfigPngCard;
    WinnerUser: TConfigPngCard;
  end;

  // 牌的位置
  TConfigPngCardPos = record
    SmallPos: TConfigControlPosFixAry;                              // 小牌
    BigPos: TConfigControlPosFixAry;                                // 大牌
  end;

  // 发牌动画配置
  TConfigAnimationDeal = record
    DealInterval: Integer;                                          // 发牌间隙
    DeckPos: TConfigControlPos;                                     // 整副牌的位置
    IniPos: TConfigControlPosFixAry;                                // 每个玩家发牌的初始位置，结束位置是程序计算出来的
    SelfUserImageList: TConfigPngImageList;                         // 到自己位置的发牌图片列表
    OtherUserImageList: TConfigPngImageList;                        // 到其他玩家位置的发牌图片列表
  end;

  // 带有标签的数字
  TConfigPicLabelNumber = record
    PosSize: TConfigPosAndSize;                                     // 位置和大小
    NumCfg: TConfigPicNumber;                                       // 数字配置
  end;

  // 加注倍数
  TConfigBetMulti = record
    Multi: Integer;                                                 // 倍数是多少
    BtnCfg: TConfigPngButton;                                       // 按钮配置
  end;
  TConfigBetMultiAry = array of TConfigBetMulti;                    // 从小到大排序 

  // 加注框配置
  TConfigBtnBetRaise = record
    BeanNum: TConfigPicLabelNumber;                                 // 加注的数量
    MultiAry: TConfigBetMultiAry;                                   // 加注倍数按钮
    MaxBtn: TConfigPngButton;                                       // 最大按钮
    OkBtn: TConfigPngButton;                                        // 确定按钮
    CancelBtn: TConfigPngButton;                                    // 取消按钮
  end;

  // 赢家位置显示配置
  TConfigImageWinnerFlag = record
    Pos: TConfigControlPosFixAry;
    ShowSecond: Integer;
  end;

  // 缩放配置
  TConfigAnimationZoom = record
    TotalStep: Integer;                                             // 总共多少布完成
    Interval: Integer;                                              // 每一步的时间间隙
    BeginMulti: Double;                                             // 开始的大小倍数
    EndMulti: Double;                                               // 结束的大小倍数
  end;

  // 收筹码动画配置
  TConfigAnimationDrawChip = record
    ZoomCfg: TConfigAnimationZoom;                                  // 缩放配置
    BeginCenterPos: TConfigControlPosFixAry;                        // 开始移动的中心位置
    EndCenterPos: TConfigControlPosFixAry;                          // 结束移动的中心位置
  end;

  // 保险箱配置
  TConfigCofferDlg = record
    Pos: TConfigControlPos;
    TransColor: TColor;
    MsgBoxTitle: string;
    LockPos: TConfigControlPos;
    OpenPos: TConfigControlPos;
    TitleDraw: TConfigPngButton;
    TitleSave: TConfigPngButton;
    BtnDrawCanel: TConfigPngButton;
    BtnDraw: TConfigPngButton;
    BtnSaveCanel: TConfigPngButton;
    BtnSave: TConfigPngButton;
    EditDrawUserBean: TConfigPicEdit;
    EditDrawCofferBean: TConfigPicEdit;
    EditDrawDrawBean: TConfigPicEdit;
    EditSaveUserBean: TConfigPicEdit;
    EditSaveCofferBean: TConfigPicEdit;
    EditSaveSaveBean: TConfigPicEdit;
    EditAnswer: TConfigPicEdit;
    QuestionPosSize: TConfigPosAndSize;
    QuestionFont: TConfigFontColorSize;
  end;

  // 高于游戏豆多少鼓掌
  TConfigBetApplauseAry = TInt64DynArray;

  // 声音配置
  TConfigSound = record
    BetApplause: TConfigBetApplauseAry;                   // 下注掌上配置，降序排列
  end;

implementation

end.
