unit MyDownUrl;

interface

uses
  Windows, SysUtils, Classes, WinInet, ActiveX;

// gameId
const C_GAME_ID: Integer = 1;

type

  PMyInternetContext = ^TMyInternetContext;
  TMyInternetContext = record
    Code: Integer;
    PConnetHandle: Pointer;
    PRequestHandle: Pointer;
    PConnectEvent: PHandle;
    PRequestOpenEvent: PHandle;
    PRequestCompleteEvent: PHandle;
  end;

  TDownUrlObject = class
  private
    FhSession: HINTERNET;

    FRequestHandle: HINTERNET;
    FConnetHandle: HINTERNET;
    FConnectEvent: THandle;
    FRequestOpenEvent:THandle;
    FRequestCompleteEvent: THandle;

    FContextConnect: TMyInternetContext;
    FContextRequest: TMyInternetContext;
  public
    constructor Create;
    destructor Destroy; override;

    function DownUrlStr(const URL: string; var RetStr: AnsiString): Boolean;
    function DownUrlToStream(const URL: string; const RetStream: TStream; XCanCache: Boolean): Boolean;
  end;

  TExeThreadEvent = procedure(XParam: Pointer) of object;
  
  TMyExeThreadEvent = class(TThread)
  private
    FExeEvent: TExeThreadEvent;
    FParam: Pointer;
    FSynEvent: TThreadMethod;
  protected
    procedure Execute; override;
  public
    constructor Create(XEvent: TExeThreadEvent; XParam: Pointer; XSynEvent: TThreadMethod);
    destructor Destroy; override;
  end;

  procedure DoExeThreadEvent(XEvent: TExeThreadEvent; XParam: Pointer; XSynEvent: TThreadMethod);

implementation

const
  CDownWait_Max = 20 * 1000;

  CDownContext_Code_Connect = 1;
  CDownContext_Code_Request = 2;

procedure InternetStatusCallbackForTDownUrlObject(hInt: HINTERNET; dwContext: DWORD_PTR;
    dwInternetStatus: DWORD; lpvStatusInformation: Pointer;
    dwStatusInformationLength: DWORD); stdcall;
var
  InternetAsyncResult: TInternetAsyncResult;
  LPContext: PMyInternetContext;
begin
  if not (dwInternetStatus in [INTERNET_STATUS_HANDLE_CREATED,
    INTERNET_STATUS_REQUEST_COMPLETE]) then
  begin
    Exit;
  end;

  LPContext := PMyInternetContext(dwContext);
  if LPContext = nil then
    Exit;  

  case LPContext^.Code of
    CDownContext_Code_Connect:
      if (dwInternetStatus = INTERNET_STATUS_HANDLE_CREATED) then
      begin
        InternetAsyncResult:=TInternetAsyncResult(lpvStatusInformation^);
        Pointer((LPContext^.PConnetHandle)^) := Pointer(InternetAsyncResult.dwResult);
        SetEvent((LPContext^.PConnectEvent)^);
      end;
    CDownContext_Code_Request:
    case dwInternetStatus of
      INTERNET_STATUS_HANDLE_CREATED:
      begin
        InternetAsyncResult:=TInternetAsyncResult(lpvStatusInformation^);
        Pointer((LPContext^.PRequestHandle)^) := Pointer(InternetAsyncResult.dwResult);
        SetEvent((LPContext^.PRequestOpenEvent)^);
      end;
      INTERNET_STATUS_REQUEST_COMPLETE:
      begin
        SetEvent((LPContext^.PRequestCompleteEvent)^);
      end;
    end;
  end;
end;

function TDownUrlObject.DownUrlStr(const URL: string; var RetStr: AnsiString): Boolean;
const
  CLBufferSize = 1024*4;
  CLHttP = 'http://';
var
  LHeader: AnsiString;
  LReservered: Cardinal;
  LBufferStr: AnsiString;
  LbOK: Boolean;
  LInternetBuffer: TInternetBuffersA;
  LWaitResult: Cardinal;

  function GetHost(XTheURL: string): string;
  var
    LStr: string;
    LPos: Integer;
  begin
    Result := '';

    LPos := Pos(UpperCase(CLHttP), UpperCase(XTheURL));
    if LPos > 0 then
    begin
      LStr := Copy(XTheURL, LPos + Length(CLHttP), Length(XTheURL)); 
    end else
    begin
      LStr := XTheURL;
    end;

    LPos := Pos('/', LStr);
    if LPos > 0 then
      LStr := Copy(LStr, 1, LPos - 1);
    LPos := Pos(':', LStr);
    if LPos > 0 then
      LStr := Copy(LStr, 1, LPos - 1);

    Result := LStr;
  end;

  function GetPort(XTheURL: string): Word;
  var
    LStr: String;
    LPos: Integer;
  begin
    Result := 80;

    LPos := Pos(UpperCase(CLHttP), UpperCase(XTheURL));
    if LPos > 0 then
    begin
      LStr := Copy(XTheURL, LPos + Length(CLHttP), Length(XTheURL)); 
    end else
    begin
      LStr := XTheURL;
    end;

    LPos := Pos('/', LStr);
    if LPos > 0 then
      LStr := Copy(LStr, 1, LPos - 1);
    LPos := Pos(':', LStr);
    if LPos > 0 then
    begin
      LStr := Copy(LStr, LPos + 1, Length(LStr));
      if Length(LStr) > 0 then
      begin
        Result := StrToIntDef(LStr, 80);
      end;
    end;
  end;

  function GetURI(XTheURL: string):string;
  var
    LStr: string;
    LPos: Integer;
  begin
    Result := '';

    LPos := Pos(UpperCase(CLHttP), UpperCase(XTheURL));
    if LPos > 0 then
    begin
      LStr := Copy(XTheURL, LPos + Length(CLHttP), Length(XTheURL)); 
    end else
    begin
      LStr := XTheURL;
    end;

    LPos := Pos('/', LStr);
    if LPos > 0 then
    begin
      LStr := Copy(LStr, LPos, Length(LStr));
      
      Result := LStr;
    end;
  end;

  procedure ClearHandle;
  begin
    if FRequestHandle <> nil then
    begin
      InternetCloseHandle(FRequestHandle);
      FRequestHandle := nil;
    end;
    if FConnetHandle <> nil then
    begin
      InternetCloseHandle(FConnetHandle);
      FConnetHandle := nil;
    end;
  end;

begin
  Result := False;
  RetStr := '';

  ClearHandle;
  
  FConnetHandle:=InternetConnectA(
                  FhSession,
                  PAnsiChar(AnsiString(GetHost(URL))),
                  GetPort(URL),
                  nil,
                  nil,
                  INTERNET_SERVICE_HTTP,
                  0,
                  Cardinal(@FContextConnect));
  if not Assigned(FConnetHandle) then
  begin
    if GetLastError=ERROR_IO_PENDING then
    begin
      if WaitForSingleObject(FConnectEvent, CDownWait_Max) <> WAIT_OBJECT_0 then
      begin
        ClearHandle;
        Exit;
      end;
    end else
    begin
      ClearHandle;
      Exit;
    end;
  end;
 
  FRequestHandle := HttpOpenRequestA(FConnetHandle,
                               PAnsiChar('GET'),
                               PAnsiChar(AnsiString(GetURI(URL))),
                               nil,
                               nil,
                               nil,
                               INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE,
                               Cardinal(@FContextRequest));
  if not Assigned(FRequestHandle) then
  begin
     if GetLastError=ERROR_IO_PENDING then
     begin
        if WaitForSingleObject(FRequestOpenEvent, CDownWait_Max) <> WAIT_OBJECT_0 then
        begin
          ClearHandle;
          Exit;
        end;
     end else
     begin
       ClearHandle;
       Exit;
     end;
  end;
 
  LHeader := AnsiString(Format(
        'Host: %s'#13#10 +
        'Connection: keep-alive'#13#10 +
        'User-Agent: youxigongshe-Auto-updater'#13#10 +
        'Accept: text/html,application/xhtml+xml,application/*;q=0.9,*/*;q=0.8'#13#10 +
        'Accept-Encoding: identity'#13#10 +    // gzip,deflate   默认是identity
        'Accept-Charset: ISO-8859-1'#13#10 + // ISO-8859-1,utf-8;q=0.7,*;q=0.3
        'Accept-Language: *'#13#10 +
        'Referer: http://www.youxigongshe.com/'#13#10+
//        'appVersion: 1.0.0'#13#10 +
        Format('gameId: %d', [C_GAME_ID])
//        'sourceid:'#13#10+
//        'pver: 1.0'#13#10+
//        'smUserId: 1001'#13#10+
//        'smPinYin: ngc.cl'#13#10+
//        'os: android'#13#10+
//        'osVersion: 4.0'#13#10+
//        'userId: 0'#13#10+
//        'userSession:'#13#10+
//        'udid: testudid'
        , [GetHost(URL)]));
  if not HttpSendRequestA(FRequestHandle,
                         PAnsiChar(LHeader),
                         SizeOf(AnsiChar)*Length(LHeader),
                         nil,
                         0)
  then
  begin
    if GetLastError<>ERROR_IO_PENDING then
    begin
       ClearHandle;
       Exit;
    end;

    LWaitResult := WaitForSingleObject(FRequestCompleteEvent, CDownWait_Max);
    //100   258
    if LWaitResult <> WAIT_OBJECT_0 then
    begin
      ClearHandle;
      Exit;
    end;
  end;

  // 不请求大小, 有的页面大小获取会失败
  
  SetLength(LBufferStr, CLBufferSize);
  ZeroMemory(@LInternetBuffer,SizeOf(LInternetBuffer));

  while (True) do
  begin
    ZeroMemory(@LInternetBuffer,SizeOf(LInternetBuffer));
    LInternetBuffer.dwStructSize := SizeOf(LInternetBuffer);
    LInternetBuffer.lpvBuffer := @LBufferStr[1];
    LInternetBuffer.dwBufferLength := CLBufferSize;
 
    ResetEvent(FRequestCompleteEvent);
    LReservered:=1;
    LbOK := InternetReadFileExA(FRequestHandle, @LInternetBuffer, IRF_NO_WAIT,
      LReservered);
    if LbOK then
    begin
      if (LInternetBuffer.dwBufferLength=0) then
      begin
        Result := True;
        Break;
      end else
      begin
        SetLength(RetStr, Length(RetStr) + Integer(LInternetBuffer.dwBufferLength));
        Move(LBufferStr[1], RetStr[Length(RetStr) - Integer(LInternetBuffer.dwBufferLength) + 1], LInternetBuffer.dwBufferLength);
      end;

      FillChar(LBufferStr[1], Length(LBufferStr), 0);
    end else
    begin
      if GetLastError=ERROR_IO_PENDING then
      begin
        if WaitForSingleObject(FRequestCompleteEvent,CDownWait_Max) <> WAIT_OBJECT_0 then
        begin
          ClearHandle;
          Exit;
        end;
      end else
      begin
        ClearHandle;
        Exit;
      end;
    end;
  end;

  ClearHandle;
end;

function TDownUrlObject.DownUrlToStream(const URL: string;
  const RetStream: TStream; XCanCache: Boolean): Boolean;
const
  CLBufferSize = 1024*4;
  CLHttP = 'http://';
var
  LHeader: AnsiString;
  LReservered: Cardinal;
  LBufferStr: AnsiString;
  LbOK: Boolean;
  LInternetBuffer: TInternetBuffersA;
  LWaitResult: Cardinal;
  LFlag: Cardinal;

  function GetHost(XTheURL: string): string;
  var
    LStr: string;
    LPos: Integer;
  begin
    Result := '';

    LPos := Pos(UpperCase(CLHttP), UpperCase(XTheURL));
    if LPos > 0 then
    begin
      LStr := Copy(XTheURL, LPos + Length(CLHttP), Length(XTheURL)); 
    end else
    begin
      LStr := XTheURL;
    end;

    LPos := Pos('/', LStr);
    if LPos > 0 then
      LStr := Copy(LStr, 1, LPos - 1);
    LPos := Pos(':', LStr);
    if LPos > 0 then
      LStr := Copy(LStr, 1, LPos - 1);

    Result := LStr;
  end;

  function GetPort(XTheURL: string): Word;
  var
    LStr: String;
    LPos: Integer;
  begin
    Result := 80;

    LPos := Pos(UpperCase(CLHttP), UpperCase(XTheURL));
    if LPos > 0 then
    begin
      LStr := Copy(XTheURL, LPos + Length(CLHttP), Length(XTheURL)); 
    end else
    begin
      LStr := XTheURL;
    end;

    LPos := Pos('/', LStr);
    if LPos > 0 then
      LStr := Copy(LStr, 1, LPos - 1);
    LPos := Pos(':', LStr);
    if LPos > 0 then
    begin
      LStr := Copy(LStr, LPos + 1, Length(LStr));
      if Length(LStr) > 0 then
      begin
        Result := StrToIntDef(LStr, 80);
      end;
    end;
  end;

  function GetURI(XTheURL: string):string;
  var
    LStr: string;
    LPos: Integer;
  begin
    Result := '';

    LPos := Pos(UpperCase(CLHttP), UpperCase(XTheURL));
    if LPos > 0 then
    begin
      LStr := Copy(XTheURL, LPos + Length(CLHttP), Length(XTheURL)); 
    end else
    begin
      LStr := XTheURL;
    end;

    LPos := Pos('/', LStr);
    if LPos > 0 then
    begin
      LStr := Copy(LStr, LPos, Length(LStr));
      
      Result := LStr;
    end;
  end;

  procedure ClearHandle;
  begin
    if FRequestHandle <> nil then
    begin
      InternetCloseHandle(FRequestHandle);
      FRequestHandle := nil;
    end;
    if FConnetHandle <> nil then
    begin
      InternetCloseHandle(FConnetHandle);
      FConnetHandle := nil;
    end;
  end;

begin
  Result := False;

  ClearHandle;
  
  FConnetHandle:=InternetConnectA(
                  FhSession,
                  PAnsiChar(AnsiString(GetHost(URL))),
                  GetPort(URL),
                  nil,
                  nil,
                  INTERNET_SERVICE_HTTP,
                  0,
                  Cardinal(@FContextConnect));
  if not Assigned(FConnetHandle) then
  begin
    if GetLastError=ERROR_IO_PENDING then
    begin
      if WaitForSingleObject(FConnectEvent, CDownWait_Max) <> WAIT_OBJECT_0 then
      begin
        ClearHandle;
        Exit;
      end;
    end else
    begin
      ClearHandle;
      Exit;
    end;
  end;

  if XCanCache then
    LFlag := 0
  else
    LFlag := INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE;
 
  FRequestHandle := HttpOpenRequestA(FConnetHandle,
                               PAnsiChar('GET'),
                               PAnsiChar(AnsiString(GetURI(URL))),
                               nil,
                               nil,
                               nil,
                               LFlag,
                               Cardinal(@FContextRequest));
  if not Assigned(FRequestHandle) then
  begin
     if GetLastError=ERROR_IO_PENDING then
     begin
        if WaitForSingleObject(FRequestOpenEvent, CDownWait_Max) <> WAIT_OBJECT_0 then
        begin
          ClearHandle;
          Exit;
        end;
     end else
     begin
       ClearHandle;
       Exit;
     end;
  end;

  LHeader := AnsiString(Format(
        'Host: %s'#13#10 +
        'Connection: keep-alive'#13#10 +
        'User-Agent: youxigongshe-Auto-updater'#13#10 +
        'Accept: text/html,application/xhtml+xml,application/*;q=0.9,*/*;q=0.8'#13#10 +
        'Accept-Encoding: identity'#13#10 +    // gzip,deflate   默认是identity
        'Accept-Charset: ISO-8859-1'#13#10 + // ISO-8859-1,utf-8;q=0.7,*;q=0.3
        'Accept-Language: *'#13#10 +
        'Referer: http://www.youxigongshe.com/'
        , [GetHost(URL)]));
  if not HttpSendRequestA(FRequestHandle,
                         PAnsiChar(LHeader),
                         SizeOf(AnsiChar)*Length(LHeader),
                         nil,
                         0)
  then
  begin
    if GetLastError<>ERROR_IO_PENDING then
    begin
       ClearHandle;
       Exit;
    end;

    LWaitResult := WaitForSingleObject(FRequestCompleteEvent, CDownWait_Max);
    //100   258
    if LWaitResult <> WAIT_OBJECT_0 then
    begin
      ClearHandle;
      Exit;
    end;
  end;

  // 不请求大小, 有的页面大小获取会失败
  
  SetLength(LBufferStr, CLBufferSize);
  ZeroMemory(@LInternetBuffer,SizeOf(LInternetBuffer));

  while (True) do
  begin
    ZeroMemory(@LInternetBuffer,SizeOf(LInternetBuffer));
    LInternetBuffer.dwStructSize := SizeOf(LInternetBuffer);
    LInternetBuffer.lpvBuffer := @LBufferStr[1];
    LInternetBuffer.dwBufferLength := CLBufferSize;
 
    ResetEvent(FRequestCompleteEvent);
    LReservered:=1;
    LbOK := InternetReadFileExA(FRequestHandle, @LInternetBuffer, IRF_NO_WAIT,
      LReservered);
    if LbOK then
    begin
      if (LInternetBuffer.dwBufferLength=0) then
      begin
        Result := True;
        Break;
      end else
      begin
        RetStream.WriteBuffer(LBufferStr[1], LInternetBuffer.dwBufferLength);
      end;

      FillChar(LBufferStr[1], Length(LBufferStr), 0);
    end else
    begin
      if GetLastError=ERROR_IO_PENDING then
      begin
        if WaitForSingleObject(FRequestCompleteEvent,CDownWait_Max) <> WAIT_OBJECT_0 then
        begin
          ClearHandle;
          Exit;
        end;
      end else
      begin
        ClearHandle;
        Exit;
      end;
    end;
  end;

  ClearHandle;
end;

constructor TDownUrlObject.Create;
var
  LCallBackPointer: PFNInternetStatusCallback;
begin
  inherited;

  FConnectEvent := CreateEvent(nil, FALSE, FALSE, nil);
  if FConnectEvent = 0 then
    raise Exception.Create('FConnectEvent = nil');
  FRequestCompleteEvent := CreateEvent(nil, FALSE, FALSE, nil);
  if FRequestCompleteEvent = 0 then
    raise Exception.Create('FRequestCompleteEvent = nil');
  FRequestOpenEvent := CreateEvent(nil, FALSE, FALSE, nil);
  if FRequestOpenEvent = 0 then
    raise Exception.Create('FRequestOpenEvent = nil');

  FContextConnect.Code := CDownContext_Code_Connect;
  FContextRequest.Code := CDownContext_Code_Request;

  FContextConnect.PConnetHandle := @FConnetHandle;
  FContextConnect.PRequestHandle := @FRequestHandle;
  FContextConnect.PConnectEvent := @FConnectEvent;
  FContextConnect.PRequestOpenEvent := @FRequestOpenEvent;
  FContextConnect.PRequestCompleteEvent := @FRequestCompleteEvent;
  FContextRequest.PConnetHandle := @FConnetHandle;
  FContextRequest.PRequestHandle := @FRequestHandle;
  FContextRequest.PConnectEvent := @FConnectEvent;
  FContextRequest.PRequestOpenEvent := @FRequestOpenEvent;
  FContextRequest.PRequestCompleteEvent := @FRequestCompleteEvent;

  FhSession := InternetOpenA(PAnsiChar(AnsiString('YXGS')),
    INTERNET_OPEN_TYPE_PRECONFIG, niL, niL, INTERNET_FLAG_ASYNC);
  if FhSession = nil then
  begin
    raise Exception.Create('FhSession = nil');
  end;

  LCallBackPointer := @InternetStatusCallbackForTDownUrlObject;
  LCallBackPointer := InternetSetStatusCallback(FhSession, LCallBackPointer);
  if NativeInt(LCallBackPointer) = INTERNET_INVALID_STATUS_CALLBACK then
  begin
    raise Exception.Create('NativeInt(LCallBackPointer) = INTERNET_INVALID_STATUS_CALLBACK');
  end;
end;

destructor TDownUrlObject.Destroy;
begin
  if FhSession <> nil then
  begin
    InternetSetStatusCallback(FhSession, nil);
    InternetCloseHandle(FhSession);
    FhSession := nil;
  end;

  if FConnectEvent <> 0 then
  begin
    CloseHandle(FConnectEvent);
    FConnectEvent := 0;
  end;
  if FRequestCompleteEvent <> 0 then
  begin
    CloseHandle(FRequestCompleteEvent);
    FRequestCompleteEvent := 0;
  end;
  if FRequestOpenEvent <> 0 then
  begin
    CloseHandle(FRequestOpenEvent);
    FRequestOpenEvent := 0;
  end;

  inherited;
end;
  

{ TMyExeThreadEvent }

constructor TMyExeThreadEvent.Create(XEvent: TExeThreadEvent; XParam: Pointer; XSynEvent: TThreadMethod);
begin
  inherited Create(True);

  FreeOnTerminate := True;
  FExeEvent := XEvent;
  FParam := XParam;
  FSynEvent := XSynEvent;
end;

destructor TMyExeThreadEvent.Destroy;
begin

  inherited;
end;

procedure TMyExeThreadEvent.Execute;
begin
  inherited;

  // 为了在非主线程调用com，兑换游戏豆
  CoInitialize(nil);
  
  try
    if Assigned(FExeEvent) then
    begin
      FExeEvent(FParam);
    end;
  except end;
  try
    if Assigned(FSynEvent) then
    begin
      FSynEvent;
    end;
  except end;

  CoUninitialize;
end;

procedure DoExeThreadEvent(XEvent: TExeThreadEvent; XParam: Pointer; XSynEvent: TThreadMethod);
var
  LThread: TMyExeThreadEvent;
begin
  LThread := TMyExeThreadEvent.Create(XEvent, XParam, XSynEvent);
  LThread.Suspended := False;
end;

end.

