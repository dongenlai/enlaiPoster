unit Config;

interface

uses
  Windows, SysUtils, Classes, Graphics, Forms, JaConfigMgr, JaContainers;

type

{ Types }

  TSimpleUserInfo = record
    userId: Int64;
    userType: Int64;
  end;
  TSimpleUserInfoAry = array of TSimpleUserInfo;

  // robot用户
  PJJBRobotUser = ^TJJBRobotUser;
  TJJBRobotUser = record
    UserName: string;       // 0表示自动生成游客
    Password: string;
    WeiDu: string;
    JingDu: string;
  end;
  TLoginUserRecArray = array of TJJBRobotUser;

  // 服务器配置
  TServerConfig = record
    HSUrl: string;
    FSUrl: string;
    ThreadCount: Integer;
    GameFormCount: Integer;
    GSIP: string;
    GSPort: integer;
  end;

{ TBcConfigMgr }

  TBcConfigMgr = class(TCustomConfigMgr)
  private
    FServerCfg: TServerConfig;
    FLoginUserList: TLoginUserRecArray;

    FLock: TSyncObject;
    FThreadIDAry: array of Cardinal;
  private
    procedure LoadFromFile;
    function GetIniFileName: string;

    procedure InitRobotUser(var AUser: TJJBRobotUser);

    function GetCurThreadHostIndex: Integer;
    function GetFSUrl: string;
    function GetHSUrl: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load;
    procedure GetLoginUserList(var List: TLoginUserRecArray);

    property ServerCfg: TServerConfig read FServerCfg;

    property HSUrl: string read GetHSUrl;
    property FSUrl: string read GetFSUrl;
  end;

var
  ConfigMgr: TBcConfigMgr;
   
implementation

const
  SConfigFileName = 'config.ini';

  SServer = 'Server';
  SUserName = 'UserName';
  SPassword = 'Password';


{ TBcConfigMgr }

constructor TBcConfigMgr.Create;
begin
  inherited;

  FLock := TSyncObject.Create;
  FLock.ThreadSafe := True;

  SetLength(FLoginUserList, 0);
  SetLength(FThreadIDAry, 0);

  Load;
end;

destructor TBcConfigMgr.Destroy;
begin
  FreeAndNil(FLock);

  inherited;
end;

function TBcConfigMgr.GetCurThreadHostIndex: Integer;
var
  LThreadID: Cardinal;
  I: Integer;
begin
  LThreadID := GetCurrentThreadId();

  Result := -1;

  FLock.Lock;
  try
    for I := Low(FThreadIDAry) to High(FThreadIDAry) do
    begin
      if FThreadIDAry[I] = LThreadID then
      begin
        Result := I;

        Break;
      end;
    end;

    if Result = -1 then
    begin
      SetLength(FThreadIDAry, Length(FThreadIDAry) + 1);
      FThreadIDAry[High(FThreadIDAry)] := LThreadID;

      Result := High(FThreadIDAry);
    end;
  finally
    FLock.Unlock;
  end;
end;

function TBcConfigMgr.GetFSUrl: string;
begin
  Result := Format(FServerCfg.FSUrl, [GetCurThreadHostIndex]);
end;

function TBcConfigMgr.GetHSUrl: string;
begin
  Result := Format(FServerCfg.HSUrl, [GetCurThreadHostIndex]);
end;

function TBcConfigMgr.GetIniFileName: string;
begin
  Result := ExtractFilePath(Application.ExeName) + SConfigFileName;
end;

procedure TBcConfigMgr.Load;

  procedure LoadLoginUserList;
  var
    I, LLen: Integer;
    LIsEnd: Boolean;
    LTmpStr: string;

    procedure ReadLoginID;
    begin
      LTmpStr := Format('UserName%.2d', [I]);
      LTmpStr := GetString(SUserName, LTmpStr, '');
    end;

    procedure CalcJingWeiDu(const XCfg: string);
    var
      LStrList: TStringList;
    begin
      LStrList := TStringList.Create;
      try
        LStrList.StrictDelimiter := True;
        LStrList.NameValueSeparator := #0;
        LStrList.QuoteChar := #0;
        LStrList.Duplicates := dupAccept;
        LStrList.Sorted := False;
        LStrList.Delimiter := ',';

        LStrList.DelimitedText := XCfg;
        if(2 = LStrList.Count)then
        begin
          FLoginUserList[LLen].WeiDu := LStrList[0];
          FLoginUserList[LLen].JingDu := LStrList[1];
        end;
      finally
        LStrList.Free;
      end;
    end;

  begin
    LIsEnd := False;
    I := Length(FLoginUserList);
    while not LIsEnd do begin
      Inc(I);
      ReadLoginID;
      if Length(LTmpStr) < 1 then begin
        LIsEnd := True;
      end
      else begin
        LLen := Length(FLoginUserList);
        SetLength(FLoginUserList, LLen + 1);
        InitRobotUser(FLoginUserList[LLen]);
        
        FLoginUserList[LLen].UserName := LTmpStr;
        FLoginUserList[LLen].Password := Trim(GetString(SPassword, Format('Pwd%.2d', [I]), ''));
        CalcJingWeiDu(Trim(GetString('UserPos', Format('Pos%.2d', [I]), '')));
      end;
    end;
  end;

  procedure LoadServerCfg;
  begin
    FServerCfg.HSUrl := Trim(GetString(SServer, 'HSUrl', ''));
    FServerCfg.FSUrl := Trim(GetString(SServer, 'FSUrl', ''));
    FServerCfg.ThreadCount := StrToIntDef(GetString(SServer, 'ThreadCount', '1'), 1);
    FServerCfg.GameFormCount := StrToIntDef(GetString(SServer, 'GameFormCount', ''), 0);
    FServerCfg.GSIP  := Trim(GetString(SServer, 'GSIP', ''));
    FServerCfg.GSPort := StrToIntDef(GetString(SServer, 'GSPort', ''), 0);
  end;

begin
  LoadFromFile;

  LoadLoginUserList;
  LoadServerCfg;
end;

procedure TBcConfigMgr.LoadFromFile;
var
  LStream: TMemoryStream;
  LBinStr: string;
begin
  LStream := TMemoryStream.Create;
  try
    try
      if FileExists(GetIniFileName) then
      begin
        LStream.LoadFromFile(GetIniFileName);
        System.SetString(LBinStr, PChar(LStream.Memory), LStream.Size);
      end;
      
      LoadFromStr(LBinStr);
    except
    end;
  finally
    LStream.Free;
  end;
end;

procedure TBcConfigMgr.GetLoginUserList(var List: TLoginUserRecArray);
var
  LFromIndex: Integer;
  I: Integer;
begin
  LFromIndex := Length(List);
    
  SetLength(List, Length(FLoginUserList));
  
  for I := LFromIndex to High(FLoginUserList) do
  begin
    List[I] := FLoginUserList[I];
  end;
end;

procedure TBcConfigMgr.InitRobotUser(var AUser: TJJBRobotUser);
begin
  AUser.UserName := '0';
  AUser.Password := '';
  AUser.WeiDu := '0.0';
  AUser.JingDu := '0.0';
end;

initialization
  ConfigMgr := TBcConfigMgr.Create;  

finalization
  ConfigMgr.Free;

end.
