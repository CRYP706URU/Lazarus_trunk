unit compiler_other_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, LCLProc, IDEOptionsIntf, Project, CompilerOptions, LazarusIDEStrConsts;

type

  { TCompilerOtherOptionsFrame }

  TCompilerOtherOptionsFrame = class(TAbstractIDEOptionsEditor)
    chkConfigFile: TCheckBox;
    chkCustomConfigFile: TCheckBox;
    edtConfigPath: TEdit;
    grpConfigFile: TGroupBox;
    grpCustomOptions: TGroupBox;
    memCustomOptions: TMemo;
  private
    FOptions: TProjectCompilerOptions;
  public
    function Check: Boolean; override;
    function GetTitle: string; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TCompilerOtherOptionsFrame }

function TCompilerOtherOptionsFrame.Check: Boolean;
var
  NewDontUseConfigFile: Boolean;
  NewCustomConfigFile: Boolean;
  NewConfigFilePath: String;
  AdditionalConfig: String;
begin
  NewDontUseConfigFile := not chkConfigFile.Checked;
  NewCustomConfigFile := chkCustomConfigFile.Checked;
  NewConfigFilePath := edtConfigPath.Text;

  if ((NewDontUseConfigFile <> FOptions.DontUseConfigFile) or
    (NewCustomConfigFile <> FOptions.CustomConfigFile) or
    (NewConfigFilePath <> FOptions.ConfigFilePath)) and (not NewDontUseConfigFile) and
    NewCustomConfigFile then
  begin
    // config file options changed
    // and both additional and standard config files are used
    AdditionalConfig := ExtractFilename(edtConfigPath.Text);
    if (CompareFileNames(AdditionalConfig, 'fpc.cfg') = 0) or
      (CompareFileNames(AdditionalConfig, 'ppc386.cfg') = 0) then
    begin
      if MessageDlg(lisCOAmbiguousAdditionalCompilerConfigFile,
        Format(lisCOClickOKIfAreSureToDoThat,
        [BreakString(lisCOWarningTheAdditionalCompilerConfigFileHasTheSameNa,
        60, 0), #13#13]), mtWarning, [mbOK, mbCancel], 0) <> mrOk then
      begin
        Result := False;
        exit;
      end;
    end;
  end;
  Result := True;
end;

function TCompilerOtherOptionsFrame.GetTitle: string;
begin
  Result := dlgCOOther;
end;

procedure TCompilerOtherOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  grpConfigFile.Caption := dlgConfigFiles;
  chkConfigFile.Caption := dlgUseFpcCfg + ' (If not checked: -n)';
  chkCustomConfigFile.Caption := dlgUseCustomConfig + ' (@)';
  edtConfigPath.Text := '';

  grpCustomOptions.Caption := lisCustomOptions2;
end;

procedure TCompilerOtherOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  FOptions := AOptions as TProjectCompilerOptions;
  with FOptions do
  begin
    chkConfigFile.Checked := not DontUseConfigFile;
    chkCustomConfigFile.Checked := CustomConfigFile;
    edtConfigPath.Enabled := chkCustomConfigFile.Checked;
    edtConfigPath.Text := ConfigFilePath;
    memCustomOptions.Text := CustomOptions;
  end;
end;

procedure TCompilerOtherOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TProjectCompilerOptions do
  begin
    DontUseConfigFile := not chkConfigFile.Checked;
    CustomConfigFile := chkCustomConfigFile.Checked;
    ConfigFilePath := edtConfigPath.Text;
    CustomOptions := memCustomOptions.Text;
  end;
end;

class function TCompilerOtherOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TProjectCompilerOptions;
end;

initialization
  {$I compiler_other_options.lrs}
  RegisterIDEOptionsEditor(GroupCompiler, TCompilerOtherOptionsFrame,
    CompilerOptionsOther);

end.

