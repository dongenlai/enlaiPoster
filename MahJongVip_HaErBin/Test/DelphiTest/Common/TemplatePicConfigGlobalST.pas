{*************************************************************************}
{                                                                         }
{  ��Ԫ˵��: ����ȫ������                                                 }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  ��Ԫ��;:                                                              }
{                                                                         }
{   ��������ȫ�ֵĽṹ�塢����                                            }
{                                                                         }
{*************************************************************************}

unit TemplatePicConfigGlobalST;

interface

uses
  Types, Graphics, Classes, TemplateGlobalST;

const
  CCONFIG_INI_FILE_NAME = 'GameImage.ini';                               // �����ļ���
  
  CCONFIG_MAIN_FRAME = 'MainFrame';                                     // �������������
  CCONFIG_PANEL_GAMECLIENT = 'PanelGameClient';                         // ��Ϸ����
  CCONFIG_PANEL_USERINFO = 'PanelUserInfo';                             // �û�����
  CCONFIG_TABLE_BACK = 'TableBack';                                     // ��������
  CCONFIG_USER_LIST = 'UserList';                                       // �û��б�
  CCONFIG_SELECT_USER_INFO = 'SelectUserInfo';                          // ѡ���û�����Ϣ
  CCONFIG_SCROLL_BAR = 'ScrollBar';                                     // ������
  CCONFIG_PANEL_GAME_AD = 'PanelGameAd';                                // ��Ϸ�����
  CCONFIG_PANEL_PROP = 'PanelProp';                                     // ��Ϸ������
  CCONFIG_PLUGIN_CHAT = 'PluginChat';                                   // �����
  CCONFIG_PLUGIN_MENU = 'PluginMenu';                                   // �����˵�����
  CCONFIG_PLUGIN_DIALOG = 'PluginDialog';                               // ȷ�Ͽ�
  CCONFIG_PLUGIN_SETTING = 'PluginSetting';                             // ���ÿ�
  CCONFIG_PLUGIN_ACTION = 'PluginAction';                               // ������

  CCONFIG_SETTING_HAVE_SOUND = 'CheckBoxHaveSound';                     // �Ƿ�����Ч
  CCONFIG_SETTING_HAVE_BACK_MUSIC = 'CheckBoxHaveBackMusic';            // �Ƿ��б�������
  
  CCONFIG_IMAGELIST_CHAT_SEND = 'ImageListChatSend';                    // ������Ͱ�ťͼƬ�б�
  CCONFIG_IMAGELIST_CHAT_EMOTION = 'ImageListChatEmotion';              // �������鰴ťͼƬ�б�
  CCONFIG_IMAGELIST_CHAT_SHOUT = 'ImageListChatShout';                  // ���������㲥��ťͼƬ�б�
  CCONFIG_IMAGELIST_CHAT_ACTION = 'ImageListChatAction';                // ���������ťͼƬ�б�
  CCONFIG_IMAGELIST_EMOTION_PIC = 'ImageListEmotionPic';                // ��������ͼƬ�б�
  CCONFIG_IMAGELIST_DLG_BUTTON = 'ImageListDialogButton';               // �Ի���ť
  CCONFIG_IMAGELIST_DLG_CLOSE = 'ImageListDialogClose';                 // �Ի���رհ�ť

  CCONFIG_BUTTON_LOGO = 'ButtonLogo';                                   // Logo��ť
  CCONFIG_BUTTON_SETTING = 'ButtonSetting';                             // ���ð�ť
  CCONFIG_BUTTON_SNAP_SHOT = 'ButtonSnapShot';                          // ��ͼ��ť
  CCONFIG_BUTTON_MIN = 'ButtonMin';                                     // ��С����ť
  CCONFIG_BUTTON_CLOSE = 'ButtonClose';                                 // �رհ�ť


  // ��������Ϸ���������
  CCONFIG_BUTTON_READY = 'ButtonReady';                                 // Ready��ť
  CCONFIG_BUTTON_BET_RAISE = 'ButtonBetRaise';                          // ��ע��ť����
  CCONFIG_BUTTON_BET_FORMAT = 'ButtonBet%s';                            // ��ע��ť����

  CCONFIG_IMAGE_USER_READY = 'ImageUserReady';                          // �û�ReadyͼƬ������
  CCONFIG_IMAGE_USER_BET_CHIP = 'ImageUserBetChip';                     // �û��Ѿ���עͼƬ������
  CCONFIG_TIMER_NUMBER = 'TimerNumber';                                 // ��ʱ��
  CCONFIG_GAME_USER_INFO = 'GameUserInfo';                              // �û���Ϣ��
  CCONFIG_SH_PNG_CARD_FORMAT = 'PngCard%s';                             // �Ƶ�����
  CCONFIG_SH_PNG_CARD_POS = 'PngCardPos';                               // �Ƶİڷ�λ��
  CCONFIG_LABEL_ROUND_MAX_BET = 'PicLabelRoundMaxBet';                  // ���ע����ⶥ
  CCONFIG_LABEL_BASE_BET = 'PicLabelBaseBet';                           // ��ע��ǩ
  CCONFIG_IMAGE_GAME_SCORE = 'ImageGameScore';                          // �÷���Ϣ
  CCONFIG_IMAGE_WINNER_FLAG = 'ImageWinnerFlag';                        // Ӯ�ұ�־

  CCONFIG_ANIMATION_SHUFFLE = 'AnimationShuffle';                       // ϴ�ƶ�������
  CCONFIG_ANIMATION_STAR = 'AnimationStar';                             // ��������
  CCONFIG_ANIMATION_CHIP_PIC = 'AnimationChipPic';                      // ���붯������
  CCONFIG_WAVE_NUMBER = 'WaveNumber';                                   // ������������
  CCONFIG_ANIMATION_DEAL = 'AnimationDeal';                             // ���ƶ���
  CCONFIG_ANIMATION_DRAW_CHIP = 'AnimationDrawChip';                    // �ճ��붯��

  CCONFIG_COFFER_DLG = 'CofferDlg';                                     // ����������
  CCONFIG_SOUND = 'Sound';                                              // ��������      
type

  // ���������
  TConfigMainFrame = record
    TransColor: TColor;                   // ͸����ɫ
    BorderTop: Integer;                   // �ϱ߱߿�߶�
    BorderBottom: Integer;                // �±߱߿�߶�
    BorderLeft: Integer;                  // ��߱߿���
    BorderRight: Integer;                 // �ұ߱߿���
  end;

  // λ�úʹ�С����
  TConfigPosAndSize = record
    Left: Integer;                        // ���λ��
    Top: Integer;                         // �ϱ�λ��
    Width: Integer;                       // ���
    Height: Integer;                      // �߶�
  end;

  // λ������
  TConfigControlPos = record
    Left: Integer;                        // ���λ��
    Top: Integer;                         // �ϱ�λ��
  end;
  TConfigControlPosFixAry = array[TTemplatePlace] of TConfigControlPos;

  // ��Ⱥ͸߶�
  TConfigWidthHeight = record
    Width: Integer;
    Height: Integer;
  end;

  // ��ߺͿ��
  TConfigLeftWidth = record
    Left: Integer;
    Width: Integer;
  end;

  // ��������
  TConfigFontColorSize = record
    FontColor: TColor;
    FontSize: Integer;
    IsBold: Boolean;
  end;

  // Int��Χ
  TIntegerRange = record
    Min: Integer;
    Max: Integer;
  end;

  // �û��б���ɫ����
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

  // �û��б��п��
  TConfigUserListColumnWidth = record
    ColUserIDWidth: Integer;
    ColNickNameWidth: Integer;
    ColLevelWidth: Integer;
    ColBeanWidth: Integer;
    ColScoreWidth: Integer;
    ColGoldWidth: Integer;
  end;

  // �û��б�����
  TConfigUserList = record
    PosSize: TConfigPosAndSize;
    Color: TConfigUserListColor;
    ColWidth: TConfigUserListColumnWidth;
  end;

  // ѡ���û�����
  TConfigSelectUserInfo = record
    PosSize: TConfigPosAndSize;
    FacePosSize: TConfigPosAndSize;
    FontColor: TColor;
    FontSize: Integer;
    //LabelPosSize: array[TPluginUserColumn] of TConfigPosAndSize;
  end;

  // ���������ͼƬ����
  TConfigStrechPic = record
    CenterX: Integer;
    CenterY: Integer;
    TransparentColor: TColor;
  end;

  // ��ͼ����
  TConfigViewSpace = record
    LeftSpace: Integer;
    TopSpace: Integer;
    RightSpace: Integer;
    BottomSpace: Integer;
  end;

  // ���������
  TConfigInputSpace = record
    LeftSpace: Integer;
    RightSpace: Integer;
    Height: Integer;
    BottomSpace: Integer;
  end;

  // ���찴ť��λ��
  TConfigChatBtnPos = record
    RightSpace: Integer;
    BottomSpace: Integer;
  end;

  // ���������
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

  // ͼƬ�б�����
  TConfigImageList = record
    TransColor: TColor;                       // ͸����ɫ
    SmallWidth: Integer;                      // СͼƬ�Ŀ��
    SmallHeight: Integer;                     // СͼƬ�ĸ߶�
    Interval: Integer;                        // ͼƬ��϶
  end;

  // ����ͼƬ�б�����
  TConfigImageListEmotionPic = record
    ImageList: TConfigImageList;
    HintMsg: TStringList;
  end;

  TConfigPngImageList = record
    SmallWidth: Integer;                      // СͼƬ�Ŀ��
    SmallHeight: Integer;                     // СͼƬ�ĸ߶�
    Interval: Integer;                        // ͼƬ��϶
  end;

  // PngͼƬ��ťͼƬ�б�����
  TConfigPngButton = record
    ImageList: TConfigPngImageList;           // ͼƬ�б�����
    Pos: TConfigControlPos;                   // ��ťλ��
    Hint: string;                             // ��ʾ��Ϣ
  end;

  // Png����֡������
  TConfigPngFrame = record
    FrameInterval: Integer;                   // ÿ֡���ż��
    FrameLeft: string;                        // ֡�����λ�ã���ʽ��֡:Left;֡:Left...
    FrameTop: string;                         // ֡���ϱ�λ�ã���ʽ��֡:Top;֡:Top...
    FramePlayCount: string;                   // ֡�Ĳ��Ŵ�������ʽ��֡:����;֡:����...
  end;

  // �˵�����
  TConfigPluginMenu = record
    Stetch: TConfigStrechPic;
    ViewSpace: TConfigViewSpace;
    CommonTextColor: TColor;
    LineColor: TColor;
    SelectColor: TColor;
    SelectTextColor: TColor;
  end;

  // �Ի�������
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

  // ���ÿ�����
  TConfigPluginSetting = record
    DlgCfg: TConfigPluginDlg;
  end;

  // ���ÿ��е�CheckBox����
  TConfigSettingCheckBox = record
    PosSize: TConfigPosAndSize;
    Caption: string;
    Color: TColor;
  end;

  // ����������
  TConfigPluginAction = record
    DlgCfg: TConfigPluginDlg;
    EditorViewSpace: TConfigViewSpace;
    EditorBackColor: TColor;
    EditorFontColor: TColor;
  end;

  // �û���ʼ��ʾ����
  TConfigImageUserReady = record
    Pos: TConfigControlPosFixAry;
  end;

  // ����Щ�û���Ϣ
  TConfigGameUserInfoType =(cgsitNickName, cgsitID, cgsitBean, cgsitBetBean);
  TConfigUserInfoPosAndSizeAry = array[TConfigGameUserInfoType] of TConfigPosAndSize;

  // ��ʾ����Ϸ�û���Ϣ
  TGameUserInfo = record
    UserInfo: array[TConfigGameUserInfoType] of string;
  end;

  // �û���Ϣ
  TConfigGameUserInfo = record
    HidePos: TConfigControlPosFixAry;                                         // ���ص�λ��
    ShowPos: TConfigControlPosFixAry;                                         // ��ʾ��λ��
    MoveStep: TConfigControlPosFixAry;                                        // ÿ���ƶ��Ĳ���
    MoveInterval: Integer;                                                    // �ƶ�ʱ����
    LabelFont: TConfigFontColorSize;                                          // ��ǩ������
    UserInfoFont: TConfigFontColorSize;                                       // �û���Ϣ������
    UserInfoLabel: array[TConfigGameUserInfoType] of string;                  // ��ǩ��ʲô
    LabelPosSize: TConfigUserInfoPosAndSizeAry;                               // ��ǩ������
    UserInfoPosSize: TConfigUserInfoPosAndSizeAry;                            // �û���Ϣ������
    OfflineNickName: string;                                                  // ����ʱ��ʾ���ǳ�
    EscapeNickName: string;                                                   // ����ʱ��ʾ���ǳ�
  end;

  // �Լ��û���Ϣ������
  TConfigSelfGameUserInfo = record
    PosSize: TConfigPosAndSize;
    LabelFont: TConfigFontColorSize;                                          // ��ǩ������
    UserInfoFont: TConfigFontColorSize;                                       // �û���Ϣ������
    UserInfoLabel: array[TConfigGameUserInfoType] of string;                  // ��ǩ��ʲô
    LabelPosSize: TConfigUserInfoPosAndSizeAry;                               // ��ǩ������
    UserInfoPosSize: TConfigUserInfoPosAndSizeAry;                            // �û���Ϣ������
  end;

  // ����������
  TConfigPngAnimation = record
    ImageList: TConfigPngImageList;
    Frame: TConfigPngFrame;
  end;
  TConfigPngAnimationFixAry = array[TTemplatePlace] of TConfigPngAnimation;

  // ϴ�ƶ�������
  TConfigAnimationShuffle = record
    Pos: TConfigControlPos;
    Animation: TConfigPngAnimation;
  end;

  // ���Ƕ�������
  TConfigAnimationStar = record
    PosSize: TConfigPosAndSize;                                   // λ�úʹ�С
    CenterPos: TConfigControlPos;                                 // ����λ��
    MinInterval: TConfigWidthHeight;                              // ���ټ��
    Animation: TConfigPngAnimation;                               // ������Ƕ�������
  end;

  // �������ʾ��ʽ
  PConfigShowChip = ^TConfigShowChip;
  TConfigShowChip = record
    BetBean: Int64;                                               // �ö��ĳ����ʾ
    Count: Integer;                                               // �ü�����ʾ
    IsSmallChip: Boolean;                                         // ��������ģ��Ƿ���С����
    ChipIndex: Integer;                                           // ��������ģ�������±�
  end;
  TConfigShowChipAry = array of TConfigShowChip;
  
  // С����
  TConfigChipSmallItem = record
    BetBean: Int64;                                               // �ó���������Ϸ��
    ShowChip: TConfigShowChipAry;                                 // �ó�����ô��ʾ
  end;
  TConfigChipSmallItemAry = array of TConfigChipSmallItem;        // �Ӵ�С����

  // �����
  TConfigChipBigItem = record
    BetBean: Int64;                                               // �ó���������Ϸ��
    ShowChip: TConfigShowChipAry;                                 // �ó�����ô��ʾ
    ImageList: TConfigPngImageList;                               // ͼƬ�б�����
  end;
  TConfigChipBigItemAry = array of TConfigChipBigItem;            // �Ӵ�С����

  // �����ƶ�����
  TConfigChipMove = record
    StepRange: TIntegerRange;
    StartShowStepRate: array of Integer;
    StartRandomRect: TConfigPosAndSize;
    EndRandomRect: TConfigPosAndSize;
  end;

  // ���붯���õ�������
  TConfigAnimationChipPic = record
    MaxChipCount: Integer;                                      // һ�ֳ�����������
    SmallChip: TConfigChipSmallItemAry;                         // С���������
    BigChip: TConfigChipBigItemAry;                             // ����������
    FrameInterval: Integer;                                     // ����ʱ����
    SmallChipMove: TConfigChipMove;                             // С������ƶ�����
    BigChipMove: TConfigChipMove;                               // �������ƶ�����
    BeginCenterPos: TConfigControlPosFixAry;                    // ��ͬ��λ��ʼ�ƶ�������λ��
    EndCenterPos: TConfigControlPosFixAry;                      // ��ͬ��λ�����ƶ�������λ��
  end;

  // �������� A*Cos(B*x) + C 
  TConfigWave = record
    WaveInterval: Integer;                                      // ���ı仯ʱ����
    WaveMulti: Double;                                          // ���ı�������ӦA
    WaveRate: Double;                                           // ���ı任�ٶȣ���ӦB
    WaveOffSet: Double;                                         // ����ƫ��������ӦC
    InitOffSet: Integer;                                        // ��ʼ��λ��
    InitAngle: Integer;                                         // ���ĳ�ʼ�Ƕ�
    IncAngle: Integer;                                          // ÿ�β����ĽǶ�
    NumAngle: Integer;                                          // ÿ�����ִ���ĽǶ�
    UnitAngle: Integer;                                         // ÿ����λ����ĽǶ�
    WaveTotalAngle: Integer;                                    // �ܹ����ٽǶ�    
  end;

  // ������������
  TConfigWaveNumber = record
    PosSize: TConfigPosAndSize;                                 // λ�úʹ�С
    ImageList: TConfigPngImageList;                             // ����ͼƬ�б�����
    UnitAry: TInt64DynArray;                                    // ����Щ��λ���Ӵ�С����
    Wave: TConfigWave;                                          // ��������  
  end;

  // �÷ֿ�����
  TConfigImageGameScore = record
    Pos: TConfigControlPos;                                                   // λ��
    LabelFont: TConfigFontColorSize;                                          // ��ǩ������
    UserInfoFont: TConfigFontColorSize;                                       // �û���Ϣ������
    UserInfoLabel: array[TConfigGameUserInfoType] of string;                  // ��ǩ��ʲô
    LabelPosSize: TConfigUserInfoPosAndSizeAry;                               // ��ǩ������
    UserInfoPosSize: TConfigUserInfoPosAndSizeAry;                            // �û���Ϣ������
    CardPos: TConfigControlPos;                                               // �Ƶ�λ��
    WinnerFlagPos: TConfigControlPos;                                         // Ӯ�ұ�־��λ��
    NickNamePos: TConfigLeftWidth;                                            // �ǳ�λ��
    BetBeanPos: TConfigLeftWidth;                                             // ��עλ��
    ScorePos: TConfigLeftWidth;                                               // ����λ��
    BeanPos: TConfigLeftWidth;                                                // ��Ϸ��λ��
    ItemTop: Integer;                                                         // �б���λ��
    ItemInterval: Integer;                                                    // �б�����
    ItemFont: TConfigFontColorSize;                                           // �б�������
    SelfFont: TConfigFontColorSize;                                           // �Լ��÷ֵ�����
  end;

  // ��������
  TConfigPicNumber = record
    Pos: TConfigControlPos;                                       // λ��
    ImageList: TConfigPngImageList;                               // ͼƬ�б�����
    Decimal: Integer;                                             // ������ʾ����λ
    PicInterval: Integer;                                         // ���ֵļ�϶
  end;

  // ����ʱ����
  TConfigTimerNumber = record
    ReadyPos: TConfigControlPos;                                    // Ready����ʱλ��
    BetPosAry: TConfigControlPosFixAry;                             // ��עʱ����ʱλ��
    NumCfg: TConfigPicNumber;                                       // ��������
  end;

  // ͼƬEdit
  TConfigPicEdit = record
    Pos: TConfigControlPos;                                         // λ��
    MaxTextLen: Integer;                                            // �����������ַ�
    TextSpace: TConfigViewSpace;                                    // �ı��ı߾�
    CommFont: TConfigFontColorSize;                                 // ����������
    DisableFontColor: TColor;                                       // ��ҵ�������ɫ
    SelectBgColor: TColor;                                          // ѡ�еı���ɫ
    SelectFontColor: TColor;                                        // ѡ�е�������ɫ
  end;

  // �Ƶ�����
  TCardArrangeType = (catHorizontal, catVertical);                  // ���Ǻ���������
  TConfigPngCard = record
    CardImageList: TConfigPngImageList;                             // �Ƶ�ͼƬ�б�����
    CardInterval: array[TCardArrangeType] of Integer;               // �Ƶļ�� Ҫ��֤������0
    BackInterval: array[TCardArrangeType] of Integer;               // ���Ǳ����ʱ���Ƶļ�� Ҫ��֤������0
    SelectedInterval: Integer;                                      // ��ѡ�е�ʱ��ļ��  Ҫ��֤������0
  end;

  // ����Ƶ�����
  TConfigShPngCard = record
    SelfUser: TConfigPngCard;
    OtherUser: TConfigPngCard;
    SelfUserBig: TConfigPngCard;
    OtherUserBig: TConfigPngCard;
    WinnerUser: TConfigPngCard;
  end;

  // �Ƶ�λ��
  TConfigPngCardPos = record
    SmallPos: TConfigControlPosFixAry;                              // С��
    BigPos: TConfigControlPosFixAry;                                // ����
  end;

  // ���ƶ�������
  TConfigAnimationDeal = record
    DealInterval: Integer;                                          // ���Ƽ�϶
    DeckPos: TConfigControlPos;                                     // �����Ƶ�λ��
    IniPos: TConfigControlPosFixAry;                                // ÿ����ҷ��Ƶĳ�ʼλ�ã�����λ���ǳ�����������
    SelfUserImageList: TConfigPngImageList;                         // ���Լ�λ�õķ���ͼƬ�б�
    OtherUserImageList: TConfigPngImageList;                        // ���������λ�õķ���ͼƬ�б�
  end;

  // ���б�ǩ������
  TConfigPicLabelNumber = record
    PosSize: TConfigPosAndSize;                                     // λ�úʹ�С
    NumCfg: TConfigPicNumber;                                       // ��������
  end;

  // ��ע����
  TConfigBetMulti = record
    Multi: Integer;                                                 // �����Ƕ���
    BtnCfg: TConfigPngButton;                                       // ��ť����
  end;
  TConfigBetMultiAry = array of TConfigBetMulti;                    // ��С�������� 

  // ��ע������
  TConfigBtnBetRaise = record
    BeanNum: TConfigPicLabelNumber;                                 // ��ע������
    MultiAry: TConfigBetMultiAry;                                   // ��ע������ť
    MaxBtn: TConfigPngButton;                                       // ���ť
    OkBtn: TConfigPngButton;                                        // ȷ����ť
    CancelBtn: TConfigPngButton;                                    // ȡ����ť
  end;

  // Ӯ��λ����ʾ����
  TConfigImageWinnerFlag = record
    Pos: TConfigControlPosFixAry;
    ShowSecond: Integer;
  end;

  // ��������
  TConfigAnimationZoom = record
    TotalStep: Integer;                                             // �ܹ����ٲ����
    Interval: Integer;                                              // ÿһ����ʱ���϶
    BeginMulti: Double;                                             // ��ʼ�Ĵ�С����
    EndMulti: Double;                                               // �����Ĵ�С����
  end;

  // �ճ��붯������
  TConfigAnimationDrawChip = record
    ZoomCfg: TConfigAnimationZoom;                                  // ��������
    BeginCenterPos: TConfigControlPosFixAry;                        // ��ʼ�ƶ�������λ��
    EndCenterPos: TConfigControlPosFixAry;                          // �����ƶ�������λ��
  end;

  // ����������
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

  // ������Ϸ�����ٹ���
  TConfigBetApplauseAry = TInt64DynArray;

  // ��������
  TConfigSound = record
    BetApplause: TConfigBetApplauseAry;                   // ��ע�������ã���������
  end;

implementation

end.
