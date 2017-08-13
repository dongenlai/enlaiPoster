{
  手牌中缓存图片的用法：竖直显示时自己方位因为频繁变动所以不用缓存图片
  其他方位当竖直显示时用缓存图片，但是缓存图片只保存摸牌前的那些图片
    摸到的那张牌不用缓存图片在Paint函数里直接画(因为它频繁变动)
  平铺显示时都用缓存图片
}

unit MJGrapShouPai;

interface

uses
  Classes, Types, Controls, Graphics, SysUtils, Messages, PngImage, TemplateGlobalST,
  TemplateImageGlobalST, TemplatePicConfigGlobalST, MJType;

type

  // 配置，添加此结构的目的是为了编码方便
  TMinConfig = record
    SingleWidth: Integer;                   // 单张图片的宽度
    SingleHeight: Integer;                  // 单张图片的高度
    OffsetX: Integer;                       // 图片之间横向间距
    OffsetY: Integer;                       // 图片之间的纵向间距
    Space: Integer;                         // 与最后一张牌的间距
    MingPSpace: Integer;                    // 与明牌的间距
    jumpY: Integer;
  end;



  // 事件类型
  TMJMouseDownEvent = procedure(Sender: TObject; ASelPosIndex: Integer; ACardID: Integer) of object;
  TMJMouseMoveEvent = procedure(Sender: TObject; ASelPosIndex: Integer; ACardChar: Char; APoint: TPoint) of object;

  TMJGrapShouPai = class(TGraphicControl)
  private
    FOwnerControl: TControl;                            // 父窗口
    FRealPlace: TTemplatePlace;                         // 自己的真实位置
    FViewPlace: TTemplatePlace;                         // 视图位置
    FShouPaiData: TMJShouPaiItem;                       // 手牌数据
    FBErect: Boolean;                                   // 是否直立画牌
    FBBackNoErect: Boolean;                             // 整牌后扣牌

    // 以下变量是针对自己方位的辅助变量
//    FBHasSorted: Boolean;                               // 自己方位摸到牌后是否已经重新排序
    FSelPosIndex: Integer;                              // 自己手中原来选择的牌索引
    FDownPosIndex: Integer;                             // 当前按下鼠标的牌索引
    FOnMJMouseDown: TMJMouseDownEvent;                  // 鼠标按下事件
    FOnMJMouseMove: TMJMouseMoveEvent;                  // 鼠标移动时间

    FErectCardSkin: TMJCardErectSkin;                   // 直立牌皮肤
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

    procedure updateCardList(ACardAry: TIntegerDynArray);                            // 开局抓牌
    procedure TakePai(ACardID: Byte; AIsBuZhang: Boolean);                               // 拿牌,包括摸牌和补张
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
  // 空字符串单独处理
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
// 获取第AIndex张牌在当前图像中的位置
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

  // 只有自己的牌才响应鼠标事件
  if FViewPlace <> 0 then
    Exit;
  // 平铺画牌时也不响应
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

  // 只有自己的牌才响应鼠标事件
  if FViewPlace <> 0 then
    Exit;
  // 平铺画牌时也不响应
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
  // 杠牌时要把手牌列到明牌中,所以没有进张。 碰牌时已经进张
  if ACount = 2 then
    FShouPaiData.rBJinZhang := True
  else
    FShouPaiData.rBJinZhang := False
end;

function TMJGrapShouPai.PointToCardPosIndex(const APoint: TPoint): Integer;
// 自己牌、竖直牌图像中，APoint对应的牌张索引
var
  LRect: TRect;
  LLen: Integer;
  I: Integer;
begin
  Result := 0;
  LRect.Top := 0;
  LRect.Bottom := Height;
  LLen := Length(FShouPaiData.rStrData);
  // 如果想提高效率，可采用折半查找的方法
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
//  // 补花时候不能影响数据逻辑
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
