{ /***************************************************************************
                     editdefinetree.pas  -  Lazarus IDE unit
                     ---------------------------------------

 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
 
  Author: Mattias Gaertner
 
  Abstract:
    - procs to transfer the compiler options to the CodeTools
}
unit EditDefineTree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IDEProcs, CodeToolManager, DefineTemplates,
  CompilerOptions, TransferMacros, LinkScanner;

procedure SetCompilerOptionsToCodeToolBoss(CompOpts: TCompilerOptions);

const
  ProjectDirDefTemplName = 'Current Project Directory';


implementation


function ConvertTransferMacrosToExternalMacros(const s: string): string;
var
  Count, i, j: integer;
begin
  Count:=0;
  for i:=1 to length(s)-2 do
    if (s[i]<>SpecialChar) and (s[i+1]='$') and (s[i+2] in ['(','{']) then
      inc(Count);
  SetLength(Result,Length(s)+Count);
  i:=1;
  j:=1;
  while (i<=length(s)) do begin
    if (i>=3) and (s[i-2]<>SpecialChar) and (s[i-1]='$') and (s[i] in ['(','{'])
    then begin
      Result[j]:='(';
      inc(j);
      Result[j]:=ExternalMacroStart;
    end else if (i>=2) and (s[i-1]<>SpecialChar) and (s[i]='}') then begin
      Result[j]:=')';
    end else begin
      Result[j]:=s[i];
    end;
    inc(j);
    inc(i);
  end;
end;

procedure SetCompilerOptionsToCodeToolBoss(CompOpts: TCompilerOptions);
var ProjectDir, s: string;
  ProjTempl: TDefineTemplate;
begin
  { ToDo:
  
    StackChecks
    DontUseConfigFile
    AdditionalConfigFile
  }
  
  // define macros for project directory
  ProjectDir:='$('+ExternalMacroStart+'ProjectDir)';

  // create define node for current project directory -------------------------
  ProjTempl:=TDefineTemplate.Create(ProjectDirDefTemplName,
    'Current Project Directory','',ProjectDir,da_Directory);
    
  // FPC modes ----------------------------------------------------------------
  if CompOpts.DelphiCompat then begin
    // set mode DELPHI
    ProjTempl.AddChild(TDefineTemplate.Create('MODE',
    'set FPC mode to DELPHI',CompilerModeVars[cmDELPHI],'1',da_DefineAll));
  end else if CompOpts.TPCompatible then begin
    // set mode TP
    ProjTempl.AddChild(TDefineTemplate.Create('MODE',
    'set FPC mode to TP',CompilerModeVars[cmTP],'1',da_DefineAll));
  end else if CompOpts.GPCCompat then begin
    // set mode GPC
    ProjTempl.AddChild(TDefineTemplate.Create('MODE',
    'set FPC mode to GPC',CompilerModeVars[cmGPC],'1',da_DefineAll));
  end;
  
  // Checks -------------------------------------------------------------------
  if CompOpts.IOChecks then begin
    // set IO checking on
    ProjTempl.AddChild(TDefineTemplate.Create('IOCHECKS on',
    'set IOCHECKS on','IOCHECKS','1',da_DefineAll));
  end;
  if CompOpts.RangeChecks then begin
    // set Range checking on
    ProjTempl.AddChild(TDefineTemplate.Create('RANGECHECKS on',
    'set RANGECHECKS on','RANGECHECKS','1',da_DefineAll));
  end;
  if CompOpts.OverflowChecks then begin
    // set Overflow checking on
    ProjTempl.AddChild(TDefineTemplate.Create('OVERFLOWCHECKS on',
    'set OVERFLOWCHECKS on','OVERFLOWCHECKS','1',da_DefineAll));
  end;

  // Hidden used units --------------------------------------------------------
  if CompOpts.UseLineInfoUnit then begin
    // use lineinfo unit
    ProjTempl.AddChild(TDefineTemplate.Create('Use LINEINFO unit',
    'use LineInfo unit',ExternalMacroStart+'UseLineInfo','1',da_DefineAll));
  end;
  if CompOpts.UseHeaptrc then begin
    // use heaptrc unit
    ProjTempl.AddChild(TDefineTemplate.Create('Use HEAPTRC unit',
    'use HeapTrc unit',ExternalMacroStart+'UseHeapTrcUnit','1',da_DefineAll));
  end;
  
  // Paths --------------------------------------------------------------------
  
  // Include Path
  if CompOpts.IncludeFiles<>'' then begin
    // add include paths
    ProjTempl.AddChild(TDefineTemplate.Create('INCLUDEPATH',
      'include path addition',ExternalMacroStart+'INCPATH',
      ConvertTransferMacrosToExternalMacros(CompOpts.IncludeFiles)+';'
      +'$('+ExternalMacroStart+'INCPATH)',
      da_DefineAll));
  end;
  // compiled unit path (ppu/ppw/dcu files)
  s:=CompOpts.OtherUnitFiles;
  if (CompOpts.UnitOutputDirectory<>'') then begin
    if s<>'' then
      s:=s+';'+CompOpts.UnitOutputDirectory
    else
      s:=CompOpts.UnitOutputDirectory;
  end;
  if s<>'' then begin
    // add compiled unit path
    ProjTempl.AddChild(TDefineTemplate.Create('UNITPATH',
      'unit path addition',ExternalMacroStart+'UNITPATH',
      ConvertTransferMacrosToExternalMacros(s)+';'
      +'$('+ExternalMacroStart+'UNITPATH)',
      da_DefineAll));
  end;
  // source path (unitpath + sources for the CodeTools, hidden to the compiler)
  if s<>'' then begin
    // add compiled unit path
    ProjTempl.AddChild(TDefineTemplate.Create('SRCPATH',
      'source path addition',ExternalMacroStart+'SRCPATH',
      ConvertTransferMacrosToExternalMacros(s)+';'
      +'$('+ExternalMacroStart+'SRCPATH)',
      da_DefineAll));
  end;

  // LCL Widget Type ----------------------------------------------------------
  if CodeToolBoss.GlobalValues[ExternalMacroStart+'LCLWidgetType']<>
    CompOpts.LCLWidgetType then
  begin
    CodeToolBoss.GlobalValues[ExternalMacroStart+'LCLWidgetType']:=
      CompOpts.LCLWidgetType;
    CodeToolBoss.DefineTree.ClearCache;
  end;
  
  // --------------------------------------------------------------------------
  // replace project defines in DefineTree
  CodeToolBoss.DefineTree.ReplaceSameName(ProjTempl);
end;

end.

