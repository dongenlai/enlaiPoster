unit GsClient;

interface

uses
  Windows, Classes, Graphics, SysUtils, StrUtils, superobject, JaEncrypt,
  IdHTTPWebsocketClient, IdSocketIOHandling, JaContainers, TemplateCardGlobalST,
  TemplatePubUtils, Config, TemplateGameLogicProc, TemplateGlobalST, gamefrm,
  Types, MJType;

type
  // gs1 is client use only
  TGameStatus = (gsNone = 0, gsDealCard, gsDiscard, gsCalcResult, gs1Finished, gs1WaitOther);

  TNetParams = record
    _uid: Integer;
    _place: Integer;
    WeiDu: string;
    JingDu: string;
    IsFind: Integer;
    BaseScore: Integer;
    MaxRound: Integer;
    TableNum: string;
    VipType: Integer;
  end;

  TGameUserState = (gusNone = 0, gusAuthed, gusInTable);

  TTableUserState = (tusNone = 0, tusWaitNextRound, tusNomal, tusOffline, tusFlee);

  TUserBaseInfo = record
    userId: Integer;
    userType: Integer;
    score: Int64;
    bean: Int64;
    userName: string;
    nickName: string;
    sex: Integer;
    level: Integer;
    faceId: Integer;
    faceUrl: string;
  end;

  TGameUser = record
    baseInfo: TUserBaseInfo;
    state: TGameUserState;
    tableHandle: Integer;
    chairIndex: Integer;
    tstate: TTableUserState;
    isReady: Boolean;
    isTrust: Boolean;
    GameCard: TGameCardAry;
    incScore: Int64;
    incBean: Int64;
  end;

  TGameUserAry = array of TGameUser;

  TGsClient = class(TObject)
  private
    FGameFormHandle: THandle;
    FSocket: TIdHTTPWebsocketClient;
    FReceiveMsgList: TStringList;
    FMsgLock: TSyncObject; //FSocket has a lock
    FLock: TSyncObject;
    FNetParam: TNetParams;
    FStatus: TGameStatus;

    // lord data
    FGameLogic: TTemplateGameLogicProc;
    FUserAry: TGameUserAry;
    FCurUserId: Integer;
    FCurrPlace: Integer;
    FCurMulti: Integer;
    FDecTimeCount: Integer;
    FSeLDelSuit: Integer;
    FBackCard: TGameCardAry;
    FHandCards: TGameCardAry;
    FLastCards: TGameCardAry;
    FSelfLastCards: TGameCardAry;
    FLastCardType: TLordCardType;
    FLastDiscardId: Integer;
    FLandLordId: Integer;
    FFirstLandLordId: Integer;
    FBaseScore: Integer;
    FMinBean: Integer;
    FCurRound: Integer;
    FMaxRound: Integer;
    FTableNum: string;
    FHintMsg: string;
    FHuPaiMsg: string;
    FResultMsg: TStringList;
    FRoundMsg: TStringList;
    function GetConnected: Boolean;
    procedure DoDisconnect;
    procedure ClearGameRoundInfo;
    procedure PostGameRefreshMsg;
    procedure AddLog(const XMsg: string);
    procedure ClearIgnoreSelfUser();
    procedure DelUser(const XUserID: Integer);
    function AddUserBaseInfo(const XBaseInfo: TUserBaseInfo): Integer;
    procedure UpdateUserState(const XUserID: Integer; XState: TGameUserState);
    function FindUser(const XUserID: Integer): Integer;
    function DelACard(cardId: Integer): Boolean;
    procedure SortCards;
    procedure addMingPai(const str: string);

    procedure ProcReceivePackage;
    procedure ProcActionID(const XActionID: Integer; const XJson: ISuperObject);
    procedure MyOnReceiveTextData(const aData: string);
    procedure MyOnDisconnect(Sender: TObject);
  public
    FSelfMjCards: TIntegerDynArray;
    FSelfMJActionList: TAryPlayerMJActionMin;
    FSelfMingPaiList: TStringDynArray;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock;
    procedure UnLock;
    procedure Clear;
    procedure DoWork;
    procedure RefreshGameForm(XGameForm: TGameForm);
    procedure DecTimeCount(XGameForm: TGameForm);
    procedure SetGameFormHandle(XHandle: THandle);
    procedure Connect(const XHost: string; XPort: Integer; const XUserID: Integer; const XWeiDu, XJinDu: string; XIsFind, XBaseScore, XMaxRound, XVipType: Integer; const XTableNum: string);
    procedure SendData(const XData: string);
    procedure SendPackUpdateUserInfo;
    procedure SendPackOnTick;
    procedure SendPackSit;
    procedure SendPackChatMsg(const XMsg: string);
    procedure SendPackReady;
    procedure SendPackTrust(IsTrust: Integer);
    procedure SendPackDeclare(IsDeclare: Integer);
    procedure SendPackDiscard(var discard: TGameCardAry);
    procedure SendPackSwapCard(const cardsStr: string);
    procedure SendSelDelSuit(selSuit: Integer);
    procedure SendPackChuPai(ACardID: Integer);
    procedure SendPackQuestDisband(ctrlCode: Integer; isAgree: Integer);
    procedure SendPackDoAction(mjAction: TMJActionName; const AStr: string);
    procedure SendPackLiangGang(const AStr: string);
    property Connected: Boolean read GetConnected;
    property Status: TGameStatus read FStatus;
    property GameLogic: TTemplateGameLogicProc read FGameLogic;
  end;

implementation

uses
  MainFrm;

const
    CCAPTION_FANGWEI: array[0..3] of string = ('自己', '下家', '对家', '上家');

{ TGsClient }

procedure TGsClient.UnLock;
begin
  FLock.Unlock;
end;

procedure TGsClient.UpdateUserState(const XUserID: Integer; XState: TGameUserState);
var
  LUserIndex: Integer;
begin
  LUserIndex := FindUser(XUserID);
  if LUserIndex >= 0 then
  begin
    FUserAry[LUserIndex].state := XState;
  end;
end;

procedure TGsClient.AddLog(const XMsg: string);
begin
  MainForm.AddLog(Format('SelfId=%d {%s}', [FNetParam._uid, XMsg]));
end;

procedure TGsClient.addMingPai(const str: string);
var
  Llen: Integer;
begin
  Llen := Length(FSelfMingPaiList);
  SetLength(FSelfMingPaiList, Llen + 1);
  FSelfMingPaiList[LLen] := str;
end;

function TGsClient.AddUserBaseInfo(const XBaseInfo: TUserBaseInfo): Integer;
var
  LUserIndex: Integer;
begin
  LUserIndex := FindUser(XBaseInfo.userId);
  if LUserIndex >= 0 then
  begin
    FUserAry[LUserIndex].baseInfo := XBaseInfo;
    Result := LUserIndex;
  end
  else
  begin
    SetLength(FUserAry, Length(FUserAry) + 1);
    FUserAry[High(FUserAry)].baseInfo := XBaseInfo;
    Result := High(FUserAry);
  end;
end;

procedure TGsClient.Clear;
begin
  DoDisconnect;

  FMsgLock.Lock;
  try
    FReceiveMsgList.Clear;
  finally
    FMsgLock.Unlock;
  end;

  SetLength(FUserAry, 0);
  ClearGameRoundInfo();

  FNetParam._uid := 0;
  FStatus := gsNone;

  FBaseScore := 0;
  FMinBean := 0;
  FCurRound := 0;
  FMaxRound := 0;
  FTableNum := '';
end;

procedure TGsClient.ClearGameRoundInfo;
var
  I: Integer;
begin
  FDecTimeCount := -1;
  FCurUserId := -1;
  FCurMulti := 0;
  SetLength(FBackCard, 0);
  SetLength(FHandCards, 0);
  SetLength(FLastCards, 0);
  SetLength(FSelfLastCards, 0);
  InitLordCardType(FLastCardType);
  FLastDiscardId := -1;
  FLandLordId := -1;
  FFirstLandLordId := -1;
//  Inc(FCurRound);
//  if (FCurRound > FMaxRound) then
//    FCurRound := 0;

  for I := Low(FUserAry) to High(FUserAry) do
  begin
    FUserAry[I].isReady := False;
    FUserAry[I].isTrust := False;
    SetLength(FUserAry[I].GameCard, 0);
  end;
end;

procedure TGsClient.ClearIgnoreSelfUser;
var
  LSelfIndex: Integer;
begin
  LSelfIndex := FindUser(FNetParam._uid);
  if (LSelfIndex >= 0) then
  begin
    if (LSelfIndex > 0) then
      FUserAry[0] := FUserAry[LSelfIndex];
    SetLength(FUserAry, 1);
  end
  else
  begin
    SetLength(FUserAry, 0);
  end;
end;

procedure TGsClient.Connect(const XHost: string; XPort: Integer; const XUserID: Integer; const XWeiDu, XJinDu: string; XIsFind, XBaseScore, XMaxRound, XVipType: Integer; const XTableNum: string);
begin
  DoDisconnect;

  FNetParam._uid := XUserID;
  FNetParam.WeiDu := XWeiDu;
  FNetParam.JingDu := XJinDu;
  FNetParam.IsFind := XIsFind;
  FNetParam.BaseScore := XBaseScore;
  FNetParam.MaxRound := XMaxRound;
  FNetParam.TableNum := XTableNum;
  FNetParam.VipType := XVipType;

  FSocket.Host := XHost;
  FSocket.Port := XPort;
  FSocket.Connect;
  FSocket.UpgradeToWebsocket;
end;

constructor TGsClient.Create;
begin
  inherited;

  FLock := TSyncObject.Create;
  FLock.ThreadSafe := True;
  FMsgLock := TSyncObject.Create;
  FMsgLock.ThreadSafe := True;

  FGameFormHandle := 0;
  FSocket := TIdHTTPWebsocketClient.Create(nil);
  FSocket.SocketIOCompatible := False;
  FSocket.OnTextData := MyOnReceiveTextData;
  FSocket.OnDisconnected := MyOnDisconnect;

  FReceiveMsgList := TStringList.Create;
  FReceiveMsgList.Duplicates := dupAccept;
  FReceiveMsgList.Sorted := False;

  FGameLogic := TTemplateGameLogicProc.Create;
  FResultMsg := TStringList.Create;
  FRoundMsg := TStringList.Create;

  Clear;
end;

procedure TGsClient.DecTimeCount(XGameForm: TGameForm);
begin
  Lock;
  try
    if (FDecTimeCount > 0) then
    begin
      Dec(FDecTimeCount);
      XGameForm.UpdateDecTime(FDecTimeCount);
    end;
  finally
    UnLock;
  end;
end;

function TGsClient.DelACard(cardId: Integer): Boolean;
var
  LLen: Integer;
  i, j: Integer;
begin
  Result := False;
  LLen := Length(FSelfMjCards);
  for I := Llen -1 downto 0 do
  begin
    if FSelfMjCards[i] = cardId then
    begin
      Result := True;
      for J := i to LLen - 2 do
      begin
        FSelfMjCards[j] := FSelfMjCards[j + 1];
      end;
      SetLength(FSelfMjCards, llen - 1);
      Break;
    end;
  end;
end;

procedure TGsClient.DelUser(const XUserID: Integer);
var
  LUserIndex: Integer;
  I: Integer;
begin
  LUserIndex := FindUser(XUserID);
  if LUserIndex >= 0 then
  begin
    for I := LUserIndex to High(FUserAry) - 1 do
    begin
      FUserAry[I].baseInfo := FUserAry[I + 1].baseInfo;
      FUserAry[I].chairIndex := FUserAry[I + 1].chairIndex;
      FUserAry[I].state := FUserAry[I + 1].state;
      CopyGameCardAry(FUserAry[I + 1].GameCard, FUserAry[I].GameCard);
    end;

    SetLength(FUserAry, Length(FUserAry) - 1);
  end
end;

destructor TGsClient.Destroy;
begin
  FLock.Lock;
  try
    FreeAndNil(FSocket);
    FreeAndNil(FReceiveMsgList);
    FreeAndNil(FGameLogic);
    FreeAndNil(FMsgLock);
  finally
    FLock.Unlock;
  end;

  FreeAndNil(FLock);

  inherited;
end;

procedure TGsClient.DoDisconnect;
begin
  if FSocket.Connected then
  begin
    FSocket.Disconnect(False);
  end;

  // clear serverip  port or will reconnect auto
  FSocket.Host := '';
  FSocket.Port := 0;
end;

procedure TGsClient.DoWork;
begin
  FMsgLock.Lock;
  try
    ProcReceivePackage;
  finally
    FMsgLock.Unlock;
  end;
end;

function TGsClient.FindUser(const XUserID: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(FUserAry) to High(FUserAry) do
  begin
    if FUserAry[I].baseInfo.userId = XUserID then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TGsClient.GetConnected: Boolean;
begin
  Result := FSocket.Connected;
end;

procedure TGsClient.Lock;
begin
  FLock.Lock;
end;

procedure TGsClient.MyOnDisconnect(Sender: TObject);
begin
  AddLog('MyOnDisconnect');
  FStatus := gs1Finished;
end;

procedure TGsClient.MyOnReceiveTextData(const aData: string);
var
  LJson: ISuperObject;
begin
  if Pos('"action":3', aData) < 1 then
    AddLog(Format('Receive: %s', [aData]));

  LJson := SO(aData);
  if (LJson <> nil) and (LJson['action'] <> nil) then
  begin
    // OnTick proc
    if LJson['action'].AsInteger = 3 then
    begin
      ProcActionID(LJson['action'].AsInteger, LJson);
    end
    else
    begin
      FMsgLock.Lock;
      try
        FReceiveMsgList.Add(aData);
      finally
        FMsgLock.Unlock;
      end;
    end;
  end
  else
  begin
    AddLog(Format('nil json: %s', [aData]));
  end;
end;

procedure TGsClient.PostGameRefreshMsg;
begin
  if (0 <> FGameFormHandle) then
    PostMessage(FGameFormHandle, WM_MYREFRESH_GAME, Integer(Self), 0);
end;

procedure TGsClient.ProcActionID(const XActionID: Integer; const XJson: ISuperObject);

  procedure writeSelfAction(aAry: TSuperArray);
  var
    llen: Integer;
    i: integer;
    LItem: ISuperObject;
  begin
    llen := aAry.Length;
    setlength(FSelfMJActionList, llen);
    for I := 0 to llen - 1 do
    begin
      LItem := aAry.O[I];
      FSelfMJActionList[I].MJAName := TMJActionName(LItem['a'].AsInteger);
      FSelfMJActionList[I].ExpandStr := LItem['e'].AsString;
    end;
  end;

  procedure DoActionLoginResult;
  var
    LBaseInfo: TUserBaseInfo;
    LBaseJson: ISuperObject;
    LUserIndex: Integer;
  begin
    if (XJson['code'].AsInteger <> 0) then
    begin
      AddLog(Format('login failed: Msg=%s', [XJson['msg'].AsString]));
      FStatus := gs1Finished;
      Exit;
    end;
    LBaseJson := SO(XJson['baseInfo'].AsString);
    if (LBaseJson = nil) then
    begin
      AddLog(Format('nil json: %s', [XJson['baseInfo'].AsString]));
      Exit;
    end;
    LBaseInfo.userId := LBaseJson['userId'].AsInteger;
    LBaseInfo.userType := LBaseJson['userType'].AsInteger;
    LBaseInfo.score := LBaseJson['score'].AsInteger;
    LBaseInfo.bean := LBaseJson['bean'].AsInteger;
    LBaseInfo.userName := LBaseJson['userName'].AsString;
    LBaseInfo.nickName := LBaseJson['nickName'].AsString;
    LBaseInfo.sex := LBaseJson['sex'].AsInteger;
    LBaseInfo.level := LBaseJson['level'].AsInteger;
    LBaseInfo.faceId := LBaseJson['faceId'].AsInteger;
    LBaseInfo.faceUrl := LBaseJson['faceUrl'].AsString;

    LUserIndex := AddUserBaseInfo(LBaseInfo);
    FUserAry[LUserIndex].state := TGameUserState(XJson['userState'].AsInteger);

    if (FUserAry[LUserIndex].state <> gusInTable) then
      SendPackSit();
  end;

  procedure DoActionUpdateUserInfoResult;
  var
    LBaseInfo: TUserBaseInfo;
    LBaseJson: ISuperObject;
    LUserIndex: Integer;
  begin
    if (XJson['code'].AsInteger <> 0) then
    begin
      AddLog(Format('updateUserInfo failed: Msg=%s', [XJson['msg'].AsString]));
      FStatus := gs1Finished;
      Exit;
    end;

    LBaseJson := SO(XJson['baseInfo'].AsString);
    LBaseInfo.userId := LBaseJson['userId'].AsInteger;
    LBaseInfo.userType := LBaseJson['userType'].AsInteger;
    LBaseInfo.score := LBaseJson['score'].AsInteger;
    LBaseInfo.bean := LBaseJson['bean'].AsInteger;
    LBaseInfo.userName := LBaseJson['userName'].AsString;
    LBaseInfo.nickName := LBaseJson['nickName'].AsString;
    LBaseInfo.sex := LBaseJson['sex'].AsInteger;
    LBaseInfo.level := LBaseJson['level'].AsInteger;
    LBaseInfo.faceId := LBaseJson['faceId'].AsInteger;
    LBaseInfo.faceUrl := LBaseJson['faceUrl'].AsString;

    LUserIndex := FindUser(LBaseInfo.userId);
    if LUserIndex >= 0 then
    begin
      FUserAry[LUserIndex].baseInfo := LBaseInfo;
      AddLog(Format('updateUserInfo success uid=%d', [LBaseInfo.userId]));
    end
    else
    begin
      AddLog(Format('updateUserInfo failed uid=%d', [LBaseInfo.userId]));
    end;
  end;

  procedure DoActionOnTickResult;
  var
    LOldTick: Cardinal;
  begin
    LOldTick := XJson['tick'].AsInteger;
    //AddLog(Format('OnTick success diff=%d', [Cardinal(GetTickCount - LOldTick)]));
  end;

  procedure DoActionSitResult;
  begin
    ClearIgnoreSelfUser;
    if (XJson['code'].AsInteger <> 0) then
    begin
      AddLog(Format('Sit failed: Msg=%s', [XJson['msg'].AsString]));
      FStatus := gs1Finished;
      Exit;
    end;
    AddLog(Format('MSGID_CLIENT_SIT_RESP: %s', [XJson.AsString]));
    UpdateUserState(FNetParam._uid, TGameUserState(XJson['userState'].AsInteger));
    AddLog('Sit success ');

    // 自动ready
  //  SendData(Format('{"action":56,"i64param":0}', []));
    SendPackReady;
  end;

  procedure DoActionChatResult;
  begin
    if (XJson['code'].AsInteger <> 0) then
    begin
      AddLog(Format('chat failed: Msg=%s', [XJson['msg'].AsString]));
      Exit;
    end;

    AddLog(Format('chat success msg=%s', [XJson['chatMsg'].AsString]));
  end;

  procedure DoActionReadyResult;
  var
    LSelfIndex: Integer;
  begin
    if (XJson['code'].AsInteger <> 0) then
    begin
      FHintMsg := 'ready 失败' + XJson['msg'].AsString;
      AddLog(Format('ready failed: Msg=%s', [XJson['msg'].AsString]));
      Exit;
    end;

    LSelfIndex := FindUser(FNetParam._uid);
    if (LSelfIndex >= 0) then
    begin
      FUserAry[LSelfIndex].isReady := True;
      AddLog('Ready success');
    end
    else
    begin
      AddLog('Find self failed');

    end;
  end;

  procedure DoActionTrustResult;
  var
    LSelfIndex: Integer;
  begin
    AddLog(Format('IsTrust=%d', [XJson['isTrust'].AsInteger]));

    LSelfIndex := FindUser(FNetParam._uid);
    if (LSelfIndex >= 0) then
    begin
      FUserAry[LSelfIndex].isTrust := Boolean(XJson['isTrust'].AsInteger);
    end;

    if (XJson['code'].AsInteger <> 0) then
    begin
      AddLog(Format('Trust failed: Msg=%s', [XJson['msg'].AsString]));
    end;
  end;

  procedure DoActionSwapCardsResult;
  begin
    if (XJson['code'].AsInteger <> 0) then
    begin
      fhintmsg := '换牌失败，原因：' + XJson['msg'].AsString;
      FHintMsg := '换牌成功，等待其他玩家';
      AddLog(Format('swap cards failed: Msg=%s', [XJson['msg'].AsString]));
    end
    else
    begin
      FHintMsg := '换牌成功，等待其他玩家';
      AddLog('swap cards success');
    end;
  end;

  procedure DoActionSelDelSuitResult;
  begin
    if (XJson['code'].AsInteger <> 0) then
    begin
      fhintmsg := '选择打缺失败，原因：' + XJson['msg'].AsString;
      AddLog(Format('selDelSuit failed: Msg=%s', [XJson['msg'].AsString]));
    end
    else
    begin

      FHintMsg := '选择打缺成功，等待其他玩家';
      AddLog('selDelSuit success');
    end;
  end;

  procedure DoActionDiscardResult;
  begin
    if (XJson['code'].AsInteger <> 0) then
    begin
      AddLog(Format('discard failed: code=%d Msg=%s', [XJson['code'].AsInteger, XJson['msg'].AsString]));
    end
    else
    begin
      AddLog('discard success');
    end;

    ConvertJsonToGameCard(XJson['curCards'].AsArray, FHandCards);
  end;

  procedure DoActionBeginGameNotify;
  var
    LSelfIndex: Integer;
  begin
    LSelfIndex := FindUser(FNetParam._uid);
    if (LSelfIndex < 0) then
    begin
      AddLog('DoActionBeginGameNotify find user failed');
      Exit;
    end;

    FUserAry[LSelfIndex].tableHandle := XJson['tableHandle'].AsInteger;
    FUserAry[LSelfIndex].chairIndex := XJson['chairIndex'].AsInteger;
    FUserAry[LSelfIndex].isReady := Boolean(XJson['isReady'].AsInteger);
    FUserAry[LSelfIndex].tstate := TTableUserState(XJson['tuserState'].AsInteger);
    FStatus := TGameStatus(XJson['tbState'].AsInteger);

    FNetParam._place := XJson['chairIndex'].AsInteger;

    FBaseScore := XJson['baseScore'].AsInteger;
    FMinBean := XJson['minBean'].AsInteger;
    FCurRound := XJson['curRound'].AsInteger;
    FMaxRound := XJson['maxRound'].AsInteger;
    FTableNum := XJson['tableNum'].AsString;

    AddLog(Format('begin game table=%d chair=%d; baseScore=%d, minBean=%d, curRound=%d, maxRound=%d, tableNum =  %s ', [FUserAry[LSelfIndex].tableHandle, FUserAry[LSelfIndex].chairIndex, FBaseScore, FMinBean, FCurRound, FMaxRound, FTableNum]));

    // 其他玩家自动登录这个桌子，
    if length(FTableNum) > 0 then
    begin
      MainForm.CheckFindTable(FTableNum);
    end;
  end;

  procedure DoActionOtherEnterNotify;
  var
    LBaseInfo: TUserBaseInfo;
    LBaseJson: ISuperObject;
    LUserIndex: Integer;
  begin
    LBaseJson := SO(XJson['baseInfo'].AsString);
    LBaseInfo.userId := LBaseJson['userId'].AsInteger;
    LBaseInfo.userType := LBaseJson['userType'].AsInteger;
    LBaseInfo.score := LBaseJson['score'].AsInteger;
    LBaseInfo.bean := LBaseJson['bean'].AsInteger;
    LBaseInfo.userName := LBaseJson['userName'].AsString;
    LBaseInfo.nickName := LBaseJson['nickName'].AsString;
    LBaseInfo.sex := LBaseJson['sex'].AsInteger;
    LBaseInfo.level := LBaseJson['level'].AsInteger;
    LBaseInfo.faceId := LBaseJson['faceId'].AsInteger;
    LBaseInfo.faceUrl := LBaseJson['faceUrl'].AsString;

    LUserIndex := AddUserBaseInfo(LBaseInfo);
    FUserAry[LUserIndex].chairIndex := XJson['chairIndex'].AsInteger;
    FUserAry[LUserIndex].isReady := Boolean(XJson['isReady'].AsInteger);
    FUserAry[LUserIndex].tstate := TTableUserState(XJson['tuserState'].AsInteger);

    AddLog(Format('userId=%d Enter ', [LBaseInfo.userId]));
  end;

  procedure DoActionOtherLeaveNotify;
  var
    LUserId: Integer;
  begin
    LUserId := XJson['userId'].AsInteger;
    DelUser(LUserId);
    AddLog(Format('userId=%d leave ', [LUserId]));
  end;

  procedure DoActionForceLeaveNotify;
  begin
    AddLog(Format('force leave: code=%d, Msg=%s', [XJson['code'].AsInteger, XJson['msg'].AsString]));

    FStatus := gs1Finished;
  end;

  procedure DoActionOtherChatNotify;
  begin
    AddLog(Format('chat: userId=%d chatMsg=%s', [XJson['userId'].AsInteger, XJson['chatMsg'].AsString]));
  end;

  procedure DoActionOtherReadyNotify;
  var
    LUserIndex: Integer;
  begin
    LUserIndex := FindUser(XJson['userId'].AsInteger);
    if (LUserIndex < 0) then
    begin
      AddLog(Format('ready userId=%d not found', [XJson['userId'].AsInteger]));
    end
    else
    begin
      FUserAry[LUserIndex].isReady := True;

      AddLog(Format('ready userId=%d', [XJson['userId'].AsInteger]));
    end;
  end;

  procedure DoActionOtherStateNotify;
  var
    LUserIndex: Integer;
  begin
    LUserIndex := FindUser(XJson['userId'].AsInteger);
    if (LUserIndex < 0) then
    begin
      AddLog(Format('State Change userId=%d not found', [XJson['userId'].AsInteger]));
    end
    else
    begin
      FUserAry[LUserIndex].tstate := TTableUserState(XJson['tuserState'].AsInteger);
      FUserAry[LUserIndex].baseInfo.bean := XJson['bean'].AsInteger;

      AddLog(Format('State Change userId=%d', [XJson['userId'].AsInteger]));
    end;
  end;

  procedure DoActionSynNotify;
  var
    LUsers: TSuperArray;
    I: Integer;
    LItem: ISuperObject;
    LUserId: Integer;
    LUserIndex: Integer;
  begin
    AddLog('完整包同步：' + XJson.AsString);

    exit;

//    FCurUserId := XJson['curUserId'].AsInteger;
//    FCurMulti := XJson['curMulti'].AsInteger;
//    AddLog(Format('syn curMulti=%d', [FCurMulti]));
//
//    FDecTimeCount := XJson['decTimeCount'].AsInteger;
//    FLandLordId := XJson['landLordId'].AsInteger;
//    FFirstLandLordId := XJson['firstLandLordId'].AsInteger;
//    ConvertJsonToGameCard(XJson['cards'].AsArray, FHandCards);
//    ConvertJsonToGameCard(XJson['backCards'].AsArray, FBackCard);
//    FLastDiscardId := XJson['lastDiscardId'].AsInteger;
//    ConvertJsonToGameCard(XJson['lastDiscard'].AsArray, FLastCards);
//    FGameLogic.DecSortCardAryByValue(FLastCards);
//    FGameLogic.CheckCardType(FLastCards, FLastCardType);
//    if (FLastDiscardId = FNetParam._uid) then
//    begin
//      CopyGameCardAry(FLastCards, FSelfLastCards);
//    end;
//
//    LUsers := XJson['users'].AsArray;
//    for I := 0 to LUsers.Length - 1 do
//    begin
//      LItem := LUsers.O[I];
//      LUserId := LItem['userId'].AsInteger;
//      LUserIndex := FindUser(LUserId);
//      if (LUserIndex < 0) then
//      begin
//        AddLog(Format('DoActionSynNotify find userId=%d failed', [LUserId]));
//      end
//      else
//      begin
//        FUserAry[LUserIndex].isTrust := Boolean(LItem['isTrust'].AsInteger);
//        SetLength(FUserAry[LUserIndex].GameCard, LItem['cardCount'].AsInteger);
//      end;
//    end;
  end;

  procedure DoActionOtherTrustNotify;
  var
    LUserIndex: Integer;
  begin
    LUserIndex := FindUser(XJson['userId'].AsInteger);
    if (LUserIndex < 0) then
    begin
      AddLog(Format('trust Change userId=%d not found', [XJson['userId'].AsInteger]));
    end
    else
    begin
      FUserAry[LUserIndex].isTrust := Boolean(XJson['isTrust'].AsInteger);

      AddLog(Format('trust Change userId=%d trust=%d', [XJson['userId'].AsInteger, XJson['isTrust'].AsInteger]));
    end;
  end;

  // deal card
  procedure DoActionDealCardNotify;
  var
    I: Integer;
    cardAry: TSuperArray;
  begin
    FHintMsg := '开局了！！！请等待下一个换牌状态';
    AddLog(Format('开局发牌, 骰子值(%d, %d), 东风： %d, 从第 %d 玩家抓牌。',
      [XJson['dice0'].AsInteger, XJson['dice1'].AsInteger, XJson['eastP'].AsInteger,
      XJson['startP'].AsInteger]));

    cardary := XJson['cards'].AsArray;
    setLength(FSelfMjCards, cardAry.Length);

    for I := 0 to cardAry.Length - 1 do
    begin
      FSelfMjCards[i] := cardAry.I[I];
    end;

    FStatus := gsDealCard;

  end;

  // notify declare lord
  procedure DoActionStartSwapCardNotify;
  begin
//    FDecTimeCount := XJson['decTimeCount'].AsInteger;
//    FHintMsg := '请选择3张换牌';
//
//    AddLog(Format('swap Cards', []));

//    FStatus := gsSwapCard;
  end;

  procedure DoActionSelDelSuitNotify;
  var
    LAry: array of Integer;
    LSelfIndex: Integer;
    LSelfPlace: Integer;
  begin
    SetLength(LAry, 4);
    LAry[0] := XJson['U0'].AsInteger;
    LAry[1] := XJson['U1'].AsInteger;
    LAry[2] := XJson['U2'].AsInteger;
    LAry[3] := XJson['U3'].AsInteger;

    FCurrPlace := XJson['p'].AsInteger;
    FDecTimeCount := XJson['dT'].AsInteger;
    writeSelfAction(XJson['mjAction'].AsArray);

    LSelfIndex := FindUser(FNetParam._uid);
    lselfPlace := FUserAry[LSelfIndex].chairIndex;

    FSeLDelSuit := LAry[lselfPlace];

    FHintMsg := Format('选择打缺， 自己选择 %s, 所有人选择列表： %d -%d -%d-%d', [CMJSUIT_CAPTION[FSeLDelSuit], lary[0], lary[1], lary[2], lary[3]]);

    fstatus := gsDiscard;

    SetLength(LAry, 0);
  end;

  procedure DoActionDiscardNotify;
  var
    LTmpCard: TGameCardAry;
    LCardType: TLordCardType;
    discardUserId: Integer;
    leftCardCount: Integer;
    LUserIndex: Integer;
  begin
    discardUserId := XJson['discardUserId'].AsInteger;
    if (discardUserId <> -1) then
    begin
      leftCardCount := XJson['leftCardCount'].AsInteger;
      LUserIndex := FindUser(discardUserId);
      if (LUserIndex >= 0) then
        SetLength(FUserAry[LUserIndex].GameCard, leftCardCount);

      ConvertJsonToGameCard(XJson['cards'].AsArray, LTmpCard);
      AddLog(Format('%d discard=%s', [discardUserId, FGameLogic.GetCardAryHintMsg(LTmpCard)]));

      FGameLogic.DecSortCardAryByValue(LTmpCard);
      FGameLogic.CheckCardType(LTmpCard, LCardType);
      if LCardType.TypeValue.Value <> scvNone then
      begin
        CopyGameCardAry(LTmpCard, FLastCards);
        FLastCardType := LCardType;
        FLastDiscardId := discardUserId;
      end;
      if (discardUserId = FNetParam._uid) then
      begin
        CopyGameCardAry(LTmpCard, FSelfLastCards);
      end;

      if (discardUserId = FNetParam._uid) then
      begin
        if FGameLogic.IsDiscardInCardAry(LTmpCard, FHandCards) then
          FGameLogic.DelCardFromCardAry(LTmpCard, FHandCards);
      end;
    end
    else
    begin
      FLastDiscardId := FLandLordId;
    end;

    FCurUserId := XJson['curUserId'].AsInteger;
    FCurMulti := XJson['curMulti'].AsInteger;
    FDecTimeCount := XJson['decTimeCount'].AsInteger;

    if (FCurUserId = -1) then
      FStatus := gsCalcResult
    else
      FStatus := gsDiscard;

    if (FCurUserId = FNetParam._uid) then
    begin
      SetLength(FSelfLastCards, 0);
    end;
  end;

  // finished
  procedure DoActionGameResultNotify;
  var
    LScoresAry: TSuperArray;
    LItem: TSuperArray;
    LScoreItem: ISuperObject;
    I: Integer;
    LIncScoreAry: TIntegerDynArray;
    LStr: string;
    LBWinner: Boolean;
    LBZiMo: Boolean;
    LScores, LFan, LIncScore: Integer;
    LPlace, LPaoPlace: Integer;
    ltmpStr: string;
  begin
    AddLog(Format('游戏结束： %s', [XJson.AsString]));

    FCurMulti := XJson['baseScore'].AsInteger;
    FCurRound := XJson['curRound'].AsInteger;


    FResultMsg.Clear;

    FResultMsg.Add(Format('局数： %d/%d', [FCurRound, FMaxRound]));
    FResultMsg.Add('');

    FResultMsg.Add('各玩家的得分情况：');
    LItem := XJson['scores'].AsArray;
    for I := 0 to LItem.Length - 1 do
    begin
      LPlace := (I - FNetParam._place + 4) mod 4;

      LScoreItem := LItem.O[I];
      LFan := LScoreItem['sumFans'].AsInteger;
      LIncScore := LScoreItem['incZScore'].AsInteger;
      LScores := LScoreItem['ZScore'].AsInteger;
      if LFan > 0 then
        FResultMsg.Add(Format('%s: 番数 +%d, 分数 +%d  当前 %d', [CCAPTION_FANGWEI[LPlace],
          lfan, lincscore, lscores]))
      else
        FResultMsg.Add(Format('%s: 番数 %d, 分数 %d  当前 %d', [CCAPTION_FANGWEI[LPlace],
          lfan, lincscore, lscores]));
    end;

    FResultMsg.Add('');
    FResultMsg.Add('自己的输赢情况：');
    LItem := XJson['result' + inttostr(fnetparam._place)].AsArray;
    for I := 0 to LItem.Length - 1 do
    begin
      LScoreItem := LItem.O[I];
      LBWinner := LScoreItem['isWinner'].AsBoolean;
      LBZimo := LScoreItem['isZiMo'].AsBoolean;
      LScores := LScoreItem['scores'].AsInteger;
      LPaoPlace := LScoreItem['otherPlace'].AsInteger;
      LPlace := (LPaoPlace - FNetParam._place + 4) mod 4;
      if LBWinner then
      begin
        if not LBZiMo then
          LStr := Format('+ %d 赢 %s', [LScores, CCAPTION_FANGWEI[lpLACE]])
        else
          LStr := Format('+ %d 赢三家', [LScores * 3, CCAPTION_FANGWEI[lpLACE]])
      end
      else
        LStr := Format('- %d 输给 %s', [LScores, CCAPTION_FANGWEI[LPlace]]);
      FResultMsg.Add(LStr);
    end;

    ClearGameRoundInfo;
    FStatus := gsNone;
  end;

  procedure DoActionSwapCardsNotify;
//  var
//    I: Integer;
//    cardAry: TSuperArray;
//  const
//    CSTR_SWAP: array[0..2] of string = ('对家换牌', '上家拿下家', '下家拿上家');
  begin
//    FHintMsg := Format('%s 换牌， 拿走: %s, 拿来： %s;  --- 请选择缺牌---', [CSTR_SWAP[XJson['swapDirction'].AsInteger], XJson['delCards'].AsString, XJson['addCards'].AsString]);
//    addlog(fhintmsg);
//
//    FDecTimeCount := XJson['decTimeCount'].AsInteger;
//
//    cardary := XJson['cards'].AsArray;
//    setLength(FSelfMjCards, cardAry.Length);
//    for I := 0 to cardAry.Length - 1 do
//    begin
//      FSelfMjCards[i] := cardAry.I[I];
//    end;
//
//    FStatus := gsSelDeletCard;

  end;

  procedure DoActionMoPaiNotify;
  var
    LLen: Integer;
    FMoPaiPlace: Integer;
  begin
    AddLog('摸牌： ' + XJson.AsString);
    FHintMsg := Format('%d 摸牌 %s', [XJson['p'].AsInteger, CMJDATA_CAPTION[XJson['c'].AsInteger]]);

    FMoPaiPlace := XJson['p'].AsInteger;
    FCurrPlace := XJson['cP'].AsInteger;
    writeSelfAction(XJson['mjAction'].AsArray);
    FDecTimeCount := XJson['dT'].AsInteger;

    if FNetParam._place = FMoPaiPlace then
    begin
      LLen := Length(fselfMJCARDS);
      setlength(FSelfMJCards, Llen + 1);
      FSelfMJCards[llen] := XJson['c'].AsInteger;
    end;
  end;

  procedure DoActionChuPaiNotify();
  var
    LChuPaiCard: Integer;
    LChuPaiPlace: Integer;
    LBFind: Boolean;
  begin
    AddLog('出牌： ' + XJson.AsString);
    LChuPaiPlace := XJson['p'].AsInteger;
    LChuPaiCard := XJson['c'].AsInteger;
    FHintMsg := Format('%d 出牌 %s', [XJson['p'].AsInteger, CMJDATA_CAPTION[LChuPaiCard]]);

    FCurrPlace := XJson['cP'].AsInteger;
    FDecTimeCount := XJson['dT'].AsInteger;
    writeSelfAction(XJson['mjAction'].AsArray);

    if FNetParam._place = LChuPaiPlace then
    begin
      LBFind := DelACard(LChuPaiCard);
      if not LBFind then
      begin
        AddLog('出牌错误，找不到这张牌');
        FHintMsg := '出牌错误，找不到这张牌';
      end;

      SortCards;
    end;
  end;

  procedure DoActionPengGangNotify;
  var
    LDoActionPlace, LDoActionCardId, LLastPlace: Integer;
    LMJAction: TMJActionName;
    LBFind: Boolean;
  begin
    AddLog('碰杠： ' + XJson.AsString);
    LDoActionPlace := XJson['p'].AsInteger;
    LDoActionCardId := XJson['c'].AsInteger;
    LMJAction := TMJActionName(XJson['a'].AsInteger);
    LLastPlace := XJson['lP'].AsInteger;

    FCurrPlace := XJson['cP'].AsInteger;
    FDecTimeCount := XJson['dT'].AsInteger;
    writeSelfAction(XJson['mjAction'].AsArray);

    FHintMsg := Format('%d %s %d %s', [LDoActionPlace, CMJACTION_CAPTION[LMJAction], llastplace, CMJDATA_CAPTION[LDoActionCardId]]);

    if LDoActionPlace = FNetParam._place then
    begin
      if LMJAction = mjaPeng then
      begin
        LBFind := DelACard(LDoActionCardId) and DelACard(LDoActionCardId);
        addMingPai(CMJDATA_CAPTION[LDoActionCardId] + CMJDATA_CAPTION[LDoActionCardId] +
          CMJDATA_CAPTION[LDoActionCardId]);

      end else
      begin
        LBFind := DelACard(LDoActionCardId) and DelACard(LDoActionCardId) and DelACard(LDoActionCardId);
        addMingPai(CMJDATA_CAPTION[LDoActionCardId] + CMJDATA_CAPTION[LDoActionCardId] +
          CMJDATA_CAPTION[LDoActionCardId] + CMJDATA_CAPTION[LDoActionCardId]);
      end;

      if not LBFind then
      begin
        AddLog('动作错误，找不到牌');
        FHintMsg := '动作错误，找不到牌';
      end;
    end;
  end;

  procedure DoActionHuPaiNotify;
  var
    LHuPlace, LHuCardId, LDianPaoPlace, LScores, LHuCount, LPlace: Integer;
    LIsZiMo: Boolean;
    LScoreAry: TSuperArray;
    I: Integer;
    isQiangGang: Boolean;
  const
    CCaption_Hu: array[Boolean] of string = ('捉炮胡牌', '自摸胡牌');
  const
    CCAPTION_FANGWEI: array[0..3] of string = ('自己', '下家', '对家', '上家');
  begin
    AddLog('胡牌了： ' + XJson.AsString);

    LHuPlace := XJson['p'].AsInteger;
    LIsZiMo := XJson['isZiMo'].AsBoolean;
    LDianPaoPlace := XJson['lP'].AsInteger;
    LHuCardId := XJson['lC'].AsInteger;
    LHuCount := XJson['huCount'].AsInteger;
    isQiangGang := XJson['isQ'].AsBoolean;

    LScoreAry := XJson['zScores'].AsArray;
    for I := 0 to LScoreAry.Length - 1 do
    begin
      if i = FNetParam._place then
        LScores := LScoreAry.I[I];
    end;

    FCurrPlace := XJson['cP'].AsInteger;
    FDecTimeCount := XJson['dT'].AsInteger;
    writeSelfAction(XJson['mjAction'].AsArray);

    LPlace := (LHuPlace - FNetParam._place + 4) mod 4;
    FHintMsg := Format('%s %s, 胡 %s,  自己当前分数: %d， 一炮%d响',
      [CCAPTION_FANGWEI[LPlace], CCaption_Hu[LIsZiMo], CMJDATA_CAPTION[LHuCardId], LScores, LHuCount]);
    FHuPaiMsg := FHintMsg;

    if lhuplace = FNetParam._place then
    begin
      if LIsZiMo then
      begin
        // 删除手牌
        DelACard(LHuCardId);
      end;

      if isQiangGang then
      begin
        // todo: 抢杠胡牌，修改抢杠为碰
      end;
    end;
  end;

  procedure DoActionEndRoundNotify;
  var
    LItem: TSuperArray;
    LScoreItem: ISuperObject;
    I, LPlace: Integer;
    LZiMoHu, LZhuoPaoHu, LDianPao, LMingGang, LAnGang: Integer;
  begin
    FRoundMsg.Clear;
    LItem := XJson['countInfo'].AsArray;
    for I := 0 to LItem.Length - 1 do
    begin
      LPlace := (I - FNetParam._place + 4) mod 4;
      LScoreItem := LItem.O[I];
      LZiMoHu := LScoreItem['cntZiMoHu'].AsInteger;
      LZhuoPaoHu := LScoreItem['cntZhuoPaoHu'].AsInteger;
      LDianPao := LScoreItem['cntDianPao'].AsInteger;
      LMingGang := LScoreItem['cntMingGang'].AsInteger;
      LAnGang := LScoreItem['cntAnGang'].AsInteger;
      FRoundMsg.Add(Format('%s: ', [CCAPTION_FANGWEI[LPlace]]));
      FRoundMsg.Add(Format('  自摸胡: %d', [lzimohu]));
      FRoundMsg.Add(Format('  捉炮胡: %d', [lzhuopaohu]));
      FRoundMsg.Add(Format('  放炮: %d', [ldianpao]));
      FRoundMsg.Add(Format('  明杠: %d', [lminggang]));
      FRoundMsg.Add(Format('  暗杠: %d', [langang]));
    end;
  end;

  procedure DoActionQuestDisbandResult;
  var
    LStr: string;
  begin
    LStr := XJson['msg'].AsString;
    if (XJson['code'].AsInteger <> 0) then
    begin
      FHintMsg := '请求散桌失败， 原因： ' + LStr;
    end else
    begin
      FHintMsg := '请求散桌成功，请等待其他玩家选择。';
    end;
  end;

  procedure DoActionDisbandNotify;
  var
    ctrlCode, userId, isAgree: Integer;
  begin
    ctrlCode := XJson['ctrlCode'].AsInteger;
    userId := XJson['userId'].AsInteger;
    isAgree := XJson['isAgree'].AsInteger;

    if ctrlcode = 0 then
    begin
      // 玩家请求散桌，弹出选择框
      if(0 <> FGameFormHandle) then
      begin
        FHintMsg := Format('玩家 %d 请求散桌，您是否同意？', [userid]);
        PostMessage(FGameFormHandle, WM_MYSHOW_IS_AGREE, 0, 0);
      end;
    end else
    begin
      if isAgree = 1 then
        FHintMsg := Format('玩家 %d 同意散桌', [userid])
      else
      begin
        FHintMsg := Format('玩家 %d 反对散桌, 本次散桌失败', [userid]);
        PostMessage(FGameFormHandle, WM_MYSHOW_IS_AGREE, 1, 0);
      end;
    end;
  end;

  procedure DoActionChiNotify;
  var
    LDoActionPlace, LDoActionCardId, LLastPlace: Integer;
    LMJAction: TMJActionName;
    LBFind: Boolean;
    LOrder: Integer;
    LDel00, LDel01: Integer;
    LChiStr: string;
  begin
    AddLog('碰杠： ' + XJson.AsString);
    LDoActionPlace := XJson['p'].AsInteger;
    LDoActionCardId := XJson['c'].AsInteger;
    LOrder := XJson['order'].AsInteger;
    LMJAction := TMJActionName(XJson['a'].AsInteger);
    LLastPlace := XJson['lP'].AsInteger;

    FCurrPlace := XJson['cP'].AsInteger;
    FDecTimeCount := XJson['dT'].AsInteger;
    writeSelfAction(XJson['mjAction'].AsArray);

    FHintMsg := Format('%d %s %d %s', [LDoActionPlace,
      CMJACTION_CAPTION[LMJAction], LLastPlace,
      CMJDATA_CAPTION[LDoActionCardId]]);

    if LDoActionPlace = FNetParam._place then
    begin
      if LOrder = 0 then
      begin
        LDel00 := LDoActionCardId + 1;
        LDel01 := LDoActionCardId + 2;
        LChiStr := CMJDATA_CAPTION[LDoActionCardId] + CMJDATA_CAPTION[LDel00]
          + CMJDATA_CAPTION[LDel01];
      end
      else if LOrder = 1 then
      begin
        LDel00 := LDoActionCardId - 1;
        LDel01 := LDoActionCardId + 1;
        LChiStr := CMJDATA_CAPTION[LDel00] + CMJDATA_CAPTION[LDoActionCardId]
          + CMJDATA_CAPTION[LDel01];
      end
      else
      begin
        LDel00 := LDoActionCardId - 2;
        LDel01 := LDoActionCardId - 1;
        LChiStr := CMJDATA_CAPTION[LDel00] + CMJDATA_CAPTION[LDel01]
          + CMJDATA_CAPTION[LDoActionCardId];
      end;

      LBFind := DelACard(LDel00) and DelACard(LDel01);
      addMingPai(LChiStr);

      if not LBFind then
      begin
        AddLog('动作错误，找不到牌');
        FHintMsg := '动作错误，找不到牌';
      end;
    end;
  end;

  procedure DoActionSpecialNotify;
  var
    LDataAry: TSuperArray;
    LMoPaiAry: TSuperArray;
    I, J: Integer;
    LObj: ISuperObject;
    LFlag: Integer;
    LStr: string;
    LStringList: TStringList;
    LCardid: Integer;
    LPlace, LLen: Integer;
  begin
    FHintMsg := '玩家特殊杠';

    LPlace := XJson['p'].AsInteger;
    LDataAry := XJson['gangCards'].AsArray;
    lstr := '';
    for I := 0 to LDataAry.Length - 1 do
    begin
      LCardid := LDataAry.I[i];
      DelACard(LCardid);
      LStr := LStr + CMJDATA_CAPTION[LCardid] + ' ';
    end;


    writeSelfAction(XJson['mjAction'].AsArray);
  end;

begin
  AddLog(Format('proc Action=%d; json = %s', [XActionID, xjson.AsString]));   // try

  FHuPaiMsg := '';
  case XActionID of
    1:
      DoActionLoginResult;
    2:
      DoActionUpdateUserInfoResult;
    3:
      DoActionOnTickResult;
    4:
      DoActionSitResult;
    5:
      DoActionChatResult;
    6:
      DoActionReadyResult;
    7:
      DoActionTrustResult;
    8:
      DoActionSwapCardsResult;
    9:
      DoActionDiscardResult;
    10:
      DoActionSelDelSuitResult;
    11:
      DoActionQuestDisbandResult;
    21:
      DoActionBeginGameNotify;
    22:
      DoActionOtherEnterNotify;
    23:
      DoActionOtherLeaveNotify;
    24:
      DoActionForceLeaveNotify;
    25:
      DoActionOtherChatNotify;
    26:
      DoActionOtherReadyNotify;
    27:
      DoActionOtherStateNotify;
    28:
      DoActionSynNotify;
    29:
      DoActionOtherTrustNotify;
    30:
      DoActionDealCardNotify;
    31:
      DoActionStartSwapCardNotify;
    32:
      DoActionSelDelSuitNotify;
    33:
      DoActionDiscardNotify;
    34:
      DoActionGameResultNotify;
    36:
      DoActionSwapCardsNotify;
    37:
      DoActionMoPaiNotify;
    38:
      DoActionChuPaiNotify;
    39:
      DoActionPengGangNotify;
    40:
      DoActionHuPaiNotify;
    41:
      DoActionEndRoundNotify;
    42:
      DoActionDisbandNotify;
    43:
      DoActionChiNotify;
    46:
      DoActionSpecialNotify;

  else
    AddLog(Format('Not Process Action: %s', [XJson.AsString]));
  end;
end;

procedure TGsClient.ProcReceivePackage;
var
  I: Integer;
  LJson: ISuperObject;
begin
  for I := 0 to FReceiveMsgList.Count - 1 do
  begin
    LJson := SO(FReceiveMsgList[I]);
    if (LJson <> nil) and (LJson['action'] <> nil) then
    begin
      ProcActionID(LJson['action'].AsInteger, LJson);
      PostGameRefreshMsg;
    end
    else
    begin
      AddLog(Format('nil json: %s', [FReceiveMsgList[I]]));
    end;
    LJson := nil;
  end;

  FReceiveMsgList.Clear;
end;

procedure TGsClient.RefreshGameForm(XGameForm: TGameForm);

  function GetUserListStr(): string;
  var
    I: Integer;
  begin
    Result := '';
    for I := Low(FUserAry) to High(FUserAry) do
    begin
      Result := Result + Format('id=%d,chair=%d,bean=%d,incBean=%d,cardCount=%d; ', [FUserAry[I].baseInfo.userId, FUserAry[i].chairIndex, FUserAry[i].baseInfo.bean, FUserAry[I].incBean, Length(FUserAry[I].GameCard)]);
    end;
  end;

var
  LSelfIndex: Integer;
  I: Integer;
begin
  // in main thread
  Lock;
  try
    if (FNetParam._place = FCurrPlace) then
      XGameForm.Color := clWhite
    else
      XGameForm.Color := clSkyBlue;

    XGameForm.Caption := Format('uid:%d; place: %d; connect:%d', [FNetParam._uid, FNetParam._place, Ord(Connected)]);
    XGameForm.lblUserList.Caption := GetUserListStr;
    XGameForm.lblCurUserId.Caption := Format('curUser=%d', [FCurUserId]);
    XGameForm.lblCurMulti.Caption := Format('curMulti=%d', [FCurMulti]);
    XGameForm.lblLandLordId.Caption := Format('landLord=%d', [FLandLordId]);
    XGameForm.lblLastDiscardId.Caption := Format('LastDiscardId=%d', [FLastDiscardId]);
    XGameForm.UpdateDecTime(FDecTimeCount);
    XGameForm.clbSelSwapCard.Visible := False; // FStatus = gsSwapCard;
//    if (FStatus = gsSwapCard) then
//    begin
//      XGameForm.updateSwapUI(FSelfMjCards);
//    end;
//    XGameForm.btnSelWan.Visible := FStatus = gsSelDeletCard;
//    XGameForm.btnSelBing.Visible := FStatus = gsSelDeletCard;
//    XGameForm.btnSelTiao.Visible := FStatus = gsSelDeletCard;
    XGameForm.lblHint.Caption := FHintMsg;

    LSelfIndex := FindUser(FNetParam._uid);
    if (LSelfIndex >= 0) then
    begin
      XGameForm.chkTrust.Checked := FUserAry[LSelfIndex].isTrust;
    end;

    // to do for Test
    XGameForm.UpdateSelfCard(FSelfMjCards);
    XGameForm.UpdateSelfAction(FSelfMJActionList);
    XGameForm.UpdateMingPai(FSelfMingPaiList);
    XGameForm.lblLandLordId.caption := CMJSUIT_CAPTION[FSeLDelSuit];
    if Length(FHuPaiMsg) > 0 then
    begin
      XGameForm.lbHuPaiInfo.AddItem(FHuPaiMsg, nil);
      FHuPaiMsg := '';
    end;

    if FResultMsg.Count > 0 then
    begin
      XGameForm.lbHuPaiInfo.Clear;
      XGameForm.lbHuPaiInfo.AddItem('---游戏结束--', nil);
      XGameForm.lbHuPaiInfo.AddItem('', nil);
      for I := 0 to FResultMsg.Count - 1 do
      begin
        XGameForm.lbHuPaiInfo.AddItem(FResultMsg[I], nil);
      end;
      FResultMsg.Clear;
    end;

    if FRoundMsg.Count > 0 then
    begin
      XGameForm.lbHuPaiInfo.AddItem('', nil);
      XGameForm.lbHuPaiInfo.AddItem('--- 牌局结束 ---', nil);
      XGameForm.lbHuPaiInfo.AddItem('', nil);
      for I := 0 to FRoundMsg.Count - 1 do
      begin
        XGameForm.lbHuPaiInfo.AddItem(FRoundMsg[I], nil);
      end;
      FRoundMsg.Clear;
    end;

    // 一局游戏重新开始
    if FStatus = gsDealCard then
    begin
      XGameForm.lbHuPaiInfo.Clear;
      XGameForm.lbMingPai.Clear;
    end;

    //XGameForm.UpdateSelfCard(FHandCards, FBackCard, FLastCards);
  finally
    Unlock;
  end;
end;

procedure TGsClient.SendPackChatMsg(const XMsg: string);
begin
  Lock;
  try
    SendData(Format('{"action":55,"chatType":0, "isSplit":0, "packOrder":0, "chatMsg":"%s"}', [XMsg]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackChuPai(ACardID: Integer);
begin
  Lock;
  try
    SendData(Format('{"action":61,"cardId":%d}', [ACardId]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackDeclare(IsDeclare: Integer);
begin
  Lock;
  try
    SendData(Format('{"action":58,"isDeclare":%d}', [IsDeclare]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackDiscard(var discard: TGameCardAry);
begin
  Lock;
  try
    FGameLogic.DecSortCardAryByValue(discard);
    if FGameLogic.IsDiscardInCardAry(discard, FHandCards) then
      FGameLogic.DelCardFromCardAry(discard, FHandCards);
    SendData(Format('{"action":59,"cards":%s}', [ConvertGameCardToAryStr(discard)]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackDoAction(mjAction: TMJActionName;
  const AStr: string);
begin
  Lock;
  try
    SendData(Format('{"action":62,"mjAction":%d,"eS":"%s"}',
      [ord(mjaction), astr]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackLiangGang(const AStr: string);
begin
  Lock;
  try
    SendData(Format('{"action":66,"data":%s}',
      [astr]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendData(const XData: string);
begin
  if FSocket.Connected then
  begin
    if Pos('"action":53', XData) < 1 then
      AddLog('sendData: ' + XData);
    FSocket.SocketIO.Send(XData);

  end
  else
    AddLog('SendData not connected');
end;

procedure TGsClient.SendPackOnTick;
begin
  Lock;
  try
    SendData(Format('{"action":53,"tick":%d}', [GetTickCount]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackQuestDisband(ctrlCode, isAgree: Integer);
begin
  Lock;
  try
    SendData(Format('{"action":63,"ctrlCode":%d,"isAgree":%d}', [ctrlcode, isagree]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackReady;
begin
  Lock;
  try
    SendData(Format('{"action":56,"i64param":0}', []));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackTrust(IsTrust: Integer);
begin
  Lock;
  try
    SendData(Format('{"action":57,"isTrust":%d}', [IsTrust]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackUpdateUserInfo;
begin
  Lock;
  try
    SendData(Format('{"action":52}', []));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendSelDelSuit(selSuit: Integer);
begin
  Lock;
  try
    SendData(Format('{"action":60, "delSuit": %d}', [selSuit]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackSit;
begin
  Lock;
  try
    SendData(Format('{"action":54,"jingdu":%s,"weidu":%s,"isFind":%d,"selScore":%d,'+
    '"totalRound":%d,"tableNum":"%s","vipRoomType":%d,"canHuQingYiSe":0,"gangFanType":0}', // try
    [FNetParam.JingDu, FNetParam.WeiDu, FNetParam.IsFind, FNetParam.BaseScore, FNetParam.MaxRound, FNetParam.TableNum, fnetparam.VipType]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SendPackSwapCard(const cardsStr: string);
begin
  Lock;
  try

    SendData(Format('{"action":58, "cards":%s}', [cardsStr]));
  finally
    UnLock;
  end;
end;

procedure TGsClient.SetGameFormHandle(XHandle: THandle);
begin
  FGameFormHandle := XHandle;
end;

procedure TGsClient.SortCards;
var
  I, J: Integer;
  LMinIdx, LMinValue: Integer;
begin
  for I := 0 to Length(FSelfMjCards) - 2 do
  begin
    LMinIdx := I;
    LMinValue := FSelfMjCards[I];

    for J := I + 1 to Length(FSelfMjCards) - 1 do
    begin
      if FSelfMjCards[J] < LMinValue then
      begin
        LMinValue := FSelfMjCards[J];
        LMinIdx := J;
      end;
    end;

    if LMinIdx <> I then
    begin
      FSelfMjCards[LMinIdx] := FSelfMjCards[I];
      FSelfMjCards[I] := LMinValue;
    end;
  end;
end;

end.

