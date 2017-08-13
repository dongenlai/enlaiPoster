unit User;

interface

uses
  SysUtils, StrUtils, Config, MyDownUrl, superobject, GsClient;

type

  TRobotUserState = (rusWaiting, rusNone, rusGuestGenerate, rusLogin,
    rusEnterQueue, rusLoginGameServer, rusGame, rusFinish);

  TUser = class(TObject)
  private
    FRobotInfo: TJJBRobotUser;
    FIsGuest: Boolean;
    FState: TRobotUserState;
    FIsFind: Integer;
    FBaseScore: Integer;
    FRound: Integer;
    FTableNum: string;
    FVIPType: Integer;

    FNickName: string;
    FToken: string; // 自动登录用
    FAccess_token: string; // 登录分发、游戏服务器用
    FUserId: Int64;
    FBean: Int64;

    FServerIP: string;
    FServerPort: Integer;

    FGsClient: TGsClient;

    procedure CheckLoginSuccess(const XLoginStr: string);

    procedure DoUserStateNone;
    procedure DoUserStateGuestGenerate;
    procedure DoUserStateLogin;
    procedure DoUserStateEnterQueue;
    procedure DoUserStateLoginGameServer;
    procedure DoUserStateGame;
    procedure DoUserStateFinish;
  public
    constructor Create(const XRobotInfo: TJJBRobotUser);
    destructor Destroy; override;
    procedure Clear;
    procedure SetGameFormHandle(XHandle: THandle);
    procedure CreateTable(XBaseScore: Integer; XRound, XVIPType: Integer);
    procedure FindTable(XTableNum: string);

    procedure DoWork;

    property State: TRobotUserState read FState;
  end;

implementation

uses
  MainFrm;

function DownUrlStrUtf8(const URL: string; var RetStr: string): Boolean;
var
  LObj: TDownUrlObject;
  LStr: AnsiString;
begin
  LObj := TDownUrlObject.Create;
  try
    Result := LObj.DownUrlStr(URL, LStr);
    if Result then
    begin
      RetStr := Utf8ToAnsi(LStr);
      Result := Length(RetStr) > 0;
    end;
  finally
    LObj.Free;
  end;
end;

{ TUser }

procedure TUser.CheckLoginSuccess(const XLoginStr: string);
var
  LJson: ISuperObject;
  LResp: Integer;
begin
  LJson := SO(XLoginStr);

  LResp := LJson['response'].AsInteger;
  if LResp <> 1 then
  begin
    raise Exception.Create('CheckLoginSuccess failed: ' + XLoginStr);
  end;

  FNickName := LJson['nickName'].AsString;
  FToken := LJson['token'].AsString;
  FAccess_token := LJson['access_token'].AsString;
  FUserId := LJson['userId'].AsInteger;
  FBean := LJson['bean'].AsInteger;

  FState := rusLoginGameServer; // rusEnterQueue;
end;

procedure TUser.Clear;
begin
  FState := rusWaiting;
  FNickName := '';
  FToken := '';
  FAccess_token := '';
  FUserId := 0;
  FBean := 0;

  FServerIP := '';
  FServerPort := 0;

  FGsClient.Lock;
  try
    FGsClient.Clear;
  finally
    FGsClient.UnLock;
  end;
end;

constructor TUser.Create(const XRobotInfo: TJJBRobotUser);
begin
  inherited Create();

  FRobotInfo := XRobotInfo;
  FIsGuest := FRobotInfo.UserName = '0';

  FGsClient := TGsClient.Create;

  Clear;
end;

procedure TUser.CreateTable(XBaseScore, XRound, XVIPType: Integer);
begin
  Clear();
  FIsFind := 0;
  FBaseScore := XBaseScore;
  FRound := XRound;
  FTableNum := '';
  FVIPType := XVIPType;

  FState := rusNone;
end;

destructor TUser.Destroy;
begin
  // free FGsClient will not stop process

  inherited;
end;

procedure TUser.DoUserStateEnterQueue;
var
  LTmpStr: string;
  LRetStr: string;

  LJson: ISuperObject;
  LData: ISuperObject;
  LRetCode: Integer;
begin
  LTmpStr := Format('%s?accessToken=%s&isFind=%d&tableNum=%s',
    [ConfigMgr.FSUrl, ReplaceStr(FAccess_token, '+', '%2B'), FIsFind,
    FTableNum]);

  if not DownUrlStrUtf8(LTmpStr, LRetStr) then
  begin
    MainForm.AddLog(LTmpStr + ' failed!');
    Exit;
  end;

  LJson := SO(LRetStr);
  LRetCode := LJson['retCode'].AsInteger;
  if LRetCode <> 0 then
  begin
    raise Exception.Create
      ('DoUserStateEnterQueue failed: ' + LTmpStr + ' ' + LRetStr);
  end;

  LData := LJson['data'];

  FServerIP := LData['ip'].AsString;
  FServerPort := LData['port'].AsInteger;

  FState := rusLoginGameServer;
end;

procedure TUser.DoUserStateFinish;
begin
  if Random(100) < 50 then
  begin
    Clear;
  end
  else
  begin
    FGsClient.Lock;
    try
      FGsClient.Clear;
    finally
      FGsClient.UnLock;
    end;

    FState := rusLoginGameServer;
  end;
end;

procedure TUser.DoUserStateGame;
begin
  FGsClient.Lock;
  try
    if not FGsClient.Connected then
    begin
      MainForm.AddLog('reconnect');
      FState := rusFinish;
    end
    else
    begin
      FGsClient.DoWork;
      if FGsClient.Status = gs1Finished then
        FState := rusFinish;
    end;
  finally
    FGsClient.UnLock;
  end;
end;

procedure TUser.DoUserStateGuestGenerate;
var
  LUrl: string;
  LRetStr: string;
begin
  LUrl := Format('%s/interface/base_guestGenerateAndLogin.do',
    [ConfigMgr.HSUrl]);

  if not DownUrlStrUtf8(LUrl, LRetStr) then
  begin
    MainForm.AddLog(LUrl + ' failed!');
    Exit;
  end;

  CheckLoginSuccess(LRetStr);
end;

procedure TUser.DoUserStateLogin;
var
  LUrl: string;
  LRetStr: string;
begin
  LUrl := Format('%s/interface/base_login.do?loginAccount=%s&password=%s',
    [ConfigMgr.HSUrl, FRobotInfo.UserName, FRobotInfo.Password]);

  if not DownUrlStrUtf8(LUrl, LRetStr) then
  begin
    MainForm.AddLog(LUrl + ' failed!');
    Exit;
  end;

  CheckLoginSuccess(LRetStr);
end;

procedure TUser.DoUserStateLoginGameServer;
begin
  FGsClient.Lock;
  try
    FServerIP := ConfigMgr.ServerCfg.GSIP;
    FServerPort := ConfigMgr.ServerCfg.GSPort;

    if not FGsClient.Connected then
    begin
      FGsClient.Connect(FServerIP, FServerPort, FUserId, FRobotInfo.WeiDu,
        FRobotInfo.JingDu, FIsFind, FBaseScore, FRound, FVIPType, FTableNum);
    end;

    if not FGsClient.Connected then
    begin
      MainForm.AddLog(Format('Connect to %s:%d Failed!', [FServerIP,
          FServerPort]));
      Exit;
    end;

    MainForm.AddLog(Format('Connected Server=%s:%d', [FServerIP, FServerPort]));

    FGsClient.SendData(Format(
        '{"action":51,"accessToken":"%s","mac":"%s","whereFrom":2, "version": 1}',
        [FAccess_token, '00-0C-29-86-68-64']));

    FState := rusGame;
  finally
    FGsClient.UnLock;
  end;
end;

procedure TUser.DoUserStateNone;
begin
  if FIsGuest then
    FState := rusGuestGenerate
  else
    FState := rusLogin;
end;

procedure TUser.DoWork;
begin
  case FState of
    rusNone:
      DoUserStateNone;
    rusGuestGenerate:
      DoUserStateGuestGenerate;
    rusLogin:
      DoUserStateLogin;
    rusEnterQueue:
      DoUserStateEnterQueue;
    rusLoginGameServer:
      DoUserStateLoginGameServer;
    rusGame:
      DoUserStateGame;
    rusFinish:
      DoUserStateFinish;
  end;
end;

procedure TUser.FindTable(XTableNum: string);
begin
  Clear();
  FIsFind := 1;
  FBaseScore := 0;
  FRound := 0;
  FTableNum := XTableNum;

  FState := rusNone;
end;

procedure TUser.SetGameFormHandle(XHandle: THandle);
begin
  FGsClient.SetGameFormHandle(XHandle);
end;

end.
