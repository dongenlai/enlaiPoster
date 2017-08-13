unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, User, Config, JaContainers, gamefrm, ExtCtrls;

type

  TWorkThread = class(TThread)
  private
    FFromIndex: Integer;
    FUserCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TMainForm = class(TForm)
    MemoLog: TMemo;
    ButtonStart: TButton;
    tmrAddMsg: TTimer;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrAddMsgTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FIsInit: Boolean;
    FLock: TSyncObject;
    FMsgList: TStringList; // for dead lock    1 lockWs:sendmessage  2 mainllock:lockWs
    FTableNum: string;
    FHasAutoFind: Boolean;

    FUserList: array of TUser;
    FGameFormAry: array of TGameForm;
    FThreadAry: array of TWorkThread;
  public
    procedure AddLog(const XMsg: string);
    procedure CheckFindTable(const tableNum: string);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.AddLog(const XMsg: string);
begin
  if not FIsInit then
    Exit;

  FLock.Lock;
  try
    FMsgList.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss ', Now) + XMsg);
  finally
    FLock.Unlock;
  end;
end;

procedure TMainForm.ButtonStartClick(Sender: TObject);
var
  I: Integer;
  LIsRun: Boolean;
begin
  LIsRun := False;

  for I := Low(FThreadAry) to High(FThreadAry) do
  begin
    if FThreadAry[I].Suspended then
    begin
      FThreadAry[I].Suspended := False;
      LIsRun := True;
    end else
    begin
      FThreadAry[I].Suspended := True;
      LIsRun := False;
    end;
  end;

  if LIsRun then
    ButtonStart.Caption := 'Stop'
  else
    ButtonStart.Caption := 'Start';
end;

procedure TMainForm.CheckFindTable(const tableNum: string);
begin
  FTableNum := tableNum;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  LLen: Integer;
  I: Integer;
  LUserAry: TLoginUserRecArray;
  LThreadCount: Integer;
  LPerCount: Integer;
begin
  FHasAutoFind := False;
  FTableNum := '';
  FMsgList := TStringList.Create;
  SetLength(FGameFormAry, ConfigMgr.ServerCfg.GameFormCount);
  for I := Low(FGameFormAry) to High(FGameFormAry) do
    FGameFormAry[I] := TGameForm.Create(Self);

  FLock := TSyncObject.Create;
  FLock.ThreadSafe := True;

  ConfigMgr.GetLoginUserList(LUserAry);
  LLen := Length(LUserAry);
  
  SetLength(FUserList, LLen);
  for I := 0 to LLen - 1 do
  begin
    FUserList[I] := TUser.Create(LUserAry[I]);
  end;

  if(Length(FGameFormAry) > 0) then
  begin
    for I := 0 to LLen - 1 do
    begin
      if (I <= High(FGameFormAry)) then
      begin
        FUserList[I].SetGameFormHandle(FGameFormAry[I].Handle);
        FGameFormAry[I].SetUserPtr(FUserList[I]);
      end else
      begin
        Break;
      end;
    end;
  end;

  LThreadCount := ConfigMgr.ServerCfg.ThreadCount;
  if LThreadCount > LLen then
    LThreadCount := LLen;
  if LThreadCount < 1 then
    LThreadCount := 1;

  LPerCount := LLen div LThreadCount;
  
  SetLength(FThreadAry, LThreadCount);
  for I := Low(FThreadAry) to High(FThreadAry) do
  begin
    FThreadAry[I] := TWorkThread.Create;
    FThreadAry[I].FFromIndex := I * LPerCount;
    FThreadAry[I].FUserCount := LPerCount;
  end;
  FThreadAry[High(FThreadAry)].FUserCount := LLen - (LPerCount * (LThreadCount - 1));

  FIsInit := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  FIsInit := False;

  for I := Low(FThreadAry) to High(FThreadAry) do
  begin
    if FThreadAry[I].Suspended then
      FThreadAry[I].Suspended := False;
    FThreadAry[I].Terminate;
    FThreadAry[I].WaitFor;
    FThreadAry[I].Free;
  end;
  SetLength(FThreadAry, 0);

  for I := Low(FUserList) to High(FUserList) do
    FreeAndNil(FUserList[I]);
  SetLength(FUserList, 0);

  FreeAndNil(FLock);

  FreeAndNil(FMsgList);
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  I: Integer;
begin
  for I := Low(FGameFormAry) to High(FGameFormAry) do
    FGameFormAry[I].Show;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  I: Integer;
begin
  if (not FHasAutoFind) and (Length(FTableNum) > 0) then
  begin
    FHasAutoFind := True;
    Timer1.Enabled := False;
    for I := 0 to Length(FGameFormAry) - 1 do
    begin
      FGameFormAry[i].CheckFindTable(FTableNum);
    end;
  end;
end;

procedure TMainForm.tmrAddMsgTimer(Sender: TObject);
var
  I: Integer;
begin
  if FMsgList.Count = 0 then
    Exit;

  FLock.Lock;
  try
    for I := 0 to FMsgList.Count - 1 do
    begin
      MemoLog.Lines.Add(FMsgList[I]);
      if MemoLog.Lines.Count > 5000 then
      begin
        MemoLog.Lines.SaveToFile(FormatDateTime('yyyymmddhhnnss', Now) + '.log');
        MemoLog.Lines.Clear;
      end;
    end;

    FMsgList.Clear;
  finally
    FLock.Unlock;
  end;
end;

{ TWorkThread }

constructor TWorkThread.Create;
begin
  inherited Create(True);

  FreeOnTerminate := False;
end;

destructor TWorkThread.Destroy;
begin

  inherited;
end;

procedure TWorkThread.Execute;
var
  I: Integer;
begin
  inherited;

  Randomize;
  
  while not Terminated do
  begin
    for I := 0 to FUserCount - 1 do
    begin
      try
        MainForm.FUserList[FFromIndex + I].DoWork;
      except on E: Exception do
        begin
          MainForm.FUserList[FFromIndex + I].Clear;
          MainForm.AddLog('DoWork: ' + E.Message);
        end;
      end;
    end;

    Sleep(100);
  end;
end;

end.
