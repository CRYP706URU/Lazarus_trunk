{
 /***************************************************************************
                             checkbox.pp
                             -----------
                        Sample for Lazarus Checkbox.


                   Initial Revision  : Wed Dec 29 23:15:32 CST 1999


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
program CheckBox;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, Stdctrls, Forms, Buttons, Menus, Comctrls,
  SysUtils, ExtCtrls, GraphType, Graphics, Controls;

type
  TForm1 = class(TFORM)
  public
    Button2: TButton;
    Button3: TButton;
    Button11, Button12, Button13 : TSpeedButton; 
    Panel1: TPanel;
    mnuMain: TMainMenu;
    itmFileQuit: TMenuItem;
    itmFile: TMenuItem;
    CheckBox1 : TCheckBox;
    RadioButton : TRadioButton;
    RadioButton2 : TRadioButton;
    RadioButton3 : TRadioButton;
    RadioGroup   : TRadioGroup;
    RadioGroup2  : TRadioGroup;
    ToggleBox   : TToggleBox;
    label1    : TLabel;   
    label2    : TLabel;
    FPixmap : TPixMap;
    constructor Create(AOwner: TComponent); override; 
    procedure LoadMainMenu;
    Procedure FormKill(Sender : TObject);
    procedure mnuQuitClicked(Sender : TObject);
  protected
    procedure Button1CLick(Sender : TObject);
    procedure Button2CLick(Sender : TObject);
    procedure Button3CLick(Sender : TObject);
    procedure Button4CLick(Sender : TObject);
    procedure CheckBoxClick(Sender : TObject);
    procedure RadioButtonClick(Sender : TObject);
    procedure RadioGroupClick(Sender : TObject);
    procedure ToggleBoxClick(Sender : TObject);
  end;

var
Form1 : TForm1;

constructor TForm1.Create(AOwner: TComponent);  
begin
   inherited Create(AOwner);
   Caption := 'CheckBox Demo V.02';
   LoadMainMenu;
end;

procedure TForm1.Button1Click(Sender : TObject);
Begin
End;

procedure TForm1.Button2Click(Sender : TObject);
Begin
   if assigned (CheckBox1) then
   begin
      CheckBox1.Checked := not CheckBox1.Checked; 
   end;
   Panel1.Caption:= 'Changed';
End;

procedure TForm1.Button3Click(Sender : TObject);
var
   i : integer;
Begin
   if assigned (RadioGroup) then
   begin
      i := RadioGroup.ItemIndex;
      if i < RadioGroup.Items.Count -1 
         then RadioGroup.ItemIndex := i + 1
         else RadioGroup.ItemIndex := 0
   end;
   if assigned (RadioGroup2) then
   begin
      i := RadioGroup2.ItemIndex;
      if i < RadioGroup2.Items.Count -1 
         then RadioGroup2.ItemIndex := i + 1
         else RadioGroup2.ItemIndex := 0
   end;
End;

procedure TForm1.Button4Click(Sender : TObject);
Begin
End;

procedure TForm1.CheckBoxClick(Sender : TObject);
Begin
  WriteLn('[TForm1.CheckBoxClick]');
   if assigned (CheckBox1) and assigned (label1) then begin
      Writeln ('   [checkbox and label assigned]');
      if CheckBox1.Checked
        then label1.Caption := 'checked'
        else label1.Caption := 'unchecked';
// ***SIGSEGV!!!!!!!!!      label1.Repaint; 
      if CheckBox1.Checked
        then CheckBox1.Caption := 'new caption'
        else CheckBox1.Caption := 'Checkbox 1';
   end;
End;

procedure TForm1.RadioButtonClick(Sender : TObject);
begin
   WriteLn('[TForm1.RadioButtonClick]');
   if assigned (label2)
      then label2.Caption := 'active: ' + TRadioButton (Sender).Caption
end;

procedure TForm1.RadioGroupClick(Sender : TObject);
begin
   WriteLn('[TForm1.RadioGroupClick]');
end;

procedure TForm1.ToggleBoxClick(Sender : TObject);
begin
   WriteLn('[TForm1.ToggleBoxClick]');
   if assigned (ToggleBox) then
   begin
      if ToggleBox.checked
         then ToggleBox.Caption := 'Togglebox1'
	 else ToggleBox.Caption := 'does nothing:-(';
// ***SIGSEGV!!!!!!!!!      ToggleBox.RePaint;
   end;
end;

{------------------------------------------------------------------------------}

procedure TForm1.FormKill(Sender : TObject);
Begin

End;

{------------------------------------------------------------------------------}
procedure TForm1.LoadMainMenu;

begin
 OnDestroy := @FormKill;

{    set the height and width }
   Height := 450;
   Width := 700;

   { Create a checkbox }
   CheckBox1 := TCheckBox.Create(Self);
   CheckBox1.Parent := self;
   CheckBox1.top := 35;
   CheckBox1.left := 10;
   CheckBox1.Height :=20;
   CheckBox1.Width := 200;
   CheckBox1.OnCLick := @CheckBoxClick;
   CheckBox1.Show;
   CheckBox1.Caption := 'Checkbox 1';

   { Create a label which shows the state checked/unchecked of the checkbox}
   label1 := TLabel.Create(Self);
   label1.Parent := self;
   label1.top := 35;
   label1.left := 220;
   label1.Height :=20;
   label1.Width := 100;
   label1.Show;
   label1.Caption := 'unchecked';


   { Sample panel here }
   Panel1:= TPanel.Create(Self);
   with Panel1 do begin
     Parent := Self;
     Left := 320;
     Top := 60;
     Width := 280;
     Height := 81;
     Alignment:= taRightJustify;
     BevelInner:= bvLowered;
     BevelOuter:= bvRaised;
     BorderWidth:= 4;
     BevelWidth:= 4;
     Show;
     Caption:= 'Hello world';
   end;     

   { Create a button which toggles the checkbox }
   Button2 := TBitBtn.Create(Self);
   Button2.Parent := Panel1;
   Button2.Left := 5;
   Button2.Top := 45;
   Button2.Width := 180;
   Button2.Height := 20;
   Button2.Show;
   Button2.Caption := 'Toggle checkbox';
   Button2.OnClick := @Button2Click;

   FPixMap:= TPixmap.Create;
   FPixmap.LoadFromFile('../images/btn_newform.xpm');

   Button11 := TSpeedButton.Create(Self);
   Button11.GroupIndex:= 1;
   Button11.Layout:= blGlyphTop;
//   Button11.Caption:= 'Option 1';
   Button11.Parent := Self;
   Button11.Left := 5;
   Button11.Top := 5;
   Button11.Width:= 45;
   Button11.Height:= 55;
   Button11.Flat:= true;
   Button11.Glyph:= FPixmap;
//   Button11.Spacing:= -1;
//   Button11.Margin:= 4;
   Button11.Visible:= true;
   
   Button12 := TSpeedButton.Create(Self);
   Button12.GroupIndex:= 1;
   Button12.Caption:= '2';
   Button12.Parent := Self;
   Button12.Left := 55;
   Button12.Top := 5;
//   Button12.Flat:= true;
   Button12.Visible:= true;

   Button13 := TSpeedButton.Create(Self);
   Button13.GroupIndex:= 1;
   Button13.Caption:= '3';
   Button13.Parent := Self;
   Button13.Left := 95;
   Button13.Top := 5;
   Button13.Flat:= true;
   Button13.AllowAllUp:= true;
   Button13.Visible:= true;
   

   { Create a label which shows the caption of the active radiobutton }
   label2 := TLabel.Create(Self);
   label2.Parent := self;
   label2.top := 90;
   label2.left := 220;
   label2.Height :=20;
   label2.Width := 200;
   label2.Show;
   label2.Caption := 'active: unknown';

   { Create a radio button }
   RadioButton := TRadioButton.Create(Self);
   RadioButton.Parent := self;
   RadioButton.top := 70;
   RadioButton.left := 10;
   RadioButton.Height :=20;
   RadioButton.Width := 200;
   RadioButton.OnCLick := @RadioButtonClick;
   RadioButton.Checked := false;  
   RadioButton.Show;
   RadioButton.Caption := 'Radio button 1';
   
   { Create a 2nd radiobutton }
   RadioButton2 := TRadioButton.Create(Self);
   with RadioButton2 do
   begin
     Parent := self;
     top := 90;
     left := 10;
     Height :=20;
     Width := 200;
     OnCLick := @RadioButtonClick;
     Checked := true; 
     Show;
     Caption := 'Radiobutton 2'
   end;

   { Create a 3rd radiobutton }
   RadioButton3 := TRadioButton.Create(Self);
   with RadioButton3 do
   begin
     Parent := self;
     top := 110;
     left := 10;
     Height :=20;
     Width := 200;
     OnCLick := @RadioButtonClick;
     Checked := false;  
     Show;
     Caption := 'Radiobutton 3'
   end;

   { Create a radiogroup }
   RadioGroup := TRadioGroup.Create(Self);
   with RadioGroup do
   begin
     Parent := self;
     top := 200;
     left := 10;
     Height :=200;
     Width := 150;
     OnCLick := @RadioGroupClick;
     RadioGroup.Items.Add ('No 1');
     RadioGroup.Items.Add ('No 2');
     RadioGroup.Items.Add ('No 3');
     RadioGroup.Items.Add ('No 4');
     RadioGroup.Items.Add ('No 5');
     RadioGroup.Items.Add ('No 6');
     ItemIndex := 3;
     Show;
     Caption := 'Radiogroup';
   end;

   { Create a button which does mystic things with the radiogroup }
   Button3 := TButton.Create(Self);
   Button3.Parent := Self;
   Button3.Left := 220;
   Button3.Top := 220;
   Button3.Width := 180;
   Button3.Height := 30;
   Button3.Show;
   Button3.Caption := 'Mystic Radiogroups';
   Button3.OnClick := @Button3Click;

   { Create a radiogroup }
   RadioGroup2 := TRadioGroup.Create(Self);
   with RadioGroup2 do
   begin
     Parent := self;
     top     := 300;
     left    := 220;
     Height  := 100;
     Width   := 300;
     Columns := 3;
     Items.Add ('No 1');
     Items.Add ('No 2');
     Items.Add ('No 3');
     Items.Add ('No 4');
     Items.Add ('No 5');
     Items.Add ('No 6');
     ItemIndex := 1;
     Show;
     Caption := '3 columns';
   end;

   { Create a togglebox }
   ToggleBox := TToggleBox.Create(Self);
   with ToggleBox do
   begin
     Parent := self;
     top := 150;
     left := 10;
     Height :=30;
     Width := 240;
     OnCLick := @ToggleBoxClick;
     Show;
     Caption := 'ToggleBox 1'
   end;

   mnuMain := TMainMenu.Create(Self);
   Menu := mnuMain;

   itmFile := TMenuItem.Create(Self);
   itmFile.Caption := 'File';
   mnuMain.Items.Add(itmFile);

   itmFileQuit := TMenuItem.Create(Self);
   itmFileQuit.Caption := 'Quit';
   itmFileQuit.OnClick := @mnuQuitClicked;
   itmFile.Add(itmFileQuit);

   

end;

{------------------------------------------------------------------------------}
procedure TForm1.mnuQuitClicked(Sender : TObject);
begin
  Close;
end;
{------------------------------------------------------------------------------}

begin
   Application.Initialize; { calls InitProcedure which starts up GTK }
   Application.CreateForm(TForm1, Form1);
   Application.Run;
end.

{
  $Log$
  Revision 1.8  2003/11/01 10:27:40  mattias
  fpc 1.1 fixes, started scrollbar hiding, started polymorphing client areas

  Revision 1.7  2003/09/18 09:21:03  mattias
  renamed LCLLinux to LCLIntf

  Revision 1.6  2002/10/30 13:44:29  lazarus
  MG: fixed examples

  Revision 1.5  2002/10/29 08:22:32  lazarus
  MG: added interfaces unit

  Revision 1.4  2002/05/10 06:57:50  lazarus
  MG: updated licenses

  Revision 1.3  2002/02/24 20:51:23  lazarus
  Improved TSpeedButton (Glyph, Spacing, Margin, drawing)
  Added PageCount to TNotebook
  Optimized component selection buttons a bit.

  Revision 1.2  2002/02/03 00:24:00  lazarus
  TPanel implemented.
  Basic graphic primitives split into GraphType package, so that we can
  reference it from interface (GTK, Win32) units.
  New Frame3d canvas method that uses native (themed) drawing (GTK only).
  New overloaded Canvas.TextRect method.
  LCLIntf and Graphics was split, so a bunch of files had to be modified.

  Revision 1.1  2000/07/13 10:28:20  michael
  + Initial import

  Revision 1.6  2000/06/22 20:58:49  lazarus
    - enhanced checkbox example, stoppok

  Revision 1.5  2000/06/18 08:11:32  lazarus
    Fixed crash in checkbox.pp when Checkbox1 was clicked.
      stoppok

  Revision 1.4  2000/01/04 23:12:46  lazarus
  MWE:
    Fixed LM_CHAR message. It is now after the LM_KEYUP message
    Fixed Menus at checkbox example.
    Removed references to TTabbedNtBK (somebody removed the files) and
      chanched it on the compileroptions form

  Revision 1.3  2000/01/02 00:30:29  lazarus
  Stoppok:
    - Shows usage of TRadiogroup now

  Revision 1.2  1999/12/30 19:05:22  lazarus

    - Enhanced checkbox.pp to also demonstrate TRadiobutton
        stoppok

}

