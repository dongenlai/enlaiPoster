{
  �����л���ͼƬ���÷�����ֱ��ʾʱ�Լ���λ��ΪƵ���䶯���Բ��û���ͼƬ
  ������λ����ֱ��ʾʱ�û���ͼƬ�����ǻ���ͼƬֻ��������ǰ����ЩͼƬ
    �����������Ʋ��û���ͼƬ��Paint������ֱ�ӻ�(��Ϊ��Ƶ���䶯)
  ƽ����ʾʱ���û���ͼƬ
}

unit MJGrapShouPai;

interface

uses
  Classes, Types, Controls, Graphics, SysUtils, Messages, PngImage, TemplateGlobalST,
  TemplateImageGlobalST, TemplatePicConfigGlobalST, MJType;

type

  // ���ã���Ӵ˽ṹ��Ŀ����Ϊ�˱��뷽��
  TMinConfig = record
    SingleWidth: Integer;                   // ����ͼƬ�Ŀ��
    SingleHeight: Integer;                  // ����ͼƬ�ĸ߶�
    OffsetX: Integer;                       // ͼƬ֮�������
    OffsetY: Integer;                       // ͼƬ֮���������
    Space: Integer;                         // �����һ���Ƶļ��
    MingPSpace: Integer;                    // �����Ƶļ��
    jumpY: Integer;
  end;



  // �¼�����
  TMJMouseDownEvent = procedure(Sender: TObject; ASelPosIndex: Integer; ACardID: Integer) of object;
  TMJMouseMoveEvent = procedure(Sender: TObject; ASelPosIndex: Integer; ACardChar: Char; APoint: TPoint) of object;

  TMJGrapShouPai = class(TGraphicControl)
  private
    FOwnerControl: TControl;                            // ������
    FRealPlace: TTemplatePlace;                         // �Լ�����ʵλ��
    FViewPlace: TTemplatePlace;                         // ��ͼλ��
    FShouPaiData: TMJShouPaiItem;                       // ��������
    FBErect: Boolean;                                   // �Ƿ�ֱ������
    FBBackNoErect: Boolean;                             // ���ƺ����

    // ���±���������Լ���λ�ĸ�������
//    FBHasSorted: Boolean;                               // �Լ���λ�����ƺ��Ƿ��Ѿ���������
    FSelPosIndex: Integer;                              // �Լ�����ԭ��ѡ���������
    FDownPosIndex: Integer;                             // ��ǰ��������������
    FOnMJMouseDown: TMJMouseDownEvent;                  // ��갴���¼�
    FOnMJMouseMove: TMJMouseMoveEvent;                  // ����ƶ�ʱ��

    FErectCardSkin: TMJCardErectSkin;                   // ֱ����Ƥ��
    FMinCfg: TMinConfig;
  private
    procedure CalcPosAndSize(const AMinCfg: TMinConfig; var RetLeft, RetTop, RetWidth, RetHeight: Integer);
    procedure GetRectByIndex(const AMinCfg: TMinConfig; AIndex: Integer; var RetRect: TRect);
    function PointToCardPosIndex(const APoint: TPoint): Integer;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    function DeleteACard(ACardID: Byte; ACount: Integer): Boolean;
  protected
    procedure DoChangeSelf;
    procedure DrawErectSelfCards(AMinCfg: TMinConfig);
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure DoChange;

    procedure Initialize(AParent: TControl);

    procedure updateCardList(ACardAry: TIntegerDynArray);                            // ����ץ��
    procedure TakePai(ACardID: Byte; AIsBuZhang: Boolean);                               // ����,�������ƺͲ���
    function PengGangPai(ACardID: Byte; ACount: Integer): Boolean;
    function ChiPai(ADelStr: string): Boolean;
  public
    property RealPlace: TTemplatePlace read FRealPlace write FRealPlace;
    property ErectCardSkin: TMJCardErectSkin read FErectCardSkin write FErectCardSkin;
    property OnMJMouseDown: TMJMouseDownEvent read FOnMJMouseDown write FOnMJMouseDown;
    property OnMJMouseMove: TMJMouseMoveEvent read FOnMJMouseMove write FOnMJMouseMove;
  end;

  

implementation

uses
  TemplatePubUtils, Forms;

{ TMJGrapShouPai }


procedure TMJGrapShouPai.CMMouseLeave(var Message: TMessage);
begin
  inherited;

  if FViewPlace = 0 then
  begin
    if FSelPosIndex <> CINVALID_INDEX then
    begin
      FSelPosIndex := CINVALID_INDEX;
      Invalidate;
    end;
  end;
end;

constructor TMJGrapShouPai.Create(AOwner: TComponent);
var
  I: Integer;
  LResPath: string;
begin
  inherited;

  FBErect := True;
  FBBackNoErect := False;
  FSelPosIndex := CINVALID_INDEX;
  FDownPosIndex := CINVALID_INDEX;

  LResPath := ExtractFilePath(Application.ExeName) + '\res\MJCardErect';

  for I := 0 to Length(FErectCardSkin.SelfCardList) - 1 do
  begin
    FErectCardSkin.SelfCardList[i] := TPNGObject.Create;
    FErectCardSkin.SelfCardList[i].LoadFromFile(Format('%s\MJCardErect%.2d.png', [lrespath, I]));
  end;

  FMinCfg.SingleWidth := 58;
    FMinCfg.SingleHeight := 89;
      FMinCfg.OffsetX := 51;
        FMinCfg.OffsetY := 89;
  FMinCfg.jumpY := 20;
end;

function TMJGrapShouPai.DeleteACard(ACardID: Byte; ACount: Integer): Boolean;
//var
//  I: Integer;
//  LLen: Integer;
//  LStr: string;
//  LCount: Integer;
//  J: Integer;
begin
  Result := True;
//  Result := False;
//
//  LLen := Length(FShouPaiData.rStrData);
//  if LLen <= 0 then
//    Exit;
//
//
//  LCount := 0;
//  for I := 1 to LLen do
//    if FShouPaiData.rStrData[I] = ACardID then
//      Inc(LCount);
//  if LCount < ACount then
//    Exit;
//
//  LCount := 0;
//  for I := LLen - 1 downto 0 do
//  begin
//    if FShouPaiData.rStrData[I] = ACardID then
//    begin
//      for J := I to Length(FShouPaiData.rStrData) - 2 do
//      begin
//        FShouPaiData[j] := FShouPaiData[j+1];
//        Inc(LCount);
//        if(LCount >= acount)then
//          Break;
//      end;
//    end;
//  end;
//
//  SetLength(FShouPaiData.rStrData, llen-acount);
//
//
//  DoChange;
//
//  Result := True;
end;



destructor TMJGrapShouPai.Destroy;
begin

  inherited;
end;

procedure TMJGrapShouPai.DoChange;
begin
    DoChangeSelf;
    Invalidate;
end;

procedure TMJGrapShouPai.DoChangeSelf;
var
  LLen: Integer;
  LLeft, LTop, LWidth, LHeight: Integer;
  LPoint: TPoint;


  function ProcEmptyStr: Boolean;
  // ���ַ�����������
  begin
    if LLen = 0 then
    begin
      Width := 0;
      Height := 0;
      Result := True;
    end else
      Result := False;
  end;

  

begin
  LPoint := Point(0, 0);
  LLen := Length(FShouPaiData.rStrData);

  if ProcEmptyStr then
    Exit;

  CalcPosAndSize(FMinCfg, LLeft, LTop, LWidth, LHeight);

  width := LWidth;
  height := LHeight;
  Invalidate;
end;

procedure TMJGrapShouPai.DrawErectSelfCards(AMinCfg: TMinConfig);
var
  I: Integer;
  LDestRect: TRect;
  LCardIndex: Integer;
begin
  for I := 0 to Length(FShouPaiData.rStrData) - 1 do
  begin
    GetRectByIndex(AMinCfg, I, LDestRect);
    if FSelPosIndex <> I then
      OffsetRect(LDestRect, 0, FMinCfg.jumpY);
    LCardIndex := FShouPaiData.rStrData[I];
    if (LCardIndex >= 0) and (LCardIndex < 42) then
      Canvas.Draw(LDestRect.Left, LDestRect.Top, FErectCardSkin.SelfCardList[LCardIndex]);
  end;
end;



procedure TMJGrapShouPai.GetRectByIndex(const AMinCfg: TMinConfig; AIndex: Integer; var RetRect: TRect);
// ��ȡ��AIndex�����ڵ�ǰͼ���е�λ��
//var
//  LLen: Integer;
begin
//  LLen := Length(FShouPaiData.rStrData);


  RetRect.Left := AIndex * AMinCfg.OffsetX;
  RetRect.Top := 0;


  RetRect.Right := RetRect.Left + AMinCfg.SingleWidth;
  RetRect.Bottom := RetRect.Top + AMinCfg.SingleHeight;
end;



procedure TMJGrapShouPai.Initialize(AParent: TControl);
begin
  FOwnerControl := AParent;
end;


procedure TMJGrapShouPai.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  LIndexSel: Integer;
  LMJIndex: Integer;
begin
  inherited;

  // ֻ���Լ����Ʋ���Ӧ����¼�
  if FViewPlace <> 0 then
    Exit;
  // ƽ�̻���ʱҲ����Ӧ
  if not FBErect then
    Exit;
  
  LIndexSel := PointToCardPosIndex(Point(X, Y));
  if LIndexSel < 0 then
    Exit;

  FDownPosIndex := LIndexSel;
  LMJIndex := FShouPaiData.rStrData[FDownPosIndex];
  if Assigned(FOnMJMouseDown) then
    FOnMJMouseDown(Self, LIndexSel, LMJIndex);
end;

procedure TMJGrapShouPai.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LIndexSel: Integer;
//  LRect: TRect;
//  LPoint: TPoint;
begin
  inherited;

  // ֻ���Լ����Ʋ���Ӧ����¼�
  if FViewPlace <> 0 then
    Exit;
  // ƽ�̻���ʱҲ����Ӧ
  if not FBErect then
    Exit;
  LIndexSel := PointToCardPosIndex(Point(X, Y));

  if LIndexSel <> FSelPosIndex then
  begin
      FSelPosIndex := LIndexSel;
      Invalidate;
  end;
end;


procedure TMJGrapShouPai.Paint;
begin
  inherited;

    DrawErectSelfCards(FMinCfg)
end;

function TMJGrapShouPai.PengGangPai(ACardID: Byte; ACount: Integer): Boolean;
begin
  if FViewPlace = 0 then
    Result := DeleteACard(ACardID, ACount)
  else
  begin
    FShouPaiData.rStrData := Copy(FShouPaiData.rStrData, ACount + 1, MaxInt);
    Result := True;
  end;
  // ����ʱҪ�������е�������,����û�н��š� ����ʱ�Ѿ�����
  if ACount = 2 then
    FShouPaiData.rBJinZhang := True
  else
    FShouPaiData.rBJinZhang := False
end;

function TMJGrapShouPai.PointToCardPosIndex(const APoint: TPoint): Integer;
// �Լ��ơ���ֱ��ͼ���У�APoint��Ӧ����������
var
  LRect: TRect;
  LLen: Integer;
  I: Integer;
begin
  Result := 0;
  LRect.Top := 0;
  LRect.Bottom := Height;
  LLen := Length(FShouPaiData.rStrData);
  // ��������Ч�ʣ��ɲ����۰���ҵķ���
  for I := 1 to LLen do
  begin
    GetRectByIndex(FMinCfg, i, LRect);
    if PtInRect(LRect, APoint) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;


procedure TMJGrapShouPai.CalcPosAndSize(const AMinCfg: TMinConfig; var RetLeft, RetTop, RetWidth, RetHeight: Integer);
var
  LLen: Integer;
begin
  LLen := Length(FShouPaiData.rStrData);


  RetWidth := (LLen - 1) * AMinCfg.OffsetX + AMinCfg.SingleWidth;
    RetHeight := AMinCfg.SingleHeight + fmincfg.JumpY;
    RetLeft := 0;
    RetTop := 0;
end;

function TMJGrapShouPai.ChiPai(ADelStr: string): Boolean;
//var
//  I: Integer;
//  LMJProp: TMJCardProp;
begin
  Result := True;
//  Result := False;
//  if Length(ADelStr) <> 2 then
//    Exit;
//
//  if FViewPlace = 0 then
//  begin
//    for I := 1 to Length(ADelStr) do
//    begin
//      LMJProp := GetMJProp(ADelStr[I]);
//      Result := DeleteACard(LMJProp.CardID, 1);
//      if not Result then
//        Exit;
//    end;
//  end else
//  begin
//    FShouPaiData.rStrData := Copy(FShouPaiData.rStrData, 3, MaxInt);
//  end;
//  FShouPaiData.rBMoPai := False;
//  FShouPaiData.rBJinZhang := True;
//
//  Result := True;
end;



procedure TMJGrapShouPai.TakePai(ACardID: Byte; AIsBuZhang: Boolean);
begin
//  LGameClient := TTemplateGameClient(FOwnerControl);
//  // ����ʱ����Ӱ�������߼�
//  if LGameClient.GameStateMgr.GameState = tgsXingPai then
//  begin
//    FShouPaiData.rLastCardID := ACardID;
//    FShouPaiData.rBJinZhang := True;
//    FShouPaiData.rBMoPai := True;
//  end;
//  if FViewPlace = 0 then
//  begin
//    FShouPaiData.rStrData := FShouPaiData.rStrData + GMJCardList[ACardID].CardChar;
//    FSelPosIndex := CINVALID_INDEX;
//  end else
//    FShouPaiData.rStrData := FShouPaiData.rStrData + CMJCHAR_SHOUPAI_HIDE;
//
//  if not AIsBuZhang then
//    Invalidate
//  else
//    DoChange;
end;

procedure TMJGrapShouPai.updateCardList(ACardAry: TIntegerDynArray);
var
  I: Integer;
begin
  SetLength(FShouPaiData.rStrData, Length(ACardAry));
  for I := 0 to Length(ACardAry) - 1 do
  begin
    FShouPaiData.rStrData[i] := ACardAry[i];
  end;

  DoChange;
end;

end.
