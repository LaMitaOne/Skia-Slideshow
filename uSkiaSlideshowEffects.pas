{*******************************************************************************
  Skia Slideshow Effects
********************************************************************************
  Implementation of various transition effects for TSkiaSlideshow.
*******************************************************************************}

unit uSkiaSlideshowEffects;

interface

uses
  System.SysUtils, System.Types, System.Classes, System.Math, System.UITypes,
  FMX.Graphics, System.Skia, FMX.Skia, uSkiaSlideshowEngine;

type
  TEffectBase = class(TInterfacedObject, ISlideTransitionEffect)
  protected
    FName: string;
  public
    constructor Create(const AName: string);
    function GetEffectName: string;
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); virtual;
  end;

  TSkiaEffectFactory = class
  public
    class function CreateEffect(ATransition: TSlideTransition): ISlideTransitionEffect;
  end;

implementation

{==============================================================================
  TEffectBase Implementation
==============================================================================}

constructor TEffectBase.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TEffectBase.GetEffectName: string;
begin
  Result := FName;
end;

procedure TEffectBase.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
begin
  // Base implementation does nothing.
end;

{==============================================================================
  HELPER FUNCTIONS
==============================================================================}
procedure DrawImageFit(const ACanvas: ISkCanvas; const AImage: ISkImage; const ADest: TRectF; const Zoom: Single = 1.0; const PanX: Single = 0.0; const PanY: Single = 0.0);
var
  SrcW, SrcH: Single;
  DestW, DestH: Single;
  Ratio, DestRatio: Single;
  NewW, NewH: Single;
  DrawRect: TRectF;
  Paint: ISkPaint;
  HighQuality: TSkSamplingOptions;
  CachedImg: ISkImage;
begin
  if (AImage = nil) or (ADest.Width <= 0) or (ADest.Height <= 0) then
    Exit;

  // Performance: Ensure the image is a raster image in RAM, not lazy-loaded from stream
  // This prevents severe stuttering when resizing the window!
  if not AImage.IsTextureBacked then
    CachedImg := AImage.MakeRasterImage
  else
    CachedImg := AImage;

  SrcW := CachedImg.Width;
  SrcH := CachedImg.Height;
  DestW := ADest.Width;
  DestH := ADest.Height;

  Ratio := SrcW / SrcH;
  DestRatio := DestW / DestH;

  if Ratio > DestRatio then
  begin
    NewH := DestH;
    NewW := NewH * Ratio;
  end
  else
  begin
    NewW := DestW;
    NewH := NewW / Ratio;
  end;

  NewW := NewW * Zoom;
  NewH := NewH * Zoom;

  DrawRect := TRectF.Create(ADest.CenterPoint.X - (NewW / 2) + PanX, ADest.CenterPoint.Y - (NewH / 2) + PanY, ADest.CenterPoint.X + (NewW / 2) + PanX, ADest.CenterPoint.Y + (NewH / 2) + PanY);

  Paint := TSkPaint.Create;
  Paint.AntiAlias := True;
  HighQuality := TSkSamplingOptions.Medium;

  ACanvas.DrawImageRect(CachedImg, TRectF.Create(0, 0, SrcW, SrcH), DrawRect, HighQuality, Paint);
end;

{==============================================================================
  EFFECT IMPLEMENTATIONS
==============================================================================}

// --- EFFECT 1: CROSSFADE ---
type
  TEffectCrossfade = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectCrossfade.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  Paint: ISkPaint;
begin
  DrawImageFit(ACanvas, AImage1, ADest, 1.0, 0, 0);

  if AImage2 <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    Paint.Alpha := Round(255 * Progress);

    ACanvas.SaveLayer(ADest, Paint);
    try
      DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
    finally
      ACanvas.Restore;
    end;
  end;
end;

// --- EFFECT 2: SLIDE LEFT ---
type
  TEffectSlideLeft = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectSlideLeft.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  OffsetX: Single;
begin
  OffsetX := ADest.Width * Progress;
  ACanvas.Save;
  ACanvas.ClipRect(ADest);
  try
    ACanvas.Translate(-OffsetX, 0);
    DrawImageFit(ACanvas, AImage1, ADest, 1.0, 0, 0);
    ACanvas.Translate(ADest.Width, 0);
    if AImage2 <> nil then
      DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
  finally
    ACanvas.Restore;
  end;
end;

// --- EFFECT 3: ZOOM ---
type
  TEffectZoom = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectZoom.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  Paint: ISkPaint;
  Scale1, Scale2: Single;
begin
  Scale1 := 1.0 + (Progress * 0.5);
  DrawImageFit(ACanvas, AImage1, ADest, Scale1, 0, 0);

  if AImage2 <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.Alpha := Round(255 * Progress);
    ACanvas.SaveLayer(ADest, Paint);
    try
      Scale2 := 1.5 - (Progress * 0.5);
      DrawImageFit(ACanvas, AImage2, ADest, Scale2, 0, 0);
    finally
      ACanvas.Restore;
    end;
  end;
end;

// --- EFFECT 4: WIPE DIAGONAL ---
type
  TEffectWipe = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectWipe.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  Paint: ISkPaint;
  ClipRect: TRectF;
begin
  DrawImageFit(ACanvas, AImage1, ADest, 1.0, 0, 0);

  if AImage2 <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    ACanvas.SaveLayer(ADest, Paint);
    try
      ClipRect := TRectF.Create(ADest.Left, ADest.Top, ADest.Right * Progress, ADest.Bottom * Progress);
      ACanvas.ClipRect(ClipRect);
      DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
    finally
      ACanvas.Restore;
    end;
  end;
end;

// --- EFFECT 5: ZOOM BLUR ---
type
  TEffectZoomBlur = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectZoomBlur.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  Paint: ISkPaint;
begin
  Paint := TSkPaint.Create;
  if Progress > 0.01 then
    Paint.ImageFilter := TSkImageFilter.MakeBlur(Progress * 15, Progress * 15);

  ACanvas.SaveLayer(ADest, Paint);
  try
    DrawImageFit(ACanvas, AImage1, ADest, 1.0 + (Progress * 0.8), 0, 0);
  finally
    ACanvas.Restore;
  end;

  if AImage2 <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.Alpha := Round(255 * Progress);
    ACanvas.SaveLayer(ADest, Paint);
    try
      DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
    finally
      ACanvas.Restore;
    end;
  end;
end;

// --- EFFECT 6: REVEAL CENTER ---
type
  TEffectReveal = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectReveal.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  Paint: ISkPaint;
  MaxSize, Radius: Single;
  Center: TPointF;
  ClipRect: TRectF;
begin
  DrawImageFit(ACanvas, AImage1, ADest, 1.0, 0, 0);

  if AImage2 <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    ACanvas.SaveLayer(ADest, Paint);
    try
      Center := ADest.CenterPoint;
      MaxSize := Max(ADest.Width, ADest.Height);
      Radius := MaxSize * Progress;
      if Radius > 0 then
      begin
        ClipRect := TRectF.Create(Center.X - Radius, Center.Y - Radius, Center.X + Radius, Center.Y + Radius);
        ACanvas.ClipRect(ClipRect);
        DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
      end;
    finally
      ACanvas.Restore;
    end;
  end;
end;

// --- EFFECT 7: BARN DOORS ---
type
  TEffectBarnDoors = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectBarnDoors.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  Paint: ISkPaint;
  DoorWidth: Single;
  LeftDoor, RightDoor: TRectF;
begin
  DrawImageFit(ACanvas, AImage1, ADest, 1.0, 0, 0);

  if AImage2 <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    ACanvas.SaveLayer(ADest, Paint);
    try
      DoorWidth := (ADest.Width / 2) * Progress;
      LeftDoor := TRectF.Create(ADest.Left, ADest.Top, ADest.Left + DoorWidth, ADest.Bottom);
      RightDoor := TRectF.Create(ADest.Right - DoorWidth, ADest.Top, ADest.Right, ADest.Bottom);

      ACanvas.Save;
      try
        ACanvas.ClipRect(LeftDoor);
        DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
      finally
        ACanvas.Restore;
      end;

      ACanvas.Save;
      try
        ACanvas.ClipRect(RightDoor);
        DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
      finally
        ACanvas.Restore;
      end;
    finally
      ACanvas.Restore;
    end;
  end;
end;

// --- EFFECT 8: IRIS CIRCLE ---
type
  TEffectIrisCircle = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectIrisCircle.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  Paint: ISkPaint;
  MaxSize, Radius: Single;
  Center: TPointF;
  ClipRect: TRectF;
  RoundRect: ISkRoundRect;
begin
  DrawImageFit(ACanvas, AImage1, ADest, 1.0, 0, 0);

  if AImage2 <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    ACanvas.SaveLayer(ADest, Paint);
    try
      Center := ADest.CenterPoint;
      MaxSize := Max(ADest.Width, ADest.Height) / 2;
      Radius := MaxSize * Progress;

      if Radius > 0 then
      begin
        ClipRect := TRectF.Create(Center.X - Radius, Center.Y - Radius, Center.X + Radius, Center.Y + Radius);
        RoundRect := TSkRoundRect.Create;
        RoundRect.SetRect(ClipRect, Radius, Radius);
        ACanvas.ClipRoundRect(RoundRect);
        DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
      end;
    finally
      ACanvas.Restore;
    end;
  end;
end;

// --- EFFECT 9: CLOCK WIPE ---
type
  TEffectClockWipe = class(TEffectBase)
  public
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single); override;
  end;

procedure TEffectClockWipe.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AImage1, AImage2: ISkImage; const Progress: Single);
var
  Paint: ISkPaint;
  PathBuilder: ISkPathBuilder;
  Center: TPointF;
  Radius, Angle: Single;
  ClipRect: TRectF;
begin
  DrawImageFit(ACanvas, AImage1, ADest, 1.0, 0, 0);

  if AImage2 <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    ACanvas.SaveLayer(ADest, Paint);
    try
      Center := ADest.CenterPoint;
      Radius := Max(ADest.Width, ADest.Height);
      Angle := (Progress * 360);
      ClipRect := TRectF.Create(Center.X - Radius, Center.Y - Radius, Center.X + Radius, Center.Y + Radius);

      PathBuilder := TSkPathBuilder.Create;
      PathBuilder.MoveTo(Center);
      PathBuilder.AddArc(ClipRect, -90, Angle);
      PathBuilder.Close;

      ACanvas.ClipPath(PathBuilder.Snapshot);
      DrawImageFit(ACanvas, AImage2, ADest, 1.0, 0, 0);
    finally
      ACanvas.Restore;
    end;
  end;
end;

{==============================================================================
  FACTORY IMPLEMENTATION
==============================================================================}
class function TSkiaEffectFactory.CreateEffect(ATransition: TSlideTransition): ISlideTransitionEffect;
begin
  case ATransition of
    stCrossfade:
      Result := TEffectCrossfade.Create('Crossfade');
    stSlideLeft:
      Result := TEffectSlideLeft.Create('Slide Left');
    stZoom:
      Result := TEffectZoom.Create('Zoom');
    stWipe:
      Result := TEffectWipe.Create('Wipe Diagonal');
    stZoomBlur:
      Result := TEffectZoomBlur.Create('Zoom Blur');
    stReveal:
      Result := TEffectReveal.Create('Reveal Center');
    stBarnDoors:
      Result := TEffectBarnDoors.Create('Barn Doors');
    stIrisCircle:
      Result := TEffectIrisCircle.Create('Iris Circle');
    stClockWipe:
      Result := TEffectClockWipe.Create('Clock Wipe');
  else
    Result := TEffectCrossfade.Create('Crossfade');
  end;
end;

end.

