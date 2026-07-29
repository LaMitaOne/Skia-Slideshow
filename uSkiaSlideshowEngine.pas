{*******************************************************************************
  Skia Slideshow Engine
********************************************************************************
  A high-performance, hardware-accelerated slideshow component for Delphi FMX.
*******************************************************************************}

unit uSkiaSlideshowEngine;

interface

uses
  System.SysUtils, System.Types, System.Classes, System.Math,
  System.Generics.Collections, System.SyncObjs, System.UITypes, System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Skia, System.Skia;

type
  TSlideTransition = (stCrossfade, stSlideLeft, stZoom, stWipe, stZoomBlur, stReveal, stBarnDoors, stIrisCircle, stClockWipe);

  TSkiaSlideshow = class;

  TSkiaDrawEvent = procedure(Sender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF) of object;

  ISlideTransitionEffect = interface
    ['{C3D4E5F6-A7B8-4789-0033-445566778899}']
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
    function GetEffectName: string;
  end;

  TSkiaSlideshow = class(TSkCustomControl)
  private
    FThread: TThread;
    FActive: Boolean;
    FLock: TCriticalSection;

    FImages: TList<ISkImage>;
    FTitles: TList<string>;
    FCaptions: TList<string>;

    FCurrentIndex: Integer;
    FNextIndex: Integer;
    FProgress: Double;

    FInterval: Integer;
    FTransitionTime: Double;
    FElapsed: Double;

    FTransition: TSlideTransition;
    FRandomizeEffects: Boolean;
    FCurrentEffect: ISlideTransitionEffect;
    FCurrentEffectName: string;

    FCaptionColor: TAlphaColor;
    FIsTransitioning: Boolean;
    FPrevWidth: Single;
    FPrevHeight: Single;

    FOnCustomDraw: TSkiaDrawEvent;
    FOnTransitionStart: TNotifyEvent;
    FOnTransitionComplete: TNotifyEvent;
    FShowEffectName: Boolean;
    FShowTitle: Boolean;
    FShowCaption: Boolean;

    procedure SetActive(const Value: Boolean);
    procedure SetTransition(const Value: TSlideTransition);
    procedure SetInterval(const Value: Integer);
    procedure SetTransitionTime(const Value: Double);
    procedure SetRandomizeEffects(const Value: Boolean);
    procedure SetShowEffectName(const Value: Boolean);
    procedure SetShowTitle(const Value: Boolean);
    procedure SetShowCaption(const Value: Boolean);
    procedure CreateEffect;
    procedure PickRandomEffect;
    procedure StartTransition(TargetIndex: Integer);
    procedure UpdateLogic(DeltaSec: Double);
    procedure SafeInvalidate;
    procedure StartThread;
    procedure StopThread;
    function GetCurrentImage: ISkImage;
    function GetNextImage: ISkImage;
    function GetCurrentTitle: string;
    function GetCurrentCaption: string;
  protected
    procedure Resize; override;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddImage(const AImage: ISkImage; const ATitle: string = ''; const ACaption: string = '');
    procedure AddImageFromFile(const AFileName: string; const ATitle: string = ''; const ACaption: string = '');
    procedure ClearImages;
    procedure Next;
    procedure Prev;
    procedure ShowRandomImage;

    property Active: Boolean read FActive write SetActive;
    property Transition: TSlideTransition read FTransition write SetTransition;
    property Interval: Integer read FInterval write SetInterval;
    property TransitionTime: Double read FTransitionTime write SetTransitionTime;
    property CaptionColor: TAlphaColor read FCaptionColor write FCaptionColor;
    property RandomizeEffects: Boolean read FRandomizeEffects write SetRandomizeEffects;
  published
    property ShowEffectName: Boolean read FShowEffectName write SetShowEffectName default False;
    property ShowTitle: Boolean read FShowTitle write SetShowTitle default True;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption default True;
    property OnCustomDraw: TSkiaDrawEvent read FOnCustomDraw write FOnCustomDraw;
    property OnTransitionStart: TNotifyEvent read FOnTransitionStart write FOnTransitionStart;
    property OnTransitionComplete: TNotifyEvent read FOnTransitionComplete write FOnTransitionComplete;
  end;

implementation

uses
  uSkiaSlideshowEffects;

{ TSkiaSlideshow }

constructor TSkiaSlideshow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLock := TCriticalSection.Create;
  FImages := TList<ISkImage>.Create;
  FTitles := TList<string>.Create;
  FCaptions := TList<string>.Create;

  Align := TAlignLayout.Client;
  HitTest := True;

  FActive := True;
  FInterval := 5;
  FTransitionTime := 1.0;
  FElapsed := 0;
  FProgress := 0;
  FCurrentIndex := -1;
  FNextIndex := -1;
  FIsTransitioning := False;

  FTransition := stCrossfade;
  FRandomizeEffects := False;
  FCaptionColor := TAlphaColors.White;

  FShowEffectName := False;
  FShowTitle := True;
  FShowCaption := True;

  FPrevWidth := 0;
  FPrevHeight := 0;

  CreateEffect;
  StartThread;
end;

destructor TSkiaSlideshow.Destroy;
begin
  StopThread;
  FLock.Acquire;
  try
    FImages.Free;
    FTitles.Free;
    FCaptions.Free;
  finally
    FLock.Release;
  end;
  FreeAndNil(FLock);
  inherited;
end;

procedure TSkiaSlideshow.CreateEffect;
begin
  FCurrentEffect := TSkiaEffectFactory.CreateEffect(FTransition);
  if Assigned(FCurrentEffect) then
    FCurrentEffectName := FCurrentEffect.GetEffectName
  else
    FCurrentEffectName := '';
end;

procedure TSkiaSlideshow.PickRandomEffect;
var
  RandVal: Integer;
begin
  RandVal := Random(Ord(High(TSlideTransition)) + 1);
  FTransition := TSlideTransition(RandVal);
  CreateEffect;
end;

procedure TSkiaSlideshow.SetTransition(const Value: TSlideTransition);
begin
  if FTransition <> Value then
  begin
    FLock.Acquire;
    try
      FTransition := Value;
      CreateEffect;
    finally
      FLock.Release;
    end;
    Redraw;
  end;
end;

procedure TSkiaSlideshow.SetRandomizeEffects(const Value: Boolean);
begin
  if FRandomizeEffects <> Value then
  begin
    FLock.Acquire;
    try
      FRandomizeEffects := Value;
    finally
      FLock.Release;
    end;
  end;
end;

procedure TSkiaSlideshow.SetShowEffectName(const Value: Boolean);
begin
  if FShowEffectName <> Value then
  begin
    FShowEffectName := Value;
    Redraw;
  end;
end;

procedure TSkiaSlideshow.SetShowTitle(const Value: Boolean);
begin
  if FShowTitle <> Value then
  begin
    FShowTitle := Value;
    Redraw;
  end;
end;

procedure TSkiaSlideshow.SetShowCaption(const Value: Boolean);
begin
  if FShowCaption <> Value then
  begin
    FShowCaption := Value;
    Redraw;
  end;
end;

procedure TSkiaSlideshow.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FLock.Acquire;
    try
      FActive := Value;
    finally
      FLock.Release;
    end;
  end;
end;

procedure TSkiaSlideshow.SetInterval(const Value: Integer);
begin
  if FInterval <> Value then
  begin
    FLock.Acquire;
    try
      FInterval := Value;
    finally
      FLock.Release;
    end;
  end;
end;

procedure TSkiaSlideshow.SetTransitionTime(const Value: Double);
begin
  if FTransitionTime <> Value then
  begin
    FLock.Acquire;
    try
      FTransitionTime := Value;
    finally
      FLock.Release;
    end;
  end;
end;

procedure TSkiaSlideshow.AddImage(const AImage: ISkImage; const ATitle: string = ''; const ACaption: string = '');
begin
  FLock.Acquire;
  try
    FImages.Add(AImage);
    FTitles.Add(ATitle);
    FCaptions.Add(ACaption);
    if FCurrentIndex = -1 then
    begin
      FCurrentIndex := 0;
      FNextIndex := 0;
    end;
  finally
    FLock.Release;
  end;
  Redraw;
end;

procedure TSkiaSlideshow.AddImageFromFile(const AFileName: string; const ATitle: string = ''; const ACaption: string = '');
var
  Bytes: TBytes;
  RawImg, CachedImg: ISkImage;
begin
  if FileExists(AFileName) then
  begin
    Bytes := TFile.ReadAllBytes(AFileName);
    RawImg := TSkImage.MakeFromEncoded(Bytes);
    if RawImg <> nil then
    begin
      CachedImg := RawImg.MakeRasterImage;
      if CachedImg <> nil then
        AddImage(CachedImg, ATitle, ACaption)
      else
        AddImage(RawImg, ATitle, ACaption);
    end;
  end;
end;

procedure TSkiaSlideshow.ClearImages;
begin
  FLock.Acquire;
  try
    FImages.Clear;
    FTitles.Clear;
    FCaptions.Clear;
    FCurrentIndex := -1;
    FNextIndex := -1;
    FIsTransitioning := False;
    FElapsed := 0;
    FProgress := 0;
  finally
    FLock.Release;
  end;
  Redraw;
end;

procedure TSkiaSlideshow.StartTransition(TargetIndex: Integer);
begin
  FLock.Acquire;
  try
    if (FImages.Count > 1) and (TargetIndex <> FCurrentIndex) then
    begin
      FNextIndex := TargetIndex;
      FIsTransitioning := True;
      FProgress := 0;
      FElapsed := 0;

      if FRandomizeEffects then
        PickRandomEffect;
    end;
  finally
    FLock.Release;
  end;

  TThread.Queue(nil,
    procedure
    begin
      if Assigned(FOnTransitionStart) then
        FOnTransitionStart(Self);
    end);
end;

procedure TSkiaSlideshow.Next;
var
  Idx: Integer;
begin
  FLock.Acquire;
  try
    if FImages.Count > 0 then
    begin
      Idx := FCurrentIndex;
      if FIsTransitioning then
        Idx := FNextIndex;
    end;
  finally
    FLock.Release;
  end;

  if FImages.Count > 0 then
    StartTransition((Idx + 1) mod FImages.Count);
end;

procedure TSkiaSlideshow.Prev;
var
  Idx: Integer;
begin
  FLock.Acquire;
  try
    if FImages.Count > 0 then
    begin
      Idx := FCurrentIndex;
      if FIsTransitioning then
        Idx := FNextIndex;
    end;
  finally
    FLock.Release;
  end;

  if FImages.Count > 0 then
    StartTransition((Idx - 1 + FImages.Count) mod FImages.Count);
end;

procedure TSkiaSlideshow.ShowRandomImage;
var
  NewIdx: Integer;
begin
  FLock.Acquire;
  try
    if FImages.Count > 1 then
    begin
      NewIdx := FCurrentIndex;
      while NewIdx = FCurrentIndex do
        NewIdx := Random(FImages.Count);
    end
    else
      NewIdx := -1;
  finally
    FLock.Release;
  end;

  if NewIdx <> -1 then
    StartTransition(NewIdx);
end;

function TSkiaSlideshow.GetCurrentImage: ISkImage;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < FImages.Count) then
    Result := FImages[FCurrentIndex]
  else
    Result := nil;
end;

function TSkiaSlideshow.GetNextImage: ISkImage;
begin
  if (FNextIndex >= 0) and (FNextIndex < FImages.Count) then
    Result := FImages[FNextIndex]
  else
    Result := nil;
end;

function TSkiaSlideshow.GetCurrentTitle: string;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < FTitles.Count) then
    Result := FTitles[FCurrentIndex]
  else
    Result := '';
end;

function TSkiaSlideshow.GetCurrentCaption: string;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < FCaptions.Count) then
    Result := FCaptions[FCurrentIndex]
  else
    Result := '';
end;

{------------------------------------------------------------------------------
  INTERNAL LOGIC & THREADING
------------------------------------------------------------------------------}
procedure TSkiaSlideshow.UpdateLogic(DeltaSec: Double);
begin
  if not FActive then
    Exit;

  FLock.Acquire;
  try
    if FImages.Count = 0 then
      Exit;

    FElapsed := FElapsed + DeltaSec;

    if FIsTransitioning then
    begin
      if FTransitionTime > 0 then
        FProgress := FElapsed / FTransitionTime
      else
        FProgress := 1.0;

      if FProgress >= 1.0 then
      begin
        FProgress := 1.0;
        FIsTransitioning := False;
        FCurrentIndex := FNextIndex;
        FElapsed := 0;

        TThread.Queue(nil,
          procedure
          begin
            if Assigned(FOnTransitionComplete) then
              FOnTransitionComplete(Self);
          end);
      end;
    end
    else
    begin
      if FElapsed >= FInterval then
      begin
        if FImages.Count > 1 then
        begin
          FNextIndex := (FCurrentIndex + 1) mod FImages.Count;
          FIsTransitioning := True;
          FProgress := 0;
          FElapsed := 0;

          if FRandomizeEffects then
            PickRandomEffect;
        end;
      end;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TSkiaSlideshow.SafeInvalidate;
begin
  if csDestroying in ComponentState then
    Exit;
  TThread.Queue(nil,
    procedure
    begin
      if not (csDestroying in ComponentState) and Assigned(Self) then
      begin
        Self.Redraw;
      end;
    end);
end;

procedure TSkiaSlideshow.StartThread;
begin
  if Assigned(FThread) then
    Exit;
  FThread := TThread.CreateAnonymousThread(
    procedure
    var
      LastTime, NowTime, DeltaMS: Cardinal;
      SleepTime: Integer;
    begin
      LastTime := TThread.GetTickCount;
      while not TThread.CheckTerminated do
      begin
        NowTime := TThread.GetTickCount;
        DeltaMS := NowTime - LastTime;
        if DeltaMS = 0 then
          DeltaMS := 1;
        LastTime := NowTime;

        if FActive then
        begin
          UpdateLogic(DeltaMS / 1000);
          SafeInvalidate;
        end;

        SleepTime := 16; // ~60 FPS
        Sleep(SleepTime);
      end;
    end);
  FThread.FreeOnTerminate := True;
  FThread.Start;
end;

procedure TSkiaSlideshow.StopThread;
begin
  FActive := False;
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    Sleep(50);
  end;
end;

{------------------------------------------------------------------------------
  OVERRIDE METHODS
------------------------------------------------------------------------------}
procedure TSkiaSlideshow.Resize;
begin
  inherited;
  if (FPrevWidth <> Width) or (FPrevHeight <> Height) then
  begin
    FPrevWidth := Width;
    FPrevHeight := Height;
    if not (csDestroying in ComponentState) then
      Redraw;
  end;
end;

procedure TSkiaSlideshow.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var
  CurrentImg, NextImg: ISkImage;
  Eff: ISlideTransitionEffect;
  Progress: Single;
  TitleStr, CaptionStr: string;
  TitleFont, CaptionFont, NameFont: ISkFont;
  TextPaint: ISkPaint;
begin
  ACanvas.Clear(TAlphaColors.Black);

  FLock.Acquire;
  try
    CurrentImg := GetCurrentImage;
    NextImg := GetNextImage;
    Eff := FCurrentEffect;
    Progress := FProgress;
    TitleStr := GetCurrentTitle;
    CaptionStr := GetCurrentCaption;
  finally
    FLock.Release;
  end;

  // Draw the effect
  if Assigned(Eff) and (CurrentImg <> nil) then
  begin
    if FIsTransitioning and (NextImg <> nil) then
      Eff.Draw(ACanvas, ADest, CurrentImg, NextImg, Progress)
    else
      Eff.Draw(ACanvas, ADest, CurrentImg, CurrentImg, 1.0);
  end;

  // Draw Texts on top
  TextPaint := TSkPaint.Create;
  TextPaint.AntiAlias := True;
  TextPaint.Color := FCaptionColor;

  if FShowTitle and (TitleStr <> '') then
  begin
    TitleFont := TSkFont.Create(TSkTypeface.MakeDefault, 42);
    TextPaint.Color := TAlphaColors.Black;
    ACanvas.DrawSimpleText(TitleStr, ADest.Left + 22, ADest.Top + 52, TitleFont, TextPaint);
    TextPaint.Color := FCaptionColor;
    ACanvas.DrawSimpleText(TitleStr, ADest.Left + 20, ADest.Top + 50, TitleFont, TextPaint);
  end;

  if FShowCaption and (CaptionStr <> '') then
  begin
    CaptionFont := TSkFont.Create(TSkTypeface.MakeDefault, 18);
    TextPaint.Color := TAlphaColors.Black;
    ACanvas.DrawSimpleText(CaptionStr, ADest.Left + 22, ADest.Bottom - 18, CaptionFont, TextPaint);
    TextPaint.Color := FCaptionColor;
    ACanvas.DrawSimpleText(CaptionStr, ADest.Left + 20, ADest.Bottom - 20, CaptionFont, TextPaint);
  end;

  if Assigned(FOnCustomDraw) then
    FOnCustomDraw(Self, ACanvas, ADest);

  if FShowEffectName and (FCurrentEffectName <> '') then
  begin
    NameFont := TSkFont.Create(TSkTypeface.MakeDefault, 16);
    TextPaint.Color := TAlphaColors.Yellow;
    ACanvas.DrawSimpleText('Effect: ' + FCurrentEffectName, ADest.Right - 200, ADest.Top + 25, NameFont, TextPaint);
  end;
end;

end.

