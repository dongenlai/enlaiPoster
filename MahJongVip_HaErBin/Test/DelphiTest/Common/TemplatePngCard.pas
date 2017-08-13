{*************************************************************************}
{                                                                         }
{  单元说明: Png牌控件                                                    }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  单元用途:                                                              }
{                                                                         }
{      梭哈游戏的Png牌，支持正面和背面混合。 当点击背面的牌时，可以显示   }
{  一段时间。要支持牌型的显示。                                           }
{                                                                         }
{  属性：是否可以点击等。                                                 }
{                                                                         }
{*************************************************************************}

unit TemplatePngCard;

interface

uses
  Classes, Windows, Messages, Controls, PngImage, TemplateGlobalST, TemplateImageGlobalST,
  TemplatePicConfigGlobalST, TemplateCardGlobalST, SysUtils;

type

  TTemplatePngCard = class;
  TTemplatePngCardFixAry = array[TTemplatePlace] of TTemplatePngCard;

  TTemplatePngCard = class(TGraphicControl)
  type
    TPngGameCard = record
      IsSelected: Boolean;
      Card: TGameCard;
    end;
    TPngGameCardAry = array of TPngGameCard;
  private
    FImageSkin: TPngCardPic;                                    // 图片
    FImageCfg: TConfigPngCard;                                  // 配置
    
    FCardAry: TPngGameCardAry;                                  // 牌数组
    FCardArrangeType: TCardArrangeType;                         // 牌的方向
    FCardBackType: TCardBackType;                               // 牌背面类型
    FCanSelect: Boolean;                                        // 是否可以选择
    FCardSortType: TLordCardSortType;                           // 排序规则

    FIsAllBackCard: Boolean;                                    // 是否全部是背面的牌
    FCurCardInterval: Integer;                                  // 当前牌的间隙
    FCurACardWidth: Integer;                                    // 当前牌的宽度
    FCurACardHeight: Integer;                                   // 当前牌的高度
    FIsMouseDown: Boolean;                                      // 鼠标是否按下
    FMouseDownCardIndex: Integer;                               // 鼠标按下的牌下标
    FCurMouseCardIndex: Integer;                                // 当前鼠标所在的牌下标           
  private
    procedure InitData;
    procedure ClearSelectState;
    procedure ReSortCardAry;
    procedure DoChange;

    function GetIsEmpty: Boolean;
    function GetCardCount: Integer;
    function GetIsAllBackCard: Boolean;
    function GetCardIndexByPos(AXPos, AYPos: Smallint): Integer;
    procedure SetImageCfg(const Value: TConfigPngCard);
    procedure SetImageSkin(const Value: TPngCardPic);
    procedure SetCardArrangeType(const Value: TCardArrangeType);
    procedure SetCardBackType(const Value: TCardBackType);
    procedure SetCanSelect(const Value: Boolean);
    procedure SetCardSortType(const Value: TLordCardSortType);
  protected
    procedure Paint; override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ClearCard;
    procedure UnSelectCard;
    procedure SetCardAry(const ACardAry: TGameCardAry);
    procedure GetCardAry(var RetCardAry: TGameCardAry);
    procedure GetSelectedCardAry(var RetCardAry: TGameCardAry);
    procedure SetSelectedCardAry(const ASelCardAry: TGameCardAry);
    procedure AddACard(const ACard: TGameCard);
  public
    property ImageSkin: TPngCardPic read FImageSkin write SetImageSkin;
    property ImageCfg: TConfigPngCard read FImageCfg write SetImageCfg;
    property IsEmpty: Boolean read GetIsEmpty;
    property CardCount: Integer read GetCardCount;
    property IsAllBackCard: Boolean read FIsAllBackCard;

    property CardArrangeType: TCardArrangeType read FCardArrangeType write SetCardArrangeType;
    property CardBackType: TCardBackType read FCardBackType write SetCardBackType;
    property CanSelect: Boolean read FCanSelect write SetCanSelect;
    property CardSortType: TLordCardSortType read FCardSortType write SetCardSortType;

    property OnDblClick;
    property OnMouseDown;
  end;

implementation

uses
  TemplatePubUtils;

{ TTemplatePngCard }

procedure TTemplatePngCard.AddACard(const ACard: TGameCard);
var
  LCardAry: TGameCardAry;
begin
  GetCardAry(LCardAry);
  SetLength(LCardAry, Length(LCardAry) + 1);
  LCardAry[High(LCardAry)] := ACard;
  
  SetCardAry(LCardAry);
end;

procedure TTemplatePngCard.ClearCard;
var
  LCardAry: TGameCardAry;
begin
  SetLength(LCardAry, 0);
  SetCardAry(LCardAry);
end;

procedure TTemplatePngCard.ClearSelectState;
var
  I: Integer;
begin
  for I := Low(FCardAry) to High(FCardAry) do
  begin
    FCardAry[I].IsSelected := False;
  end;

  FIsMouseDown := False;
  FMouseDownCardIndex := CINVALID_INDEX;
  FCurMouseCardIndex := CINVALID_INDEX;
end;

constructor TTemplatePngCard.Create(AOwner: TComponent);
begin
  inherited;
  
  InitData;
end;

destructor TTemplatePngCard.Destroy;
begin
  InitData;

  inherited;
end;

procedure TTemplatePngCard.DoChange;
var
  LWidth, LHeight: Integer;
  LOldVisible: Boolean;
begin
  // 计算牌的大小
  FIsAllBackCard := GetIsAllBackCard;

  if IsEmpty then
  begin
    Width := 0;
    Height := 0;
  end else
  begin
    if FIsAllBackCard then
      FCurCardInterval := FImageCfg.BackInterval[FCardArrangeType]
    else
      FCurCardInterval := FImageCfg.CardInterval[FCardArrangeType];
      
    if FCardArrangeType = catHorizontal then
    begin
      LWidth := (Length(FCardAry) - 1) * FCurCardInterval + FCurACardWidth;
      LHeight := FCurACardHeight + FImageCfg.SelectedInterval;
    end else
    begin
      // 竖向的牌是不让选择的
      LWidth := FCurACardWidth;
      LHeight := (Length(FCardAry) - 1) * FCurCardInterval + FCurACardHeight;
    end;

    if (LWidth <> Width) or (LHeight <> Height) then
    begin
      LOldVisible := Visible;
      
      if LOldVisible then
        Visible := False;
      Width := LWidth;
      Height := LHeight;

      Visible := LOldVisible;
    end;
  end;

  ClearSelectState;
  Invalidate;
end;

procedure TTemplatePngCard.GetCardAry(var RetCardAry: TGameCardAry);
var
  I: Integer;
begin
  SetLength(RetCardAry, Length(FCardAry));
  for I := Low(RetCardAry) to High(RetCardAry) do
  begin
    RetCardAry[I] := FCardAry[I].Card;
  end;
end;

function TTemplatePngCard.GetCardCount: Integer;
begin
  Result := Length(FCardAry);
end;

function TTemplatePngCard.GetCardIndexByPos(AXPos, AYPos: Smallint): Integer;
var
  I: Integer;
  LFromIndex, LToIndex: Integer;
  LPoint: TPoint;
  LRect: TRect;
begin
  // 根据位置来确定哪张牌
  Result := CINVALID_INDEX;

  // 只处理横向牌的情况
  if FCardArrangeType = catHorizontal then
  begin
    LPoint.X := AXPos;
    LPoint.Y := AYPos;
    LFromIndex := AXPos div FCurCardInterval;
    if LFromIndex > High(FCardAry) then
      LFromIndex := High(FCardAry);
    LToIndex := (AXPos - FCurACardWidth) div FCurCardInterval - 1;
    if LToIndex < Low(FCardAry) then
      LToIndex := Low(FCardAry);

    for I := LFromIndex downto LToIndex do
    begin
      LRect.Left := I * FCurCardInterval;
      if FCardAry[I].IsSelected then
      begin
        LRect.Top := 0;
      end else
      begin
        LRect.Top := FImageCfg.SelectedInterval;
      end;
      LRect.Right := LRect.Left + FCurACardWidth;
      LRect.Bottom := LRect.Top + FCurACardHeight;

      if PtInRect(LRect, LPoint) then
      begin
        Result := I;
        Break;
      end;
    end;
  end;
end;

function TTemplatePngCard.GetIsAllBackCard: Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := Low(FCardAry) to High(FCardAry)do
  begin
    if FCardAry[I].Card.Color <> sccBack then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TTemplatePngCard.GetIsEmpty: Boolean;
begin
  if (Length(FCardAry) < 1) or (FCurACardWidth = 0) or (FCurACardHeight = 0)
  or (FImageCfg.CardImageList.SmallWidth = 0) then
    Result := True
  else
    Result := False;
end;

procedure TTemplatePngCard.GetSelectedCardAry(var RetCardAry: TGameCardAry);
var
  I: Integer;
  LIndex: Integer;
  LCardCount: Integer;
begin
  LCardCount := 0;
  for I := Low(FCardAry) to High(FCardAry) do
  begin
    if FCardAry[I].IsSelected then
      Inc(LCardCount);
  end;

  SetLength(RetCardAry, LCardCount);
  LIndex := 0;
  for I := Low(FCardAry) to High(FCardAry) do
  begin
    if FCardAry[I].IsSelected then
    begin
      RetCardAry[LIndex] := FCardAry[I].Card;
      Inc(LIndex);
    end;
  end;
end;

procedure TTemplatePngCard.InitData;
begin
  SetLength(FCardAry, 0);
  FCardArrangeType := catHorizontal;
  FCardBackType := cbtNormal;
  FCanSelect := True;
  FCardSortType := lcstNone;

  FIsAllBackCard := False;
  FCurCardInterval := 0;
  FCurACardWidth := 0;
  FCurACardHeight := 0;
  ClearSelectState;
end;

procedure TTemplatePngCard.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;

  if Button <> mbLeft then
    Exit;
  if (not FCanSelect) or GetIsEmpty then
    Exit;
  if FIsMouseDown or FIsAllBackCard then
    Exit;

  FMouseDownCardIndex := GetCardIndexByPos(X, Y);
  FCurMouseCardIndex := FMouseDownCardIndex;
  if FMouseDownCardIndex = CINVALID_INDEX then
    FIsMouseDown := False
  else
    FIsMouseDown := True;
end;

procedure TTemplatePngCard.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LCurMouseCardIndex: Integer;
begin
  inherited;

  if (not FCanSelect) or GetIsEmpty then
    Exit;
    
  if FIsMouseDown then
  begin
    LCurMouseCardIndex := GetCardIndexByPos(X, Y);
    if (LCurMouseCardIndex <> CINVALID_INDEX) and (FCurMouseCardIndex <> LCurMouseCardIndex) then
    begin
      FCurMouseCardIndex := LCurMouseCardIndex;
      Invalidate;
    end;       
  end;
end;

procedure TTemplatePngCard.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  I: Integer;
  LCurMouseCardIndex: Integer;
  LFromIndex, LToIndex: Integer;
begin
  inherited;

  if Button <> mbLeft then
    Exit;
  if (not FCanSelect) or GetIsEmpty then
    Exit;
  if FIsMouseDown then
  begin
    LCurMouseCardIndex := GetCardIndexByPos(X, Y);
    if LCurMouseCardIndex <> CINVALID_INDEX then
      FCurMouseCardIndex := LCurMouseCardIndex;

    if FCurMouseCardIndex > FMouseDownCardIndex then
    begin
      LFromIndex := FMouseDownCardIndex;
      LToIndex := FCurMouseCardIndex;
    end else
    begin
      LFromIndex := FCurMouseCardIndex;
      LToIndex := FMouseDownCardIndex;
    end;

    if LFromIndex < Low(FCardAry) then
      LFromIndex := Low(FCardAry);
    if LToIndex > High(FCardAry) then
      LToIndex := High(FCardAry);

    // 反向选择
    for I := LFromIndex to LToIndex do
    begin
      FCardAry[I].IsSelected := not FCardAry[I].IsSelected; 
    end;

    FIsMouseDown := False;
    FMouseDownCardIndex := CINVALID_INDEX;
    FCurMouseCardIndex := CINVALID_INDEX;

    Invalidate;
  end;
end;

procedure TTemplatePngCard.Paint;

  function GetACardPngPic(const ACard: TGameCard): TPNGObject;
  begin
    Result := nil;

    if (ACard.Color >= sccDiamond) and (ACard.Color <= sccSpade) then
    begin
      if (ACard.Value >= scvA) and (ACard.Value <= scvB2) then
        Result := FImageSkin.AToKPic[ACard.Color][ACard.Value];
    end else if ACard.Color = sccJoker then
    begin
      if ACard.Value in [scvSJoker, scvBJoker] then
        Result := FImageSkin.JokerPic[ACard.Value];
    end else if ACard.Color = sccBack then
    begin
      Result := FImageSkin.BackPic[FCardBackType];
    end;
  end;

  procedure DrawCard;
  var
    I: Integer;
    LXPos, LYPos: Integer;
    LSelectInterval: Integer;
    LIsSelected: Boolean;
    LPng: TPNGObject;
    LFromSelectingIndex, LToSelectingIndex: Integer;

    procedure DrawHorizontalCard(ACardIndex: Integer);
    begin
      if LIsSelected then
        LYPos := 0
      else
        LYPos := LSelectInterval;
          
      Canvas.Draw(LXPos, LYPos, LPng);
        
      if LIsSelected then
      begin
        Canvas.Draw(LXPos, LYPos, FImageSkin.MaskPic[cmtSelected]);
      end;

      if FIsMouseDown and (ACardIndex >= LFromSelectingIndex) and (ACardIndex <= LToSelectingIndex) then
      begin
        Canvas.Draw(LXPos, LYPos, FImageSkin.MaskPic[cmtSelecting]);          
      end;

      Inc(LXPos, FCurCardInterval);
    end;

    procedure DrawVerticalCard(ACardIndex: Integer);
    begin
      Canvas.Draw(LXPos, LYPos, LPng);
      Inc(LYPos, FCurCardInterval);
    end;
    
  begin
    LXPos := 0;
    LYPos := 0;
    LFromSelectingIndex := CINVALID_INDEX;
    LToSelectingIndex := CINVALID_INDEX;
    LSelectInterval := FImageCfg.SelectedInterval;

    if FIsMouseDown then
    begin
      if FCurMouseCardIndex > FMouseDownCardIndex then
      begin
        LFromSelectingIndex := FMouseDownCardIndex;
        LToSelectingIndex := FCurMouseCardIndex;
      end else
      begin
        LFromSelectingIndex := FCurMouseCardIndex;
        LToSelectingIndex := FMouseDownCardIndex;
      end;
    end;
    
    for I := Low(FCardAry) to High(FCardAry) do
    begin
      LPng := GetACardPngPic(FCardAry[I].Card);
      LIsSelected := FCardAry[I].IsSelected;

      if LPng <> nil then
      begin
        if FCardArrangeType = catHorizontal then
          DrawHorizontalCard(I)
        else
          DrawVerticalCard(I);
      end;
    end;
  end;

begin
  inherited;

  if (not IsEmpty) and (Width > 0) and Visible then
  begin
    DrawCard;
  end;
end;

procedure TTemplatePngCard.ReSortCardAry;

  function CompareACard(const ACard1, ACard2: TGameCard): Integer;
  begin
    // 结果: ACard1>ACard2则大于0，相等则等于0，ACard1<ACard2则小于0
    Result := Ord(ACard1.Value) - Ord(ACard2.Value);

    if Result = 0 then
      Result := Ord(ACard1.Color) - Ord(ACard2.Color);
  end;

  procedure SortCardByValue(var RetAry: TPngGameCardAry);
  var
    I, J: Integer;
    LMaxIndex: Integer;
    LTmpCard: TPngGameCard;
  begin
    for I := Low(RetAry) to High(RetAry) - 1 do
    begin
      LMaxIndex := I;
      for J := I + 1 to High(RetAry) do
      begin
        if CompareACard(RetAry[J].Card, RetAry[LMaxIndex].Card) > 0 then
          LMaxIndex := J;
      end;

      if LMaxIndex <> I then
      begin
        LTmpCard := RetAry[LMaxIndex];
        RetAry[LMaxIndex] := RetAry[I];
        RetAry[I] := LTmpCard;
      end;
    end;
  end;

  procedure GetCardScanTable(
    const ADecSortCardAry: TPngGameCardAry;
    var RetScanArySortByValue: TCardScanItemAry);
  var
    I: Integer;
    LLastCard: TGameCard;
    LRetScanIndex: Integer;

    procedure RaiseRetScanAry(ACardIndex: Integer);
    begin
      Inc(LRetScanIndex);
      SetLength(RetScanArySortByValue, LRetScanIndex + 1);

      LLastCard := ADecSortCardAry[ACardIndex].Card;
      RetScanArySortByValue[LRetScanIndex].Card := LLastCard;
      RetScanArySortByValue[LRetScanIndex].Count := 1;
      RetScanArySortByValue[LRetScanIndex].Index := ACardIndex;
    end;

  begin
    // 计算牌的扫描表格
    // 根据从大到小排列的牌，根据牌值生成一个按照牌大小排序的牌的数量扫描表
    if Length(ADecSortCardAry) < 1 then
    begin
      SetLength(RetScanArySortByValue, 0);
    end else
    begin
      LRetScanIndex := -1;
      RaiseRetScanAry(0);

      for I := Low(ADecSortCardAry) + 1 to High(ADecSortCardAry) do
      begin
        if ADecSortCardAry[I].Card.Value = LLastCard.Value then
        begin
          Inc(RetScanArySortByValue[LRetScanIndex].Count);
        end else
        begin
          RaiseRetScanAry(I);
        end;
      end;
    end;
  end;

  procedure DecSortCardScanAryByCount(
    var RetScanAry: TCardScanItemAry);
  var
    I, J: Integer;
    LMaxIndex: Integer;
    LTmpItem: TCardScanItem;
    LCountInterval: Integer;
  begin
    for I := Low(RetScanAry) to High(RetScanAry) - 1 do
    begin
      LMaxIndex := I;
      for J := I + 1 to High(RetScanAry) do
      begin
        LCountInterval := RetScanAry[J].Count - RetScanAry[LMaxIndex].Count;
        if LCountInterval > 0 then
        begin
          LMaxIndex := J;
        end else if LCountInterval = 0 then
        begin
          if CompareACard(RetScanAry[J].Card, RetScanAry[LMaxIndex].Card) > 0 then
            LMaxIndex := J;
        end;
      end;

      if LMaxIndex <> I then
      begin
        LTmpItem := RetScanAry[LMaxIndex];
        RetScanAry[LMaxIndex] := RetScanAry[I];
        RetScanAry[I] := LTmpItem; 
      end;
    end;
  end;

  procedure CopyPngGameCardAry(const ASource: TPngGameCardAry; var Dest: TPngGameCardAry);
  var
    I: Integer;
  begin
    SetLength(Dest, Length(ASource));
    for I := Low(Dest) to High(Dest) do
      Dest[I] := ASource[I];
  end;

  procedure SortCardByCount(var RetAry: TPngGameCardAry);
  var
    LTmpCardAry: TPngGameCardAry;
    LScanAry: TCardScanItemAry;
    LScanIndex: Integer;
    LCardIndex: Integer;
    LCountIndex: Integer;
    LFirstIndex: Integer;
  begin
    CopyPngGameCardAry(RetAry, LTmpCardAry);
    SortCardByValue(LTmpCardAry);
    GetCardScanTable(LTmpCardAry, LScanAry);
    DecSortCardScanAryByCount(LScanAry);

    LCardIndex := 0;
    for LScanIndex := Low(LScanAry) to High(LScanAry) do
    begin
      LFirstIndex := LScanAry[LScanIndex].Index;
      for LCountIndex := 0 to LScanAry[LScanIndex].Count - 1 do
      begin
        RetAry[LCardIndex] := LTmpCardAry[LFirstIndex + LCountIndex];
        Inc(LCardIndex);
      end;
    end;
  end;

begin
  // 根据排序规则，重新排序
  if FCardSortType = lcstByValue then
    SortCardByValue(FCardAry)
  else if FCardSortType = lcstByCount then
    SortCardByCount(FCardAry);
end;

procedure TTemplatePngCard.SetCanSelect(const Value: Boolean);
begin
  if FCanSelect <> Value then
  begin
    FCanSelect := Value;
    ClearSelectState;
    Invalidate;
  end;
end;

procedure TTemplatePngCard.SetCardArrangeType(const Value: TCardArrangeType);
begin
  if FCardArrangeType <> Value then
  begin
    FCardArrangeType := Value;

    DoChange;
  end;
end;

procedure TTemplatePngCard.SetCardAry(const ACardAry: TGameCardAry);
var
  I: Integer;
  LIsSame: Boolean;
begin
  if Length(FCardAry) = Length(ACardAry) then
  begin
    LIsSame := True;
    for I := Low(FCardAry) to High(FCardAry) do
    begin
      if (FCardAry[I].Card.Color <> ACardAry[I].Color) or (FCardAry[I].Card.Value <> ACardAry[I].Value) then
      begin
        LIsSame := False;
        Break;
      end;
    end;
  end else
    LIsSame := False;

  if not LIsSame then
  begin
    SetLength(FCardAry, Length(ACardAry));
    for I := Low(FCardAry) to High(FCardAry) do
    begin
      FCardAry[I].IsSelected := False;
      FCardAry[I].Card := ACardAry[I];
    end;

    ReSortCardAry;
    DoChange;
  end;
end;

procedure TTemplatePngCard.SetCardBackType(const Value: TCardBackType);
begin
  if FCardBackType <> Value then
  begin
    FCardBackType := Value;
    Invalidate;
  end;
end;

procedure TTemplatePngCard.SetCardSortType(const Value: TLordCardSortType);
begin
  if FCardSortType <> Value then
  begin
    FCardSortType := Value;
    ClearSelectState;
    ReSortCardAry;

    Invalidate;
  end;
end;

procedure TTemplatePngCard.SetImageCfg(const Value: TConfigPngCard);
begin
  FImageCfg := Value;

  DoChange;
end;

procedure TTemplatePngCard.SetImageSkin(const Value: TPngCardPic);
begin
  FImageSkin := Value;
  if Assigned(FImageSkin.BackPic[cbtNormal]) then
  begin
    FCurACardWidth := FImageSkin.BackPic[cbtNormal].Width;
    FCurACardHeight := FImageSkin.BackPic[cbtNormal].Height;
  end else
  begin
    FCurACardWidth := 0;
    FCurACardHeight := 0;
  end;
  
  DoChange;
end;

procedure TTemplatePngCard.SetSelectedCardAry(const ASelCardAry: TGameCardAry);
var
  I, J: Integer;
  LSelCard: TGameCard;
  LTmpCard: TGameCard;
begin
  ClearSelectState;

  for I := Low(ASelCardAry) to High(ASelCardAry) do
  begin
    LSelCard := ASelCardAry[I];
    for J := Low(FCardAry) to High(FCardAry) do
    begin
      LTmpCard := FCardAry[J].Card;
      if (LTmpCard.Color = LSelCard.Color) and (LTmpCard.Value = LSelCard.Value) then
      begin
        FCardAry[J].IsSelected := True;  
        Break;
      end;
    end;
  end;

  Invalidate;
end;

procedure TTemplatePngCard.UnSelectCard;
begin
  // 取消选择的牌
  ClearSelectState;
  Invalidate;
end;

end.
