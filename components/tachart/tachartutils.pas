{
 /***************************************************************************
                               TAChartUtils.pas
                               ----------------
              Component Library Standard Graph Utiliity Functions


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

Authors: Luнs Rodrigues, Philippe Martinole, Alexander Klenin

}

unit TAChartUtils;

{$H+}

interface

uses
  Classes, Graphics, Math, Types, SysUtils;

const
  Colors: array [1..15] of TColor = (
    clRed, clGreen, clYellow, clBlue, clWhite, clGray, clFuchsia,
    clTeal, clNavy, clMaroon, clLime, clOlive, clPurple, clSilver, clAqua);
  clTAColor = clScrollBar;
  CHART_COMPONENT_IDE_PAGE = 'Chart';
  PERCENT = 0.01;

type
  EChartError = class(Exception);
  EChartIntervalError = class(EChartError);
  EListenerError = class(EChartError);

  TDoublePoint = record
    X, Y: Double;
  end;

  TDoubleRect = record
  case Integer of
    0: (
      a, b: TDoublePoint;
    );
    1: (
      coords: array [1..4] of Double;
    );
  end;

  TChartDistance = 0..MaxInt;

  TPointDistFunc = function (const A, B: TPoint): Integer;

  TAxisScale = (asIncreasing, asDecreasing, asLogIncreasing, asLogDecreasing);

  TPenBrushFont = set of (pbfPen, pbfBrush, pbfFont);

  TSeriesMarksStyle = (
    smsCustom,         { user-defined }
    smsNone,           { no labels }
    smsValue,          { 1234 }
    smsPercent,        { 12 % }
    smsLabel,          { Cars }
    smsLabelPercent,   { Cars 12 % }
    smsLabelValue,     { Cars 1234 }
    smsLegend,         { ? }
    smsPercentTotal,   { 12 % of 1234 }
    smsLabelPercentTotal, { Cars 12 % of 1234 }
    smsXValue);        { 21/6/1996 }

  TSeriesPointerStyle = (
    psNone, psRectangle, psCircle, psCross, psDiagCross, psStar,
    psLowBracket, psHighBracket, psLeftBracket, psRightBracket, psDiamond);

  { TPenBrushFontRecall }

  TPenBrushFontRecall = class
  private
    FBrush: TBrush;
    FCanvas: TCanvas;
    FFont: TFont;
    FPen: TPen;
  public
    constructor Create(ACanvas: TCanvas; AParams: TPenBrushFont);
    destructor Destroy; override;
    procedure Recall;
  end;

  TDoubleInterval = record
    FStart, FEnd: Double;
  end;

  { TIntervalList }

  TIntervalList = class
  private
    FEpsilon: Double;
    FIntervals: array of TDoubleInterval;
    FOnChange: TNotifyEvent;
    procedure Changed;
    function GetInterval(AIndex: Integer): TDoubleInterval;
    function GetIntervalCount: Integer;
    procedure SetEpsilon(AValue: Double);
    procedure SetOnChange(AValue: TNotifyEvent);
  public
    constructor Create;
  public
    procedure AddPoint(APoint: Double); inline;
    procedure AddRange(AStart, AEnd: Double);
    procedure Clear;
    function Intersect(
      var ALeft, ARight: Double; var AHint: Integer): Boolean;
  public
    property Epsilon: Double read FEpsilon write SetEpsilon;
    property Interval[AIndex: Integer]: TDoubleInterval read GetInterval;
    property IntervalCount: Integer read GetIntervalCount;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  end;

  TCaseOfTwo = (cotNone, cotFirst, cotSecond, cotBoth);

  { TIndexedComponent }

  TIndexedComponent = class (TComponent)
  protected
    function GetIndex: Integer; virtual; abstract;
    procedure SetIndex(AValue: Integer); virtual; abstract;
  public
    property Index: Integer read GetIndex write SetIndex;
  end;

  TBroadcaster = class;

  { TListener }

  TListener = class
  private
    FBroadcaster: TBroadcaster;
    FOnNotify: TNotifyEvent;
    FRef: PPointer;
    function GetIsListening: Boolean;
  public
    constructor Create(ARef: PPointer; AOnNotify: TNotifyEvent);
    destructor Destroy; override;
    procedure Forget; virtual;
    procedure Notify(ASender: TObject); virtual;
    property IsListening: Boolean read GetIsListening;
  end;

  { TBroadcaster }

  TBroadcaster = class(TFPList)
  public
    destructor Destroy; override;
  public
    procedure Broadcast;
    procedure Subscribe(AListener: TListener);
    procedure Unsubscribe(AListener: TListener);
  end;

const
  // 0-value, 1-percent, 2-label, 3-total, 4-xvalue
  SERIES_MARK_FORMATS: array [TSeriesMarksStyle] of String = (
    '', '',
    '%0:.9g', // smsValue
    '%1:.2f%%', // smsPercent
    '%2:s', // smsLabel
    '%2:s %1:.2f%%', // smsLabelPercent
    '%2:s %0:.9g', // smsLabelValue
    '%2:s', // smsLegend: not sure what it means, left for Delphi compatibility
    '%1:.2f%% of %3:g', // smsPercentTotal
    '%1:.2f%% of %3:g', // smsLabelPercentTotal
    '%4:.9g' // smsXValue
  );
  ZeroDoublePoint: TDoublePoint = (X: 0; Y: 0);
  EmptyDoubleRect: TDoubleRect = (coords: (0, 0, 0, 0));
  EmptyExtent: TDoubleRect =
    (coords: (Infinity, Infinity, NegInfinity, NegInfinity));
  CASE_OF_TWO: array [Boolean, Boolean] of TCaseOfTwo =
    ((cotNone, cotSecond), (cotFirst, cotBoth));

function BoundsSize(ALeft, ATop: Integer; ASize: TSize): TRect; inline;

function DoubleRect(AX1, AY1, AX2, AY2: Double): TDoubleRect; inline;

procedure DrawLineDepth(ACanvas: TCanvas; AX1, AY1, AX2, AY2, ADepth: Integer);
procedure DrawLineDepth(ACanvas: TCanvas; const AP1, AP2: TPoint; ADepth: Integer);

procedure Exchange(var A, B: Integer); overload;
procedure Exchange(var A, B: Double); overload;
procedure Exchange(var A, B: TDoublePoint); overload;
procedure Exchange(var A, B: String); overload;

procedure ExpandRange(var ALo, AHi: Double; ACoeff: Double); inline;

function GetIntervals(AMin, AMax: Double; AInverted: Boolean): TDoubleDynArray;

function LineIntersectsRect(
  var AA, AB: TDoublePoint; const ARect: TDoubleRect): Boolean;

procedure NormalizeRect(var ARect: TRect);

function PointDist(const A, B: TPoint): Integer; inline;
function PointDistX(const A, B: TPoint): Integer; inline;
function PointDistY(const A, B: TPoint): Integer; inline;

procedure PrepareSimplePen(ACanvas: TCanvas; AColor: TColor);
procedure PrepareXorPen(ACanvas: TCanvas);

function RectIntersectsRect(
  var ARect: TDoubleRect; const AFixed: TDoubleRect): Boolean;

function RoundChecked(A: Double): Integer; inline;

function TypicalTextHeight(ACanvas: TCanvas): Integer;

// Call this to silence 'parameter is unused' hint
procedure Unused(const A1);
procedure Unused(const A1, A2);

procedure UpdateMinMax(AValue: Double; var AMin, AMax: Double);

operator +(const A: TPoint; B: TSize): TPoint; overload; inline;
operator +(const A, B: TPoint): TPoint; overload; inline;
operator +(const A, B: TDoublePoint): TDoublePoint; overload; inline;
operator -(const A, B: TPoint): TPoint; overload; inline;
operator -(const A, B: TDoublePoint): TDoublePoint; overload; inline;
operator =(const A, B: TMethod): Boolean; overload; inline;

implementation

uses
  LCLIntf;

function BoundsSize(ALeft, ATop: Integer; ASize: TSize): TRect; inline;
begin
  Result := Bounds(ALeft, ATop, ASize.cx, ASize.cy);
end;

procedure CalculateIntervals(
  AMin, AMax: Double; AxisScale: TAxisScale; out AStart, AStep: Double);
var
  extent, extentTmp, stepCount, scale, maxStepCount, m: Double;
  i: Integer;
const
  GOOD_STEPS: array [1..3] of Double = (0.2, 0.5, 1.0);
  BASE = 10;
begin
  extent := AMax - AMin;
  AStep := 1;
  AStart := AMin;
  if extent <= 0 then exit;

  maxStepCount := 0;
  scale := 1.0;
  for i := Low(GOOD_STEPS) to High(GOOD_STEPS) do begin
    extentTmp := extent / GOOD_STEPS[i];
    m := IntPower(BASE, Round(logn(BASE, extentTmp)));
    while extentTmp * m > BASE do
      m /= BASE;
    while extentTmp * m <= 1 do
      m *= BASE;
    stepCount := extentTmp * m;
    if stepCount > maxStepCount then begin
      maxStepCount := stepCount;
      scale := m;
      AStep := GOOD_STEPS[i] / m;
    end;
  end;
  case AxisScale of
    asIncreasing: begin
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMin - AStep) * scale) / scale;
      while AStart > AMin do AStart -= AStep;
    end;
    asDecreasing: begin
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMax + AStep) * scale) / scale;
      while AStart < AMax do AStart += AStep;
    end;
    asLogIncreasing: begin
      // FIXME: asLogIncreasing is still not implemented.
      // The following is the same code for asIncreasing;
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMin - AStep) * scale) / scale;
      while AStart > AMin do AStart -= AStep;
    end;
    asLogDecreasing: begin
      // FIXME: asLogDecreasing is still not implemented.
      // The following is the same code for asIncreasing;
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMax + AStep) * scale) / scale;
      while AStart < AMax do AStart += AStep;
    end;
  end; {case AxisScale}
end;

function DoubleRect(AX1, AY1, AX2, AY2: Double): TDoubleRect; inline;
begin
  Result.a.X := AX1;
  Result.a.Y := AY1;
  Result.b.X := AX2;
  Result.b.Y := AY2;
end;

procedure DrawLineDepth(ACanvas: TCanvas; AX1, AY1, AX2, AY2, ADepth: Integer);
begin
  DrawLineDepth(ACanvas, Point(AX1, AY1), Point(AX2, AY2), ADepth);
end;

procedure DrawLineDepth(
  ACanvas: TCanvas; const AP1, AP2: TPoint; ADepth: Integer);
var
  d: TSize;
begin
  d := Size(ADepth, -ADepth);
  ACanvas.Polygon([AP1, AP1 + d, AP2 + d, AP2]);
end;

procedure Exchange(var A, B: Integer); overload;
var
  t: Integer;
begin
  t := A;
  A := B;
  B := t;
end;

procedure Exchange(var A, B: Double); overload;
var
  t: Double;
begin
  t := A;
  A := B;
  B := t;
end;

procedure Exchange(var A, B: TDoublePoint);
var
  t: TDoublePoint;
begin
  t := A;
  A := B;
  B := t;
end;

procedure Exchange(var A, B: String); overload;
var
  t: String;
begin
  t := A;
  A := B;
  B := t;
end;

procedure ExpandRange(var ALo, AHi: Double; ACoeff: Double); inline;
var
  d: Double;
begin
  d := AHi - ALo;
  ALo -= d * ACoeff;
  AHi += d * ACoeff;
end;

function GetIntervals(AMin, AMax: Double; AInverted: Boolean): TDoubleDynArray;
const
  INV_TO_SCALE: array [Boolean] of TAxisScale = (asIncreasing, asDecreasing);
  K = 1e-10;
var
  start, step, m, m1: Double;
  markCount: Integer;
begin
  CalculateIntervals(AMin, AMax, INV_TO_SCALE[AInverted], start, step);
  AMin -= step * K;
  AMax += step * K;
  if AInverted then
    step := - step;
  m := start;
  markCount := 0;
  while true do begin
    if InRange(m, AMin, AMax) then
      Inc(markCount)
    else if markCount > 0 then
      break;
    m1 := m + step;
    if m1 = m then break;
    m := m1;
  end;
  SetLength(Result, markCount);
  m := start;
  markCount := 0;
  while true do begin
    if Abs(m / step) < K then
      m := 0;
    if InRange(m, AMin, AMax) then begin
      Result[markCount] := m;
      Inc(markCount);
    end
    else if markCount > 0 then
      break;
    m1 := m + step;
    if m1 = m then break;
    m := m1;
  end;
end;

function LineIntersectsRect(
  var AA, AB: TDoublePoint; const ARect: TDoubleRect): Boolean;
var
  dx, dy: Double;

  procedure AdjustX(var AP: TDoublePoint; ANewX: Double); inline;
  begin
    AP.Y += dy / dx * (ANewX - AP.X);
    AP.X := ANewX;
  end;

  procedure AdjustY(var AP: TDoublePoint; ANewY: Double); inline;
  begin
    AP.X += dx / dy * (ANewY - AP.Y);
    AP.Y := ANewY;
  end;

begin
  dx := AB.X - AA.X;
  dy := AB.Y - AA.Y;
  case CASE_OF_TWO[AA.X < ARect.a.X, AB.X < ARect.a.X] of
    cotFirst: AdjustX(AA, ARect.a.X);
    cotSecond: AdjustX(AB, ARect.a.X);
    cotBoth: exit(false);
  end;
  case CASE_OF_TWO[AA.X > ARect.b.X, AB.X > ARect.b.X] of
    cotFirst: AdjustX(AA, ARect.b.X);
    cotSecond: AdjustX(AB, ARect.b.X);
    cotBoth: exit(false);
  end;
  case CASE_OF_TWO[AA.Y < ARect.a.Y, AB.Y < ARect.a.Y] of
    cotFirst: AdjustY(AA, ARect.a.Y);
    cotSecond: AdjustY(AB, ARect.a.Y);
    cotBoth: exit(false);
  end;
  case CASE_OF_TWO[AA.Y > ARect.b.Y, AB.Y > ARect.b.Y] of
    cotFirst: AdjustY(AA, ARect.b.Y);
    cotSecond: AdjustY(AB, ARect.b.Y);
    cotBoth: exit(false);
  end;
  Result := true;
end;

procedure NormalizeRect(var ARect: TRect);
begin
  with ARect do begin
    if Left > Right then
      Exchange(Left, Right);
    if Top > Bottom then
      Exchange(Top, Bottom);
  end;
end;

function PointDist(const A, B: TPoint): Integer;
begin
  Result := Sqr(A.X - B.X) + Sqr(A.Y - B.Y);
end;

function PointDistX(const A, B: TPoint): Integer;
begin
  Result := Abs(A.X - B.X);
end;

function PointDistY(const A, B: TPoint): Integer; inline;
begin
  Result := Abs(A.Y - B.Y);
end;

procedure PrepareSimplePen(ACanvas: TCanvas; AColor: TColor);
begin
  with ACanvas.Pen do begin
    Color := AColor;
    Style := psSolid;
    Mode := pmCopy;
    Width := 1;
  end;
end;

procedure PrepareXorPen(ACanvas: TCanvas);
begin
  with ACanvas do begin
    Brush.Style := bsClear;
    Pen.Style := psSolid;
    Pen.Mode := pmXor;
    Pen.Color := clWhite;
    Pen.Width := 1;
  end;
end;

{$HINTS OFF}

function RectIntersectsRect(
  var ARect: TDoubleRect; const AFixed: TDoubleRect): Boolean;

  function RangesIntersect(L1, R1, L2, R2: Double; out L, R: Double): Boolean;
  begin
    if L1 > R1 then Exchange(L1, R1);
    if L2 > R2 then Exchange(L2, R2);
    L := Max(L1, L2);
    R := Min(R1, R2);
    Result := L <= R;
  end;

begin
  with ARect do
    Result :=
      RangesIntersect(a.X, b.X, AFixed.a.X, AFixed.b.X, a.X, b.X) and
      RangesIntersect(a.Y, b.Y, AFixed.a.Y, AFixed.b.Y, a.Y, b.Y);
end;

function RoundChecked(A: Double): Integer;
begin
  Result := Round(EnsureRange(A, -MaxInt, MaxInt));
end;

function TypicalTextHeight(ACanvas: TCanvas): Integer;
const
  TYPICAL_TEXT = 'Iy';
begin
  Result := ACanvas.TextHeight(TYPICAL_TEXT);
end;

procedure Unused(const A1);
begin
end;

procedure Unused(const A1, A2);
begin
end;
{$HINTS ON}

procedure UpdateMinMax(AValue: Double; var AMin, AMax: Double);
begin
  if AValue < AMin then
    AMin := AValue;
  if AValue > AMax then
    AMax := AValue;
end;

operator + (const A: TPoint; B: TSize): TPoint;
begin
  Result.X := A.X + B.cx;
  Result.Y := A.Y + B.cy;
end;

operator + (const A, B: TPoint): TPoint;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

operator + (const A, B: TDoublePoint): TDoublePoint;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

operator - (const A, B: TPoint): TPoint;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

operator - (const A, B: TDoublePoint): TDoublePoint; overload; inline;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

operator = (const A, B: TMethod): Boolean;
begin
  Result := (A.Code = B.Code) and (A.Data = B.Data);
end;

{ TPenBrushFontRecall }

constructor TPenBrushFontRecall.Create(ACanvas: TCanvas; AParams: TPenBrushFont);
begin
  inherited Create;
  FCanvas := ACanvas;
  if pbfPen in AParams then begin
    FPen := TPen.Create;
    FPen.Assign(FCanvas.Pen);
  end;
  if pbfBrush in AParams then begin
    FBrush := TBrush.Create;
    FBrush.Assign(FCanvas.Brush);
  end;
  if pbfFont in AParams then begin
    FFont := TFont.Create;
    FFont.Assign(FCanvas.Font);
  end;
end;

destructor TPenBrushFontRecall.Destroy;
begin
  Recall;
  inherited;
end;

procedure TPenBrushFontRecall.Recall;
begin
  if FPen <> nil then begin
    FCanvas.Pen.Assign(FPen);
    FreeAndNil(FPen);
  end;
  if FBrush <> nil then begin
    FCanvas.Brush.Assign(FBrush);
    FreeAndNil(FBrush);
  end;
  if FFont <> nil then begin
    FCanvas.Font.Assign(FFont);
    FreeAndNil(FFont);
  end;
end;

{ TIntervalList }

procedure TIntervalList.AddPoint(APoint: Double); inline;
begin
  AddRange(APoint, APoint);
end;

procedure TIntervalList.AddRange(AStart, AEnd: Double);
var
  i: Integer;
  j: Integer;
  k: Integer;
begin
  i := 0;
  while (i <= High(FIntervals)) and (FIntervals[i].FEnd < AStart) do
    Inc(i);
  if i <= High(FIntervals) then
    AStart := Min(AStart, FIntervals[i].FStart);
  j := High(FIntervals);
  while (j >= 0) and (FIntervals[j].FStart > FIntervals[j].FEnd) do
    Dec(j);
  if j >= 0 then
    AEnd := Max(AEnd, FIntervals[j].FEnd);
  if i < j then begin
    for k := j + 1 to High(FIntervals) do
      FIntervals[i + k - j] := FIntervals[j];
    SetLength(FIntervals, Length(FIntervals) - j + i);
  end
  else if i > j then begin
    SetLength(FIntervals, Length(FIntervals) + 1);
    for k := High(FIntervals) downto i do
      FIntervals[k] := FIntervals[k - 1];
  end;
  FIntervals[i].FStart := AStart;
  FIntervals[i].FEnd := AEnd;
  Changed;
end;

procedure TIntervalList.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TIntervalList.Clear;
begin
  FIntervals := nil;
  Changed;
end;

constructor TIntervalList.Create;
const
  DEFAULT_EPSILON = 1e-6;
begin
  FEpsilon := DEFAULT_EPSILON;
end;

function TIntervalList.GetInterval(AIndex: Integer): TDoubleInterval;
begin
  Result := FIntervals[AIndex];
end;

function TIntervalList.GetIntervalCount: Integer;
begin
  Result := Length(FIntervals);
end;

function TIntervalList.Intersect(
  var ALeft, ARight: Double; var AHint: Integer): Boolean;
var
  fi, li: Integer;
begin
  Result := false;
  if Length(FIntervals) = 0 then exit;

  AHint := Min(High(FIntervals), AHint);
  while (AHint > 0) and (FIntervals[AHint].FStart > ARight) do
    Dec(AHint);

  while
    (AHint <= High(FIntervals)) and (FIntervals[AHint].FStart <= ARight)
  do begin
    if FIntervals[AHint].FEnd >= ALeft then begin
      if not Result then fi := AHint;
      li := AHint;
      Result := true;
    end;
    Inc(AHint);
  end;

  if Result then begin
    ALeft := FIntervals[fi].FStart - Epsilon;
    ARight := FIntervals[li].FEnd + Epsilon;
  end;
end;

procedure TIntervalList.SetEpsilon(AValue: Double);
begin
  if FEpsilon = AValue then exit;
  if AValue <= 0 then
    raise EChartIntervalError.Create('Epsilon <= 0');
  FEpsilon := AValue;
  Changed;
end;

procedure TIntervalList.SetOnChange(AValue: TNotifyEvent);
begin
  if TMethod(FOnChange) = TMethod(AValue) then exit;
  FOnChange := AValue;
end;

{ TListener }

constructor TListener.Create(ARef: PPointer; AOnNotify: TNotifyEvent);
begin
  FOnNotify := AOnNotify;
  FRef := Aref;
end;

destructor TListener.Destroy;
begin
  if IsListening then
    FBroadcaster.Unsubscribe(Self);
  inherited;
end;

procedure TListener.Forget;
begin
  FBroadcaster := nil;
  FRef^ := nil;
end;

function TListener.GetIsListening: Boolean;
begin
  Result := FBroadcaster <> nil;
end;

procedure TListener.Notify(ASender: TObject);
begin
  FOnNotify(ASender)
end;

{ TBroadcaster }

procedure TBroadcaster.Broadcast;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    TListener(Items[i]).Notify(nil);
end;

destructor TBroadcaster.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    TListener(Items[i]).Forget;
  inherited;
end;

procedure TBroadcaster.Subscribe(AListener: TListener);
begin
  if AListener.IsListening then
    raise EListenerError.Create('Listener subscribed twice');
  if IndexOf(AListener) >= 0 then
    raise EListenerError.Create('Duplicate listener');
  AListener.FBroadcaster := Self;
  Add(AListener);
end;

procedure TBroadcaster.Unsubscribe(AListener: TListener);
var
  i: Integer;
begin
  if not AListener.IsListening then
    raise EListenerError.Create('Listener not subscribed');
  AListener.Forget;
  i := IndexOf(AListener);
  if i < 0 then
    raise EListenerError.Create('Listener not found');
  Delete(i);
end;

end.
