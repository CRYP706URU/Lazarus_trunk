{
 /***************************************************************************
                projectdefs.pas  -  project definitions file
                --------------------------------------------


 ***************************************************************************/

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

}
unit ProjectDefs;

{$mode objfpc}{$H+}

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

interface

uses
  Classes, SysUtils, Laz_XMLCfg, IDEProcs, SynRegExpr, FileCtrl, PublishModule;

type
  TOnLoadSaveFilename = procedure(var Filename:string; Load:boolean) of object;

  TProjectWriteFlag = (
    pwfDontSaveClosedUnits,
    pwfSaveOnlyProjectUnits
    );
  TProjectWriteFlags = set of TProjectWriteFlag;

  TNewUnitType = (
     nuEmpty,   // no code
     nuUnit,    // unit
     nuForm,    // unit with form
     nuText,
     nuCustomProgram  // program
   );

  TUnitUsage = (uuIsPartOfProject, uuIsLoaded, uuIsModified, uuNotUsed);


  //---------------------------------------------------------------------------
  // bookmarks of a single file
  TFileBookmark = class
  private
    fCursorPos: TPoint;
    fID: integer;
  public
    constructor Create;
    constructor Create(NewX,NewY,AnID: integer);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    function X: integer;
    function Y: integer;
  public
    property CursorPos: TPoint read fCursorPos write fCursorPos;
    property ID: integer read fID write fID;
  end;
  
  TFileBookmarks = class
  private
    FBookmarks:TList;  // list of TFileBookmark
    function GetBookmarks(Index:integer):TFileBookmark;
    procedure SetBookmarks(Index:integer; ABookmark: TFileBookmark);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index:integer]:TFileBookmark
       read GetBookmarks write SetBookmarks; default;
    function Count:integer;
    procedure Delete(Index:integer);
    procedure Clear;
    function Add(ABookmark: TFileBookmark):integer;
    function Add(X,Y,ID: integer):integer;
    function IndexOfID(ID:integer):integer;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
  end;
  
  //---------------------------------------------------------------------------
  // The currently visible bookmarks of the project
  TProjectBookmark = class
  private
    fCursorPos: TPoint;
    fEditorIndex: integer;
    fID: integer;
  public
    constructor Create;
    constructor Create(X,Y, AnEditorIndex, AnID: integer);
    property CursorPos: TPoint read fCursorPos write fCursorPos;
    property EditorIndex: integer read fEditorIndex write fEditorIndex;
    property ID:integer read fID write fID;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
  end;

  TProjectBookmarkList = class
  private
    FBookmarks:TList;  // list of TProjectBookmark
    function GetBookmarks(Index:integer):TProjectBookmark;
    procedure SetBookmarks(Index:integer;  ABookmark: TProjectBookmark);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index:integer]:TProjectBookmark
       read GetBookmarks write SetBookmarks; default;
    function Count:integer;
    procedure Delete(Index:integer);
    procedure Clear;
    function Add(ABookmark: TProjectBookmark):integer;
    function Add(X,Y,EditorID,ID: integer):integer;
    procedure DeleteAllWithEditorIndex(EditorIndex:integer);
    function IndexOfID(ID:integer):integer;
    function BookmarkWithIndex(ID: integer): TProjectBookmark;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
  end;

//-----------------------------------------------------------------------------
type
  TProjectWatchType = (pwtDefault, pwtChar, pwtString, pwtDecimal, pwtHex,
    pwtFloat, pwtPointer, pwtRecord, pwtMemDump);
const
  ProjectWatchTypeNames : array[TProjectWatchType] of string = (
    'Default', 'Character', 'String', 'Decimal', 'Hexadecimal',
    'Float', 'Pointer', 'Record', 'MemDump');

type
  TProjectWatch = class
  private
    fExpression: string;
    fRepeatCount: integer;
    fDigits: integer;
    fEnabled: boolean;
    fAllowFunctionCalls: boolean;
    fTheType: TProjectWatchType;
  public
    constructor Create;
    procedure Clear;
    destructor Destroy; override; 
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    property Expression: string read fExpression write fExpression;
    property RepeatCount: integer read fRepeatCount write fRepeatCount;
    property Digits: integer read fDigits write fDigits;
    property Enabled: boolean read fEnabled write fEnabled;
    property AllowFunctionCalls: boolean 
          read fAllowFunctionCalls write fAllowFunctionCalls;
    property TheType: TProjectWatchType read fTheType write fTheType;
  end;

//---------------------------------------------------------------------------
type
  TProjectBreakPoint = class
  private
    fActivated: boolean;
    fBreakExecution: boolean;
    fCondition: string;
    fEnableGroup: string;
    fEvalExpression: string;
    fDisableGroup: string;
    fGroup: string;
    fHandleSubsequentExceptions: boolean;
    fIgnoreSubsequentExceptions: boolean;
    fLineNumber: integer;
    fLogMessage: string;
    fLogExpressionResult: boolean;
    fPassCount: integer;
  public
    constructor Create;
    procedure Clear;
    destructor Destroy; override; 
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    property Activated: boolean read fActivated write fActivated;
    property BreakExecution: boolean read fBreakExecution write fBreakExecution;
    property Condition: string read fCondition write fCondition;
    property EnableGroup: string read fEnableGroup write fEnableGroup;
    property EvalExpression: string read fEvalExpression write fEvalExpression;
    property DisableGroup: string read fDisableGroup write fDisableGroup;
    property Group: string read fGroup write fGroup;
    property HandleSubsequentExceptions: boolean
          read fHandleSubsequentExceptions write fHandleSubsequentExceptions;
    property IgnoreSubsequentExceptions: boolean
          read fIgnoreSubsequentExceptions write fIgnoreSubsequentExceptions;
    property LineNumber: integer read fLineNumber write fLineNumber;
    property LogMessage: string read fLogMessage write fLogMessage;
    property LogExpressionResult: boolean 
          read fLogExpressionResult write fLogExpressionResult;
    property PassCount: integer read fPassCount write fPassCount;
  end;

  TProjectBreakPointList = class
  private
    FBreakPoints:TList;  // list of TProjectBreakPoint
    function GetBreakPoints(Index:integer):TProjectBreakPoint;
    procedure SetBreakPoints(Index:integer;  ABreakPoint: TProjectBreakPoint);
  public
    function Add(ABreakPoint: TProjectBreakPoint):integer;
    constructor Create;
    procedure Clear;
    function Count:integer;
    procedure Delete(Index:integer);
    destructor Destroy; override;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    property Items[Index:integer]:TProjectBreakPoint 
       read GetBreakPoints write SetBreakPoints; default;
  end;


  //---------------------------------------------------------------------------

  TProjectJumpHistoryPosition = class
  private
    FCaretXY: TPoint;
    FFilename: string;
    FTopLine: integer;
    fOnLoadSaveFilename: TOnLoadSaveFilename;
  public
    procedure Assign(APosition: TProjectJumpHistoryPosition);
    constructor Create(const AFilename: string; ACaretXY: TPoint; 
      ATopLine: integer);
    constructor Create(APosition: TProjectJumpHistoryPosition);
    function IsEqual(APosition: TProjectJumpHistoryPosition): boolean;
    function IsSimilar(APosition: TProjectJumpHistoryPosition): boolean;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    property CaretXY: TPoint read FCaretXY write FCaretXY;
    property Filename: string read FFilename write FFilename;
    property TopLine: integer read FTopLine write FTopLine;
    property OnLoadSaveFilename: TOnLoadSaveFilename
        read fOnLoadSaveFilename write fOnLoadSaveFilename;
  end;

  TCheckPositionEvent = 
    function(APosition:TProjectJumpHistoryPosition): boolean of object;

  TProjectJumpHistory = class
  private
    FHistoryIndex: integer;
    FOnCheckPosition: TCheckPositionEvent;
    FPositions:TList;  // list of TProjectJumpHistoryPosition
    FMaxCount: integer;
    fOnLoadSaveFilename: TOnLoadSaveFilename;
    function GetPositions(Index:integer):TProjectJumpHistoryPosition;
    procedure SetPositions(Index:integer; APosition: TProjectJumpHistoryPosition);
  public
    function Add(APosition: TProjectJumpHistoryPosition):integer;
    function AddSmart(APosition: TProjectJumpHistoryPosition):integer;
    constructor Create;
    procedure Clear;
    procedure DeleteInvalidPositions;
    function Count:integer;
    procedure Delete(Index:integer);
    procedure DeleteFirst;
    procedure DeleteForwardHistory;
    procedure DeleteLast;
    destructor Destroy; override;
    function IndexOf(APosition: TProjectJumpHistoryPosition): integer;
    function FindIndexOfFilename(const Filename: string; 
      StartIndex: integer): integer;
    procedure Insert(Index: integer; APosition: TProjectJumpHistoryPosition);
    procedure InsertSmart(Index: integer; APosition: TProjectJumpHistoryPosition);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure WriteDebugReport;
    property HistoryIndex: integer read FHistoryIndex write FHistoryIndex;
    property Items[Index:integer]:TProjectJumpHistoryPosition 
       read GetPositions write SetPositions; default;
    property MaxCount: integer read FMaxCount write FMaxCount;
    property OnCheckPosition: TCheckPositionEvent
       read FOnCheckPosition write FOnCheckPosition;
    property OnLoadSaveFilename: TOnLoadSaveFilename
        read fOnLoadSaveFilename write fOnLoadSaveFilename;
  end;

  //---------------------------------------------------------------------------

  { TPublishProjectOptions }
  
  TPublishProjectOptions = class(TPublishModuleOptions)
  private
    FSaveClosedEditorFilesInfo: boolean;
    FSaveEditorInfoOfNonProjectFiles: boolean;
    procedure SetSaveClosedEditorFilesInfo(const AValue: boolean);
    procedure SetSaveEditorInfoOfNonProjectFiles(const AValue: boolean);
  public
    procedure LoadDefaults; override;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const APath: string); override;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const APath: string); override;
    function WriteFlags: TProjectWriteFlags;
  public
    // project info
    property SaveEditorInfoOfNonProjectFiles: boolean
                read FSaveEditorInfoOfNonProjectFiles
                write SetSaveEditorInfoOfNonProjectFiles;
    property SaveClosedEditorFilesInfo: boolean
                read FSaveClosedEditorFilesInfo
                write SetSaveClosedEditorFilesInfo;
  end;


  //---------------------------------------------------------------------------

const
  DefPublProjIncFilter = '*.(pas|pp|inc|lfm|lpr|lrs|lpi|lpk|sh|xml)';
  DefPublProjExcFilter = '*.(bak|ppu|ppw|o|so);*~;backup';

function ProjectWatchTypeNameToType(const s: string): TProjectWatchType;


implementation


function ProjectWatchTypeNameToType(const s: string): TProjectWatchType;
begin
  for Result:=Low(TProjectWatchType) to High(TProjectWatchType) do
    if lowercase(s)=lowercase(ProjectWatchTypeNames[Result]) then exit;
  Result:=pwtDefault;
end;




{ TProjectBookmark }

constructor TProjectBookmark.Create;
begin
  inherited Create;
end;

constructor TProjectBookmark.Create(X,Y, AnEditorIndex, AnID: integer);
begin
  inherited Create;
  fCursorPos.X:=X;
  fCursorPos.Y:=Y;
  fEditorIndex:=AnEditorIndex;
  fID:=AnID;
end;

procedure TProjectBookmark.SaveToXMLConfig(XMLConfig: TXMLConfig; 
  const Path: string);
begin
  XMLConfig.SetValue(Path+'ID',ID);
  XMLConfig.SetValue(Path+'CursorPosX',CursorPos.X);
  XMLConfig.SetValue(Path+'CursorPosY',CursorPos.Y);
  XMLConfig.SetValue(Path+'EditorIndex',EditorIndex);
end;

procedure TProjectBookmark.LoadFromXMLConfig(XMLConfig: TXMLConfig; 
  const Path: string);
begin
  ID:=XMLConfig.GetValue(Path+'ID',-1);
  CursorPos.X:=XMLConfig.GetValue(Path+'CursorPosX',0);
  CursorPos.Y:=XMLConfig.GetValue(Path+'CursorPosY',0);
  EditorIndex:=XMLConfig.GetValue(Path+'EditorIndex',-1);
end;


{ TProjectBookmarkList }

constructor TProjectBookmarkList.Create;
begin
  inherited Create;
  fBookmarks:=TList.Create;
end;

destructor TProjectBookmarkList.Destroy;
begin
  Clear;
  fBookmarks.Free;
  inherited Destroy;
end;

procedure TProjectBookmarkList.Clear;
var a:integer;
begin
  for a:=0 to fBookmarks.Count-1 do Items[a].Free;
  fBookmarks.Clear;
end;

function TProjectBookmarkList.Count:integer;
begin
  Result:=fBookmarks.Count;
end;

function TProjectBookmarkList.GetBookmarks(Index:integer):TProjectBookmark;
begin
  Result:=TProjectBookmark(fBookmarks[Index]);
end;

procedure TProjectBookmarkList.SetBookmarks(Index:integer;  
  ABookmark: TProjectBookmark);
begin
  fBookmarks[Index]:=ABookmark;
end;

function TProjectBookmarkList.IndexOfID(ID:integer):integer;
begin
  Result:=Count-1;
  while (Result>=0) and (Items[Result].ID<>ID) do dec(Result);
end;

function TProjectBookmarkList.BookmarkWithIndex(ID: integer
  ): TProjectBookmark;
var
  i: Integer;
begin
  i:=IndexOfID(ID);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

procedure TProjectBookmarkList.Delete(Index:integer);
begin
  Items[Index].Free;
  fBookmarks.Delete(Index);
end;

procedure TProjectBookmarkList.DeleteAllWithEditorIndex(
  EditorIndex:integer);
var i:integer;
begin
  i:=Count-1;
  while (i>=0) do begin
    if Items[i].EditorIndex=EditorIndex then Delete(i);
    dec(i);
  end;
end;

function TProjectBookmarkList.Add(ABookmark: TProjectBookmark):integer;
var
  i: Integer;
begin
  i:=IndexOfID(ABookmark.ID);
  if i>=0 then Delete(i);
  Result:=fBookmarks.Add(ABookmark);
end;

function TProjectBookmarkList.Add(X, Y, EditorID, ID: integer): integer;
begin
  Result:=Add(TProjectBookmark.Create(X,Y,EditorID,ID));
end;

procedure TProjectBookmarkList.SaveToXMLConfig(XMLConfig: TXMLConfig; 
  const Path: string);
var a:integer;
begin
  XMLConfig.SetDeleteValue(Path+'Bookmarks/Count',Count,0);
  for a:=0 to Count-1 do
    Items[a].SaveToXMLConfig(XMLConfig,Path+'Bookmarks/Mark'+IntToStr(a)+'/');
end;

procedure TProjectBookmarkList.LoadFromXMLConfig(XMLConfig: TXMLConfig; 
  const Path: string);
var a,NewCount:integer;
  NewBookmark:TProjectBookmark;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'Bookmarks/Count',0);
  for a:=0 to NewCount-1 do begin
    NewBookmark:=TProjectBookmark.Create;
    Add(NewBookmark);
    NewBookmark.LoadFromXMLConfig(XMLConfig,Path+'Bookmarks/Mark'+IntToStr(a)+'/');
  end;
end;

{ TProjectWatch }

constructor TProjectWatch.Create;
begin
  inherited Create;
  Clear;
end;

procedure TProjectWatch.Clear;
begin
  fExpression:='';
  fRepeatCount:=0;
  fDigits:=4;
  fEnabled:=true;
  fAllowFunctionCalls:=true;
  fTheType:=pwtDefault;
end;

destructor TProjectWatch.Destroy;
begin
  inherited Destroy;
end;

procedure TProjectWatch.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  Clear;
  fExpression:=XMLConfig.GetValue(Path+'Expression',fExpression);
  fRepeatCount:=XMLConfig.GetValue(Path+'RepeatCount',fRepeatCount);
  fDigits:=XMLConfig.GetValue(Path+'Digits',fDigits);
  fEnabled:=XMLConfig.GetValue(Path+'Enabled',fEnabled);
  fAllowFunctionCalls:=XMLConfig.GetValue(Path+'AllowFunctionCalls',
    fAllowFunctionCalls);
  fTheType:=ProjectWatchTypeNameToType(XMLConfig.GetValue(Path+'TheType',''));
end;

procedure TProjectWatch.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfig.SetValue(Path+'Expression',fExpression);
  XMLConfig.SetValue(Path+'RepeatCount',fRepeatCount);
  XMLConfig.SetValue(Path+'Digits',fDigits);
  XMLConfig.SetValue(Path+'Enabled',fEnabled);
  XMLConfig.SetValue(Path+'AllowFunctionCalls',fAllowFunctionCalls);
  XMLConfig.SetValue(Path+'TheType',ProjectWatchTypeNames[fTheType]);
end;


{ TProjectBreakPoint }

constructor TProjectBreakPoint.Create;
begin
  inherited Create;
  Clear;
end;

destructor TProjectBreakPoint.Destroy;
begin
  inherited Destroy;
end;

procedure TProjectBreakPoint.Clear;
begin
  fActivated:=true;
  fBreakExecution:=true;
  fCondition:='';
  fEnableGroup:='';
  fEvalExpression:='';
  fDisableGroup:='';
  fGroup:='';
  fHandleSubsequentExceptions:=false;
  fIgnoreSubsequentExceptions:=false;
  fLineNumber:=-1;
  fLogMessage:='';
  fLogExpressionResult:=true;
  fPassCount:=0;
end;

procedure TProjectBreakPoint.SaveToXMLConfig(XMLConfig: TXMLConfig; 
  const Path: string);
begin
  XMLConfig.SetValue(Path+'LineNumber',LineNumber);
  XMLConfig.SetValue(Path+'Activated',Activated);
  XMLConfig.SetValue(Path+'BreakExecution',BreakExecution);
  XMLConfig.SetValue(Path+'Condition',Condition);
  XMLConfig.SetValue(Path+'EnableGroup',EnableGroup);
  XMLConfig.SetValue(Path+'EvalExpression',EvalExpression);
  XMLConfig.SetValue(Path+'DisableGroup',DisableGroup);
  XMLConfig.SetValue(Path+'Group',Group);
  XMLConfig.SetValue(Path+'HandleSubsequentExceptions',HandleSubsequentExceptions);
  XMLConfig.SetValue(Path+'IgnoreSubsequentExceptions',IgnoreSubsequentExceptions);
  XMLConfig.SetValue(Path+'LineNumber',LineNumber);
  XMLConfig.SetValue(Path+'LogMessage',LogMessage);
  XMLConfig.SetValue(Path+'LogExpressionResult',LogExpressionResult);
  XMLConfig.SetValue(Path+'PassCount',PassCount);
end;

procedure TProjectBreakPoint.LoadFromXMLConfig(XMLConfig: TXMLConfig; 
  const Path: string);
begin
  Clear;
  LineNumber:=XMLConfig.GetValue(Path+'LineNumber',LineNumber);
  Activated:=XMLConfig.GetValue(Path+'Activated',Activated);
  BreakExecution:=XMLConfig.GetValue(Path+'BreakExecution',BreakExecution);
  Condition:=XMLConfig.GetValue(Path+'Condition',Condition);
  EnableGroup:=XMLConfig.GetValue(Path+'EnableGroup',EnableGroup);
  EvalExpression:=XMLConfig.GetValue(Path+'EvalExpression',EvalExpression);
  DisableGroup:=XMLConfig.GetValue(Path+'DisableGroup',DisableGroup);
  Group:=XMLConfig.GetValue(Path+'Group',Group);
  HandleSubsequentExceptions:=XMLConfig.GetValue(
            Path+'HandleSubsequentExceptions',HandleSubsequentExceptions);
  IgnoreSubsequentExceptions:=XMLConfig.GetValue(
            Path+'IgnoreSubsequentExceptions',IgnoreSubsequentExceptions);
  LineNumber:=XMLConfig.GetValue(Path+'LineNumber',LineNumber);
  LogMessage:=XMLConfig.GetValue(Path+'LogMessage',LogMessage);
  LogExpressionResult:=XMLConfig.GetValue(Path+'LogExpressionResult',
            LogExpressionResult);
  PassCount:=XMLConfig.GetValue(Path+'PassCount',PassCount);
end;


{ TProjectBreakPointList }

constructor TProjectBreakPointList.Create;
begin
  inherited Create;
  fBreakPoints:=TList.Create;
end;

destructor TProjectBreakPointList.Destroy;
begin
  Clear;
  fBreakPoints.Free;
  inherited Destroy;
end;

procedure TProjectBreakPointList.Clear;
var a:integer;
begin
  for a:=0 to fBreakPoints.Count-1 do Items[a].Free;
  fBreakPoints.Clear;
end;

function TProjectBreakPointList.Count:integer;
begin
  Result:=fBreakPoints.Count;
end;

function TProjectBreakPointList.GetBreakPoints(Index:integer):TProjectBreakPoint;
begin
  Result:=TProjectBreakPoint(fBreakPoints[Index]);
end;

procedure TProjectBreakPointList.SetBreakPoints(Index:integer;
  ABreakPoint: TProjectBreakPoint);
begin
  fBreakPoints[Index]:=ABreakPoint;
end;

procedure TProjectBreakPointList.Delete(Index:integer);
begin
  Items[Index].Free;
  fBreakPoints.Delete(Index);
end;

function TProjectBreakPointList.Add(ABreakPoint: TProjectBreakPoint):integer;
begin
  Result:=fBreakPoints.Add(ABreakPoint);
end;

procedure TProjectBreakPointList.SaveToXMLConfig(XMLConfig: TXMLConfig; 
  const Path: string);
var a:integer;
begin
  XMLConfig.SetDeleteValue(Path+'BreakPoints/Count',Count,0);
  for a:=0 to Count-1 do
    Items[a].SaveToXMLConfig(XMLConfig,Path+'BreakPoints/Point'+IntToStr(a)+'/');
end;

procedure TProjectBreakPointList.LoadFromXMLConfig(XMLConfig: TXMLConfig; 
  const Path: string);
var a,NewCount:integer;
  NewBreakPoint:TProjectBreakPoint;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'BreakPoints/Count',0);
  for a:=0 to NewCount-1 do begin
    NewBreakPoint:=TProjectBreakPoint.Create;
    Add(NewBreakPoint);
    NewBreakPoint.LoadFromXMLConfig(XMLConfig
      ,Path+'BreakPoints/Point'+IntToStr(a)+'/');
  end;
end;


{ TProjectJumpHistoryPosition }

constructor TProjectJumpHistoryPosition.Create(const AFilename: string;
  ACaretXY: TPoint; ATopLine: integer);
begin
  inherited Create;
  FCaretXY:=ACaretXY;
  FFilename:=AFilename;
  FTopLine:=ATopLine;
end;

constructor TProjectJumpHistoryPosition.Create(
  APosition: TProjectJumpHistoryPosition);
begin
  inherited Create;
  Assign(APosition);
end;

procedure TProjectJumpHistoryPosition.Assign(
  APosition: TProjectJumpHistoryPosition);
begin
  FCaretXY:=APosition.CaretXY;
  FFilename:=APosition.Filename;
  FTopLine:=APosition.TopLine;
end;

function TProjectJumpHistoryPosition.IsEqual(
  APosition: TProjectJumpHistoryPosition): boolean;
begin
  Result:=(Filename=APosition.Filename)
      and (CaretXY.X=APosition.CaretXY.X) and (CaretXY.Y=APosition.CaretXY.Y)
      and (TopLine=APosition.TopLine);
end;

function TProjectJumpHistoryPosition.IsSimilar(
  APosition: TProjectJumpHistoryPosition): boolean;
begin
  Result:=(Filename=APosition.Filename)
      and (CaretXY.Y=APosition.CaretXY.Y);
end;

procedure TProjectJumpHistoryPosition.LoadFromXMLConfig(
  XMLConfig: TXMLConfig; const Path: string);
var AFilename: string;
begin
  FCaretXY.Y:=XMLConfig.GetValue(Path+'Caret/Line',0);
  FCaretXY.X:=XMLConfig.GetValue(Path+'Caret/Column',0);
  FTopLine:=XMLConfig.GetValue(Path+'Caret/TopLine',0);
  AFilename:=XMLConfig.GetValue(Path+'Filename/Value','');
  if Assigned(fOnLoadSaveFilename) then
    fOnLoadSaveFilename(AFilename,true);
  fFilename:=AFilename;
end;

procedure TProjectJumpHistoryPosition.SaveToXMLConfig(
  XMLConfig: TXMLConfig; const Path: string);
var AFilename: string;
begin
  AFilename:=Filename;
  if Assigned(fOnLoadSaveFilename) then
    fOnLoadSaveFilename(AFilename,false);
  XMLConfig.SetValue(Path+'Filename/Value',AFilename);
  XMLConfig.SetValue(Path+'Caret/Line',FCaretXY.Y);
  XMLConfig.SetValue(Path+'Caret/Column',FCaretXY.X);
  XMLConfig.SetValue(Path+'Caret/TopLine',FTopLine);
end;

{ TProjectJumpHistory }

function TProjectJumpHistory.GetPositions(
  Index:integer):TProjectJumpHistoryPosition;
begin
  if (Index<0) or (Index>=Count) then
    raise Exception.Create('TProjectJumpHistory.GetPositions: Index '
      +IntToStr(Index)+' out of bounds. Count='+IntToStr(Count));
  Result:=TProjectJumpHistoryPosition(FPositions[Index]);
end;

procedure TProjectJumpHistory.SetPositions(Index:integer;
  APosition: TProjectJumpHistoryPosition);
begin
  if (Index<0) or (Index>=Count) then
    raise Exception.Create('TProjectJumpHistory.SetPositions: Index '
      +IntToStr(Index)+' out of bounds. Count='+IntToStr(Count));
  Items[Index].Assign(APosition);
end;

function TProjectJumpHistory.Add(
  APosition: TProjectJumpHistoryPosition):integer;
begin
  Result:=FPositions.Add(APosition);
  APosition.OnLoadSaveFilename:=OnLoadSaveFilename;
  FHistoryIndex:=Count-1;
  if Count>MaxCount then DeleteFirst;
end;

function TProjectJumpHistory.AddSmart(
  APosition: TProjectJumpHistoryPosition):integer;
// add, if last Item is not equal to APosition
begin
  if (Count=0) or (not Items[Count-1].IsEqual(APosition)) then
    Result:=Add(APosition)
  else begin
    APosition.Free;
    Result:=-1;
  end;
end;

constructor TProjectJumpHistory.Create;
begin
  inherited Create;
  FPositions:=TList.Create;
  FHistoryIndex:=-1;
  FMaxCount:=30;
end;

procedure TProjectJumpHistory.Clear;
var i: integer;
begin
  for i:=0 to Count-1 do
    Items[i].Free;
  FPositions.Clear;
  FHistoryIndex:=-1;
end;

function TProjectJumpHistory.Count:integer;
begin
  Result:=FPositions.Count;
end;

procedure TProjectJumpHistory.Delete(Index:integer);
begin
  Items[Index].Free;
  FPositions.Delete(Index);
  if FHistoryIndex>=Index then dec(FHistoryIndex);
end;

destructor TProjectJumpHistory.Destroy;
begin
  Clear;
  FPositions.Free;
  inherited Destroy;
end;

function TProjectJumpHistory.IndexOf(APosition: TProjectJumpHistoryPosition
  ): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (not APosition.IsEqual(Items[Result])) do
    dec(Result);
end;

procedure TProjectJumpHistory.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var i, NewCount, NewHistoryIndex: integer;
  NewPosition: TProjectJumpHistoryPosition;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'JumpHistory/Count',0);
  NewHistoryIndex:=XMLConfig.GetValue(Path+'JumpHistory/HistoryIndex',-1);
  NewPosition:=nil;
  for i:=0 to NewCount-1 do begin
    if NewPosition=nil then
      NewPosition:=TProjectJumpHistoryPosition.Create('',Point(0,0),0);
    NewPosition.LoadFromXMLConfig(XMLConfig,
                                 Path+'JumpHistory/Position'+IntToStr(i+1)+'/');
    if (NewPosition.Filename<>'') and (NewPosition.CaretXY.Y>0)
    and (NewPosition.CaretXY.X>0) and (NewPosition.TopLine>0)
    and (NewPosition.TopLine<=NewPosition.CaretXY.Y) then begin
      Add(NewPosition);
      NewPosition:=nil;
    end else if NewHistoryIndex>=i then
      dec(NewHistoryIndex);
  end;
  if NewPosition<>nil then NewPosition.Free;
  if (NewHistoryIndex<0) or (NewHistoryIndex>=Count) then 
    NewHistoryIndex:=Count-1;
  FHistoryIndex:=NewHistoryIndex;
end;

procedure TProjectJumpHistory.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var i: integer;
begin
  XMLConfig.SetValue(Path+'JumpHistory/Count',Count);
  XMLConfig.SetValue(Path+'JumpHistory/HistoryIndex',HistoryIndex);
  for i:=0 to Count-1 do begin
    Items[i].SaveToXMLConfig(XMLConfig,
                             Path+'JumpHistory/Position'+IntToStr(i+1)+'/');
  end;
end;

function TProjectJumpHistory.FindIndexOfFilename(const Filename: string; 
  StartIndex: integer): integer;
begin
  Result:=StartIndex;
  while (Result<Count) do begin
    if (CompareFilenames(Filename,Items[Result].Filename)=0) then exit;
    inc(Result);
  end;
  Result:=-1;
end;

procedure TProjectJumpHistory.DeleteInvalidPositions;
var i: integer;
begin
  i:=Count-1;
  while (i>=0) do begin
    if (Items[i].Filename='') or (Items[i].CaretXY.Y<1)
    or (Items[i].CaretXY.X<1)
    or (Assigned(FOnCheckPosition) and (not FOnCheckPosition(Items[i]))) then
    begin
      Delete(i);
    end;
    dec(i);
  end;
end;

procedure TProjectJumpHistory.DeleteLast;
begin
  if Count=0 then exit;
  Delete(Count-1);
end;

procedure TProjectJumpHistory.DeleteFirst;
begin
  if Count=0 then exit;
  Delete(0);
end;

procedure TProjectJumpHistory.Insert(Index: integer;
  APosition: TProjectJumpHistoryPosition);
begin
  APosition.OnLoadSaveFilename:=OnLoadSaveFilename;
  if Count=MaxCount then begin
    if Index>0 then begin
      DeleteFirst;
      dec(Index);
    end else
      DeleteLast;
  end;
  if Index<0 then Index:=0;
  if Index>Count then Index:=Count;
  FPositions.Insert(Index,APosition);
  if (FHistoryIndex<0) and (Count=1) then
    FHistoryIndex:=0
  else if FHistoryIndex>=Index then
    inc(FHistoryIndex);
end;

procedure TProjectJumpHistory.InsertSmart(Index: integer;
  APosition: TProjectJumpHistoryPosition);
// insert if item after or in front of Index is not similar to APosition
// else replace the similar with the new updated version
var
  NewIndex: integer;
begin
  if Index<0 then Index:=Count;
  if (Index<=Count) then begin
    if (Index>0) and Items[Index-1].IsSimilar(APosition) then begin
      //writeln('TProjectJumpHistory.InsertSmart Replacing prev: Index=',Index,
      //  ' Old=',Items[Index-1].CaretXY.X,',',Items[Index-1].CaretXY.Y,' ',Items[Index-1].Filename,
      //  ' New=',APosition.CaretXY.X,',',APosition.CaretXY.Y,' ',APosition.Filename,
      //  ' ');
      Items[Index-1]:=APosition;
      NewIndex:=Index-1;
      APosition.Free;
    end else if (Index<Count) and Items[Index].IsSimilar(APosition) then begin
      //writeln('TProjectJumpHistory.InsertSmart Replacing next: Index=',Index,
      //  ' Old=',Items[Index].CaretXY.X,',',Items[Index].CaretXY.Y,' ',Items[Index].Filename,
      //  ' New=',APosition.CaretXY.X,',',APosition.CaretXY.Y,' ',APosition.Filename,
      //  ' ');
      Items[Index]:=APosition;
      NewIndex:=Index;
      APosition.Free;
    end else begin
      //writeln('TProjectJumpHistory.InsertSmart Adding: Index=',Index,
      //  ' New=',APosition.CaretXY.X,',',APosition.CaretXY.Y,' ',APosition.Filename,
      //  ' ');
      Insert(Index,APosition);
      NewIndex:=IndexOf(APosition);
    end;
    if (HistoryIndex<0) or (HistoryIndex=NewIndex-1) then
      HistoryIndex:=NewIndex;
    //writeln('  HistoryIndex=',HistoryIndex);
  end else begin
    APosition.Free;
  end;
end;

procedure TProjectJumpHistory.DeleteForwardHistory;
var i, d: integer;
begin
  d:=FHistoryIndex+1;
  if d<0 then d:=0;
  for i:=Count-1 downto d do Delete(i);
end;

procedure TProjectJumpHistory.WriteDebugReport;
var i: integer;
begin
  writeln('[TProjectJumpHistory.WriteDebugReport] Count=',Count
    ,' MaxCount=',MaxCount,' HistoryIndex=',HistoryIndex);
  for i:=0 to Count-1 do begin
    writeln('  ',i,': Line=',Items[i].CaretXY.Y,' Col=',Items[i].CaretXY.X,
      ' "',Items[i].Filename,'"');
  end;
end;

{ TPublishProjectOptions }

procedure TPublishProjectOptions.SetSaveClosedEditorFilesInfo(
  const AValue: boolean);
begin
  if FSaveClosedEditorFilesInfo=AValue then exit;
  FSaveClosedEditorFilesInfo:=AValue;
end;

procedure TPublishProjectOptions.SetSaveEditorInfoOfNonProjectFiles(
  const AValue: boolean);
begin
  if FSaveEditorInfoOfNonProjectFiles=AValue then exit;
  FSaveEditorInfoOfNonProjectFiles:=AValue;
end;

procedure TPublishProjectOptions.LoadDefaults;
begin
  inherited LoadDefaults;
  DestinationDirectory:='$(TestDir)/publishedproject/';
  CommandAfter:='';
  UseIncludeFileFilter:=true;
  IncludeFilterSimpleSyntax:=true;
  IncludeFileFilter:=DefPublProjIncFilter;
  UseExcludeFileFilter:=false;
  ExcludeFilterSimpleSyntax:=true;
  ExcludeFileFilter:=DefPublProjExcFilter;
  SaveClosedEditorFilesInfo:=false;
  SaveEditorInfoOfNonProjectFiles:=false;
end;

procedure TPublishProjectOptions.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const APath: string);
//var
//  XMLVersion: integer;
begin
  inherited LoadFromXMLConfig(XMLConfig,APath);
  //XMLVersion:=XMLConfig.GetValue(APath+'Version/Value',0);
  FSaveClosedEditorFilesInfo:=XMLConfig.GetValue(
             APath+'SaveClosedEditorFilesInfo/Value',SaveClosedEditorFilesInfo);
  FSaveEditorInfoOfNonProjectFiles:=XMLConfig.GetValue(
             APath+'SaveEditorInfoOfNonProjectFiles/Value',
             SaveEditorInfoOfNonProjectFiles);
end;

procedure TPublishProjectOptions.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const APath: string);
begin
  inherited SaveToXMLConfig(XMLConfig,APath);
  XMLConfig.SetDeleteValue(APath+'SaveClosedEditorFilesInfo/Value',
    SaveClosedEditorFilesInfo,false);
  XMLConfig.SetDeleteValue(APath+'SaveEditorInfoOfNonProjectFiles/Value',
    SaveEditorInfoOfNonProjectFiles,false);
end;

function TPublishProjectOptions.WriteFlags: TProjectWriteFlags;
begin
  Result:=[];
  if not SaveEditorInfoOfNonProjectFiles then
    Include(Result,pwfSaveOnlyProjectUnits);
  if not SaveClosedEditorFilesInfo then
    Include(Result,pwfDontSaveClosedUnits);
end;


{ TFileBookmark }

constructor TFileBookmark.Create;
begin

end;

constructor TFileBookmark.Create(NewX, NewY, AnID: integer);
begin
  fCursorPos.X:=NewX;
  fCursorPos.Y:=NewY;
  fID:=AnID;
end;

procedure TFileBookmark.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfig.SetValue(Path+'X',fCursorPos.X);
  XMLConfig.SetValue(Path+'Y',fCursorPos.Y);
  XMLConfig.SetValue(Path+'ID',fID);
end;

procedure TFileBookmark.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  fCursorPos.X:=XMLConfig.GetValue(Path+'X',1);
  fCursorPos.Y:=XMLConfig.GetValue(Path+'Y',1);
  fID:=XMLConfig.GetValue(Path+'ID',0);
end;

function TFileBookmark.X: integer;
begin
  Result:=fCursorPos.X;
end;

function TFileBookmark.Y: integer;
begin
  Result:=fCursorPos.Y;
end;

{ TFileBookmarks }

function TFileBookmarks.GetBookmarks(Index: integer): TFileBookmark;
begin
  Result:=TFileBookmark(FBookmarks[Index]);
end;

procedure TFileBookmarks.SetBookmarks(Index: integer; ABookmark: TFileBookmark
  );
begin
  FBookmarks[Index]:=ABookmark;
end;

constructor TFileBookmarks.Create;
begin
  FBookmarks:=TList.Create;
  Clear;
end;

destructor TFileBookmarks.Destroy;
begin
  Clear;
  FBookmarks.Free;
  inherited Destroy;
end;

function TFileBookmarks.Count: integer;
begin
  Result:=FBookmarks.Count;
end;

procedure TFileBookmarks.Delete(Index: integer);
begin
  Items[Index].Free;
  FBookmarks.Delete(Index);
end;

procedure TFileBookmarks.Clear;
var
  i: Integer;
begin
  for i:=0 to FBookmarks.Count-1 do Items[i].Free;
  FBookmarks.Clear;
end;

function TFileBookmarks.Add(ABookmark: TFileBookmark): integer;
var
  i: Integer;
begin
  i:=IndexOfID(ABookmark.ID);
  if i>=0 then Delete(i);
  Result:=FBookmarks.Add(ABookmark);
end;

function TFileBookmarks.Add(X, Y, ID: integer): integer;
begin
  Result:=Add(TFileBookmark.Create(X,Y,ID));
end;

function TFileBookmarks.IndexOfID(ID: integer): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (Items[Result].ID<>ID) do dec(Result);
end;

procedure TFileBookmarks.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var
  i: Integer;
begin
  XMLConfig.SetDeleteValue(Path+'Count',Count,0);
  for i:=0 to Count-1 do
    Items[i].SaveToXMLConfig(XMLConfig,Path+'Item'+IntToStr(i)+'/');
end;

procedure TFileBookmarks.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var
  NewCount: Integer;
  NewBookmark: TFileBookmark;
  i: Integer;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'Count',0);
  for i:=0 to NewCount-1 do begin
    NewBookmark:=TFileBookmark.Create;
    NewBookmark.LoadFromXMLConfig(XMLConfig,Path+'Item'+IntToStr(i)+'/');
    Add(NewBookmark);
  end;
end;

end.

