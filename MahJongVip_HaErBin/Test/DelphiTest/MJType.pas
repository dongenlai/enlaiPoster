unit MJType;

interface

uses

  pngimage, TemplateGlobalST;



type

// 麻将牌索引 1..9万、1..9筒、1..9条、东南西北中发白、春夏秋冬梅兰竹菊
  TMJCardIndex = 0..42 - 1;

  TMJShouPaiItem = record
    rStrData: array of Integer;                           // 数据数组
    rLastCardID: Byte;                          // 最后一张摸到或出的牌
    rBMoPai: Boolean;                           // 是否刚摸到牌
    rBJinZhang: Boolean;                        // 是否已经进张
  end;

  // 偏移量
  TDrawMJPaiOffset = record
    OffsetX: Integer;                                           // 水平方向的偏移量
    OffsetY: Integer;                                           // 垂直方向上偏移量
  end;

  // 大小配置
  TConfigSize = record
    Width: Integer;                       // 宽度
    Height: Integer;                      // 高度
  end;

  // 手牌的配置。手牌的位置信息要根据明牌的定点算出
  TConfigMJGrapShouPai = record
    AryErectSingleSize: array[TTemplatePlace] of TConfigSize;      // 直立画牌时各视图位置上单张牌大小
    AryErectDrawOffSet: array[TTemplatePlace] of TDrawMJPaiOffset; // 直立画牌偏移量
    ArySpaceLastCard: array [TTemplatePlace] of Integer;           // 最后摸到的一张牌与前面的牌的间隔
    JumpY: Integer;                                                // 自己方位的牌跳起的高度
  end;

  TAryCardList = array[TMJCardIndex] of TPNGObject;

  // 直立牌的皮肤
  TMJCardErectSkin = record
    NoSelPng: TPngObject;                             // 不能选择时的蒙罩图片
    AryBackPng: array[TTemplatePlace] of TPNGObject;  // 直立背面牌的各个方位
    SelfCardList: TAryCardList;                       // 直立牌面自己方位
  end;

  // 麻将牌的各种动作,因为英文译法晦涩难懂，大量专业词汇用汉语拼音(麻将是国粹，哈哈)
  // 注：广义上的明杠包括大明杠(别人出,本人杠)和小明杠(又称加杠)
  TMJActionName = (mjaError, mjaPass, mjaMo, mjaChi, mjaPeng, mjaDaMingGang,
               mjaChu, mjaAnGang, mjaJiaGang, mjaSpecialGang, mjaBuHua, mjaTing, mjaHu);

  // 这个动作结构用于网络传输和客户端显示
  TPlayerMJActionMin = record
    MJAName: TMJActionName;
    ExpandStr: string;
  end;
  TAryPlayerMJActionMin = array of TPlayerMJActionMin;

const
  CMJACTION_CAPTION: array[TMJActionName] of string =
  ('error', '过', 'mo', 'chi', '碰', '大明杠', 'chu', '暗杠', '加杠', '亮杠', 'buhua', 'ting', 'hu');

  CMJSUIT_CAPTION: array[0..3] of string =
  ('error', '万', '饼', '条');

    CMJDATA_CAPTION: array[TMJCardIndex] of string = //牌名称//对应牌名称
  (
  '一万', '二万', '三万', '四万', '五万', '六万', '七万', '八万', '九万', //万子
  //0     1     2     3     4     5     6     7     8
  '一饼', '二饼', '三饼', '四饼', '五饼', '六饼', '七饼', '八饼', '九饼', //饼子
  //9    10    11    12    13    14    15    16    17
  '一条', '二条', '三条', '四条', '五条', '六条', '七条', '八条', '九条', //条子
  //18   19    20    21    22    23    24    25    26
  '东风', '南风', '西风', '北风', //风牌
  //27   28    29    30
  '红中', '绿发', '白板', //箭牌
  //31   32    33
  '春', '夏', '秋', '冬', '梅', '兰', '竹', '菊' //花牌
  //34   35    36    37    38    39    40    41
  );

implementation

end.
