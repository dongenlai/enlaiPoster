{*************************************************************************}
{                                                                         }
{  ��Ԫ˵��: ͼƬȫ������                                                 }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  ��Ԫ��;:                                                              }
{                                                                         }
{   ����ͼƬȫ�ֵĽṹ�塢����                                            }
{                                                                         }
{*************************************************************************}

unit TemplateImageGlobalST;

interface

uses
  Types, Graphics, PngImage, Jpeg,
  TemplateCardGlobalST, TemplateGlobalST;

const
  CIMAGE_GAME_IMAGE_PACK = 'GameImage.dat';                               // ͼƬ���ļ���
  CIMAGE_MAIN_FRAME = 'MainFrame.png';                                    // ������ļ���
  CIMAGE_USER_INFO_BACK = 'UserInfoBack.png';                             // �û���Ϣ����
  CIMAGE_TABLE_BACK_FORMAT = 'TableBack%.2d.jpg';                         // ���ӱ���ͼƬ��ʽ
  CIMAGE_USERLIST_HEADER_BG = 'UserListHeaderBgPic.png';                  // �û��б����ı���
  CIMAGE_USERLIST_HEADER_SPLITTER = 'UserListHeaderSplitterPic.png';      // �û��б����ķָ���
  CIMAGE_GAME_AD_FILE = 'Ad.png';                                         // ���ͼƬ
  CIMAGE_CHAT_BACK = 'ChatBack.png';                                      // ����򱳾�
  CIMAGE_CHAT_COMBO_BACK = 'ChatComboBoxBack.bmp';                        // ��������Ͽ򱳾�
  CIMAGE_PLUGIN_MENUM_BACK = 'PluginMenuBack.bmp';                        // ��Ϸ�˵�����ͼƬ
  CIMAGE_PLUGIN_DIALOG_BACK = 'PluginDialogBack.png';                     // ��Ϸ�Ի��򱳾�
  CIMAGE_PLUGIN_SETTING_BACK = 'PluginSettingBack.png';                   // ��Ϸ���ñ���
  CIMAGE_PLUGIN_ACTION_BACK = 'PluginActionBack.png';                     // ��Ϸ��������

  CIMAGE_LIST_CHAT_SEND = 'ImageListChatSend.bmp';                        // ������Ͱ�ťͼƬ�б�
  CIMAGE_LIST_CHAT_EMOTION = 'ImageListEmotion.bmp';                      // �������鰴ť
  CIMAGE_LIST_CHAT_SHOUT = 'ImageListShout.bmp';                          // ���������㲥��ť
  CIMAGE_LIST_CHAT_ACTION = 'ImageListAction.bmp';                        // ���������ť
  CIMAGE_LIST_EMOTION_PIC = 'ImageListEmotionPic.bmp';                    // �������
  CIMAGE_LIST_DLG_BUTTON = 'ImageListDialogButton.bmp';                   // �Ի���ťͼƬ�б�
  CIMAGE_LIST_DLG_CLOSE = 'ImageListDialogClose.bmp';                     // �Ի���رհ�ťͼƬ�б�

  CIMAGE_BUTTON_SETTING = 'ButtonSetting.png';                            // ���ð�ť
  CIMAGE_BUTTON_SNAP_SHOT = 'ButtonSnapShot.png';                         // ��ͼ��ť
  CIMAGE_BUTTON_MIN = 'ButtonMin.png';                                    // ��С����ť
  CIMAGE_BUTTON_CLOSE = 'ButtonClose.png';                                // �رհ�ť


  // ��������Ϸ�������Դ

  // ��ť
  CIMAGE_BUTTON_READY = 'ButtonReady';                                    // Ready��ť
  CIMAGE_BUTTON_RAISE_BACK = 'BetRaiseBack.png';                          // ��ע����
  CIMAGE_BUTTON_RAISE_FORMAT = 'BetRaise%s';                              // ��ע��ť��ʽ
  CIMAGE_BUTTON_BET_FORMAT = 'BetBtn%s';                                  // ��ע��ť��ʽ

  // ͼƬ
  CIMAGE_IMAGE_USER_READY = 'ImageUserReady.png';                         // �û��Ѿ�׼����ͼƬ
  CIMAGE_TIMER_NUMBER_BACK = 'TimerNumberBack.png';                       // ����ʱ����
  CIMAGE_TIMER_NUMBER = 'TimerNumber.png';                                // ����ʱ����
  CIMAGE_GAME_USER_INFO_BACK = 'GameUserInfoBack.png';                    // ��Ϸ�����û���Ϣ����
  CIMAGE_PNG_CARD_FORMAT = 'CardImage%s';                                 // ��ͼƬ
  CIMAGE_CARD_DECK = 'CardImageCardDeck.png';                             // ����ʱ��һ����ͼƬ
  CIMAGE_LABEL_ROUND_MAX_BET = 'LabelRoundMaxBet.png';                    // ���ע��
  CIMAGE_LABEL_BASE_BET = 'LabelBaseBet.png';                             // ���ֵ�ע
  CIMAGE_LABEL_NUMBER = 'LabelPicNum.png';                                // ����ͼƬ
  CIMAGE_GAME_SCORE_FORMAT = 'GameScore%s.png';                           // ��Ϸ�÷ֿ�
  CIMAGE_IMAGE_WINNER_FLAG = 'ImageWinnerFlag.png';                       // Ӯ�ұ�־

  // ����
  CIMAGE_ANIMATION_SHUFFLE = 'AnimationShuffle';                          // ϴ�ƶ���
  CIMAGE_ANIMATION_STAR = 'AnimationStar';                                // ��ߵ�����
  CIMAGE_ANIMATION_CHIP_SMALL = 'ChipSmall%d.png';                        // С����ͼƬ
  CIMAGE_ANIMATION_CHIP_BIG = 'ChipBig%d';                                // �����ͼƬ
  CIMAGE_ANIMATION_WAVE_NUMBER = 'AnimationWaveNumber';                   // ��������
  CIMAGE_ANIMATION_WAVE_UNIT = 'AnimationWave%d.png';                     // �������ֵĵ�λ
  CIMAGE_ANIMATION_DEAL_FORMAT = 'CardImageDeal%s';                       // ���ƶ���ͼƬ

  CIMAGE_COFFER_DLG_FORMAT = 'Coffer%s.png';                              // ������

type
  TButtonPicType = (bptComm, bptMove, bptDown, bptGray);        // ��ťͼƬ������
  TCardBackType = (cbtNormal, cbtFarmer, cbtLandLord);          // �Ʊ�������
  TCardMaskType = (cmtSelected, cmtSelecting);                  // �ɰ�����

  // ͼƬ��С
  TSingleImageSize = record
    Width: Integer;                         // ���
    Height: Integer;                        // �߶�
  end;
  
  // ͼƬ��λ��
  TSingleImagePos = record
    Left: Integer;                          // ���
    Top: Integer;                           // �ұ�
  end;

  // ������
  TPointAry = array of TPoint;


  // JpegͼƬ����
  TJPEGImageAry = array of TJPEGImage;

  // Png��ťͼƬ�б�
  TPngButtonPic = record
    PicAry: array[TButtonPicType] of TPNGObject;    // ��ť��ͬ״̬��ͼƬ
  end;

  // BmpͼƬ�б�
  TImageListBmpPic = record
    TransColor: TColor;                           // ͸����ɫ
    PicAry: array of TBitmap;                     // ͼƬ�б�          
  end;

  // png֡
  TSinglePngFrame = record
    Pos: TSingleImagePos;                         // �ڶ����е�λ��
    PlayCount: Integer;                           // ���Ŵ���
    Pic: TPNGObject;                              // PngͼƬ
  end;

  // С����ͼƬ
  TSmallChipPic = record
    BetBean: Int64;                               // ���������Ϸ��
    Pic: TPNGObject;                              // ��ӦͼƬ
  end;
  TSmallChipPicAry = array of TSmallChipPic;

  // Png����ͼƬ�б�
  TPngAnimationPic = record
    Interval: Integer;                            // �������
    PicAry: array of TSinglePngFrame;             // ֡����
  end;
  TPngAnimationPicFixAry = array[TTemplatePlace] of TPngAnimationPic;

  // ��Ϸ���ĵ�λ
  TBeanUnitPic = record
    BetBean: Int64;                               // ���������Ϸ��
    Pic: TPNGObject;                              // ��ӦͼƬ  
  end;
  TBeanUnitPicAry = array of TBeanUnitPic;

  // ��������ͼƬ
  TWaveNumberPic = record
    NumPng: array[0..9] of TPNGObject;            // ����
    UnitAry: TBeanUnitPicAry;                     // ��λͼƬ���Ӵ�С����
  end;

  // �û��б����ͼƬ
  TImageUserListHeader = record
    HeaderBg: TPNGObject;                         // ����
    HeaderSplitter: TPNGObject;                   // �ָ���
  end;

  // ����ʱͼƬ
  TImageTimerNumber = record
    BackPng: TPNGObject;                          // ����
    NumPng: array[0..9] of TPNGObject;            // ����
  end;

  // ͼƬEdit
  TImagePicEdit = record
    TransColor: TColor;                           // ͼƬ��͸����ɫ
    CommPic: TPNGObject;                          // ������ͼƬ
    DisablePic: TPNGObject;                       // �����õ�ͼƬ
  end;

  // ��עͼƬ��Ϣ
  TPngPosAndPic = record
    Pos: TPoint;
    Png: TPNGObject;  
  end;
  TTPngPosAndPicAry = array of TPngPosAndPic;

  // ��ͼƬ��Ϣ
  TPngCardPic = record
    AToKPic: array[sccDiamond..sccSpade] of array[scvA..scvB2] of TPngObject;
    JokerPic: array[scvSJoker..scvBJoker] of TPNGObject;
    BackPic: array[TCardBackType] of TPNGObject;
    MaskPic: array[TCardMaskType] of TPNGObject;
  end;

  // �����ͼƬ
  TShPngCardPic = record
    SelfUser: TPngCardPic;
    OtherUser: TPngCardPic;
    SelfUserBig: TPngCardPic;
    OtherUserBig: TPngCardPic;
    WinnerUser: TPngCardPic;
  end;


  // ͼƬ��ǩ
  TLabelNumberPic = record
    NumLabel: TPNGObject;                                                                
    NumPic: array[0..9] of TPNGObject;
  end;

  // �÷ֿ�ͼƬ
  TImageGameScorePic = record
    Back: TPNGObject;
    WinnerFlag: TPNGObject;  
  end;


implementation

end.
