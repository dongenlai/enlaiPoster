{*************************************************************************}
{                                                                         }
{  单元说明: 游戏逻辑处理                                                 }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  单元用途:                                                              }
{                                                                         }
{   提供游戏逻辑相关方法，比如排序、确定牌型、比较大小等                  }
{                                                                         }
{*************************************************************************}

unit TemplateGameLogicProc;

interface

uses
  Classes, SysUtils, TemplateGlobalST, TemplateCardGlobalST;

type
  TTemplateGameLogicProc = class(TObject)
  private
    function CompareACard(const ACard1, ACard2: TGameCard): Integer;
    procedure CopyScanAry(const ASource: TCardScanItemAry; var Dest: TCardScanItemAry);
    procedure DecSortCardScanAryByCount(var RetScanAry: TCardScanItemAry);
    procedure GetCardScanTable(const ADecSortCardAry: TGameCardAry; AExceptColor: TCardColor; var RetScanArySortByValue: TCardScanItemAry);
    procedure CalcTakesCard(var RetSplitAryAry: TSplitCardAryAry);

    function IsACardValid(const ACard: TGameCard): Boolean;
    function IsCardTypeSame(const ACardType1, ACardType2: TLordCardType): Boolean;
    function GetCardLenByCardType(const ACardType: TLordCardType): Integer;
    function GetSplitTotalBaShu(const ASplitAry: TSplitCardAryAry; AFromSplit, AToSplit: TSplitCardType): Integer;
    function CheckCanTakeB2(const ASplitAry: TSplitCardAryAry; N, ATakeCount: Integer): Boolean;
    function GetSplitTakeCardNotChaiPai(const ASplitAry: TSplitCardAryAry; ANotTakeMinValue, ANotTakeMaxValue: TCardValue; N, ATakeCount: Integer; var RetTakeCard: TGameCardAry): Boolean;
    function GetSplitTakeCardChaiPai(const ASplitAry: TSplitCardAryAry; ANotTakeMinValue, ANotTakeMaxValue: TCardValue; N, ATakeCount: Integer; var RetTakeCard: TGameCardAry): Boolean;
  public
    function GetCardAryScore(var RetDecSortCardAry: TGameCardAry): Integer;

    procedure DecSortCardAryByValue(var ACardAry: TGameCardAry);
    procedure AddCardToCardAry(const AAddDecSortCardAry: TGameCardAry; var RetDecSortCardAry: TGameCardAry);
    function DelCardFromCardAry(const ADelDecSortCard: TGameCardAry; var RetDecSortCardAry: TGameCardAry): Boolean;

    function IsCardAryValid(const ACardAry: TGameCardAry): Boolean;
    function IsDiscardInCardAry(const ADecSortDiscard, ADecSortUserCard: TGameCardAry): Boolean;
    function IsCardTypeValid(const ACardType: TLordCardType): Boolean;
    function IsNewCardTypeBigger(const ANewCardType, AOldCardType: TLordCardType): Boolean;
    function IsBombCardType(const ACardType: TLordCardType): Boolean;
    function IsRocketCardType(const ACardType: TLordCardType): Boolean;
    function SplitCard(const ADecSortCardAry: TGameCardAry; var RetSplitAryAry: TSplitCardAryAry): Integer;
    function DoUserFirstDiscard(var UserCard: TGameCardAryAry; ACurPlace, ALordPlace: Integer; var RetCardAry: TGameCardAry): Boolean;
    function DoUserFirstDiscard2(const XSelfCard: TGameCardAry; var RetCardAry: TGameCardAry): Boolean;
    function DoUserSecondDiscard(const ALastCardType: TLordCardType; var UserCard: TGameCardAryAry; ALastPlace, ACurPlace, ALordPlace, XDiscardTurn: Integer; var RetCardAry: TGameCardAry): Boolean;

    function GetSplitAryHintMsg(const SplitAryAry: TSplitCardAryAry; const RetStrList: TStringList): Integer;
    procedure CheckCardType(const ADecSortCardAry: TGameCardAry; var RetCardType: TLordCardType);
    function GetCardAryHintMsg(const XCardAry: TGameCardAry): string;

    procedure GetHintBiggerCard(const AOldCardType: TLordCardType;
      const ADecSortUserCardAry: TGameCardAry; AIsFirstHint: Boolean;
      const AFirstTypeValue: TGameCard; var RetNewCardType: TLordCardType;
      var RetNewCardAry: TGameCardAry);
  end;

implementation

uses
  TemplatePubUtils;

{ TTemplateGameLogicProc }

procedure TTemplateGameLogicProc.AddCardToCardAry(
  const AAddDecSortCardAry: TGameCardAry; var RetDecSortCardAry: TGameCardAry);

  procedure MergeCardAry;
  var
    I: Integer;
    LSourceLen, LAddLen: Integer;
    LSourceAry: TGameCardAry;
    LAddIndex, LSourceIndex: Integer;

    procedure CopyASourceCard(ARetIndex: Integer);
    begin
      RetDecSortCardAry[ARetIndex] := LSourceAry[LSourceIndex];
      Inc(LSourceIndex);
    end;

    procedure CopyAAddCard(ARetIndex: Integer);
    begin
      RetDecSortCardAry[ARetIndex] := AAddDecSortCardAry[LAddIndex];
      Inc(LAddIndex);
    end;
    
  begin
    LAddLen := Length(AAddDecSortCardAry);
    LSourceLen := Length(RetDecSortCardAry);
    
    CopyGameCardAry(RetDecSortCardAry, LSourceAry);
    SetLength(RetDecSortCardAry, LAddLen + LSourceLen);

    LAddIndex := 0;
    LSourceIndex := 0;  
    for I := Low(RetDecSortCardAry) to High(RetDecSortCardAry) do
    begin
      if LAddIndex >= LAddLen then
      begin
        CopyASourceCard(I);
      end else if LSourceIndex >= LSourceLen then
      begin
        CopyAAddCard(I)
      end else
      begin
        if CompareACard(LSourceAry[LSourceIndex], AAddDecSortCardAry[LAddIndex]) > 0  then
        begin
          CopyASourceCard(I);
        end else
        begin
          CopyAAddCard(I);
        end;
      end;
    end; 
  end;
  
begin
  if Length(AAddDecSortCardAry) > 0 then
  begin
    if Length(RetDecSortCardAry) = 0 then
    begin
      CopyGameCardAry(AAddDecSortCardAry, RetDecSortCardAry);
    end else
    begin
      MergeCardAry;    
    end;
  end;
end;

procedure TTemplateGameLogicProc.GetCardScanTable(
  const ADecSortCardAry: TGameCardAry; AExceptColor: TCardColor;
  var RetScanArySortByValue: TCardScanItemAry);
var
  I: Integer;
  LLastCard: TGameCard;
  LRetScanIndex: Integer;

  procedure RaiseRetScanAry(ACardIndex: Integer);
  begin
    Inc(LRetScanIndex);
    SetLength(RetScanArySortByValue, LRetScanIndex + 1);

    LLastCard := ADecSortCardAry[ACardIndex];
    RetScanArySortByValue[LRetScanIndex].Card := LLastCard;
    RetScanArySortByValue[LRetScanIndex].Count := 1;
    RetScanArySortByValue[LRetScanIndex].Index := ACardIndex;
  end;

begin
  // 计算牌的扫描表格 不扫描不扫描花色是AExceptColor的
  // 根据从大到小排列的牌，根据牌值生成一个按照牌大小排序的牌的数量扫描表
  if Length(ADecSortCardAry) < 1 then
  begin
    SetLength(RetScanArySortByValue, 0);
  end else
  begin
    LRetScanIndex := -1;
    RaiseRetScanAry(0);

    if AExceptColor = sccNone then
    begin
      for I := Low(ADecSortCardAry) + 1 to High(ADecSortCardAry) do
      begin
        if ADecSortCardAry[I].Value = LLastCard.Value then
        begin
          Inc(RetScanArySortByValue[LRetScanIndex].Count);
        end else
        begin
          RaiseRetScanAry(I);
        end;
      end;
    end else
    begin
      for I := Low(ADecSortCardAry) + 1 to High(ADecSortCardAry) do
      begin
        if ADecSortCardAry[I].Color <> AExceptColor then
        begin
          if ADecSortCardAry[I].Value = LLastCard.Value then
          begin
            Inc(RetScanArySortByValue[LRetScanIndex].Count);
          end else
          begin
            RaiseRetScanAry(I);
          end;
        end;
      end;
    end;
  end;
end;

function TTemplateGameLogicProc.CompareACard(const ACard1,
  ACard2: TGameCard): Integer;
begin
  // 结果: ACard1>ACard2则大于0，相等则等于0，ACard1<ACard2则小于0
  Result := Ord(ACard1.Value) - Ord(ACard2.Value);

  if Result = 0 then
    Result := Ord(ACard1.Color) - Ord(ACard2.Color);
end;

procedure TTemplateGameLogicProc.CopyScanAry(const ASource: TCardScanItemAry;
  var Dest: TCardScanItemAry);
var
  I: Integer;
begin
  SetLength(Dest, Length(ASource));
  for I := Low(Dest) to High(Dest) do
  begin
    Dest[I] := ASource[I];  
  end;
end;

function TTemplateGameLogicProc.IsNewCardTypeBigger(const ANewCardType,
  AOldCardType: TLordCardType): Boolean;
begin
  // 新的牌ANewCardType是否大于旧的AOldCardType
  if not IsCardTypeValid(ANewCardType) then
    Result := False
  else if not IsCardTypeValid(AOldCardType) then
    Result := True
  else
  begin
    if IsCardTypeSame(ANewCardType, AOldCardType) then
    begin
      // 斗地主不区分花色
      Result := Ord(ANewCardType.TypeValue.Value) - Ord(AOldCardType.TypeValue.Value) > 0;
    end else
    begin
      if IsBombCardType(ANewCardType) then
        Result := True
      else
        Result := False;
    end;
  end;
end;

function TTemplateGameLogicProc.IsRocketCardType(
  const ACardType: TLordCardType): Boolean;
begin
  // 判断是否是火箭
  Result := (ACardType.TypeNum.X = 1) and (ACardType.TypeNum.M = 4) and
    (ACardType.TypeNum.Y = 0) and (ACardType.TypeNum.N = 0) and
    (ACardType.TypeValue.Value = scvBJoker);
end;

procedure TTemplateGameLogicProc.DecSortCardAryByValue(
  var ACardAry: TGameCardAry);
var
  I, J: Integer;
  LMaxIndex: Integer;
  LTmpCard: TGameCard;
begin
  for I := Low(ACardAry) to High(ACardAry) - 1 do
  begin
    LMaxIndex := I;
    for J := I + 1 to High(ACardAry) do
    begin
      if CompareACard(ACardAry[J], ACardAry[LMaxIndex]) > 0 then
        LMaxIndex := J;
    end;
    
    if LMaxIndex <> I then
    begin
      LTmpCard := ACardAry[LMaxIndex];
      ACardAry[LMaxIndex] := ACardAry[I];
      ACardAry[I] := LTmpCard;
    end;
  end;
end;

procedure TTemplateGameLogicProc.DecSortCardScanAryByCount(
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

function TTemplateGameLogicProc.DelCardFromCardAry(
  const ADelDecSortCard: TGameCardAry; var RetDecSortCardAry: TGameCardAry): Boolean;
var
  LTmpRetUserCard: TGameCardAry;
  I: Integer;
  LDelCardLen: Integer;
  LUserCardLen: Integer;
  LDelIndex: Integer;
  LNextUserCardIndex: Integer;
  LCompareResult: Integer;
  LTmpCard: TGameCard;
  LEqualIndex: Integer;
  LTmpCardIndex: Integer;
begin
  // 从RetDecSortCardAry去掉ADelDecSortCard
  // 首先要确保ADelDecSortCard完全包含在RetDecSortCardAry中
  LDelCardLen := Length(ADelDecSortCard);
  LUserCardLen := Length(RetDecSortCardAry);

  if LDelCardLen < 1 then
  begin
    Result := True;
  end else if LUserCardLen < LDelCardLen then
  begin
    Result := False;
  end else
  begin
    Result := True;
    SetLength(LTmpRetUserCard, LUserCardLen - LDelCardLen);

    LNextUserCardIndex := 0;
    LTmpCardIndex := 0;
    for LDelIndex := 0 to LDelCardLen - 1 do
    begin
      LEqualIndex := CINVALID_INDEX;
      LTmpCard := ADelDecSortCard[LDelIndex];
      
      // 找到下一个相等的
      for I := LNextUserCardIndex to LUserCardLen - 1 do
      begin
        LCompareResult := CompareACard(LTmpCard, RetDecSortCardAry[I]);
        if LCompareResult = 0 then
        begin
          LEqualIndex := I;
          Break;
        end else if LCompareResult > 0 then
        begin
          Break;
        end else if LCompareResult < 0 then
        begin
          LTmpRetUserCard[LTmpCardIndex] := RetDecSortCardAry[I];
          Inc(LTmpCardIndex);
        end;
      end;

      if LEqualIndex <> CINVALID_INDEX then
      begin
        LNextUserCardIndex := LEqualIndex + 1;
      end else
      begin
        Result := False;
        Break;
      end;
    end;

    if Result then
    begin
      for I := LTmpCardIndex to High(LTmpRetUserCard) do
      begin
        LTmpRetUserCard[I] := RetDecSortCardAry[I + LDelCardLen];
      end;
      
      CopyGameCardAry(LTmpRetUserCard, RetDecSortCardAry);
    end;
  end;
end;

procedure TTemplateGameLogicProc.CheckCardType(const ADecSortCardAry: TGameCardAry;
  var RetCardType: TLordCardType);
var
  LScanAry: TCardScanItemAry;
  LCardLen: Integer;

  function Is1Series: Boolean;
  var
    I: Integer;
  begin
    // 是否是单顺
    Result := (Length(LScanAry) >= 5) and (LCardLen = Length(LScanAry));
    if Result then
    begin
      for I := Low(LScanAry) to High(LScanAry) - 1 do
      begin
        if (LScanAry[I].Count <> 1) or (LScanAry[I].Card.Value > scvBA) then
           Result := False
        else if Ord(LScanAry[I].Card.Value) - Ord(LScanAry[I + 1].Card.Value) <> 1 then
          Result := False;
          
        if not Result then
          Break;
      end;
    end;
  end;

  function Is2Series: Boolean;
  var
    I: Integer;
  begin
    // 是否是双顺
    Result := (Length(LScanAry) >= 3) and (LCardLen div 2 = Length(LScanAry));
    if Result then
    begin
      for I := Low(LScanAry) to High(LScanAry) - 1 do
      begin
        if (LScanAry[I].Count <> 2) or (LScanAry[I].Card.Value > scvBA) then
           Result := False
        else if Ord(LScanAry[I].Card.Value) - Ord(LScanAry[I + 1].Card.Value) <> 1 then
          Result := False;

        if not Result then
          Break;
      end;
    end;
  end;

  function Is3Series: Boolean;
  var
    I: Integer;
  begin
    // 是否是三顺，注意不包括飞机
    Result := (Length(LScanAry) >= 2) and (LCardLen div 3 = Length(LScanAry));
    if Result then
    begin
      for I := Low(LScanAry) to High(LScanAry) - 1 do
      begin
        if (LScanAry[I].Count <> 3) or (LScanAry[I].Card.Value > scvBA) then
           Result := False
        else if Ord(LScanAry[I].Card.Value) - Ord(LScanAry[I + 1].Card.Value) <> 1 then
          Result := False;
          
        if not Result then
          Break;
      end;
    end;
  end;

  function GetExactXMScanIndex(AX, AM: Byte): Integer;
  var
    I: Integer;
    LXCount: Integer;
    LLastValue: TCardValue;
    LTmpValue: TCardValue;
    LTmpCount: Integer;
  begin
    // 获得精确的X个连续长度为M的位置
    LXCount := 0;
    Result := CINVALID_INDEX;
    LLastValue := scvNone;
    for I := High(LScanAry) downto Low(LScanAry) do
    begin
      LTmpValue := LScanAry[I].Card.Value;
      LTmpCount := LScanAry[I].Count;

      if (LTmpCount = AM) then
      begin
        if LLastValue = scvNone then
        begin
          LXCount := 1;
        end else
        begin
          if Ord(LTmpValue) - Ord(LLastValue) = 1 then
            Inc(LXCount)
          else
            LXCount := 1;
        end;

        // 长度不够，没有必要扫描  这个判断不能放在外层，因为 LScanAry是按照个数排序的
        if (LXCount <= 1) and (Ord(scvBA) - Ord(LTmpValue) + 1 < AX) then
          Break;
      end else
      begin
        LXCount := 0;
      end;

      // 找到最小的类型
      if LXCount >= AX then
      begin
        Result := I;
        Break;
      end;

      LLastValue := LScanAry[I].Card.Value;
    end;
  end;

  function Is3SeriesTake1: Boolean;
  var
    I: Integer;
    LSeriesCount: Integer;
    LX3Index: Integer;
  begin
    // 是否是三顺带单牌的飞机
    Result := (LCardLen >= 8) and (LCardLen mod 4 = 0) and (Length(LScanAry) >= 3);

    // 不允许带炸弹
    if Result then
    begin
      for I := Low(LScanAry) to High(LScanAry) do
      begin
        if LScanAry[I].Count > 3 then
        begin
           Result := False;
           Break;
        end;
      end;
    end;

    if Result then
    begin
      LSeriesCount := LCardLen div 4;
      LX3Index := GetExactXMScanIndex(LSeriesCount, 3);
      Result := LX3Index <> CINVALID_INDEX;
    end;
  end;

  function Is3SeriesTake2: Boolean;
  var
    I: Integer;
    LSeriesCount: Integer;
  begin
    // 是否是三顺带对牌的飞机
    Result := (LCardLen >= 10) and (LCardLen mod 5 = 0) and (Length(LScanAry) >= 3);
    if Result then
    begin
      LSeriesCount := LCardLen div 5;

      // 判断3顺
      for I := Low(LScanAry) to LSeriesCount - 2 do
      begin
        if (LScanAry[I].Count <> 3) or (LScanAry[I].Card.Value > scvBA) then
           Result := False
        else if Ord(LScanAry[I].Card.Value) - Ord(LScanAry[I + 1].Card.Value) <> 1 then
          Result := False;
          
        if not Result then
          Break;
      end;

      if Result then
      begin
        // 判断对子
        for I := LSeriesCount to High(LScanAry) do
        begin
          if LScanAry[I].Count <> 2 then
          begin
            Result := False;
            Break;
          end;
        end;
      end;
    end;
  end;

  procedure CheckCardType01;
  begin
    // 只能是单张
    RetCardType.TypeNum.X := 1;
    RetCardType.TypeNum.M := 1;
  end;

  procedure CheckCardType02;
  begin
    // 可能是一对、火箭
    if LScanAry[0].Count = 2 then
    begin
      RetCardType.TypeNum.X := 1;
      RetCardType.TypeNum.M := 2;
    end else
    begin
      if (LScanAry[0].Card.Value = scvBJoker) and (LScanAry[1].Card.Value = scvSJoker) then
      begin
        RetCardType.TypeNum.X := 1;
        RetCardType.TypeNum.M := 4;
      end;
    end;
  end;

  procedure CheckCardType03;
  begin
    // 只可能是3张
    if LScanAry[0].Count = 3 then
    begin
      RetCardType.TypeNum.X := 1;
      RetCardType.TypeNum.M := 3;
    end;
  end;

  procedure CheckCardType04;
  var
    LScan0Count: Integer;
  begin
    // 可以是3带1，4张
    LScan0Count := LScanAry[0].Count;
    if LScan0Count = 3 then
    begin
      RetCardType.TypeNum.X := 1;
      RetCardType.TypeNum.M := 3;
      RetCardType.TypeNum.Y := 1;
      RetCardType.TypeNum.N := 1;
    end else if LScan0Count = 4 then
    begin
      RetCardType.TypeNum.X := 1;
      RetCardType.TypeNum.M := 4;
    end;
  end;

  procedure CheckCardType05;
  var
    LScanLen: Integer;
  begin
    // 可以是3带一对、单顺
    LScanLen := Length(LScanAry); 
    if LScanLen = 2 then
    begin
      if (LScanAry[0].Count = 3) and (LScanAry[1].Count = 2) then
      begin
        RetCardType.TypeNum.X := 1;
        RetCardType.TypeNum.M := 3;
        RetCardType.TypeNum.Y := 1;
        RetCardType.TypeNum.N := 2;
      end;
    end else if LScanLen = 5 then
    begin
      if Is1Series then
      begin
        RetCardType.TypeNum.X := 5;
        RetCardType.TypeNum.M := 1;
      end;
    end;
  end;

  procedure CheckCardType06;
  var
    LScan0Count: Integer;
  begin
    // 可以是四带二单、三顺、双顺、单顺
    LScan0Count := LScanAry[0].Count;
    case LScan0Count of
      4:
      begin
        RetCardType.TypeNum.X := 1;
        RetCardType.TypeNum.M := 4;
        RetCardType.TypeNum.Y := 2;
        RetCardType.TypeNum.N := 1;  
      end;
      3:
      begin
        if Is3Series then
        begin
          RetCardType.TypeNum.X := 2;
          RetCardType.TypeNum.M := 3;
        end;
      end;
      2:
      begin
        if Is2Series then
        begin
          RetCardType.TypeNum.X := 3;
          RetCardType.TypeNum.M := 2;
        end;
      end;
      1:
      begin
        if Is1Series then
        begin
          RetCardType.TypeNum.X := 6;
          RetCardType.TypeNum.M := 1;
        end;
      end;  
    end;
  end;

  procedure CheckCardType07;
  begin
    // 只可能是单顺
    if Length(LScanAry) = 7 then
    begin
      if Is1Series then
      begin
        RetCardType.TypeNum.X := 7;
        RetCardType.TypeNum.M := 1;
      end;
    end;
  end;

  procedure CheckCardType08;
  var
    LScan0Count: Integer;
  begin
    // 可能是四带二对、三顺带二单、双顺、单顺
    LScan0Count := LScanAry[0].Count;
    case LScan0Count of
      4:
      begin
        if (Length(LScanAry) = 3) and (LScanAry[1].Count = 2) then
        begin
          RetCardType.TypeNum.X := 1;
          RetCardType.TypeNum.M := 4;
          RetCardType.TypeNum.Y := 2;
          RetCardType.TypeNum.N := 2;
        end;
      end;
      3:
      begin
        if Is3SeriesTake1 then
        begin
          RetCardType.TypeNum.X := 2;
          RetCardType.TypeNum.M := 3;
          RetCardType.TypeNum.Y := 2;
          RetCardType.TypeNum.N := 1;
        end;
      end;
      2:
      begin
        if Is2Series then
        begin
          RetCardType.TypeNum.X := 4;
          RetCardType.TypeNum.M := 2;
        end;
      end;
      1:
      begin
        if Is1Series then
        begin
          RetCardType.TypeNum.X := 8;
          RetCardType.TypeNum.M := 1;
        end;
      end;  
    end;
  end;

  procedure CheckCardType09;
  var
    LScan0Count: Integer;
  begin
    // 可能是三顺、单顺
    LScan0Count := LScanAry[0].Count;
    if LScan0Count = 3 then
    begin
      if Is3Series then
      begin
        RetCardType.TypeNum.X := 3;
        RetCardType.TypeNum.M := 3;
      end;
    end else if LScan0Count = 1 then
    begin
      if Is1Series then
      begin
        RetCardType.TypeNum.X := 9;
        RetCardType.TypeNum.M := 1;
      end;
    end;
  end;

  procedure CheckCardType10;
  var
    LScan0Count: Integer;
  begin
    // 可能是三顺带二对、双顺、单顺
    LScan0Count := LScanAry[0].Count;
    case LScan0Count of
      3:
      begin
        if Is3SeriesTake2 then
        begin
          RetCardType.TypeNum.X := 2;
          RetCardType.TypeNum.M := 3;
          RetCardType.TypeNum.Y := 2;
          RetCardType.TypeNum.N := 2;
        end;
      end;
      2:
      begin
        if Is2Series then
        begin
          RetCardType.TypeNum.X := 5;
          RetCardType.TypeNum.M := 2;
        end;
      end;
      1:
      begin
        if Is1Series then
        begin
          RetCardType.TypeNum.X := 10;
          RetCardType.TypeNum.M := 1;
        end;
      end;
    end;
  end;

  procedure CheckCardType11;
  begin
    // 只可能是单顺
    if LScanAry[0].Count = 1 then
    begin
      if Is1Series then
      begin
        RetCardType.TypeNum.X := 11;
        RetCardType.TypeNum.M := 1;
      end;
    end;
  end;

  procedure CheckCardType12;
  var
    LScan0Count: Integer;
  begin
    // 可能是三顺带三、三顺、双顺、单顺
    LScan0Count := LScanAry[0].Count;
    case LScan0Count of
      3:
      begin
        if Is3Series then
        begin
          RetCardType.TypeNum.X := 4;
          RetCardType.TypeNum.M := 3;
        end else if Is3SeriesTake1 then
        begin
          RetCardType.TypeNum.X := 3;
          RetCardType.TypeNum.M := 3;
          RetCardType.TypeNum.Y := 3;
          RetCardType.TypeNum.N := 1;
        end;
      end;
      2:
      begin
        if Is2Series then
        begin
          RetCardType.TypeNum.X := 6;
          RetCardType.TypeNum.M := 2;
        end;
      end;
      1:
      begin
        if Is1Series then
        begin
          RetCardType.TypeNum.X := 12;
          RetCardType.TypeNum.M := 1;
        end;
      end;  
    end;
  end;

  procedure CheckCardType14;
  begin
    // 只可能是双顺
    if LScanAry[0].Count = 2 then
    begin
      if Is2Series then
      begin
        RetCardType.TypeNum.X := 7;
        RetCardType.TypeNum.M := 2;
      end;
    end;
  end;

  procedure CheckCardType15;
  begin
    // 可能是三顺、三顺带三对
    if LScanAry[0].Count = 3 then
    begin
      if Is3Series then
      begin
        RetCardType.TypeNum.X := 5;
        RetCardType.TypeNum.M := 3;
      end else if Is3SeriesTake2 then
      begin
        RetCardType.TypeNum.X := 3;
        RetCardType.TypeNum.M := 3;
        RetCardType.TypeNum.Y := 3;
        RetCardType.TypeNum.N := 2;
      end;
    end;
  end;

  procedure CheckCardType16;
  var
    LScan0Count: Integer;
  begin
    // 可能是三顺带四单、双顺
    LScan0Count := LScanAry[0].Count;

    if LScan0Count = 3 then
    begin
      if Is3SeriesTake1 then
      begin
        RetCardType.TypeNum.X := 4;
        RetCardType.TypeNum.M := 3;
        RetCardType.TypeNum.Y := 4;
        RetCardType.TypeNum.N := 1;
      end;
    end else if LScan0Count = 2 then
    begin
      if Is2Series then
      begin
        RetCardType.TypeNum.X := 8;
        RetCardType.TypeNum.M := 2;
      end;
    end;
  end;

  procedure CheckCardType18;
  var
    LScan0Count: Integer;
  begin
    // 可能是三顺、双顺
    LScan0Count := LScanAry[0].Count;
    if LScan0Count = 3 then
    begin
      if Is3Series then
      begin
        RetCardType.TypeNum.X := 6;
        RetCardType.TypeNum.M := 3;
      end;
    end else if LScan0Count = 2 then
    begin
      if Is2Series then
      begin
        RetCardType.TypeNum.X := 9;
        RetCardType.TypeNum.M := 2;
      end;
    end;
  end;

  procedure CheckCardType20;
  var
    LScan0Count: Integer;
  begin
    // 可能是三顺带四对、三顺带五单、双顺
    LScan0Count := LScanAry[0].Count;
    if LScan0Count = 3 then
    begin
      if Is3SeriesTake2 then
      begin
        RetCardType.TypeNum.X := 4;
        RetCardType.TypeNum.M := 3;
        RetCardType.TypeNum.Y := 4;
        RetCardType.TypeNum.N := 2;
      end else if Is3SeriesTake1 then
      begin
        RetCardType.TypeNum.X := 5;
        RetCardType.TypeNum.M := 3;
        RetCardType.TypeNum.Y := 5;
        RetCardType.TypeNum.N := 1;
      end;
    end else if LScan0Count = 2 then
    begin
      if Is2Series then
      begin
        RetCardType.TypeNum.X := 10;
        RetCardType.TypeNum.M := 2;
      end;
    end;
  end;

begin
  // 确定牌型
  InitLordCardType(RetCardType);
  
  LCardLen := Length(ADecSortCardAry);
  GetCardScanTable(ADecSortCardAry, sccNone, LScanAry);
  DecSortCardScanAryByCount(LScanAry);
  
  case LCardLen of
    1: CheckCardType01;
    2: CheckCardType02;
    3: CheckCardType03;
    4: CheckCardType04;
    5: CheckCardType05;
    6: CheckCardType06;
    7: CheckCardType07;
    8: CheckCardType08;
    9: CheckCardType09;
    10: CheckCardType10;
    11: CheckCardType11;
    12: CheckCardType12;
    14: CheckCardType14;
    15: CheckCardType15;
    16: CheckCardType16;
    18: CheckCardType18;
    20: CheckCardType20;
  end;

  // 如果是正确牌型，则得到牌值
  if RetCardType.TypeNum.X > 0 then
    RetCardType.TypeValue := LScanAry[0].Card;
end;

procedure TTemplateGameLogicProc.GetHintBiggerCard(
  const AOldCardType: TLordCardType; const ADecSortUserCardAry: TGameCardAry;
  AIsFirstHint: Boolean; const AFirstTypeValue: TGameCard;
  var RetNewCardType: TLordCardType; var RetNewCardAry: TGameCardAry);
type
  // 带牌的下标和数量， 是LScanArySortByCount的下标
  TTakeCardItem = record
    ScanIndex: Integer;
    CardCount: Integer;
  end;
  TTakeCardItemAry = array of TTakeCardItem;

var
  LScanArySortByValue: TCardScanItemAry;
  LScanArySortByCount: TCardScanItemAry;    // 用于单张、对子、3张、3带1、3带2 4带2 和 带单牌 带对子
  LCardLen: Integer;
  LOldCardLen: Integer;

  procedure UpdateCardToRetNewCard(AUserCardFromIndex, ACardCount: Integer);
  var
    I: Integer;
  begin
    // 设置返回的牌列表中牌，牌下标从AFromIndex，个数为ACardCount
    SetLength(RetNewCardAry, ACardCount);
    if ACardCount > 0 then
    begin
      for I := 0 to ACardCount - 1 do
      begin
        RetNewCardAry[I] := ADecSortUserCardAry[AUserCardFromIndex + I];
      end;
    end;
  end;

  procedure AddCardToRetNewCardForXMYN(ANewCardIndex, AUserCardFromIndex, AnAddCount: Integer);
  var
    I: Integer;
    LNewIndex: Integer;
  begin
    // 向返回的牌列表中添加牌，添加的牌下标从AFromIndex，个数为AnAddCount
    // ANewCardIndex表示RetNewCardAry的开始下标
    if AnAddCount > 0 then
    begin
      if Length(RetNewCardAry) <> LOldCardLen then
        SetLength(RetNewCardAry, LOldCardLen);
        
      LNewIndex := ANewCardIndex;
      for I := 0 to AnAddCount - 1 do
      begin
        RetNewCardAry[LNewIndex] := ADecSortUserCardAry[AUserCardFromIndex + I];
        Inc(LNewIndex);
      end;
    end;
  end;

  procedure AddYNToNewCard(const ATakeCardAry: TTakeCardItemAry);
  var
    I: Integer;
    LNewIndex: Integer;
    LTmpCount: Byte;
    LCardIndex: Integer;
  begin
    // 把带的牌加入新牌
    LNewIndex := AOldCardType.TypeNum.X * AOldCardType.TypeNum.M;
    for I := Low(ATakeCardAry) to High(ATakeCardAry) do
    begin
      LTmpCount := ATakeCardAry[I].CardCount;
      LCardIndex := LScanArySortByCount[ATakeCardAry[I].ScanIndex].Index;
      AddCardToRetNewCardForXMYN(LNewIndex, LCardIndex, LTmpCount);

      Inc(LNewIndex, LTmpCount);
    end;
  end;

  procedure AddXMToNewCard(AXMScanIndex: Integer; AIsSortByCount: Boolean);
  var
    I: Integer;
    LNewIndex: Integer;
    LMCount: Byte;
  begin
    LMCount := AOldCardType.TypeNum.M;
    LNewIndex := 0;

    if AIsSortByCount then
    begin
      for I := 0 to AOldCardType.TypeNum.X - 1 do
      begin
        AddCardToRetNewCardForXMYN(LNewIndex, LScanArySortByCount[AXMScanIndex].Index, LMCount);

        Inc(LNewIndex, LMCount);
        Inc(AXMScanIndex);
      end;
    end else
    begin
      for I := 0 to AOldCardType.TypeNum.X - 1 do
      begin
        AddCardToRetNewCardForXMYN(LNewIndex, LScanArySortByValue[AXMScanIndex].Index, LMCount);

        Inc(LNewIndex, LMCount);
        Inc(AXMScanIndex);
      end;
    end;
  end;

  function GetCanTakeScanIndexAry(AMaxXMValue: TCardValue; var RetCountIndexAry: TTakeCardItemAry): Boolean;

    procedure RaiseIndexAry(AScanIndex, ACardCount: Integer);
    var
      LItemIndex: Integer;
    begin
      LItemIndex := Length(RetCountIndexAry);
      SetLength(RetCountIndexAry, LItemIndex + 1);

      RetCountIndexAry[LItemIndex].ScanIndex := AScanIndex;
      RetCountIndexAry[LItemIndex].CardCount := ACardCount;
    end;
    
  var
    I: Integer;
    LMaxTakeCount: Integer;
    LTotalCount: Integer;
    LMinXMValue: TCardValue;
    LTmpValue: TCardValue;
    LTmpCount: Integer;
    LCountDiff: Integer;
  begin
    Result := False;
    SetLength(RetCountIndexAry, 0);

    // 判断是否需要带牌
    LMaxTakeCount := AOldCardType.TypeNum.Y * AOldCardType.TypeNum.N;
    if LMaxTakeCount < 1 then
    begin
      Result := True;
    end else if Length(LScanArySortByCount) > AOldCardType.TypeNum.Y then
    begin
      LMinXMValue := TCardValue(Ord(AMaxXMValue) - AOldCardType.TypeNum.X + 1);
      LTotalCount := 0;

      for I := High(LScanArySortByCount) downto Low(LScanArySortByCount) do
      begin
        LTmpValue := LScanArySortByCount[I].Card.Value;
        LTmpCount := LScanArySortByCount[I].Count;

        // 只能带与X个M中不同的牌          
        if ((LTmpValue < LMinXMValue) or (LTmpValue > AMaxXMValue)) then
        begin
          LCountDiff := LMaxTakeCount - LTotalCount;

          // 不能带炸弹
          if LCountDiff >= 4 then
            LCountDiff := 3;
            
          if AOldCardType.TypeNum.N = 1 then
          begin
            if LTmpCount <= LCountDiff then
            begin
              RaiseIndexAry(I, LTmpCount);
              Inc(LTotalCount, LTmpCount);
            end else
            begin
              RaiseIndexAry(I, LCountDiff);
              Inc(LTotalCount, LCountDiff);
            end;
          end else if AOldCardType.TypeNum.N = 2 then
          begin
            // 带对子
            if LTmpCount >= 2 then
            begin
              RaiseIndexAry(I, 2);
              Inc(LTotalCount, 2);
            end;
          end;
        end;

        if LMaxTakeCount = LTotalCount then
        begin
          Result := True;
          Break;
        end;
      end;
    end;
  end;

  function GetOldTypeScanIndex: Integer;
  var
    I: Integer;
    LOldValue: TCardValue;
  begin
    Result := CINVALID_INDEX;
    LOldValue := AOldCardType.TypeValue.Value;
    
    for I := Low(LScanArySortByCount) to High(LScanArySortByCount) do
    begin
      if LScanArySortByCount[I].Card.Value = LOldValue then
      begin
        Result := I;
        Break;
      end;
    end;
  end;

  function Search1_2_3_4BiggerCard(ACardCount: Byte): Boolean;

    procedure SearchCardCount1_2_3_4(AFromIndex: Integer;
      var RetScanIndex: Integer);
    var
      I: Integer;
    begin
      // 查找1，2，3, 4张的大牌，牌数量是ACardCount， 开始位置AFromIndex，倒序搜索
      // 返回LScanArySortByCount的Index
      RetScanIndex := CINVALID_INDEX;

      for I := AFromIndex downto Low(LScanArySortByCount) do
      begin
        if (LScanArySortByCount[I].Card.Value > AFirstTypeValue.Value) and
          (LScanArySortByCount[I].Count >= ACardCount) then
        begin
          RetScanIndex := I;
          Break;
        end;
      end;
    end;

    function ProcessTakeCard(A3_4ScanIndex: Integer): Boolean;
    var
      LTakeCardAry: TTakeCardItemAry;
    begin
      Result := False;

      if GetCanTakeScanIndexAry(LScanArySortByCount[A3_4ScanIndex].Card.Value, LTakeCardAry) then
      begin
        RetNewCardType.TypeValue := LScanArySortByCount[A3_4ScanIndex].Card;
        AddXMToNewCard(A3_4ScanIndex, True);
        AddYNToNewCard(LTakeCardAry);

        Result := True;
      end;
    end;

  var
    LOldScanIndex: Integer;
    LScanIndex: Integer;
  begin
    Result := False;

    if AIsFirstHint then
    begin
      SearchCardCount1_2_3_4(High(LScanArySortByCount), LScanIndex);
    end else
    begin
      LOldScanIndex := GetOldTypeScanIndex;
      if LOldScanIndex <> CINVALID_INDEX then
      begin
        SearchCardCount1_2_3_4(LOldScanIndex - 1, LScanIndex);  
      end;
    end;

    if LScanIndex <> CINVALID_INDEX then
    begin
      // 判断是否有带牌
      if AOldCardType.TypeNum.Y = 0 then
      begin
        RetNewCardType.TypeValue := LScanArySortByCount[LScanIndex].Card;
        UpdateCardToRetNewCard(LScanArySortByCount[LScanIndex].Index, ACardCount);

        Result := True;
      end else
      begin
        Result := ProcessTakeCard(LScanIndex);
      end;
    end;
  end;

  function SearchXMYNBiggerCard: Boolean;

    function GetXMScanIndex: Integer;
    var
      I: Integer;
      LXCount: Integer;
      LOldMinValue: TCardValue;
      LLastValue: TCardValue;
      LTmpValue: TCardValue;
      LTmpCount: Integer;
    begin
      LOldMinValue := TCardValue(Ord(AOldCardType.TypeValue.Value) - AOldCardType.TypeNum.X + 1);

      LXCount := 0;
      Result := CINVALID_INDEX;
      LLastValue := scvNone;
      for I := High(LScanArySortByValue) downto Low(LScanArySortByValue) do
      begin
        LTmpValue := LScanArySortByValue[I].Card.Value;
        LTmpCount := LScanArySortByValue[I].Count;

        // 找比LOldMinValue大的牌
        if (LTmpValue > LOldMinValue) then
        begin
          if (LTmpCount >= AOldCardType.TypeNum.M) then
          begin
            if LLastValue = scvNone then
            begin
              LXCount := 1;
            end else
            begin
              if Ord(LTmpValue) - Ord(LLastValue) = 1 then
                Inc(LXCount)
              else
                LXCount := 1;
            end;
          end else
          begin
            LXCount := 0;
          end;
        end else
        begin
          LXCount := 0;
        end;

        // 长度不够，没有必要扫描
        if (LXCount <= 1) and (Ord(scvBA) - Ord(LTmpValue) + 1 < AOldCardType.TypeNum.X) then
          Break;

        // 找到最小的类型
        if LXCount >= AOldCardType.TypeNum.X then
        begin
          Result := I;
          Break;
        end;

        LLastValue := LScanArySortByValue[I].Card.Value;
      end;
    end;

  var
    LXMScanIndex: Integer;
    LTakeCardAry: TTakeCardItemAry;
  begin
    // 查找XMYN类型的牌, 不包括单牌、对子、3张、3带1、3带对、炸弹、4带2
    // X个M中不包括2和大小王
    Result := False;

    // 单个的就不处理了
    if AOldCardType.TypeNum.X <= 1 then
      Exit;
    // A是这种类型中最大的
    if AOldCardType.TypeValue.Value >= scvBA then
      Exit;

    LXMScanIndex := GetXMScanIndex;

    // 如果找到了连续的X个M
    if LXMScanIndex <> CINVALID_INDEX then
    begin
      if GetCanTakeScanIndexAry(LScanArySortByValue[LXMScanIndex].Card.Value, LTakeCardAry) then
      begin
        RetNewCardType.TypeValue := LScanArySortByValue[LXMScanIndex].Card;
        AddXMToNewCard(LXMScanIndex, False);
        AddYNToNewCard(LTakeCardAry);

        Result := True;
      end;
    end;
  end;

  function SearchSameTypeBiggerCard: Boolean;
  begin
    // 搜索牌型相同的大牌，不包括炸弹类型的牌
    Result := False;

    // 牌型如果相同，牌数量要相同
    if LCardLen < LOldCardLen then
      Exit;

    if (AOldCardType.TypeNum.X = 1) and (AOldCardType.TypeNum.M <= 4) then
    begin
      // 要区分是否是第一次提示
      Result := Search1_2_3_4BiggerCard(AOldCardType.TypeNum.M);
    end else
    begin
      Result := SearchXMYNBiggerCard;
    end;

    if Result then
    begin
      RetNewCardType.TypeNum := AOldCardType.TypeNum;
    end;
  end;

  function SearchBombTypeBiggerCard(AOldValue: TCardValue): Boolean;
  var
    I: Integer;
    LScanCount: Integer;
  begin
    // 查找最小的炸弹类型的牌
    Result := False;

    // 先找4张的炸弹  如果没有，再找火箭
    if LCardLen >= 4 then
    begin
      for I := High(LScanArySortByValue) downto Low(LScanArySortByValue) do
      begin
        LScanCount := LScanArySortByValue[I].Count;
        if (LScanCount = 4) and (LScanArySortByValue[I].Card.Value > AOldValue) then
        begin
          RetNewCardType.TypeValue := LScanArySortByValue[I].Card;
          UpdateCardToRetNewCard(LScanArySortByValue[I].Index, 4);

          Result := True;
          Break;
        end;
      end;
    end;

    // 找火箭
    if (not Result) and (Length(LScanArySortByValue) >= 2) then
    begin
      if (LScanArySortByValue[0].Card.Value = scvBJoker) and
        (LScanArySortByValue[1].Card.Value = scvSJoker) then
      begin
        RetNewCardType.TypeValue := LScanArySortByValue[0].Card;
        UpdateCardToRetNewCard(0, 2);

        Result := True;
      end;
    end;

    if Result then
    begin
      RetNewCardType.TypeNum.X := 1;
      RetNewCardType.TypeNum.M := 4;
    end;
  end;

begin
  // 相当于托管出牌功能
  // 根据AOldCardType来选出比它大的牌，返回大牌的牌型和具体的牌
  // 是否是第一次提示是有用的，用于确定怎么拆牌 AFistCardValue只用于提示单张、对子、3张、3带1、3带2，4带2
  // 如果是第一次调用，从最小的开始找，只要大就可以
  // 如果不是第一次调用，对于单张、对子、3张、3带1、3带2，4带2需要找到上次提示的位置，然后往大牌找
  InitLordCardType(RetNewCardType);
  SetLength(RetNewCardAry, 0);
  LCardLen := Length(ADecSortUserCardAry);
  LOldCardLen := GetCardLenByCardType(AOldCardType);

  // 自己没有牌，或者先前是火箭，直接不出
  if (LCardLen < 1) or IsRocketCardType(AOldCardType) then
    Exit;
    
  // 首次出牌，从最小的出
  if not IsCardTypeValid(AOldCardType) then
  begin
    RetNewCardType.TypeNum.X := 1;
    RetNewCardType.TypeNum.M := 1;
    SetLength(RetNewCardAry, 1);
    RetNewCardAry[0] := ADecSortUserCardAry[High(ADecSortUserCardAry)];
    RetNewCardType.TypeValue := RetNewCardAry[0];
  end else
  begin
    GetCardScanTable(ADecSortUserCardAry, sccNone, LScanArySortByValue);
    CopyScanAry(LScanArySortByValue, LScanArySortByCount);
    DecSortCardScanAryByCount(LScanArySortByCount);

    if IsBombCardType(AOldCardType) then
    begin
      SearchBombTypeBiggerCard(AOldCardType.TypeValue.Value);
    end else
    begin
      if not SearchSameTypeBiggerCard then
      begin
        SearchBombTypeBiggerCard(scvNone);
      end;
    end;

    // 返回后按照大小排序
    DecSortCardAryByValue(RetNewCardAry);
  end;
end;

function TTemplateGameLogicProc.GetCardAryHintMsg(
  const XCardAry: TGameCardAry): string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(XCardAry) to High(XCardAry) do
  begin
    Result := Result + Format('%s%s,', [
      CCARD_COLOR_MSG[XCardAry[I].Color], CCARD_VALUE_MSG[XCardAry[I].Value]]);
  end;
end;

function TTemplateGameLogicProc.GetCardAryScore(
  var RetDecSortCardAry: TGameCardAry): Integer;
const
  CScoreRocket: Integer = 40;
  CScore3Straight: array[2..4] of Integer = (90, 160, 250);
  CScoreBomb: array[1..4] of Integer = (60, 100, 200, 250);
  CScore3: array[1..5] of Integer = (40, 80, 120, 160, 250);
  CScore2Straight: array[3..8] of Integer = (60, 100, 120, 150, 200, 250);
  CScore1Straight: array[5..12] of Integer = (50, 60, 80, 100, 110, 120, 150, 180);
var
  LScanAry: TCardScanItemAry;
  LHasRocket: Boolean;
  L3StraightCount: array[2..4] of Integer;
  LBombCount: Integer;
  L3Count: array[1..1] of Integer;
  L2StraightCount: array[3..8] of Integer;
  L1StraightCount: array[5..12] of Integer;

  function CheckHasRocket: Boolean;
  begin
    Result := False;
    if Length(RetDecSortCardAry) >= 2 then
    begin
      if (RetDecSortCardAry[0].Color = sccJoker) and (RetDecSortCardAry[1].Color = sccJoker) and
        (RetDecSortCardAry[0].Value <> RetDecSortCardAry[1].Value) then
      begin
        Result := True;      
      end;
    end;
  end;

  // 统计N顺子个数，2不算顺子
  procedure CalcNStraightCount(const AMinN, AMaxN, AMinLen, AMaxLen: Integer; var RetAry: array of Integer);
  var
    I: Integer;
    LStraightCount: Integer;
    LLastItem, LCurItem: TCardScanItem;

    procedure CheckIncCount;
    var
      LRealIndex: Integer;
    begin
      // 注意：Low(RetAry) 永远是0，即使外面传入的是 array[2..4] of Integer
      if (LStraightCount >= AMinLen) and (LStraightCount <= AMaxLen) then
      begin
        LRealIndex := LStraightCount - AMinLen;
        if (LRealIndex >= Low(RetAry)) and (LRealIndex <= High(RetAry)) then
          Inc(RetAry[LRealIndex]);
      end;

      LStraightCount := 0;
    end;

    procedure CheckIsStraight;
    begin
      if LStraightCount = 0 then
      begin
        LStraightCount := 1;
      end else
      begin
        if Ord(LLastItem.Card.Value) - Ord(LCurItem.Card.Value) = 1 then
        begin
          Inc(LStraightCount);
        end else
        begin
          CheckIncCount;
          LStraightCount := 1;
        end;
      end;
    end;
    
  begin
    for I := Low(RetAry) to High(RetAry) do
      RetAry[I] := 0;

    LStraightCount := 0;
    FillChar(LLastItem, SizeOf(LLastItem), 0);
    for I := Low(LScanAry) to High(LScanAry) do
    begin
      LCurItem := LScanAry[I];

      if (LCurItem.Card.Value <= scvBA) then
      begin
        if (LCurItem.Count >= AMinN) and (LCurItem.Count <= AMaxN) then
        begin
          CheckIsStraight;
        end else
          CheckIncCount;
      end else
      begin
        // 当不是顺子时，2要计算在内
        if (LCurItem.Count >= AMinN) and (LCurItem.Count <= AMaxN)
          and (AMinLen = 1) and (AMaxLen = 1)  then
        begin
          LStraightCount := 1;
          CheckIncCount;
        end else
          LStraightCount := 0;
      end;

      LLastItem := LCurItem;
    end;

    CheckIncCount;
  end;

  function CalcBombCount: Integer;
  var
    I: Integer;
  begin
    Result := 0;

    for I := Low(LScanAry) to High(LScanAry) do
    begin
      if LScanAry[I].Count = 4 then
        Inc(Result);
    end;
  end;

var
  LIndex: Integer;
begin
  Result := 0;

  DecSortCardAryByValue(RetDecSortCardAry);
  LHasRocket := CheckHasRocket;
  GetCardScanTable(RetDecSortCardAry, sccJoker, LScanAry);
  CalcNStraightCount(3, 3, Low(L3StraightCount), High(L3StraightCount), L3StraightCount);
  LBombCount := CalcBombCount;
  CalcNStraightCount(3, 3, Low(L3Count), High(L3Count), L3Count);
  CalcNStraightCount(2, 2, Low(L2StraightCount), High(L2StraightCount), L2StraightCount);
  CalcNStraightCount(1, 1, Low(L1StraightCount), High(L1StraightCount), L1StraightCount);

  // 火箭
  if LHasRocket then
    Inc(Result, CScoreRocket);

  // 3顺子
  for LIndex := Low(CScore3Straight) to High(CScore3Straight) do
  begin
    if L3StraightCount[LIndex] > 0 then
      Inc(Result, CScore3Straight[LIndex] * L3StraightCount[LIndex]);
  end;

  // 炸弹个数
  if (LBombCount >= Low(CScoreBomb)) and (LBombCount <= High(CScoreBomb)) then
    Inc(Result, CScoreBomb[LBombCount]);

  // 3张个数（不包括3顺）
  if (L3Count[1] >= Low(CScore3)) and (L3Count[1] <= High(CScore3)) then
    Inc(Result, CScore3[L3Count[1]]);

  // 连对个数
  for LIndex := Low(CScore2Straight) to High(CScore2Straight) do
  begin
    if L2StraightCount[LIndex] > 0 then
      Inc(Result, CScore2Straight[LIndex] * L2StraightCount[LIndex]);
  end;

  // 单顺个数
  for LIndex := Low(CScore1Straight) to High(CScore1Straight) do
  begin
    if L1StraightCount[LIndex] > 0 then
      Inc(Result, CScore1Straight[LIndex] * L1StraightCount[LIndex]);
  end;
end;

function TTemplateGameLogicProc.GetCardLenByCardType(
  const ACardType: TLordCardType): Integer;
begin
  // 根据牌型获得数量
  if IsRocketCardType(ACardType) then
    Result := 2
  else
  begin
    Result := (ACardType.TypeNum.X * ACardType.TypeNum.M) +
      (ACardType.TypeNum.Y * ACardType.TypeNum.N);
  end;
end;

function TTemplateGameLogicProc.IsACardValid(const ACard: TGameCard): Boolean;
begin
  if ACard.Color <> sccJoker then
  begin
    Result := (ACard.Color >= sccDiamond) and (ACard.Color <= sccSpade) and
      (ACard.Value >= scv3) and (ACard.Value <= scvB2);
  end else
  begin
    Result := (ACard.Value = scvSJoker) or (ACard.Value = scvBJoker);
  end;

end;

function TTemplateGameLogicProc.IsBombCardType(
  const ACardType: TLordCardType): Boolean;
begin
  // 判断是否是炸弹（包括火箭）
  Result := (ACardType.TypeNum.X = 1) and (ACardType.TypeNum.M = 4) and
    (ACardType.TypeNum.Y = 0) and (ACardType.TypeNum.N = 0);
end;

function TTemplateGameLogicProc.IsCardAryValid(
  const ACardAry: TGameCardAry): Boolean;
var
  I: Integer;
begin
  // 牌是否合法
  Result := True;
  for I := Low(ACardAry) to High(ACardAry) do
  begin
    if not IsACardValid(ACardAry[I]) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TTemplateGameLogicProc.IsCardTypeSame(const ACardType1,
  ACardType2: TLordCardType): Boolean;
begin
  Result :=
    (ACardType1.TypeNum.X = ACardType2.TypeNum.X) and
    (ACardType1.TypeNum.M = ACardType2.TypeNum.M) and
    (ACardType1.TypeNum.Y = ACardType2.TypeNum.Y) and
    (ACardType1.TypeNum.N = ACardType2.TypeNum.N);
end;

function TTemplateGameLogicProc.IsCardTypeValid(
  const ACardType: TLordCardType): Boolean;
begin
  // 是否是正确的牌型
  Result := (ACardType.TypeNum.X > 0) and (ACardType.TypeNum.M > 0) and
    IsACardValid(ACardType.TypeValue);
end;

function TTemplateGameLogicProc.IsDiscardInCardAry(const ADecSortDiscard,
  ADecSortUserCard: TGameCardAry): Boolean;
var
  I: Integer;
  LDiscardLen: Integer;
  LUserCardLen: Integer;
  LDiscardIndex: Integer;
  LNextUserCardIndex: Integer;
  LCompareResult: Integer;
  LTmpCard: TGameCard;
  LEqualIndex: Integer;
begin
  LDiscardLen := Length(ADecSortDiscard);
  LUserCardLen := Length(ADecSortUserCard);

  if LDiscardLen < 1 then
  begin
    Result := True;
  end else if LUserCardLen < LDiscardLen then
  begin
    Result := False;
  end else
  begin
    Result := True;

    LNextUserCardIndex := 0;
    for LDiscardIndex := 0 to LDiscardLen - 1 do
    begin
      LEqualIndex := CINVALID_INDEX;
      LTmpCard := ADecSortDiscard[LDiscardIndex];
      
      // 找到下一个相等的
      for I := LNextUserCardIndex to LUserCardLen - 1 do
      begin
        LCompareResult := CompareACard(LTmpCard, ADecSortUserCard[I]);
        if LCompareResult = 0 then
        begin
          LEqualIndex := I;
          Break;
        end else if LCompareResult > 0 then
        begin
          Break;
        end;
      end;

      if LEqualIndex <> CINVALID_INDEX then
      begin
        LNextUserCardIndex := LEqualIndex + 1;
      end else
      begin
        Result := False;
        Break;
      end;
    end;
  end;
end;


procedure TTemplateGameLogicProc.CalcTakesCard(
  var RetSplitAryAry: TSplitCardAryAry);

  // 检测3张2带牌后，是否最多剩余一把牌
  function Check222Take1Left1Ba: Boolean;
  var
    LTotalBaShu: Integer;
    LBaShuExcept2_1: Integer;
  begin
    LTotalBaShu := GetSplitTotalBaShu(RetSplitAryAry, Low(TSplitCardType), High(TSplitCardType));
    LBaShuExcept2_1 := GetSplitTotalBaShu(RetSplitAryAry, Low(TSplitCardType), sctThree);
    
    Result := (LBaShuExcept2_1 <= 2) and (LTotalBaShu - LBaShuExcept2_1 = 1);
  end;

  function CheckCanTakeB2ForCalc(ATakeCount: Integer): Boolean;
  var
    L1Count, L2Count: Integer;
    LBaShuExcept2_1: Integer;
  begin
    LBaShuExcept2_1 := GetSplitTotalBaShu(RetSplitAryAry, Low(TSplitCardType), sctThree);
    L1Count := Length(RetSplitAryAry[sctSingle]);
    L2Count := Length(RetSplitAryAry[sctPair]);
    
    Result := (LBaShuExcept2_1 <= 2) and (
      ((L1Count = ATakeCount) and (L2Count = 0)) or
      ((L1Count = 0) and (L2Count = ATakeCount)) or
      (L2Count * 2 + L1Count = ATakeCount)
      );
  end;

  function AddTakeCard(var RetSpitItem: TSplitCardItem): Boolean;
  var
    I: Integer;
    LCanTakeB2: Boolean;
    LTakeCount: Integer;
    LCurValue: TCardValue;
    LNotTakeMaxValue, LNotTakeMinValue: TCardValue;
    LMinTake2Value, LMinTake1Value: TCardValue;
    LCanTake2Count, LCanTake1Count: Integer;
    LSmallSingleCount, LSmallPairCount: Integer;
    LTake2Count, LTake1Count: Integer;

    procedure DoTake2(AIndex: Integer);
    var
      J: Integer;
    begin
      Inc(LCanTake2Count);

      AddGameCardAry(RetSplitAryAry[sctPair][AIndex].CardAry, 0, 2, RetSpitItem.TakesCard);

      for J := AIndex to High(RetSplitAryAry[sctPair]) - 1 do
        RetSplitAryAry[sctPair][J] := RetSplitAryAry[sctPair][J + 1];
      SetLength(RetSplitAryAry[sctPair], Length(RetSplitAryAry[sctPair]) - 1);
    end;

    procedure DoTake1(AIndex: Integer);
    var
      J: Integer;
    begin
      Inc(LCanTake1Count);

      AddGameCardAry(RetSplitAryAry[sctSingle][AIndex].CardAry, 0, 1, RetSpitItem.TakesCard);

      for J := AIndex to High(RetSplitAryAry[sctSingle]) - 1 do
        RetSplitAryAry[sctSingle][J] := RetSplitAryAry[sctSingle][J + 1];
      SetLength(RetSplitAryAry[sctSingle], Length(RetSplitAryAry[sctSingle]) - 1);
    end;
    
  begin
    LTakeCount := RetSpitItem.CardType.TypeNum.X;
    LNotTakeMaxValue := RetSpitItem.CardType.TypeValue.Value;
    LNotTakeMinValue := TCardValue(Ord(LNotTakeMaxValue) - LTakeCount + 1);
    LCanTakeB2 := CheckCanTakeB2ForCalc(LTakeCount);

    // 获得可以带多少对子，可以带多少单牌
    LCanTake2Count := 0;
    LCanTake1Count := 0;
    LSmallPairCount := 0;
    LSmallSingleCount := 0;
    LMinTake2Value := scvNone;
    LMinTake1Value := scvNone;
    for I := High(RetSplitAryAry[sctPair]) downto Low(RetSplitAryAry[sctPair]) do
    begin
      LCurValue := RetSplitAryAry[sctPair][I].CardType.TypeValue.Value;
      if (LCurValue < LNotTakeMinValue) or (LCurValue > LNotTakeMaxValue) then
      begin
        if LMinTake2Value = scvNone then
          LMinTake2Value := LCurValue;
          
        if LCurValue > scvBA then
        begin
          if LCanTakeB2 then
            Inc(LCanTake2Count);
        end else
        begin
          Inc(LCanTake2Count);
          if LCurValue <= scv10 then
            Inc(LSmallPairCount);
        end;
      end;
    end;
    for I := High(RetSplitAryAry[sctSingle]) downto Low(RetSplitAryAry[sctSingle]) do
    begin
      LCurValue := RetSplitAryAry[sctSingle][I].CardType.TypeValue.Value;
      if (LCurValue < LNotTakeMinValue) or (LCurValue > LNotTakeMaxValue) then
      begin
        if LMinTake1Value = scvNone then
          LMinTake1Value := LCurValue;
          
        if LCurValue > scvBA then
        begin
          if LCanTakeB2 then
            Inc(LCanTake1Count);
        end else
        begin
          Inc(LCanTake1Count);
          if LCurValue <= scvJ then
            Inc(LSmallSingleCount);
        end;
      end;
    end;

    LTake2Count := 0;
    LTake1Count := 0;
    // 如果单和对都能带，谁小带谁
    if (LCanTake2Count >= LTakeCount) and (LCanTake1Count >= LTakeCount) then
    begin
      if LTakeCount > 1 then
      begin
        if LSmallPairCount > LSmallSingleCount then
          LTake2Count := LTakeCount
        else
          LTake1Count := LTakeCount;
      end else
      begin
        if LMinTake2Value < LMinTake1Value then
          LTake2Count := LTakeCount
        else
          LTake1Count := LTakeCount;
      end;
    end else if LCanTake1Count >= LTakeCount then
    begin
      LTake1Count := LTakeCount;
    end else if LCanTake2Count >= LTakeCount then
    begin
      LTake2Count := LTakeCount;
    end else if (LCanTake2Count * 2 + LCanTake1Count) >= LTakeCount then
    begin
      // 判断带所有单牌后剩余是偶数还是奇数
      if (LTakeCount - LCanTake1Count) mod 2 = 0  then
      begin
        LTake1Count := LCanTake1Count;
        LTake2Count := (LTakeCount - LTake1Count) div 2;
      end else
      begin
        // 这里不能把对子拆分成单牌，因为会破坏拆牌结构
        if LCanTake1Count > 0 then
        begin
          LTake1Count := LCanTake1Count - 1;
          LTake2Count := (LTakeCount - LTake1Count) div 2;
        end;                   
      end;
    end;

    // 开始带牌
    Result := (LTake1Count + LTake2Count) > 0;
    if Result then
    begin
      LCanTake2Count := 0;
      LCanTake1Count := 0;
      for I := High(RetSplitAryAry[sctPair]) downto Low(RetSplitAryAry[sctPair]) do
      begin
        // 已经处理完毕
        if LCanTake2Count >= LTake2Count then
          Break;
          
        LCurValue := RetSplitAryAry[sctPair][I].CardType.TypeValue.Value;
        if (LCurValue < LNotTakeMinValue) or (LCurValue > LNotTakeMaxValue) then
        begin
          if LCurValue > scvBA then
          begin
            if LCanTakeB2 then
              DoTake2(I);
          end else
          begin
            DoTake2(I);
          end;
        end;
      end;
      
      for I := High(RetSplitAryAry[sctSingle]) downto Low(RetSplitAryAry[sctSingle]) do
      begin
        // 已经处理完毕
        if LCanTake1Count >= LTake1Count then
          Break;
          
        LCurValue := RetSplitAryAry[sctSingle][I].CardType.TypeValue.Value;
        if (LCurValue < LNotTakeMinValue) or (LCurValue > LNotTakeMaxValue) then
        begin
          if LCurValue > scvBA then
          begin
            if LCanTakeB2 then
              DoTake1(I);
          end else
          begin
            DoTake1(I);
          end;
        end;
      end;
    end;
  end;

var
  I: Integer;
  LSplitType: TSplitCardType;
begin
  // 处理怎么带牌

  // 初始化
  for LSplitType := Low(RetSplitAryAry) to High(RetSplitAryAry) do
  begin
    if Length(RetSplitAryAry[LSplitType]) > 0 then
    begin
      for I := Low(RetSplitAryAry[LSplitType]) to High(RetSplitAryAry[LSplitType]) do
      begin
        SetLength(RetSplitAryAry[LSplitType][I].TakesCard, 0);
      end;
    end;
  end;

  // 先给3顺带牌
  if Length(RetSplitAryAry[sct3Series]) > 0 then
  begin
    for I := High(RetSplitAryAry[sct3Series]) downto Low(RetSplitAryAry[sct3Series]) do
    begin
      if not AddTakeCard(RetSplitAryAry[sct3Series][I]) then
        Break; 
    end;
  end;

  // 再给3张带牌，3张2一般不处理带牌，除带牌后还剩余1把牌
  if Length(RetSplitAryAry[sctThree]) > 0 then
  begin
    for I := High(RetSplitAryAry[sctThree]) downto Low(RetSplitAryAry[sctThree]) do
    begin
      if RetSplitAryAry[sctThree][I].CardType.TypeValue.Value = scvB2 then
      begin
        if not Check222Take1Left1Ba then
          Continue;
      end;
      
      if not AddTakeCard(RetSplitAryAry[sctThree][I]) then
        Break;        
    end;
  end;
end;

function TTemplateGameLogicProc.GetSplitTakeCardChaiPai(
  const ASplitAry: TSplitCardAryAry; ANotTakeMinValue, ANotTakeMaxValue: TCardValue; N,
  ATakeCount: Integer; var RetTakeCard: TGameCardAry): Boolean;
var
  LCurTakeCount: Integer;                   // 当前已经获得了多少张带牌
  LExcludeCardValue: set of TCardValue;     // 排除要带的牌值

  function InitVar: Boolean;
  var
    LCanTakeB2: Boolean;
  begin
    Result := False;
    
    SetLength(RetTakeCard, 0);
    if (N < 1) or (N > 2) then
      Exit;
    if ATakeCount < 1 then
      Exit;

    LCurTakeCount := 0;
    LExcludeCardValue := [ANotTakeMinValue..ANotTakeMaxValue];
    LCanTakeB2 := CheckCanTakeB2(ASplitAry, N, ATakeCount);
    if not LCanTakeB2 then
    begin
      Include(LExcludeCardValue, scvB2);
      Include(LExcludeCardValue, scvSJoker);
      Include(LExcludeCardValue, scvBJoker);
    end;
    
    Result := True;
  end;
  
  procedure GetTake1_2Card;
  var
    I: Integer;
    LCurValue: TCardValue;
  begin
    if N = 2 then
    begin
      for I := High(ASplitAry[sctPair]) downto Low(ASplitAry[sctPair]) do
      begin
        LCurValue := ASplitAry[sctPair][I].CardType.TypeValue.Value;
        if not (LCurValue in LExcludeCardValue) then
        begin
          Inc(LCurTakeCount);
          Include(LExcludeCardValue, ASplitAry[sctPair][I].CardType.TypeValue.Value);
          
          AddGameCardAry(ASplitAry[sctPair][I].CardAry, 0, 2, RetTakeCard);
        end;
        
        if LCurTakeCount >= ATakeCount then
          Break;
      end;
    end else
    begin
      for I := High(ASplitAry[sctSingle]) downto Low(ASplitAry[sctSingle]) do
      begin
        LCurValue := ASplitAry[sctSingle][I].CardType.TypeValue.Value;
        if not (LCurValue in LExcludeCardValue) then
        begin
          Inc(LCurTakeCount);
          Include(LExcludeCardValue, ASplitAry[sctSingle][I].CardType.TypeValue.Value);
          
          AddGameCardAry(ASplitAry[sctSingle][I].CardAry, 0, 1, RetTakeCard);
        end;

        if LCurTakeCount >= ATakeCount then
          Break;
      end;
    end;
  end;

  procedure DoChaiPaiForPair;
  var
    I, J: Integer;
    LLen: Integer;
    LCanSplitCount: Integer;
    LCurValue: TCardValue;
  begin
    if LCurTakeCount >= ATakeCount then
      Exit;
    // 拆4连以上的双顺顶张
    if Length(ASplitAry[sct2Series]) > 0 then
    begin
      for I := High(ASplitAry[sct2Series]) downto Low(ASplitAry[sct2Series]) do
      begin
        LLen := ASplitAry[sct2Series][I].CardType.TypeNum.X;
        if LLen >= 4 then
        begin
          LCanSplitCount := LLen - 3;

          // 先尝试带小牌
          J := High(ASplitAry[sct2Series][I].CardAry) - 1;
          while J >= Low(ASplitAry[sct2Series][I].CardAry) do
          begin
            LCurValue := ASplitAry[sct2Series][I].CardAry[J].Value;
            if LCurValue in LExcludeCardValue then
              Break;

            Dec(LCanSplitCount);
            Inc(LCurTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct2Series][I].CardAry, J, 2, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
            if LCanSplitCount < 1 then
              Break;

            Dec(J, 2);          
          end;

          if LCanSplitCount < 1 then
            Continue;

          // 再尝试带大牌
          J := Low(ASplitAry[sct2Series][I].CardAry);
          while J <= High(ASplitAry[sct2Series][I].CardAry) - 1 do
          begin
            LCurValue := ASplitAry[sct2Series][I].CardAry[J].Value;
            if LCurValue in LExcludeCardValue then
              Break;

            Dec(LCanSplitCount);
            Inc(LCurTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct2Series][I].CardAry, J, 2, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
            if LCanSplitCount < 1 then
              Break;

            Inc(J, 2);
          end;
        end;
      end;
    end;
    // 拆双顺
    if Length(ASplitAry[sct2Series]) > 0 then
    begin
      for I := High(ASplitAry[sct2Series]) downto Low(ASplitAry[sct2Series]) do
      begin
        // 先尝试带小牌
        J := High(ASplitAry[sct2Series][I].CardAry) - 1;
        while J >= Low(ASplitAry[sct2Series][I].CardAry) do
        begin
          LCurValue := ASplitAry[sct2Series][I].CardAry[J].Value;
          if not (LCurValue in LExcludeCardValue) then
          begin
            Inc(LCurTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct2Series][I].CardAry, J, 2, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
          end;

          Dec(J, 2);
        end;
      end;
    end;
    // 拆三条
    if Length(ASplitAry[sctThree]) > 0 then
    begin
      for I := High(ASplitAry[sctThree]) downto Low(ASplitAry[sctThree]) do
      begin
        // 先尝试带小牌
        LCurValue := ASplitAry[sctThree][I].CardType.TypeValue.Value;
        if LCurValue in LExcludeCardValue then
          Continue;

        Inc(LCurTakeCount);
        Include(LExcludeCardValue, LCurValue);
        AddGameCardAry(ASplitAry[sctThree][I].CardAry, 0, 2, RetTakeCard);
        if LCurTakeCount >= ATakeCount then
          Exit;
      end;
    end;
    // 拆三顺
    if Length(ASplitAry[sct3Series]) > 0 then
    begin
      for I := High(ASplitAry[sct3Series]) downto Low(ASplitAry[sct3Series]) do
      begin
        // 先尝试带小牌
        J := High(ASplitAry[sct3Series][I].CardAry) - 2;
        while J >= Low(ASplitAry[sct3Series][I].CardAry) do
        begin
          LCurValue := ASplitAry[sct3Series][I].CardAry[J].Value;
          if not (LCurValue in LExcludeCardValue) then
          begin
            Inc(LCurTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct3Series][I].CardAry, J, 2, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
          end;

          Dec(J, 3);
        end;
      end;
    end;
  end;

  procedure DoChaiPaiForSingle;
  var
    I, J: Integer;
    LLen: Integer;
    LCanSplitCount: Integer;
    LCurValue: TCardValue;
    LCalcTakeCount: Integer;
  begin
    if LCurTakeCount >= ATakeCount then
      Exit;
    // 拆6连以上的单顺顶张
    if Length(ASplitAry[sct1Series]) > 0 then
    begin
      for I := High(ASplitAry[sct1Series]) downto Low(ASplitAry[sct1Series]) do
      begin
        LLen := ASplitAry[sct1Series][I].CardType.TypeNum.X;
        if LLen >= 6 then
        begin
          LCanSplitCount := LLen - 5;

          // 先尝试带小牌
          J := High(ASplitAry[sct1Series][I].CardAry);
          while J >= Low(ASplitAry[sct1Series][I].CardAry) do
          begin
            LCurValue := ASplitAry[sct1Series][I].CardAry[J].Value;
            if LCurValue in LExcludeCardValue then
              Break;

            Dec(LCanSplitCount);
            Inc(LCurTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct1Series][I].CardAry, J, 1, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
            if LCanSplitCount < 1 then
              Break;

            Dec(J, 1);          
          end;

          if LCanSplitCount < 1 then
            Continue;

          // 再尝试带大牌
          J := Low(ASplitAry[sct1Series][I].CardAry);
          while J <= High(ASplitAry[sct1Series][I].CardAry) do
          begin
            LCurValue := ASplitAry[sct1Series][I].CardAry[J].Value;
            if LCurValue in LExcludeCardValue then
              Break;

            Dec(LCanSplitCount);
            Inc(LCurTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct1Series][I].CardAry, J, 1, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
            if LCanSplitCount < 1 then
              Break;

            Inc(J, 1);
          end;
        end;
      end;
    end;
    // 拆对牌
    if Length(ASplitAry[sctPair]) > 0 then
    begin
      for I := High(ASplitAry[sctPair]) downto Low(ASplitAry[sctPair]) do
      begin
        // 先尝试带小牌
        LCurValue := ASplitAry[sctPair][I].CardType.TypeValue.Value;
        if LCurValue in LExcludeCardValue then
          Continue;

        if ATakeCount - LCurTakeCount >= 2 then
          LCalcTakeCount := 2
        else
          LCalcTakeCount := 1;
          
        Inc(LCurTakeCount, LCalcTakeCount);
        Include(LExcludeCardValue, LCurValue);
        AddGameCardAry(ASplitAry[sctPair][I].CardAry, 0, LCalcTakeCount, RetTakeCard);
        if LCurTakeCount >= ATakeCount then
          Exit;
      end;
    end;
    // 拆三条
    if Length(ASplitAry[sctThree]) > 0 then
    begin
      for I := High(ASplitAry[sctThree]) downto Low(ASplitAry[sctThree]) do
      begin
        // 先尝试带小牌
        LCurValue := ASplitAry[sctThree][I].CardType.TypeValue.Value;
        if LCurValue in LExcludeCardValue then
          Continue;
                           
        // 可以带3张，但是不能和原来的牌型组成3顺
        if (ATakeCount - LCurTakeCount >= 3) and (Ord(LCurValue) - Ord(ANotTakeMaxValue) <> 1) and (Ord(ANotTakeMinValue) - Ord(LCurValue) <> 1) then
          LCalcTakeCount := 3
        else if ATakeCount - LCurTakeCount >= 2 then
          LCalcTakeCount := 2
        else
          LCalcTakeCount := 1;
          
        Inc(LCurTakeCount, LCalcTakeCount);
        Include(LExcludeCardValue, LCurValue);
        AddGameCardAry(ASplitAry[sctThree][I].CardAry, 0, LCalcTakeCount, RetTakeCard);
        if LCurTakeCount >= ATakeCount then
          Exit;
      end;
    end;
    // 拆三顺
    if Length(ASplitAry[sct3Series]) > 0 then
    begin
      for I := High(ASplitAry[sct3Series]) downto Low(ASplitAry[sct3Series]) do
      begin
        // 先尝试带小牌
        J := High(ASplitAry[sct3Series][I].CardAry) - 2;
        while J >= Low(ASplitAry[sct3Series][I].CardAry) do
        begin
          LCurValue := ASplitAry[sct3Series][I].CardAry[J].Value;
          if not (LCurValue in LExcludeCardValue) then
          begin
            // 可以带3张，但是不能和原来的牌型组成3顺
            if (ATakeCount - LCurTakeCount >= 3) and (Ord(LCurValue) - Ord(ANotTakeMaxValue) <> 1) and (Ord(ANotTakeMinValue) - Ord(LCurValue) <> 1) then
              LCalcTakeCount := 3
            else if ATakeCount - LCurTakeCount >= 2 then
              LCalcTakeCount := 2
            else
              LCalcTakeCount := 1;

            Inc(LCurTakeCount, LCalcTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct3Series][I].CardAry, J, LCalcTakeCount, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
          end;

          Dec(J, 3);
        end;
      end;
    end;
    // 拆双顺
    if Length(ASplitAry[sct2Series]) > 0 then
    begin
      for I := High(ASplitAry[sct2Series]) downto Low(ASplitAry[sct2Series]) do
      begin
        // 先尝试带小牌
        J := High(ASplitAry[sct2Series][I].CardAry) - 1;
        while J >= Low(ASplitAry[sct2Series][I].CardAry) do
        begin
          LCurValue := ASplitAry[sct2Series][I].CardAry[J].Value;
          if not (LCurValue in LExcludeCardValue) then
          begin
            if ATakeCount - LCurTakeCount >= 2 then
              LCalcTakeCount := 2
            else
              LCalcTakeCount := 1;

            Inc(LCurTakeCount, LCalcTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct2Series][I].CardAry, J, LCalcTakeCount, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
          end;

          Dec(J, 2);
        end;
      end;
    end;
    // 拆5连单顺
    if Length(ASplitAry[sct1Series]) > 0 then
    begin
      for I := High(ASplitAry[sct1Series]) downto Low(ASplitAry[sct1Series]) do
      begin
        // 先尝试带小牌
        J := High(ASplitAry[sct1Series][I].CardAry);
        while J >= Low(ASplitAry[sct1Series][I].CardAry) do
        begin
          LCurValue := ASplitAry[sct1Series][I].CardAry[J].Value;
          if not (LCurValue in LExcludeCardValue) then
          begin
            LCalcTakeCount := 1;

            Inc(LCurTakeCount, LCalcTakeCount);
            Include(LExcludeCardValue, LCurValue);
            AddGameCardAry(ASplitAry[sct1Series][I].CardAry, J, LCalcTakeCount, RetTakeCard);
            if LCurTakeCount >= ATakeCount then
              Exit;
          end;

          Dec(J, 1);
        end;
      end;
    end;
  end;

begin
  // 拆牌带单和对
  // 注意要排除带3张
  Result := False;
  if not InitVar then
    Exit;

  // 提出可以带的单和对
  GetTake1_2Card;

  // 看是否需要拆牌来带
  if LCurTakeCount < ATakeCount then
  begin
    if N = 2 then
    begin
      DoChaiPaiForPair;
    end else
    begin
      DoChaiPaiForSingle;
    end;
  end;

  Result := LCurTakeCount = ATakeCount;
end;

function TTemplateGameLogicProc.GetSplitTakeCardNotChaiPai(
  const ASplitAry: TSplitCardAryAry; ANotTakeMinValue, ANotTakeMaxValue: TCardValue; N, ATakeCount: Integer;
  var RetTakeCard: TGameCardAry): Boolean;
var
  I: Integer;
  LCanTakeB2: Boolean;
  LCurValue: TCardValue;
  LCanTake2Count, LCanTake1Count: Integer;
  LSmallSingleCount, LSmallPairCount: Integer;
  LTake2Count, LTake1Count: Integer;

  procedure DoTake2(AIndex: Integer);
  begin
    Inc(LCanTake2Count);

    AddGameCardAry(ASplitAry[sctPair][AIndex].CardAry, 0, 2, RetTakeCard);
  end;

  procedure DoTake1(AIndex: Integer);
  begin
    Inc(LCanTake1Count);

    AddGameCardAry(ASplitAry[sctSingle][AIndex].CardAry, 0, 1, RetTakeCard);
  end;
    
begin
  Result := False;
  SetLength(RetTakeCard, 0);
  if (N < 1) or (N > 2) then
    Exit;
  if ATakeCount < 1 then
    Exit;
  
  LCanTakeB2 := CheckCanTakeB2(ASplitAry, N, ATakeCount);

  // 获得可以带多少对子，可以带多少单牌
  LCanTake2Count := 0;
  LCanTake1Count := 0;
  LSmallPairCount := 0;
  LSmallSingleCount := 0;
  for I := High(ASplitAry[sctPair]) downto Low(ASplitAry[sctPair]) do
  begin
    LCurValue := ASplitAry[sctPair][I].CardType.TypeValue.Value;
    if (LCurValue < ANotTakeMinValue) or (LCurValue > ANotTakeMaxValue) then
    begin
      if LCurValue > scvBA then
      begin
        if LCanTakeB2 then
          Inc(LCanTake2Count);
      end else
      begin
        Inc(LCanTake2Count);
        if LCurValue <= scv10 then
          Inc(LSmallPairCount);
      end;
    end;
  end;
  for I := High(ASplitAry[sctSingle]) downto Low(ASplitAry[sctSingle]) do
  begin
    LCurValue := ASplitAry[sctSingle][I].CardType.TypeValue.Value;
    if (LCurValue < ANotTakeMinValue) or (LCurValue > ANotTakeMaxValue) then
    begin
      if LCurValue > scvBA then
      begin
        if LCanTakeB2 then
          Inc(LCanTake1Count);
      end else
      begin
        Inc(LCanTake1Count);
        if LCurValue <= scvJ then
          Inc(LSmallSingleCount);
      end;
    end;
  end;

  LTake2Count := 0;
  LTake1Count := 0;

  if N = 2 then
  begin
    // 如果要带对牌，则只能带对牌
    if LCanTake2Count >= ATakeCount then
      LTake2Count := ATakeCount;
  end else
  begin
    // 如果要带单牌，则优先带单牌
    if LCanTake1Count >= ATakeCount then
    begin
      LTake1Count := ATakeCount;

      // 如果小对多，优先带对子
      if (LSmallPairCount > LSmallSingleCount) and (LSmallPairCount * 2 >= ATakeCount) then
      begin
        if ATakeCount mod 2 = 0 then
        begin
          LTake1Count := 0;
        end else
        begin
          LTake1Count := 1;
        end;

        LTake2Count := ATakeCount div 2;
      end;
    end else if (LCanTake2Count * 2 + LCanTake1Count) >= ATakeCount then
    begin
      // 判断带所有单牌后剩余是偶数还是奇数
      if (ATakeCount - LCanTake1Count) mod 2 = 0  then
      begin
        LTake1Count := LCanTake1Count;
        LTake2Count := (ATakeCount - LTake1Count) div 2;
      end else
      begin
        // 这里不能把对子拆分成单牌，因为会破坏拆牌结构
        if LCanTake1Count > 0 then
        begin
          LTake1Count := LCanTake1Count - 1;
          LTake2Count := (ATakeCount - LTake1Count) div 2;
        end;                   
      end;
    end;
  end;

  // 开始带牌
  Result := (LTake1Count + LTake2Count) > 0;
  if Result then
  begin
    LCanTake2Count := 0;
    LCanTake1Count := 0;
    for I := High(ASplitAry[sctPair]) downto Low(ASplitAry[sctPair]) do
    begin
      // 已经处理完毕
      if LCanTake2Count >= LTake2Count then
        Break;
          
      LCurValue := ASplitAry[sctPair][I].CardType.TypeValue.Value;
      if (LCurValue < ANotTakeMinValue) or (LCurValue > ANotTakeMaxValue) then
      begin
        if LCurValue > scvBA then
        begin
          if LCanTakeB2 then
            DoTake2(I);
        end else
        begin
          DoTake2(I);
        end;
      end;
    end;
      
    for I := High(ASplitAry[sctSingle]) downto Low(ASplitAry[sctSingle]) do
    begin
      // 已经处理完毕
      if LCanTake1Count >= LTake1Count then
        Break;
          
      LCurValue := ASplitAry[sctSingle][I].CardType.TypeValue.Value;
      if (LCurValue < ANotTakeMinValue) or (LCurValue > ANotTakeMaxValue) then
      begin
        if LCurValue > scvBA then
        begin
          if LCanTakeB2 then
            DoTake1(I);
        end else
        begin
          DoTake1(I);
        end;
      end;
    end;
  end;
end;

function TTemplateGameLogicProc.GetSplitTotalBaShu(
  const ASplitAry: TSplitCardAryAry; AFromSplit, AToSplit: TSplitCardType): Integer;
var
  LSplitType: TSplitCardType;
begin
  // 获得把数
  Result := 0;

  if AFromSplit <= AToSplit then
  begin
    for LSplitType := AFromSplit to AToSplit do
    begin
      Inc(Result, Length(ASplitAry[LSplitType]));
    end;
  end else
  begin
    for LSplitType := AToSplit downto AFromSplit do
    begin
      Inc(Result, Length(ASplitAry[LSplitType]));
    end;
  end;
end;

function TTemplateGameLogicProc.CheckCanTakeB2(const ASplitAry: TSplitCardAryAry; N, ATakeCount: Integer): Boolean;
var
  L1Count, L2Count: Integer;
  LBaShuExcept2_1: Integer;
begin
  LBaShuExcept2_1 := GetSplitTotalBaShu(ASplitAry, Low(TSplitCardType), sctThree);
  L1Count := Length(ASplitAry[sctSingle]);
  L2Count := Length(ASplitAry[sctPair]);
    
  Result := (LBaShuExcept2_1 <= 2) and (
    ((N = 1) and (L1Count = ATakeCount) and (L2Count = 0)) or
    ((N = 2) and (L1Count = 0) and (L2Count = ATakeCount)) or
    ((N = 1) and (L2Count * 2 + L1Count = ATakeCount))
    );
end;

function TTemplateGameLogicProc.GetSplitAryHintMsg(
  const SplitAryAry: TSplitCardAryAry; const RetStrList: TStringList): Integer;

  function GetOneCardStr(const ACard: TGameCard): string;
  begin
    Result := CCARD_COLOR_MSG[ACard.Color] + CCARD_VALUE_MSG[ACard.Value];
  end;

  function GetCardAryStr(const ACardAry: TGameCardAry): string;
  var
    I: Integer;
  begin
    Result := '';
    for I := Low(ACardAry) to High(ACardAry) do
      Result := Result + GetOneCardStr(ACardAry[I]) + ' ';
  end;

  function GetCardTypeStr(const ACardType: TLordCardType): string;
  begin
    Result := Format('%d-%d-%d-%d', [ACardType.TypeNum.X, ACardType.TypeNum.M, ACardType.TypeNum.Y, ACardType.TypeNum.N]) +
      ': ' + GetOneCardStr(ACardType.TypeValue);
  end;

var
  I: Integer;
  LSplitType: TSplitCardType;
begin
  // 该函数返回牌总数
  Result := 0;

  for LSplitType := Low(SplitAryAry) to High(SplitAryAry) do
  begin
    if Length(SplitAryAry[LSplitType]) > 0 then
    begin
      RetStrList.Add(CSPLIT_CARD_TYPE_MSG[LSplitType] + ':'#13#10);

      for I := Low(SplitAryAry[LSplitType]) to High(SplitAryAry[LSplitType]) do
      begin
        RetStrList.Add('[' + GetCardTypeStr(SplitAryAry[LSplitType][I].CardType)  + ']'#13#10);
        RetStrList.Add(GetCardAryStr(SplitAryAry[LSplitType][I].CardAry));
        if Length(SplitAryAry[LSplitType][I].TakesCard) > 0 then
          RetStrList.Add('带牌：' + GetCardAryStr(SplitAryAry[LSplitType][I].TakesCard));
        RetStrList.Add(#13#10);

        Inc(Result, Length(SplitAryAry[LSplitType][I].CardAry));
        Inc(Result, Length(SplitAryAry[LSplitType][I].TakesCard));
      end;

      RetStrList.Add(#13#10#13#10);      
    end;
  end;
end;

function TTemplateGameLogicProc.SplitCard(const ADecSortCardAry: TGameCardAry;
  var RetSplitAryAry: TSplitCardAryAry): Integer;
var
  LLeftCardAry: TGameCardAry;
  LScanAry: TCardScanItemAry;
  LCardLen: Integer;
  LPTmpTypeNum: PCardTypeNum;

  procedure InitVar;
  var
    LSplitType: TSplitCardType;
  begin
    for LSplitType := Low(RetSplitAryAry) to High(RetSplitAryAry) do
      SetLength(RetSplitAryAry[LSplitType], 0);

    LCardLen := Length(ADecSortCardAry);
    CopyGameCardAry(ADecSortCardAry, LLeftCardAry);
  end;

  procedure CheckSplitRocket;
  begin
    if Length(LLeftCardAry) < 2 then
      Exit;

    // 如果包含火箭
    if (LLeftCardAry[0].Value = scvBJoker) and (LLeftCardAry[1].Value = scvSJoker) then
    begin
      SetLength(RetSplitAryAry[sctRocket], 1);
      SetLength(RetSplitAryAry[sctRocket][0].CardAry, 0);

      // 牌型是火箭
      RetSplitAryAry[sctRocket][0].CardType.TypeValue := LLeftCardAry[0];
      LPTmpTypeNum := @RetSplitAryAry[sctRocket][0].CardType.TypeNum;
      LPTmpTypeNum^.X := 1;
      LPTmpTypeNum^.M := 4;
      LPTmpTypeNum^.Y := 0;
      LPTmpTypeNum^.N := 0;

      // 选出火箭
      AddGameCardAry(LLeftCardAry, 0, 2, RetSplitAryAry[sctRocket][0].CardAry);

      // 剩余牌中去掉火箭
      DelCardFromCardAry(RetSplitAryAry[sctRocket][0].CardAry, LLeftCardAry);
    end;
  end;

  procedure CheckSplit3Series;
  var
    LIndex: Integer;
    LLastCard: TGameCard;
    LMaxCard: TGameCard;
    L3SeriesLen: Integer;
    LDelFromIndex: Integer;

    procedure CheckAdd3Series(ACurScanIndex: Integer);
    var
      J: Integer;
    begin
      if L3SeriesLen >= 2 then
      begin
        LIndex := Length(RetSplitAryAry[sct3Series]);
        SetLength(RetSplitAryAry[sct3Series], LIndex + 1);
        SetLength(RetSplitAryAry[sct3Series][LIndex].CardAry, 0);
        if LDelFromIndex = -1 then
          LDelFromIndex := LIndex;

        // 牌型
        RetSplitAryAry[sct3Series][LIndex].CardType.TypeValue := LMaxCard;
        LPTmpTypeNum := @RetSplitAryAry[sct3Series][LIndex].CardType.TypeNum;
        LPTmpTypeNum^.X := L3SeriesLen;
        LPTmpTypeNum^.M := 3;
        LPTmpTypeNum^.Y := 0;
        LPTmpTypeNum^.N := 0;

        // 选出牌来
        for J := L3SeriesLen downto 1 do
        begin
          AddGameCardAry(LLeftCardAry, LScanAry[ACurScanIndex - J].Index, 3, RetSplitAryAry[sct3Series][LIndex].CardAry);
        end;
      end;
    end;

  var
    I: Integer;
  begin
    if Length(LLeftCardAry) < 6 then
      Exit;
      
    GetCardScanTable(LLeftCardAry, sccNone, LScanAry);
    DecSortCardScanAryByCount(LScanAry);

    // 从第二张牌开始扫描
    LDelFromIndex := -1;
    L3SeriesLen := 1;
    LLastCard := LScanAry[0].Card;
    LMaxCard := LScanAry[0].Card;
    for I := Low(LScanAry) + 1 to High(LScanAry) do
    begin
      if LScanAry[I].Count <> 3 then
      begin
        Break;
      end else
      begin
        // 3顺的第二个3张肯定小于A
        if LScanAry[I].Card.Value > scvK then
        begin
          L3SeriesLen := 1;
          LLastCard := LScanAry[I].Card;
          LMaxCard := LScanAry[I].Card;
        end else
        begin
          if (Ord(LLastCard.Value) - Ord(LScanAry[I].Card.Value)) = 1 then
          begin
            Inc(L3SeriesLen);
          end else
          begin
            // 检测是否选出一个3顺
            CheckAdd3Series(I);

            // 换了另外一个3顺
            L3SeriesLen := 1;
            LMaxCard := LScanAry[I].Card;
          end;
        end;

        LLastCard := LScanAry[I].Card;
      end;
    end;

    // 检测是否选出一个3顺
    CheckAdd3Series(I);

    // 去掉选出的牌
    if LDelFromIndex >= 0 then
    begin
      for I := LDelFromIndex to High(RetSplitAryAry[sct3Series]) do
      begin
        DelCardFromCardAry(RetSplitAryAry[sct3Series][I].CardAry, LLeftCardAry);
      end;
    end;
  end;

  procedure Split1SeriesExtractAll5;
  var
    I: Integer;
    LIndex: Integer;
    LLastCard: TGameCard;
    L1SeriesLen: Integer;
    LTmpCardAry: TGameCardAry;
  begin
    SetLength(LTmpCardAry, 5);

    while True do
    begin
      if Length(LLeftCardAry) < 5 then
        Break;

      L1SeriesLen := 1;
      LLastCard := LLeftCardAry[High(LLeftCardAry)];
      LTmpCardAry[5 - L1SeriesLen] := LLeftCardAry[High(LLeftCardAry)];
      for I := High(LLeftCardAry) - 1 downto Low(LLeftCardAry) do
      begin
        // 单顺的最大牌肯定小于等于A
        if LLeftCardAry[I].Value > scvBA then
        begin
          Break;
        end else
        begin
          // 判断是否是连续序列
          if LLeftCardAry[I].Value = LLastCard.Value then
          begin
            Continue;
          end else if Ord(LLeftCardAry[I].Value) - Ord(LLastCard.Value) = 1 then
          begin
            Inc(L1SeriesLen);
            LTmpCardAry[5 - L1SeriesLen] := LLeftCardAry[I];
            if L1SeriesLen >= 5 then
              Break;
          end else
          begin
            L1SeriesLen := 1;
            LTmpCardAry[5 - L1SeriesLen] := LLeftCardAry[I];
          end;
        end;

        LLastCard := LLeftCardAry[I];
      end;

      if L1SeriesLen <> 5 then
        Break;

      // 找到5张顺子
      LIndex := Length(RetSplitAryAry[sct1Series]);
      SetLength(RetSplitAryAry[sct1Series], LIndex + 1);
      SetLength(RetSplitAryAry[sct1Series][LIndex].CardAry, 0);

      // 牌型
      RetSplitAryAry[sct1Series][LIndex].CardType.TypeValue := LTmpCardAry[0];
      LPTmpTypeNum := @RetSplitAryAry[sct1Series][LIndex].CardType.TypeNum;
      LPTmpTypeNum^.X := L1SeriesLen;
      LPTmpTypeNum^.M := 1;
      LPTmpTypeNum^.Y := 0;
      LPTmpTypeNum^.N := 0;

      // 选出牌来
      CopyGameCardAry(LTmpCardAry, RetSplitAryAry[sct1Series][LIndex].CardAry);

      // 删除牌
      DelCardFromCardAry(LTmpCardAry, LLeftCardAry);
    end;
  end;

  procedure Split1SeriesExpand5;
  var
    I, J: Integer;
    LTmpCard, LMaxCard: TGameCard;
    LDelLen, LLeftLen: Integer;
    LDelCardAry: TGameCardAry;
  begin
    if Length(LLeftCardAry) < 1 then
      Exit;
    if Length(RetSplitAryAry[sct1Series]) < 1 then
      Exit;

    LDelLen := 0;
    LLeftLen := Length(LLeftCardAry);
    SetLength(LDelCardAry, LLeftLen);
    for I := High(LLeftCardAry) downto Low(LLeftCardAry) do
    begin
      // 单顺的最大牌肯定小于等于A
      if LLeftCardAry[I].Value > scvBA then
      begin
        Break;
      end else
      begin
        LTmpCard := LLeftCardAry[I];

        // 看看是否有可以连接的，仅需要考虑连接顺子尾部（大牌）
        for J := Low(RetSplitAryAry[sct1Series]) to High(RetSplitAryAry[sct1Series]) do
        begin
          LMaxCard := RetSplitAryAry[sct1Series][J].CardAry[0];
          if LTmpCard.Value < LMaxCard.Value then
            Break;
          if Ord(LTmpCard.Value) - Ord(LMaxCard.Value) = 1 then
          begin
            // 可以扩展1连
            RetSplitAryAry[sct1Series][J].CardType.TypeValue := LTmpCard;
            RetSplitAryAry[sct1Series][J].CardType.TypeNum.X := Length(RetSplitAryAry[sct1Series][J].CardAry) + 1;

            InsertGameCardAry(LLeftCardAry, I, 0, 1, RetSplitAryAry[sct1Series][J].CardAry);

            // 因为从小到大搜索，所以这么写
            Inc(LDelLen);
            LDelCardAry[LLeftLen - LDelLen] := LTmpCard;

            Break;
          end;
        end;
      end;
    end;

    // 删除牌
    if LDelLen > 0 then
    begin
      for I := 0 to LDelLen - 1 do
        LDelCardAry[I] := LDelCardAry[LLeftLen - LDelLen + I];
      SetLength(LDelCardAry, LDelLen);
      DelCardFromCardAry(LDelCardAry, LLeftCardAry);
    end;
  end;

  procedure Split1SeriesMerge;
  var
    I, J: Integer;
    LSelIndex: Integer;
    LTmpInt: Integer;
    LMinCard, LMaxCard: TGameCard;
  begin
    if Length(RetSplitAryAry[sct1Series]) < 2 then
      Exit;

    for I := High(RetSplitAryAry[sct1Series]) downto Low(RetSplitAryAry[sct1Series]) + 1 do
    begin
      LSelIndex := I;

      LTmpInt := High(RetSplitAryAry[sct1Series][I].CardAry);
      LMinCard := RetSplitAryAry[sct1Series][I].CardAry[LTmpInt];
      for J := I - 1 downto Low(RetSplitAryAry[sct1Series]) do
      begin
        LMaxCard := RetSplitAryAry[sct1Series][J].CardAry[0];

        // 如果大顺的最小牌比小顺的最大牌大1，则可以合并
        if Ord(LMinCard.Value) - Ord(LMaxCard.Value) = 1 then
        begin
          LSelIndex := J;
          Break;
        end;
      end;

      // 找到可以合并的项
      if LSelIndex <> I then
      begin
        LTmpInt := Length(RetSplitAryAry[sct1Series][LSelIndex].CardAry);
        AddGameCardAry(RetSplitAryAry[sct1Series][LSelIndex].CardAry, 0, LTmpInt, RetSplitAryAry[sct1Series][I].CardAry);

        RetSplitAryAry[sct1Series][I].CardType.TypeNum.X := Length(RetSplitAryAry[sct1Series][I].CardAry);
        RetSplitAryAry[sct1Series][I].CardType.TypeValue := RetSplitAryAry[sct1Series][I].CardAry[0];

        // 移动位置
        for J := LSelIndex to High(RetSplitAryAry[sct1Series]) - 1 do
          RetSplitAryAry[sct1Series][J] := RetSplitAryAry[sct1Series][J + 1];
        SetLength(RetSplitAryAry[sct1Series], Length(RetSplitAryAry[sct1Series]) - 1);
      end;
    end;
  end;

  procedure Split1SeriesCheckBaShu;
  var
    LSeriesLen: Integer;
    LMinCardValue: TCardValue;
    LMaxCardValue: TCardValue;

    function CheckDelSeries: Boolean;
    var
      I: Integer;
      LTmpCardValue: TCardValue;
      LCardCount: Integer;
    begin
      LCardCount := 0;

      // 从小牌到大牌搜索包含顺子牌大小的有多少张
      for I := High(LLeftCardAry) downto Low(LLeftCardAry) do
      begin
        LTmpCardValue := LLeftCardAry[I].Value;
        
        if LTmpCardValue >= LMinCardValue then
        begin
          if (LTmpCardValue <= LMaxCardValue) then
            Inc(LCardCount)
          else
            Break;
        end;
      end;

      Result := (LSeriesLen - LCardCount < 2);
    end;

  var
    I, J: Integer;
    LIsDelSeries: Boolean;
  begin
    if Length(LLeftCardAry) < 3 then
      Exit;
    if Length(RetSplitAryAry[sct1Series]) < 1 then
      Exit;

    I := Low(RetSplitAryAry[sct1Series]);
    while I <= High(RetSplitAryAry[sct1Series]) do
    begin
      LSeriesLen := RetSplitAryAry[sct1Series][I].CardType.TypeNum.X;
      LMaxCardValue := RetSplitAryAry[sct1Series][I].CardAry[0].Value;
      LMinCardValue := RetSplitAryAry[sct1Series][I].CardAry[LSeriesLen - 1].Value;

      LIsDelSeries := CheckDelSeries;
      if LIsDelSeries then
      begin
        // 添加到剩余的牌
        AddCardToCardAry(RetSplitAryAry[sct1Series][I].CardAry, LLeftCardAry);
        // 删除顺子
        for J := I to High(RetSplitAryAry[sct1Series]) - 1 do
          RetSplitAryAry[sct1Series][J] := RetSplitAryAry[sct1Series][J + 1];
        SetLength(RetSplitAryAry[sct1Series], Length(RetSplitAryAry[sct1Series]) - 1);
      end else
      begin
        Inc(I);
      end;
    end;
  end;

  procedure Split1SeriesCheckUnionThree;
  var
    I, J: Integer;
    LSeriesLen: Integer;
    LMinCardValue: TCardValue;
    LMaxCardValue: TCardValue;
    LCanUnionMin, LCanUnionMax: Boolean;

    function CheckDoUnion(ASeriesIndex: Integer): Boolean;
    var
      LUnionCardLen: Integer;
      LUnionCardAry: TGameCardAry;
    begin
      LUnionCardLen := 0;
      SetLength(LUnionCardAry, LUnionCardLen);

      // 如果两头都可以，并且连子是6，则仅合并最大牌为3张
      if LCanUnionMin and LCanUnionMax and (LSeriesLen = 6) then
      begin
        LCanUnionMin := False;
      end;

      // 必需先判断最大牌，这样LUnionCardAry才能从大到小排序
      if LCanUnionMax then
      begin
        Inc(LUnionCardLen);
        SetLength(LUnionCardAry, LUnionCardLen);
        LUnionCardAry[LUnionCardLen - 1] := RetSplitAryAry[sct1Series][ASeriesIndex].CardAry[0];        
      end;
      if LCanUnionMin then
      begin
        Inc(LUnionCardLen);
        SetLength(LUnionCardAry, LUnionCardLen);
        LUnionCardAry[LUnionCardLen - 1] := RetSplitAryAry[sct1Series][ASeriesIndex].CardAry[LSeriesLen - 1];
      end;

      Result := LUnionCardLen > 0;

      if Result then
      begin
        // 从顺子中删除合并的牌，改变牌型
        DelCardFromCardAry(LUnionCardAry, RetSplitAryAry[sct1Series][ASeriesIndex].CardAry);
        RetSplitAryAry[sct1Series][ASeriesIndex].CardType.TypeNum.X := Length(RetSplitAryAry[sct1Series][ASeriesIndex].CardAry);
        RetSplitAryAry[sct1Series][ASeriesIndex].CardType.TypeValue := RetSplitAryAry[sct1Series][ASeriesIndex].CardAry[0];

        // 重新回到剩余牌中
        AddCardToCardAry(LUnionCardAry, LLeftCardAry);
      end;
    end;
    
  begin
    if Length(LLeftCardAry) < 2 then
      Exit;
    if Length(RetSplitAryAry[sct1Series]) < 1 then
      Exit;

    GetCardScanTable(LLeftCardAry, sccNone, LScanAry);
    DecSortCardScanAryByCount(LScanAry);
    
    for I := Low(RetSplitAryAry[sct1Series]) to High(RetSplitAryAry[sct1Series]) do
    begin
      LSeriesLen := RetSplitAryAry[sct1Series][I].CardType.TypeNum.X;
      if LSeriesLen > 5 then
      begin
        LCanUnionMin := False;
        LCanUnionMax := False;
        LMinCardValue := RetSplitAryAry[sct1Series][I].CardAry[LSeriesLen - 1].Value;
        LMaxCardValue := RetSplitAryAry[sct1Series][I].CardAry[0].Value;

        for J := Low(LScanAry) to High(LScanAry) do
        begin
          if LScanAry[J].Count = 2 then
          begin
            if LMinCardValue = LScanAry[J].Card.Value then
              LCanUnionMin := True
            else if LMaxCardValue = LScanAry[J].Card.Value then
              LCanUnionMax := True;
          end else if LScanAry[I].Count < 2 then
          begin
            Break;
          end;
        end;

        if CheckDoUnion(I) then
        begin
          // 改变了牌，需要重新扫描
          GetCardScanTable(LLeftCardAry, sccNone, LScanAry);
          DecSortCardScanAryByCount(LScanAry);
        end;
      end;
    end;
  end;

  // 看看顺子数量 减去 剩余牌中与顺子牌相同的牌数量 有多少
  function GetCardIntervalByMinMaxValue(AMinCardValue, AMaxCardValue: TCardValue): Integer;
  var
    I: Integer;
    LCurValue: TCardValue;
    LLeftCardCount: Integer;
  begin
    LLeftCardCount := 0;
    
    for I := High(LLeftCardAry) downto Low(LLeftCardAry) do
    begin
      LCurValue := LLeftCardAry[I].Value;
      if LCurValue >= AMinCardValue then
      begin
        if (LCurValue <= AMaxCardValue) then
          Inc(LLeftCardCount)
        else
          Break;
      end;
    end;

    Result := (Ord(AMaxCardValue) - Ord(AMinCardValue) + 1) - LLeftCardCount;
  end;

  // 找到最优的顺子，返回左边和右边个去掉多少张牌
  procedure GetMaxIntervalByMinMaxValueForDec(AMinCardValue, AMaxCardValue: TCardValue; var RetLeftCount, RetRightCount: Integer);
  var
    LSelLen: Integer;
    LSeriesLen: Integer;
    LMaxInterval: Integer;
    LCurInterval: Integer;
    LCurMinValue, LCurMaxValue: TCardValue;
    LSelFromIndex: Integer;
  begin
    RetLeftCount := 0;
    RetRightCount := 0;
    LSeriesLen := Ord(AMaxCardValue) - Ord(AMinCardValue) + 1;
    LMaxInterval := GetCardIntervalByMinMaxValue(AMinCardValue, AMaxCardValue);

    // 选出牌的长度由大到小选择
    for LSelLen := LSeriesLen - 1 downto 5 do
    begin
      LSelFromIndex := 0;
      while LSelFromIndex <= LSeriesLen - LSelLen do
      begin
        LCurMaxValue := TCardValue(Ord(AMaxCardValue) - LSelFromIndex);
        LCurMinValue := TCardValue(Ord(LCurMaxValue) - LSelLen + 1);
        
        LCurInterval := GetCardIntervalByMinMaxValue(LCurMinValue, LCurMaxValue);
        if LCurInterval >= LMaxInterval then
        begin
          LMaxInterval := LCurInterval;
          
          RetLeftCount := LSelFromIndex;
          RetRightCount := LSeriesLen - LSelFromIndex - LSelLen;
        end;
          
        Inc(LSelFromIndex);
      end;
    end;
  end;

  // 最优缩短连牌，不拆分成2个
  procedure Split1SeriesBestDecLen;
  var
    I: Integer;
    LSplitItem: TSplitCardItem;
    LSeriesLen: Integer;
    LMinCardValue, LMaxCardValue: TCardValue;
    LLeftCount, LRightCount: Integer;
    LDelCardAry: TGameCardAry;
  begin
    if Length(RetSplitAryAry[sct1Series]) < 1 then
      Exit;

    for I := Low(RetSplitAryAry[sct1Series]) to High(RetSplitAryAry[sct1Series]) do
    begin
      LSplitItem := RetSplitAryAry[sct1Series][I];
      LSeriesLen := LSplitItem.CardType.TypeNum.X;
      LMaxCardValue := LSplitItem.CardType.TypeValue.Value;
      LMinCardValue := LSplitItem.CardAry[LSeriesLen - 1].Value;

      // 检测是否需要缩短
      GetMaxIntervalByMinMaxValueForDec(LMinCardValue, LMaxCardValue, LLeftCount, LRightCount);
      if (LLeftCount + LRightCount) > 0 then
      begin
        // 选出要删除的牌
        SetLength(LDelCardAry, 0);
        AddGameCardAry(LSplitItem.CardAry, 0, LLeftCount, LDelCardAry);
        AddGameCardAry(LSplitItem.CardAry, LSeriesLen - LRightCount, LRightCount, LDelCardAry);

        // 删除牌，改变牌型
        DelCardFromCardAry(LDelCardAry, RetSplitAryAry[sct1Series][I].CardAry);
        RetSplitAryAry[sct1Series][I].CardType.TypeNum.X := Length(RetSplitAryAry[sct1Series][I].CardAry);
        RetSplitAryAry[sct1Series][I].CardType.TypeValue := RetSplitAryAry[sct1Series][I].CardAry[0];

        // 剩余牌中添加牌
        AddCardToCardAry(LDelCardAry, LLeftCardAry); 
      end;
    end;
  end;

  // 找到最优的拆分顺子方法，返回左边、中间、右边个去掉多少张牌
  procedure GetMaxIntervalByMinMaxValueForSplit(AMinCardValue, AMaxCardValue: TCardValue;
    var RetMidFromIndex, RetMidLen: Integer);
  var
    LMidLen: Integer;
    LSeriesLen: Integer;
    LMaxInterval: Integer;
    LCurMidFromIndex: Integer;
    LCurLeftInterval, LCurRighInterval: Integer;
    LCurValue: TCardValue;
  begin
    RetMidFromIndex := -1;
    RetMidLen := 0;
    LSeriesLen := Ord(AMaxCardValue) - Ord(AMinCardValue) + 1;
    LMaxInterval := GetCardIntervalByMinMaxValue(AMinCardValue, AMaxCardValue);

    // LMidLen是中间的空隙数量
    for LMidLen := 1 to LSeriesLen - 10 do
    begin
      LCurMidFromIndex := 5;
      while LCurMidFromIndex + (LMidLen - 1) < LSeriesLen - 5 do
      begin

        // 判断左边的牌
        LCurValue := TCardValue(Ord(AMinCardValue) + LCurMidFromIndex - 1);
        LCurLeftInterval := GetCardIntervalByMinMaxValue(AMinCardValue, LCurValue);

        // 判断右边的牌
        LCurValue :=  TCardValue(Ord(AMinCardValue) + LCurMidFromIndex + LMidLen);
        LCurRighInterval := GetCardIntervalByMinMaxValue(LCurValue, AMaxCardValue);

        if LCurLeftInterval + LCurRighInterval > LMaxInterval then
        begin
          LMaxInterval := LCurLeftInterval + LCurRighInterval;

          RetMidFromIndex := LCurMidFromIndex;
          RetMidLen := LMidLen;
        end;
        
        Inc(LCurMidFromIndex);
      end;
    end;       
  end;

  // 检测是否需要把一个单顺拆分成2个
  procedure Split1SeriesBestSplitSeries;
  var
    I: Integer;
    LIndex: Integer;
    LSplitItem: TSplitCardItem;
    LSeriesLen: Integer;
    LMinCardValue, LMaxCardValue: TCardValue;
    LMidFromIndex, LMidLen: Integer;
    LDelCardAry: TGameCardAry;
  begin
    if Length(RetSplitAryAry[sct1Series]) < 1 then
      Exit;

    for I := Low(RetSplitAryAry[sct1Series]) to High(RetSplitAryAry[sct1Series]) do
    begin
      LSplitItem := RetSplitAryAry[sct1Series][I];
      LSeriesLen := LSplitItem.CardType.TypeNum.X;

      // 只有大于等于11的单顺才可能有必要拆分
      if LSeriesLen >= 11 then
      begin
        LMaxCardValue := LSplitItem.CardType.TypeValue.Value;
        LMinCardValue := LSplitItem.CardAry[LSeriesLen - 1].Value;

        // 检测是否需要拆分
        GetMaxIntervalByMinMaxValueForSplit(LMinCardValue, LMaxCardValue, LMidFromIndex, LMidLen);
        if LMidLen > 0 then
        begin
          // 选出要删除的牌
          SetLength(LDelCardAry, 0);
          AddGameCardAry(LSplitItem.CardAry, LMidFromIndex, LMidLen, LDelCardAry);

          // 把分离出来的小顺子，添加到一个新的顺子
          LIndex := Length(RetSplitAryAry[sct1Series]);
          SetLength(RetSplitAryAry[sct1Series], LIndex + 1);
          SetLength(RetSplitAryAry[sct1Series][LIndex].CardAry, 0);
          // 选出牌来
          AddGameCardAry(LSplitItem.CardAry, LMidFromIndex + LMidLen, LSeriesLen - (LMidFromIndex + LMidLen), RetSplitAryAry[sct1Series][LIndex].CardAry);
          // 牌型
          RetSplitAryAry[sct1Series][LIndex].CardType.TypeValue := RetSplitAryAry[sct1Series][LIndex].CardAry[0];
          LPTmpTypeNum := @RetSplitAryAry[sct1Series][LIndex].CardType.TypeNum;
          LPTmpTypeNum^.X := Length(RetSplitAryAry[sct1Series][LIndex].CardAry);
          LPTmpTypeNum^.M := 1;
          LPTmpTypeNum^.Y := 0;
          LPTmpTypeNum^.N := 0;

          // 从顺子中删除牌，并更新牌型
          DelCardFromCardAry(RetSplitAryAry[sct1Series][LIndex].CardAry, RetSplitAryAry[sct1Series][I].CardAry);
          DelCardFromCardAry(LDelCardAry, RetSplitAryAry[sct1Series][I].CardAry);
          // 牌型
          RetSplitAryAry[sct1Series][I].CardType.TypeNum.X := Length(RetSplitAryAry[sct1Series][I].CardAry);
          RetSplitAryAry[sct1Series][I].CardType.TypeValue := RetSplitAryAry[sct1Series][I].CardAry[0];

          // 添加到剩余牌
          AddCardToCardAry(LDelCardAry, LLeftCardAry);
        end;
      end;
    end;
  end;

  //  单顺的确定
  //      a) 选取五连，先取出最小的一个五连，再在剩余的牌中取出最小的一个五连，依此类推，直到没有五连为止。
  //      b) 扩展五连，将剩余的牌与已经取出的牌进行比对，如果某张剩余的牌与已知的连牌能组成更大的连牌，则将其合并。一直到无法合并为止。
  //      c) 合并连牌，如果某两组连牌能无缝连接成更大的连牌，则将其合并成一组。
  //      经过上述选取、扩展和合并，则将一手牌中的所有连牌提取出来了，举例如下：
  //        假定一手牌是：2AKQJ1099877766543
  //        第一步，选取出34567，678910两个连牌组。剩余的牌还有79JQKA2
  //        第二步，剩余的JQKA能和678910组成新的连牌678910JQKA。
  //        第三步，已知的两个连牌组不能合并成新的、更大的连牌组，则这手牌就被分成了34567、678910JQKA两个连牌组和7、9、2三张单牌。
  procedure CheckSplit1Series;
  begin
    if Length(LLeftCardAry) < 5 then
      Exit;

    // 取出所有5连
    Split1SeriesExtractAll5;
    // 扩展5连
    Split1SeriesExpand5;
    // 合并连牌
    Split1SeriesMerge;
    // 判断5连以上顶张的是否可以变成3条
    Split1SeriesCheckUnionThree;
    // 最优缩短连牌
    Split1SeriesBestDecLen;
    // 最优拆分连牌
    Split1SeriesBestSplitSeries;
    // 检测如果连牌不提出，把数会不会减少
    Split1SeriesCheckBaShu;
  end;

  procedure Split2SeriesMergeSame1Series;
  var
    I, J: Integer;
    LSelIndex, L1SeriesIndex: Integer;
    LAryIndex: Integer;
    LFixCardType, LCmpCardType: TLordCardType;
  begin
    if Length(RetSplitAryAry[sct1Series]) < 2 then
      Exit;

    L1SeriesIndex := High(RetSplitAryAry[sct1Series]);
    while L1SeriesIndex >= Low(RetSplitAryAry[sct1Series]) + 1 do
    begin
      LSelIndex := L1SeriesIndex;

      LFixCardType := RetSplitAryAry[sct1Series][L1SeriesIndex].CardType;
      for I := L1SeriesIndex - 1 downto Low(RetSplitAryAry[sct1Series]) do
      begin
        LCmpCardType := RetSplitAryAry[sct1Series][I].CardType;

        // 如果牌型相同，则可以合并
        if (LFixCardType.TypeNum.X = LCmpCardType.TypeNum.X) and (LFixCardType.TypeValue.Value = LCmpCardType.TypeValue.Value) then
        begin
          LSelIndex := I;
          Break;
        end;
      end;

      // 找到可以合并的项
      if LSelIndex <> L1SeriesIndex then
      begin
        // 找到双顺
        LAryIndex := Length(RetSplitAryAry[sct2Series]);
        SetLength(RetSplitAryAry[sct2Series], LAryIndex + 1);
        SetLength(RetSplitAryAry[sct2Series][LAryIndex].CardAry, 0);

        // 选出牌来
        CopyGameCardAry(RetSplitAryAry[sct1Series][L1SeriesIndex].CardAry, RetSplitAryAry[sct2Series][LAryIndex].CardAry);
        AddCardToCardAry(RetSplitAryAry[sct1Series][LSelIndex].CardAry, RetSplitAryAry[sct2Series][LAryIndex].CardAry);

        // 牌型
        RetSplitAryAry[sct2Series][LAryIndex].CardType.TypeValue := RetSplitAryAry[sct2Series][LAryIndex].CardAry[0];
        LPTmpTypeNum := @RetSplitAryAry[sct2Series][LAryIndex].CardType.TypeNum;
        LPTmpTypeNum^.X := RetSplitAryAry[sct1Series][LSelIndex].CardType.TypeNum.X;
        LPTmpTypeNum^.M := 2;
        LPTmpTypeNum^.Y := 0;
        LPTmpTypeNum^.N := 0;

        // 删除前面的位置
        for J := LSelIndex to High(RetSplitAryAry[sct1Series]) - 1 do
          RetSplitAryAry[sct1Series][J] := RetSplitAryAry[sct1Series][J + 1];
        Dec(L1SeriesIndex);

        // 删除合并的后面位置
        for J := L1SeriesIndex to High(RetSplitAryAry[sct1Series]) - 1 do
          RetSplitAryAry[sct1Series][J] := RetSplitAryAry[sct1Series][J + 1];
        Dec(L1SeriesIndex);
        
        SetLength(RetSplitAryAry[sct1Series], Length(RetSplitAryAry[sct1Series]) - 2);
      end else
      begin
        Dec(L1SeriesIndex);
      end;
    end;
  end;

  procedure Split2SeriesForLeftCard;
  var
    LIndex: Integer;
    LLastCard: TGameCard;
    LMaxCard: TGameCard;
    L2SeriesLen: Integer;
    LDelFromIndex: Integer;

    procedure CheckAdd2Series(ACurScanIndex: Integer);
    var
      J: Integer;
    begin
      if L2SeriesLen >= 3 then
      begin
        LIndex := Length(RetSplitAryAry[sct2Series]);
        SetLength(RetSplitAryAry[sct2Series], LIndex + 1);
        SetLength(RetSplitAryAry[sct2Series][LIndex].CardAry, 0);
        if LDelFromIndex = -1 then
          LDelFromIndex := LIndex;

        // 牌型
        RetSplitAryAry[sct2Series][LIndex].CardType.TypeValue := LMaxCard;
        LPTmpTypeNum := @RetSplitAryAry[sct2Series][LIndex].CardType.TypeNum;
        LPTmpTypeNum^.X := L2SeriesLen;
        LPTmpTypeNum^.M := 2;
        LPTmpTypeNum^.Y := 0;
        LPTmpTypeNum^.N := 0;

        // 选出牌来
        for J := L2SeriesLen downto 1 do
        begin
          AddGameCardAry(LLeftCardAry, LScanAry[ACurScanIndex - J].Index, 2, RetSplitAryAry[sct2Series][LIndex].CardAry);
        end;
      end;
    end;

  var
    I: Integer;
    LFromScanIndex: Integer;
  begin
    if Length(LLeftCardAry) < 6 then
      Exit;
      
    GetCardScanTable(LLeftCardAry, sccNone, LScanAry);
    DecSortCardScanAryByCount(LScanAry);

    // 从第一张牌对牌开始扫描
    LFromScanIndex := -1;
    for I := Low(LScanAry) to High(LScanAry) do
    begin
      if LScanAry[I].Count = 2 then
      begin
        LFromScanIndex := I;
        Break;
      end; 
    end;
    if LFromScanIndex < 0 then
      Exit;

    LDelFromIndex := -1;
    L2SeriesLen := 1;
    LLastCard := LScanAry[LFromScanIndex].Card;
    LMaxCard := LScanAry[LFromScanIndex].Card;
    for I := LFromScanIndex + 1 to High(LScanAry) do
    begin
      if LScanAry[I].Count < 2 then
      begin
        Break;
      end else if LScanAry[I].Count = 2 then
      begin
        // 2顺的第二个2张肯定小于A
        if LScanAry[I].Card.Value > scvK then
        begin
          L2SeriesLen := 1;
          LLastCard := LScanAry[I].Card;
          LMaxCard := LScanAry[I].Card;
        end else
        begin
          if (Ord(LLastCard.Value) - Ord(LScanAry[I].Card.Value)) = 1 then
          begin
            Inc(L2SeriesLen);
          end else
          begin
            // 检测是否选出一个2顺
            CheckAdd2Series(I);

            // 换了另外一个2顺
            L2SeriesLen := 1;
            LMaxCard := LScanAry[I].Card;
          end;
        end;

        LLastCard := LScanAry[I].Card;
      end;
    end;

    // 检测是否选出一个2顺
    CheckAdd2Series(I);

    // 去掉选出的牌
    if LDelFromIndex >= 0 then
    begin
      for I := LDelFromIndex to High(RetSplitAryAry[sct2Series]) do
      begin
        DelCardFromCardAry(RetSplitAryAry[sct2Series][I].CardAry, LLeftCardAry);
      end;
    end;
  end;

  //   下列情况下才重新组合
  //      [纯4连 5把]和并连牌后能分出[1双顺 <=3单]、[不可能: 1双顺 2连]、[1双顺 1连 <=2单]
  //      [纯3连 4把]和并连牌后能分出[1双顺 2单]、[不可能: 1双顺 2连]、[1双顺 1连 <=1单]
  //      [4连包含1双 5把]和并连牌后能分出[1双顺 <=2单]、[不可能: 1双顺 2连]、[1双顺 1连 <=1单]
  //      [4连含2双]和并连牌后能分出[1双顺 <=1单]、[1双顺 1连]
  //      [3连含1双]和并连牌后能分出[1双顺 1连]
  //      [4连含1三张 4把]和并连牌后能分出[1双顺 <=1单]、[1双顺 1连]  
  procedure ReUnion3_4(const Sel3_4CardAry: TGameCardAry; APairCount, AThreeCount: Integer;
    var DelCardAry, AddCardAry: TGameCardAry);

    procedure DoUnion3_4(AMinBaShu: Integer);
    var
      I, J: Integer;
      LIndex: Integer;
      LTmpCardType: TLordCardType;
      LSeriesLen: Integer;
      LCurBaShu: Integer;
      LMinBaShu: Integer;
      LTmpInt: Integer;
      LMinBaShuIndex: Integer;
      LMinCardValue, LMaxCardValue: TCardValue;
      LIntervalForMinCard, LIntervalForMaxCard: Integer;
    begin
      // 找到合并后把数最少的单顺下标
      LMinCardValue := Sel3_4CardAry[High(Sel3_4CardAry)].Value;
      LMaxCardValue := Sel3_4CardAry[0].Value;
      LMinBaShu := 0;
      LMinBaShuIndex := -1;
      for I := Low(RetSplitAryAry[sct1Series]) to High(RetSplitAryAry[sct1Series]) do
      begin
        LTmpCardType := RetSplitAryAry[sct1Series][I].CardType;
        LSeriesLen := LTmpCardType.TypeNum.X;
        LIntervalForMaxCard := Ord(LTmpCardType.TypeValue.Value) - Ord(LMaxCardValue);
        LIntervalForMinCard := Ord(LMinCardValue) - (Ord(LTmpCardType.TypeValue.Value) - LSeriesLen + 1);

        // 如果可以合并
        if (LIntervalForMaxCard >= 0) and (LIntervalForMinCard >= 0) then
        begin
          LCurBaShu := MaxInt;
          LTmpInt := LIntervalForMaxCard + LIntervalForMinCard;
          if LTmpInt < 5 then
          begin
            // 单顺比要合并的牌数多<5张以下，只能合并成 [双顺 + 单]
            LCurBaShu := 1 + (LIntervalForMaxCard + LIntervalForMinCard);
          end else if LTmpInt < 10 then
          begin
            // 单顺最大3-A 12张，LSelLen最少3，这样他们的差最大是9
            // 单顺比要合并的牌数多5-9张，能合并成 [双顺 + 单] [双顺 + 1连] [双顺 + 1连 + 单]
            if LIntervalForMinCard < 5 then
            begin
              if LIntervalForMaxCard < 5 then
                LCurBaShu := 1 + (LIntervalForMaxCard + LIntervalForMinCard)
              else
                LCurBaShu := 2 + LIntervalForMinCard;
            end else
            begin
              if LIntervalForMaxCard < 5 then
                LCurBaShu := 2 + LIntervalForMaxCard
              else
                LCurBaShu := 3;
            end;
          end;

          // 判断当前合并的把数是否小
          if LMinBaShu = 0 then
          begin
            LMinBaShu := LCurBaShu;
            LMinBaShuIndex := I;
          end else
          begin
            if LCurBaShu < LMinBaShu then
            begin
              LMinBaShu := LCurBaShu;
              LMinBaShuIndex := I;
            end;
          end;
        end;
      end;

      // 找到符合要求的把数
      if (LMinBaShu > 1) and (LMinBaShu <= AMinBaShu) then
      begin
        // 选出的牌要删除
        AddGameCardAry(Sel3_4CardAry, 0, Length(Sel3_4CardAry), DelCardAry);
        // 合并牌
        AddCardToCardAry(Sel3_4CardAry, RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry);

        LTmpCardType := RetSplitAryAry[sct1Series][LMinBaShuIndex].CardType;
        LSeriesLen := LTmpCardType.TypeNum.X;
        LIntervalForMaxCard := Ord(LTmpCardType.TypeValue.Value) - Ord(LMaxCardValue);
        LIntervalForMinCard := Ord(LMinCardValue) - (Ord(LTmpCardType.TypeValue.Value) - LSeriesLen + 1);

        // 增加双顺
        LIndex := Length(RetSplitAryAry[sct2Series]);
        SetLength(RetSplitAryAry[sct2Series], LIndex + 1);
        SetLength(RetSplitAryAry[sct2Series][LIndex].CardAry, 0);
        // 牌型
        RetSplitAryAry[sct2Series][LIndex].CardType.TypeValue := RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry[LIntervalForMaxCard];
        LPTmpTypeNum := @RetSplitAryAry[sct2Series][LIndex].CardType.TypeNum;
        LPTmpTypeNum^.X := Length(Sel3_4CardAry);
        LPTmpTypeNum^.M := 2;
        LPTmpTypeNum^.Y := 0;
        LPTmpTypeNum^.N := 0;
        // 选出牌来
        AddGameCardAry(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry, LIntervalForMaxCard,
         LPTmpTypeNum^.X + LPTmpTypeNum^.X, RetSplitAryAry[sct2Series][LIndex].CardAry);

        // 删除单顺中的双顺
        DelCardFromCardAry(RetSplitAryAry[sct2Series][LIndex].CardAry, RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry);

        // 散牌要回到剩余牌中
        if (LIntervalForMaxCard > 0) and (LIntervalForMaxCard < 5) then
        begin
          AddGameCardAry(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry, 0, LIntervalForMaxCard, AddCardAry);
          
          for J := 0 to High(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry) - LIntervalForMaxCard do
            RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry[J] := RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry[J + LIntervalForMaxCard];
          SetLength(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry, Length(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry) - LIntervalForMaxCard);
        end;
        
        LTmpInt := Length(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry);
        if (LIntervalForMinCard > 0) and (LIntervalForMinCard < 5) then
        begin
          AddGameCardAry(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry,
            LTmpInt - LIntervalForMinCard, LIntervalForMinCard, AddCardAry);
            
          SetLength(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry, Length(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry) - LIntervalForMinCard);
        end;

        // 如果剩余的牌还可以是5连以上
        LTmpInt := Length(RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry);
        if LTmpInt >= 5 then
        begin
          RetSplitAryAry[sct1Series][LMinBaShuIndex].CardType.TypeValue := RetSplitAryAry[sct1Series][LMinBaShuIndex].CardAry[0];
          LPTmpTypeNum := @RetSplitAryAry[sct1Series][LMinBaShuIndex].CardType.TypeNum;
          LPTmpTypeNum^.X := LTmpInt;
        end else
        begin
          // 删除单顺
          for I := LMinBaShuIndex to High(RetSplitAryAry[sct1Series]) - 1 do
            RetSplitAryAry[sct1Series][I] := RetSplitAryAry[sct1Series][I + 1];
          SetLength(RetSplitAryAry[sct1Series], Length(RetSplitAryAry[sct1Series]) - 1);
        end;
      end;
    end;
    
  var
    LLen: Integer;
    LMinBaShu: Integer;
  begin
    LMinBaShu := 0;
    LLen := Length(Sel3_4CardAry);
    if AThreeCount = 1 then
    begin
      if (APairCount = 0) and (LLen = 4) then
      begin
        // [4连含1三张 4把]和并连牌后能分出[1双顺 <=1单]、[1双顺 1连]
        LMinBaShu := 2;     
      end;
    end else if AThreeCount = 0 then
    begin
      if LLen = 4 then
      begin
        case APairCount of
          0: // [纯4连 5把]和并连牌后能分出[1双顺 <=3单]、[1双顺 2连]、[1双顺 1连 <=2单]
          begin
            LMinBaShu := 4;
          end;
          1: // [4连包含1双 5把]和并连牌后能分出[1双顺 <=2单]、[1双顺 2连]、[1双顺 1连 <=1单]
          begin
            LMinBaShu := 3;
          end;
          2: // [4连含2双]和并连牌后能分出[1双顺 <=1单]、[1双顺 1连]
          begin
            LMinBaShu := 2;
          end;
        end;
      end else if LLen = 3 then
      begin
        if APairCount = 0 then
        begin
          // [纯3连 4把]和并连牌后能分出[1双顺 2单]、[1双顺 2连]、[1双顺 1连 <=1单]
          LMinBaShu := 3;
        end else if APairCount = 1 then
        begin
          // [3连含1双]和并连牌后能分出[1双顺 1连]
          LMinBaShu := 2;
        end;
      end;
    end;

    if LMinBaShu > 1 then
      DoUnion3_4(LMinBaShu);
  end;

  procedure Split2SeriesMerge3_4(AMergeCount: Integer);
  var
    LSel3_4CardAry: TGameCardAry;
    LCardCountAry: array of Integer;
    LPairCount, LThreeCount: Integer;

    procedure GetSelCardCountAry;
    var
      I, J: Integer;
      LTmpCard: TGameCard;
    begin
      SetLength(LCardCountAry, Length(LSel3_4CardAry));
      GetCardScanTable(LLeftCardAry, sccNone, LScanAry);
      DecSortCardScanAryByCount(LScanAry);
      for I := Low(LSel3_4CardAry) to High(LSel3_4CardAry) do
      begin
        LTmpCard := LSel3_4CardAry[I];

        LCardCountAry[I] := 1;
        for J := Low(LScanAry) to High(LScanAry) do
        begin
          if LScanAry[I].Count < 2 then
            Break;
          if LScanAry[I].Card.Value = LTmpCard.Value then
          begin
            LCardCountAry[I] := LScanAry[I].Count;
            Break;
          end;
        end;
      end;
    end;

    function Get2_3Count: Boolean;
    var
      I: Integer;
    begin
      LPairCount := 0;
      LThreeCount := 0;
      for I := Low(LCardCountAry) to High(LCardCountAry) do
      begin
        if LCardCountAry[I] = 2 then
          Inc(LPairCount)
        else if LCardCountAry[I] = 3 then
          Inc(LThreeCount);
      end;

      if Length(LCardCountAry) = 3 then
      begin
        // 纯3连，3连中含一对
        Result := (LThreeCount = 0) and (LPairCount <= 1);
      end else
      begin
        if (LThreeCount = 0) then
          Result := (LPairCount <= 2)
        else
          Result := (LThreeCount = 1) and (LPairCount = 0);
      end;
    end;

  var
    I: Integer;
    LFromSearchIndex: Integer;
    LLastCard: TGameCard;
    L1SeriesLen: Integer;
    LTmpCardAry: TGameCardAry;
    LDelCardAry, LAddCardAry: TGameCardAry;
  begin
    if Length(RetSplitAryAry[sct1Series]) < 1 then
      Exit;
      
    SetLength(LDelCardAry, 0);
    SetLength(LAddCardAry, 0);
    SetLength(LTmpCardAry, AMergeCount);
    LFromSearchIndex := High(LLeftCardAry);
    while True do
    begin
      if Length(LLeftCardAry) < AMergeCount then
        Break;
      if LFromSearchIndex < AMergeCount - 1 then
        Break;
      if Length(RetSplitAryAry[sct1Series]) < 1 then
        Break;

      L1SeriesLen := 1;
      LLastCard := LLeftCardAry[LFromSearchIndex];
      LTmpCardAry[AMergeCount - L1SeriesLen] := LLeftCardAry[LFromSearchIndex];
      for I := LFromSearchIndex - 1 downto Low(LLeftCardAry) do
      begin
        // 单顺的最大牌肯定小于等于A
        if LLeftCardAry[I].Value > scvBA then
        begin
          LFromSearchIndex := 0;
          Break;
        end else
        begin
          // 判断是否是连续序列
          if LLeftCardAry[I].Value = LLastCard.Value then
          begin
            Continue;
          end else if Ord(LLeftCardAry[I].Value) - Ord(LLastCard.Value) = 1 then
          begin
            Inc(L1SeriesLen);
            LTmpCardAry[AMergeCount - L1SeriesLen] := LLeftCardAry[I];

            // 下次从第二个连续的开始找
            if L1SeriesLen = 2 then
              LFromSearchIndex := I;
              
            // 找到4连
            if L1SeriesLen >= AMergeCount then
            begin
              Break;
            end;
          end else
          begin
            LFromSearchIndex := I - 1;

            L1SeriesLen := 1;
            LTmpCardAry[AMergeCount - L1SeriesLen] := LLeftCardAry[I];
          end;
        end;

        LLastCard := LLeftCardAry[I];
      end;

      if L1SeriesLen <> AMergeCount then
        Break;

      // 复制牌
      SetLength(LSel3_4CardAry, 0);
      InsertGameCardAry(LTmpCardAry, 0, 0, L1SeriesLen, LSel3_4CardAry);

      // 获得连牌中每张牌的相同数量
      GetSelCardCountAry;
      // 获得2、3张在连牌中的数量 并判断是否可以重新组合
      if Get2_3Count then
      begin
        ReUnion3_4(LSel3_4CardAry, LPairCount, LThreeCount, LDelCardAry, LAddCardAry);  
      end;
    end;

    // 删除一部分牌，添加一部分牌
    if Length(LDelCardAry) > 0 then
    begin
      DecSortCardAryByValue(LDelCardAry);
      DelCardFromCardAry(LDelCardAry, LLeftCardAry);
    end;
    if Length(LAddCardAry) > 0 then
    begin
      AddGameCardAry(LAddCardAry, 0, Length(LAddCardAry), LLeftCardAry);
      DecSortCardAryByValue(LLeftCardAry);
    end;
  end;

  // 确定双顺：
  // 首先，如果两单顺牌完全重合，则将其重新组合成双顺。
  // 其次，在除炸弹、三顺、三条、单顺以外的牌中检测是否包含双顺。
  //      如果有，将其提取出来；
  // 再检测连续牌 3连和4连
  //     （可能会拆对牌或3张，
  //      [纯4连 5把]和并连牌后能分出[1双顺 <=3单]、[1双顺 2连]、[1双顺 1连 <=2单]
  //      [纯3连 4把]和并连牌后能分出[1双顺 2单]、[1双顺 2连]、[1双顺 1连 <=1单]
  //      [4连包含1双 5把]和并连牌后能分出[1双顺 <=2单]、[1双顺 2连]、[1双顺 1连 <=1单]
  //      [4连含2双]和并连牌后能分出[1双顺 <=1单]、[1双顺 1连]
  //      [3连含1双]和并连牌后能分出[1双顺 1连]
  //      [4连含1三张 4把]和并连牌后能分出[1双顺 <=1单]、[1双顺 1连]
  //      ）
  //    和每个单顺的组合，如果组合后把数减少， 则把单顺和连续单组合成双顺。
  procedure CheckSplit2Series;
  begin
    if (Length(RetSplitAryAry[sct1Series]) = 0) and (Length(LLeftCardAry) < 6) then
      Exit;
    if Length(LLeftCardAry) < 3 then
      Exit;

    // 合并完全重合的单顺为双顺
    Split2SeriesMergeSame1Series;
    // 看剩余的牌里面是否有双顺，排除3张
    Split2SeriesForLeftCard;
    // 检测3连和4连是否可以和顺子合并为双顺
    Split2SeriesMerge3_4(4);
    Split2SeriesMerge3_4(3);
  end;

  // 选出4、3、2、1条
  procedure CheckSplit4321(ACardCount: Integer; ASplitType: TSplitCardType);
  var
    I: Integer;
    LIndex: Integer;
    LDelFromIndex: Integer;
  begin
    if Length(LLeftCardAry) < ACardCount then
      Exit;

    LDelFromIndex := -1;
    GetCardScanTable(LLeftCardAry, sccNone, LScanAry);
    DecSortCardScanAryByCount(LScanAry);
    for I := Low(LScanAry) to High(LScanAry) do
    begin
      if LScanAry[I].Count <> ACardCount then
      begin
        Break;
      end else
      begin
        LIndex := Length(RetSplitAryAry[ASplitType]);
        SetLength(RetSplitAryAry[ASplitType], LIndex + 1);
        SetLength(RetSplitAryAry[ASplitType][LIndex].CardAry, 0);
        if LDelFromIndex = -1 then
          LDelFromIndex := LIndex;

        // 牌型
        RetSplitAryAry[ASplitType][LIndex].CardType.TypeValue := LScanAry[I].Card;
        LPTmpTypeNum := @RetSplitAryAry[ASplitType][LIndex].CardType.TypeNum;
        LPTmpTypeNum^.X := 1;
        LPTmpTypeNum^.M := ACardCount;
        LPTmpTypeNum^.Y := 0;
        LPTmpTypeNum^.N := 0;

        // 选出牌
        AddGameCardAry(LLeftCardAry, LScanAry[I].Index, ACardCount, RetSplitAryAry[ASplitType][LIndex].CardAry);
      end;
    end;

    // 去掉选出的牌
    if LDelFromIndex >= 0 then
    begin
      for I := LDelFromIndex to High(RetSplitAryAry[ASplitType]) do
      begin
        DelCardFromCardAry(RetSplitAryAry[ASplitType][I].CardAry, LLeftCardAry);
      end;
    end;
  end;

  // 检测炸弹是否可以拆分成顺子 尝试加入单个炸弹，然后找最长的顺子
  //      （可能会拆对牌或3张，
  //        [+炸弹5连 ]和并连牌后能分出 [1顺 1三条 单张 对牌] ，最多拆分1对    5 – 1=4 > 3
  //        [+炸弹5连以上时，保证 总连牌数 -（对牌数 + 三条数*2）>  3
  //       ）

  procedure CheckSplitBombAs1Series;
  var
    LTmpLeftCardAry: TGameCardAry;
    LBombCardValue: TCardValue;
    LSearchSuccess: Boolean;
    LIsIncludeBomb: Boolean;
    LSelCardAry: TGameCardAry;

    procedure AddBombSearch1Series;
    var
      I: Integer;
      LLastCard: TGameCard;
      L1SeriesLen: Integer;
      LTmpCardAry: TGameCardAry;
      LSameCardCount: Integer;
      LPairCardCount: Integer;
      LThreeCardCount: Integer;
      LBestSuccssLen: Integer;
      LBestInterval: Integer;

      procedure CheckSearchSucces;
      var
        LCurInterval: Integer;
      begin
        // 统计对子和3张的数量
        if LSameCardCount = 2 then
          Inc(LPairCardCount)
        else if LSameCardCount = 3 then
          Inc(LThreeCardCount);

        // 判断对子和3张的数量
        if L1SeriesLen >= 5 then
        begin
          LCurInterval := (L1SeriesLen - (LPairCardCount + LThreeCardCount + LThreeCardCount));

          LIsIncludeBomb := (LBombCardValue <= LTmpCardAry[12 - L1SeriesLen].Value)
            and (LBombCardValue >= LTmpCardAry[High(LTmpCardAry)].Value);
            
          if not LIsIncludeBomb then
            LSearchSuccess := LCurInterval > 1
          else
            LSearchSuccess := LCurInterval > 3;

          if LSearchSuccess then
          begin
            // 如果这次搜索成功，并且比最好的要好
            if (LBestSuccssLen = 0) or (LCurInterval > LBestInterval) then
            begin
              LBestSuccssLen := L1SeriesLen;
              LBestInterval := LCurInterval;
            end;
          end;
        end;
      end;
      
    begin
      // 初始化
      LSearchSuccess := False;
      LIsIncludeBomb := False;
      SetLength(LTmpCardAry, 12);
      SetLength(LSelCardAry, 0);

      // 统计用
      LSameCardCount := 1;
      LPairCardCount := 0;
      LThreeCardCount := 0;
      
      LBestSuccssLen := 0;
      LBestInterval := 0;
      
      L1SeriesLen := 1;
      LLastCard := LTmpLeftCardAry[High(LTmpLeftCardAry)];
      LTmpCardAry[12 - L1SeriesLen] := LTmpLeftCardAry[High(LTmpLeftCardAry)];
      for I := High(LTmpLeftCardAry) - 1 downto Low(LTmpLeftCardAry) do
      begin
        // 单顺的最大牌肯定小于等于A
        if LTmpLeftCardAry[I].Value > scvBA then
        begin
          CheckSearchSucces;
          Break;
        end else
        begin
          // 判断是否是连续序列
          if LTmpLeftCardAry[I].Value = LLastCard.Value then
          begin
            // 累计牌张数
            Inc(LSameCardCount);

            // 如果是最后一张，需要判断是否查找成功
            if I = Low(LTmpLeftCardAry) then
              CheckSearchSucces;
                          
            Continue;
          end else if Ord(LTmpLeftCardAry[I].Value) - Ord(LLastCard.Value) = 1 then
          begin
            CheckSearchSucces;

            // 清空牌张数统计
            LSameCardCount := 1;
            Inc(L1SeriesLen);
            LTmpCardAry[12 - L1SeriesLen] := LTmpLeftCardAry[I];
          end else
          begin
            CheckSearchSucces;
            
            // 找到一个5连退出
            if L1SeriesLen >= 5 then
              Break;

            // 重新开始统计
            LPairCardCount := 0;
            LThreeCardCount := 0;
            // 清空牌张数统计
            LSameCardCount := 1;
            L1SeriesLen := 1;
            LTmpCardAry[12 - L1SeriesLen] := LTmpLeftCardAry[I];
          end;
        end;

        LLastCard := LTmpLeftCardAry[I];
      end;

      if LSearchSuccess then
      begin
        L1SeriesLen := LBestSuccssLen;
       
        // 复制牌
        SetLength(LSelCardAry, 0);
        AddGameCardAry(LTmpCardAry, 12 - L1SeriesLen, L1SeriesLen, LSelCardAry);
      end;
    end;

    procedure Add1SeriesToList;
    var
      LIndex: Integer;
    begin
       // 找到5张顺子
      LIndex := Length(RetSplitAryAry[sct1Series]);
      SetLength(RetSplitAryAry[sct1Series], LIndex + 1);
      SetLength(RetSplitAryAry[sct1Series][LIndex].CardAry, 0);

      // 牌型
      RetSplitAryAry[sct1Series][LIndex].CardType.TypeValue := LSelCardAry[0];
      LPTmpTypeNum := @RetSplitAryAry[sct1Series][LIndex].CardType.TypeNum;
      LPTmpTypeNum^.X := Length(LSelCardAry);
      LPTmpTypeNum^.M := 1;
      LPTmpTypeNum^.Y := 0;
      LPTmpTypeNum^.N := 0;

      // 选出牌来
      CopyGameCardAry(LSelCardAry, RetSplitAryAry[sct1Series][LIndex].CardAry);
    end;
    
  var
    I, J: Integer;
    LChangeBomb: Boolean;
  begin
    LChangeBomb := False;
    if Length(LLeftCardAry) < 4 then
      Exit;
    if Length(RetSplitAryAry[sctBomb]) < 1 then
      Exit;

    I := Low(RetSplitAryAry[sctBomb]);
    while I <= High(RetSplitAryAry[sctBomb]) do
    begin
      if Length(LLeftCardAry) < 4 then
        Break;
      LBombCardValue := RetSplitAryAry[sctBomb][I].CardType.TypeValue.Value;
      
      // 一直找顺子，直到找到包含炸弹的顺子
      LSearchSuccess := True;
      LIsIncludeBomb := False;
      while LSearchSuccess do
      begin
        CopyGameCardAry(LLeftCardAry, LTmpLeftCardAry);
        AddCardToCardAry(RetSplitAryAry[sctBomb][I].CardAry, LTmpLeftCardAry);
        AddBombSearch1Series;
        if LIsIncludeBomb then
          Break;

        if LSearchSuccess then
        begin
          // 添加单顺牌型到单顺列表
          Add1SeriesToList;
          // 在剩余牌中去掉添加的单顺
          DelCardFromCardAry(LSelCardAry, LLeftCardAry);
        end;
      end;

      if LSearchSuccess and LIsIncludeBomb then
      begin
        LChangeBomb := True;
        
        // 在剩余牌中添加炸弹, 如果不先添加牌，删除单顺时会失败！！
        AddCardToCardAry(RetSplitAryAry[sctBomb][I].CardAry, LLeftCardAry);
        // 添加单顺牌型到单顺列表
        Add1SeriesToList;
        // 在剩余牌中去掉添加的单顺
        DelCardFromCardAry(LSelCardAry, LLeftCardAry);
        // 删除炸弹列表中的炸弹
        for J := I to High(RetSplitAryAry[sctBomb]) - 1 do
          RetSplitAryAry[sctBomb][J] := RetSplitAryAry[sctBomb][J + 1];
        SetLength(RetSplitAryAry[sctBomb], Length(RetSplitAryAry[sctBomb]) - 1);
      end else
      begin
        Inc(I);
      end;       
    end;

    // 因为如果炸弹变成顺子，改变了顺子，所以要处理
    if LChangeBomb then
    begin
      // 最优缩短连牌
      Split1SeriesBestDecLen;
      // 最优拆分连牌
      Split1SeriesBestSplitSeries;
      // 因为可能改变了炸弹，所以要再选择一次炸弹
      CheckSplit4321(4, sctBomb);
    end;
  end;

  // 选出对子
  procedure CheckSplitPair;
  begin
    if Length(LLeftCardAry) < 2 then
      Exit;
  end;

  // 选出单张
  procedure CheckSplitSingle;
  begin
    if Length(LLeftCardAry) < 1 then
      Exit;
  end;

  // 对分离出的每个牌型，从大到小排序
  procedure DecSortSplitAry;
  var
    LSplitType: TSplitCardType;
    I, J: Integer;
    LLen: Integer;
    LMaxIndex: Integer;
    LTmpItem: TSplitCardItem;
  begin
    for LSplitType := Low(RetSplitAryAry) to High(RetSplitAryAry) do
    begin
      LLen := Length(RetSplitAryAry[LSplitType]);
      Inc(Result, LLen);
      if LLen > 1 then
      begin
        for I := Low(RetSplitAryAry[LSplitType]) to High(RetSplitAryAry[LSplitType]) - 1 do
        begin
          LMaxIndex := I;
          
          for J := I + 1 to High(RetSplitAryAry[LSplitType]) do
          begin
            if CompareACard(RetSplitAryAry[LSplitType][J].CardType.TypeValue,
              RetSplitAryAry[LSplitType][LMaxIndex].CardType.TypeValue) > 0 then
            begin
              LMaxIndex := J;
            end;
          end;
    
          if LMaxIndex <> I then
          begin
            LTmpItem := RetSplitAryAry[LSplitType][LMaxIndex];
            RetSplitAryAry[LSplitType][LMaxIndex] := RetSplitAryAry[LSplitType][I];
            RetSplitAryAry[LSplitType][I] := LTmpItem;
          end;
        end;
      end;
    end;
  end;

begin
  Result := 0;

  InitVar;
  if IsCardAryHasBackCard(ADecSortCardAry) then
    Exit;

  CheckSplitRocket;
  CheckSplit4321(4, sctBomb);
  CheckSplit3Series;
  CheckSplit1Series;
  CheckSplit2Series;
  CheckSplitBombAs1Series;
  CheckSplit4321(3, sctThree);
  CheckSplit4321(2, sctPair);
  CheckSplit4321(1, sctSingle);
  
  DecSortSplitAry;
end;

function TTemplateGameLogicProc.DoUserFirstDiscard(
  var UserCard: TGameCardAryAry; ACurPlace, ALordPlace: Integer;
  var RetCardAry: TGameCardAry): Boolean;
var
  LPartnerPlace: Integer;           // 农民的同伙的方位
  LIsSelfLordPrevious: Boolean;     // 自己是否是地主上家
  LLordPreviousPlace, LLordNextPlace: Integer;    // 地主上家、地主下家的方位
  LCurUserCard: TGameCardAry;                     // 自己的牌
  LCurUserScanAry: TCardScanItemAry;              // 自己牌的扫描表
  LCurPlaceSplit: TSplitCardAryAry;               // 自己牌的拆分表
  LTakeCardSplit: TSplitCardAryAry;               // 自己的牌拆分后带牌处理

  function CheckParams: Boolean;
  var
    I: Integer;
  begin
    Result := False;
    if Length(UserCard) <> 3 then
      Exit;

    for I := Low(UserCard) to High(UserCard) do
    begin
      if Length(UserCard[I]) < 1 then
        Exit;
      if IsCardAryHasBackCard(UserCard[I]) then
        Exit;

      DecSortCardAryByValue(UserCard[I]);
    end;
    
    if not IsTemplatePlaceValid(ACurPlace) then
      Exit;
    if not IsTemplatePlaceValid(ALordPlace) then
      Exit;

    CopyGameCardAry(UserCard[ACurPlace], LCurUserCard);
    GetCardScanTable(UserCard[ACurPlace], sccNone, LCurUserScanAry);
    DecSortCardScanAryByCount(LCurUserScanAry);

    LLordNextPlace := (ALordPlace + 1) mod CTEMPLATE_MAX_USER_COUNT;
    LLordPreviousPlace := (ALordPlace + 2) mod CTEMPLATE_MAX_USER_COUNT;
    
    if ACurPlace = ALordPlace then
    begin
      LIsSelfLordPrevious := False;
      LPartnerPlace := -1;
    end else
    begin
      if (ACurPlace + 1) mod CTEMPLATE_MAX_USER_COUNT = ALordPlace then
      begin
        LIsSelfLordPrevious := True;
        LPartnerPlace := (ACurPlace + 2) mod CTEMPLATE_MAX_USER_COUNT;
      end else
      begin
        LIsSelfLordPrevious := False;
        LPartnerPlace := (ACurPlace + 1) mod CTEMPLATE_MAX_USER_COUNT;      
      end;
    end;

    Result := True;
  end;

  function CheckFetchOutAll: Boolean;
  var
    LCardType: TLordCardType;
  begin
    Result := True;

    // 排除双王和其他牌型一块出去
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      if Length(LCurUserCard) > 2 then
      begin
        Result := False;
      end;
    end;
    
    if Result then
    begin
      CheckCardType(LCurUserCard, LCardType);
      Result := IsCardTypeValid(LCardType);
    end;

    if Result then
      CopyGameCardAry(LCurUserCard, RetCardAry);
  end;

  function CheckHasBiggerCard(const ACmpType: TLordCardType; APlace: Integer): Boolean;
  var
    LNewCardType: TLordCardType;
    LNewCardAry: TGameCardAry;
  begin
    GetHintBiggerCard(ACmpType, UserCard[APlace], True, ACmpType.TypeValue, LNewCardType, LNewCardAry);
    Result := IsCardTypeValid(LNewCardType);
  end;

  function CheckBiShaFetchOutAll: Boolean;
  var
    I, J: Integer;
    LSplitType: TSplitCardType;
    LSmallBaShu: Integer;
    LSmallSplitType: TSplitCardType;
    LSmallSpiitIndex: Integer;
    LTmpCardAry: TGameCardAry;
    LOldCardType: TLordCardType;
  begin
    Result := True;

    LSmallBaShu := 0;
    LSmallSplitType := sctRocket;
    LSmallSpiitIndex := -1;
    
    for LSplitType := High(LTakeCardSplit) downto Low(LTakeCardSplit) do
    begin
      if Length(LTakeCardSplit[LSplitType]) > 0 then
      begin
        for I := High(LTakeCardSplit[LSplitType]) downto Low(LTakeCardSplit[LSplitType]) do
        begin
          // 获得1把牌
          CopyGameCardAry(LTakeCardSplit[LSplitType][I].CardAry, LTmpCardAry);
          if Length(LTakeCardSplit[LSplitType][I].TakesCard) > 0 then
          begin
            AddGameCardAry(LTakeCardSplit[LSplitType][I].TakesCard, 0,
              Length(LTakeCardSplit[LSplitType][I].TakesCard), LTmpCardAry);
            DecSortCardAryByValue(LTmpCardAry);
          end;

          CheckCardType(LTmpCardAry, LOldCardType);

          for J := Low(UserCard) to High(UserCard) do
          begin
            if J = ACurPlace then
              Continue;
            // 只要有一个人有比自己大的牌就可以
            if CheckHasBiggerCard(LOldCardType, J) then
            begin
              Inc(LSmallBaShu);

              // 记录第一次小牌
              if LSmallBaShu = 1 then
              begin
                LSmallSplitType := LSplitType;
                LSmallSpiitIndex := I;
              end else
              begin
                // 如果有2把及以上的牌小，则必杀失败
                Result := False;
                Exit;
              end;

              Break;
            end;
          end;
        end;
      end;
    end;

    if Result then
    begin
      for LSplitType := High(LTakeCardSplit) downto Low(LTakeCardSplit) do
      begin
        if Length(LTakeCardSplit[LSplitType]) > 0 then
        begin
          for I := High(LTakeCardSplit[LSplitType]) downto Low(LTakeCardSplit[LSplitType]) do
          begin
            if (LSplitType = LSmallSplitType) and (LSmallSpiitIndex = I) then
              Continue;

            // 成功获得1把牌
            CopyGameCardAry(LTakeCardSplit[LSplitType][I].CardAry, RetCardAry);
            if Length(LTakeCardSplit[LSplitType][I].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[LSplitType][I].TakesCard, 0,
                Length(LTakeCardSplit[LSplitType][I].TakesCard), RetCardAry);
              DecSortCardAryByValue(RetCardAry);
            end;

            Exit;
          end;
        end;
      end;
    end;
  end;

  // 判断牌是否为单张或者对子
  function IsCardAryPairOrSingle(APlace: Integer): Boolean;
  var
    LCardLen: Integer;
  begin
    Result := False;

    LCardLen := Length(UserCard[APlace]);
    if LCardLen > 2 then
      Exit;
    if LCardLen = 2 then
    begin
      if UserCard[APlace][0].Value <> UserCard[APlace][1].Value then
        Exit;
    end;

    Result := True;
  end;

  function CheckSelfFarmerAndPartnerPairOrSingle: Boolean;
  var
    LPartnerCardLen: Integer;

    // 看看自己是否可以顺同伙走
    function CheckShunPaiForPartner(ALordCardValue, APartnerCardValue: TCardValue): Boolean;
    var
      I: Integer;
      LTmpValue: TCardValue;
    begin
      Result := False;

      if APartnerCardValue <= ALordCardValue then
        Exit;
        
      for I := High(LCurUserScanAry) downto Low(LCurUserScanAry) do
      begin
        if LCurUserScanAry[I].Count >= LPartnerCardLen then
        begin
          LTmpValue := LCurUserScanAry[I].Card.Value;
          if (LTmpValue >= ALordCardValue) and (LTmpValue < APartnerCardValue) then
          begin
            AddGameCardAry(UserCard[ACurPlace], LCurUserScanAry[I].Index, LPartnerCardLen, RetCardAry);

            Result := True;
            Break;
          end;
        end;
      end;
    end;

  begin
    Result := False;

    // 检测条件：自己是农民，并且同伙剩余1对牌、一张牌
    if ACurPlace = ALordPlace then
      Exit;
    LPartnerCardLen := Length(UserCard[LPartnerPlace]);
    if not IsCardAryPairOrSingle(LPartnerPlace) then
      Exit;

    if not LIsSelfLordPrevious then
    begin
      Result := CheckShunPaiForPartner(scvNone, UserCard[LPartnerPlace][0].Value);
    end else
    begin
      if (not IsCardAryPairOrSingle(ALordPlace))
        or (Length(UserCard[ALordPlace]) <> LPartnerCardLen) then
      begin
        // 地主不是单张和对子 或者同伙和地主牌数量不同
        Result := CheckShunPaiForPartner(scvNone, UserCard[LPartnerPlace][0].Value);      
      end else
      begin
        // 地主和同伙剩余牌型相同
        Result := CheckShunPaiForPartner(UserCard[ALordPlace][0].Value, UserCard[LPartnerPlace][0].Value);      
      end;
    end;
  end;

  // 获得倒数第二大的单牌
  function GetSingleCardAry2FromLast(var SingleCardAry: TGameCardAry): Boolean;
  var
    I: Integer;
  begin
    Result := False;

    for I := High(LTakeCardSplit[sctSingle]) - 1 downto Low(LTakeCardSplit[sctSingle]) do
    begin
      CopyGameCardAry(LTakeCardSplit[sctSingle][I].CardAry, SingleCardAry);
      Result := True;
      Break;
    end;
  end;

  // 获得倒数第二大的对牌
  function GetPairCardAry2FromLast(var PairCardAry: TGameCardAry): Boolean;
  var
    I: Integer;
  begin
    Result := False;

    for I := High(LTakeCardSplit[sctPair]) - 1 downto Low(LTakeCardSplit[sctPair]) do
    begin
      CopyGameCardAry(LTakeCardSplit[sctPair][I].CardAry, PairCardAry);
      Result := True;
      Break;
    end;
  end;

  // 获得一手最小的牌
  function Get1BaMinCardAry(AFromSplit, AToSplit: TSplitCardType;
    AMinValue, AMaxValue: TCardValue; var Ret1Ba: TGameCardAry): Boolean;
  var
    I: TSplitCardType;
    J: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    
    if AFromSplit <= AToSplit then
    begin
      for I := AFromSplit to AToSplit do
      begin
        for J := High(LTakeCardSplit[I]) downto Low(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end else
    begin
      for I := AFromSplit downto AToSplit do
      begin
        for J := High(LTakeCardSplit[I]) downto Low(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  // 获得一手最大的牌
  function Get1BaMaxCardAry(AFromSplit, AToSplit: TSplitCardType;
    AMinValue, AMaxValue: TCardValue; var Ret1Ba: TGameCardAry): Boolean;
  var
    I: TSplitCardType;
    J: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    
    if AFromSplit <= AToSplit then
    begin
      for I := AFromSplit to AToSplit do
      begin
        for J := Low(LTakeCardSplit[I]) to High(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end else
    begin
      for I := AFromSplit downto AToSplit do
      begin
        for J := Low(LTakeCardSplit[I]) to High(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  function GetMinCardAry(var RetMinCard: TGameCardAry; AFromSplit: TSplitCardType): Boolean;
  var
    I: TSplitCardType;
    J: Integer;
    LIndex: Integer;
    LCurValue: TCardValue;
    LMinSplit: TSplitCardType;
    LMinIndex: Integer;
    LMinCardValue: TCardValue;
  begin
    LMinCardValue := scvNone;
    LMinSplit := sctSingle;
    LMinIndex := -1;

    // 获得3张以上的牌型    
    for I := AFromSplit downto sct3Series do
    begin
      for J := High(LTakeCardSplit[I]) downto Low(LTakeCardSplit[I]) do
      begin
        LIndex := High(LTakeCardSplit[I][J].CardAry);
        LCurValue := LTakeCardSplit[I][J].CardAry[LIndex].Value;

        if (LMinCardValue = scvNone) or (LCurValue < LMinCardValue) then
        begin
          LMinCardValue := LCurValue;
          LMinSplit := I;
          LMinIndex := J;
        end;
      end;
    end;
    Result := (LMinCardValue <> scvNone);
    // 再获得最小的炸弹
    if not Result then
    begin
      for I := sctBomb downto sctRocket do
      begin
        if Length(LTakeCardSplit[I]) > 0 then
        begin
          LMinSplit := I;
          LMinIndex := High(LTakeCardSplit[I]);
          
          Result := True;
          Break;
        end;
      end;
    end;

    if Result then
    begin
      CopyGameCardAry(LTakeCardSplit[LMinSplit][LMinIndex].CardAry, RetMinCard);
      if Length(LTakeCardSplit[LMinSplit][LMinIndex].TakesCard) > 0 then
      begin
        AddGameCardAry(LTakeCardSplit[LMinSplit][LMinIndex].TakesCard, 0, Length(LTakeCardSplit[LMinSplit][LMinIndex].TakesCard), RetMinCard);
        DecSortCardAryByValue(RetMinCard);
      end;
    end;
  end;

  // 地主出牌，农民一个剩余一张，另一个剩余一对牌
  function DoSelfLordAndEnemy1_2: Boolean;
  begin
    // 如果有倒数第二大的单牌，则出单牌
    Result := GetSingleCardAry2FromLast(RetCardAry);
    // 如果有倒数第二大的对牌，则出对牌
    if not Result then
      Result := GetPairCardAry2FromLast(RetCardAry);
    // 如果手里只剩下1个单牌和1个对牌，则出牌值较大的牌型
    if not Result then
    begin
      if (Length(LTakeCardSplit[sctSingle]) = 1) and (Length(LTakeCardSplit[sctPair]) = 1) then
      begin
        if LTakeCardSplit[sctPair][0].CardType.TypeValue.Value > LTakeCardSplit[sctSingle][0].CardType.TypeValue.Value then
          Result := Get1BaMinCardAry(sctPair, sctPair, Low(TCardValue), High(TCardValue), RetCardAry)
        else
          Result := Get1BaMinCardAry(sctSingle, sctSingle, Low(TCardValue), High(TCardValue), RetCardAry)
      end;
    end;
    // 如果手里还有除了单牌和对牌的牌型，则出之
    if not Result then
      Result := Get1BaMinCardAry(sctThree, Low(TSplitCardType), Low(TCardValue), High(TCardValue), RetCardAry);
  end;

  // 地主出牌，如果农民剩余单牌，先出带牌之外的倒数第二大的单牌，再从小到大出其他牌型
  function DoSelfLordAndOneFarmer1Card: Boolean;
  var
    LFarmerMinLen: Integer;
  begin
    LFarmerMinLen := Length(UserCard[LLordPreviousPlace]);
    if Length(UserCard[LLordNextPlace]) < LFarmerMinLen then
      LFarmerMinLen := Length(UserCard[LLordNextPlace]);

    if LFarmerMinLen = 1 then
    begin
      Result := GetSingleCardAry2FromLast(RetCardAry);
      if not Result then
        Result := GetMinCardAry(RetCardAry, sctPair);
    end else
    begin
      Result := False;
    end;
  end;

  // 对手剩余对牌
  // 先出单牌(不包括2和王)
  // 再拆对出单（不包括2和王）
  // 再出小于炸弹的牌型
  // 再出2或者王单
  // 再出2的对
  // 再出炸弹以上的牌型
  function DoEnemyPair: Boolean;
  begin
    Result := Get1BaMinCardAry(sctSingle, sctSingle, Low(TCardValue), scvBA, RetCardAry);
    if not Result then
    begin
      Result := Get1BaMinCardAry(sctPair, sctPair, Low(TCardValue), scvBA, RetCardAry);
      if Result then
        SetLength(RetCardAry, 1);
    end;
    if not Result then
      Result := Get1BaMinCardAry(sctThree, sct3Series, Low(TCardValue), High(TCardValue), RetCardAry);
    if not Result then
      Result := Get1BaMinCardAry(sctSingle, sctSingle, Low(TCardValue), High(TCardValue), RetCardAry);
    if not Result then
      Result := Get1BaMinCardAry(sctPair, sctPair, Low(TCardValue), High(TCardValue), RetCardAry);
    if not Result then
      Result := Get1BaMinCardAry(sctBomb, Low(TSplitCardType), Low(TCardValue), High(TCardValue), RetCardAry);
  end;

  // 如果都带单牌(包括4带2)，获得可以带单牌的最大数量
  function GetSplitCanTakeSingleCount: Integer;
  var
    I: Integer;
  begin
    // 4带2, 3带1
    Result := Length(LCurPlaceSplit[sctBomb]) + Length(LCurPlaceSplit[sctBomb])
      + Length(LCurPlaceSplit[sctThree]);

    // 3顺
    for I := Low(LCurPlaceSplit[sct3Series]) to High(LCurPlaceSplit[sct3Series]) do
      Inc(Result, LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X);
  end;

  // 自己是农民，地主剩余单张时的出牌方法
  // 如果按照一般的带牌方法，自己可以赢，则先出倒数第二大的牌，再出其他牌型
  // 否则，如果采用全带单牌方法，自己可以赢，则全带单牌出，出3带1\3顺带单\4带2，如果3顺不能带够牌，则拆成3带1
  // 否则，出同伙可以接管的牌型，并且不出炸弹、火箭
  // 否则，全带单牌出其他牌型（炸弹要带2单牌），然后单牌从大到小出
  function DoSelfFarmerAndEnemy1: Boolean;
  var
    LLordSingleValue: TCardValue;

    function CheckCommonTakeCardSuccess: Boolean;
    var
      I: Integer;
    begin
      Result := True;
      for I := High(LTakeCardSplit[sctSingle]) - 1 downto Low(LTakeCardSplit[sctSingle]) do
      begin
        if LTakeCardSplit[sctSingle][I].CardType.TypeValue.Value < LLordSingleValue then
          Result := False;

        Break;
      end;

      if Result then
      begin
        Result := Get1BaMinCardAry(sctSingle, sctSingle, LLordSingleValue, High(TCardValue), RetCardAry);
        if not Result then
          Result := Get1BaMinCardAry(sctPair, Low(TSplitCardType), Low(TCardValue), High(TCardValue), RetCardAry);
      end;
    end;

    function CheckAllTakeSingleSuccess: Boolean;
    var
      I: Integer;
      LCanTakeSingleCount: Integer;
      LMustTakeCount: Integer;
      LSingleLen: Integer;
      L3SeriesLen: Integer;
      LIndex: Integer;
    begin
      LMustTakeCount := 0;
      LCanTakeSingleCount := GetSplitCanTakeSingleCount;
      LSingleLen := Length(LCurPlaceSplit[sctSingle]);

      for I := High(LCurPlaceSplit[sctSingle]) - 1 downto Low(LCurPlaceSplit[sctSingle]) do
      begin
        if LCurPlaceSplit[sctSingle][I].CardType.TypeValue.Value < LLordSingleValue then
          Inc(LMustTakeCount)
        else
          Break;
      end;

      Result := LCanTakeSingleCount >= LMustTakeCount;
      if Result then
      begin
        if LMustTakeCount > 0 then
        begin
          if Length(LCurPlaceSplit[sctThree]) > 0 then
          begin
            LIndex := High(LCurPlaceSplit[sctThree]);
            
            CopyGameCardAry(LCurPlaceSplit[sctThree][LIndex].CardAry, RetCardAry);
            AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - 1].CardAry, RetCardAry);
          end else if Length(LCurPlaceSplit[sct3Series]) > 0 then
          begin
            LIndex := High(LCurPlaceSplit[sct3Series]); 
            L3SeriesLen := LCurPlaceSplit[sct3Series][LIndex].CardType.TypeNum.X;
            if L3SeriesLen > LSingleLen then
            begin
              // 拆分3顺
              AddGameCardAry(LCurPlaceSplit[sct3Series][LIndex].CardAry, (L3SeriesLen - LSingleLen) * 3, LSingleLen * 3, RetCardAry);
              
              for I := 1 to LSingleLen do
                AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - I].CardAry, RetCardAry);
            end else
            begin
              LIndex := High(LCurPlaceSplit[sct3Series]);
              CopyGameCardAry(LCurPlaceSplit[sct3Series][LIndex].CardAry, RetCardAry);
              
              for I := 1 to L3SeriesLen do
                AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - I].CardAry, RetCardAry);
            end;
          end else if Length(LCurPlaceSplit[sctBomb]) > 0 then
          begin
            LIndex := High(LCurPlaceSplit[sctBomb]);
            CopyGameCardAry(LCurPlaceSplit[sctBomb][LIndex].CardAry, RetCardAry);

            AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - 1].CardAry, RetCardAry);
            AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - 2].CardAry, RetCardAry);
          end else
          begin
            Result := False;
          end;
        end else
        begin
          Result := False;
        end;
      end;
    end;

    function CheckFetchOutPartnerCardType: Boolean;
    var
      I: TSplitCardType;
      LIndex: Integer;
      LHintCardType: TLordCardType;
      LHintCard: TGameCardAry;
    begin
      Result := False;
      
      for I := sctPair downto sct3Series do
      begin
        if Length(LTakeCardSplit[I]) > 0 then
        begin
          LIndex := High(LTakeCardSplit[I]);
          GetHintBiggerCard(LTakeCardSplit[I][LIndex].CardType, UserCard[LPartnerPlace],
            True, LTakeCardSplit[I][LIndex].CardType.TypeValue, LHintCardType, LHintCard);
          if IsCardTypeValid(LHintCardType) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][LIndex].CardAry, RetCardAry);
            if Length(LTakeCardSplit[I][LIndex].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][LIndex].TakesCard, 0,
                Length(LTakeCardSplit[I][LIndex].TakesCard), RetCardAry);
              DecSortCardAryByValue(RetCardAry);
            end;

            Result := True;
            Break;
          end;
        end;
      end;           
    end;

    // 如果地主下家单牌从小到大开始出，
    // 全带单牌出其他牌型（炸弹要带2单牌），
    // 然后单牌从大到小出;
    function CheckFetchOutSelfCard: Boolean;
    var
      I: Integer;
      LSingleLen: Integer;
      L3SeriesLen: Integer;
      LIndex: Integer;
    begin
      Result := True;
      LSingleLen := Length(LCurPlaceSplit[sctSingle]);
      Assert(LSingleLen > 0);

      // 如果地主下家单牌从小到大开始出
      if not LIsSelfLordPrevious then
      begin
        LIndex := LSingleLen - 1;
        CopyGameCardAry(LCurPlaceSplit[sctSingle][LIndex].CardAry, RetCardAry);

        Exit;
      end;

      if Length(LCurPlaceSplit[sctThree]) > 0 then
      begin
        LIndex := High(LCurPlaceSplit[sctThree]);
            
        CopyGameCardAry(LCurPlaceSplit[sctThree][LIndex].CardAry, RetCardAry);
        AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - 1].CardAry, RetCardAry);
      end else if Length(LCurPlaceSplit[sct3Series]) > 0 then
      begin
        LIndex := High(LCurPlaceSplit[sct3Series]); 
        L3SeriesLen := LCurPlaceSplit[sct3Series][LIndex].CardType.TypeNum.X;
        if L3SeriesLen > LSingleLen then
        begin
          // 拆分3顺
          AddGameCardAry(LCurPlaceSplit[sct3Series][LIndex].CardAry, (L3SeriesLen - LSingleLen) * 3, LSingleLen * 3, RetCardAry);
              
          for I := 1 to LSingleLen do
            AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - I].CardAry, RetCardAry);
        end else
        begin
          LIndex := High(LCurPlaceSplit[sct3Series]);
          CopyGameCardAry(LCurPlaceSplit[sct3Series][LIndex].CardAry, RetCardAry);
              
          for I := 1 to L3SeriesLen do
            AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - I].CardAry, RetCardAry);
        end;
      end else if Length(LCurPlaceSplit[sctBomb]) > 0 then
      begin
        LIndex := High(LCurPlaceSplit[sctBomb]);
        CopyGameCardAry(LCurPlaceSplit[sctBomb][LIndex].CardAry, RetCardAry);

        AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - 1].CardAry, RetCardAry);
        AddCardToCardAry(LCurPlaceSplit[sctSingle][LSingleLen - 2].CardAry, RetCardAry);
      end else
      begin
        // 没有带牌，所以怎么用哪个Split方法都一样
        Result := Get1BaMinCardAry(sctPair, sct3Series, Low(TCardValue), High(TCardValue), RetCardAry);
        if not Result then
        begin
          LIndex := 0;
          CopyGameCardAry(LCurPlaceSplit[sctSingle][LIndex].CardAry, RetCardAry);
          Result := True;
        end;
      end;
    end;

  begin
    LLordSingleValue := UserCard[ALordPlace][0].Value;

    Result := CheckCommonTakeCardSuccess;
    if not Result then
      Result := CheckAllTakeSingleSuccess;
    if not Result then
      Result := CheckFetchOutPartnerCardType;
    if not Result then
      Result :=  CheckFetchOutSelfCard;
  end;

  function CheckEnemy1_2: Boolean;
  var
    LIsLordPrevious1_2, LIsLordNext1_2: Boolean;
    LLen1, LLen2: Integer;
  begin
    Result := False;

    // 检测条件
    if ACurPlace = ALordPlace then
    begin
      LIsLordPrevious1_2 := IsCardAryPairOrSingle(LLordPreviousPlace);
      LIsLordNext1_2 := IsCardAryPairOrSingle(LLordNextPlace);
      LLen1 := Length(UserCard[LLordNextPlace]);
      LLen2 := Length(UserCard[LLordPreviousPlace]);

      // 判断是否 对手一个剩余一张，另一个剩余一对牌
      if LIsLordPrevious1_2 and LIsLordNext1_2 and (LLen1 <> LLen2) then
        Result := DoSelfLordAndEnemy1_2
      else if LIsLordPrevious1_2 or LIsLordNext1_2 then
      begin
        if (LLen1 = 1) or (LLen2 = 1) then
          Result := DoSelfLordAndOneFarmer1Card
        else
          Result := DoEnemyPair;
      end;
    end else
    begin
      LLen1 := Length(UserCard[ALordPlace]);
      if IsCardAryPairOrSingle(ALordPlace) then
      begin
        if LLen1 = 1 then
          Result := DoSelfFarmerAndEnemy1
        else
          Result := DoEnemyPair;
      end;
    end;
  end;

  function GetMin3SeriesByMaxCard(AMinMaxCard, AMaxMaxCard: TCardValue; var Ret3Series: TGameCardAry): Boolean;
  var
    I: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    for I := High(LTakeCardSplit[sct3Series]) downto Low(LTakeCardSplit[sct3Series]) do
    begin
      LCurValue := LTakeCardSplit[sct3Series][I].CardAry[0].Value;
      if (LCurValue >= AMinMaxCard) and (LCurValue <= AMaxMaxCard) then
      begin
        CopyGameCardAry(LTakeCardSplit[sct3Series][I].CardAry, Ret3Series);
        if Length(LTakeCardSplit[sct3Series][I].TakesCard) > 0 then
        begin
          AddGameCardAry(LTakeCardSplit[sct3Series][I].TakesCard, 0, Length(LTakeCardSplit[sct3Series][I].TakesCard), Ret3Series);
          DecSortCardAryByValue(Ret3Series);
        end;

        Result := True;
        Break;
      end;
    end;
  end;

  function GetMin1_2SeriesByMinCard(AMinMinCard, AMaxMinCard: TCardValue; ASplitType: TSplitCardType; var Ret1_2Series: TGameCardAry): Boolean;
  var
    I: Integer;
    LIndex: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    for I := High(LTakeCardSplit[ASplitType]) downto Low(LTakeCardSplit[ASplitType]) do
    begin
      LIndex := High(LTakeCardSplit[ASplitType][I].CardAry);
      LCurValue := LTakeCardSplit[ASplitType][I].CardAry[LIndex].Value;
      if (LCurValue >= AMinMinCard) and (LCurValue <= AMaxMinCard) then
      begin
        CopyGameCardAry(LTakeCardSplit[ASplitType][I].CardAry, Ret1_2Series);
        if Length(LTakeCardSplit[ASplitType][I].TakesCard) > 0 then
        begin
          AddGameCardAry(LTakeCardSplit[ASplitType][I].TakesCard, 0, Length(LTakeCardSplit[ASplitType][I].TakesCard), Ret1_2Series);
          DecSortCardAryByValue(Ret1_2Series);
        end;

        Result := True;
        Break;
      end;
    end;
  end;

  function CheckCommonFetch: Boolean;
  var
    LMinValue, LMaxValue: TCardValue;
  begin
    // 检测3-6直接的单 对 三张
    LMinValue := scv3;
    LMaxValue := scv6;
    if LIsSelfLordPrevious then
    begin
      Result := Get1BaMaxCardAry(sctSingle, sctSingle, LMinValue, LMaxValue, RetCardAry);
      if not Result then
        Result := Get1BaMaxCardAry(sctPair, sctPair, LMinValue, LMaxValue, RetCardAry);
      if not Result then
        Result := Get1BaMaxCardAry(sctThree, sctThree, LMinValue, LMaxValue, RetCardAry);
    end else
    begin
      Result := Get1BaMinCardAry(sctSingle, sctSingle, LMinValue, LMaxValue, RetCardAry);
      if not Result then
        Result := Get1BaMinCardAry(sctPair, sctPair, LMinValue, LMaxValue, RetCardAry);
      if not Result then
        Result := Get1BaMinCardAry(sctThree, sctThree, LMinValue, LMaxValue, RetCardAry);    
    end;
    // 检测最大牌小于等于J的飞机
    if not Result then
      Result := GetMin3SeriesByMaxCard(scvNone, scvJ, RetCardAry);
    // 如果有从3、4、5、6、7连起来的单连或对连牌，则先出连牌；
    if not Result then
      Result := GetMin1_2SeriesByMinCard(scvNone, scvJ, sct1Series, RetCardAry);
    if not Result then
      Result := GetMin1_2SeriesByMinCard(scvNone, scvJ, sct2Series, RetCardAry);
    // 如果有小于等于J的三条，则先出三条
    if not Result then
      Result := Get1BaMinCardAry(sctThree, sctThree, scvNone, scvJ, RetCardAry);
    // 从最小牌开始出
    if not Result then
      Result := GetMinCardAry(RetCardAry, sctSingle);
  end;

  // 看对手是否有比自己大的牌型
  function CheckEnemyHasBiggerCard(const ADecSortCardAry: TGameCardAry): Boolean;
  var
    LCardType: TLordCardType;
  begin
    CheckCardType(ADecSortCardAry, LCardType);
    if ACurPlace = ALordPlace then
    begin
      Result := CheckHasBiggerCard(LCardType, LLordPreviousPlace) or
        CheckHasBiggerCard(LCardType, LLordNextPlace);
    end else
    begin
      Result := CheckHasBiggerCard(LCardType, ALordPlace);
    end;
  end;

  // 看对手是否可以压上自己的牌型，并且可以出完
  function CheckEnemyHasBiggerCardAndFetchAll(const ADecSortCardAry: TGameCardAry): Boolean;
  var
    LSelfCardType: TLordCardType;
    LEnemyCardType: TLordCardType;
  begin
    Result := False;
    CheckCardType(ADecSortCardAry, LSelfCardType);
    if ACurPlace = ALordPlace then
    begin
      CheckCardType(UserCard[LLordPreviousPlace], LEnemyCardType);
      if IsNewCardTypeBigger(LEnemyCardType, LSelfCardType) then
        Result := True;

      if not Result then
      begin
        CheckCardType(UserCard[LLordNextPlace], LEnemyCardType);
        if IsNewCardTypeBigger(LEnemyCardType, LSelfCardType) then
          Result := True;
      end;
    end else
    begin
      CheckCardType(UserCard[ALordPlace], LEnemyCardType);
      if IsNewCardTypeBigger(LEnemyCardType, LSelfCardType) then
        Result := True;
    end;
  end;

  // 剩余1个炸弹[火箭]，和1个其他牌型
  // 前提：自己的炸弹比对手所有牌型大
  // 如果该牌型对手不能压上后就完全出完，则先出此牌型
  function CheckLeft1BombAnd1Other: Boolean;
  var
    LBombCard: TGameCardAry;
    LOtherCard: TGameCardAry;
  begin
    Result := False;
    // 检测条件
    if not Get1BaMinCardAry(sctBomb, sctRocket, Low(TCardValue), High(TCardValue), LBombCard) then
      Exit;
    if CheckEnemyHasBiggerCard(LBombCard) then
      Exit;
    if not Get1BaMinCardAry(sctSingle, sct3Series, Low(TCardValue), High(TCardValue), LOtherCard) then
      Exit;
    if not CheckEnemyHasBiggerCardAndFetchAll(LOtherCard) then
    begin
      Result := True;
      CopyGameCardAry(LOtherCard, RetCardAry);
    end;
  end;

  // 剩余1个炸弹[火箭]，和2个其他牌型
  // 前提：自己的炸弹比对手所有牌型大
  // 如果有一把牌型自己出完后，对手不能压上出完，则先出此牌型
  function CheckLeft1BombAnd2Other: Boolean;
  var
    LBombCard: TGameCardAry;
    LOtherCard: TGameCardAry;
  begin
    Result := False;
    // 检测条件
    if not Get1BaMinCardAry(sctBomb, sctRocket, Low(TCardValue), High(TCardValue), LBombCard) then
      Exit;
    if CheckEnemyHasBiggerCard(LBombCard) then
      Exit;
    if not Get1BaMinCardAry(sctSingle, sct3Series, Low(TCardValue), High(TCardValue), LOtherCard) then
      Exit;
    if not CheckEnemyHasBiggerCardAndFetchAll(LOtherCard) then
    begin
      Result := True;
      CopyGameCardAry(LOtherCard, RetCardAry);
    end;
    
    if not Result then
    begin
      if not Get1BaMaxCardAry(sct3Series, sctSingle, Low(TCardValue), High(TCardValue), LOtherCard) then
        Exit;
      if not CheckEnemyHasBiggerCardAndFetchAll(LOtherCard) then
      begin
        Result := True;
        CopyGameCardAry(LOtherCard, RetCardAry);
      end;
    end;
  end;

  function CheckLeft1BombAnd1_2Other: Boolean;
  var
    LBombCount: Integer;
    LTotalBaShu: Integer;
  begin
    Result := False;

    LBombCount := Length(LTakeCardSplit[sctBomb]) + Length(LTakeCardSplit[sctRocket]);
    if LBombCount <> 1 then
      Exit;
    LTotalBaShu := GetSplitTotalBaShu(LTakeCardSplit, Low(TSplitCardType), High(TSplitCardType));
    if (LTotalBaShu < 2) or (LTotalBaShu > 3) then
      Exit;

    if LTotalBaShu = 2 then
      Result := CheckLeft1BombAnd1Other
    else if LTotalBaShu = 3 then
      Result := CheckLeft1BombAnd2Other;         
  end;

var
  LSplitCount: Integer;
begin
  // 处理玩家首次出牌
  SetLength(RetCardAry, 0);
  // 检测参数
  Result := CheckParams;
  if not Result then
    Exit;

  // 拆分当前玩家的牌
  LSplitCount := SplitCard(LCurUserCard, LCurPlaceSplit);
  if LSplitCount < 1 then
    Exit;
  // 处理带牌
  CopySplitAry(LCurPlaceSplit, LTakeCardSplit);
  CalcTakesCard(LTakeCardSplit);

  // 剩余1炸弹 + <=2把其他牌型
  if CheckLeft1BombAnd1_2Other then
    Exit;

  // 检测是否可以一次出完，要排除带双王的情况。
  if CheckFetchOutAll then
    Exit;

  // 检测是否剩余牌必杀，即所有把数的牌最多有一把牌别人可以压过
  if CheckBiShaFetchOutAll then
    Exit;

  // 自己是农民，农民同伙剩余1对牌、一张牌
  if CheckSelfFarmerAndPartnerPairOrSingle then
    Exit;

  // 如果对手单张或者对牌
  if CheckEnemy1_2 then
    Exit;
    
  // 一般的出牌原则
  Result := CheckCommonFetch;
end;

function TTemplateGameLogicProc.DoUserFirstDiscard2(
  const XSelfCard: TGameCardAry; var RetCardAry: TGameCardAry): Boolean;
var
  LCurUserCard: TGameCardAry;                     // 自己的牌
  LCurUserScanAry: TCardScanItemAry;              // 自己牌的扫描表
  LCurPlaceSplit: TSplitCardAryAry;               // 自己牌的拆分表
  LTakeCardSplit: TSplitCardAryAry;               // 自己的牌拆分后带牌处理

  function CheckParams: Boolean;
  begin
    CopyGameCardAry(XSelfCard, LCurUserCard);
    DecSortCardAryByValue(LCurUserCard);
    GetCardScanTable(LCurUserCard, sccNone, LCurUserScanAry);
    DecSortCardScanAryByCount(LCurUserScanAry);

    Result := True;
  end;

  function CheckFetchOutAll: Boolean;
  var
    LCardType: TLordCardType;
  begin
    Result := True;

    // 排除双王和其他牌型一块出去
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      if Length(LCurUserCard) > 2 then
      begin
        Result := False;
      end;
    end;

    if Result then
    begin
      CheckCardType(LCurUserCard, LCardType);
      Result := IsCardTypeValid(LCardType);
    end;

    if Result then
      CopyGameCardAry(LCurUserCard, RetCardAry);
  end;

  // 获得倒数第二大的单牌
  function GetSingleCardAry2FromLast(var SingleCardAry: TGameCardAry): Boolean;
  var
    I: Integer;
  begin
    Result := False;

    for I := High(LTakeCardSplit[sctSingle]) - 1 downto Low(LTakeCardSplit[sctSingle]) do
    begin
      CopyGameCardAry(LTakeCardSplit[sctSingle][I].CardAry, SingleCardAry);
      Result := True;
      Break;
    end;
  end;

  // 获得倒数第二大的对牌
  function GetPairCardAry2FromLast(var PairCardAry: TGameCardAry): Boolean;
  var
    I: Integer;
  begin
    Result := False;

    for I := High(LTakeCardSplit[sctPair]) - 1 downto Low(LTakeCardSplit[sctPair]) do
    begin
      CopyGameCardAry(LTakeCardSplit[sctPair][I].CardAry, PairCardAry);
      Result := True;
      Break;
    end;
  end;

  // 获得一手最小的牌
  function Get1BaMinCardAry(AFromSplit, AToSplit: TSplitCardType;
    AMinValue, AMaxValue: TCardValue; var Ret1Ba: TGameCardAry): Boolean;
  var
    I: TSplitCardType;
    J: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;

    if AFromSplit <= AToSplit then
    begin
      for I := AFromSplit to AToSplit do
      begin
        for J := High(LTakeCardSplit[I]) downto Low(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end else
    begin
      for I := AFromSplit downto AToSplit do
      begin
        for J := High(LTakeCardSplit[I]) downto Low(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  // 获得一手最大的牌
  function Get1BaMaxCardAry(AFromSplit, AToSplit: TSplitCardType;
    AMinValue, AMaxValue: TCardValue; var Ret1Ba: TGameCardAry): Boolean;
  var
    I: TSplitCardType;
    J: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;

    if AFromSplit <= AToSplit then
    begin
      for I := AFromSplit to AToSplit do
      begin
        for J := Low(LTakeCardSplit[I]) to High(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end else
    begin
      for I := AFromSplit downto AToSplit do
      begin
        for J := Low(LTakeCardSplit[I]) to High(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  function GetMinCardAry(var RetMinCard: TGameCardAry; AFromSplit: TSplitCardType): Boolean;
  var
    I: TSplitCardType;
    J: Integer;
    LIndex: Integer;
    LCurValue: TCardValue;
    LMinSplit: TSplitCardType;
    LMinIndex: Integer;
    LMinCardValue: TCardValue;
  begin
    LMinCardValue := scvNone;
    LMinSplit := sctSingle;
    LMinIndex := -1;

    // 获得3张以上的牌型
    for I := AFromSplit downto sct3Series do
    begin
      for J := High(LTakeCardSplit[I]) downto Low(LTakeCardSplit[I]) do
      begin
        LIndex := High(LTakeCardSplit[I][J].CardAry);
        LCurValue := LTakeCardSplit[I][J].CardAry[LIndex].Value;

        if (LMinCardValue = scvNone) or (LCurValue < LMinCardValue) then
        begin
          LMinCardValue := LCurValue;
          LMinSplit := I;
          LMinIndex := J;
        end;
      end;
    end;
    Result := (LMinCardValue <> scvNone);
    // 再获得最小的炸弹
    if not Result then
    begin
      for I := sctBomb downto sctRocket do
      begin
        if Length(LTakeCardSplit[I]) > 0 then
        begin
          LMinSplit := I;
          LMinIndex := High(LTakeCardSplit[I]);

          Result := True;
          Break;
        end;
      end;
    end;

    if Result then
    begin
      CopyGameCardAry(LTakeCardSplit[LMinSplit][LMinIndex].CardAry, RetMinCard);
      if Length(LTakeCardSplit[LMinSplit][LMinIndex].TakesCard) > 0 then
      begin
        AddGameCardAry(LTakeCardSplit[LMinSplit][LMinIndex].TakesCard, 0, Length(LTakeCardSplit[LMinSplit][LMinIndex].TakesCard), RetMinCard);
        DecSortCardAryByValue(RetMinCard);
      end;
    end;
  end;

  // 地主出牌，农民一个剩余一张，另一个剩余一对牌
  function DoSelfLordAndEnemy1_2: Boolean;
  begin
    // 如果有倒数第二大的单牌，则出单牌
    Result := GetSingleCardAry2FromLast(RetCardAry);
    // 如果有倒数第二大的对牌，则出对牌
    if not Result then
      Result := GetPairCardAry2FromLast(RetCardAry);
    // 如果手里只剩下1个单牌和1个对牌，则出牌值较大的牌型
    if not Result then
    begin
      if (Length(LTakeCardSplit[sctSingle]) = 1) and (Length(LTakeCardSplit[sctPair]) = 1) then
      begin
        if LTakeCardSplit[sctPair][0].CardType.TypeValue.Value > LTakeCardSplit[sctSingle][0].CardType.TypeValue.Value then
          Result := Get1BaMinCardAry(sctPair, sctPair, Low(TCardValue), High(TCardValue), RetCardAry)
        else
          Result := Get1BaMinCardAry(sctSingle, sctSingle, Low(TCardValue), High(TCardValue), RetCardAry)
      end;
    end;
    // 如果手里还有除了单牌和对牌的牌型，则出之
    if not Result then
      Result := Get1BaMinCardAry(sctThree, Low(TSplitCardType), Low(TCardValue), High(TCardValue), RetCardAry);
  end;

  // 对手剩余对牌
  // 先出单牌(不包括2和王)
  // 再拆对出单（不包括2和王）
  // 再出小于炸弹的牌型
  // 再出2或者王单
  // 再出2的对
  // 再出炸弹以上的牌型
  function DoEnemyPair: Boolean;
  begin
    Result := Get1BaMinCardAry(sctSingle, sctSingle, Low(TCardValue), scvBA, RetCardAry);
    if not Result then
    begin
      Result := Get1BaMinCardAry(sctPair, sctPair, Low(TCardValue), scvBA, RetCardAry);
      if Result then
        SetLength(RetCardAry, 1);
    end;
    if not Result then
      Result := Get1BaMinCardAry(sctThree, sct3Series, Low(TCardValue), High(TCardValue), RetCardAry);
    if not Result then
      Result := Get1BaMinCardAry(sctSingle, sctSingle, Low(TCardValue), High(TCardValue), RetCardAry);
    if not Result then
      Result := Get1BaMinCardAry(sctPair, sctPair, Low(TCardValue), High(TCardValue), RetCardAry);
    if not Result then
      Result := Get1BaMinCardAry(sctBomb, Low(TSplitCardType), Low(TCardValue), High(TCardValue), RetCardAry);
  end;

  // 如果都带单牌(包括4带2)，获得可以带单牌的最大数量
  function GetSplitCanTakeSingleCount: Integer;
  var
    I: Integer;
  begin
    // 4带2, 3带1
    Result := Length(LCurPlaceSplit[sctBomb]) + Length(LCurPlaceSplit[sctBomb])
      + Length(LCurPlaceSplit[sctThree]);

    // 3顺
    for I := Low(LCurPlaceSplit[sct3Series]) to High(LCurPlaceSplit[sct3Series]) do
      Inc(Result, LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X);
  end;


  function GetMin3SeriesByMaxCard(AMinMaxCard, AMaxMaxCard: TCardValue; var Ret3Series: TGameCardAry): Boolean;
  var
    I: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    for I := High(LTakeCardSplit[sct3Series]) downto Low(LTakeCardSplit[sct3Series]) do
    begin
      LCurValue := LTakeCardSplit[sct3Series][I].CardAry[0].Value;
      if (LCurValue >= AMinMaxCard) and (LCurValue <= AMaxMaxCard) then
      begin
        CopyGameCardAry(LTakeCardSplit[sct3Series][I].CardAry, Ret3Series);
        if Length(LTakeCardSplit[sct3Series][I].TakesCard) > 0 then
        begin
          AddGameCardAry(LTakeCardSplit[sct3Series][I].TakesCard, 0, Length(LTakeCardSplit[sct3Series][I].TakesCard), Ret3Series);
          DecSortCardAryByValue(Ret3Series);
        end;

        Result := True;
        Break;
      end;
    end;
  end;

  function GetMin1_2SeriesByMinCard(AMinMinCard, AMaxMinCard: TCardValue; ASplitType: TSplitCardType; var Ret1_2Series: TGameCardAry): Boolean;
  var
    I: Integer;
    LIndex: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    for I := High(LTakeCardSplit[ASplitType]) downto Low(LTakeCardSplit[ASplitType]) do
    begin
      LIndex := High(LTakeCardSplit[ASplitType][I].CardAry);
      LCurValue := LTakeCardSplit[ASplitType][I].CardAry[LIndex].Value;
      if (LCurValue >= AMinMinCard) and (LCurValue <= AMaxMinCard) then
      begin
        CopyGameCardAry(LTakeCardSplit[ASplitType][I].CardAry, Ret1_2Series);
        if Length(LTakeCardSplit[ASplitType][I].TakesCard) > 0 then
        begin
          AddGameCardAry(LTakeCardSplit[ASplitType][I].TakesCard, 0, Length(LTakeCardSplit[ASplitType][I].TakesCard), Ret1_2Series);
          DecSortCardAryByValue(Ret1_2Series);
        end;

        Result := True;
        Break;
      end;
    end;
  end;

  function CheckCommonFetch: Boolean;
  var
    LMinValue, LMaxValue: TCardValue;
  begin
    // 检测3-6直接的单 对 三张
    LMinValue := scv3;
    LMaxValue := scv6;
    begin
      Result := Get1BaMaxCardAry(sctSingle, sctSingle, LMinValue, LMaxValue, RetCardAry);
      if not Result then
        Result := Get1BaMaxCardAry(sctPair, sctPair, LMinValue, LMaxValue, RetCardAry);
      if not Result then
        Result := Get1BaMaxCardAry(sctThree, sctThree, LMinValue, LMaxValue, RetCardAry);
    end;
    // 检测最大牌小于等于J的飞机
    if not Result then
      Result := GetMin3SeriesByMaxCard(scvNone, scvJ, RetCardAry);
    // 如果有从3、4、5、6、7连起来的单连或对连牌，则先出连牌；
    if not Result then
      Result := GetMin1_2SeriesByMinCard(scvNone, scvJ, sct1Series, RetCardAry);
    if not Result then
      Result := GetMin1_2SeriesByMinCard(scvNone, scvJ, sct2Series, RetCardAry);
    // 如果有小于等于J的三条，则先出三条
    if not Result then
      Result := Get1BaMinCardAry(sctThree, sctThree, scvNone, scvJ, RetCardAry);
    // 从最小牌开始出
    if not Result then
      Result := GetMinCardAry(RetCardAry, sctSingle);
  end;

var
  LSplitCount: Integer;
begin
  // 处理玩家首次出牌
  SetLength(RetCardAry, 0);
  // 检测参数
  Result := CheckParams;
  if not Result then
    Exit;

  // 拆分当前玩家的牌
  LSplitCount := SplitCard(LCurUserCard, LCurPlaceSplit);
  if LSplitCount < 1 then
    Exit;
  // 处理带牌
  CopySplitAry(LCurPlaceSplit, LTakeCardSplit);
  CalcTakesCard(LTakeCardSplit);

  // 检测是否可以一次出完，要排除带双王的情况。
  if CheckFetchOutAll then
    Exit;

  // 一般的出牌原则
  Result := CheckCommonFetch;
end;

function TTemplateGameLogicProc.DoUserSecondDiscard(
  const ALastCardType: TLordCardType; var UserCard: TGameCardAryAry;
  ALastPlace, ACurPlace, ALordPlace, XDiscardTurn: Integer; var RetCardAry: TGameCardAry): Boolean;
var
  LPartnerPlace: Integer;           // 农民的同伙的方位
  LIsSelfLordPrevious: Boolean;     // 自己是否是地主上家
  LIsLastPartnerFetch: Boolean;     // 最后是否是同伙出牌
  LLordPreviousPlace, LLordNextPlace: Integer;    // 地主上家、地主下家的方位
  LCurUserCard: TGameCardAry;                     // 自己的牌
  LCurUserScanAry: TCardScanItemAry;              // 自己牌的扫描表
  LCurPlaceSplit: TSplitCardAryAry;               // 自己牌的拆分表
  LTakeCardSplit: TSplitCardAryAry;               // 自己的牌拆分后带牌处理
  LHintBiggerCard: TGameCardAry;                  // 默认提示出牌的牌

  function CheckParams: Boolean;
  var
    I: Integer;
  begin
    Result := False;
    if Length(UserCard) <> 3 then
      Exit;
    if not IsCardTypeValid(ALastCardType) then
      Exit;
    if ALastPlace = ACurPlace then
      Exit;

    for I := Low(UserCard) to High(UserCard) do
    begin
      if Length(UserCard[I]) < 1 then
        Exit;
      if IsCardAryHasBackCard(UserCard[I]) then
        Exit;

      DecSortCardAryByValue(UserCard[I]);
    end;

    if not IsTemplatePlaceValid(ALastPlace) then
      Exit;
    if not IsTemplatePlaceValid(ACurPlace) then
      Exit;
    if not IsTemplatePlaceValid(ALordPlace) then
      Exit;

    CopyGameCardAry(UserCard[ACurPlace], LCurUserCard);
    GetCardScanTable(UserCard[ACurPlace], sccNone, LCurUserScanAry);
    DecSortCardScanAryByCount(LCurUserScanAry);

    LLordNextPlace := (ALordPlace + 1) mod CTEMPLATE_MAX_USER_COUNT;
    LLordPreviousPlace := (ALordPlace + 2) mod CTEMPLATE_MAX_USER_COUNT;
    
    if ACurPlace = ALordPlace then
    begin
      LIsSelfLordPrevious := False;
      LIsLastPartnerFetch := False;
      LPartnerPlace := -1;
    end else
    begin
      if (ACurPlace + 1) mod CTEMPLATE_MAX_USER_COUNT = ALordPlace then
      begin
        LIsSelfLordPrevious := True;
        LPartnerPlace := (ACurPlace + 2) mod CTEMPLATE_MAX_USER_COUNT;
      end else
      begin
        LIsSelfLordPrevious := False;
        LPartnerPlace := (ACurPlace + 1) mod CTEMPLATE_MAX_USER_COUNT;      
      end;

      LIsLastPartnerFetch := (ALastPlace = LPartnerPlace); 
    end;

    Result := True;
  end;

  function CheckHasHintBiggerCard: Boolean;
  var
    LNewCardType: TLordCardType;
  begin
    GetHintBiggerCard(ALastCardType, UserCard[ACurPlace], True, ALastCardType.TypeValue, LNewCardType, LHintBiggerCard);
    Result := IsCardTypeValid(LNewCardType);
  end;

  // 获得一手最小的牌
  function Get1BaMinCardAry(AFromSplit, AToSplit: TSplitCardType;
    AMinValue, AMaxValue: TCardValue; var Ret1Ba: TGameCardAry): Boolean;
  var
    I: TSplitCardType;
    J: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    
    if AFromSplit <= AToSplit then
    begin
      for I := AFromSplit to AToSplit do
      begin
        for J := High(LTakeCardSplit[I]) downto Low(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end else
    begin
      for I := AFromSplit downto AToSplit do
      begin
        for J := High(LTakeCardSplit[I]) downto Low(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  // 获得一手最大的牌
  function Get1BaMaxCardAry(AFromSplit, AToSplit: TSplitCardType;
    AMinValue, AMaxValue: TCardValue; var Ret1Ba: TGameCardAry): Boolean;
  var
    I: TSplitCardType;
    J: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    
    if AFromSplit <= AToSplit then
    begin
      for I := AFromSplit to AToSplit do
      begin
        for J := Low(LTakeCardSplit[I]) to High(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end else
    begin
      for I := AFromSplit downto AToSplit do
      begin
        for J := Low(LTakeCardSplit[I]) to High(LTakeCardSplit[I]) do
        begin
          LCurValue := LTakeCardSplit[I][J].CardType.TypeValue.Value;
          if (LCurValue >= AMinValue) and (LCurValue <= AMaxValue) then
          begin
            CopyGameCardAry(LTakeCardSplit[I][J].CardAry, Ret1Ba);
            if Length(LTakeCardSplit[I][J].TakesCard) > 0 then
            begin
              AddGameCardAry(LTakeCardSplit[I][J].TakesCard, 0, Length(LTakeCardSplit[I][J].TakesCard), Ret1Ba);
              DecSortCardAryByValue(Ret1Ba);
            end;

            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  function CheckHasBiggerCard(const ACmpType: TLordCardType; APlace: Integer): Boolean;
  var
    LNewCardType: TLordCardType;
    LNewCardAry: TGameCardAry;
  begin
    GetHintBiggerCard(ACmpType, UserCard[APlace], True, ACmpType.TypeValue, LNewCardType, LNewCardAry);
    Result := IsCardTypeValid(LNewCardType);
  end;

  // 看对手是否有比自己大的牌型
  function CheckEnemyHasBiggerCard(const ADecSortCardAry: TGameCardAry): Boolean;
  var
    LCardType: TLordCardType;
  begin
    CheckCardType(ADecSortCardAry, LCardType);
    if ACurPlace = ALordPlace then
    begin
      Result := CheckHasBiggerCard(LCardType, LLordPreviousPlace) or
        CheckHasBiggerCard(LCardType, LLordNextPlace);
    end else
    begin
      Result := CheckHasBiggerCard(LCardType, ALordPlace);
    end;
  end;

  // 剩余1个炸弹[火箭]，和1个其他牌型
  // 前提：自己的炸弹比对手所有牌型大
  // 先出炸弹，后出其他牌型
  function DoLeft1BombAnd1Other: Boolean;
  var
    LBombCard: TGameCardAry;
  begin
    Result := False;
    // 检测条件
    if not Get1BaMinCardAry(sctBomb, sctRocket, Low(TCardValue), High(TCardValue), LBombCard) then
      Exit;
    if CheckEnemyHasBiggerCard(LBombCard) then
      Exit;

    Result := True;
    CopyGameCardAry(LBombCard, RetCardAry);
  end;

  function CheckLeft1BombAnd1Other: Boolean;
  var
    LBombCount: Integer;
    LTotalBaShu: Integer;
  begin
    Result := False;

    LBombCount := Length(LTakeCardSplit[sctBomb]) + Length(LTakeCardSplit[sctRocket]);
    if LBombCount <> 1 then
      Exit;
    LTotalBaShu := GetSplitTotalBaShu(LTakeCardSplit, Low(TSplitCardType), High(TSplitCardType));

    if LTotalBaShu = 2 then
    begin
      Result := DoLeft1BombAnd1Other;
    end;
  end;

  function CheckFetchOutAll: Boolean;
  var
    LCardType: TLordCardType;
  begin
    Result := True;

    // 排除双王和其他牌型一块出去
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      if Length(LCurUserCard) > 2 then
      begin
        Result := False;
      end;
    end;
    
    if Result then
    begin
      CheckCardType(LCurUserCard, LCardType);
      Result := IsNewCardTypeBigger(LCardType, ALastCardType);
    end;

    if Result then
      CopyGameCardAry(LCurUserCard, RetCardAry);
  end;

  function CheckBiShaFetchOutAll: Boolean;
  var
    I, J: Integer;
    LSplitType: TSplitCardType;
    LSmallBaShu: Integer;
    LSmallSpiitIndex: Integer;
    LHasBigCard: Boolean;
    LBigSplitType: TSplitCardType;
    LBigSplitIndex: Integer;
    LTmpCardAry: TGameCardAry;
    LCurCardType: TLordCardType;
  begin
    Result := True;

    LSmallBaShu := 0;
    LSmallSpiitIndex := -1;
    LHasBigCard := False;
    LBigSplitType := sctRocket;
    LBigSplitIndex := -1;
    
    for LSplitType := High(LTakeCardSplit) downto Low(LTakeCardSplit) do
    begin
      if Length(LTakeCardSplit[LSplitType]) > 0 then
      begin
        for I := High(LTakeCardSplit[LSplitType]) downto Low(LTakeCardSplit[LSplitType]) do
        begin
          // 获得1把牌
          CopyGameCardAry(LTakeCardSplit[LSplitType][I].CardAry, LTmpCardAry);
          if Length(LTakeCardSplit[LSplitType][I].TakesCard) > 0 then
          begin
            AddGameCardAry(LTakeCardSplit[LSplitType][I].TakesCard, 0,
              Length(LTakeCardSplit[LSplitType][I].TakesCard), LTmpCardAry);
            DecSortCardAryByValue(LTmpCardAry);
          end;

          CheckCardType(LTmpCardAry, LCurCardType);

          for J := Low(UserCard) to High(UserCard) do
          begin
            if J = ACurPlace then
              Continue;
            // 只要有一个人有比自己大的牌就可以
            if CheckHasBiggerCard(LCurCardType, J) then
            begin
              Inc(LSmallBaShu);

              // 记录第一次小牌
              if LSmallBaShu = 1 then
              begin
                LSmallSpiitIndex := I;
              end else
              begin
                // 如果有2把及以上的牌小，则必杀失败
                Result := False;
                Exit;
              end;

              Break;
            end;
          end;

          // 判断是否有比当前牌大的牌型，并且不是别人可以压上的。
          if (LSmallSpiitIndex <> I) and (not LHasBigCard) then
          begin
            if IsNewCardTypeBigger(LCurCardType, ALastCardType) then
            begin
              LHasBigCard := True;
              LBigSplitType := LSplitType;
              LBigSplitIndex := I;
            end;
          end;
        end;
      end;
    end;

    if Result and LHasBigCard then
    begin
      // 成功获得1把牌
      CopyGameCardAry(LTakeCardSplit[LBigSplitType][LBigSplitIndex].CardAry, RetCardAry);
      if Length(LTakeCardSplit[LBigSplitType][LBigSplitIndex].TakesCard) > 0 then
      begin
        AddGameCardAry(LTakeCardSplit[LBigSplitType][LBigSplitIndex].TakesCard, 0,
          Length(LTakeCardSplit[LBigSplitType][LBigSplitIndex].TakesCard), RetCardAry);
        DecSortCardAryByValue(RetCardAry);
      end;
    end else
    begin
      Result := False;
    end;
  end;

  // 判断牌是否为单张或者对子
  function IsCardAryPairOrSingle(APlace: Integer): Boolean;
  var
    LCardLen: Integer;
  begin
    Result := False;

    LCardLen := Length(UserCard[APlace]);
    if LCardLen > 2 then
      Exit;
    if LCardLen = 2 then
    begin
      if UserCard[APlace][0].Value <> UserCard[APlace][1].Value then
        Exit;
    end;

    Result := True;
  end;

  // 检测自己是否可以绝对压过当前出牌玩家的牌，YaPaiLeftCard返回压牌后剩余的牌
  function CheckAbsolutelyYaPai(var FetchCard, YaPaiLeftCard: TGameCardAry): Boolean;
  var
    I: Integer;
    LSplitType: TSplitCardType;
    LCurCardType: TLordCardType;
    LCheckSuccess: Boolean;
  begin
    // 从炸弹开始搜索
    Result := False;
    LCheckSuccess := False;
    for LSplitType := Low(LTakeCardSplit) to High(LTakeCardSplit) do
    begin
      for I := Low(LTakeCardSplit[LSplitType]) to High(LTakeCardSplit[LSplitType]) do
      begin
        // 获得1把牌
        CopyGameCardAry(LTakeCardSplit[LSplitType][I].CardAry, FetchCard);
        if Length(LTakeCardSplit[LSplitType][I].TakesCard) > 0 then
        begin
          AddGameCardAry(LTakeCardSplit[LSplitType][I].TakesCard, 0,
            Length(LTakeCardSplit[LSplitType][I].TakesCard), FetchCard);
          DecSortCardAryByValue(FetchCard);
        end;

        CheckCardType(FetchCard, LCurCardType);
        if IsNewCardTypeBigger(LCurCardType, ALastCardType) then
        begin
          // 如果对手不能压过自己的牌，则成功了
          if not CheckHasBiggerCard(LCurCardType, ALastPlace) then
          begin
            Result := True;
          end;

          LCheckSuccess := True;
          Break;
        end;
      end;

      if LCheckSuccess then
        Break;
    end;

    if Result then
    begin
      // 获得出牌后剩余的牌
      CopyGameCardAry(UserCard[ACurPlace], YaPaiLeftCard);
      DelCardFromCardAry(FetchCard, YaPaiLeftCard);
    end;
  end;

  function CheckHasShunPai1_2(const AScanAry: TCardScanItemAry; APartnerCardLen: Integer; APartnerCardValue: TCardValue): Boolean;
  var
    I: Integer;
    LTmpValue: TCardValue;
  begin
    // 检测是否可以顺同伙
    Result := False;
    for I := High(LCurUserScanAry) downto Low(LCurUserScanAry) do
    begin
      if LCurUserScanAry[I].Count >= APartnerCardLen then
      begin
        LTmpValue := LCurUserScanAry[I].Card.Value;
        if LTmpValue < APartnerCardValue then
        begin
          Result := True;
          Break;
        end;
      end;
    end;
  end;

  // 检测自己按照一般的拆牌规则，是否有相同牌型的 可以压过当前出牌玩家的牌
  function CheckCommonTakeYaPai(var FetchCard: TGameCardAry): Boolean;
  var
    I: Integer;
    LSplitType: TSplitCardType;
    LCurCardType: TLordCardType;
    LLowIndex, LHighIndex: TSplitCardType;
  begin
    Result := False;
    LHighIndex := High(LTakeCardSplit);
    LLowIndex := Low(LTakeCardSplit);
    if IsBombCardType(ALastCardType) then
      LHighIndex := sctBomb
    else
      LLowIndex := sct3Series;
      
    for LSplitType := LHighIndex downto LLowIndex do
    begin
      for I := High(LTakeCardSplit[LSplitType]) downto Low(LTakeCardSplit[LSplitType]) do
      begin
        // 获得1把牌
        CopyGameCardAry(LTakeCardSplit[LSplitType][I].CardAry, FetchCard);
        if Length(LTakeCardSplit[LSplitType][I].TakesCard) > 0 then
        begin
          AddGameCardAry(LTakeCardSplit[LSplitType][I].TakesCard, 0,
            Length(LTakeCardSplit[LSplitType][I].TakesCard), FetchCard);
          DecSortCardAryByValue(FetchCard);
        end;

        CheckCardType(FetchCard, LCurCardType);
        if LCurCardType.TypeNum.M <> ALastCardType.TypeNum.M then
          Break;
          
        if IsNewCardTypeBigger(LCurCardType, ALastCardType) then
        begin
          Result := True;
          Break;
        end;
      end;

      if Result then
        Break;
    end;
  end;

  function Check42Or3Or3SeriesYaPai: Boolean;
  var
    LTakeSuccess: Boolean;
    LTakeCard: TGameCardAry;

    function Process42YaPai: Boolean;
    var
      LBombCount, LRocketCount: Integer;
      LHasBigCard: Boolean;
      I: Integer;
      LSelIndex: Integer;
    begin
      Result := False;
      LRocketCount := Length(LCurPlaceSplit[sctRocket]);
      LBombCount := Length(LCurPlaceSplit[sctBomb]);
      if LBombCount > 0 then
      begin
        LHasBigCard := False;
        LSelIndex := -1;

        for I := High(LCurPlaceSplit[sctBomb]) downto Low(LCurPlaceSplit[sctBomb]) do
        begin
          if LCurPlaceSplit[sctBomb][I].CardType.TypeValue.Value > ALastCardType.TypeValue.Value then
          begin
            LHasBigCard := True;
            LSelIndex := I;
            Break;
          end;
        end;

        if LHasBigCard then
        begin
          LTakeSuccess := GetSplitTakeCardNotChaiPai(LCurPlaceSplit, LCurPlaceSplit[sctBomb][LSelIndex].CardType.TypeValue.Value,
            LCurPlaceSplit[sctBomb][LSelIndex].CardType.TypeValue.Value, ALastCardType.TypeNum.N, ALastCardType.TypeNum.Y, LTakeCard);
          if LTakeSuccess then
          begin
            CopyGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, RetCardAry);
            AddGameCardAry(LTakeCard, 0, Length(LTakeCard), RetCardAry);
            DecSortCardAryByValue(RetCardAry);
          end else
          begin
            CopyGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, RetCardAry);            
          end;

          Result := True;
        end;
      end;

      if (not Result) and (LRocketCount > 0) then
      begin
        CopyGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, RetCardAry);
        Result := True;
      end;
    end;

    function ProcessThreeYaPai: Boolean;
    var
      LThreeCount: Integer;
      LHasBigCard: Boolean;
      I: Integer;
      LSelIndex: Integer;
    begin
      Result := False;
      LThreeCount := Length(LCurPlaceSplit[sctThree]);
      if LThreeCount > 0 then
      begin
        LHasBigCard := False;
        LSelIndex := -1;

        for I := High(LCurPlaceSplit[sctThree]) downto Low(LCurPlaceSplit[sctThree]) do
        begin
          if LCurPlaceSplit[sctThree][I].CardType.TypeValue.Value > ALastCardType.TypeValue.Value then
          begin
            LHasBigCard := True;
            LSelIndex := I;
            Break;
          end;
        end;

        if LHasBigCard then
        begin
          if ALastCardType.TypeNum.Y > 0 then
          begin
            LTakeSuccess := GetSplitTakeCardNotChaiPai(LCurPlaceSplit, LCurPlaceSplit[sctThree][LSelIndex].CardType.TypeValue.Value,
              LCurPlaceSplit[sctThree][LSelIndex].CardType.TypeValue.Value, ALastCardType.TypeNum.N, ALastCardType.TypeNum.Y, LTakeCard);
            if LTakeSuccess then
            begin
              CopyGameCardAry(LCurPlaceSplit[sctThree][LSelIndex].CardAry, RetCardAry);
              AddGameCardAry(LTakeCard, 0, Length(LTakeCard), RetCardAry);
              DecSortCardAryByValue(RetCardAry);

              Result := True;
            end;
          end else
          begin
            CopyGameCardAry(LCurPlaceSplit[sctThree][LSelIndex].CardAry, RetCardAry);
            Result := True;          
          end;
        end;
      end;
    end;

    function Process3SeriesYaPai: Boolean;
    var
      L3SeriesCount: Integer;
      LHasBigCard: Boolean;
      I: Integer;
      LSelIndex: Integer;
    begin
      Result := False;
      L3SeriesCount := Length(LCurPlaceSplit[sct3Series]);
      if L3SeriesCount > 0 then
      begin
        LHasBigCard := False;
        LSelIndex := -1;

        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          if (LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X = ALastCardType.TypeNum.X)
            and (LCurPlaceSplit[sct3Series][I].CardType.TypeValue.Value > ALastCardType.TypeValue.Value) then
          begin
            LHasBigCard := True;
            LSelIndex := I;
            Break;
          end;
        end;

        if LHasBigCard then
        begin
          if ALastCardType.TypeNum.Y > 0 then
          begin
            LTakeSuccess := GetSplitTakeCardNotChaiPai(LCurPlaceSplit,
              TCardValue(Ord(LCurPlaceSplit[sct3Series][LSelIndex].CardType.TypeValue.Value) - ALastCardType.TypeNum.Y + 1),
              LCurPlaceSplit[sct3Series][LSelIndex].CardType.TypeValue.Value, ALastCardType.TypeNum.N, ALastCardType.TypeNum.Y, LTakeCard);
            if LTakeSuccess then
            begin
              CopyGameCardAry(LCurPlaceSplit[sct3Series][LSelIndex].CardAry, RetCardAry);
              AddGameCardAry(LTakeCard, 0, Length(LTakeCard), RetCardAry);
              DecSortCardAryByValue(RetCardAry);

              Result := True;
            end;
          end else
          begin
            CopyGameCardAry(LCurPlaceSplit[sct3Series][LSelIndex].CardAry, RetCardAry);
            Result := True;          
          end;
        end;
      end;
    end;

  begin
    Result := False;
    if ALastCardType.TypeNum.M = 4 then
    begin
      if ALastCardType.TypeNum.Y = 2 then
      begin
        // 4带2
        Result := Process42YaPai;
      end;
    end else if ALastCardType.TypeNum.M = 3 then
    begin
      if ALastCardType.TypeNum.X = 1 then
      begin
        // 3条
        Result := ProcessThreeYaPai;
      end else
      begin
        // 3顺
        Result := Process3SeriesYaPai;      
      end;     
    end;
  end;

  function DoFetchSameCardType: Boolean;
  var
    LTmpCard: TGameCardAry;
  begin
    // 考虑按照自己的带牌原则，是否有相同牌型
    Result := CheckCommonTakeYaPai(LTmpCard);
    if Result then
    begin
      CopyGameCardAry(LTmpCard, RetCardAry);
    end else
    begin
      // 对于3张、3顺类型，4带2 处理带牌看是否可以压上
      Result := Check42Or3Or3SeriesYaPai;  
    end;      
  end;

  function DoFetchOutChaiPaiSingle(AIsOnlyToBomb: Boolean): Boolean;
  var
    I: Integer;
    LCurValue: TCardValue;
    LLastValue: TCardValue;
    LSelIndex: Integer;
    LTmpIndex: Integer;
  begin
    Result := False;
    LLastValue := ALastCardType.TypeValue.Value;

    // 先考虑拆2
    if LLastValue < scvB2 then
    begin
      for I := Low(LCurUserCard) to High(LCurUserCard) do
      begin
        LCurValue := LCurUserCard[I].Value;
        if LCurValue < scvB2 then
          Break;
        if LCurValue = scvB2 then
        begin
          AddGameCardAry(LCurUserCard, I, 1, RetCardAry);
          Result := True;
          Exit;
        end;
      end;
    end;
    // 拆6连以上的单顺顶张
    if Length(LCurPlaceSplit[sct1Series]) > 0 then
    begin
      if LCurPlaceSplit[sct1Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct1Series]) downto Low(LCurPlaceSplit[sct1Series]) do
        begin
          if LCurPlaceSplit[sct1Series][I].CardType.TypeNum.X >= 6 then
          begin
            LSelIndex := -1;
            LTmpIndex := High(LCurPlaceSplit[sct1Series][I].CardAry);
            if LCurPlaceSplit[sct1Series][I].CardAry[LTmpIndex].Value > LLastValue then
              LSelIndex := LTmpIndex
            else if LCurPlaceSplit[sct1Series][I].CardAry[0].Value > LLastValue then
              LSelIndex := 0;
            if LSelIndex >= 0 then
            begin
              AddGameCardAry(LCurPlaceSplit[sct1Series][I].CardAry, LSelIndex, 1, RetCardAry);
              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 拆对牌
    if Length(LCurPlaceSplit[sctPair]) > 0 then
    begin
      if LCurPlaceSplit[sctPair][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sctPair]) downto Low(LCurPlaceSplit[sctPair]) do
        begin
          LCurValue := LCurPlaceSplit[sctPair][I].CardType.TypeValue.Value;
          if LCurValue > LLastValue then
          begin
            AddGameCardAry(LCurPlaceSplit[sctPair][I].CardAry, 0, 1, RetCardAry);
            Result := True;
            Exit;
          end;       
        end;
      end;
    end;
    // 拆双王 手中牌炸弹<=1才拆双王
    if (Length(LCurPlaceSplit[sctBomb]) <= 1) and (Length(LCurPlaceSplit[sctRocket]) > 0) then
    begin
      AddGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, 1, 1, RetCardAry);
      Result := True;
      Exit;
    end;
    // 使用炸弹
    if Length(LCurPlaceSplit[sctBomb]) > 0 then
    begin
      LSelIndex := High(LCurPlaceSplit[sctBomb]);
      AddGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, 0, 4, RetCardAry);
      Result := True;
      Exit;
    end;
    // 使用火箭
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      AddGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, 0, 2, RetCardAry);
      Result := True;
      Exit;    
    end;
    if AIsOnlyToBomb then
      Exit;
    // 拆三条
    if Length(LCurPlaceSplit[sctThree]) > 0 then
    begin
      if LCurPlaceSplit[sctThree][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sctThree]) downto Low(LCurPlaceSplit[sctThree]) do
        begin
          LCurValue := LCurPlaceSplit[sctThree][I].CardType.TypeValue.Value;
          if LCurValue > LLastValue then
          begin
            AddGameCardAry(LCurPlaceSplit[sctThree][I].CardAry, 0, 1, RetCardAry);
            Result := True;
            Exit;
          end;       
        end;
      end;
    end;
    // 拆三顺
    if Length(LCurPlaceSplit[sct3Series]) > 0 then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          LSelIndex := -1;
          LTmpIndex := High(LCurPlaceSplit[sct3Series][I].CardAry);
          if LCurPlaceSplit[sct3Series][I].CardAry[LTmpIndex].Value > LLastValue then
            LSelIndex := LTmpIndex
          else if LCurPlaceSplit[sct3Series][I].CardAry[0].Value > LLastValue then
            LSelIndex := 0;
          if LSelIndex >= 0 then
          begin
            AddGameCardAry(LCurPlaceSplit[sct3Series][I].CardAry, LSelIndex, 1, RetCardAry);
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
    // 拆双顺
    if Length(LCurPlaceSplit[sct2Series]) > 0 then
    begin
      if LCurPlaceSplit[sct2Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct2Series]) downto Low(LCurPlaceSplit[sct2Series]) do
        begin
          LSelIndex := -1;
          LTmpIndex := High(LCurPlaceSplit[sct2Series][I].CardAry);
          if LCurPlaceSplit[sct2Series][I].CardAry[LTmpIndex].Value > LLastValue then
            LSelIndex := LTmpIndex
          else if LCurPlaceSplit[sct2Series][I].CardAry[0].Value > LLastValue then
            LSelIndex := 0;
          if LSelIndex >= 0 then
          begin
            AddGameCardAry(LCurPlaceSplit[sct2Series][I].CardAry, LSelIndex, 1, RetCardAry);
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
    // 拆5连单顺
    if Length(LCurPlaceSplit[sct1Series]) > 0 then
    begin
      if LCurPlaceSplit[sct1Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct1Series]) downto Low(LCurPlaceSplit[sct1Series]) do
        begin
          LSelIndex := -1;
          LTmpIndex := High(LCurPlaceSplit[sct1Series][I].CardAry);
          if LCurPlaceSplit[sct1Series][I].CardAry[LTmpIndex].Value > LLastValue then
            LSelIndex := LTmpIndex
          else if LCurPlaceSplit[sct1Series][I].CardAry[0].Value > LLastValue then
            LSelIndex := 0;
          if LSelIndex >= 0 then
          begin
            AddGameCardAry(LCurPlaceSplit[sct1Series][I].CardAry, LSelIndex, 1, RetCardAry);
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  function DoFetchOutChaiPaiPair(AIsOnlyToBomb: Boolean): Boolean;
  var
    I: Integer;
    LCurValue: TCardValue;
    LLastValue: TCardValue;
    LSelIndex: Integer;
    LTmpIndex: Integer;
  begin
    Result := False;
    LLastValue := ALastCardType.TypeValue.Value;

    // 先考虑拆4连以上的双顺顶张
    if Length(LCurPlaceSplit[sct2Series]) > 0 then
    begin
      if LCurPlaceSplit[sct2Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct2Series]) downto Low(LCurPlaceSplit[sct2Series]) do
        begin
          if LCurPlaceSplit[sct2Series][I].CardType.TypeNum.X >= 4 then
          begin
            LSelIndex := -1;
            LTmpIndex := High(LCurPlaceSplit[sct2Series][I].CardAry) - 1;
            if LCurPlaceSplit[sct2Series][I].CardAry[LTmpIndex].Value > LLastValue then
              LSelIndex := LTmpIndex
            else if LCurPlaceSplit[sct2Series][I].CardAry[0].Value > LLastValue then
              LSelIndex := 0;
            if LSelIndex >= 0 then
            begin
              AddGameCardAry(LCurPlaceSplit[sct2Series][I].CardAry, LSelIndex, 2, RetCardAry);
              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 使用炸弹
    if Length(LCurPlaceSplit[sctBomb]) > 0 then
    begin
      LSelIndex := High(LCurPlaceSplit[sctBomb]);
      AddGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, 0, 4, RetCardAry);
      Result := True;
      Exit;
    end;
    // 使用火箭
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      AddGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, 0, 2, RetCardAry);
      Result := True;
      Exit;    
    end;
    if AIsOnlyToBomb then
      Exit;
    // 拆双顺
    if Length(LCurPlaceSplit[sct2Series]) > 0 then
    begin
      if LCurPlaceSplit[sct2Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct2Series]) downto Low(LCurPlaceSplit[sct2Series]) do
        begin
          LSelIndex := -1;
          LTmpIndex := High(LCurPlaceSplit[sct2Series][I].CardAry) - 1;
          if LCurPlaceSplit[sct2Series][I].CardAry[LTmpIndex].Value > LLastValue then
            LSelIndex := LTmpIndex
          else if LCurPlaceSplit[sct2Series][I].CardAry[0].Value > LLastValue then
            LSelIndex := 0;
          if LSelIndex >= 0 then
          begin
            AddGameCardAry(LCurPlaceSplit[sct2Series][I].CardAry, LSelIndex, 2, RetCardAry);
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
    // 拆三条
    if Length(LCurPlaceSplit[sctThree]) > 0 then
    begin
      if LCurPlaceSplit[sctThree][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sctThree]) downto Low(LCurPlaceSplit[sctThree]) do
        begin
          LCurValue := LCurPlaceSplit[sctThree][I].CardType.TypeValue.Value;
          if LCurValue > LLastValue then
          begin
            AddGameCardAry(LCurPlaceSplit[sctThree][I].CardAry, 0, 2, RetCardAry);
            Result := True;
            Exit;
          end;       
        end;
      end;
    end;
    // 拆三顺
    if Length(LCurPlaceSplit[sct3Series]) > 0 then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          LSelIndex := -1;
          LTmpIndex := High(LCurPlaceSplit[sct3Series][I].CardAry) - 1;
          if LCurPlaceSplit[sct3Series][I].CardAry[LTmpIndex].Value > LLastValue then
            LSelIndex := LTmpIndex
          else if LCurPlaceSplit[sct3Series][I].CardAry[0].Value > LLastValue then
            LSelIndex := 0;
          if LSelIndex >= 0 then
          begin
            AddGameCardAry(LCurPlaceSplit[sct3Series][I].CardAry, LSelIndex, 2, RetCardAry);
            Result := True;
            Exit;
          end;
        end;
      end;
    end; 
  end;

  function DoFetchOutChaiPaiThree(AIsOnlyToBomb: Boolean): Boolean;
  var
    LHasBigCard: Boolean;
    I: Integer;
    LCurValue: TCardValue;
    LLastValue: TCardValue;
    LSelIndex: Integer;
    LTakeCard: TGameCardAry;
  begin
    Result := False;
    LLastValue := ALastCardType.TypeValue.Value;

    // 先考虑炸弹。因为不拆牌带牌的情况已经处理过了
    // 使用炸弹
    if Length(LCurPlaceSplit[sctBomb]) > 0 then
    begin
      LSelIndex := High(LCurPlaceSplit[sctBomb]);
      AddGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, 0, 4, RetCardAry);
      Result := True;
      Exit;
    end;
    // 使用火箭
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      AddGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, 0, 2, RetCardAry);
      Result := True;
      Exit;    
    end;

    if AIsOnlyToBomb then
      Exit;
    
    // 是否有大的3张
    LHasBigCard := False;
    LSelIndex := -1;
    if Length(LCurPlaceSplit[sctThree]) > 0 then
    begin
      if LCurPlaceSplit[sctThree][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sctThree]) downto Low(LCurPlaceSplit[sctThree]) do
        begin
          LCurValue := LCurPlaceSplit[sctThree][I].CardType.TypeValue.Value;
          if LCurValue > LLastValue then
          begin
            LSelIndex := I;
            LHasBigCard := True;
            Break;
          end;
        end;
      end;
    end;
    
    if LHasBigCard then
    begin
      if ALastCardType.TypeNum.Y > 0 then
      begin
        if GetSplitTakeCardChaiPai(LCurPlaceSplit, LCurPlaceSplit[sctThree][LSelIndex].CardType.TypeValue.Value,
          LCurPlaceSplit[sctThree][LSelIndex].CardType.TypeValue.Value, ALastCardType.TypeNum.N, ALastCardType.TypeNum.Y, LTakeCard) then
        begin
          CopyGameCardAry(LCurPlaceSplit[sctThree][LSelIndex].CardAry, RetCardAry);
          AddGameCardAry(LTakeCard, 0, Length(LTakeCard), RetCardAry);
          DecSortCardAryByValue(RetCardAry);
          
          Result := True;
          Exit;
        end;
      end else
      begin
        CopyGameCardAry(LCurPlaceSplit[sctThree][LSelIndex].CardAry, RetCardAry);
        Result := True;
        Exit;
      end;
    end;

    // 拆三顺 顺带牌，先考虑不拆牌，在考虑拆牌
    LHasBigCard := False;
    LSelIndex := -1;
    if Length(LCurPlaceSplit[sct3Series]) > 0 then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          LCurValue := LCurPlaceSplit[sct3Series][I].CardType.TypeValue.Value;
          if LCurValue > LLastValue then
          begin
            LSelIndex := I;
            LHasBigCard := True;
            Break;
          end;
        end;
      end;
    end;

    if LHasBigCard then
    begin
      if ALastCardType.TypeNum.Y > 0 then
      begin
        if GetSplitTakeCardChaiPai(LCurPlaceSplit,
          LCurPlaceSplit[sct3Series][LSelIndex].CardType.TypeValue.Value,
          LCurPlaceSplit[sct3Series][LSelIndex].CardType.TypeValue.Value, ALastCardType.TypeNum.N, ALastCardType.TypeNum.Y, LTakeCard) then
        begin
          AddGameCardAry(LCurPlaceSplit[sct3Series][LSelIndex].CardAry, 0, 3, RetCardAry);
          AddGameCardAry(LTakeCard, 0, Length(LTakeCard), RetCardAry);
          DecSortCardAryByValue(RetCardAry);
          
          Result := True;
          Exit;
        end;
      end else
      begin
        AddGameCardAry(LCurPlaceSplit[sct3Series][LSelIndex].CardAry, 0, 3, RetCardAry);
        Result := True;
        Exit;
      end;
    end;
  end;

  function DoFetchOutChaiPai3Series(AIsOnlyToBomb: Boolean): Boolean;
  var
    LHasBigCard: Boolean;
    I: Integer;
    LCurValue: TCardValue;
    LLastValue: TCardValue;
    LSelIndex: Integer;
    LTakeCard: TGameCardAry;
    LTmpRetCard: TGameCardAry;
  begin
    Result := False;
    LLastValue := ALastCardType.TypeValue.Value;

    // 使用炸弹
    if Length(LCurPlaceSplit[sctBomb]) > 0 then
    begin
      LSelIndex := High(LCurPlaceSplit[sctBomb]);
      AddGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, 0, 4, RetCardAry);
      Result := True;
      Exit;
    end;
    // 使用火箭
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      AddGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, 0, 2, RetCardAry);
      Result := True;
      Exit;    
    end;

    if AIsOnlyToBomb then
      Exit;

    // 先找相同的3顺
    LHasBigCard := False;
    SetLength(LTmpRetCard, 0);
    if Length(LCurPlaceSplit[sct3Series]) > 0 then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          if LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X = ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct3Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              CopyGameCardAry(LCurPlaceSplit[sct3Series][I].CardAry, LTmpRetCard);
              LHasBigCard := True;
              Break;
            end;
          end;
        end;
      end;
    end;
    // 看长三顺能否拆成小的三顺
    if (not LHasBigCard) and (Length(LCurPlaceSplit[sct3Series]) > 0) then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          if LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X > ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct3Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              AddGameCardAry(LCurPlaceSplit[sct3Series][I].CardAry, 0, ALastCardType.TypeNum.X * ALastCardType.TypeNum.M, LTmpRetCard);
              LHasBigCard := True;
              Break;
            end;
          end;
        end;
      end;
    end;

    if LHasBigCard then
    begin
      if ALastCardType.TypeNum.Y > 0 then
      begin
        if GetSplitTakeCardChaiPai(LCurPlaceSplit,
          TCardValue(Ord(LTmpRetCard[0].Value) - ALastCardType.TypeNum.Y + 1),
          LTmpRetCard[0].Value, ALastCardType.TypeNum.N, ALastCardType.TypeNum.Y, LTakeCard) then
        begin
          CopyGameCardAry(LTmpRetCard, RetCardAry);
          AddGameCardAry(LTakeCard, 0, Length(LTakeCard), RetCardAry);
          DecSortCardAryByValue(RetCardAry);
          
          Result := True;
          Exit;
        end;
      end else
      begin
        CopyGameCardAry(LTmpRetCard, RetCardAry);
        Result := True;
        Exit;
      end;
    end;
  end;

  function DoFetchOutChaiPai1Series(AIsOnlyToBomb: Boolean): Boolean;
  var
    I, J: Integer;
    LCurValue: TCardValue;
    LLastValue: TCardValue;
    LSelIndex: Integer;
  begin
    Result := False;
    LLastValue := ALastCardType.TypeValue.Value;

    // 相同张数的双顺
    if Length(LCurPlaceSplit[sct2Series]) > 0 then
    begin
      if LCurPlaceSplit[sct2Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct2Series]) downto Low(LCurPlaceSplit[sct2Series]) do
        begin
          if LCurPlaceSplit[sct2Series][I].CardType.TypeNum.X = ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct2Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              SetLength(RetCardAry, ALastCardType.TypeNum.X);
              for J := Low(RetCardAry) to High(RetCardAry) do
                RetCardAry[J] := LCurPlaceSplit[sct2Series][I].CardAry[J + J];

              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 可以分割成2套单顺的长连牌
    if Length(LCurPlaceSplit[sct1Series]) > 0 then
    begin
      if LCurPlaceSplit[sct1Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct1Series]) downto Low(LCurPlaceSplit[sct1Series]) do
        begin
          if LCurPlaceSplit[sct1Series][I].CardType.TypeNum.X >= ALastCardType.TypeNum.X + 5 then
          begin
            LCurValue := LCurPlaceSplit[sct1Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              AddGameCardAry(LCurPlaceSplit[sct1Series][I].CardAry, 0, ALastCardType.TypeNum.X, RetCardAry);
              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 使用炸弹
    if Length(LCurPlaceSplit[sctBomb]) > 0 then
    begin
      LSelIndex := High(LCurPlaceSplit[sctBomb]);
      AddGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, 0, 4, RetCardAry);
      Result := True;
      Exit;
    end;
    // 使用火箭
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      AddGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, 0, 2, RetCardAry);
      Result := True;
      Exit;    
    end;
    if AIsOnlyToBomb then
      Exit;
    // 相同张数的三顺
    if Length(LCurPlaceSplit[sct3Series]) > 0 then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          if LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X = ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct3Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              SetLength(RetCardAry, ALastCardType.TypeNum.X);
              for J := Low(RetCardAry) to High(RetCardAry) do
                RetCardAry[J] := LCurPlaceSplit[sct3Series][I].CardAry[J * 3];

              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 不同张数的连牌（并且剩余单张<=2）
    if Length(LCurPlaceSplit[sct1Series]) > 0 then
    begin
      if LCurPlaceSplit[sct1Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct1Series]) downto Low(LCurPlaceSplit[sct1Series]) do
        begin
          if LCurPlaceSplit[sct1Series][I].CardType.TypeNum.X <= ALastCardType.TypeNum.X + 2 then
          begin
            LCurValue := LCurPlaceSplit[sct1Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              AddGameCardAry(LCurPlaceSplit[sct1Series][I].CardAry, 0, ALastCardType.TypeNum.X, RetCardAry);
              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 不同张数的双顺
    if Length(LCurPlaceSplit[sct2Series]) > 0 then
    begin
      if LCurPlaceSplit[sct2Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct2Series]) downto Low(LCurPlaceSplit[sct2Series]) do
        begin
          if LCurPlaceSplit[sct2Series][I].CardType.TypeNum.X > ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct2Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              SetLength(RetCardAry, ALastCardType.TypeNum.X);
              for J := Low(RetCardAry) to High(RetCardAry) do
                RetCardAry[J] := LCurPlaceSplit[sct2Series][I].CardAry[J + J];

              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 不同张数的连牌（剩余单张>2）
    if Length(LCurPlaceSplit[sct1Series]) > 0 then
    begin
      if LCurPlaceSplit[sct1Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct1Series]) downto Low(LCurPlaceSplit[sct1Series]) do
        begin
          if LCurPlaceSplit[sct1Series][I].CardType.TypeNum.X > ALastCardType.TypeNum.X + 2 then
          begin
            LCurValue := LCurPlaceSplit[sct1Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              AddGameCardAry(LCurPlaceSplit[sct1Series][I].CardAry, 0, ALastCardType.TypeNum.X, RetCardAry);
              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 不同张数的三顺
    if Length(LCurPlaceSplit[sct3Series]) > 0 then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          if LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X > ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct3Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              SetLength(RetCardAry, ALastCardType.TypeNum.X);
              for J := Low(RetCardAry) to High(RetCardAry) do
                RetCardAry[J] := LCurPlaceSplit[sct3Series][I].CardAry[J * 3];

              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
  end;

  function DoFetchOutChaiPai2Series(AIsOnlyToBomb: Boolean): Boolean;
  var
    I, J: Integer;
    LCurValue: TCardValue;
    LLastValue: TCardValue;
    LSelIndex: Integer;
  begin
    Result := False;
    LLastValue := ALastCardType.TypeValue.Value;

    // 拆不同张数的双顺
    if Length(LCurPlaceSplit[sct2Series]) > 0 then
    begin
      if LCurPlaceSplit[sct2Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct2Series]) downto Low(LCurPlaceSplit[sct2Series]) do
        begin
          if LCurPlaceSplit[sct2Series][I].CardType.TypeNum.X > ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct2Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              SetLength(RetCardAry, ALastCardType.TypeNum.X * 2);
              for J := Low(RetCardAry) to High(RetCardAry) do
                RetCardAry[J] := LCurPlaceSplit[sct2Series][I].CardAry[J];

              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 使用炸弹
    if Length(LCurPlaceSplit[sctBomb]) > 0 then
    begin
      LSelIndex := High(LCurPlaceSplit[sctBomb]);
      AddGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, 0, 4, RetCardAry);
      Result := True;
      Exit;
    end;
    // 使用火箭
    if Length(LCurPlaceSplit[sctRocket]) > 0 then
    begin
      AddGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, 0, 2, RetCardAry);
      Result := True;
      Exit;    
    end;
    if AIsOnlyToBomb then
      Exit;
    // 拆不同张数的三顺
    if Length(LCurPlaceSplit[sct3Series]) > 0 then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          if LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X > ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct3Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              SetLength(RetCardAry, ALastCardType.TypeNum.X * 2);
              for J := Low(RetCardAry) to High(RetCardAry) do
              begin
                if J mod 2 = 0 then
                  RetCardAry[J] := LCurPlaceSplit[sct3Series][I].CardAry[(J * 3) div 2]
                else
                  RetCardAry[J] := LCurPlaceSplit[sct3Series][I].CardAry[((J - 1) * 3) div 2 + 1];
              end;

              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
    // 拆相同张数的三顺
    if Length(LCurPlaceSplit[sct3Series]) > 0 then
    begin
      if LCurPlaceSplit[sct3Series][0].CardType.TypeValue.Value > LLastValue then
      begin
        for I := High(LCurPlaceSplit[sct3Series]) downto Low(LCurPlaceSplit[sct3Series]) do
        begin
          if LCurPlaceSplit[sct3Series][I].CardType.TypeNum.X = ALastCardType.TypeNum.X then
          begin
            LCurValue := LCurPlaceSplit[sct3Series][I].CardType.TypeValue.Value;
            if LCurValue > LLastValue then
            begin
              SetLength(RetCardAry, ALastCardType.TypeNum.X * 2);
              for J := Low(RetCardAry) to High(RetCardAry) do
              begin
                if J mod 2 = 0 then
                  RetCardAry[J] := LCurPlaceSplit[sct3Series][I].CardAry[(J * 3) div 2]
                else
                  RetCardAry[J] := LCurPlaceSplit[sct3Series][I].CardAry[((J - 1) * 3) div 2 + 1];
              end;

              Result := True;
              Exit;
            end;
          end;
        end;
      end;
    end;
  end;

  // 是否只到炸弹：拆牌到使用炸弹时，停止拆牌
  function DoFetchOutChaiPai(AIsOnlyToBomb: Boolean): Boolean;
  var
    LX, LM: Integer;
  begin
    Result := False;

    // 不用处理炸弹和4带2
    LX := ALastCardType.TypeNum.X;
    LM := ALastCardType.TypeNum.M;
    
    if (LX = 1) and (LM = 1) then
    begin
      // 单牌
      Result := DoFetchOutChaiPaiSingle(AIsOnlyToBomb);
    end else if (LX = 1) and (LM = 2) then
    begin
      // 对牌
      Result := DoFetchOutChaiPaiPair(AIsOnlyToBomb);
    end else if (LX = 1) and (LM = 3) then
    begin
      // 三条
      Result := DoFetchOutChaiPaiThree(AIsOnlyToBomb);
    end else if (LX >= 2) and (LM = 3) then
    begin
      // 三顺
      Result := DoFetchOutChaiPai3Series(AIsOnlyToBomb);
    end else if (LX >= 5) and (LM = 1) then
    begin
      // 单顺
      Result := DoFetchOutChaiPai1Series(AIsOnlyToBomb);
    end else if (LX >= 3) and (LM = 2) then
    begin
      // 双顺
      Result := DoFetchOutChaiPai2Series(AIsOnlyToBomb);
    end;

    // 如果拆牌不成功，还有提示的大牌
    if not Result then
    begin
      CopyGameCardAry(LHintBiggerCard, RetCardAry);
      Result := True;
    end;
  end;

  // 能打则打
  // 先考虑相同牌型，再考虑拆牌
  function DoNengDaZeDa: Boolean;
  begin
    Result := DoFetchSameCardType;
    if not Result then
      Result := DoFetchOutChaiPai(False);
  end;

  function DoSelfFarmerShunPaiFor1_2(AMaxShun: TCardValue): Boolean;
  var
    I: Integer;
    LCurValue: TCardValue;
  begin
    Result := False;
    if (ALastCardType.TypeNum.X > 1) or (ALastCardType.TypeNum.M > 2) then
      Exit;
    if ALastCardType.TypeValue.Value >= AMaxShun then
      Exit;

    if ALastCardType.TypeNum.M = 1 then
    begin
      for I := High(LCurPlaceSplit[sctSingle]) downto Low(LCurPlaceSplit[sctSingle]) do
      begin
        LCurValue := LCurPlaceSplit[sctSingle][I].CardType.TypeValue.Value;
        if LCurValue > AMaxShun then
          Break;
        if LCurValue > ALastCardType.TypeValue.Value then
        begin
          CopyGameCardAry(LCurPlaceSplit[sctSingle][I].CardAry, RetCardAry);
          Result := True;
          Exit;
        end;
      end;
    end else if ALastCardType.TypeNum.M = 2 then
    begin
      for I := High(LCurPlaceSplit[sctPair]) downto Low(LCurPlaceSplit[sctPair]) do
      begin
        LCurValue := LCurPlaceSplit[sctPair][I].CardType.TypeValue.Value;
        if LCurValue > AMaxShun then
          Break;
        if LCurValue > ALastCardType.TypeValue.Value then
        begin
          CopyGameCardAry(LCurPlaceSplit[sctPair][I].CardAry, RetCardAry);
          Result := True;
          Exit;
        end;
      end;
    end;
  end;

  function CheckSelfFarmerAndPartnerPairOrSingle: Boolean;
  var
    LPartnerCardLen: Integer;

    // 地主出牌，自己是地主下家，看看自己是否可以顺同伙走
    function CheckShunPaiForPartner(APartnerCardValue: TCardValue): Boolean;
    var
      LCanAbsolutelyYaPai: Boolean;
      LFetchCard, LYaPaiLeftCard: TGameCardAry;
      LTmpScanAry: TCardScanItemAry;
      LCanShunPai: Boolean;
      LIsPartnerBig: Boolean;
    begin
      LIsPartnerBig := CheckHasBiggerCard(ALastCardType, LPartnerPlace);
      LCanShunPai := CheckHasShunPai1_2(LCurUserScanAry, LPartnerCardLen, APartnerCardValue);
      if LCanShunPai then
      begin
        // 是否可以绝对压过地主
        LCanAbsolutelyYaPai := CheckAbsolutelyYaPai(LFetchCard, LYaPaiLeftCard);
        // 剩余的牌是否可以顺同伙
        if LCanAbsolutelyYaPai then
        begin
          GetCardScanTable(LYaPaiLeftCard, sccNone, LTmpScanAry);
          DecSortCardScanAryByCount(LTmpScanAry);
          LCanShunPai := CheckHasShunPai1_2(LTmpScanAry, LPartnerCardLen, APartnerCardValue);
        end;

        if LCanAbsolutelyYaPai and LCanShunPai then
        begin
          // 如果自己可以绝对压上地主，即地主不能再压，则出牌压地主。
          CopyGameCardAry(LFetchCard, RetCardAry);
          Result := True;
        end else
        begin
          // 同伙剩余的牌可以压过地主，则不出, 否则，能打则打
          if LIsPartnerBig then
            Result := True
          else
            Result := DoNengDaZeDa;
        end;
      end else
      begin
        // 同伙剩余的牌可以压过地主，则不出, 否则，能打则打
        if LIsPartnerBig then
          Result := True
        else
          Result := DoNengDaZeDa;
      end;
    end;

    function DoSelfFarmerPartnerNoBigCard: Boolean;
    var
      LCanAbsolutelyYaPai: Boolean;
      LFetchCard, LYaPaiLeftCard: TGameCardAry;
      LCurValue: TCardValue;
      LMaxValue: TCardValue;
      LMaxIndex: Integer;
      I: Integer;
    begin
      // 本函数仅针对单牌和对子
      Result := False;
      
      // 是否可以绝对压过地主
      LCanAbsolutelyYaPai := CheckAbsolutelyYaPai(LFetchCard, LYaPaiLeftCard);
      if LCanAbsolutelyYaPai then
      begin
        // 如果自己可以绝对压上地主，即地主不能再压，则出牌压地主。
        CopyGameCardAry(LFetchCard, RetCardAry);
        Result := True;
      end else
      begin
        LMaxIndex := -1;
        LMaxValue := scvNone;
        for I := Low(LCurUserScanAry) to High(LCurUserScanAry) do
        begin
          if LCurUserScanAry[I].Count < ALastCardType.TypeNum.M then
          begin
            Break;
          end else
          begin
            LCurValue := LCurUserScanAry[I].Card.Value;
            if LCurValue > ALastCardType.TypeValue.Value then
            begin
              if LCurValue > LMaxValue then
              begin
                LMaxValue := LCurValue;
                LMaxIndex := I;
              end;           
            end;
          end;
        end;

        if LMaxIndex >= 0 then
        begin
          AddGameCardAry(LCurUserCard, LCurUserScanAry[LMaxIndex].Index, ALastCardType.TypeNum.M, RetCardAry);
          Result := True;
        end;
      end;
    end;

  begin
    Result := False;

    // 检测条件：自己是农民，并且同伙剩余1对牌、一张牌
    if ACurPlace = ALordPlace then
      Exit;
    LPartnerCardLen := Length(UserCard[LPartnerPlace]);
    if not IsCardAryPairOrSingle(LPartnerPlace) then
      Exit;

    // 自己是地主下家
    if not LIsSelfLordPrevious then
    begin
      // 如果地主没有出牌，则自己不出
      if ALastPlace <> ALordPlace then
        Result := True
      else
        Result := CheckShunPaiForPartner(UserCard[LPartnerPlace][0].Value);
    end else
    begin
      if ALastPlace = ALordPlace then
      begin
        // 如果最后一次是地主出牌
        // 如果地主剩余不是1对或者单张时，能打则打
        if IsCardAryPairOrSingle(ALordPlace) then
          Result := False
        else
          Result := DoNengDaZeDa; 
      end else
      begin
        if IsCardAryPairOrSingle(ALordPlace) then
        begin
          if not CheckHasBiggerCard(ALastCardType, ALordPlace) then
          begin
            // 如果地主不能压过同伙，则过牌
            Result := True;
          end else
          begin
            if (Length(UserCard[ALordPlace]) = 2)
              and (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = 1) then
            begin
              // 如果地主是对牌，同伙出的是单张，则过牌。
              Result := True;
            end else
            begin
              // 压死，让地主没有牌权；如果不能压死，则用最大顶。
              Result := DoSelfFarmerPartnerNoBigCard;
            end;
          end;
        end else
        begin
          // 如果地主剩余不是1对或者单张时
          // J以下的对或者单牌时，能顺则顺，最大能顺到J
          Result := DoSelfFarmerShunPaiFor1_2(scvJ);
        end;
      end;
    end;
  end;

  function FetchMaxCardFor1_2: Boolean;
  var
    I: Integer;
    LCurValue: TCardValue;
    LMaxIndex: Integer;
    LMaxValue: TCardValue;
  begin
    // 如果有双王，压单牌时优先用2
    Result := False;
    if (Length(LCurPlaceSplit[sctRocket]) > 0) and (ALastCardType.TypeValue.Value < scvB2) then
    begin
      for I := Low(LCurUserScanAry) to High(LCurUserScanAry) do
      begin
        LCurValue := LCurUserScanAry[I].Card.Value;
        if LCurValue < scvB2 then
          Break;
        if LCurValue = scvB2 then
        begin
          if LCurUserScanAry[I].Count < ALastCardType.TypeNum.M then
            Break;
            
          AddGameCardAry(LCurUserCard, LCurUserScanAry[I].Index, ALastCardType.TypeNum.M, RetCardAry);
          Result := True;
          Exit;
        end;
      end;
    end;

    LMaxIndex := -1;
    LMaxValue := scvNone;
    for I := Low(LCurUserScanAry) to High(LCurUserScanAry) do
    begin
      if LCurUserScanAry[I].Count < ALastCardType.TypeNum.M then
      begin
        Break;
      end else
      begin
        LCurValue := LCurUserScanAry[I].Card.Value;
        if LCurValue > ALastCardType.TypeValue.Value then
        begin
          if LCurValue > LMaxValue then
          begin
            LMaxValue := LCurValue;
            LMaxIndex := I;
          end;           
        end;
      end;
    end;

    if LMaxIndex >= 0 then
    begin
      AddGameCardAry(LCurUserCard, LCurUserScanAry[LMaxIndex].Index, ALastCardType.TypeNum.M, RetCardAry);
      Result := True;
    end;
  end;

  function DoSelfLordAndEnemy1_2: Boolean;
  begin
    if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M <= 2) then
    begin
      // 如果当前牌型是单牌或者对牌
      // 出可以打过对手最大单牌或者对牌（可以拆任何牌，优先拆2）
      Result := FetchMaxCardFor1_2;
    end else
    begin
      Result := DoNengDaZeDa;
    end;
  end;

  function DoSelfLordAndOneFarmer1Card: Boolean;
  begin
    if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = 1) then
    begin
      Result := FetchMaxCardFor1_2;
    end else
    begin
      Result := DoNengDaZeDa;
    end;
  end;

  function DoSelfLordAndOneFarmerPair: Boolean;
  begin
    if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = 2) then
    begin
      Result := FetchMaxCardFor1_2;
    end else
    begin
      Result := DoNengDaZeDa;
    end;
  end;

  // 如果都带单牌(包括4带2)，获得可以带单牌的最大数量
  function GetSplitCanTakeSingleCount(const ALeftCardSpit: TSplitCardAryAry): Integer;
  var
    I: Integer;
  begin
    // 4带2, 3带1
    Result := Length(ALeftCardSpit[sctBomb]) + Length(ALeftCardSpit[sctBomb])
      + Length(ALeftCardSpit[sctThree]);

    // 3顺
    for I := Low(ALeftCardSpit[sct3Series]) to High(ALeftCardSpit[sct3Series]) do
      Inc(Result, ALeftCardSpit[sct3Series][I].CardType.TypeNum.X);
  end;

  // 自己是农民，最后出牌不是单张， 地主剩余单张时的出牌方法
  // 如果按照一般的带牌方法，自己可以赢，则先出倒数第二大的牌，再出其他牌型
  // 否则，如果采用全带单牌方法，自己可以赢，则全带单牌出，出3带1\3顺带单\4带2，如果3顺不能带够牌，则拆成3带1
  function DoSelfFarmerAndEnemy1AndLastNot1: Boolean;
  var
    LLordSingleValue: TCardValue;
    LFirstFetchCardAry: TGameCardAry;
    LLeftCard: TGameCardAry;
    LLeftCardSpit: TSplitCardAryAry;
    LLeftTakeCardSplit: TSplitCardAryAry;

    function CheckCommonTakeCardSuccess: Boolean;
    var
      I: Integer;
    begin
      Result := True;
      for I := High(LLeftTakeCardSplit[sctSingle]) - 1 downto Low(LLeftTakeCardSplit[sctSingle]) do
      begin
        if LLeftTakeCardSplit[sctSingle][I].CardType.TypeValue.Value < LLordSingleValue then
          Result := False;

        Break;
      end;
    end;

    function CheckAllTakeSingleSuccess: Boolean;
    var
      I: Integer;
      LCanTakeSingleCount: Integer;
      LMustTakeCount: Integer;
    begin
      LMustTakeCount := 0;
      LCanTakeSingleCount := GetSplitCanTakeSingleCount(LLeftCardSpit);

      for I := High(LLeftCardSpit[sctSingle]) - 1 downto Low(LLeftCardSpit[sctSingle]) do
      begin
        if LLeftCardSpit[sctSingle][I].CardType.TypeValue.Value < LLordSingleValue then
          Inc(LMustTakeCount)
        else
          Break;
      end;

      Result := LCanTakeSingleCount >= LMustTakeCount;
    end;

    procedure DelFirstFetchCard(var FirstFetchCardAry: TGameCardAry);
    begin
      SetLength(FirstFetchCardAry, 0);
      if DoFetchSameCardType then
      begin
        CopyGameCardAry(RetCardAry, FirstFetchCardAry);
      end else
      begin
        CopyGameCardAry(LHintBiggerCard, FirstFetchCardAry);
      end;
      SetLength(RetCardAry, 0);
      
      CopyGameCardAry(LCurUserCard, LLeftCard);
      DelCardFromCardAry(FirstFetchCardAry, LLeftCard);
    end;

  begin
    LLordSingleValue := UserCard[ALordPlace][0].Value;
    
    DelFirstFetchCard(LFirstFetchCardAry);
    SplitCard(LLeftCard, LLeftCardSpit);
    CopySplitAry(LLeftCardSpit, LLeftTakeCardSplit);
    CalcTakesCard(LLeftTakeCardSplit);

    Result := CheckCommonTakeCardSuccess;
    if not Result then
      Result := CheckAllTakeSingleSuccess;
      
    if Result then
    begin
      CopyGameCardAry(LFirstFetchCardAry, RetCardAry);
    end else
    begin
      // 如果不能接牌，则不出
      Result := True;
    end;
  end;

  function DoSelfFarmerAndEnemy1_2(EnemyLen: Integer): Boolean;
  begin
    // 当前牌型和对手剩余牌型一样
    if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = EnemyLen) then
    begin
      // 地主是否最后出牌
      if ALastPlace = ALordPlace then
      begin
        Result := FetchMaxCardFor1_2;
      end else
      begin
        // 地主的牌是否大于同伙
        if CheckHasBiggerCard(ALastCardType, ALordPlace) then
          Result := FetchMaxCardFor1_2
        else
          Result := DoSelfFarmerShunPaiFor1_2(scvK);        
      end;
    end else
    begin
      // 地主是否最后出牌
      if ALastPlace = ALordPlace then
      begin
        Result := DoNengDaZeDa;
      end else
      begin
        if EnemyLen = 2 then
        begin
          Result := True;
        end else
        begin
          // 如果自己必赢，则能接就接
          // 如果自己必输，则不出。
          Result := DoSelfFarmerAndEnemy1AndLastNot1;
        end;
      end;
    end;
  end;

  function CheckEnemy1_2: Boolean;
  var
    LIsLordPrevious1_2, LIsLordNext1_2: Boolean;
    LLen1, LLen2: Integer;
  begin
    Result := False;

    // 检测条件
    if ACurPlace = ALordPlace then
    begin
      LIsLordPrevious1_2 := IsCardAryPairOrSingle(LLordPreviousPlace);
      LIsLordNext1_2 := IsCardAryPairOrSingle(LLordNextPlace);
      LLen1 := Length(UserCard[LLordNextPlace]);
      LLen2 := Length(UserCard[LLordPreviousPlace]);

      // 判断是否 对手一个剩余一张，另一个剩余一对牌
      if LIsLordPrevious1_2 and LIsLordNext1_2 and (LLen1 <> LLen2) then
        Result := DoSelfLordAndEnemy1_2
      else if LIsLordPrevious1_2 or LIsLordNext1_2 then
      begin
        if (LLen1 = 1) or (LLen2 = 1) then
          Result := DoSelfLordAndOneFarmer1Card
        else
          Result := DoSelfLordAndOneFarmerPair;
      end;
    end else
    begin
      LLen1 := Length(UserCard[ALordPlace]);
      if IsCardAryPairOrSingle(ALordPlace) then
      begin
        Result := DoSelfFarmerAndEnemy1_2(LLen1);
      end;
    end;
  end;

  function IsCardAryBombOrRocketAnd1_2(APlace: Integer): Boolean;
  var
    LCardLen: Integer;
    LCardType: TLordCardType;
  begin
    Result := False;

    LCardLen := Length(UserCard[APlace]);
    if (LCardLen = 2) or (LCardLen = 4) then
    begin
      CheckCardType(UserCard[APlace], LCardType);
      Result := IsBombCardType(LCardType);
    end;

    if not Result then
    begin
      if LCardLen = 3 then
      begin
        Result := (UserCard[APlace][0].Value = scvBJoker) and (UserCard[APlace][1].Value = scvSJoker);
      end else if LCardLen = 4 then
      begin
        Result := (UserCard[APlace][0].Value = scvBJoker) and (UserCard[APlace][1].Value = scvSJoker)
          and (UserCard[APlace][2].Value = UserCard[APlace][3].Value);
      end;               
    end;
  end;

  function CheckEmemyBombOrRocketAnd1_2: Boolean;
  begin
    if ACurPlace = ALordPlace then
    begin
      Result := IsCardAryBombOrRocketAnd1_2(LLordPreviousPlace)
        or IsCardAryBombOrRocketAnd1_2(LLordNextPlace);
    end else
    begin
      Result := IsCardAryBombOrRocketAnd1_2(ALordPlace);
    end;
  end;

  function FixRate(XRate: Integer): Boolean;
  begin
    Result := Random(100) < XRate;
  end;

  // 特殊情况不压牌 2012-2-15 添加
  function CheckSpecialDonotYaPai: Boolean;
  var
    LHintCardType: TLordCardType;
    LTmpSplitAryAry: TSplitCardAryAry;
  begin
    Result := False;

    CheckCardType(LHintBiggerCard, LHintCardType);
    if IsBombCardType(LHintCardType) then
    begin
      if XDiscardTurn = 1 then
      begin
        // 第一轮不出炸弹
        Result := True;
        Exit;
      end else if XDiscardTurn = 2 then
      begin
        // 第二轮不出王和2炸弹
        if LHintCardType.TypeValue.Value >= scvB2 then
        begin
          Result := True;
          Exit;
        end else if LHintCardType.TypeValue.Value >= scv10 then
        begin
          // 95% 不出10-A炸弹
          if FixRate(95) then
          begin
            Result := True;
            Exit;
          end;
        end else
        begin
          // 80% 不出3-9炸弹
          if FixRate(80) then
          begin
            Result := True;
            Exit;
          end;
        end;
      end;
    end;

    if (ALastCardType.TypeValue.Value < scvQ) and (LHintCardType.TypeValue.Value = scvB2) then
    begin
      if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = 3) then
      begin
        // 当对手手中持有的牌型多于3套时，不能用三张2去打对手Q以下的三张牌
        if SplitCard(UserCard[ALastPlace], LTmpSplitAryAry) >= 3 then
        begin
          Result := True;
          Exit;
        end;
      end else if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = 2) then
      begin
        // 当对手手中持有的牌型多于5套时，不能用对2去打对手Q以下的对牌
        if SplitCard(UserCard[ALastPlace], LTmpSplitAryAry) >= 5 then
        begin
          Result := True;
          Exit;
        end;
      end;              
    end;
  end;

  // 压对手牌逻辑
  function CommonFetchYaPai: Boolean;
  var
    LTmpCardAry: TGameCardAry;
    LTakeCard: TGameCardAry;
    LHasBiggerCard: Boolean;
    I: Integer;
    LCurValue: TCardValue;
    LSelIndex: Integer;
    LTmpInt: Integer;
  begin
    Result := False;

    // 如果对手剩余1个炸弹或者1双王，或者1双王+一单或者1双，则尽量不出
    if CheckEmemyBombOrRocketAnd1_2 then
    begin
      // 如果不是炸弹，当手中有相应牌跟则跟
      if ALastCardType.TypeNum.M <> 4 then
      begin
        Result := DoFetchSameCardType;
        if Result then
        begin
          Exit;
        end;
      end;
      
      Result := True;
      Exit;
    end;

    if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = 4) then
    begin
      // 默认不出
      Result := True;
      
      if ALastCardType.TypeNum.Y = 0 then
      begin
        // 如果要压的牌是炸弹
        // 如果炸弹个数>剩余牌把数，则炸
        if GetSplitTotalBaShu(LTakeCardSplit, sctRocket, sctBomb) > GetSplitTotalBaShu(LTakeCardSplit, sct3Series, sctSingle) then
        begin
          if CheckCommonTakeYaPai(LTmpCardAry) then
          begin
            CopyGameCardAry(LTmpCardAry, RetCardAry);
            Exit;
          end;
        end;
      end else
      begin
        // 如果要压的牌是4带2

        // 如果炸弹个数>剩余牌把数，则炸
        if GetSplitTotalBaShu(LTakeCardSplit, sctRocket, sctBomb) > GetSplitTotalBaShu(LTakeCardSplit, sct3Series, sctSingle) then
        begin
          if Length(LCurPlaceSplit[sctBomb]) > 0 then
          begin
            CopyGameCardAry(LCurPlaceSplit[sctBomb][High(LCurPlaceSplit[sctBomb])].CardAry, RetCardAry);
            Exit;
          end;
          if Length(LCurPlaceSplit[sctRocket]) > 0 then
          begin
            CopyGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, RetCardAry);
            Exit;
          end;
        end;

        // 手里如果有不拆牌的4带2【排除4个2】，则跟
        LHasBiggerCard := False;
        for I := High(LTakeCardSplit[sctBomb]) downto Low(LTakeCardSplit[sctBomb]) do
        begin
          LCurValue := LTakeCardSplit[sctBomb][I].CardType.TypeValue.Value;
          if (LCurValue < scvB2) and (LCurValue > ALastCardType.TypeValue.Value) then
          begin
            LHasBiggerCard := True;
            CopyGameCardAry(LTakeCardSplit[sctBomb][I].CardAry, LTmpCardAry);
          end;
        end;
        if not LHasBiggerCard then
        begin
          Exit;
        end;

        if GetSplitTakeCardNotChaiPai(LCurPlaceSplit, LTmpCardAry[0].Value, LTmpCardAry[0].Value,
          ALastCardType.TypeNum.N, ALastCardType.TypeNum.Y, LTakeCard) then
        begin
          CopyGameCardAry(LTmpCardAry, RetCardAry);
          AddGameCardAry(LTakeCard, 0, Length(LTakeCard), RetCardAry);
          DecSortCardAryByValue(RetCardAry);
        end;
      end;
    end;

    if Result then
      Exit;

    // 当手中有相应牌跟则跟
    Result := DoFetchSameCardType;
    if Result then
    begin
      Exit;
    end;

    // 对手出[Q及其以上]牌使用10以下炸弹
    if ALastCardType.TypeValue.Value >= scvQ then
    begin
      if Length(LCurPlaceSplit[sctBomb]) > 0 then
      begin
        LSelIndex := High(LCurPlaceSplit[sctBomb]);
        if LCurPlaceSplit[sctBomb][LSelIndex].CardType.TypeValue.Value <= scv10 then
        begin
          CopyGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, RetCardAry);
          Result := True;
          Exit;
        end;
      end;
    end;
    // 如自己剩余的牌型在5手以内，则出炸弹(不包括火箭和4个2)
    LTmpInt := GetSplitTotalBaShu(LTakeCardSplit, Low(TSplitCardType), High(TSplitCardType));
    if LTmpInt <= 5 then
    begin
      if Length(LCurPlaceSplit[sctBomb]) > 0 then
      begin
        LSelIndex := High(LCurPlaceSplit[sctBomb]);
        if LCurPlaceSplit[sctBomb][LSelIndex].CardType.TypeValue.Value < scvB2 then
        begin
          CopyGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, RetCardAry);
          Result := True;
          Exit;
        end;
      end;
    end;
    // 如剩余的牌型在3手内，则出火箭或者4个2，否则PASS。
    if LTmpInt <= 3 then
    begin
      if Length(LCurPlaceSplit[sctBomb]) > 0 then
      begin
        LSelIndex := High(LCurPlaceSplit[sctBomb]);
        CopyGameCardAry(LCurPlaceSplit[sctBomb][LSelIndex].CardAry, RetCardAry);
        Result := True;
        Exit;
      end;
      if Length(LCurPlaceSplit[sctRocket]) > 0 then
      begin
        CopyGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, RetCardAry);
        Result := True;
        Exit;
      end;
    end;

    if ALastCardType.TypeValue.Value <= scv10 then
    begin
      // 如果对手出的牌小于等于10， 则拆牌
      Result := DoFetchOutChaiPai(False);
    end else
    begin
      // 如果对手出的牌大于10

      // 如果对手出单和对，先看是否有2
      if (ALastCardType.TypeValue.Value < scvB2) and (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M <= 2) then
      begin
        for I := Low(LCurUserScanAry) to High(LCurUserScanAry) do
        begin
          if LCurUserScanAry[I].Count < ALastCardType.TypeNum.M then
            Break;
          if LCurUserScanAry[I].Card.Value = scvB2 then
          begin
            AddGameCardAry(LCurUserCard, LCurUserScanAry[I].Index, ALastCardType.TypeNum.M, RetCardAry);
            Result := True;
            Exit;
          end;                   
        end;
      end;

      Result := DoFetchOutChaiPai(True);
      if not Result then
        Result := True;
    end;
  end;

  // 农民压地主牌逻辑
  function CommonFetchSelfFarmerEnemyLord: Boolean;
  begin
    if LIsSelfLordPrevious then
    begin
      Result := CommonFetchYaPai;
    end else
    begin
      // 如果同伙不能压上地主
      if not CheckHasBiggerCard(ALastCardType, LPartnerPlace) then
      begin
        Result := CommonFetchYaPai;
      end else
      begin
        if not IsBombCardType(ALastCardType) then
        begin
          // 有相同牌型，则跟 否则Pass
          Result := DoFetchSameCardType;
          if not Result then
            Result := True;
        end else
        begin
          Result := CommonFetchYaPai;
        end;
      end;
    end;
  end;

  // 顺同伙牌逻辑
  function CommonFetchSelfFarmerEnemyPartner: Boolean;
  var
    I: Integer;
  begin
    if not LIsSelfLordPrevious then
    begin
      //  自己是地主下家 不跟
      Result := True;
      Exit;
    end;

    // 如果自己手里只剩余炸弹，则能炸则炸
    if GetSplitTotalBaShu(LCurPlaceSplit, sctRocket, sctBomb) = GetSplitTotalBaShu(LCurPlaceSplit, Low(TSplitCardType), High(TSplitCardType)) then
    begin
      for I := High(LCurPlaceSplit[sctBomb]) downto Low(LCurPlaceSplit[sctBomb]) do
      begin
        if IsNewCardTypeBigger(LCurPlaceSplit[sctBomb][I].CardType, ALastCardType) then
        begin
          CopyGameCardAry(LCurPlaceSplit[sctBomb][I].CardAry, RetCardAry);
          Result := True;
          Exit;        
        end;
      end;
      if Length(LCurPlaceSplit[sctRocket]) > 0 then
      begin
        CopyGameCardAry(LCurPlaceSplit[sctRocket][0].CardAry, RetCardAry);
        Result := True;
        Exit;
      end;
    end;
    // 如果同伙出>=Q，并且地主不能压上同伙，则不跟
    if ALastCardType.TypeValue.Value >= scvQ then
    begin
      if CheckHasBiggerCard(ALastCardType, ALordPlace) then
      begin
        Result := True;
        Exit;
      end;
    end;
    // 同伙出炸弹和4带2，不跟
    if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = 4) then
    begin
      Result := True;
      Exit;
    end;

    if (ALastCardType.TypeNum.X = 1) and (ALastCardType.TypeNum.M = 1) then
    begin
      // 如果是同伙出的是单并且大于等于A，则不跟，
      if ALastCardType.TypeValue.Value >= scvBA then
      begin
        Result := True;
        Exit;
      end;
    end else
    begin
      // 如果同伙出了K及以上非单牌型时，也不跟
      if ALastCardType.TypeValue.Value >= scvK then
      begin
        Result := True;
        Exit;
      end;
    end;
    // 否则当手中有相应牌跟则跟，否则不跟
    Result := DoFetchSameCardType;
    if not Result then
      Result := True;
  end;

  function CheckCommonFetch: Boolean;
  begin
    if ACurPlace = ALordPlace then
    begin
      Result := CheckSpecialDonotYaPai;
      if Result then
        Exit;
      Result := CommonFetchYaPai;
    end else
    begin
      if ALastPlace = ALordPlace then
      begin
        Result := CheckSpecialDonotYaPai;
        if Result then
          Exit;
        Result := CommonFetchSelfFarmerEnemyLord;
      end else
      begin
        Result := CommonFetchSelfFarmerEnemyPartner;
      end;
    end;
  end;

var
  LSplitCount: Integer;
begin
  // 处理玩家压牌
  SetLength(RetCardAry, 0);
  // 检测参数
  Result := CheckParams;
  if not Result then
    Exit;

  // 判断自己是否有压牌的能力
  if not CheckHasHintBiggerCard then
  begin
    Result := True;
    Exit;
  end;

  // 拆分当前玩家的牌
  LSplitCount := SplitCard(LCurUserCard, LCurPlaceSplit);
  if LSplitCount < 1 then
    Exit;
  // 处理带牌
  CopySplitAry(LCurPlaceSplit, LTakeCardSplit);
  CalcTakesCard(LTakeCardSplit);

  // 剩余1炸弹 + 1把其他牌型
  if CheckLeft1BombAnd1Other then
    Exit;

  // 检测是否可以一次出完，要排除带双王的情况。
  if CheckFetchOutAll then
    Exit;

  // 检测是压牌后否剩余牌必杀，即所有把数的牌最多有一把牌别人可以压过，并且可以不拆散牌压牌
  if CheckBiShaFetchOutAll then
    Exit;

  // 自己是农民，农民同伙剩余1对牌、一张牌
  if CheckSelfFarmerAndPartnerPairOrSingle then
    Exit;

  // 如果对手单张或者对牌
  if CheckEnemy1_2 then
    Exit;

  // 一般的出牌原则
  Result := CheckCommonFetch;

  // to do 先测试上面逻辑
  
//  if not Result then
//  begin
//    // 如果程序出错
//    CopyGameCardAry(LHintBiggerCard, RetCardAry);
//    Result := True;
//  end;
end;

end.
