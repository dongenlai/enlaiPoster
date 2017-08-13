object GameForm: TGameForm
  Left = 0
  Top = 0
  Caption = 'GameForm'
  ClientHeight = 503
  ClientWidth = 852
  Color = clSkyBlue
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseDown = FormMouseDown
  PixelsPerInch = 96
  TextHeight = 13
  object lblUserList: TLabel
    Left = 16
    Top = 8
    Width = 48
    Height = 13
    Caption = 'lblUserList'
  end
  object lblCurUserId: TLabel
    Left = 232
    Top = 109
    Width = 24
    Height = 13
    Caption = '###'
  end
  object lblCurMulti: TLabel
    Left = 344
    Top = 109
    Width = 24
    Height = 13
    Caption = '###'
  end
  object lblDecTime: TLabel
    Left = 448
    Top = 109
    Width = 24
    Height = 13
    Caption = '###'
  end
  object lblLandLordId: TLabel
    Left = 552
    Top = 109
    Width = 24
    Height = 13
    Caption = '###'
  end
  object lblLastDiscardId: TLabel
    Left = 648
    Top = 109
    Width = 24
    Height = 13
    Caption = '###'
  end
  object Label1: TLabel
    Left = 424
    Top = 24
    Width = 36
    Height = 13
    Caption = #24213#20998#65306
  end
  object Label2: TLabel
    Left = 511
    Top = 24
    Width = 36
    Height = 13
    Caption = #23616#25968#65306
  end
  object lblHint: TLabel
    Left = 8
    Top = 149
    Width = 64
    Height = 19
    Caption = #25552#31034#20449#24687
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbHuPaiInfo: TListBox
    Left = 528
    Top = 128
    Width = 316
    Height = 217
    ItemHeight = 13
    TabOrder = 29
  end
  object btnUpdateUserInfo: TButton
    Left = 8
    Top = 27
    Width = 89
    Height = 25
    Caption = 'UpdateUserInfo'
    TabOrder = 0
    OnClick = btnUpdateUserInfoClick
  end
  object btnTick: TButton
    Left = 112
    Top = 27
    Width = 75
    Height = 25
    Caption = 'OnTick'
    TabOrder = 1
    OnClick = btnTickClick
  end
  object edtChat: TEdit
    Left = 195
    Top = 29
    Width = 121
    Height = 21
    TabOrder = 2
    Text = 'testchat'#27491#24120
  end
  object btnChat: TButton
    Left = 322
    Top = 27
    Width = 75
    Height = 25
    Caption = 'Chat'
    TabOrder = 3
    OnClick = btnChatClick
  end
  object btnReady: TButton
    Left = 8
    Top = 58
    Width = 75
    Height = 25
    Caption = 'Ready'
    TabOrder = 4
    OnClick = btnReadyClick
  end
  object btnTrust: TButton
    Left = 112
    Top = 58
    Width = 75
    Height = 25
    Caption = 'Trust'
    TabOrder = 5
    OnClick = btnTrustClick
  end
  object chkTrust: TCheckBox
    Left = 193
    Top = 62
    Width = 97
    Height = 17
    Caption = 'isTrust'
    TabOrder = 6
  end
  object btnDeclare: TButton
    Left = 8
    Top = 104
    Width = 75
    Height = 25
    Caption = 'Declare'
    TabOrder = 7
    OnClick = btnDeclareClick
  end
  object btnNotDeclare: TButton
    Left = 89
    Top = 104
    Width = 75
    Height = 25
    Caption = 'NotDeclare'
    TabOrder = 8
    OnClick = btnNotDeclareClick
  end
  object edtBaseScore: TEdit
    Left = 464
    Top = 21
    Width = 42
    Height = 21
    Hint = 'BaseScore'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 9
    Text = '5'
  end
  object edtRound: TEdit
    Left = 551
    Top = 451
    Width = 66
    Height = 21
    Hint = 'Round'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 10
    Text = '3'
    Visible = False
  end
  object btnCreateTable: TButton
    Left = 631
    Top = 451
    Width = 75
    Height = 25
    Caption = #21019#24314#29616#37329#23616
    TabOrder = 11
    Visible = False
    OnClick = btnCreateTableClick
  end
  object edtTableNum: TEdit
    Left = 464
    Top = 62
    Width = 153
    Height = 21
    Hint = 'TableNum'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 12
    Text = '123456'
  end
  object btnFindTable: TButton
    Left = 648
    Top = 58
    Width = 75
    Height = 25
    Caption = ' '#26597#25214#24231#20301
    TabOrder = 13
    OnClick = btnFindTableClick
  end
  object cmbVipType: TComboBox
    Left = 623
    Top = 21
    Width = 145
    Height = 21
    ItemIndex = 1
    TabOrder = 14
    Text = #25105#25343#26700#36153
    Items.Strings = (
      #22343#25674#26700#36153
      #25105#25343#26700#36153)
  end
  object editMaxRound: TEdit
    Left = 543
    Top = 21
    Width = 66
    Height = 21
    Hint = 'Round'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 15
    Text = '6'
  end
  object Button1: TButton
    Left = 774
    Top = 19
    Width = 75
    Height = 25
    Caption = #21019#24314#31215#20998#23616
    TabOrder = 16
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 729
    Top = 58
    Width = 75
    Height = 25
    Caption = #27169#25311#25481#32447
    TabOrder = 17
    OnClick = Button2Click
  end
  object clbSelSwapCard: TCheckListBox
    Left = 171
    Top = 342
    Width = 85
    Height = 153
    ItemHeight = 13
    Items.Strings = (
      '0'
      '1'
      '2')
    TabOrder = 18
    Visible = False
  end
  object btnSwapCards: TButton
    Left = 23
    Top = 455
    Width = 75
    Height = 25
    Caption = #25442#29260
    TabOrder = 19
    Visible = False
    OnClick = btnSwapCardsClick
  end
  object btnSelWan: TBitBtn
    Tag = 1
    Left = 23
    Top = 368
    Width = 75
    Height = 25
    Caption = #19975
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 20
    Visible = False
    OnClick = btnSelWanClick
  end
  object btnSelBing: TBitBtn
    Tag = 2
    Left = 22
    Top = 399
    Width = 75
    Height = 25
    Caption = #39292
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 21
    Visible = False
    OnClick = btnSelWanClick
  end
  object btnSelTiao: TBitBtn
    Tag = 3
    Left = 23
    Top = 424
    Width = 75
    Height = 25
    Caption = #26465
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 22
    Visible = False
    OnClick = btnSelWanClick
  end
  object btnChi: TButton
    Left = 170
    Top = 288
    Width = 75
    Height = 25
    Caption = #21507
    TabOrder = 23
    OnClick = btnChiClick
  end
  object btnPeng: TButton
    Left = 241
    Top = 288
    Width = 75
    Height = 25
    Caption = #30896
    TabOrder = 24
    OnClick = btnPengClick
  end
  object btnGang: TButton
    Left = 314
    Top = 288
    Width = 75
    Height = 25
    Caption = #26464
    TabOrder = 25
    OnClick = btnGangClick
  end
  object btnHu: TButton
    Left = 449
    Top = 288
    Width = 75
    Height = 25
    Caption = #32993
    TabOrder = 26
    OnClick = btnHuClick
  end
  object btnPass: TButton
    Left = 511
    Top = 288
    Width = 75
    Height = 25
    Caption = #36807
    TabOrder = 27
    OnClick = btnPassClick
  end
  object lbMingPai: TListBox
    Left = 8
    Top = 210
    Width = 121
    Height = 135
    ItemHeight = 13
    TabOrder = 28
  end
  object btnQuestDisband: TButton
    Left = 293
    Top = 58
    Width = 75
    Height = 25
    Caption = #35831#27714#25955#26700
    TabOrder = 30
    OnClick = btnQuestDisbandClick
  end
  object pnlIsAgreeClear: TPanel
    Left = 322
    Top = 132
    Width = 185
    Height = 57
    TabOrder = 31
    Visible = False
    object btnAgree: TBitBtn
      Left = 8
      Top = 16
      Width = 75
      Height = 25
      Caption = #21516#24847#25955#26700
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 0
      OnClick = btnAgreeClick
    end
    object btnDisagree: TBitBtn
      Left = 96
      Top = 16
      Width = 75
      Height = 25
      Caption = #19981#21516#24847
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 1
      OnClick = btnDisagreeClick
    end
  end
  object lbChi: TListBox
    Left = 169
    Top = 184
    Width = 121
    Height = 97
    ItemHeight = 13
    TabOrder = 32
    Visible = False
    OnClick = lbChiClick
  end
  object btnLiangGang: TButton
    Left = 385
    Top = 288
    Width = 75
    Height = 25
    Caption = #20142
    TabOrder = 33
    OnClick = btnLiangGangClick
  end
  object editLiangGang: TEdit
    Left = 171
    Top = 319
    Width = 569
    Height = 21
    TabOrder = 34
    Text = 
      '[{"gangFlag":0,"cards":""},{"gangFlag":2,"cards":"27,28,29,31,32' +
      '"}]'
  end
  object tmrDecTime: TTimer
    Interval = 100
    OnTimer = tmrDecTimeTimer
    Left = 496
    Top = 104
  end
end
