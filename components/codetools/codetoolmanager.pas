{
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

  Author: Mattias Gaertner

  Abstract:
    TCodeToolManager gathers all tools in one single Object and makes it easy
    to use the code tools in a program.

}
unit CodeToolManager;

{$ifdef fpc}{$mode objfpc}{$endif}{$H+}

interface

{$I codetools.inc}

{ $DEFINE CTDEBUG}
{ $DEFINE DoNotHandleFindDeclException}

uses
  {$IFDEF MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, FileProcs, BasicCodeTools, CodeToolsStrConsts,
  EventCodeTool, CodeTree, CodeAtom, SourceChanger, DefineTemplates, CodeCache,
  ExprEval, LinkScanner, KeywordFuncLists, TypInfo, AVL_Tree, LFMTrees,
  CustomCodeTool, FindDeclarationTool, IdentCompletionTool, StdCodeTools,
  ResourceCodeTool, CodeToolsStructs, CodeTemplatesTool, ExtractProcTool;

type
  TCodeToolManager = class;
  TCodeTool = TEventsCodeTool;

  TGetStringProc = procedure(const s: string) of object;
  TOnBeforeApplyChanges = procedure(Manager: TCodeToolManager;
                                    var Abort: boolean) of object;
  TOnAfterApplyChanges = procedure(Manager: TCodeToolManager) of object;
  TOnGatherExternalChanges = procedure(Manager: TCodeToolManager;
                                       var Abort: boolean) of object;
  TOnSearchUsedUnit = function(const SrcFilename: string;
                               const TheUnitName, TheUnitInFilename: string
                               ): TCodeBuffer of object;
  TOnCodeToolCheckAbort = function: boolean of object;
  TOnGetDefinePropertiesForClass = procedure(Sender: TObject;
    const ComponentClassName: string; var List: TStrings) of object;

  TCodeToolManager = class
  private
    FAbortable: boolean;
    FAddInheritedCodeToOverrideMethod: boolean;
    FAdjustTopLineDueToComment: boolean;
    FCatchExceptions: boolean;
    FCheckFilesOnDisk: boolean;
    FCompleteProperties: boolean;
    FCurCodeTool: TCodeTool; // current codetool
    FCursorBeyondEOL: boolean;
    FErrorCode: TCodeBuffer;
    FErrorColumn: integer;
    FErrorLine: integer;
    FErrorMsg: string;
    FErrorTopLine: integer;
    FIndentSize: integer;
    FJumpCentered: boolean;
    FOnAfterApplyChanges: TOnAfterApplyChanges;
    FOnBeforeApplyChanges: TOnBeforeApplyChanges;
    FOnCheckAbort: TOnCodeToolCheckAbort;
    FOnGatherExternalChanges: TOnGatherExternalChanges;
    FOnGetDefineProperties: TOnGetDefineProperties;
    FOnGetDefinePropertiesForClass: TOnGetDefinePropertiesForClass;
    FOnSearchUsedUnit: TOnSearchUsedUnit;
    FResourceTool: TResourceCodeTool;
    FSetPropertyVariablename: string;
    FSourceExtensions: string; // default is '.pp;.pas;.lpr;.dpr;.dpk'
    FSourceTools: TAVLTree; // tree of TCustomCodeTool sorted for pointer
    FTabWidth: integer;
    FVisibleEditorLines: integer;
    FWriteExceptions: boolean;
    FWriteLockCount: integer;// Set/Unset counter
    FWriteLockStep: integer; // current write lock ID
    function OnScannerGetInitValues(Code: Pointer;
      var AChangeStep: integer): TExpressionEvaluator;
    procedure OnDefineTreeReadValue(Sender: TObject; const VariableName: string;
                                    var Value: string; var Handled: boolean);
    procedure OnGlobalValuesChanged;
    function DoOnFindUsedUnit(SrcTool: TFindDeclarationTool; const TheUnitName,
          TheUnitInFilename: string): TCodeBuffer;
    function DoOnGetSrcPathForCompiledUnit(Sender: TObject;
          const AFilename: string): string;
    function FindCodeOfMainUnitHint(Code: TCodeBuffer): TCodeBuffer;
    procedure CreateScanner(Code: TCodeBuffer);
    function InitCurCodeTool(Code: TCodeBuffer): boolean;
    function InitResourceTool: boolean;
    procedure ClearPositions;
    function GetCodeToolForSource(Code: TCodeBuffer;
      ExceptionOnError: boolean): TCustomCodeTool;
    procedure SetAbortable(const AValue: boolean);
    procedure SetAddInheritedCodeToOverrideMethod(const AValue: boolean);
    procedure SetCheckFilesOnDisk(NewValue: boolean);
    procedure SetCompleteProperties(const AValue: boolean);
    procedure SetIndentSize(NewValue: integer);
    procedure SetTabWidth(const AValue: integer);
    procedure SetVisibleEditorLines(NewValue: integer);
    procedure SetJumpCentered(NewValue: boolean);
    procedure SetCursorBeyondEOL(NewValue: boolean);
    procedure BeforeApplyingChanges(var Abort: boolean);
    procedure AfterApplyingChanges;
    function HandleException(AnException: Exception): boolean;
    function OnGetCodeToolForBuffer(Sender: TObject;
      Code: TCodeBuffer): TFindDeclarationTool;
    procedure OnToolSetWriteLock(Lock: boolean);
    procedure OnToolGetWriteLockInfo(var WriteLockIsSet: boolean;
      var WriteLockStep: integer);
    function OnParserProgress(Tool: TCustomCodeTool): boolean;
    function OnScannerProgress(Sender: TLinkScanner): boolean;
    function GetResourceTool: TResourceCodeTool;
    function GetOwnerForCodeTreeNode(ANode: TCodeTreeNode): TObject;
  public
    DefinePool: TDefinePool; // definition templates (rules)
    DefineTree: TDefineTree; // cache for defines (e.g. initial compiler values)
    SourceCache: TCodeCache; // cache for source (units, include files, ...)
    SourceChangeCache: TSourceChangeCache; // cache for write accesses
    GlobalValues: TExpressionEvaluator;
    IdentifierList: TIdentifierList;
    IdentifierHistory: TIdentifierHistoryList;
    Positions: TCodeXYPositions;
    
    constructor Create;
    destructor Destroy; override;

    procedure ActivateWriteLock;
    procedure DeactivateWriteLock;

    // file handling
    property SourceExtensions: string
                                 read FSourceExtensions write FSourceExtensions;
    function FindFile(const ExpandedFilename: string): TCodeBuffer;
    function LoadFile(const ExpandedFilename: string;
                      UpdateFromDisk, Revert: boolean): TCodeBuffer;
    function CreateFile(const AFilename: string): TCodeBuffer;
    function CreateTempFile(const AFilename: string): TCodeBuffer;
    procedure ReleaseTempFile(Buffer: TCodeBuffer);
    function SaveBufferAs(OldBuffer: TCodeBuffer;const ExpandedFilename: string;
                          var NewBuffer: TCodeBuffer): boolean;
    function FilenameHasSourceExt(const AFilename: string): boolean;
    function GetMainCode(Code: TCodeBuffer): TCodeBuffer;
    function GetIncludeCodeChain(Code: TCodeBuffer;
                                 RemoveFirstCodesWithoutTool: boolean;
                                 var ListOfCodeBuffer: TList): boolean;
    function FindCodeToolForSource(Code: TCodeBuffer): TCustomCodeTool;
    property OnSearchUsedUnit: TOnSearchUsedUnit
                                 read FOnSearchUsedUnit write FOnSearchUsedUnit;
    
    // exception handling
    property CatchExceptions: boolean
                                   read FCatchExceptions write FCatchExceptions;
    property WriteExceptions: boolean
                                   read FWriteExceptions write FWriteExceptions;
    property ErrorCode: TCodeBuffer read fErrorCode;
    property ErrorColumn: integer read fErrorColumn;
    property ErrorLine: integer read fErrorLine;
    property ErrorMessage: string read fErrorMsg;
    property ErrorTopLine: integer read fErrorTopLine;
    property Abortable: boolean read FAbortable write SetAbortable;
    property OnCheckAbort: TOnCodeToolCheckAbort
                                         read FOnCheckAbort write FOnCheckAbort;

    // tool settings
    property AdjustTopLineDueToComment: boolean read FAdjustTopLineDueToComment
                                               write FAdjustTopLineDueToComment;
    property CheckFilesOnDisk: boolean read FCheckFilesOnDisk
                                       write SetCheckFilesOnDisk;
    property CursorBeyondEOL: boolean read FCursorBeyondEOL
                                      write SetCursorBeyondEOL;
    property IndentSize: integer read FIndentSize write SetIndentSize;
    property JumpCentered: boolean read FJumpCentered write SetJumpCentered;
    property SetPropertyVariablename: string
                   read FSetPropertyVariablename write FSetPropertyVariablename;
    property VisibleEditorLines: integer
                           read FVisibleEditorLines write SetVisibleEditorLines;
    property TabWidth: integer read FTabWidth write SetTabWidth;
    property CompleteProperties: boolean
                           read FCompleteProperties write SetCompleteProperties;
    property AddInheritedCodeToOverrideMethod: boolean
                                      read FAddInheritedCodeToOverrideMethod
                                      write SetAddInheritedCodeToOverrideMethod;

    // source changing
    procedure BeginUpdate;
    procedure EndUpdate;
    function GatherExternalChanges: boolean;
    property OnGatherExternalChanges: TOnGatherExternalChanges
                   read FOnGatherExternalChanges write FOnGatherExternalChanges;
    function ApplyChanges: boolean;
    property OnBeforeApplyChanges: TOnBeforeApplyChanges
                         read FOnBeforeApplyChanges write FOnBeforeApplyChanges;
    property OnAfterApplyChanges: TOnAfterApplyChanges
                           read FOnAfterApplyChanges write FOnAfterApplyChanges;
          
    // defines
    function SetGlobalValue(const VariableName, VariableValue: string): boolean;
    function GetUnitPathForDirectory(const Directory: string): string;
    function GetIncludePathForDirectory(const Directory: string): string;
    function GetSrcPathForDirectory(const Directory: string): string;
    function GetPPUSrcPathForDirectory(const Directory: string): string;
    function GetPPWSrcPathForDirectory(const Directory: string): string;
    function GetDCUSrcPathForDirectory(const Directory: string): string;
    function GetCompiledSrcPathForDirectory(const Directory: string): string;
    function GetNestedCommentsFlagForFile(const Filename: string): boolean;
    function GetPascalCompilerForDirectory(const Directory: string): TPascalCompiler;
    function GetCompilerModeForDirectory(const Directory: string): TCompilerMode;
    function GetCompiledSrcExtForDirectory(const Directory: string): string;
    function FindUnitInUnitLinks(const Directory, UnitName: string): string;
    function GetUnitLinksForDirectory(const Directory: string): string;
    procedure GetFPCVersionForDirectory(const Directory: string;
                                 var FPCVersion, FPCRelease, FPCPatch: integer);

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    // code exploring
    function Explore(Code: TCodeBuffer; var ACodeTool: TCodeTool;
          WithStatements: boolean): boolean;
    function CheckSyntax(Code: TCodeBuffer; var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer; var ErrorMsg: string): boolean;

    // compiler directives
    function GuessMisplacedIfdefEndif(Code: TCodeBuffer; X,Y: integer;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
    // find include directive of include file at position X,Y
    function FindEnclosingIncludeDirective(Code: TCodeBuffer; X,Y: integer;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
          
    // keywords and comments
    function IsKeyword(Code: TCodeBuffer; const KeyWord: string): boolean;
    function ExtractCodeWithoutComments(Code: TCodeBuffer): string;

    // blocks (e.g. begin..end, case..end, try..finally..end, repeat..until)
    function FindBlockCounterPart(Code: TCodeBuffer; X,Y: integer;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
    function FindBlockStart(Code: TCodeBuffer; X,Y: integer;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
    function GuessUnclosedBlock(Code: TCodeBuffer; X,Y: integer;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
          
    // method jumping
    function JumpToMethod(Code: TCodeBuffer; X,Y: integer;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer;
          var RevertableJump: boolean): boolean;

    // find declaration
    function FindDeclaration(Code: TCodeBuffer; X,Y: integer;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
    function FindSmartHint(Code: TCodeBuffer; X,Y: integer): string;
    function FindDeclarationInInterface(Code: TCodeBuffer;
          const Identifier: string; var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
    function FindDeclarationsAndAncestors(Code: TCodeBuffer; X,Y: integer;
          var ListOfPCodeXYPosition: TList): boolean;
    
    // gather identifiers (i.e. all visible)
    function GatherIdentifiers(Code: TCodeBuffer; X,Y: integer): boolean;
    function GetIdentifierAt(Code: TCodeBuffer; X,Y: integer;
          var Identifier: string): boolean;

    // resourcestring sections
    function GatherResourceStringSections(
          Code: TCodeBuffer; X,Y: integer;
          CodePositions: TCodeXYPositions): boolean;
    function IdentifierExistsInResourceStringSection(Code: TCodeBuffer;
          X,Y: integer; const ResStrIdentifier: string): boolean;
    function CreateIdentifierFromStringConst(
          StartCode: TCodeBuffer; StartX, StartY: integer;
          EndCode: TCodeBuffer;   EndX, EndY: integer;
          var Identifier: string; MaxLen: integer): boolean;
    function StringConstToFormatString(
          StartCode: TCodeBuffer; StartX, StartY: integer;
          EndCode: TCodeBuffer;   EndX, EndY: integer;
          var FormatStringConstant, FormatParameters: string): boolean;
    function GatherResourceStringsWithValue(SectionCode: TCodeBuffer;
          SectionX, SectionY: integer; const StringValue: string;
          CodePositions: TCodeXYPositions): boolean;
    function AddResourcestring(CursorCode: TCodeBuffer; X,Y: integer;
          SectionCode: TCodeBuffer; SectionX, SectionY: integer;
          const NewIdentifier, NewValue: string;
          InsertPolicy: TResourcestringInsertPolicy): boolean;

    // expressions
    function GetStringConstBounds(Code: TCodeBuffer; X,Y: integer;
          var StartCode: TCodeBuffer; var StartX, StartY: integer;
          var EndCode: TCodeBuffer; var EndX, EndY: integer;
          ResolveComments: boolean): boolean;
    function ReplaceCode(Code: TCodeBuffer; StartX, StartY: integer;
          EndX, EndY: integer; const NewCode: string): boolean;

    // code completion = auto class completion, auto forward proc completion,
    //             local var assignment completion, event assignment completion
    function CompleteCode(Code: TCodeBuffer; X,Y,TopLine: integer;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
          
    // extract proc
    function CheckExtractProc(Code: TCodeBuffer;
          const StartPoint, EndPoint: TPoint;
          var MethodPossible, SubProcSameLvlPossible: boolean): boolean;
    function ExtractProc(Code: TCodeBuffer; const StartPoint, EndPoint: TPoint;
          ProcType: TExtractProcType; const ProcName: string;
          var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer
          ): boolean;

    // code templates
    function InsertCodeTemplate(Code: TCodeBuffer;
          SelectionStart, SelectionEnd: TPoint;
          TopLine: integer;
          CodeTemplate: TCodeToolTemplate;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;

    // source name  e.g. 'unit UnitName;'
    function GetSourceName(Code: TCodeBuffer; SearchMainCode: boolean): string;
    function GetCachedSourceName(Code: TCodeBuffer): string;
    function RenameSource(Code: TCodeBuffer; const NewName: string): boolean;
    function GetSourceType(Code: TCodeBuffer; SearchMainCode: boolean): string;

    // uses sections
    function FindUnitInAllUsesSections(Code: TCodeBuffer;
          const AnUnitName: string;
          var NamePos, InPos: integer): boolean;
    function RenameUsedUnit(Code: TCodeBuffer;
          const OldUnitName, NewUnitName, NewUnitInFile: string): boolean;
    function AddUnitToMainUsesSection(Code: TCodeBuffer;
          const NewUnitName, NewUnitInFile: string): boolean;
    function RemoveUnitFromAllUsesSections(Code: TCodeBuffer;
          const AnUnitName: string): boolean;
    function FindUsedUnitFiles(Code: TCodeBuffer; var MainUsesSection,
          ImplementationUsesSection: TStrings): boolean;
    function FindUsedUnitNames(Code: TCodeBuffer; var MainUsesSection,
          ImplementationUsesSection: TStrings): boolean;

    // resources
    property OnGetDefineProperties: TOnGetDefineProperties
                       read FOnGetDefineProperties write FOnGetDefineProperties;
    property OnGetDefinePropertiesForClass: TOnGetDefinePropertiesForClass
                                           read FOnGetDefinePropertiesForClass
                                           write FOnGetDefinePropertiesForClass;
    function FindLFMFileName(Code: TCodeBuffer): string;
    function CheckLFM(UnitCode, LFMBuf: TCodeBuffer;
          var LFMTree: TLFMTree;
          RootMustBeClassInIntf, ObjectsMustExists: boolean): boolean;
    function FindNextResourceFile(Code: TCodeBuffer;
          var LinkIndex: integer): TCodeBuffer;
    function AddLazarusResourceHeaderComment(Code: TCodeBuffer;
          const CommentText: string): boolean;
    function FindLazarusResource(Code: TCodeBuffer;
          const ResourceName: string): TAtomPosition;
    function AddLazarusResource(Code: TCodeBuffer;
          const ResourceName, ResourceData: string): boolean;
    function RemoveLazarusResource(Code: TCodeBuffer;
          const ResourceName: string): boolean;
    function RenameMainInclude(Code: TCodeBuffer; const NewFilename: string;
          KeepPath: boolean): boolean;
    function RenameIncludeDirective(Code: TCodeBuffer; LinkIndex: integer;
          const NewFilename: string; KeepPath: boolean): boolean;
    procedure DefaultGetDefineProperties(Sender: TObject;
                       const ClassContext: TFindContext; LFMNode: TLFMTreeNode;
                       const IdentName: string; var DefineProperties: TStrings);

    // register proc
    function HasInterfaceRegisterProc(Code: TCodeBuffer;
          var HasRegisterProc: boolean): boolean;
          
    // Delphi to Lazarus conversion
    function ConvertDelphiToLazarusSource(Code: TCodeBuffer;
          AddLRSCode: boolean): boolean;
          
    // Application.Createform(ClassName,VarName) statements in program source
    function FindCreateFormStatement(Code: TCodeBuffer; StartPos: integer;
          const AClassName, AVarName: string;
          var Position: integer): integer; // 0=found, -1=not found, 1=found, but wrong classname
    function AddCreateFormStatement(Code: TCodeBuffer;
          const AClassName, AVarName: string): boolean;
    function RemoveCreateFormStatement(Code: TCodeBuffer;
          const AVarName: string): boolean;
    function ChangeCreateFormStatement(Code: TCodeBuffer;
          const OldClassName, OldVarName: string;
          const NewClassName, NewVarName: string;
          OnlyIfExists: boolean): boolean;
    function ListAllCreateFormStatements(Code: TCodeBuffer): TStrings;
    function SetAllCreateFromStatements(Code: TCodeBuffer; 
          List: TStrings): boolean;
          
    // Application.Title:= statements in program source
    function GetApplicationTitleStatement(Code: TCodeBuffer;
          var Title: string): boolean;
    function SetApplicationTitleStatement(Code: TCodeBuffer;
          const NewTitle: string): boolean;
    function RemoveApplicationTitleStatement(Code: TCodeBuffer): boolean;

    // forms
    function RenameForm(Code: TCodeBuffer;
      const OldFormName, OldFormClassName: string;
      const NewFormName, NewFormClassName: string): boolean;
    function FindFormAncestor(Code: TCodeBuffer; const FormClassName: string;
      var AncestorClassName: string; DirtySearch: boolean): boolean;

    // form components
    function CompleteComponent(Code: TCodeBuffer; AComponent: TComponent
          ): boolean;
    function PublishedVariableExists(Code: TCodeBuffer;
          const AClassName, AVarName: string;
          ErrorOnClassNotFound: boolean): boolean;
    function AddPublishedVariable(Code: TCodeBuffer;
          const AClassName,VarName, VarType: string): boolean;
    function RemovePublishedVariable(Code: TCodeBuffer;
          const AClassName, AVarName: string;
          ErrorOnClassNotFound: boolean): boolean;
    function RenamePublishedVariable(Code: TCodeBuffer;
          const AClassName, OldVariableName, NewVarName,
          VarType: shortstring; ErrorOnClassNotFound: boolean): boolean;
          
    // functions for events in the object inspector
    function GetCompatiblePublishedMethods(Code: TCodeBuffer;
          const AClassName: string; TypeData: PTypeData;
          Proc: TGetStringProc): boolean;
    function PublishedMethodExists(Code:TCodeBuffer; const AClassName,
          AMethodName: string; TypeData: PTypeData;
          var MethodIsCompatible, MethodIsPublished, IdentIsMethod: boolean
          ): boolean;
    function JumpToPublishedMethodBody(Code: TCodeBuffer;
          const AClassName, AMethodName: string;
          var NewCode: TCodeBuffer;
          var NewX, NewY, NewTopLine: integer): boolean;
    function RenamePublishedMethod(Code: TCodeBuffer;
          const AClassName, OldMethodName,
          NewMethodName: string): boolean;
    function CreatePublishedMethod(Code: TCodeBuffer; const AClassName,
          NewMethodName: string; ATypeInfo: PTypeInfo): boolean;
          
    // IDE % directives
    function GetIDEDirectives(Code: TCodeBuffer;
          DirectiveList: TStrings): boolean;
    function SetIDEDirectives(Code: TCodeBuffer;
          DirectiveList: TStrings): boolean;

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    function ConsistencyCheck: integer; // 0 = ok
    procedure WriteDebugReport(WriteTool,
          WriteDefPool, WriteDefTree, WriteCache, WriteGlobalValues: boolean);
  end;


var CodeToolBoss: TCodeToolManager;


implementation


function CompareCodeToolMainSources(Data1, Data2: Pointer): integer;
var
  Src1, Src2: integer;
begin
  Src1:=Integer(TCustomCodeTool(Data1).Scanner.MainCode);
  Src2:=Integer(TCustomCodeTool(Data2).Scanner.MainCode);
  if Src1<Src2 then
    Result:=-1
  else if Src1>Src2 then
    Result:=+1
  else
    Result:=0;
end;

function GetOwnerForCodeTreeNode(ANode: TCodeTreeNode): TObject;
begin
  Result:=CodeToolBoss.GetOwnerForCodeTreeNode(ANode);
end;


{ TCodeToolManager }

constructor TCodeToolManager.Create;
begin
  inherited Create;
  FCheckFilesOnDisk:=true;
  FOnGetDefineProperties:=@DefaultGetDefineProperties;
  DefineTree:=TDefineTree.Create;
  DefineTree.OnReadValue:=@OnDefineTreeReadValue;
  DefinePool:=TDefinePool.Create;
  SourceCache:=TCodeCache.Create;
  SourceChangeCache:=TSourceChangeCache.Create;
  SourceChangeCache.OnBeforeApplyChanges:=@BeforeApplyingChanges;
  SourceChangeCache.OnAfterApplyChanges:=@AfterApplyingChanges;
  GlobalValues:=TExpressionEvaluator.Create;
  FAddInheritedCodeToOverrideMethod:=true;
  FAdjustTopLineDueToComment:=true;
  FCatchExceptions:=true;
  FCompleteProperties:=true;
  FCursorBeyondEOL:=true;
  FIndentSize:=2;
  FJumpCentered:=true;
  FSourceExtensions:='.pp;.pas;.lpr;.lpk;.dpr;.dpk';
  FVisibleEditorLines:=20;
  FWriteExceptions:=true;
  FSourceTools:=TAVLTree.Create(@CompareCodeToolMainSources);
  IdentifierList:=TIdentifierList.Create;
  IdentifierHistory:=TIdentifierHistoryList.Create;
  IdentifierList.History:=IdentifierHistory;
end;

destructor TCodeToolManager.Destroy;
begin
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.Destroy] A');
  {$ENDIF}
  GlobalValues.Free;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.Destroy] B');
  {$ENDIF}
  Positions.Free;
  IdentifierHistory.Free;
  IdentifierList.Free;
  FSourceTools.FreeAndClear;
  FSourceTools.Free;
  FResourceTool.Free;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.Destroy] C');
  {$ENDIF}
  DefineTree.Free;
  DefinePool.Free;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.Destroy] D');
  {$ENDIF}
  SourceChangeCache.Free;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.Destroy] E');
  {$ENDIF}
  SourceCache.Free;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.Destroy] F');
  {$ENDIF}
  inherited Destroy;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.Destroy] END');
  {$ENDIF}
  {$IFDEF MEM_CHECK}
  CheckHeap('TCodeToolManager.Destroy END');
  {$ENDIF}
end;

procedure TCodeToolManager.BeginUpdate;
begin
  SourceChangeCache.BeginUpdate;
end;

procedure TCodeToolManager.EndUpdate;
begin
  SourceChangeCache.EndUpdate;
end;

function TCodeToolManager.GatherExternalChanges: boolean;
var
  Abort: Boolean;
begin
  Result:=true;
  if Assigned(OnGatherExternalChanges) then begin
    Abort:=false;
    OnGatherExternalChanges(Self,Abort);
    Result:=not Abort;
  end;
end;

function TCodeToolManager.FindFile(const ExpandedFilename: string): TCodeBuffer;
begin
  Result:=SourceCache.FindFile(ExpandedFilename);
end;

function TCodeToolManager.LoadFile(const ExpandedFilename: string;
  UpdateFromDisk, Revert: boolean): TCodeBuffer;
begin
  {$IFDEF CTDEBUG}
  DebugLn('>>>>>> [TCodeToolManager.LoadFile] ',ExpandedFilename,' Update=',UpdateFromDisk,' Revert=',Revert);
  {$ENDIF}
  Result:=SourceCache.LoadFile(ExpandedFilename);
  if Result<>nil then begin
    if Revert then
      Result.Revert
    else if UpdateFromDisk then
      Result.Reload;
  end;
end;

function TCodeToolManager.CreateFile(const AFilename: string): TCodeBuffer;
begin
  Result:=SourceCache.CreateFile(AFilename);
  {$IFDEF CTDEBUG}
  DebugLn('****** TCodeToolManager.CreateFile "',AFilename,'" ',Result<>nil);
  {$ENDIF}
end;

function TCodeToolManager.CreateTempFile(const AFilename: string): TCodeBuffer;
var
  i: Integer;
  TempFilename: string;
begin
  i:=1;
  repeat
    TempFilename:=VirtualTempDir+PathDelim+IntToStr(i)+PathDelim+AFilename;
    Result:=FindFile(TempFilename);
    if (Result<>nil) and (Result.ReferenceCount=0) then exit;
    inc(i);
  until Result=nil;
  Result:=SourceCache.CreateFile(TempFilename);
  Result.IncrementRefCount;
end;

procedure TCodeToolManager.ReleaseTempFile(Buffer: TCodeBuffer);
begin
  Buffer.ReleaseRefCount;
end;

function TCodeToolManager.SaveBufferAs(OldBuffer: TCodeBuffer;
  const ExpandedFilename: string; var NewBuffer: TCodeBuffer): boolean;
begin
  Result:=SourceCache.SaveBufferAs(OldBuffer,ExpandedFilename,NewBuffer);
end;

function TCodeToolManager.FilenameHasSourceExt(
  const AFilename: string): boolean;
var i, CurExtStart, CurExtEnd, ExtStart, ExtLen: integer;
begin
  ExtStart:=length(AFilename);
  while (ExtStart>0) and (AFilename[ExtStart]<>'.')
  and (AFilename[ExtStart]<>PathDelim) do
    dec(ExtStart);
  if (ExtStart<1) or (AFilename[ExtStart]<>'.') then begin
    Result:=false;
    exit;
  end;
  ExtLen:=length(AFilename)-ExtStart+1;
  CurExtStart:=1;
  CurExtEnd:=CurExtStart;
  while CurExtEnd<=length(FSourceExtensions)+1 do begin
    if (CurExtEnd>length(FSourceExtensions))
    or (FSourceExtensions[CurExtEnd] in [':',';']) then begin
      // compare current extension with filename-extension
      if ExtLen=CurExtEnd-CurExtStart then begin
        i:=0;
        while (i<ExtLen) 
        and (UpChars[AFilename[i+ExtStart]]
            =UpChars[FSourceExtensions[CurExtStart+i]]) do
          inc(i);
        if i=ExtLen then begin
          Result:=true;
          exit;
        end;
      end;
      inc(CurExtEnd);
      CurExtStart:=CurExtEnd;
    end else
      inc(CurExtEnd);
  end;
  Result:=false;
end;

function TCodeToolManager.GetMainCode(Code: TCodeBuffer): TCodeBuffer;
begin
  // find MainCode (= the start source, e.g. a unit/program/package source)
  Result:=Code;
  if Result=nil then exit;
  // if this is an include file, find the top level source
  while (Result.LastIncludedByFile<>'') do begin
    Result:=SourceCache.LoadFile(Result.LastIncludedByFile);
    if Result=nil then exit;
  end;
  if (not FilenameHasSourceExt(Result.Filename)) then begin
    Result:=FindCodeOfMainUnitHint(Result);
  end;
  if Result=nil then exit;
  CreateScanner(Result);
end;

function TCodeToolManager.GetIncludeCodeChain(Code: TCodeBuffer;
  RemoveFirstCodesWithoutTool: boolean; var ListOfCodeBuffer: TList): boolean;
var
  OldCode: TCodeBuffer;
begin
  // find MainCode (= the start source, e.g. a unit/program/package source)
  Result:=false;
  ListOfCodeBuffer:=nil;
  if Code=nil then exit;
  
  Result:=true;
  ListOfCodeBuffer:=TList.Create;
  ListOfCodeBuffer.Add(Code);
  
  // if this is an include file, find the top level source
  while (Code.LastIncludedByFile<>'') do begin
    Code:=SourceCache.LoadFile(Code.LastIncludedByFile);
    if Code=nil then exit;
    ListOfCodeBuffer.Insert(0,Code);
  end;

  if (not FilenameHasSourceExt(Code.Filename)) then begin
    OldCode:=Code;
    Code:=FindCodeOfMainUnitHint(OldCode);
    if Code<>OldCode then
      ListOfCodeBuffer.Insert(0,Code);
  end;

  if RemoveFirstCodesWithoutTool then begin
    while ListOfCodeBuffer.Count>0 do begin
      Code:=TCodeBuffer(ListOfCodeBuffer[0]);
      if FindCodeToolForSource(Code)<>nil then break;
      ListOfCodeBuffer.Delete(0);
    end;
    if ListOfCodeBuffer.Count=0 then begin
      ListOfCodeBuffer.Free;
      ListOfCodeBuffer:=nil;
      Result:=false;
      exit;
    end;
  end;
end;

function TCodeToolManager.FindCodeOfMainUnitHint(Code: TCodeBuffer
  ): TCodeBuffer;
var
  MainUnitFilename: string;
begin
  Result:=nil;
  if Code=nil then exit;
  //DebugLn('TCodeToolManager.FindCodeOfMainUnitHint ',Code.Filename);
  if not FindMainUnitHint(Code.Source,MainUnitFilename) then exit;
  MainUnitFilename:=TrimFilename(MainUnitFilename);
  if (not FilenameIsAbsolute(MainUnitFilename))
  and (not Code.IsVirtual) then
    MainUnitFilename:=TrimFilename(ExtractFilePath(Code.Filename)+PathDelim
                                   +MainUnitFilename);
  //DebugLn('TCodeToolManager.FindCodeOfMainUnitHint B ');
  Result:=SourceCache.LoadFile(MainUnitFilename);
end;

procedure TCodeToolManager.CreateScanner(Code: TCodeBuffer);
begin
  if FilenameHasSourceExt(Code.Filename) and (Code.Scanner=nil) then begin
    // create a scanner for the unit/program
    Code.Scanner:=TLinkScanner.Create;
    Code.Scanner.OnGetInitValues:=@OnScannerGetInitValues;
    Code.Scanner.OnSetGlobalWriteLock:=@OnToolSetWriteLock;
    Code.Scanner.OnGetGlobalWriteLockInfo:=@OnToolGetWriteLockInfo;
    Code.Scanner.OnProgress:=@OnScannerProgress;
  end;
end;

function TCodeToolManager.ApplyChanges: boolean;
begin
  Result:=SourceChangeCache.Apply;
end;

function TCodeToolManager.SetGlobalValue(const VariableName,
  VariableValue: string): boolean;
var
  OldValue: string;
begin
  OldValue:=GlobalValues[VariableName];
  Result:=(OldValue<>VariableValue);
  if not Result then exit;
  GlobalValues[VariableName]:=VariableValue;
  DefineTree.ClearCache;
end;

function TCodeToolManager.GetUnitPathForDirectory(const Directory: string): string;
begin
  Result:=DefineTree.GetUnitPathForDirectory(Directory);
end;

function TCodeToolManager.GetIncludePathForDirectory(const Directory: string
  ): string;
begin
  Result:=DefineTree.GetIncludePathForDirectory(Directory);
end;

function TCodeToolManager.GetSrcPathForDirectory(const Directory: string
  ): string;
begin
  Result:=DefineTree.GetSrcPathForDirectory(Directory);
end;

function TCodeToolManager.GetPPUSrcPathForDirectory(const Directory: string
  ): string;
begin
  Result:=DefineTree.GetPPUSrcPathForDirectory(Directory);
end;

function TCodeToolManager.GetPPWSrcPathForDirectory(const Directory: string
  ): string;
begin
  Result:=DefineTree.GetPPWSrcPathForDirectory(Directory);
end;

function TCodeToolManager.GetDCUSrcPathForDirectory(const Directory: string
  ): string;
begin
  Result:=DefineTree.GetDCUSrcPathForDirectory(Directory);
end;

function TCodeToolManager.GetCompiledSrcPathForDirectory(const Directory: string
  ): string;
begin
  Result:=DefineTree.GetCompiledSrcPathForDirectory(Directory);
end;

function TCodeToolManager.GetNestedCommentsFlagForFile(
  const Filename: string): boolean;
var
  Evaluator: TExpressionEvaluator;
  Directory: String;
begin
  Result:=false;
  Directory:=ExtractFilePath(Filename);
  // check pascal compiler is FPC and mode is FPC or OBJFPC
  if GetPascalCompilerForDirectory(Directory)<>pcFPC then exit;
  if not (GetCompilerModeForDirectory(Directory) in [cmFPC,cmOBJFPC]) then exit;
  // check Nested Compiler define is on
  Evaluator:=DefineTree.GetDefinesForDirectory(Directory,true);
  if Evaluator=nil then exit;
  if ((Evaluator.IsDefined(NestedCompilerDefine))
    or (CompareFileExt(Filename,'pp',false)=0))
  then
    Result:=true;
end;

function TCodeToolManager.GetPascalCompilerForDirectory(const Directory: string
  ): TPascalCompiler;
var
  Evaluator: TExpressionEvaluator;
  PascalCompiler: string;
  pc: TPascalCompiler;
begin
  Result:=pcFPC;
  Evaluator:=DefineTree.GetDefinesForDirectory(Directory,true);
  if Evaluator=nil then exit;
  PascalCompiler:=Evaluator.Variables[PascalCompilerDefine];
  for pc:=Low(TPascalCompiler) to High(TPascalCompiler) do
    if (PascalCompiler=PascalCompilerNames[pc]) then
      Result:=pc;
end;

function TCodeToolManager.GetCompilerModeForDirectory(const Directory: string
  ): TCompilerMode;
var
  Evaluator: TExpressionEvaluator;
  cm: TCompilerMode;
begin
  Result:=cmFPC;
  Evaluator:=DefineTree.GetDefinesForDirectory(Directory,true);
  if Evaluator=nil then exit;
  for cm:=Low(TCompilerMode) to High(TCompilerMode) do
    if Evaluator.IsDefined(CompilerModeVars[cm]) then
      Result:=cm;
end;

function TCodeToolManager.GetCompiledSrcExtForDirectory(const Directory: string
  ): string;
var
  Evaluator: TExpressionEvaluator;
begin
  Result:='.ppu';
  Evaluator:=DefineTree.GetDefinesForDirectory(Directory,true);
  if Evaluator=nil then exit;
  if Evaluator.IsDefined('WIN32') and Evaluator.IsDefined('VER1_0') then
    Result:='.ppw';
end;

function TCodeToolManager.FindUnitInUnitLinks(const Directory, UnitName: string
  ): string;
var
  UnitLinks: string;
  UnitLinkStart, UnitLinkEnd: integer;
begin
  Result:='';
  UnitLinks:=GetUnitLinksForDirectory(Directory);
  if UnitLinks='' then exit;
  SearchUnitInUnitLinks(UnitLinks,UnitName,UnitLinkStart,UnitLinkEnd,Result);
end;

function TCodeToolManager.GetUnitLinksForDirectory(const Directory: string
  ): string;
var
  Evaluator: TExpressionEvaluator;
begin
  Result:='';
  Evaluator:=DefineTree.GetDefinesForDirectory(Directory,true);
  if Evaluator=nil then exit;
  Result:=Evaluator[ExternalMacroStart+'UnitLinks'];
end;

procedure TCodeToolManager.GetFPCVersionForDirectory(const Directory: string;
  var FPCVersion, FPCRelease, FPCPatch: integer);
var
  Evaluator: TExpressionEvaluator;
  i: Integer;
  VarName: String;
  p: Integer;

  function ReadInt(var AnInteger: integer): boolean;
  var
    StartPos: Integer;
  begin
    StartPos:=p;
    AnInteger:=0;
    while (p<=length(VarName)) and (VarName[p] in ['0'..'9']) do begin
      AnInteger:=AnInteger*10+(ord(VarName[p])-ord('0'));
      if AnInteger>=100 then begin
        Result:=false;
        exit;
      end;
      inc(p);
    end;
    Result:=StartPos<p;
  end;
  
begin
  FPCVersion:=0;
  FPCRelease:=0;
  FPCPatch:=0;
  Evaluator:=DefineTree.GetDefinesForDirectory(Directory,true);
  if Evaluator=nil then exit;
  for i:=0 to Evaluator.Count-1 do begin
    VarName:=Evaluator.Names(i);
    if (length(VarName)>3) and (VarName[1] in ['V','v'])
    and (VarName[2] in ['E','e']) and (VarName[3] in ['R','r'])
    and (VarName[4] in ['0'..'9']) then begin
      p:=4;
      if not ReadInt(FPCVersion) then continue;
      if (p>=length(VarName)) or (VarName[p]<>'_') then continue;
      inc(p);
      if not ReadInt(FPCRelease) then continue;
      if (p>=length(VarName)) or (VarName[p]<>'_') then continue;
      inc(p);
      if not ReadInt(FPCPatch) then continue;
      exit;
    end;
  end;
end;

function TCodeToolManager.Explore(Code: TCodeBuffer;
  var ACodeTool: TCodeTool; WithStatements: boolean): boolean;
begin
  Result:=false;
  ACodeTool:=nil;
  try
    if InitCurCodeTool(Code) then begin
      ACodeTool:=FCurCodeTool;
      FCurCodeTool.Explore(WithStatements);
      Result:=true;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.InitCurCodeTool(Code: TCodeBuffer): boolean;
var MainCode: TCodeBuffer;
begin
  Result:=false;
  fErrorMsg:='';
  fErrorCode:=nil;
  fErrorLine:=-1;
  if IdentifierList<>nil then IdentifierList.Clear;
  MainCode:=GetMainCode(Code);
  if MainCode=nil then begin
    fErrorMsg:='TCodeToolManager.InitCurCodeTool MainCode=nil';
    exit;
  end;
  if MainCode.Scanner=nil then begin
    FErrorMsg:=Format(ctsNoScannerFound,[MainCode.Filename]);
    exit;
  end;
  FCurCodeTool:=TCodeTool(GetCodeToolForSource(MainCode,true));
  FCurCodeTool.ErrorPosition.Code:=nil;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.InitCurCodeTool] ',Code.Filename,' ',Code.SourceLength);
  {$ENDIF}
  Result:=(FCurCodeTool.Scanner<>nil);
  if not Result then begin
    fErrorCode:=MainCode;
    fErrorMsg:=ctsNoScannerAvailable;
  end;
end;

function TCodeToolManager.InitResourceTool: boolean;
begin
  fErrorMsg:='';
  fErrorCode:=nil;
  fErrorLine:=-1;
  Result:=true;
end;

procedure TCodeToolManager.ClearPositions;
begin
  if Positions=nil then
    Positions:=TCodeXYPositions.Create
  else
    Positions.Clear;
end;

function TCodeToolManager.HandleException(AnException: Exception): boolean;
var ErrorSrcTool: TCustomCodeTool;
  DirtyPos: Integer;
begin
  fErrorMsg:=AnException.Message;
  fErrorTopLine:=0;
  if (AnException is ELinkScannerError) then begin
    // link scanner error
    DirtyPos:=0;
    if AnException is ELinkScannerEditError then begin
      fErrorCode:=TCodeBuffer(ELinkScannerEditError(AnException).Buffer);
      if fErrorCode<>nil then
        DirtyPos:=ELinkScannerEditError(AnException).BufferPos;
    end else begin
      fErrorCode:=TCodeBuffer(ELinkScannerError(AnException).Sender.Code);
      DirtyPos:=ELinkScannerError(AnException).Sender.SrcPos;
    end;
    if (fErrorCode<>nil) and (DirtyPos>0) then begin
      fErrorCode.AbsoluteToLineCol(DirtyPos,fErrorLine,fErrorColumn);
    end;
  end else if (AnException is ECodeToolError) then begin
    // codetool error
    ErrorSrcTool:=ECodeToolError(AnException).Sender;
    fErrorCode:=ErrorSrcTool.ErrorPosition.Code;
    fErrorColumn:=ErrorSrcTool.ErrorPosition.X;
    fErrorLine:=ErrorSrcTool.ErrorPosition.Y;
  end else if (AnException is ESourceChangeCacheError) then begin
    // SourceChangeCache error
    fErrorCode:=nil;
  end else begin
    // unknown exception
    FErrorMsg:=AnException.ClassName+': '+FErrorMsg;
    if FCurCodeTool<>nil then begin
      fErrorCode:=FCurCodeTool.ErrorPosition.Code;
      fErrorColumn:=FCurCodeTool.ErrorPosition.X;
      fErrorLine:=FCurCodeTool.ErrorPosition.Y;
    end;
  end;
  // adjust error topline
  if (fErrorCode<>nil) and (fErrorTopLine<1) then begin
    fErrorTopLine:=fErrorLine;
    if (fErrorTopLine>0) and JumpCentered then begin
      dec(fErrorTopLine,VisibleEditorLines div 2);
      if fErrorTopLine<1 then fErrorTopLine:=1;
    end;
  end;
  // write error
  if FWriteExceptions then begin
    {$IFDEF CTDEBUG}
    WriteDebugReport(true,false,false,false,false);
    {$ENDIF}
    write('### TCodeToolManager.HandleException: "'+ErrorMessage+'"');
    if ErrorLine>0 then write(' at Line=',ErrorLine);
    if ErrorColumn>0 then write(' Col=',ErrorColumn);
    if ErrorCode<>nil then write(' in "',ErrorCode.Filename,'"');
    DebugLn('');
  end;
  // raise or catch
  if not FCatchExceptions then raise AnException;
  Result:=false;
end;

function TCodeToolManager.CheckSyntax(Code: TCodeBuffer;
  var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer;
  var ErrorMsg: string): boolean;
// returns true on syntax correct
var
  ACodeTool: TCodeTool;
begin
  Result:=Explore(Code,ACodeTool,true);
  NewCode:=ErrorCode;
  NewX:=ErrorColumn;
  NewY:=ErrorLine;
  NewTopLine:=ErrorTopLine;
  ErrorMsg:=ErrorMessage;
end;

function TCodeToolManager.JumpToMethod(Code: TCodeBuffer; X,Y: integer;
  var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer;
  var RevertableJump: boolean): boolean;
var
  CursorPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.JumpToMethod A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.JumpToMethod B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    Result:=FCurCodeTool.FindJumpPoint(CursorPos,NewPos,NewTopLine,
                                       RevertableJump);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.JumpToMethod END ');
  {$ENDIF}
end;

function TCodeToolManager.FindDeclaration(Code: TCodeBuffer; X,Y: integer;
  var NewCode: TCodeBuffer;
  var NewX, NewY, NewTopLine: integer): boolean;
var
  CursorPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclaration A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclaration B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    {$IFDEF DoNotHandleFindDeclException}
    DebugLn('TCodeToolManager.FindDeclaration NOT HANDLING EXCEPTIONS');
    RaiseUnhandableExceptions:=true;
    {$ENDIF}
    Result:=FCurCodeTool.FindDeclaration(CursorPos,NewPos,NewTopLine);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  {$IFDEF DoNotHandleFindDeclException}
  finally
    RaiseUnhandableExceptions:=false;
  end;
  {$ELSE}
  except
    on e: Exception do Result:=HandleException(e);
  end;
  {$ENDIF}
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclaration END ');
  {$ENDIF}
end;

function TCodeToolManager.FindSmartHint(Code: TCodeBuffer; X, Y: integer
  ): string;
var
  CursorPos: TCodeXYPosition;
begin
  Result:='';
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindSmartHint A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindSmartHint B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    Result:=FCurCodeTool.FindSmartHint(CursorPos);
  except
    on e: Exception do HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindSmartHint END ');
  {$ENDIF}
end;

function TCodeToolManager.FindDeclarationInInterface(Code: TCodeBuffer;
  const Identifier: string; var NewCode: TCodeBuffer; var NewX, NewY,
  NewTopLine: integer): boolean;
var
  NewPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclarationInInterface A ',Code.Filename,' Identifier=',Identifier);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclarationInInterface B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    Result:=FCurCodeTool.FindDeclarationInInterface(Identifier,NewPos,
                                                    NewTopLine);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclarationInInterface END ');
  {$ENDIF}
end;

function TCodeToolManager.FindDeclarationsAndAncestors(Code: TCodeBuffer; X,
  Y: integer; var ListOfPCodeXYPosition: TList): boolean;
var
  CursorPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclarationsAndAncestors A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclarationsAndAncestors B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    Result:=FCurCodeTool.FindDeclarationsAndAncestors(CursorPos,
                                                      ListOfPCodeXYPosition);
  except
    on e: Exception do Result:=HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindDeclarationsAndAncestors END ');
  {$ENDIF}
end;

function TCodeToolManager.GatherIdentifiers(Code: TCodeBuffer; X, Y: integer
  ): boolean;
var
  CursorPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GatherIdentifiers A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GatherIdentifiers B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    Result:=FCurCodeTool.GatherIdentifiers(CursorPos,IdentifierList,
                      SourceChangeCache.BeautifyCodeOptions);
  except
    on e: Exception do HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GatherIdentifiers END ');
  {$ENDIF}
end;

function TCodeToolManager.GetIdentifierAt(Code: TCodeBuffer; X, Y: integer;
  var Identifier: string): boolean;
var
  CleanPos: integer;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetIdentifierAt A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  Code.LineColToPosition(Y,X,CleanPos);
  if (CleanPos>0) and (CleanPos<=Code.SourceLength) then begin
    Identifier:=GetIdentifier(@Code.Source[CleanPos]);
    Result:=true;
  end else begin
    Identifier:='';
    Result:=false;
  end;
end;

function TCodeToolManager.GatherResourceStringSections(Code: TCodeBuffer;
  X, Y: integer; CodePositions: TCodeXYPositions): boolean;
var
  CursorPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GatherResourceStringSections A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  if CodePositions=nil then begin
    ClearPositions;
    CodePositions:=Positions;
  end;
  try
    Result:=FCurCodeTool.GatherResourceStringSections(CursorPos,CodePositions);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.IdentifierExistsInResourceStringSection(
  Code: TCodeBuffer; X, Y: integer; const ResStrIdentifier: string): boolean;
var
  CursorPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.IdentifierExistsInResourceStringSection A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  try
    Result:=FCurCodeTool.IdentifierExistsInResourceStringSection(CursorPos,
                                                              ResStrIdentifier);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.CreateIdentifierFromStringConst(
  StartCode: TCodeBuffer; StartX, StartY: integer;
  EndCode: TCodeBuffer; EndX, EndY: integer;
  var Identifier: string; MaxLen: integer): boolean;
var
  StartCursorPos, EndCursorPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.CreateIdentifierFromStringConst A ',StartCode.Filename,' x=',StartX,' y=',StartY);
  {$ENDIF}
  if not InitCurCodeTool(StartCode) then exit;
  StartCursorPos.X:=StartX;
  StartCursorPos.Y:=StartY;
  StartCursorPos.Code:=StartCode;
  EndCursorPos.X:=EndX;
  EndCursorPos.Y:=EndY;
  EndCursorPos.Code:=EndCode;
  Identifier:='';
  try
    Result:=FCurCodeTool.CreateIdentifierFromStringConst(
                                 StartCursorPos,EndCursorPos,Identifier,MaxLen);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.StringConstToFormatString(
  StartCode: TCodeBuffer; StartX, StartY: integer;
  EndCode: TCodeBuffer; EndX, EndY: integer;
  var FormatStringConstant, FormatParameters: string): boolean;
var
  StartCursorPos, EndCursorPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.StringConstToFormatString A ',StartCode.Filename,' x=',StartX,' y=',StartY);
  {$ENDIF}
  if not InitCurCodeTool(StartCode) then exit;
  StartCursorPos.X:=StartX;
  StartCursorPos.Y:=StartY;
  StartCursorPos.Code:=StartCode;
  EndCursorPos.X:=EndX;
  EndCursorPos.Y:=EndY;
  EndCursorPos.Code:=EndCode;
  try
    Result:=FCurCodeTool.StringConstToFormatString(
             StartCursorPos,EndCursorPos,FormatStringConstant,FormatParameters);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.GatherResourceStringsWithValue(
  SectionCode: TCodeBuffer; SectionX, SectionY: integer;
  const StringValue: string; CodePositions: TCodeXYPositions): boolean;
var
  CursorPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GatherResourceStringsWithValue A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(SectionCode) then exit;
  CursorPos.X:=SectionX;
  CursorPos.Y:=SectionY;
  CursorPos.Code:=SectionCode;
  if CodePositions=nil then begin
    ClearPositions;
    CodePositions:=Positions;
  end;
  try
    Result:=FCurCodeTool.GatherResourceStringsWithValue(CursorPos,StringValue,
                                                        CodePositions);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.AddResourcestring(
  CursorCode: TCodeBuffer; X,Y: integer;
  SectionCode: TCodeBuffer; SectionX, SectionY: integer;
  const NewIdentifier, NewValue: string;
  InsertPolicy: TResourcestringInsertPolicy): boolean;
var
  CursorPos, SectionPos, NearestPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.AddResourcestring A ',SectionCode.Filename,' x=',Sectionx,' y=',Sectiony);
  {$ENDIF}
  if not InitCurCodeTool(SectionCode) then exit;
  SectionPos.X:=SectionX;
  SectionPos.Y:=SectionY;
  SectionPos.Code:=SectionCode;
  try
    NearestPos.Code:=nil;
    if InsertPolicy=rsipContext then begin
      CursorPos.X:=X;
      CursorPos.Y:=Y;
      CursorPos.Code:=CursorCode;
      Result:=FCurCodeTool.FindNearestResourceString(CursorPos, SectionPos,
                                                     NearestPos);
      if not Result then exit;
    end;
    Result:=FCurCodeTool.AddResourcestring(SectionPos, NewIdentifier, NewValue,
                                     InsertPolicy,NearestPos,SourceChangeCache);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.GetStringConstBounds(Code: TCodeBuffer; X, Y: integer;
  var StartCode: TCodeBuffer; var StartX, StartY: integer;
  var EndCode: TCodeBuffer; var EndX, EndY: integer;
  ResolveComments: boolean): boolean;
var
  CursorPos, StartPos, EndPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetStringConstBounds A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  try
    Result:=FCurCodeTool.GetStringConstBounds(CursorPos,StartPos,EndPos,
                                              ResolveComments);
    if Result then begin
      StartCode:=StartPos.Code;
      StartX:=StartPos.X;
      StartY:=StartPos.Y;
      EndCode:=EndPos.Code;
      EndX:=EndPos.X;
      EndY:=EndPos.Y;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.ReplaceCode(Code: TCodeBuffer; StartX,
  StartY: integer; EndX, EndY: integer; const NewCode: string): boolean;
var
  StartCursorPos, EndCursorPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.ReplaceCode A ',StartCode.Filename,' x=',StartX,' y=',StartY);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  StartCursorPos.X:=StartX;
  StartCursorPos.Y:=StartY;
  StartCursorPos.Code:=Code;
  EndCursorPos.X:=EndX;
  EndCursorPos.Y:=EndY;
  EndCursorPos.Code:=Code;
  try
    Result:=FCurCodeTool.ReplaceCode(StartCursorPos,EndCursorPos,NewCode,
                                     SourceChangeCache);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.GuessMisplacedIfdefEndif(Code: TCodeBuffer; X,Y: integer;
  var NewCode: TCodeBuffer;
  var NewX, NewY, NewTopLine: integer): boolean;
var
  CursorPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GuessMisplacedIfdefEndif A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  try
    Result:=FCurCodeTool.GuessMisplacedIfdefEndif(CursorPos,NewPos,NewTopLine);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.FindEnclosingIncludeDirective(Code: TCodeBuffer; X,
  Y: integer; var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer
  ): boolean;
var
  CursorPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindEnclosingIncludeDirective A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  try
    Result:=FCurCodeTool.FindEnclosingIncludeDirective(CursorPos,
                                                       NewPos,NewTopLine);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.IsKeyword(Code: TCodeBuffer; const KeyWord: string
  ): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.IsKeyword A ',Code.Filename,' Keyword=',KeyWord);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.StringIsKeyWord(KeyWord);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.ExtractCodeWithoutComments(Code: TCodeBuffer): string;
begin
  Result:=CleanCodeFromComments(Code.Source,
                                GetNestedCommentsFlagForFile(Code.Filename));
end;

function TCodeToolManager.FindBlockCounterPart(Code: TCodeBuffer;
  X, Y: integer; var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer
  ): boolean;
var
  CursorPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindBlockCounterPart A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindBlockCounterPart B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    Result:=FCurCodeTool.FindBlockCounterPart(CursorPos,NewPos,NewTopLine);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindBlockCounterPart END ');
  {$ENDIF}
end;

function TCodeToolManager.FindBlockStart(Code: TCodeBuffer;
  X, Y: integer; var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer
  ): boolean;
var
  CursorPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindBlockStart A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindBlockStart B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    Result:=FCurCodeTool.FindBlockStart(CursorPos,NewPos,NewTopLine);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindBlockStart END ');
  {$ENDIF}
end;

function TCodeToolManager.GuessUnclosedBlock(Code: TCodeBuffer; X, Y: integer;
  var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer): boolean;
var
  CursorPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GuessUnclosedBlock A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GuessUnclosedBlock B ',FCurCodeTool.Scanner<>nil);
  {$ENDIF}
  try
    Result:=FCurCodeTool.GuessUnclosedBlock(CursorPos,NewPos,NewTopLine);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GuessUnclosedBlock END ');
  {$ENDIF}
end;

function TCodeToolManager.GetCompatiblePublishedMethods(Code: TCodeBuffer;
  const AClassName: string; TypeData: PTypeData; Proc: TGetStringProc): boolean;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetCompatiblePublishedMethods A ',Code.Filename,' Classname=',AClassname);
  {$ENDIF}
  Result:=InitCurCodeTool(Code);
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.GetCompatiblePublishedMethods(UpperCaseStr(AClassName),
       TypeData,Proc);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.PublishedMethodExists(Code:TCodeBuffer;
  const AClassName, AMethodName: string; TypeData: PTypeData;
  var MethodIsCompatible, MethodIsPublished, IdentIsMethod: boolean): boolean;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.PublishedMethodExists A ',Code.Filename,' ',AClassName,':',AMethodName);
  {$ENDIF}
  Result:=InitCurCodeTool(Code);
  if not Result then exit;
  try
    Result:=FCurCodeTool.PublishedMethodExists(UpperCaseStr(AClassName),
              UpperCaseStr(AMethodName),TypeData,
              MethodIsCompatible,MethodIsPublished,IdentIsMethod);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.JumpToPublishedMethodBody(Code: TCodeBuffer;
  const AClassName, AMethodName: string;
  var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer): boolean;
var NewPos: TCodeXYPosition;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.JumpToPublishedMethodBody A ',Code.Filename,' ',AClassName,':',AMethodName);
  {$ENDIF}
  Result:=InitCurCodeTool(Code);
  if not Result then exit;
  try
    Result:=FCurCodeTool.JumpToPublishedMethodBody(UpperCaseStr(AClassName),
              UpperCaseStr(AMethodName),NewPos,NewTopLine);
    if Result then begin
      NewCode:=NewPos.Code;
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RenamePublishedMethod(Code: TCodeBuffer;
  const AClassName, OldMethodName, NewMethodName: string): boolean;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RenamePublishedMethod A');
  {$ENDIF}
  Result:=InitCurCodeTool(Code);
  if not Result then exit;
  try
    SourceChangeCache.Clear;
    Result:=FCurCodeTool.RenamePublishedMethod(UpperCaseStr(AClassName),
              UpperCaseStr(OldMethodName),NewMethodName,
              SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.CreatePublishedMethod(Code: TCodeBuffer;
  const AClassName, NewMethodName: string; ATypeInfo: PTypeInfo): boolean;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.CreatePublishedMethod A');
  {$ENDIF}
  Result:=InitCurCodeTool(Code);
  if not Result then exit;
  try
    SourceChangeCache.Clear;
    Result:=FCurCodeTool.CreatePublishedMethod(UpperCaseStr(AClassName),
              NewMethodName,ATypeInfo,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.GetIDEDirectives(Code: TCodeBuffer;
  DirectiveList: TStrings): boolean;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetIDEDirectives A ',Code.Filename);
  {$ENDIF}
  Result:=false;
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.GetIDEDirectives(DirectiveList);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.SetIDEDirectives(Code: TCodeBuffer;
  DirectiveList: TStrings): boolean;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetIDEDirectives A ',Code.Filename);
  {$ENDIF}
  Result:=false;
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.SetIDEDirectives(DirectiveList,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.CompleteCode(Code: TCodeBuffer; X,Y,TopLine: integer;
  var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer): boolean;
var
  CursorPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.CompleteCode A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  Result:=false;
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=X;
  CursorPos.Y:=Y;
  CursorPos.Code:=Code;
  try
    Result:=FCurCodeTool.CompleteCode(CursorPos,TopLine,
                                           NewPos,NewTopLine,SourceChangeCache);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.CheckExtractProc(Code: TCodeBuffer; const StartPoint,
  EndPoint: TPoint; var MethodPossible, SubProcSameLvlPossible: boolean): boolean;
var
  StartPos, EndPos: TCodeXYPosition;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.CheckExtractProc A ',Code.Filename);
  {$ENDIF}
  Result:=false;
  if not InitCurCodeTool(Code) then exit;
  StartPos.X:=StartPoint.X;
  StartPos.Y:=StartPoint.Y;
  StartPos.Code:=Code;
  EndPos.X:=EndPoint.X;
  EndPos.Y:=EndPoint.Y;
  EndPos.Code:=Code;
  try
    Result:=FCurCodeTool.CheckExtractProc(StartPos,EndPos,MethodPossible,
                                          SubProcSameLvlPossible);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.ExtractProc(Code: TCodeBuffer; const StartPoint,
  EndPoint: TPoint; ProcType: TExtractProcType; const ProcName: string;
  var NewCode: TCodeBuffer; var NewX, NewY, NewTopLine: integer): boolean;
var
  StartPos, EndPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.ExtractProc A ',Code.Filename);
  {$ENDIF}
  Result:=false;
  if not InitCurCodeTool(Code) then exit;
  StartPos.X:=StartPoint.X;
  StartPos.Y:=StartPoint.Y;
  StartPos.Code:=Code;
  EndPos.X:=EndPoint.X;
  EndPos.Y:=EndPoint.Y;
  EndPos.Code:=Code;
  try
    Result:=FCurCodeTool.ExtractProc(StartPos,EndPos,ProcType,ProcName,
                                     NewPos,NewTopLine,SourceChangeCache);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.InsertCodeTemplate(Code: TCodeBuffer;
  SelectionStart, SelectionEnd: TPoint; TopLine: integer;
  CodeTemplate: TCodeToolTemplate; var NewCode: TCodeBuffer; var NewX, NewY,
  NewTopLine: integer): boolean;
var
  CursorPos: TCodeXYPosition;
  EndPos: TCodeXYPosition;
  NewPos: TCodeXYPosition;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.InsertCodeTemplate A ',Code.Filename,' x=',x,' y=',y);
  {$ENDIF}
  Result:=false;
  if not InitCurCodeTool(Code) then exit;
  CursorPos.X:=SelectionStart.X;
  CursorPos.Y:=SelectionStart.Y;
  CursorPos.Code:=Code;
  EndPos.X:=SelectionStart.X;
  EndPos.Y:=SelectionStart.Y;
  EndPos.Code:=Code;
  try
    Result:=FCurCodeTool.InsertCodeTemplate(CursorPos,EndPos,TopLine,
                              CodeTemplate,NewPos,NewTopLine,SourceChangeCache);
    if Result then begin
      NewX:=NewPos.X;
      NewY:=NewPos.Y;
      NewCode:=NewPos.Code;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.GetSourceName(Code: TCodeBuffer;
  SearchMainCode: boolean): string;
begin
  Result:='';
  if (Code=nil)
  or ((not SearchMainCode) and (Code.LastIncludedByFile<>'')) then exit;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetSourceName A ',Code.Filename,' ',Code.SourceLength);
  {$ENDIF}
  {$IFDEF MEM_CHECK}
  CheckHeap(IntToStr(GetMem_Cnt));
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.GetSourceName;
  except
    on e: Exception do HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetSourceName B ',Code.Filename,' ',Code.SourceLength);
  {$IFDEF MEM_CHECK}
  CheckHeap(IntToStr(GetMem_Cnt));
  {$ENDIF}
  DebugLn('SourceName=',Result);
  {$ENDIF}
end;

function TCodeToolManager.GetCachedSourceName(Code: TCodeBuffer): string;
begin
  Result:='';
  if (Code=nil)
  or (Code.LastIncludedByFile<>'') then exit;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetCachedSourceName A ',Code.Filename,' ',Code.SourceLength);
  {$ENDIF}
  {$IFDEF MEM_CHECK}
  CheckHeap(IntToStr(GetMem_Cnt));
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.GetCachedSourceName;
  except
    on e: Exception do HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetCachedSourceName B ',Code.Filename,' ',Code.SourceLength);
  {$IFDEF MEM_CHECK}
  CheckHeap(IntToStr(GetMem_Cnt));
  {$ENDIF}
  DebugLn('SourceName=',Result);
  {$ENDIF}
end;

function TCodeToolManager.GetSourceType(Code: TCodeBuffer;
  SearchMainCode: boolean): string;
begin
  Result:='';
  if (Code=nil)
  or ((not SearchMainCode) and (Code.LastIncludedByFile<>'')) then exit;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetSourceType A ',Code.Filename,' ',Code.SourceLength);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    // GetSourceType does not parse the code -> parse it with GetSourceName
    FCurCodeTool.GetSourceName;
    case FCurCodeTool.GetSourceType of
      ctnProgram: Result:='PROGRAM';
      ctnPackage: Result:='PACKAGE';
      ctnLibrary: Result:='LIBRARY';
      ctnUnit: Result:='UNIT';
    else
      Result:='';
    end;
  except
    on e: Exception do HandleException(e);
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetSourceType END ',Code.Filename,',',Code.SourceLength);
  {$IFDEF MEM_CHECK}
  CheckHeap(IntToStr(GetMem_Cnt));
  {$ENDIF}
  DebugLn('SourceType=',Result);
  {$ENDIF}
end;

function TCodeToolManager.RenameSource(Code: TCodeBuffer;
  const NewName: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RenameSource A ',Code.Filename,' NewName=',NewName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RenameSource(NewName,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.FindUnitInAllUsesSections(Code: TCodeBuffer;
  const AnUnitName: string;
  var NamePos, InPos: integer): boolean;
var NameAtomPos, InAtomPos: TAtomPosition;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindUnitInAllUsesSections A ',Code.Filename,' UnitName=',AnUnitName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindUnitInAllUsesSections B ',Code.Filename,' UnitName=',AnUnitName);
  {$ENDIF}
  try
    Result:=FCurCodeTool.FindUnitInAllUsesSections(UpperCaseStr(AnUnitName),
                NameAtomPos, InAtomPos);
    if Result then begin
      NamePos:=NameAtomPos.StartPos;
      InPos:=InAtomPos.StartPos;
    end;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RenameUsedUnit(Code: TCodeBuffer;
  const OldUnitName, NewUnitName, NewUnitInFile: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RenameUsedUnit A, ',Code.Filename,' Old=',OldUnitName,' New=',NewUnitName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RenameUsedUnit(UpperCaseStr(OldUnitName),NewUnitName,
                  NewUnitInFile,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.AddUnitToMainUsesSection(Code: TCodeBuffer;
  const NewUnitName, NewUnitInFile: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.AddUnitToMainUsesSection A ',Code.Filename,' NewUnitName=',NewUnitName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.AddUnitToMainUsesSection(NewUnitName, NewUnitInFile,
                    SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RemoveUnitFromAllUsesSections(Code: TCodeBuffer;
  const AnUnitName: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RemoveUnitFromAllUsesSections A ',Code.Filename,' UnitName=',AnUnitName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RemoveUnitFromAllUsesSections(UpperCaseStr(AnUnitName),
                SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.FindUsedUnitFiles(Code: TCodeBuffer;
  var MainUsesSection, ImplementationUsesSection: TStrings): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindUsedUnits A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.FindUsedUnitFiles(MainUsesSection,
                                           ImplementationUsesSection);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.FindUsedUnitNames(Code: TCodeBuffer;
  var MainUsesSection, ImplementationUsesSection: TStrings): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindUsedUnits A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.FindUsedUnitNames(MainUsesSection,
                                           ImplementationUsesSection);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.FindLFMFileName(Code: TCodeBuffer): string;
var LinkIndex: integer;
  CurCode: TCodeBuffer;
  Ext: string;
begin
  Result:='';
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindLFMFileName A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    LinkIndex:=-1;
    CurCode:=FCurCodeTool.FindNextIncludeInInitialization(LinkIndex);
    while (CurCode<>nil) do begin
      if UpperCaseStr(ExtractFileExt(CurCode.Filename))='.LRS' then begin
        Result:=CurCode.Filename;
        Ext:=ExtractFileExt(Result);
        Result:=copy(Result,1,length(Result)-length(Ext))+'.lfm';
        exit;
      end;
      CurCode:=FCurCodeTool.FindNextIncludeInInitialization(LinkIndex);
    end;
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.CheckLFM(UnitCode, LFMBuf: TCodeBuffer;
  var LFMTree: TLFMTree; RootMustBeClassInIntf, ObjectsMustExists: boolean
  ): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.CheckLFM A ',UnitCode.Filename,' ',LFMBuf.Filename);
  {$ENDIF}
  if not InitCurCodeTool(UnitCode) then exit;
  try
    Result:=FCurCodeTool.CheckLFM(LFMBuf,LFMTree,OnGetDefineProperties,
                                  RootMustBeClassInIntf,ObjectsMustExists);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.FindNextResourceFile(Code: TCodeBuffer;
  var LinkIndex: integer): TCodeBuffer;
begin
  Result:=nil;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindNextResourceFile A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.FindNextIncludeInInitialization(LinkIndex);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.AddLazarusResourceHeaderComment(Code: TCodeBuffer;
  const CommentText: string): boolean;
begin
  Result:=false;
  if not InitResourceTool then exit;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.AddLazarusResourceHeaderComment A ',Code.Filename,' CommentText=',CommentText);
  {$ENDIF}
  try
    Result:=GetResourceTool.AddLazarusResourceHeaderComment(Code,
      '{ '+CommentText+' }'+SourceChangeCache.BeautifyCodeOptions.LineEnd
      +SourceChangeCache.BeautifyCodeOptions.LineEnd);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.FindLazarusResource(Code: TCodeBuffer;
  const ResourceName: string): TAtomPosition;
begin
  Result.StartPos:=-1;
  if not InitResourceTool then exit;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindLazarusResource A ',Code.Filename,' ResourceName=',ResourceName);
  {$ENDIF}
  try
    Result:=GetResourceTool.FindLazarusResource(Code,ResourceName,-1);
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.AddLazarusResource(Code: TCodeBuffer;
  const ResourceName, ResourceData: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.AddLazarusResource A ',Code.Filename,' ResourceName=',ResourceName,' ',length(ResourceData));
  {$ENDIF}
  if not InitResourceTool then exit;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.AddLazarusResource B ');
  {$ENDIF}
  try
    Result:=GetResourceTool.AddLazarusResource(Code,ResourceName,ResourceData);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RemoveLazarusResource(Code: TCodeBuffer;
  const ResourceName: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RemoveLazarusResource A ',Code.Filename,' ResourceName=',ResourceName);
  {$ENDIF}
  if not InitResourceTool then exit;
  try
    Result:=GetResourceTool.RemoveLazarusResource(Code,ResourceName);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RenameMainInclude(Code: TCodeBuffer;
  const NewFilename: string; KeepPath: boolean): boolean;
var
  LinkIndex: integer;
  OldIgnoreMissingIncludeFiles: boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RenameMainInclude A ',Code.Filename,' NewFilename=',NewFilename,' KeepPath=',KeepPath);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    OldIgnoreMissingIncludeFiles:=
      FCurCodeTool.Scanner.IgnoreMissingIncludeFiles;
    FCurCodeTool.Scanner.IgnoreMissingIncludeFiles:=true;
    LinkIndex:=-1;
    if FCurCodeTool.FindNextIncludeInInitialization(LinkIndex)=nil then exit;
    Result:=FCurCodeTool.RenameInclude(LinkIndex,NewFilename,KeepPath,
                       SourceChangeCache);
    FCurCodeTool.Scanner.IgnoreMissingIncludeFiles:=
      OldIgnoreMissingIncludeFiles;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RenameIncludeDirective(Code: TCodeBuffer;
  LinkIndex: integer; const NewFilename: string; KeepPath: boolean): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RenameIncludeDirective A ',Code.Filename,' NewFilename=',NewFilename,' KeepPath=',KeepPath);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RenameInclude(LinkIndex,NewFilename,KeepPath,
                                       SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

procedure TCodeToolManager.DefaultGetDefineProperties(Sender: TObject;
  const ClassContext: TFindContext; LFMNode: TLFMTreeNode;
  const IdentName: string; var DefineProperties: TStrings);
var
  ComponentClassName: String;
begin
  if Assigned(OnGetDefinePropertiesForClass) then begin
    ComponentClassName:=ClassContext.Tool.ExtractClassName(
                                                       ClassContext.Node,false);
    OnGetDefinePropertiesForClass(ClassContext.Tool,ComponentClassName,
                                  DefineProperties);
  end;
end;

function TCodeToolManager.FindCreateFormStatement(Code: TCodeBuffer;
  StartPos: integer;
  const AClassName, AVarName: string;
  var Position: integer): integer;
// 0=found, -1=not found, 1=found, but wrong classname
var PosAtom: TAtomPosition;
begin
  Result:=-1;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindCreateFormStatement A ',Code.Filename,' StartPos=',StartPos,' ',AClassName,':',AVarName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.FindCreateFormStatement(StartPos,UpperCaseStr(AClassName),
                 UpperCaseStr(AVarName),PosAtom);
    if Result<>-1 then
      Position:=PosAtom.StartPos;
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.AddCreateFormStatement(Code: TCodeBuffer;
  const AClassName, AVarName: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.AddCreateFormStatement A ',Code.Filename,' ',AClassName,':',AVarName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.AddCreateFormStatement(AClassName,AVarName,
                    SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RemoveCreateFormStatement(Code: TCodeBuffer;
  const AVarName: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RemoveCreateFormStatement A ',Code.Filename,' ',AVarName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RemoveCreateFormStatement(UpperCaseStr(AVarName),
                    SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.ChangeCreateFormStatement(Code: TCodeBuffer;
  const OldClassName, OldVarName: string; const NewClassName,
  NewVarName: string; OnlyIfExists: boolean): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.ChangeCreateFormStatement A ',Code.Filename,
    ' ',OldVarName.':',OldClassName,' -> ',NewVarName.':',NewClassName,
    ' OnlyIfExists=',OnlyIfExists);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.ChangeCreateFormStatement(-1,OldClassName,OldVarName,
                    NewClassName,NewVarName,true,
                    SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.ListAllCreateFormStatements(
  Code: TCodeBuffer): TStrings;
begin
  Result:=nil;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.ListAllCreateFormStatements A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.ListAllCreateFormStatements;
  except
    on e: Exception do HandleException(e);
  end;
end;

function TCodeToolManager.SetAllCreateFromStatements(Code: TCodeBuffer; 
  List: TStrings): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.SetAllCreateFromStatements A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.SetAllCreateFromStatements(List,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.GetApplicationTitleStatement(Code: TCodeBuffer;
  var Title: string): boolean;
var
  StartPos, StringConstStartPos, EndPos: integer;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.GetApplicationTitleStatement A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.FindApplicationTitleStatement(StartPos,
                                                    StringConstStartPos,EndPos);
    Result:=FCurCodeTool.GetApplicationTitleStatement(StringConstStartPos,
                                                      EndPos,Title);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.SetApplicationTitleStatement(Code: TCodeBuffer;
  const NewTitle: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.SetApplicationTitleStatement A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.SetApplicationTitleStatement(NewTitle,
                                                      SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RemoveApplicationTitleStatement(Code: TCodeBuffer
  ): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RemoveApplicationTitleStatement A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RemoveApplicationTitleStatement(SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RenameForm(Code: TCodeBuffer; const OldFormName,
  OldFormClassName: string; const NewFormName, NewFormClassName: string
  ): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RenameForm A ',Code.Filename,
    ' OldFormName=',OldFormName,' OldFormClassName=',OldFormClassName,
    ' NewFormName=',NewFormName,' NewFormClassName=',NewFormClassName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RenameForm(OldFormName,OldFormClassName,
                                NewFormName,NewFormClassName,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.FindFormAncestor(Code: TCodeBuffer;
  const FormClassName: string; var AncestorClassName: string;
  DirtySearch: boolean): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.FindFormAncestor A ',Code.Filename,' ',FormClassName);
  {$ENDIF}
  AncestorClassName:='';
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.FindFormAncestor(UpperCaseStr(FormClassName),
                                          AncestorClassName);
  except
    on e: Exception do Result:=HandleException(e);
  end;
  if (not Result) and DirtySearch then begin
    AncestorClassName:=FindClassAncestorName(Code.Source,FormClassName);
    Result:=AncestorClassName<>'';
  end;
end;

function TCodeToolManager.CompleteComponent(Code: TCodeBuffer;
  AComponent: TComponent): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.CompleteComponent A ',Code.Filename,' ',AComponent.Name,':',AComponent.ClassName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.CompleteComponent(AComponent,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.PublishedVariableExists(Code: TCodeBuffer;
  const AClassName, AVarName: string; ErrorOnClassNotFound: boolean): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.PublishedVariableExists A ',Code.Filename,' ',AClassName,':',AVarName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.FindPublishedVariable(UpperCaseStr(AClassName),
                 UpperCaseStr(AVarName),ErrorOnClassNotFound)<>nil;
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.AddPublishedVariable(Code: TCodeBuffer;
  const AClassName, VarName, VarType: string): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.AddPublishedVariable A ',Code.Filename,' ',AClassName,':',VarName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.AddPublishedVariable(UpperCaseStr(AClassName),
                      VarName,VarType,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RemovePublishedVariable(Code: TCodeBuffer;
  const AClassName, AVarName: string; ErrorOnClassNotFound: boolean): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RemovePublishedVariable A ',Code.Filename,' ',AClassName,':',AVarName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RemovePublishedVariable(UpperCaseStr(AClassName),
               UpperCaseStr(AVarName),ErrorOnClassNotFound,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.RenamePublishedVariable(Code: TCodeBuffer;
  const AClassName, OldVariableName, NewVarName, VarType: shortstring;
  ErrorOnClassNotFound: boolean): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.RenamePublishedVariable A ',Code.Filename,' ',AClassName,' OldVar=',OldVarName,' NewVar=',NewVarName);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.RenamePublishedVariable(UpperCaseStr(AClassName),
               UpperCaseStr(OldVariableName),NewVarName,VarType,
               ErrorOnClassNotFound,SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.HasInterfaceRegisterProc(Code: TCodeBuffer;
  var HasRegisterProc: boolean): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.HasInterfaceRegisterProc A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.HasInterfaceRegisterProc(HasRegisterProc);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.ConvertDelphiToLazarusSource(Code: TCodeBuffer;
  AddLRSCode: boolean): boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeToolManager.ConvertDelphiToLazarusSource A ',Code.Filename);
  {$ENDIF}
  if not InitCurCodeTool(Code) then exit;
  try
    Result:=FCurCodeTool.ConvertDelphiToLazarusSource(AddLRSCode,
                                                      SourceChangeCache);
  except
    on e: Exception do Result:=HandleException(e);
  end;
end;

function TCodeToolManager.DoOnFindUsedUnit(SrcTool: TFindDeclarationTool;
  const TheUnitName, TheUnitInFilename: string): TCodeBuffer;
begin
  if Assigned(OnSearchUsedUnit) then
    Result:=OnSearchUsedUnit(SrcTool.MainFilename,
                             TheUnitName,TheUnitInFilename)
  else
    Result:=nil;
end;

function TCodeToolManager.DoOnGetSrcPathForCompiledUnit(Sender: TObject;
  const AFilename: string): string;
begin
  if CompareFileExt(AFilename,'.ppu',false)=0 then
    Result:=GetPPUSrcPathForDirectory(ExtractFilePath(AFilename))
  else if CompareFileExt(AFilename,'.ppw',false)=0 then
    Result:=GetPPWSrcPathForDirectory(ExtractFilePath(AFilename))
  else if CompareFileExt(AFilename,'.dcu',false)=0 then
    Result:=GetDCUSrcPathForDirectory(ExtractFilePath(AFilename));
  if Result='' then
    Result:=GetCompiledSrcPathForDirectory(ExtractFilePath(AFilename));
end;

function TCodeToolManager.OnParserProgress(Tool: TCustomCodeTool): boolean;
begin
  Result:=true;
  if not FAbortable then exit;
  if not Assigned(OnCheckAbort) then exit;
  Result:=not OnCheckAbort();
end;

function TCodeToolManager.OnScannerProgress(Sender: TLinkScanner): boolean;
begin
  Result:=true;
  if not FAbortable then exit;
  if not Assigned(OnCheckAbort) then exit;
  Result:=not OnCheckAbort();
end;

function TCodeToolManager.OnScannerGetInitValues(Code: Pointer;
  var AChangeStep: integer): TExpressionEvaluator;
begin
  Result:=nil;
  AChangeStep:=DefineTree.ChangeStep;
  if Code=nil then exit;
  //DefineTree.WriteDebugReport;
  if not TCodeBuffer(Code).IsVirtual then
    Result:=DefineTree.GetDefinesForDirectory(
      ExtractFilePath(TCodeBuffer(Code).Filename),false)
  else
    Result:=DefineTree.GetDefinesForVirtualDirectory;
end;

procedure TCodeToolManager.OnDefineTreeReadValue(Sender: TObject;
  const VariableName: string; var Value: string; var Handled: boolean);
begin
  Handled:=GlobalValues.IsDefined(VariableName);
  if Handled then
    Value:=GlobalValues[VariableName];
  //DebugLn('[TCodeToolManager.OnDefineTreeReadValue] Name="',VariableName,'" = "',Value,'"');
end;

procedure TCodeToolManager.OnGlobalValuesChanged;
begin
  DefineTree.ClearCache;
end;

procedure TCodeToolManager.SetCheckFilesOnDisk(NewValue: boolean);
begin
  if NewValue=FCheckFilesOnDisk then exit;
  FCheckFilesOnDisk:=NewValue;
  if FCurCodeTool<>nil then
    FCurCodeTool.CheckFilesOnDisk:=NewValue;
end;

procedure TCodeToolManager.SetCompleteProperties(const AValue: boolean);
begin
  if CompleteProperties=AValue then exit;
  FCompleteProperties:=AValue;
  if FCurCodeTool<>nil then
    FCurCodeTool.CompleteProperties:=AValue;
end;

procedure TCodeToolManager.SetIndentSize(NewValue: integer);
begin
  if NewValue=FIndentSize then exit;
  FIndentSize:=NewValue;
  if FCurCodeTool<>nil then
    FCurCodeTool.IndentSize:=NewValue;
  SourceChangeCache.BeautifyCodeOptions.Indent:=NewValue;
end;

procedure TCodeToolManager.SetTabWidth(const AValue: integer);
begin
  if FTabWidth=AValue then exit;
  FTabWidth:=AValue;
  SourceChangeCache.BeautifyCodeOptions.TabWidth:=AValue;
end;

procedure TCodeToolManager.SetVisibleEditorLines(NewValue: integer);
begin
  if NewValue=FVisibleEditorLines then exit;
  FVisibleEditorLines:=NewValue;
  if FCurCodeTool<>nil then
    FCurCodeTool.VisibleEditorLines:=NewValue;
end;

procedure TCodeToolManager.SetJumpCentered(NewValue: boolean);
begin
  if NewValue=FJumpCentered then exit;
  FJumpCentered:=NewValue;
  if FCurCodeTool<>nil then
    FCurCodeTool.JumpCentered:=NewValue;
end;

procedure TCodeToolManager.SetCursorBeyondEOL(NewValue: boolean);
begin
  if NewValue=FCursorBeyondEOL then exit;
  FCursorBeyondEOL:=NewValue;
  if FCurCodeTool<>nil then
    FCurCodeTool.CursorBeyondEOL:=NewValue;
end;

procedure TCodeToolManager.BeforeApplyingChanges(var Abort: boolean);
begin
  if Assigned(FOnBeforeApplyChanges) then
    FOnBeforeApplyChanges(Self,Abort);
end;

procedure TCodeToolManager.AfterApplyingChanges;
begin
  // clear all codetrees of changed buffers
  if FCurCodeTool<>nil then
    FCurCodeTool.Clear;
    
  // user callback
  if Assigned(FOnAfterApplyChanges) then
    FOnAfterApplyChanges(Self);
end;

function TCodeToolManager.FindCodeToolForSource(Code: TCodeBuffer
  ): TCustomCodeTool;
var ANode: TAVLTreeNode;
  CurSrc, SearchedSrc: Pointer;
begin
  ANode:=FSourceTools.Root;
  SearchedSrc:=Pointer(Code);
  while (ANode<>nil) do begin
    CurSrc:=Pointer(TCustomCodeTool(ANode.Data).Scanner.MainCode);
    if CurSrc>SearchedSrc then
      ANode:=ANode.Left
    else if CurSrc<SearchedSrc then
      ANode:=ANode.Right
    else begin
      Result:=TCustomCodeTool(ANode.Data);
      exit;
    end;
  end;
  Result:=nil;
end;

function TCodeToolManager.GetCodeToolForSource(Code: TCodeBuffer;
  ExceptionOnError: boolean): TCustomCodeTool;
// return a codetool for the source
begin
  Result:=nil;
  if Code=nil then begin
    if ExceptionOnError then
      raise Exception.Create('TCodeToolManager.GetCodeToolForSource '
        +'internal error: Code=nil');
    exit;
  end;
  Result:=FindCodeToolForSource(Code);
  if Result=nil then begin
    CreateScanner(Code);
    if Code.Scanner=nil then begin
      if ExceptionOnError then
        raise Exception.CreateFmt(ctsNoScannerFound,[Code.Filename]);
      exit;
    end;
    Result:=TCodeTool.Create;
    Result.Scanner:=Code.Scanner;
    FSourceTools.Add(Result);
  end;
  with TCodeTool(Result) do begin
    AdjustTopLineDueToComment:=Self.AdjustTopLineDueToComment;
    AddInheritedCodeToOverrideMethod:=Self.AddInheritedCodeToOverrideMethod;
    CompleteProperties:=Self.CompleteProperties;
  end;
  Result.CheckFilesOnDisk:=FCheckFilesOnDisk;
  Result.IndentSize:=FIndentSize;
  Result.VisibleEditorLines:=FVisibleEditorLines;
  Result.JumpCentered:=FJumpCentered;
  Result.CursorBeyondEOL:=FCursorBeyondEOL;
  TCodeTool(Result).OnGetCodeToolForBuffer:=@OnGetCodeToolForBuffer;
  TCodeTool(Result).OnFindUsedUnit:=@DoOnFindUsedUnit;
  TCodeTool(Result).OnGetSrcPathForCompiledUnit:=@DoOnGetSrcPathForCompiledUnit;
  Result.OnSetGlobalWriteLock:=@OnToolSetWriteLock;
  Result.OnGetGlobalWriteLockInfo:=@OnToolGetWriteLockInfo;
  TCodeTool(Result).OnParserProgress:=@OnParserProgress;
end;

procedure TCodeToolManager.SetAbortable(const AValue: boolean);
begin
  if FAbortable=AValue then exit;
  FAbortable:=AValue;
end;

procedure TCodeToolManager.SetAddInheritedCodeToOverrideMethod(
  const AValue: boolean);
begin
  if FAddInheritedCodeToOverrideMethod=AValue then exit;
  FAddInheritedCodeToOverrideMethod:=AValue;
  if FCurCodeTool<>nil then
    FCurCodeTool.AddInheritedCodeToOverrideMethod:=AValue;
end;

function TCodeToolManager.OnGetCodeToolForBuffer(Sender: TObject;
  Code: TCodeBuffer): TFindDeclarationTool;
begin
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.OnGetCodeToolForBuffer]'
    ,' Sender=',TCustomCodeTool(Sender).MainFilename
    ,' Code=',Code.Filename);
  {$ENDIF}
  Result:=TFindDeclarationTool(GetCodeToolForSource(Code,true));
end;

procedure TCodeToolManager.ActivateWriteLock;
begin
  if FWriteLockCount=0 then begin
    // start a new write lock
    if FWriteLockStep<>$7fffffff then
      inc(FWriteLockStep)
    else
      FWriteLockStep:=-$7fffffff;
    SourceCache.GlobalWriteLockIsSet:=true;
    SourceCache.GlobalWriteLockStep:=FWriteLockStep;
  end;
  inc(FWriteLockCount);
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.ActivateWriteLock] FWriteLockCount=',FWriteLockCount,' FWriteLockStep=',FWriteLockStep);
  {$ENDIF}
end;

procedure TCodeToolManager.DeactivateWriteLock;
begin
  if FWriteLockCount>0 then begin
    dec(FWriteLockCount);
    if FWriteLockCount=0 then begin
      // end the write lock
      SourceCache.GlobalWriteLockIsSet:=false;
    end;
  end;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeToolManager.DeactivateWriteLock] FWriteLockCount=',FWriteLockCount,' FWriteLockStep=',FWriteLockStep);
  {$ENDIF}
end;

procedure TCodeToolManager.OnToolGetWriteLockInfo(var WriteLockIsSet: boolean;
  var WriteLockStep: integer);
begin
  WriteLockIsSet:=FWriteLockCount>0;
  WriteLockStep:=FWriteLockStep;
//DebugLn(' FWriteLockCount=',FWriteLockCount,' FWriteLockStep=',FWriteLockStep);
end;

function TCodeToolManager.GetResourceTool: TResourceCodeTool;
begin
  if FResourceTool=nil then FResourceTool:=TResourceCodeTool.Create;
  Result:=FResourceTool;
end;

function TCodeToolManager.GetOwnerForCodeTreeNode(ANode: TCodeTreeNode
  ): TObject;
var
  AToolNode: TAVLTreeNode;
  CurTool: TCustomCodeTool;
  RootCodeTreeNode: TCodeTreeNode;
begin
  Result:=nil;
  if ANode=nil then exit;
  RootCodeTreeNode:=ANode.GetRoot;
  AToolNode:=FSourceTools.FindLowest;
  while (AToolNode<>nil) do begin
    CurTool:=TCustomCodeTool(AToolNode.Data);
    if CurTool.Tree.Root=RootCodeTreeNode then begin
      Result:=CurTool;
      exit;
    end;
    AToolNode:=FSourceTools.FindSuccessor(AToolNode);
  end;
end;

procedure TCodeToolManager.OnToolSetWriteLock(Lock: boolean);
begin
  if Lock then ActivateWriteLock else DeactivateWriteLock;
end;

function TCodeToolManager.ConsistencyCheck: integer;
// 0 = ok
begin
  try
    Result:=0;
    if FCurCodeTool<>nil then begin
      Result:=FCurCodeTool.ConsistencyCheck;
      if Result<>0 then begin
        dec(Result,10000);  exit;
      end;
    end;
    Result:=DefinePool.ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,20000);  exit;
    end;
    Result:=DefineTree.ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,30000);  exit;
    end;
    Result:=SourceCache.ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,40000);  exit;
    end;
    Result:=GlobalValues.ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,50000);  exit;
    end;
    Result:=SourceChangeCache.ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,60000);  exit;
    end;
    Result:=FSourceTools.ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,70000);  exit;
    end;
  finally
    if (Result<>0) and (FCatchExceptions=false) then
      raise Exception.Create(
                        'TCodeToolManager.ConsistencyCheck='+IntToStr(Result));
  end;
  Result:=0;
end;

procedure TCodeToolManager.WriteDebugReport(WriteTool,
  WriteDefPool, WriteDefTree, WriteCache, WriteGlobalValues: boolean);
begin
  DebugLn('[TCodeToolManager.WriteDebugReport] Consistency=',dbgs(ConsistencyCheck));
  if FCurCodeTool<>nil then begin
    if WriteTool then
      FCurCodeTool.WriteDebugTreeReport
    else
      DebugLn('  FCurCodeTool.ConsistencyCheck=',dbgs(FCurCodeTool.ConsistencyCheck));
  end;
  if WriteDefPool then
    DefinePool.WriteDebugReport
  else
    DebugLn('  DefinePool.ConsistencyCheck=',dbgs(DefinePool.ConsistencyCheck));
  if WriteDefTree then
    DefineTree.WriteDebugReport
  else
    DebugLn('  DefineTree.ConsistencyCheck=',dbgs(DefineTree.ConsistencyCheck));
  if WriteCache then
    SourceCache.WriteDebugReport
  else
    DebugLn('  SourceCache.ConsistencyCheck=',dbgs(SourceCache.ConsistencyCheck));
  if WriteGlobalValues then
    GlobalValues.WriteDebugReport
  else
    DebugLn('  GlobalValues.ConsistencyCheck=',dbgs(GlobalValues.ConsistencyCheck));
end;

//-----------------------------------------------------------------------------

initialization
  CodeToolBoss:=TCodeToolManager.Create;
  OnFindOwnerOfCodeTreeNode:=@GetOwnerForCodeTreeNode;


finalization
  {$IFDEF CTDEBUG}
  DebugLn('codetoolmanager.pas - finalization');
  {$ENDIF}
  OnFindOwnerOfCodeTreeNode:=nil;
  CodeToolBoss.Free;
  CodeToolBoss:=nil;
  {$IFDEF CTDEBUG}
  DebugLn('codetoolmanager.pas - finalization finished');
  {$ENDIF}

end.

