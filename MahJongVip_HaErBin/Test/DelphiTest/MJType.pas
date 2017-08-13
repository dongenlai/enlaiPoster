unit MJType;

interface

uses

  pngimage, TemplateGlobalST;



type

// �齫������ 1..9��1..9Ͳ��1..9�������������з��ס������ﶬ÷�����
  TMJCardIndex = 0..42 - 1;

  TMJShouPaiItem = record
    rStrData: array of Integer;                           // ��������
    rLastCardID: Byte;                          // ���һ�������������
    rBMoPai: Boolean;                           // �Ƿ��������
    rBJinZhang: Boolean;                        // �Ƿ��Ѿ�����
  end;

  // ƫ����
  TDrawMJPaiOffset = record
    OffsetX: Integer;                                           // ˮƽ�����ƫ����
    OffsetY: Integer;                                           // ��ֱ������ƫ����
  end;

  // ��С����
  TConfigSize = record
    Width: Integer;                       // ���
    Height: Integer;                      // �߶�
  end;

  // ���Ƶ����á����Ƶ�λ����ϢҪ�������ƵĶ������
  TConfigMJGrapShouPai = record
    AryErectSingleSize: array[TTemplatePlace] of TConfigSize;      // ֱ������ʱ����ͼλ���ϵ����ƴ�С
    AryErectDrawOffSet: array[TTemplatePlace] of TDrawMJPaiOffset; // ֱ������ƫ����
    ArySpaceLastCard: array [TTemplatePlace] of Integer;           // ���������һ������ǰ����Ƶļ��
    JumpY: Integer;                                                // �Լ���λ��������ĸ߶�
  end;

  TAryCardList = array[TMJCardIndex] of TPNGObject;

  // ֱ���Ƶ�Ƥ��
  TMJCardErectSkin = record
    NoSelPng: TPngObject;                             // ����ѡ��ʱ������ͼƬ
    AryBackPng: array[TTemplatePlace] of TPNGObject;  // ֱ�������Ƶĸ�����λ
    SelfCardList: TAryCardList;                       // ֱ�������Լ���λ
  end;

  // �齫�Ƶĸ��ֶ���,��ΪӢ���뷨��ɬ�Ѷ�������רҵ�ʻ��ú���ƴ��(�齫�ǹ��⣬����)
  // ע�������ϵ����ܰ���������(���˳�,���˸�)��С����(�ֳƼӸ�)
  TMJActionName = (mjaError, mjaPass, mjaMo, mjaChi, mjaPeng, mjaDaMingGang,
               mjaChu, mjaAnGang, mjaJiaGang, mjaSpecialGang, mjaBuHua, mjaTing, mjaHu);

  // ��������ṹ�������紫��Ϳͻ�����ʾ
  TPlayerMJActionMin = record
    MJAName: TMJActionName;
    ExpandStr: string;
  end;
  TAryPlayerMJActionMin = array of TPlayerMJActionMin;

const
  CMJACTION_CAPTION: array[TMJActionName] of string =
  ('error', '��', 'mo', 'chi', '��', '������', 'chu', '����', '�Ӹ�', '����', 'buhua', 'ting', 'hu');

  CMJSUIT_CAPTION: array[0..3] of string =
  ('error', '��', '��', '��');

    CMJDATA_CAPTION: array[TMJCardIndex] of string = //������//��Ӧ������
  (
  'һ��', '����', '����', '����', '����', '����', '����', '����', '����', //����
  //0     1     2     3     4     5     6     7     8
  'һ��', '����', '����', '�ı�', '���', '����', '�߱�', '�˱�', '�ű�', //����
  //9    10    11    12    13    14    15    16    17
  'һ��', '����', '����', '����', '����', '����', '����', '����', '����', //����
  //18   19    20    21    22    23    24    25    26
  '����', '�Ϸ�', '����', '����', //����
  //27   28    29    30
  '����', '�̷�', '�װ�', //����
  //31   32    33
  '��', '��', '��', '��', '÷', '��', '��', '��' //����
  //34   35    36    37    38    39    40    41
  );

implementation

end.
