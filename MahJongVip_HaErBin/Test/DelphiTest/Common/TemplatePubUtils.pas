{*************************************************************************}
{                                                                         }
{  ��Ԫ˵��: ��Ϸ���ú���                                                 }
{                                                                         }
{ ----------------------------------------------------------------------- }
{                                                                         }
{  ��Ԫ��;:                                                              }
{                                                                         }
{   ʵ����Ϸ�Ĺ��ú����������ʼ�����жϡ����Ƶ�                          }
{                                                                         }
{*************************************************************************}

unit TemplatePubUtils;

interface

uses
  Windows, SysUtils, TemplateGlobalST, TemplateCardGlobalST, superobject;


// ��ʼ�����
procedure InitTemplateUserBaseInfo(var BaseInfo: TTemplateUserBaseInfo);
procedure InitTemplateUserGameInfo(var GameInfo: TTemplateUserGameInfo);
procedure InitTemplateUserScoreInfo(var ScoreInfo: TTemplateUserScoreStatInfo);
procedure InitTemplateUserInfo(var UserInfo: TTemplateUserInfo);
procedure InitTemplateUserInfoAry(var UserInfoAry: TTemplateUserInfoAry);
procedure InitTemplateBoolGameRule(var BoolGameRule: TTemplateBoolGameRuleAry);
procedure InitTemplateIntGameRule(var IntGameRule: TTemplateIntGameRuleAry);
procedure InitTemplateInt64GameRule(var Int64GameRule: TTemplateInt64GameRuleAry);
procedure InitLordCardType(var LordCardType: TLordCardType);

// ����
function  GetSystemRandomSeed: Integer;
function GetIntAbs(AInt: Integer): Integer;

// ����
procedure CopyGameCardAry(const ASource: TGameCardAry; var Dest: TGameCardAry);
procedure AddGameCardAry(const ASource: TGameCardAry; AFromIndex, AddLen: Integer; var Dest: TGameCardAry);
procedure InsertGameCardAry(const ASource: TGameCardAry; AFromIndex, ADestIndex, AddLen: Integer; var Dest: TGameCardAry);
procedure CopySplitAry(const ASource: TSplitCardAryAry; var Dest: TSplitCardAryAry);
procedure ConvertJsonToGameCard(const XSrc: TSuperArray; var Dest: TGameCardAry);
function ConvertGameCardToAryStr(const XSrc: TGameCardAry): string;

// �ж����
function IsTemplatePlaceValid(APlace: Integer): Boolean;
function IsCardAryAllBackCard(const ACardAry: TGameCardAry): Boolean;
function IsCardAryHasBackCard(const ACardAry: TGameCardAry): Boolean;
procedure CheckIntValue(AMin, AMax, ADef: Integer; var CurValue: Integer);
procedure CheckIntGameRule(var AIntRule: TTemplateIntGameRule);
procedure CheckInt64GameRule(var AInt64Rule: TTemplateInt64GameRule);

implementation

procedure InitTemplateUserBaseInfo(var BaseInfo: TTemplateUserBaseInfo);
begin
  BaseInfo.UserState := tusNoPlayer;
  BaseInfo.LoginID := CINVALID_ID;
  BaseInfo.IsReady := False;
  BaseInfo.IsRobot := False;
end;

procedure InitTemplateUserGameInfo(var GameInfo: TTemplateUserGameInfo);
begin
  GameInfo.ShowHideInfo := True;
  SetLength(GameInfo.CardAry, 0);
  GameInfo.TrustedType := lttNone;
  GameInfo.DeclareScore := High(Byte);
  SetLength(GameInfo.LastDiscard, 0);
  GameInfo.DiscardTimeOutCount := 0;
  GameInfo.TotalPassCount := 0;

  GameInfo.TotalDiscardCount := 0;
  SetLength(GameInfo.LastTurnCard, 0);
end;

procedure InitTemplateUserScoreInfo(var ScoreInfo: TTemplateUserScoreStatInfo);
begin
  FillChar(ScoreInfo, SizeOf(ScoreInfo), 0);
end;

procedure InitTemplateUserInfo(var UserInfo: TTemplateUserInfo);
begin
  InitTemplateUserBaseInfo(UserInfo.BaseInfo);
  InitTemplateUserGameInfo(UserInfo.GameInfo);  
  InitTemplateUserScoreInfo(UserInfo.ScoreInfo);  
end;

procedure InitTemplateUserInfoAry(var UserInfoAry: TTemplateUserInfoAry);
var
  I: Integer;
begin
  for I := Low(UserInfoAry) to High(UserInfoAry) do
  begin
    InitTemplateUserInfo(UserInfoAry[I]);

    UserInfoAry[I].BaseInfo.Place := I;
  end;
end;

procedure InitTemplateBoolGameRule(var BoolGameRule: TTemplateBoolGameRuleAry);
begin
  BoolGameRule[tbgrtIsWinnerFirstDeclare].CurValue := False;
  BoolGameRule[tbgrtIsWinnerFirstDeclare].GameRuleName := '�Ƿ�ʤ�߽з�';
  BoolGameRule[tbgrtIsWinnerFirstDeclare].DefValue := BoolGameRule[tbgrtIsWinnerFirstDeclare].CurValue;
end;

procedure InitTemplateIntGameRule(var IntGameRule: TTemplateIntGameRuleAry);
begin
  IntGameRule[tigrtReadyMaxTimeCount].CurValue := 10;
  IntGameRule[tigrtReadyMaxTimeCount].GameRuleName := '׼��ʱ��';
  IntGameRule[tigrtReadyMaxTimeCount].MinValue := 1;
  IntGameRule[tigrtReadyMaxTimeCount].MaxValue := MaxInt;
  IntGameRule[tigrtReadyMaxTimeCount].DefValue := IntGameRule[tigrtReadyMaxTimeCount].CurValue;

  IntGameRule[tigrtDealMaxTimeCount].CurValue := 5;
  IntGameRule[tigrtDealMaxTimeCount].GameRuleName := '����ʱ��';
  IntGameRule[tigrtDealMaxTimeCount].MinValue := 1;
  IntGameRule[tigrtDealMaxTimeCount].MaxValue := MaxInt;
  IntGameRule[tigrtDealMaxTimeCount].DefValue := IntGameRule[tigrtDealMaxTimeCount].CurValue;

  IntGameRule[tigrtDeclareMaxTimeCount].CurValue := 15;
  IntGameRule[tigrtDeclareMaxTimeCount].GameRuleName := '�з�ʱ��';
  IntGameRule[tigrtDeclareMaxTimeCount].MinValue := 1;
  IntGameRule[tigrtDeclareMaxTimeCount].MaxValue := MaxInt;
  IntGameRule[tigrtDeclareMaxTimeCount].DefValue := IntGameRule[tigrtDeclareMaxTimeCount].CurValue;

  IntGameRule[tigrtFirDiscardMaxTimeCount].CurValue := 20;
  IntGameRule[tigrtFirDiscardMaxTimeCount].GameRuleName := '��һ�γ���ʱ��';
  IntGameRule[tigrtFirDiscardMaxTimeCount].MinValue := 1;
  IntGameRule[tigrtFirDiscardMaxTimeCount].MaxValue := MaxInt;
  IntGameRule[tigrtFirDiscardMaxTimeCount].DefValue := IntGameRule[tigrtFirDiscardMaxTimeCount].CurValue;

  IntGameRule[tigrtDiscardMaxTimeCount].CurValue := 20;
  IntGameRule[tigrtDiscardMaxTimeCount].GameRuleName := '����ʱ��';
  IntGameRule[tigrtDiscardMaxTimeCount].MinValue := 1;
  IntGameRule[tigrtDiscardMaxTimeCount].MaxValue := MaxInt;
  IntGameRule[tigrtDiscardMaxTimeCount].DefValue := IntGameRule[tigrtDiscardMaxTimeCount].CurValue;

  IntGameRule[tigrtTimeOutMaxCount].CurValue := 3;
  IntGameRule[tigrtTimeOutMaxCount].GameRuleName := '��ʱ���ƴ���';
  IntGameRule[tigrtTimeOutMaxCount].MinValue := 1;
  IntGameRule[tigrtTimeOutMaxCount].MaxValue := MaxInt;
  IntGameRule[tigrtTimeOutMaxCount].DefValue := IntGameRule[tigrtTimeOutMaxCount].CurValue;

  IntGameRule[tigrtTimeOutTrustDiscardTimeCount].CurValue := 3;
  IntGameRule[tigrtTimeOutTrustDiscardTimeCount].GameRuleName := '��ʱ�йܳ���ʱ��';
  IntGameRule[tigrtTimeOutTrustDiscardTimeCount].MinValue := 1;
  IntGameRule[tigrtTimeOutTrustDiscardTimeCount].MaxValue := MaxInt;
  IntGameRule[tigrtTimeOutTrustDiscardTimeCount].DefValue := IntGameRule[tigrtTimeOutTrustDiscardTimeCount].CurValue;

  IntGameRule[tigrtUserTrustDiscardTimeCount].CurValue := 1;
  IntGameRule[tigrtUserTrustDiscardTimeCount].GameRuleName := '�û��йܳ���ʱ��';
  IntGameRule[tigrtUserTrustDiscardTimeCount].MinValue := 1;
  IntGameRule[tigrtUserTrustDiscardTimeCount].MaxValue := MaxInt;
  IntGameRule[tigrtUserTrustDiscardTimeCount].DefValue := IntGameRule[tigrtUserTrustDiscardTimeCount].CurValue;

  IntGameRule[tigrtShowResultTimeCount].CurValue := 5;
  IntGameRule[tigrtShowResultTimeCount].GameRuleName := '��ʾ��Ϸ���ʱ��';
  IntGameRule[tigrtShowResultTimeCount].MinValue := 1;
  IntGameRule[tigrtShowResultTimeCount].MaxValue := MaxInt;
  IntGameRule[tigrtShowResultTimeCount].DefValue := IntGameRule[tigrtShowResultTimeCount].CurValue;
end;

procedure InitTemplateInt64GameRule(var Int64GameRule: TTemplateInt64GameRuleAry);
begin
  Int64GameRule[ti64grtMinBean].CurValue := 1;
  Int64GameRule[ti64grtMinBean].GameRuleName := '������Ϸ��';
  Int64GameRule[ti64grtMinBean].MinValue := 0;
  Int64GameRule[ti64grtMinBean].MaxValue := High(Int64);
  Int64GameRule[ti64grtMinBean].DefValue := Int64GameRule[ti64grtMinBean].CurValue;

  Int64GameRule[ti64grtMaxBean].CurValue := High(Int64);
  Int64GameRule[ti64grtMaxBean].GameRuleName := '�����Ϸ��';
  Int64GameRule[ti64grtMaxBean].MinValue := Int64GameRule[ti64grtMinBean].CurValue;
  Int64GameRule[ti64grtMaxBean].MaxValue := High(Int64);
  Int64GameRule[ti64grtMaxBean].DefValue := Int64GameRule[ti64grtMaxBean].CurValue;
end;

procedure InitLordCardType(var LordCardType: TLordCardType);
begin
  LordCardType.TypeNum := CLD_NONE_TYPE_NUM;
  LordCardType.TypeValue := CSH_NONE_CARD; 
end;

function  GetSystemRandomSeed: Integer;
begin
  Result := Integer(GetTickCount);
end;

function GetIntAbs(AInt: Integer): Integer;
begin
  // ���Int�ľ���ֵ
  if AInt >= 0 then
    Result := AInt
  else
    Result := -AInt;
end;

procedure CopyGameCardAry(const ASource: TGameCardAry; var Dest: TGameCardAry);
var
  I: Integer;
begin
  SetLength(Dest, Length(ASource));
  
  for I := Low(Dest) to High(Dest) do
    Dest[I] := ASource[I];
end;

procedure AddGameCardAry(const ASource: TGameCardAry; AFromIndex, AddLen: Integer; var Dest: TGameCardAry);
var
  LLen: Integer;
  I: Integer;
begin
  // ΪDest����ƣ�  ASource�Ĵ�AFromIndex��ʼ������ΪAddLen
  if (AddLen <= 0) or (AFromIndex < 0) then
    Exit;
  if AFromIndex + AddLen > Length(ASource) then
    Exit;

  LLen := Length(Dest);
  SetLength(Dest, LLen + AddLen);
  for I := 0 to AddLen - 1 do
    Dest[LLen + I] := ASource[AFromIndex + I];
end;

procedure InsertGameCardAry(const ASource: TGameCardAry; AFromIndex, ADestIndex, AddLen: Integer; var Dest: TGameCardAry);
var
  LLen: Integer;
  I: Integer;
begin
  // ΪDest�����ƣ�  ASource�Ĵ�AFromIndex��ʼ������ΪAddLen�����뵽Dest��ADestIndex
  if (AddLen <= 0) or (AFromIndex < 0) or (ADestIndex < 0) then
    Exit;
  if (AFromIndex + AddLen > Length(ASource)) or (ADestIndex > Length(Dest)) then
    Exit;

  LLen := Length(Dest);
  SetLength(Dest, LLen + AddLen);

  // �ƶ�ԭ����
  for I := LLen - 1 downto ADestIndex do
    Dest[I + 1] := Dest[I];

  // ��ʼ����
  for I := 0 to AddLen - 1 do
    Dest[ADestIndex + I] := ASource[AFromIndex + I];
end;

procedure CopySplitAry(const ASource: TSplitCardAryAry; var Dest: TSplitCardAryAry);
var
  LSplitType: TSplitCardType;
  I: Integer;
begin
  for LSplitType := Low(ASource) to High(ASource) do
  begin
    SetLength(Dest[LSplitType], Length(ASource[LSplitType]));
    for I := Low(ASource[LSplitType]) to High(ASource[LSplitType]) do
    begin
      Dest[LSplitType][I].CardType := ASource[LSplitType][I].CardType;
      CopyGameCardAry(ASource[LSplitType][I].CardAry, Dest[LSplitType][I].CardAry);
      CopyGameCardAry(ASource[LSplitType][I].TakesCard, Dest[LSplitType][I].TakesCard);
    end;
  end;
end;

procedure ConvertJsonToGameCard(const XSrc: TSuperArray; var Dest: TGameCardAry);
var
  I: Integer;
  LItem: Integer;
begin
  SetLength(Dest, XSrc.Length);
  for I := 0 to XSrc.Length - 1 do
  begin
    LItem := XSrc.I[I];
    Dest[I].Color := TCardColor(LItem mod 10);
    Dest[I].Value := TCardValue(LItem div 10);
  end;
end;

function ConvertGameCardToAryStr(const XSrc: TGameCardAry): string;
var
  I: Integer;
  LValue: Integer;
begin
  Result := '[';

  for I := Low(XSrc) to High(XSrc) do
  begin
    LValue := Ord(XSrc[I].Value)*10 + Ord(XSrc[I].Color);

    if I = 0 then
      Result := Result + Format('%d', [LValue])
    else
      Result := Result + Format(',%d', [LValue]);
  end;

  Result := Result + ']';
end;

function IsTemplatePlaceValid(APlace: Integer): Boolean;
begin
  Result := (APlace >= Low(TTemplatePlace)) and (APlace <= High(TTemplatePlace));
end;

function IsCardAryAllBackCard(const ACardAry: TGameCardAry): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := Low(ACardAry) to High(ACardAry)do
  begin
    if ACardAry[I].Color <> sccBack then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function IsCardAryHasBackCard(const ACardAry: TGameCardAry): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(ACardAry) to High(ACardAry)do
  begin
    if ACardAry[I].Color = sccBack then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure CheckIntValue(AMin, AMax, ADef: Integer; var CurValue: Integer);
begin
  if (CurValue < AMin) or (CurValue > AMax) then
    CurValue := ADef;
end;

procedure CheckIntGameRule(var AIntRule: TTemplateIntGameRule);
begin
  if (AIntRule.CurValue < AIntRule.MinValue) or (AIntRule.CurValue > AIntRule.MaxValue) then
    AIntRule.CurValue := AIntRule.DefValue;
end;

procedure CheckInt64GameRule(var AInt64Rule: TTemplateInt64GameRule);
begin
  if (AInt64Rule.CurValue < AInt64Rule.MinValue) or (AInt64Rule.CurValue > AInt64Rule.MaxValue) then
    AInt64Rule.CurValue := AInt64Rule.DefValue;
end;

end.
