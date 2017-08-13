unit gamefrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TemplateGlobalST, StdCtrls, pngimage, TemplatePicConfigGlobalST, Types,
  TemplateImageGlobalST, TemplateCardGlobalST, TemplatePngCard, ExtCtrls, MJType, MJGrapShouPai,
  CheckLst, Buttons, ComCtrls;

type
  TGameForm = class(TForm)
    lblUserList: TLabel;
    btnUpdateUserInfo: TButton;
    btnTick: TButton;
    edtChat: TEdit;
    btnChat: TButton;
    btnReady: TButton;
    btnTrust: TButton;
    chkTrust: TCheckBox;
    btnDeclare: TButton;
    btnNotDeclare: TButton;
    lblCurUserId: TLabel;
    lblCurMulti: TLabel;
    lblDecTime: TLabel;
    tmrDecTime: TTimer;
    lblLandLordId: TLabel;
    lblLastDiscardId: TLabel;
    edtBaseScore: TEdit;
    edtRound: TEdit;
    btnCreateTable: TButton;
    edtTableNum: TEdit;
    btnFindTable: TButton;
    cmbVipType: TComboBox;
    editMaxRound: TEdit;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Label2: TLabel;
    clbSelSwapCard: TCheckListBox;
    btnSwapCards: TButton;
    lblHint: TLabel;
    btnSelWan: TBitBtn;
    btnSelBing: TBitBtn;
    btnSelTiao: TBitBtn;
    btnChi: TButton;
    btnPeng: TButton;
    btnGang: TButton;
    btnHu: TButton;
    btnPass: TButton;
    lbMingPai: TListBox;
    lbHuPaiInfo: TListBox;
    btnQuestDisband: TButton;
    pnlIsAgreeClear: TPanel;
    btnAgree: TBitBtn;
    btnDisagree: TBitBtn;
    lbChi: TListBox;
    btnLiangGang: TButton;
    editLiangGang: TEdit;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure btnUpdateUserInfoClick(Sender: TObject);
    procedure btnTickClick(Sender: TObject);
    procedure btnChatClick(Sender: TObject);
    procedure btnReadyClick(Sender: TObject);
    procedure btnTrustClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnDeclareClick(Sender: TObject);
    procedure btnNotDeclareClick(Sender: TObject);
    procedure tmrDecTimeTimer(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnCreateTableClick(Sender: TObject);
    procedure btnFindTableClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure btnSwapCardsClick(Sender: TObject);
    procedure btnSelWanClick(Sender: TObject);
    procedure btnPengClick(Sender: TObject);
    procedure btnPassClick(Sender: TObject);
    procedure btnGangClick(Sender: TObject);
    procedure btnHuClick(Sender: TObject);
    procedure btnQuestDisbandClick(Sender: TObject);
    procedure btnAgreeClick(Sender: TObject);
    procedure btnDisagreeClick(Sender: TObject);
    procedure btnChiClick(Sender: TObject);
    procedure lbChiClick(Sender: TObject);
    procedure btnLiangGangClick(Sender: TObject);
  private
    FGsClient: Integer;
    FUserPtr: Pointer;
    FCardCfg: TConfigPngCard;                                     // ≈∆≈‰÷√
    FCardSkin: TPngCardPic;                                       // ≈∆µƒÕº∆¨
    FSelfCard: TTemplatePngCard;
    FBackCard: TTemplatePngCard;
    FLastCard: TTemplatePngCard;
    FLastDecTick: Cardinal;
    FIncSec: Cardinal;

    FSelfMJCard: TMJGrapShouPai;
    FSelfAction: TAryPlayerMJActionMin;
    FSelfMingPai: TStringDynArray;

    procedure WMRefreshGame(var XMsg: TMessage); message WM_MYREFRESH_GAME;
    procedure WMIsAgreeClearTable(var XMsg: TMessage); message WM_MYSHOW_IS_AGREE;
    procedure onShouPaiMJDown(Sender: TObject; ASelPosIndex: Integer; ACardID: Integer);
  public
    procedure UpdateSelfCard(const mjCards: TIntegerDynArray);
    procedure UpdateSelfAction(const selfAction: TAryPlayerMJActionMin);
    procedure UpdateMingPai(selfMingPai: TStringDynArray);
    procedure UpdateDecTime(XTime: Integer);
    procedure SetUserPtr(XUser: Pointer);
    procedure updateSwapUI(mjCards: TIntegerDynArray);
    procedure CheckFindTable(const tableNum: string);

    function HasAction(action: TMJActionName): Boolean;
  end;

implementation

uses
  GsClient, User;

{$R *.dfm}

procedure TGameForm.btnAgreeClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackQuestDisband(1, 1);
  end;
end;

procedure TGameForm.btnChatClick(Sender: TObject);
var
  LGameClient: TGsClient;
  ltmp: TIntegerDynArray;
  I: Integer;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackChatMsg(edtChat.Text);
  end;

  SetLength(ltmp, 10);
  for I := 0 to 10 - 1 do
  begin
    ltmp[i] := i;
  end;
  FSelfMJCard.updateCardList(ltmp);
end;

procedure TGameForm.btnChiClick(Sender: TObject);
var
  I: Integer;
  LGameClient: TGsClient;
  LCount: Integer;
begin
  LCount := 0;
  LGameClient := TGsClient(FGsClient);
  for I := 0 to Length(FSelfAction) - 1 do
  begin
    if (FSelfAction[i].MJAName = mjaChi) then
    begin
      Inc(LCount);
    end;
  end;

  if LCount = 1 then
  begin
    for I := 0 to Length(FSelfAction) - 1 do
    begin
      if (FSelfAction[i].MJAName = mjaChi) then
      begin
        LGameClient.SendPackDoAction(mjaChi, fselfaction[i].ExpandStr);
        Break;
      end;
    end;
  end else
  begin
    lbChi.Clear;
    for I := 0 to Length(FSelfAction) - 1 do
    begin
      if (FSelfAction[i].MJAName = mjaChi) then
      begin
        lbChi.AddItem(fselfaction[i].ExpandStr, nil);
      end;
    end;
    lbChi.Visible := True;
  end;
end;

procedure TGameForm.btnCreateTableClick(Sender: TObject);
var
  LUser: TUser;
begin
  if (FUserPtr = nil) then
    Exit;

  LUser := TUser(FUserPtr);
  LUser.CreateTable(StrToIntDef(edtBaseScore.Text, 0), StrToIntDef(edtRound.Text, 0), 1);
end;

procedure TGameForm.btnDeclareClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackDeclare(1);
  end;
end;

procedure TGameForm.btnDisagreeClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackQuestDisband(1, 0);
  end;
end;

procedure TGameForm.btnFindTableClick(Sender: TObject);
var
  LUser: TUser;
begin
  if (FUserPtr = nil) then
    Exit;

  LUser := TUser(FUserPtr);
  LUser.FindTable(Trim(edtTableNum.Text));
end;

procedure TGameForm.btnGangClick(Sender: TObject);
var
  I: Integer;
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  for I := 0 to Length(FSelfAction) - 1 do
  begin
    if (FSelfAction[i].MJAName = mjaDaMingGang) or (FSelfAction[i].MJAName = mjaJiaGang) or
      (FSelfAction[i].MJAName = mjaAnGang) or (FSelfAction[i].MJAName = mjaSpecialGang) then
    begin
      LGameClient.SendPackDoAction(FSelfAction[i].MJAName, fselfaction[i].ExpandStr);
      Break;
    end;
  end;
end;

procedure TGameForm.btnHuClick(Sender: TObject);
var
  I: Integer;
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  for I := 0 to Length(FSelfAction) - 1 do
  begin
    if (FSelfAction[i].MJAName = mjaHu) then
    begin
      LGameClient.SendPackDoAction(FSelfAction[i].MJAName, fselfaction[i].ExpandStr);
      Break;
    end;
  end;
end;

procedure TGameForm.btnLiangGangClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  LGameClient.SendPackLiangGang(editLiangGang.Text);
end;

procedure TGameForm.btnNotDeclareClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackDeclare(0);
  end;
end;

procedure TGameForm.btnPassClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  LGameClient.SendPackDoAction(mjaPass, '');

end;

procedure TGameForm.btnPengClick(Sender: TObject);
var
  I: Integer;
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  for I := 0 to Length(FSelfAction) - 1 do
  begin
    if (FSelfAction[i].MJAName = mjaPeng) then
    begin
      LGameClient.SendPackDoAction(mjaPeng, fselfaction[i].ExpandStr);
      Break;
    end;
  end;
end;

procedure TGameForm.btnQuestDisbandClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackQuestDisband(0, 1);
  end;
end;

procedure TGameForm.btnReadyClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackReady;
  end;
end;

procedure TGameForm.btnSelWanClick(Sender: TObject);
var
  SelSuit: Integer;
  LGameClient: TGsClient;
begin
  SelSuit := TBitBtn(Sender).Tag;
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendSelDelSuit(SelSuit);
  end;
end;

procedure TGameForm.btnSwapCardsClick(Sender: TObject);
var
  LGameClient: TGsClient;
  I: Integer;
  LSelCnt: Integer;
  LStr: string;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LSelCnt := 0;
    for I := 0 to clbSelSwapCard.Items.Count - 1 do
    begin
      if (clbSelSwapCard.Checked[I]) then
      begin
        if(LSelCnt = 0) then
          LStr := IntToStr(LGameClient.FSelfMjCards[I])
        else
          LStr := LStr + ',' + IntToStr(LGameClient.FSelfMjCards[I]);
        Inc(lselcnt);
      end;
    end;

    if(LSelCnt = 3) then
    begin
      LStr := '[' + lstr + ']';
      LGameClient.SendPackSwapCard(lstr);
    end else
    begin
      ShowMessage('¥ÌŒÛ£¨«Î—°‘Ò»˝’≈≈∆£°');
    end;
  end;
end;

procedure TGameForm.btnTickClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackOnTick;
  end;
end;

procedure TGameForm.btnTrustClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackTrust(Ord(not chkTrust.Checked));
  end;
end;

procedure TGameForm.btnUpdateUserInfoClick(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackUpdateUserInfo;
  end;
end;

procedure TGameForm.Button1Click(Sender: TObject);
var
  LUser: TUser;
begin
  if (FUserPtr = nil) then
    Exit;

  LUser := TUser(FUserPtr);
  LUser.CreateTable(StrToIntDef(edtBaseScore.Text, 0), StrToIntDef(editMaxRound.Text, 0), cmbVipType.ItemIndex + 2);
end;

procedure TGameForm.Button2Click(Sender: TObject);
var
  LUser: TUser;
begin
  if (FUserPtr = nil) then
    Exit;

  LUser := TUser(FUserPtr);
  LUser.Clear;
end;

procedure TGameForm.CheckFindTable(const tableNum: string);
var
  LUser: TUser;
begin
  if (FUserPtr = nil) then
    Exit;

  LUser := TUser(FUserPtr);
  if LUser.State = rusWaiting then
  begin
    edtTableNum.Text := tableNum;
    btnFindTableClick(btnFindTable);
  end;
end;

procedure TGameForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
end;

procedure TGameForm.FormCreate(Sender: TObject);

  procedure LoadPngCardPic(var RetPic: TPngCardPic);
  var
    LFileNameFmt: string;
    LIndex: Integer;
    LColor: TCardColor; LValue: TCardValue;

    procedure LoadAPngPic(var Png: TPNGObject);
    begin
      Png := TPNGObject.Create;
      Png.LoadFromFile(Format(LFileNameFmt, [LIndex]));

      Inc(LIndex);
    end;

  begin
    try
      LFileNameFmt := ExtractFilePath(ParamStr(0)) + 'Card\Card%.2d.Png';

      LIndex := 0;
      for LColor := sccDiamond to sccSpade do
      begin
        for LValue := scvA to scvK do
          LoadAPngPic(RetPic.AToKPic[LColor][LValue]);

        RetPic.AToKPic[LColor][scvBA] := RetPic.AToKPic[LColor][scvA];
        RetPic.AToKPic[LColor][scvB2] := RetPic.AToKPic[LColor][scv2];
      end;

      for LValue := scvSJoker to scvBJoker do
        LoadAPngPic(RetPic.JokerPic[LValue]);

      LoadAPngPic(RetPic.BackPic[cbtNormal]);
      LoadAPngPic(RetPic.BackPic[cbtFarmer]);
      LoadAPngPic(RetPic.BackPic[cbtLandLord]);

      LoadAPngPic(RetPic.MaskPic[cmtSelected]);
      LoadAPngPic(RetPic.MaskPic[cmtSelecting]);
    except
      ShowMessage('º”‘ÿ≈∆Õº∆¨ ß∞‹£°');
    end;
  end;

  procedure GetCardConfig;
  begin
    FCardCfg.CardImageList.SmallWidth := FCardSkin.BackPic[cbtNormal].Width;
    FCardCfg.CardImageList.SmallHeight := FCardSkin.BackPic[cbtNormal].Height;
    FCardCfg.CardImageList.Interval := 0;

    FCardCfg.CardInterval[catHorizontal] := 20;
    FCardCfg.CardInterval[catVertical] := 22;
    FCardCfg.BackInterval[catHorizontal] := 14;
    FCardCfg.BackInterval[catHorizontal] := 25;
    FCardCfg.SelectedInterval := 15;
  end;

  procedure CreateAPngCard(var RetCard: TTemplatePngCard);
  begin
    RetCard := TTemplatePngCard.Create(nil);
    RetCard.Visible := True;
    RetCard.ImageSkin := FCardSkin;
    RetCard.ImageCfg := FCardCfg;

    RetCard.Parent := Self;
  end;

begin
  SetWindowLong(Handle,GWL_EXSTYLE,(GetWindowLong(handle,GWL_EXSTYLE) or WS_EX_APPWINDOW));
  FLastDecTick := GetTickCount;
  Self.DoubleBuffered := True;

  LoadPngCardPic(FCardSkin);
  GetCardConfig;

  CreateAPngCard(FSelfCard);
  FSelfCard.Left := 128;
  FSelfCard.Top := 330;

  FSelfMJCard := TMJGrapShouPai.Create(nil);
  FSelfMJCard.OnMJMouseDown := onShouPaiMJDown;
  FSelfMJCard.Parent := Self;
  FSelfMJCard.Visible := True;
  FSelfMJCard.Left := 50;
  FSelfMJCard.Top := 330;

  CreateAPngCard(FBackCard);
  FBackCard.Left := 600;
  FBackCard.Top := 350;

  CreateAPngCard(FLastCard);
  FLastCard.Left := 300;
  FLastCard.Top := 130;

end;

procedure TGameForm.FormDestroy(Sender: TObject);

  procedure FreePngCardPic(var CardPic: TPngCardPic);
  var
    LColor: TCardColor;
    LValue: TCardValue;
  begin
    for LColor := sccDiamond to sccSpade do
    begin
      for LValue := scvA to scvK do
      begin
        FreeAndNil(CardPic.AToKPic[LColor][LValue]);
      end;

      CardPic.AToKPic[LColor][scvBA] := nil;
      CardPic.AToKPic[LColor][scvB2] := nil;
    end;

    for LValue := scvSJoker to scvBJoker do
    begin
      FreeAndNil(CardPic.JokerPic[LValue]);
    end;

    FreeAndNil(CardPic.BackPic);
  end;

begin
  FreeAndNil(FSelfCard);
  FreeAndNil(FBackCard);
  FreeAndNil(FLastCard);
  FreePngCardPic(FCardSkin);
end;

procedure TGameForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  LGameClient: TGsClient;
  LTmpCard: TGameCardAry;
begin
  if(Button = mbRight)then
  begin
    LGameClient := TGsClient(FGsClient);

    if(nil <> LGameClient) then
    begin
      FSelfCard.GetSelectedCardAry(LTmpCard);
      LGameClient.SendPackDiscard(LTmpCard);
      LGameClient.RefreshGameForm(Self);
    end;
  end;
end;

function TGameForm.HasAction(action: TMJActionName): Boolean;
var
  I: Integer;
  LAction: TMJActionName;
begin
  Result := False;
  if action <> mjaPass then
  begin
    for I := 0 to Length(FSelfAction) - 1 do
    begin
      if (FSelfAction[I].MJAName = action) then
      begin
        Result := True;
        Break;
      end;
    end;
  end else
  begin
    for I := 0 to Length(FSelfAction) - 1 do
    begin
      LAction := FSelfAction[I].MJAName;
      if ((LAction = mjaChi) or (LAction = mjaPeng) or (LAction = mjaDaMingGang) or
        (LAction = mjaJiaGang) or (LAction = mjaAnGang) or (LAction = mjaTing) or
        (LAction = mjaHu)) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

procedure TGameForm.lbChiClick(Sender: TObject);
var
  LStr: string;
  LGameClient: TGsClient;
begin
  LStr := lbChi.Items[lbChi.ItemIndex];
  LGameClient := TGsClient(FGsClient);
  LGameClient.SendPackDoAction(mjaChi, LStr);
  lbChi.Clear;
  lbChi.Visible := True;
end;

procedure TGameForm.onShouPaiMJDown(Sender: TObject; ASelPosIndex,
  ACardID: Integer);
var
  LGameClient: TGsClient;
begin
  LGameClient := TGsClient(FGsClient);
  if nil <> LGameClient then
  begin
    LGameClient.SendPackChuPai(ACardID);
  end;
end;

procedure TGameForm.SetUserPtr(XUser: Pointer);
begin
  FUserPtr := XUser;
end;

procedure TGameForm.tmrDecTimeTimer(Sender: TObject);
var
  LGameClient: TGsClient;
begin
  if (Cardinal(GetTickCount - FLastDecTick) >= 1000) then
  begin
    Inc(FLastDecTick, 1000);
    Inc(FIncSec);
    LGameClient := TGsClient(FGsClient);

    if(nil <> LGameClient) then
    begin
      LGameClient.DecTimeCount(Self);
      if (FIncSec mod 10 = 0) then
        LGameClient.SendPackOnTick;
    end;
  end;
end;

procedure TGameForm.UpdateDecTime(XTime: Integer);
begin
  lblDecTime.Caption := Format('time=%.2d', [XTime])
end;

procedure TGameForm.UpdateMingPai(selfMingPai: TStringDynArray);
var
  LLen: Integer;
  I: Integer;
begin
  if Length(selfMingPai) <> Length(FSelfMingPai) then
  begin
    LLen := Length(selfMingPai);
    SetLength(FSelfMingPai, llen);
    for I := 0 to LLen - 1 do
    begin
      FSelfMingPai[I] := selfMingPai[I];
    end;

    lbMingPai.Clear;
    for I := 0 to llen - 1 do
    begin
      lbMingPai.AddItem(selfmingpai[i], nil);
    end;
  end;
end;

procedure TGameForm.UpdateSelfAction(const selfAction: TAryPlayerMJActionMin);
var
  LLen: Integer;
  I: Integer;

begin
  LLen := Length(selfAction);
  SetLength(FSelfAction, LLen);
  for I := 0 to LLen - 1 do
  begin
    FSelfAction[I].MJAName := selfAction[I].MJAName;
    FSelfAction[I].ExpandStr := selfAction[I].ExpandStr;
  end;

  btnChi.Visible := HasAction(mjaChi);
  btnPeng.Visible := HasAction(mjaPeng);
  btnGang.Visible := HasAction(mjaDaMingGang) or HasAction(mjaJiaGang) or HasAction(mjaAnGang) or HasAction(mjaSpecialGang);
  //btnLiangGang.Visible := HasAction(mjaSpecialGang);
  //editLiangGang.Visible := HasAction(mjaSpecialGang);
  btnHu.Visible := HasAction(mjaHu);
  btnPass.Visible := HasAction(mjaPass);
end;

procedure TGameForm.UpdateSelfCard(const mjCards: TIntegerDynArray);
begin
  FSelfMJCard.updateCardList(mjCards);

end;

procedure TGameForm.updateSwapUI(mjCards: TIntegerDynArray);
var
  I: Integer;
begin
  clbSelSwapCard.Clear;
  for I := 0 to Length(mjCards) - 1 do
  begin
    clbSelSwapCard.Items.Add(CMJDATA_CAPTION[mjCards[i]]);
  end;
end;

procedure TGameForm.WMIsAgreeClearTable(var XMsg: TMessage);
begin
  if(XMsg.WParam = 0) then
      pnlIsAgreeClear.Visible := True
  else
    pnlIsAgreeClear.Visible := False;
end;

procedure TGameForm.WMRefreshGame(var XMsg: TMessage);
var
  LGameClient: TGsClient;
begin
  FGsClient := XMsg.WParam;
  LGameClient := TGsClient(FGsClient);

  if(nil <> LGameClient) then
  begin
    LGameClient.RefreshGameForm(Self);
  end;
end;

end.
