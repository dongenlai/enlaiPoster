object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'ddzrobot'
  ClientHeight = 613
  ClientWidth = 792
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object MemoLog: TMemo
    AlignWithMargins = True
    Left = 0
    Top = 0
    Width = 792
    Height = 513
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 100
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object ButtonStart: TButton
    Left = 40
    Top = 560
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 1
    OnClick = ButtonStartClick
  end
  object tmrAddMsg: TTimer
    Interval = 200
    OnTimer = tmrAddMsgTimer
    Left = 328
    Top = 152
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 392
    Top = 312
  end
end
