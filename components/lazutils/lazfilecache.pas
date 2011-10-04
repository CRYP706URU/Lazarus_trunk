unit LazFileCache;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazDbgLog, AVL_Tree, LazFileUtils;

type
  TFileStateCacheItemFlag = (
    fsciExists,    // file or directory exists
    fsciDirectory, // file exists and is directory
    fsciReadable,  // file is readable
    fsciWritable,  // file is writable
    fsciDirectoryReadable, // file is directory and can be searched
    fsciDirectoryWritable, // file is directory and new files can be created
    fsciText,      // file is text file (not binary)
    fsciExecutable,// file is executable
    fsciAge        // file age is valid
    );
  TFileStateCacheItemFlags = set of TFileStateCacheItemFlag;

  { TFileStateCacheItem }

  TFileStateCacheItem = class
  private
    FAge: longint;
    FFilename: string;
    FFlags: TFileStateCacheItemFlags;
    FTestedFlags: TFileStateCacheItemFlags;
    FTimeStamp: int64;
  public
    constructor Create(const TheFilename: string; NewTimeStamp: int64);
    function CalcMemSize: PtrUint;
  public
    property Filename: string read FFilename;
    property Flags: TFileStateCacheItemFlags read FFlags;
    property TestedFlags: TFileStateCacheItemFlags read FTestedFlags;
    property TimeStamp: int64 read FTimeStamp;
    property Age: longint read FAge;
  end;

  TOnChangeFileStateTimeStamp = procedure(Sender: TObject;
                                          const AFilename: string) of object;

  { TFileStateCache }

  TFileStateCache = class
  private
    FFiles: TAVLTree; // tree of TFileStateCacheItem
    FTimeStamp: int64;
    FLockCount: integer;
    FChangeTimeStampHandler: array of TOnChangeFileStateTimeStamp;
    procedure SetFlag(AFile: TFileStateCacheItem;
                      AFlag: TFileStateCacheItemFlag; NewValue: boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
    function Locked: boolean;
    procedure IncreaseTimeStamp(const AFilename: string);
    function FileExistsCached(const AFilename: string): boolean;
    function DirPathExistsCached(const AFilename: string): boolean;
    function DirectoryIsWritableCached(const DirectoryName: string): boolean;
    function FileIsExecutableCached(const AFilename: string): boolean;
    function FileIsReadableCached(const AFilename: string): boolean;
    function FileIsWritableCached(const AFilename: string): boolean;
    function FileIsTextCached(const AFilename: string): boolean;
    function FileAgeCached(const AFileName: string): Longint;
    function FindFile(const Filename: string;
                      CreateIfNotExists: boolean): TFileStateCacheItem;
    function Check(const Filename: string; AFlag: TFileStateCacheItemFlag;
                   out AFile: TFileStateCacheItem; var FlagIsSet: boolean): boolean;
    procedure WriteDebugReport;
    procedure AddChangeTimeStampHandler(const Handler: TOnChangeFileStateTimeStamp);
    procedure RemoveChangeTimeStampHandler(const Handler: TOnChangeFileStateTimeStamp);
    function CalcMemSize: PtrUint;
  public
    property TimeStamp: int64 read FTimeStamp;
  end;

var
  FileStateCache: TFileStateCache = nil;

function FileExistsCached(const AFilename: string): boolean;
function DirPathExistsCached(const AFilename: string): boolean;
function DirectoryIsWritableCached(const ADirectoryName: string): boolean;
function FileIsExecutableCached(const AFilename: string): boolean;
function FileIsReadableCached(const AFilename: string): boolean;
function FileIsWritableCached(const AFilename: string): boolean;
function FileIsTextCached(const AFilename: string): boolean;
function FileAgeCached(const AFileName: string): Longint;

procedure InvalidateFileStateCache(const Filename: string = ''); inline;
function CompareFileStateItems(Data1, Data2: Pointer): integer;
function CompareFilenameWithFileStateCacheItem(Key, Data: Pointer): integer;

const
  FileStateCacheItemFlagNames: array[TFileStateCacheItemFlag] of string = (
    'fsciExists',
    'fsciDirectory',
    'fsciReadable',
    'fsciWritable',
    'fsciDirectoryReadable',
    'fsciDirectoryWritable',
    'fsciText',
    'fsciExecutable',
    'fsciAge'
    );

const
  LUInvalidChangeStamp = Low(integer);
  LUInvalidChangeStamp64 = Low(int64); // using a value outside integer to spot wrong types early
procedure LUIncreaseChangeStamp(var ChangeStamp: integer); inline;
procedure LUIncreaseChangeStamp64(var ChangeStamp: int64); inline;

type
  TOnFileExistsCached = function(Filename: string): boolean of object;
  TOnFileAgeCached = function(Filename: string): longint of object;
var
  OnFileExistsCached: TOnFileExistsCached = nil;
  OnFileAgeCached: TOnFileAgeCached = nil;

implementation


function FileExistsCached(const AFilename: string): boolean;
begin
  if OnFileExistsCached<>nil then
    Result:=OnFileExistsCached(AFilename)
  else
    Result:=FileStateCache.FileExistsCached(AFilename);
end;

function DirPathExistsCached(const AFilename: string): boolean;
begin
  Result:=FileStateCache.DirPathExistsCached(AFilename);
end;

function DirectoryIsWritableCached(const ADirectoryName: string): boolean;
begin
  Result:=FileStateCache.DirectoryIsWritableCached(ADirectoryName);
end;

function FileIsExecutableCached(const AFilename: string): boolean;
begin
  Result:=FileStateCache.FileIsExecutableCached(AFilename);
end;

function FileIsReadableCached(const AFilename: string): boolean;
begin
  Result:=FileStateCache.FileIsReadableCached(AFilename);
end;

function FileIsWritableCached(const AFilename: string): boolean;
begin
  Result:=FileStateCache.FileIsWritableCached(AFilename);
end;

function FileIsTextCached(const AFilename: string): boolean;
begin
  Result:=FileStateCache.FileIsTextCached(AFilename);
end;

function FileAgeCached(const AFileName: string): Longint;
begin
  if OnFileAgeCached<>nil then
    Result:=OnFileAgeCached(AFilename)
  else
    Result:=FileStateCache.FileAgeCached(AFilename);
end;

procedure InvalidateFileStateCache(const Filename: string);
begin
  FileStateCache.IncreaseTimeStamp(Filename);
end;

function CompareFileStateItems(Data1, Data2: Pointer): integer;
begin
  Result:=CompareFilenames(TFileStateCacheItem(Data1).FFilename,
                           TFileStateCacheItem(Data2).FFilename);
end;

function CompareFilenameWithFileStateCacheItem(Key, Data: Pointer): integer;
begin
  Result:=CompareFilenames(AnsiString(Key),TFileStateCacheItem(Data).FFilename);
  //debugln('CompareFilenameWithFileStateCacheItem Key=',AnsiString(Key),' Data=',TFileStateCacheItem(Data).FFilename,' Result=',dbgs(Result));
end;

procedure LUIncreaseChangeStamp(var ChangeStamp: integer);
begin
  if ChangeStamp<High(ChangeStamp) then
    inc(ChangeStamp)
  else
    ChangeStamp:=LUInvalidChangeStamp+1;
end;

procedure LUIncreaseChangeStamp64(var ChangeStamp: int64);
begin
  if ChangeStamp<High(ChangeStamp) then
    inc(ChangeStamp)
  else
    ChangeStamp:=LUInvalidChangeStamp64+1;
end;

{ TFileStateCacheItem }

constructor TFileStateCacheItem.Create(const TheFilename: string;
  NewTimeStamp: int64);
begin
  FFilename:=TheFilename;
  FTimeStamp:=NewTimeStamp;
end;

function TFileStateCacheItem.CalcMemSize: PtrUint;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(FFilename);
end;

{ TFileStateCache }

procedure TFileStateCache.SetFlag(AFile: TFileStateCacheItem;
  AFlag: TFileStateCacheItemFlag; NewValue: boolean);
begin
  if AFile.FTimeStamp<>FTimeStamp then begin
    AFile.FTestedFlags:=[];
    AFile.FTimeStamp:=FTimeStamp;
  end;
  Include(AFile.FTestedFlags,AFlag);
  if NewValue then
    Include(AFile.FFlags,AFlag)
  else
    Exclude(AFile.FFlags,AFlag);
  //debugln('TFileStateCache.SetFlag AFile.Filename=',AFile.Filename,' ',FileStateCacheItemFlagNames[AFlag],'=',dbgs(AFlag in AFile.FFlags),' Valid=',dbgs(AFlag in AFile.FTestedFlags));
end;

constructor TFileStateCache.Create;
begin
  FFiles:=TAVLTree.Create(@CompareFileStateItems);
  LUIncreaseChangeStamp64(FTimeStamp); // one higher than default for new files
end;

destructor TFileStateCache.Destroy;
begin
  FFiles.FreeAndClear;
  FFiles.Free;
  SetLength(FChangeTimeStampHandler,0);
  inherited Destroy;
end;

procedure TFileStateCache.Lock;
begin
  inc(FLockCount);
end;

procedure TFileStateCache.Unlock;

  procedure RaiseTooManyUnlocks;
  begin
    raise Exception.Create('TFileStateCache.Unlock');
  end;

begin
  if FLockCount<=0 then RaiseTooManyUnlocks;
  dec(FLockCount);
end;

function TFileStateCache.Locked: boolean;
begin
  Result:=FLockCount>0;
end;

procedure TFileStateCache.IncreaseTimeStamp(const AFilename: string);
var
  i: Integer;
  AFile: TFileStateCacheItem;
begin
  if Self=nil then exit;
  if AFilename='' then begin
    // invalidate all
    LUIncreaseChangeStamp64(FTimeStamp);
  end else begin
    // invalidate single file
    AFile:=FindFile(AFilename,false);
    if AFile<>nil then
      AFile.FTestedFlags:=[];
  end;
  for i:=0 to length(FChangeTimeStampHandler)-1 do
    FChangeTimeStampHandler[i](Self,AFilename);
  //debugln('TFileStateCache.IncreaseTimeStamp FTimeStamp=',dbgs(FTimeStamp));
end;

function TFileStateCache.FileExistsCached(const AFilename: string): boolean;
var
  AFile: TFileStateCacheItem;
begin
  Result := False;
  if Check(AFilename,fsciExists,AFile,Result) then exit;
  Result:=FileExistsUTF8(AFile.Filename);
  SetFlag(AFile,fsciExists,Result);
  {if not Check(Filename,fsciExists,AFile,Result) then begin
    WriteDebugReport;
    raise Exception.Create('');
  end;}
end;

function TFileStateCache.DirPathExistsCached(const AFilename: string): boolean;
var
  AFile: TFileStateCacheItem;
begin
  Result := False;
  if Check(AFilename,fsciDirectory,AFile,Result) then exit;
  Result:=DirPathExists(AFile.Filename);
  SetFlag(AFile,fsciDirectory,Result);
end;

function TFileStateCache.DirectoryIsWritableCached(const DirectoryName: string
  ): boolean;
var
  AFile: TFileStateCacheItem;
begin
  Result := False;
  if Check(DirectoryName,fsciDirectoryWritable,AFile,Result) then exit;
  Result:=DirectoryIsWritable(AFile.Filename);
  SetFlag(AFile,fsciDirectoryWritable,Result);
end;

function TFileStateCache.FileIsExecutableCached(
  const AFilename: string): boolean;
var
  AFile: TFileStateCacheItem;
begin
  Result := False;
  if Check(AFilename,fsciExecutable,AFile,Result) then exit;
  Result:=FileIsExecutable(AFile.Filename);
  SetFlag(AFile,fsciExecutable,Result);
end;

function TFileStateCache.FileIsReadableCached(const AFilename: string): boolean;
var
  AFile: TFileStateCacheItem;
begin
  Result := False;
  if Check(AFilename,fsciReadable,AFile,Result) then exit;
  Result:=FileIsReadable(AFile.Filename);
  SetFlag(AFile,fsciReadable,Result);
end;

function TFileStateCache.FileIsWritableCached(const AFilename: string): boolean;
var
  AFile: TFileStateCacheItem;
begin
  Result := False;
  if Check(AFilename,fsciWritable,AFile,Result) then exit;
  Result:=FileIsWritable(AFile.Filename);
  SetFlag(AFile,fsciWritable,Result);
end;

function TFileStateCache.FileIsTextCached(const AFilename: string): boolean;
var
  AFile: TFileStateCacheItem;
begin
  Result := False;
  if Check(AFilename,fsciText,AFile,Result) then exit;
  Result:=FileIsText(AFile.Filename);
  SetFlag(AFile,fsciText,Result);
end;

function TFileStateCache.FileAgeCached(const AFileName: string): Longint;
var
  AFile: TFileStateCacheItem;
  Dummy: Boolean;
begin
  Dummy := False;
  if Check(AFilename,fsciAge,AFile,Dummy) then begin
    Result:=AFile.Age;
    exit;
  end;
  Result:=FileAge(AFile.Filename);
  AFile.FAge:=Result;
  Include(AFile.FTestedFlags,fsciAge);
end;

function TFileStateCache.FindFile(const Filename: string;
  CreateIfNotExists: boolean): TFileStateCacheItem;
var
  TrimmedFilename: String;
  ANode: TAVLTreeNode;
begin
  // make filename unique
  TrimmedFilename:=ChompPathDelim(TrimFilename(Filename));
  ANode:=FFiles.FindKey(Pointer(TrimmedFilename),
                        @CompareFilenameWithFileStateCacheItem);
  if ANode<>nil then
    Result:=TFileStateCacheItem(ANode.Data)
  else if CreateIfNotExists then begin
    Result:=TFileStateCacheItem.Create(TrimmedFilename,FTimeStamp);
    FFiles.Add(Result);
    if FFiles.FindKey(Pointer(TrimmedFilename),
                      @CompareFilenameWithFileStateCacheItem)=nil
    then begin
      //DebugLn(format('FileStateCache.FindFile: "%s"',[FileName]));
      WriteDebugReport;
      raise Exception.Create('');
    end;
  end else
    Result:=nil;
end;

function TFileStateCache.Check(const Filename: string;
  AFlag: TFileStateCacheItemFlag; out AFile: TFileStateCacheItem;
  var FlagIsSet: boolean): boolean;
begin
  AFile:=FindFile(Filename,true);
  if FTimeStamp=AFile.FTimeStamp then begin
    Result:=AFlag in AFile.FTestedFlags;
    FlagIsSet:=AFlag in AFile.FFlags;
  end else begin
    AFile.FTestedFlags:=[];
    AFile.FTimeStamp:=FTimeStamp;
    Result:=false;
    FlagIsSet:=false;
  end;
  //debugln('TFileStateCache.Check Filename=',Filename,' AFile.Filename=',AFile.Filename,' ',FileStateCacheItemFlagNames[AFlag],'=',dbgs(FlagIsSet),' Valid=',dbgs(Result));
end;

procedure TFileStateCache.WriteDebugReport;
var
  ANode: TAVLTreeNode;
  AFile: TFileStateCacheItem;
begin
  {$NOTE ToDo}
  //debugln('TFileStateCache.WriteDebugReport FTimeStamp=',dbgs(FTimeStamp));
  ANode:=FFiles.FindLowest;
  while ANode<>nil do begin
    AFile:=TFileStateCacheItem(ANode.Data);
    //debugln('  "',AFile.Filename,'" TimeStamp=',dbgs(AFile.TimeStamp));
    ANode:=FFiles.FindSuccessor(ANode);
  end;
  //debugln(' FFiles=',dbgs(FFiles.ConsistencyCheck));
  //debugln(FFiles.ReportAsString);
end;

procedure TFileStateCache.AddChangeTimeStampHandler(
  const Handler: TOnChangeFileStateTimeStamp);
begin
  SetLength(FChangeTimeStampHandler,length(FChangeTimeStampHandler)+1);
  FChangeTimeStampHandler[length(FChangeTimeStampHandler)-1]:=Handler;
end;

procedure TFileStateCache.RemoveChangeTimeStampHandler(
  const Handler: TOnChangeFileStateTimeStamp);
var
  i: Integer;
begin
  for i:=length(FChangeTimeStampHandler)-1 downto 0 do begin
    if Handler=FChangeTimeStampHandler[i] then begin
      if i<length(FChangeTimeStampHandler)-1 then
        System.Move(FChangeTimeStampHandler[i+1],FChangeTimeStampHandler[i],
                    SizeOf(TNotifyEvent)*(length(FChangeTimeStampHandler)-i-1));
      SetLength(FChangeTimeStampHandler,length(FChangeTimeStampHandler)-1);
    end;
  end;
end;

function TFileStateCache.CalcMemSize: PtrUint;
var
  Node: TAVLTreeNode;
begin
  Result:=PtrUInt(InstanceSize)
    +PtrUInt(length(FChangeTimeStampHandler))*SizeOf(TNotifyEvent);
  if FFiles<>nil then begin
    inc(Result,PtrUInt(FFiles.InstanceSize)
      +PtrUInt(FFiles.Count)*PtrUInt(TAVLTreeNode.InstanceSize));
    Node:=FFiles.FindLowest;
    while Node<>nil do begin
      inc(Result,TFileStateCacheItem(Node.Data).CalcMemSize);
      Node:=FFiles.FindSuccessor(Node);
    end;
  end;
end;

initialization
  OnInvalidateFileStateCache:=@InvalidateFileStateCache;

end.

