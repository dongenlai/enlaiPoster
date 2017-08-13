{*************************************************************************}
{                                                                         }
{  单元说明: 图片全局类型                                                 }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  单元用途:                                                              }
{                                                                         }
{   声明图片全局的结构体、常量                                            }
{                                                                         }
{*************************************************************************}

unit TemplateImageGlobalST;

interface

uses
  Types, Graphics, PngImage, Jpeg,
  TemplateCardGlobalST, TemplateGlobalST;

const
  CIMAGE_GAME_IMAGE_PACK = 'GameImage.dat';                               // 图片包文件名
  CIMAGE_MAIN_FRAME = 'MainFrame.png';                                    // 主外框文件名
  CIMAGE_USER_INFO_BACK = 'UserInfoBack.png';                             // 用户信息背景
  CIMAGE_TABLE_BACK_FORMAT = 'TableBack%.2d.jpg';                         // 桌子背景图片格式
  CIMAGE_USERLIST_HEADER_BG = 'UserListHeaderBgPic.png';                  // 用户列表标题的背景
  CIMAGE_USERLIST_HEADER_SPLITTER = 'UserListHeaderSplitterPic.png';      // 用户列表标题的分割线
  CIMAGE_GAME_AD_FILE = 'Ad.png';                                         // 广告图片
  CIMAGE_CHAT_BACK = 'ChatBack.png';                                      // 聊天框背景
  CIMAGE_CHAT_COMBO_BACK = 'ChatComboBoxBack.bmp';                        // 聊天框的组合框背景
  CIMAGE_PLUGIN_MENUM_BACK = 'PluginMenuBack.bmp';                        // 游戏菜单背景图片
  CIMAGE_PLUGIN_DIALOG_BACK = 'PluginDialogBack.png';                     // 游戏对话框背景
  CIMAGE_PLUGIN_SETTING_BACK = 'PluginSettingBack.png';                   // 游戏设置背景
  CIMAGE_PLUGIN_ACTION_BACK = 'PluginActionBack.png';                     // 游戏动作背景

  CIMAGE_LIST_CHAT_SEND = 'ImageListChatSend.bmp';                        // 聊天框发送按钮图片列表
  CIMAGE_LIST_CHAT_EMOTION = 'ImageListEmotion.bmp';                      // 聊天框表情按钮
  CIMAGE_LIST_CHAT_SHOUT = 'ImageListShout.bmp';                          // 聊天框大厅广播按钮
  CIMAGE_LIST_CHAT_ACTION = 'ImageListAction.bmp';                        // 聊天框动作按钮
  CIMAGE_LIST_EMOTION_PIC = 'ImageListEmotionPic.bmp';                    // 聊天表情
  CIMAGE_LIST_DLG_BUTTON = 'ImageListDialogButton.bmp';                   // 对话框按钮图片列表
  CIMAGE_LIST_DLG_CLOSE = 'ImageListDialogClose.bmp';                     // 对话框关闭按钮图片列表

  CIMAGE_BUTTON_SETTING = 'ButtonSetting.png';                            // 设置按钮
  CIMAGE_BUTTON_SNAP_SHOT = 'ButtonSnapShot.png';                         // 截图按钮
  CIMAGE_BUTTON_MIN = 'ButtonMin.png';                                    // 最小化按钮
  CIMAGE_BUTTON_CLOSE = 'ButtonClose.png';                                // 关闭按钮


  // 下面是游戏区域的资源

  // 按钮
  CIMAGE_BUTTON_READY = 'ButtonReady';                                    // Ready按钮
  CIMAGE_BUTTON_RAISE_BACK = 'BetRaiseBack.png';                          // 加注背景
  CIMAGE_BUTTON_RAISE_FORMAT = 'BetRaise%s';                              // 加注按钮格式
  CIMAGE_BUTTON_BET_FORMAT = 'BetBtn%s';                                  // 下注按钮格式

  // 图片
  CIMAGE_IMAGE_USER_READY = 'ImageUserReady.png';                         // 用户已经准备好图片
  CIMAGE_TIMER_NUMBER_BACK = 'TimerNumberBack.png';                       // 倒计时背景
  CIMAGE_TIMER_NUMBER = 'TimerNumber.png';                                // 倒计时数字
  CIMAGE_GAME_USER_INFO_BACK = 'GameUserInfoBack.png';                    // 游戏区域用户信息背景
  CIMAGE_PNG_CARD_FORMAT = 'CardImage%s';                                 // 牌图片
  CIMAGE_CARD_DECK = 'CardImageCardDeck.png';                             // 发牌时的一副牌图片
  CIMAGE_LABEL_ROUND_MAX_BET = 'LabelRoundMaxBet.png';                    // 最大注额
  CIMAGE_LABEL_BASE_BET = 'LabelBaseBet.png';                             // 本局底注
  CIMAGE_LABEL_NUMBER = 'LabelPicNum.png';                                // 数字图片
  CIMAGE_GAME_SCORE_FORMAT = 'GameScore%s.png';                           // 游戏得分框
  CIMAGE_IMAGE_WINNER_FLAG = 'ImageWinnerFlag.png';                       // 赢家标志

  // 动画
  CIMAGE_ANIMATION_SHUFFLE = 'AnimationShuffle';                          // 洗牌动画
  CIMAGE_ANIMATION_STAR = 'AnimationStar';                                // 左边的星星
  CIMAGE_ANIMATION_CHIP_SMALL = 'ChipSmall%d.png';                        // 小筹码图片
  CIMAGE_ANIMATION_CHIP_BIG = 'ChipBig%d';                                // 大筹码图片
  CIMAGE_ANIMATION_WAVE_NUMBER = 'AnimationWaveNumber';                   // 波形数字
  CIMAGE_ANIMATION_WAVE_UNIT = 'AnimationWave%d.png';                     // 波形数字的单位
  CIMAGE_ANIMATION_DEAL_FORMAT = 'CardImageDeal%s';                       // 发牌动画图片

  CIMAGE_COFFER_DLG_FORMAT = 'Coffer%s.png';                              // 保险箱

type
  TButtonPicType = (bptComm, bptMove, bptDown, bptGray);        // 按钮图片的类型
  TCardBackType = (cbtNormal, cbtFarmer, cbtLandLord);          // 牌背面类型
  TCardMaskType = (cmtSelected, cmtSelecting);                  // 蒙板类型

  // 图片大小
  TSingleImageSize = record
    Width: Integer;                         // 宽度
    Height: Integer;                        // 高度
  end;
  
  // 图片的位置
  TSingleImagePos = record
    Left: Integer;                          // 左边
    Top: Integer;                           // 右边
  end;

  // 点数组
  TPointAry = array of TPoint;


  // Jpeg图片数组
  TJPEGImageAry = array of TJPEGImage;

  // Png按钮图片列表
  TPngButtonPic = record
    PicAry: array[TButtonPicType] of TPNGObject;    // 按钮不同状态的图片
  end;

  // Bmp图片列表
  TImageListBmpPic = record
    TransColor: TColor;                           // 透明颜色
    PicAry: array of TBitmap;                     // 图片列表          
  end;

  // png帧
  TSinglePngFrame = record
    Pos: TSingleImagePos;                         // 在动画中的位置
    PlayCount: Integer;                           // 播放次数
    Pic: TPNGObject;                              // Png图片
  end;

  // 小筹码图片
  TSmallChipPic = record
    BetBean: Int64;                               // 代表多少游戏豆
    Pic: TPNGObject;                              // 对应图片
  end;
  TSmallChipPicAry = array of TSmallChipPic;

  // Png动画图片列表
  TPngAnimationPic = record
    Interval: Integer;                            // 动画间隔
    PicAry: array of TSinglePngFrame;             // 帧数组
  end;
  TPngAnimationPicFixAry = array[TTemplatePlace] of TPngAnimationPic;

  // 游戏豆的单位
  TBeanUnitPic = record
    BetBean: Int64;                               // 代表多少游戏豆
    Pic: TPNGObject;                              // 对应图片  
  end;
  TBeanUnitPicAry = array of TBeanUnitPic;

  // 波形数字图片
  TWaveNumberPic = record
    NumPng: array[0..9] of TPNGObject;            // 数字
    UnitAry: TBeanUnitPicAry;                     // 单位图片，从大到小排序
  end;

  // 用户列表标题图片
  TImageUserListHeader = record
    HeaderBg: TPNGObject;                         // 背景
    HeaderSplitter: TPNGObject;                   // 分割线
  end;

  // 倒计时图片
  TImageTimerNumber = record
    BackPng: TPNGObject;                          // 背景
    NumPng: array[0..9] of TPNGObject;            // 数字
  end;

  // 图片Edit
  TImagePicEdit = record
    TransColor: TColor;                           // 图片的透明颜色
    CommPic: TPNGObject;                          // 正常的图片
    DisablePic: TPNGObject;                       // 不可用的图片
  end;

  // 下注图片信息
  TPngPosAndPic = record
    Pos: TPoint;
    Png: TPNGObject;  
  end;
  TTPngPosAndPicAry = array of TPngPosAndPic;

  // 牌图片信息
  TPngCardPic = record
    AToKPic: array[sccDiamond..sccSpade] of array[scvA..scvB2] of TPngObject;
    JokerPic: array[scvSJoker..scvBJoker] of TPNGObject;
    BackPic: array[TCardBackType] of TPNGObject;
    MaskPic: array[TCardMaskType] of TPNGObject;
  end;

  // 梭哈牌图片
  TShPngCardPic = record
    SelfUser: TPngCardPic;
    OtherUser: TPngCardPic;
    SelfUserBig: TPngCardPic;
    OtherUserBig: TPngCardPic;
    WinnerUser: TPngCardPic;
  end;


  // 图片标签
  TLabelNumberPic = record
    NumLabel: TPNGObject;                                                                
    NumPic: array[0..9] of TPNGObject;
  end;

  // 得分框图片
  TImageGameScorePic = record
    Back: TPNGObject;
    WinnerFlag: TPNGObject;  
  end;


implementation

end.
