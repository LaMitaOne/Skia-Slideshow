unit Unit2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects;

type
  TForm2 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    FSlideshow: TObject;

    FBtnNext: TButton;
    FBtnRandom: TButton;
    FBtnPlayPause: TButton;
    FCheckRandomEffects: TCheckBox;
    FCheckShowTitle: TCheckBox;
    FCheckShowCaption: TCheckBox;
    FCheckShowEffect: TCheckBox;
    FTrackTime: TTrackBar;
    FLabelTime: TLabel;

    procedure BtnNextClick(Sender: TObject);
    procedure BtnRandomClick(Sender: TObject);
    procedure BtnPlayPauseClick(Sender: TObject);
    procedure CheckRandomEffectsChange(Sender: TObject);
    procedure CheckShowTitleChange(Sender: TObject);
    procedure CheckShowCaptionChange(Sender: TObject);
    procedure CheckShowEffectChange(Sender: TObject);
    procedure TrackTimeChange(Sender: TObject);
  public
    { Public-Deklarationen }
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

uses
  System.IOUtils, uSkiaSlideshowEngine;

procedure TForm2.FormCreate(Sender: TObject);
var
  ExePath: string;
  i: Integer;
  FileName: string;
  BottomBar: TLayout;
begin
  // 1. Create Slideshow Engine
  FSlideshow := TSkiaSlideshow.Create(Self);
  TSkiaSlideshow(FSlideshow).Name := 'MySlideshow';
  TSkiaSlideshow(FSlideshow).Parent := Self;
  TSkiaSlideshow(FSlideshow).Align := TAlignLayout.Client;

  TSkiaSlideshow(FSlideshow).Active := True;
  TSkiaSlideshow(FSlideshow).Interval := 3;
  TSkiaSlideshow(FSlideshow).TransitionTime := 1.2;
  TSkiaSlideshow(FSlideshow).RandomizeEffects := True;
  TSkiaSlideshow(FSlideshow).ShowEffectName := True;
  TSkiaSlideshow(FSlideshow).ShowTitle := True;
  TSkiaSlideshow(FSlideshow).ShowCaption := True;

  // 2. Create Bottom Layout
  BottomBar := TLayout.Create(Self);
  BottomBar.Name := 'BottomBar';
  BottomBar.Parent := Self;
  BottomBar.Align := TAlignLayout.Bottom;
  BottomBar.Height := 50;

  // --- Buttons links ---

  FBtnPlayPause := TButton.Create(Self);
  FBtnPlayPause.Name := 'BtnPlayPause';
  FBtnPlayPause.Parent := BottomBar;
  FBtnPlayPause.Text := 'Pause Auto';
  FBtnPlayPause.Width := 80;
  FBtnPlayPause.Align := TAlignLayout.Left;
  FBtnPlayPause.Margins := TBounds.Create(TRectF.Create(10, 8, 5, 8));
  FBtnPlayPause.OnClick := BtnPlayPauseClick;

  FBtnNext := TButton.Create(Self);
  FBtnNext.Name := 'BtnNext';
  FBtnNext.Parent := BottomBar;
  FBtnNext.Text := 'Next Image';
  FBtnNext.Width := 80;
  FBtnNext.Align := TAlignLayout.Left;
  FBtnNext.Margins := TBounds.Create(TRectF.Create(5, 8, 5, 8));
  FBtnNext.OnClick := BtnNextClick;

  FBtnRandom := TButton.Create(Self);
  FBtnRandom.Name := 'BtnRandom';
  FBtnRandom.Parent := BottomBar;
  FBtnRandom.Text := 'Random Image';
  FBtnRandom.Width := 85;
  FBtnRandom.Align := TAlignLayout.Left;
  FBtnRandom.Margins := TBounds.Create(TRectF.Create(5, 8, 5, 8));
  FBtnRandom.OnClick := BtnRandomClick;

  // --- Checkboxes mittig ---

  FCheckRandomEffects := TCheckBox.Create(Self);
  FCheckRandomEffects.Name := 'CheckRandom';
  FCheckRandomEffects.Parent := BottomBar;
  FCheckRandomEffects.Text := 'Random Effects';
  FCheckRandomEffects.Width := 115;
  FCheckRandomEffects.Align := TAlignLayout.Left;
  FCheckRandomEffects.Margins := TBounds.Create(TRectF.Create(10, 8, 5, 8));
  FCheckRandomEffects.IsChecked := True;
  FCheckRandomEffects.OnChange := CheckRandomEffectsChange;

  FCheckShowTitle := TCheckBox.Create(Self);
  FCheckShowTitle.Name := 'CheckTitle';
  FCheckShowTitle.Parent := BottomBar;
  FCheckShowTitle.Text := 'Show Title';
  FCheckShowTitle.Width := 85;
  FCheckShowTitle.Align := TAlignLayout.Left;
  FCheckShowTitle.Margins := TBounds.Create(TRectF.Create(10, 8, 5, 8));
  FCheckShowTitle.IsChecked := True;
  FCheckShowTitle.OnChange := CheckShowTitleChange;

  FCheckShowCaption := TCheckBox.Create(Self);
  FCheckShowCaption.Name := 'CheckCaption';
  FCheckShowCaption.Parent := BottomBar;
  FCheckShowCaption.Text := 'Show Caption';
  FCheckShowCaption.Width := 100;
  FCheckShowCaption.Align := TAlignLayout.Left;
  FCheckShowCaption.Margins := TBounds.Create(TRectF.Create(5, 8, 5, 8));
  FCheckShowCaption.IsChecked := True;
  FCheckShowCaption.OnChange := CheckShowCaptionChange;

  FCheckShowEffect := TCheckBox.Create(Self);
  FCheckShowEffect.Name := 'CheckEffectName';
  FCheckShowEffect.Parent := BottomBar;
  FCheckShowEffect.Text := 'Show Effect';
  FCheckShowEffect.Width := 90;
  FCheckShowEffect.Align := TAlignLayout.Left;
  FCheckShowEffect.Margins := TBounds.Create(TRectF.Create(5, 8, 5, 8));
  FCheckShowEffect.IsChecked := True;
  FCheckShowEffect.OnChange := CheckShowEffectChange;

  // --- Speed-Regler rechts ---

  FLabelTime := TLabel.Create(Self);
  FLabelTime.Name := 'LabelTime';
  FLabelTime.Parent := BottomBar;
  FLabelTime.Text := 'Speed: 1.2s';
  FLabelTime.Width := 70;
  FLabelTime.Align := TAlignLayout.Right;
  FLabelTime.Margins := TBounds.Create(TRectF.Create(10, 8, 10, 8));
  FLabelTime.StyledSettings := [];
  FLabelTime.TextSettings.VertAlign := TTextAlign.Center;

  FTrackTime := TTrackBar.Create(Self);
  FTrackTime.Name := 'TrackTime';
  FTrackTime.Parent := BottomBar;
  FTrackTime.Width := 150;
  FTrackTime.Align := TAlignLayout.Right;
  FTrackTime.Margins := TBounds.Create(TRectF.Create(5, 10, 5, 10));
  FTrackTime.Min := 0.2;
  FTrackTime.Max := 3.0;
  FTrackTime.Frequency := 0.1;
  FTrackTime.Value := 1.2;
  FTrackTime.OnChange := TrackTimeChange;

  // 3. Load Images
  ExePath := ExtractFilePath(ParamStr(0));
  for i := 1 to 3 do
  begin
    FileName := TPath.Combine(ExePath, IntToStr(i) + '.jpg');
    if FileExists(FileName) then
    begin
      TSkiaSlideshow(FSlideshow).AddImageFromFile(FileName, 'Beautiful Picture ' + IntToStr(i), 'Source: My Camera');
    end;
  end;
end;

procedure TForm2.BtnNextClick(Sender: TObject);
begin
  if Assigned(FSlideshow) then TSkiaSlideshow(FSlideshow).Next;
end;

procedure TForm2.BtnRandomClick(Sender: TObject);
begin
  if Assigned(FSlideshow) then TSkiaSlideshow(FSlideshow).ShowRandomImage;
end;

procedure TForm2.BtnPlayPauseClick(Sender: TObject);
begin
  if Assigned(FSlideshow) then
  begin
    if FBtnPlayPause.Text = 'Pause Auto' then
    begin
      TSkiaSlideshow(FSlideshow).Interval := 999999;
      FBtnPlayPause.Text := 'Play Auto';
    end
    else
    begin
      TSkiaSlideshow(FSlideshow).Interval := 3;
      FBtnPlayPause.Text := 'Pause Auto';
    end;
  end;
end;

procedure TForm2.CheckRandomEffectsChange(Sender: TObject);
begin
  if Assigned(FSlideshow) then TSkiaSlideshow(FSlideshow).RandomizeEffects := FCheckRandomEffects.IsChecked;
end;

procedure TForm2.CheckShowTitleChange(Sender: TObject);
begin
  if Assigned(FSlideshow) then TSkiaSlideshow(FSlideshow).ShowTitle := FCheckShowTitle.IsChecked;
end;

procedure TForm2.CheckShowCaptionChange(Sender: TObject);
begin
  if Assigned(FSlideshow) then TSkiaSlideshow(FSlideshow).ShowCaption := FCheckShowCaption.IsChecked;
end;

procedure TForm2.CheckShowEffectChange(Sender: TObject);
begin
  if Assigned(FSlideshow) then TSkiaSlideshow(FSlideshow).ShowEffectName := FCheckShowEffect.IsChecked;
end;

procedure TForm2.TrackTimeChange(Sender: TObject);
begin
  if Assigned(FSlideshow) then
  begin
    TSkiaSlideshow(FSlideshow).TransitionTime := FTrackTime.Value;
    FLabelTime.Text := 'Speed: ' + FloatToStrF(FTrackTime.Value, ffFixed, 0, 1) + 's';
  end;
end;

end.
