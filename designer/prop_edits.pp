unit prop_edits;
{
  Author: Mattias Gaertner

  ToDo:
    -TypInfo.GetPropList is unable to work with nil. incombatibility to delphi
    -digits for floattypes -> I hope, I have guessed right
    -TIntegerSet missing -> taking my own
    -Save ColorDialog settings
    -ColorToString missing -> taking my own
    -StringToColor missing -> taking my own
    -System.TypeInfo(Type) missing -> ?
    -StrToInt64 has a bug. It prints infinitly "something happened"
       -> taking my own

    -many more... see XXX
}

{$mode objfpc}

interface

uses Classes, TypInfo, SysUtils, Forms, Controls, Graphics, StdCtrls, Buttons;

const
  MaxIdentLength: Byte = 63;
  // XXX ToDo
  // this variable should be fetched from consts(x).inc
  // like in fcl/inc/classes.inc
  srUnknown = 'unknown';

type
  // XXX
  // The IntegerSet (a set of size of an integer)
  // don't if this is always valid
  TIntegerSet = set of 0..SizeOf(Integer) * 8 - 1;

  TGetStringProc = procedure(const s:string) of object;

  TComponentSelectionList = class
  private
    FComponents:TList;
    function GetItems(Index: integer): TComponent;
    procedure SetItems(Index: integer; const Value: TComponent);
    function GetCount: integer;
    function GetCapacity:integer;
    procedure SetCapacity(const NewCapacity:integer);
  public
    procedure Clear;
    property Count:integer read GetCount;
    property Capacity:integer read GetCapacity write SetCapacity;
    function Add(c:TComponent):integer;
    procedure Assign(SourceSelectionList:TComponentSelectionList);
    property Items[Index:integer]:TComponent read GetItems write SetItems; default;
    constructor Create;
    destructor Destroy;  override;
  end;

{ TPropertyEditor
  Edits a property of a component, or list of components, selected into the
  Object Inspector.  The property editor is created based on the type of the
  property being edited as determined by the types registered by
  RegisterPropertyEditor.  The Object Inspector uses a TPropertyEditor
  for all modification to a property. GetName and GetValue are called to display
  the name and value of the property. SetValue is called whenever the user
  requests to change the value.  Edit is called when the user double-clicks the
  property in the Object Inspector. GetValues is called when the drop-down
  list of a property is displayed. GetProperties is called when the property
  is expanded to show sub-properties. AllEqual is called to decide whether or
  not to display the value of the property when more than one component is
  selected.

  The following are methods that can be overridden to change the behavior of
  the property editor:

    Activate
      Called whenever the property becomes selected in the object inspector.
      This is potentially useful to allow certain property attributes to
      to only be determined whenever the property is selected in the object
      inspector. Only paSubProperties and paMultiSelect,returned from
      GetAttributes,need to be accurate before this method is called.
    Deactivate
      Called whenevr the property becomes unselected in the object inspector.
    AllEqual
      Called whenever there is more than one component selected.  If this
      method returns true,GetValue is called,otherwise blank is displayed
      in the Object Inspector.  This is called only when GetAttributes
      returns paMultiSelect.
    AutoFill
      Called to determine whether the values returned by GetValues can be
      selected incrementally in the Object Inspector.  This is called only when
      GetAttributes returns paValueList.
    Edit
      Called when the '...' button is pressed or the property is double-clicked.
      This can,for example,bring up a dialog to allow the editing the
      component in some more meaningful fashion than by text (e.g. the Font
      property).
    GetAttributes
      Returns the information for use in the Object Inspector to be able to
      show the appropriate tools.  GetAttributes returns a set of type
      TPropertyAttributes:
        paValueList:    The property editor can return an enumerated list of
                        values for the property.  If GetValues calls Proc
                        with values then this attribute should be set.  This
                        will cause the drop-down button to appear to the right
                        of the property in the Object Inspector.
        paSortList:     Object Inspector to sort the list returned by
                         GetValues.
        paSubProperties:The property editor has sub-properties that will be
                        displayed indented and below the current property in
                        standard outline format. If GetProperties will
                        generate property objects then this attribute should
                        be set.
        paDialog:       Indicates that the Edit method will bring up a
                        dialog.  This will cause the '...' button to be
                        displayed to the right of the property in the Object
                        Inspector.
        paMultiSelect:  Allows the property to be displayed when more than
                        one component is selected.  Some properties are not
                        appropriate for multi-selection (e.g. the Name
                        property).
        paAutoUpdate:   Causes the SetValue method to be called on each
                        change made to the editor instead of after the change
                        has been approved (e.g. the Caption property).
        paReadOnly:     Value is not allowed to change.
        paRevertable:   Allows the property to be reverted to the original
                        value.  Things that shouldn't be reverted are nested
                        properties (e.g. Fonts) and elements of a composite
                        property such as set element values.
        paFullWidthName:Tells the object inspector that the value does not
                        need to be rendered and as such the name should be
                        rendered the full width of the inspector.
    GetComponent
      Returns the Index'th component being edited by this property editor.  This
      is used to retrieve the components. A property editor can only refer to
      multiple components when paMultiSelect is returned from GetAttributes.
    GetEditLimit
      Returns the number of character the user is allowed to enter for the
      value. The inplace editor of the object inspector will be have its
      text limited set to the return value.  By default this limit is 255.
    GetName
      Returns the name of the property.  By default the value is retrieved
      from the type information with all underbars replaced by spaces.  This
      should only be overridden if the name of the property is not the name
      that should appear in the Object Inspector.
    GetProperties
      Should be overridden to call PropertyProc for every sub-property (or
      nested property) of the property begin edited and passing a new
      TPropertyEdtior for each sub-property. By default,PropertyProc is not
      called and no sub-properties are assumed. TClassPropertyEditor will pass a
      new property editor for each published property in a class.
      TSetPropertyEditor passes a new editor for each element in the set.
    GetPropType
      Returns the type information pointer for the property(s) being edited.
    GetValue
      Returns the string value of the property. By default this returns
      '(unknown)'.  This should be overridden to return the appropriate value.
    GetValues
      Called when paValueList is returned in GetAttributes.  Should call Proc
      for every value that is acceptable for this property.  TEnumPropertyEditor
      will pass every element in the enumeration.
    Initialize
      Called after the property editor has been created but before it is used.
      Many times property editors are created and because they are not a common
      property across the entire selection they are thrown away.  Initialize is
      called after it is determined the property editor is going to be used by
      the object inspector and not just thrown away.
    SetValue(Value)
      Called to set the value of the property.  The property editor should be
      able to translate the string and call one of the SetXxxValue methods. If
      the string is not in the correct format or not an allowed value,the
      property editor should generate an exception describing the problem. Set
      value can ignore all changes and allow all editing of the property be
      accomplished through the Edit method (e.g. the Picture property).
    ListMeasureWidth(Value,Canvas,AWidth)
      This is called during the width calculation phase of the drop down list
      preparation.
    ListMeasureHeight(Value,Canvas,AHeight)
      This is called during the item/value height calculation phase of the drop
      down list's render.  This is very similar to TListBox's OnMeasureItem,
      just slightly different parameters.
    ListDrawValue(Value,Canvas,Rect,Selected)
      This is called during the item/value render phase of the drop down list's
      render.  This is very similar to TListBox's OnDrawItem, just slightly
      different parameters.
    PropMeasureHeight(Value,Canvas,AHeight)
      This is called during the item/property height calculation phase of the
      object inspectors rows render. This is very similar to TListBox's
      OnMeasureItem, just slightly different parameters.
    PropDrawName(Canvas,Rect,Selected)
      Called during the render of the name column of the property list.  Its
      functionality is very similar to TListBox's OnDrawItem,but once again
      it has slightly different parameters.
    PropDrawValue(Canvas,Rect,Selected)
      Called during the render of the value column of the property list.  Its
      functionality is similar to PropDrawName.  If multiple items are selected
      and their values don't match this procedure will be passed an empty
      value.

  Properties and methods useful in creating a new TPropertyEditor classes:

    Name property
      Returns the name of the property returned by GetName
    PrivateEditory property
      It is either the .EXE or the "working editory" as specified in
      the registry under the key:
        "HKEY_CURRENT_USER\Software\Borland\Delphi\*\Globals\PrivateDir"
      If the property editor needs auxiliary or state files (templates,
      examples, etc) they should be stored in this editory.
    Value property
      The current value,as a string,of the property as returned by GetValue.
    Modified
      Called to indicate the value of the property has been modified.  Called
      automatically by the SetXxxValue methods.  If you call a TProperty
      SetXxxValue method directly,you *must* call Modified as well.
    GetXxxValue
      Gets the value of the first property in the Properties property.  Calls
      the appropriate TProperty GetXxxValue method to retrieve the value.
    SetXxxValue
      Sets the value of all the properties in the Properties property.  Calls
      the approprate TProperty SetXxxxValue methods to set the value.
    GetVisualValue
      This function will return the displayable value of the property.  If
      only one item is selected or all the multi-selected items have the same
      property value then this function will return the actual property value.
      Otherwise this function will return an empty string.}

  TPropertyAttribute=(paValueList,paSubProperties,paDialog,paMultiSelect,
    paAutoUpdate,paSortList,paReadOnly,paRevertable,paFullWidthName);
  TPropertyAttributes=set of TPropertyAttribute;

  TPropertyEditor=class;

  TInstProp=record
    Instance:TPersistent;
    PropInfo:PPropInfo;
  end;

  PInstPropList=^TInstPropList;
  TInstPropList=array[0..1023] of TInstProp;

  TGetPropEditProc=procedure(Prop:TPropertyEditor) of object;

  TPropEditDrawStateType = (pedsSelected, pedsFocused, pedsInEdit,
       pedsInComboList);
  TPropEditDrawState = set of TPropEditDrawStateType;

  TPropertyEditor=class
  private
    // XXX
    //FDesigner:IFormDesigner;
    FComponents:TComponentSelectionList;
    FPropList:PInstPropList;
    FPropCount:Integer;
    function GetPrivateDirectory:string;
    procedure SetPropEntry(Index:Integer; AInstance:TPersistent;
      APropInfo:PPropInfo);
  protected
    // XXX these functions could be transfered to the TComponentInterface
    function GetPropInfo:PPropInfo;
    function GetFloatValue:Extended;
    function GetFloatValueAt(Index:Integer):Extended;
    function GetInt64Value:Int64;
    function GetInt64ValueAt(Index:Integer):Int64;
    function GetMethodValue:TMethod;
    function GetMethodValueAt(Index:Integer):TMethod;
    function GetOrdValue:Longint;
    function GetOrdValueAt(Index:Integer):Longint;
    function GetStrValue:string;
    function GetStrValueAt(Index:Integer):string;
    function GetVarValue:Variant;
    function GetVarValueAt(Index:Integer):Variant;
    procedure SetFloatValue(NewValue:Extended);
    procedure SetMethodValue(const NewValue:TMethod);
    procedure SetInt64Value(NewValue:Int64);
    procedure SetOrdValue(NewValue:Longint);
    procedure SetStrValue(const NewValue:string);
    procedure SetVarValue(const NewValue:Variant);
    procedure Modified;
  public
    constructor Create({const ADesigner:IFormDesigner;}
      ComponentList:TComponentSelectionList;  APropCount:Integer); virtual;
    destructor Destroy; override;
    procedure Activate; virtual;
    procedure Deactivate; virtual;
    function AllEqual:Boolean; virtual;
    function AutoFill:Boolean; virtual;
    procedure Edit; virtual;
    function GetAttributes:TPropertyAttributes; virtual;
    function GetComponent(Index:Integer):TPersistent;
    function GetEditLimit:Integer; virtual;
    function GetName:string; virtual;
    procedure GetProperties(Proc:TGetPropEditProc); virtual;
    function GetPropType:PTypeInfo;
    function GetValue:string; virtual;
    function GetVisualValue:string;
    procedure GetValues(Proc:TGetStringProc); virtual;
    procedure Initialize; virtual;
    procedure Revert;
    procedure SetValue(const NewValue:string); virtual;
    function ValueAvailable:Boolean;
    procedure ListMeasureWidth(const NewValue:string; Index:integer;
      ACanvas:TCanvas;  var AWidth:Integer); dynamic;
    procedure ListMeasureHeight(const NewValue:string; Index:integer;
      ACanvas:TCanvas;  var AHeight:Integer); dynamic;
    procedure ListDrawValue(const NewValue:string; Index:integer;
      ACanvas:TCanvas;  const ARect:TRect; State: TPropEditDrawState); dynamic;
    procedure PropMeasureHeight(const NewValue:string;  ACanvas:TCanvas;
      var AHeight:Integer); dynamic;
    procedure PropDrawName(ACanvas:TCanvas; const ARect:TRect;
      State:TPropEditDrawState); dynamic;
    procedure PropDrawValue(ACanvas:TCanvas; const ARect:TRect;
      State:TPropEditDrawState); dynamic;
    //property Designer:IFormDesigner read FDesigner;
    property PrivateDirectory:string read GetPrivateDirectory;
    property PropCount:Integer read FPropCount;
    property Value2:string read GetValue write SetValue;
  end;

  TPropertyEditorClass=class of TPropertyEditor;

{ TOrdinalPropertyEditor
  The base class of all ordinal property editors.  It establishes that ordinal
  properties are all equal if the GetOrdValue all return the same value. }

  TOrdinalPropertyEditor = class(TPropertyEditor)
    function AllEqual: Boolean; override;
    function GetEditLimit: Integer; override;
  end;

{ TIntegerPropertyEditor
  Default editor for all Longint properties and all subtypes of the Longint
  type (i.e. Integer, Word, 1..10, etc.).  Restricts the value entered into
  the property to the range of the sub-type. }

  TIntegerPropertyEditor = class(TOrdinalPropertyEditor)
  public
    function GetValue: string; override;
    procedure SetValue(const NewValue: string);  override;
  end;

{ TCharPropertyEditor
  Default editor for all Char properties and sub-types of Char (i.e. Char,
  'A'..'Z', etc.). }

  TCharPropertyEditor = class(TOrdinalPropertyEditor)
  public
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TEnumPropertyEditor
  The default property editor for all enumerated properties (e.g. TShape =
  (sCircle, sTriangle, sSquare), etc.). }

  TEnumPropertyEditor = class(TOrdinalPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStringProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TBoolPropertyEditor
  Default property editor for all boolean properties }

  TBoolPropertyEditor = class(TEnumPropertyEditor)
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStringProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TInt64PropertyEditor
  Default editor for all Int64 properties and all subtypes of Int64.  }

  TInt64PropertyEditor = class(TPropertyEditor)
  public
    function AllEqual: Boolean; override;
    function GetEditLimit: Integer; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TFloatPropertyEditor
  The default property editor for all floating point types (e.g. Float,
  Single, Double, etc.) }

  TFloatPropertyEditor = class(TPropertyEditor)
  public
    function AllEqual: Boolean; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TStringPropertyEditor
  The default property editor for all strings and sub types (e.g. string,
  string[20], etc.). }

  TStringPropertyEditor = class(TPropertyEditor)
  public
    function AllEqual: Boolean; override;
    function GetEditLimit: Integer; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TNestedPropertyEditor
  A property editor that uses the parent's Designer, PropList and PropCount.
  The constructor and destructor do not call inherited, but all derived classes
  should.  This is useful for properties like the TSetElementPropertyEditor. }

  TNestedPropertyEditor = class(TPropertyEditor)
  public
    constructor Create(Parent: TPropertyEditor);
    destructor Destroy; override;
  end;

{ TSetElementPropertyEditor
  A property editor that edits an individual set element.  GetName is
  changed to display the set element name instead of the property name and
  Get/SetValue is changed to reflect the individual element state.  This
  editor is created by the TSetPropertyEditor editor. }

  TSetElementPropertyEditor = class(TNestedPropertyEditor)
  private
    FElement: Integer;
  public
    constructor Create(Parent: TPropertyEditor; AElement: Integer);
    function AllEqual: Boolean; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetName: string; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStringProc); override;
    procedure SetValue(const Value: string); override;
   end;

{ TSetPropertyEditor
  Default property editor for all set properties. This editor does not edit
  the set directly but will display sub-properties for each element of the
  set. GetValue displays the value of the set in standard set syntax. }

  TSetPropertyEditor = class(TOrdinalPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetProperties(Proc: TGetPropEditProc); override;
    function GetValue: string; override;
  end;

{ TClassPropertyEditor
  Default property editor for all objects.  Does not allow modifying the
  property but does display the class name of the object and will allow the
  editing of the object's properties as sub-properties of the property. }

  TClassPropertyEditor = class(TPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetProperties(Proc: TGetPropEditProc); override;
    function GetValue: string; override;
  end;

{ TComponentPropertyEditor
  The default editor for TComponents.  It does not allow editing of the
  properties of the component.  It allow the user to set the value of this
  property to point to a component in the same form that is type compatible
  with the property being edited (e.g. the ActiveControl property). }

  TComponentPropertyEditor = class(TPropertyEditor)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetEditLimit: Integer; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStringProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TComponentNamePropertyEditor
  Property editor for the Name property.  It restricts the name property
  from being displayed when more than one component is selected. }

  TComponentNamePropertyEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetEditLimit: Integer; override;
  end;

{ TColorPropertyEditor
  PropertyEditor editor for the TColor type.  Displays the color as a clXXX value
  if one exists, otherwise displays the value as hex.  Also allows the
  clXXX value to be picked from a list. }

  TColorPropertyEditor = class(TIntegerPropertyEditor)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStringProc); override;
    procedure SetValue(const Value: string); override;

    procedure ListMeasureWidth(const NewValue:string; Index:integer;
      ACanvas:TCanvas;  var AWidth:Integer);  override;
    procedure ListDrawValue(const NewValue:string; Index:integer;
      ACanvas:TCanvas;  const ARect:TRect; State: TPropEditDrawState); override;
    procedure PropDrawValue(ACanvas:TCanvas; const ARect:TRect;
      State:TPropEditDrawState); override;
  end;


//==============================================================================

{ RegisterPropertyEditor
  Registers a new property editor for the given type.  When a component is
  selected the Object Inspector will create a property editor for each
  of the component's properties.  The property editor is created based on
  the type of the property.  If,for example,the property type is an
  Integer,the property editor for Integer will be created (by default
  that would be TIntegerPropertyEditor). Most properties do not need specialized
  property editors.  For example, if the property is an ordinal type the
  default property editor will restrict the range to the ordinal subtype
  range (e.g. a property of type TMyRange=1..10 will only allow values
  between 1 and 10 to be entered into the property).  Enumerated types will
  display a drop-down list of all the enumerated values (e.g. TShapes =
  (sCircle,sSquare,sTriangle) will be edited by a drop-down list containing
  only sCircle,sSquare and sTriangle).  A property editor need only be
  created if default property editor or none of the existing property editors
  are sufficient to edit the property.  This is typically because the
  property is an object.  The properties are looked up newest to oldest.
  This allows and existing property editor replaced by a custom property
  editor.

    PropertyEditorType
      The type information pointer returned by the TypeInfo built-in function
      (e.g. TypeInfo(TMyRange) or TypeInfo(TShapes)).

    ComponentClass
      Type of the component to which to restrict this type editor.  This
      parameter can be left nil which will mean this type editor applies to all
      properties of PropertyEditorType.

    PropertyEditorName
      The name of the property to which to restrict this type editor.  This
      parameter is ignored if ComponentClass is nil.  This parameter can be
      an empty string ('') which will mean that this editor applies to all
      properties of PropertyEditorType in ComponentClass.

    editorClass
      The class of the editor to be created whenever a property of the type
      passed in PropertyEditorTypeInfo is displayed in the Object Inspector.
      The class will be created by calling EditorClass.Create. }

procedure RegisterPropertyEditor(PropertyType:PTypeInfo;
  ComponentClass:TClass;  const PropertyName:string;
  EditorClass:TPropertyEditorClass);

type
  TPropertyEditorMapperFunc=function(Obj:TPersistent;
    PropInfo:PPropInfo):TPropertyEditorClass;

procedure RegisterPropertyEditorMapper(Mapper:TPropertyEditorMapperFunc);

procedure GetComponentProperties(Components:TComponentSelectionList;
  Filter:TTypeKinds; Proc:TGetPropEditProc);

//procedure RegisterComponentEditor(ComponentClass:TComponentClass;
//  ComponentEditor:TComponentEditorClass);

//function GetComponentEditor(Component:TComponent;
//  Designer:IFormDesigner):TComponentEditor;


//==============================================================================

{ TMessageDialog
  The TMessageDialog form is a simple dialog like Delphis ShowMessage
}

type
  TMessageDialog = class(TForm)
  public
    OkButton:TButton;
    TextLabel:TLabel;
    procedure OkButtonClick(Sender:TObject);
    constructor Create(AOwner: TComponent); override;
  end;

procedure ShowMessageDialog(const s:string);

//==============================================================================

implementation

uses Dialogs, Math;

//==============================================================================

procedure ShowMessageDialog(const s:string);
var MessageDialog:TMessageDialog;
begin
  MessageDialog:=TMessageDialog.Create(Application);
  MessageDialog.TextLabel.Caption:=s;
  try
    MessageDialog.ShowModal;
  finally
    MessageDialog.Free;
  end;
end;

constructor TMessageDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //Position:=poFormCenter;
  Width:=400;
  Height:=100;
  // OkButton
  OkButton:=TButton.Create(Self);
  with OkButton do begin
    Name:='OkButton';
    Parent:=Self;
    Caption:='OK';
    SetBounds(150,70,100,20);
    OnClick:=@OkButtonClick;
    Show;
  end;
  // TextLabel
  TextLabel:=TLabel.Create(Self);
  with TextLabel do begin
    Name:='TextLabel';
    Parent:=Self;
    WordWrap:=true;
    SetBounds(10,10,380,20);
    Show;
  end;
end;

procedure TMessageDialog.OkButtonClick(Sender:TObject);
begin
  ModalResult:=1;
end;

//==============================================================================

const
{ TypeKinds  see typinfo.pp
       TTypeKind = (tkUnknown,tkInteger,tkChar,tkEnumeration,
                   tkFloat,tkSet,tkMethod,tkSString,tkLString,tkAString,
                   tkWString,tkVariant,tkArray,tkRecord,tkInterface,
                   tkClass,tkObject,tkWChar,tkBool,tkInt64,tkQWord);
}

  PropClassMap:array[TypInfo.TTypeKind] of TPropertyEditorClass=(
    nil,                   // tkUnknown
    TIntegerPropertyEditor,// tkInteger
    TCharpropertyEditor,   // tkChar
    TEnumPropertyEditor,   // tkEnumeration
    TFloatPropertyEditor,  // tkFloat
    TSetPropertyEditor,    // tkSet
    nil,                   // tkMethod
    TStringPropertyEditor, // tkSString
    TStringPropertyEditor, // tkLString
    TStringPropertyEditor, // tkAString
    TStringPropertyEditor, // tkWString
    TPropertyEditor,       // tkVariant
    nil,                   // tkArray
    nil,                   // tkRecord
    nil,                   // tkInterface
    TClassPropertyEditor,  // tkClass
    nil,                   // tkObject
    TPropertyEditor,       // tkWChar
    TBoolPropertyEditor,   // tkBool
    TInt64PropertyEditor,  // tkInt64
    nil                    // tkQWord
    );

// XXX ToDo: These variables/functions have bugs. Thus I provide my own ------

function StrToInt64(const s:string):int64;
var p:integer;
  negated:boolean;
begin
  p:=1;
  while (p<=length(s)) and (s[p]=' ') do inc(p);
  if (p<=length(s)) and (s[p]='-') then begin
    negated:=true;
    inc(p);
    while (p<=length(s)) and (s[p]=' ') do inc(p);
  end else begin
    negated:=false;
  end;
  Result:=0;
  while (p<=length(s)) and (s[p]>='0') and (s[p]<='9') do begin
    Result:=Result*10+ord(s[p])-ord('0');
    inc(p);
  end;
  if negated then Result:=-Result;
end;

// XXX ToDo: These variables/functions should be moved to graphics.pp  ------

{ Color mapping routines }

const
  Colors: array[0..41] of TIdentMapEntry = (
    (Value: clBlack; Name: 'clBlack'),
    (Value: clMaroon; Name: 'clMaroon'),
    (Value: clGreen; Name: 'clGreen'),
    (Value: clOlive; Name: 'clOlive'),
    (Value: clNavy; Name: 'clNavy'),
    (Value: clPurple; Name: 'clPurple'),
    (Value: clTeal; Name: 'clTeal'),
    (Value: clGray; Name: 'clGray'),
    (Value: clSilver; Name: 'clSilver'),
    (Value: clRed; Name: 'clRed'),
    (Value: clLime; Name: 'clLime'),
    (Value: clYellow; Name: 'clYellow'),
    (Value: clBlue; Name: 'clBlue'),
    (Value: clFuchsia; Name: 'clFuchsia'),
    (Value: clAqua; Name: 'clAqua'),
    (Value: clWhite; Name: 'clWhite'),
    (Value: clScrollBar; Name: 'clScrollBar'),
    (Value: clBackground; Name: 'clBackground'),
    (Value: clActiveCaption; Name: 'clActiveCaption'),
    (Value: clInactiveCaption; Name: 'clInactiveCaption'),
    (Value: clMenu; Name: 'clMenu'),
    (Value: clWindow; Name: 'clWindow'),
    (Value: clWindowFrame; Name: 'clWindowFrame'),
    (Value: clMenuText; Name: 'clMenuText'),
    (Value: clWindowText; Name: 'clWindowText'),
    (Value: clCaptionText; Name: 'clCaptionText'),
    (Value: clActiveBorder; Name: 'clActiveBorder'),
    (Value: clInactiveBorder; Name: 'clInactiveBorder'),
    (Value: clAppWorkSpace; Name: 'clAppWorkSpace'),
    (Value: clHighlight; Name: 'clHighlight'),
    (Value: clHighlightText; Name: 'clHighlightText'),
    (Value: clBtnFace; Name: 'clBtnFace'),
    (Value: clBtnShadow; Name: 'clBtnShadow'),
    (Value: clGrayText; Name: 'clGrayText'),
    (Value: clBtnText; Name: 'clBtnText'),
    (Value: clInactiveCaptionText; Name: 'clInactiveCaptionText'),
    (Value: clBtnHighlight; Name: 'clBtnHighlight'),
    (Value: cl3DDkShadow; Name: 'cl3DDkShadow'),
    (Value: cl3DLight; Name: 'cl3DLight'),
    (Value: clInfoText; Name: 'clInfoText'),
    (Value: clInfoBk; Name: 'clInfoBk'),
    (Value: clNone; Name: 'clNone'));

function ColorToIdent(Color: Longint; var Ident: AnsiString): Boolean;
begin
  Result := IntToIdent(Color, Ident, Colors);
end;

function IdentToColor(const Ident: string; var Color: Longint): Boolean;
begin
  Result := IdentToInt(Ident, Color, Colors);
end;

{function ColorToRGB(Color: TColor): Longint;
begin
  if Color < 0 then
    Result := GetSysColor(Color and $000000FF) else
    Result := Color;
end;}

function ColorToString(Color: TColor): AnsiString;
begin
  if not ColorToIdent(Color, Result) then
    Result:='$'+HexStr(Color,8);
end;

function StringToColor(const S: string): TColor;
begin
  if not IdentToColor(S, Longint(Result)) then
    Result := TColor(StrToInt(S));
end;

procedure GetColorValues(Proc: TGetStringProc);
var
  I: Integer;
begin
  for I := Low(Colors) to High(Colors) do Proc(Colors[I].Name);
end;

// -----------------------------------------------------------

var
  PropertyEditorMapperList:TList;
  PropertyClassList:TList;

type
  PPropertyClassRec=^TPropertyClassRec;
  TPropertyClassRec=record
    // XXX
    //Group:Integer;
    PropertyType:PTypeInfo;
    PropertyName:string;
    ComponentClass:TClass;
    EditorClass:TPropertyEditorClass;
  end;

  PPropertyEditorMapperRec=^TPropertyEditorMapperRec;
  TPropertyEditorMapperRec=record
    // XXX
    //Group:Integer;
    Mapper:TPropertyEditorMapperFunc;
  end;

{ TPropInfoList }

type
  TPropInfoList=class
  private
    FList:PPropList;
    FCount:Integer;
    FSize:Integer;
    function Get(Index:Integer):PPropInfo;
  public
    constructor Create(Instance:TPersistent; Filter:TTypeKinds);
    destructor Destroy; override;
    function Contains(P:PPropInfo):Boolean;
    procedure Delete(Index:Integer);
    procedure Intersect(List:TPropInfoList);
    property Count:Integer read FCount;
    property Items[Index:Integer]:PPropInfo read Get; default;
  end;

constructor TPropInfoList.Create(Instance:TPersistent; Filter:TTypeKinds);
var AllSize:integer;
  TypeInfo : PTypeInfo;
begin
  TypeInfo:=Instance.ClassInfo;

  // get filtered count
  // XXX, Delphi can do this easier. Must talk to typinfo developer...
  AllSize:=GetTypeData(TypeInfo)^.Propcount * SizeOf(Pointer);
  GetMem(FList,AllSize);
  FCount:=GetPropList(TypeInfo,Filter,FList);
  FreeMem(FList,AllSize);

  // get PropInfoList
  FSize:=FCount * SizeOf(Pointer);
  GetMem(FList,FSize);
  GetPropList(TypeInfo,Filter,FList);
end;

destructor TPropInfoList.Destroy;
begin
  if FList<>nil then FreeMem(FList,FSize);
end;

function TPropInfoList.Contains(P:PPropInfo):Boolean;
var
  I:Integer;
begin
  for I:=0 to FCount-1 do begin
    with FList^[I]^ do begin
      if (PropType^.Kind=P^.PropType^.Kind)
      and (CompareText(Name,P^.Name)=0) then begin
        Result:=True;
        Exit;
      end;
    end;
  end;
  Result:=False;
end;

procedure TPropInfoList.Delete(Index:Integer);
begin
  Dec(FCount);
  if Index < FCount then
    Move(FList^[Index+1],FList^[Index],
      (FCount-Index) * SizeOf(Pointer));
end;

function TPropInfoList.Get(Index:Integer):PPropInfo;
begin
  Result:=FList^[Index];
end;

procedure TPropInfoList.Intersect(List:TPropInfoList);
var
  I:Integer;
begin
  for I:=FCount-1 downto 0 do
    if not List.Contains(FList^[I]) then Delete(I);
end;

{ GetComponentProperties }

procedure RegisterPropertyEditor(PropertyType:PTypeInfo;
ComponentClass:TClass;  const PropertyName:string;
EditorClass:TPropertyEditorClass);
var
  P:PPropertyClassRec;
begin
  if PropertyClassList=nil then
    PropertyClassList:=TList.Create;
  New(P);
  // XXX
  //P^.Group:=CurrentGroup;
  P^.PropertyType:=PropertyType;
  P^.ComponentClass:=ComponentClass;
  P^.PropertyName:='';
  if Assigned(ComponentClass) then P^.PropertyName:=PropertyName;
  P^.EditorClass:=EditorClass;
  PropertyClassList.Insert(0,P);
end;

procedure RegisterPropertyEditorMapper(Mapper:TPropertyEditorMapperFunc);
var
  P:PPropertyEditorMapperRec;
begin
  if PropertyEditorMapperList=nil then
    PropertyEditorMapperList:=TList.Create;
  New(P);
  // XXX
  //P^.Group:=CurrentGroup;
  P^.Mapper:=Mapper;
  PropertyEditorMapperList.Insert(0,P);
end;

function GetEditorClass(PropInfo:PPropInfo;
  Obj:TPersistent):TPropertyEditorClass;
var
  PropType:PTypeInfo;
  P,C:PPropertyClassRec;
  I:Integer;
begin
  if PropertyEditorMapperList<>nil then begin
    for I:=0 to PropertyEditorMapperList.Count-1 do begin
      with PPropertyEditorMapperRec(PropertyEditorMapperList[I])^ do begin
        Result:=Mapper(Obj,PropInfo);
        if Result<>nil then Exit;
      end;
    end;
  end;
  PropType:=PropInfo^.PropType;
  I:=0;
  C:=nil;
  while I < PropertyClassList.Count do begin
    P:=PropertyClassList[I];

    if ((P^.PropertyType=PropType) or
         ((P^.PropertyType^.Kind=PropType^.Kind) and
          (P^.PropertyType^.Name=PropType^.Name)
         )
       ) or
       ( (PropType^.Kind=tkClass) and
         (P^.PropertyType^.Kind=tkClass) and
         GetTypeData(PropType)^.ClassType.InheritsFrom(GetTypeData(P^.PropertyType)^.ClassType)
       ) then
      if ((P^.ComponentClass=nil) or (Obj.InheritsFrom(P^.ComponentClass))) and
         ((P^.PropertyName='') or (CompareText(PropInfo^.Name,P^.PropertyName)=0)) then
        if (C=nil) or   // see if P is better match than C
           ((C^.ComponentClass=nil) and (P^.ComponentClass<>nil)) or
           ((C^.PropertyName='') and (P^.PropertyName<>''))
           or  // P's proptype match is exact,but C's isn't
           ((C^.PropertyType<>PropType) and (P^.PropertyType=PropType))
           or  // P's proptype is more specific than C's proptype
           ((P^.PropertyType<>C^.PropertyType) and
            (P^.PropertyType^.Kind=tkClass) and
            (C^.PropertyType^.Kind=tkClass) and
            GetTypeData(P^.PropertyType)^.ClassType.InheritsFrom(
              GetTypeData(C^.PropertyType)^.ClassType))
           or // P's component class is more specific than C's component class
           ((P^.ComponentClass<>nil) and (C^.ComponentClass<>nil) and
            (P^.ComponentClass<>C^.ComponentClass) and
            (P^.ComponentClass.InheritsFrom(C^.ComponentClass))) then
          C:=P;
    Inc(I);
  end;
  if C<>nil then
    Result:=C^.EditorClass else
    Result:=PropClassMap[PropType^.Kind];
end;

procedure GetComponentProperties(Components:TComponentSelectionList;
  Filter:TTypeKinds; Proc:TGetPropEditProc);
var
  I,J,CompCount:Integer;
  CompType:TClass;
  Candidates:TPropInfoList;
  PropLists:TList;
  Editor:TPropertyEditor;
  DirClass:TPropertyEditorClass;
  PropInfo:PPropInfo;
  AddEditor:Boolean;
  Obj:TPersistent;
begin
  if (Components=nil) or (Components.Count=0) then Exit;
  CompCount:=Components.Count;
  Obj:=Components[0];
  CompType:=Components[0].ClassType;
  Candidates:=TPropInfoList.Create(Components[0],Filter);
  try
    for I:=Candidates.Count-1 downto 0 do begin
      PropInfo:=Candidates[I];
      DirClass:=GetEditorClass(PropInfo,Obj);
      if DirClass=nil then
        Candidates.Delete(I)
      else begin
        Editor:=DirClass.Create(Components,1);
        try
          Editor.SetPropEntry(0,Components[0],PropInfo);
          Editor.Initialize;
          with PropInfo^ do
            if (GetProc=nil)
            or ((PropType^.Kind<>tkClass) and (SetProc=nil))
            or ((CompCount > 1) and not (paMultiSelect in Editor.GetAttributes))
            or (not Editor.ValueAvailable) then
              Candidates.Delete(I);
        finally
          Editor.Free;
        end;
      end;
    end;
    PropLists:=TList.Create;
    try
      PropLists.Capacity:=CompCount;
      for I:=0 to CompCount-1 do
        PropLists.Add(TPropInfoList.Create(Components[I],Filter));
      for I:=0 to CompCount-1 do
        Candidates.Intersect(TPropInfoList(PropLists[I]));
      for I:=0 to CompCount-1 do
        TPropInfoList(PropLists[I]).Intersect(Candidates);
      for I:=0 to Candidates.Count-1 do begin
        DirClass:=GetEditorClass(Candidates[I],Obj);
        if DirClass=nil then continue;
        Editor:=DirClass.Create(Components,CompCount);
        try
          AddEditor:=true;
          for j:=0 to CompCount-1 do begin
            if (Components[j].ClassType<>CompType) and
              (GetEditorClass(TPropInfoList(PropLists[j])[I],Components[j])
              <>Editor.ClassType) then
            begin
              AddEditor:=false;
              break;
            end;
            Editor.SetPropEntry(J,Components[J],
              TPropInfoList(PropLists[J])[I]);
          end;
        except
          Editor.Free;
          raise;
        end;
        if AddEditor then
        begin
          Editor.Initialize;
          if Editor.ValueAvailable then
            Proc(Editor) else
            Editor.Free;
        end
        else Editor.Free;
      end;
    finally
      for I:=0 to PropLists.Count-1 do TPropInfoList(PropLists[I]).Free;
      PropLists.Free;
    end;
  finally
    Candidates.Free;
  end;
end;

{ TPropertyEditor }

constructor TPropertyEditor.Create({const ADesigner:IFormDesigner;}
  ComponentList:TComponentSelectionList;  APropCount:Integer);
begin
  // XXX
  //FDesigner:=ADesigner;
  FComponents:=ComponentList;
  GetMem(FPropList,APropCount * SizeOf(TInstProp));
  FPropCount:=APropCount;
end;

destructor TPropertyEditor.Destroy;
begin
  if FPropList<>nil then
    FreeMem(FPropList,FPropCount * SizeOf(TInstProp));
end;

procedure TPropertyEditor.Activate;
begin
  //
end;

procedure TPropertyEditor.Deactivate;
begin
  //
end;

function TPropertyEditor.AllEqual:Boolean;
begin
  Result:=FPropCount=1;
end;

procedure TPropertyEditor.Edit;
type
  TGetStrFunc=function(const Value:string):Integer of object;
var
  I:Integer;
  Values:TStringList;
  AddValue:TGetStrFunc;
begin
  if not AutoFill then Exit;
  Values:=TStringList.Create;
  Values.Sorted:=paSortList in GetAttributes;
  try
    AddValue:=@Values.Add;
    GetValues(TGetStringProc(AddValue));
    if Values.Count > 0 then begin
      I:=Values.IndexOf(Value2)+1;
      if I=Values.Count then I:=0;
      Value2:=Values[I];
    end;
  finally
    Values.Free;
  end;
end;

function TPropertyEditor.AutoFill:Boolean;
begin
  Result:=True;
end;

function TPropertyEditor.GetAttributes:TPropertyAttributes;
begin
  Result:=[paMultiSelect,paRevertable];
end;

function TPropertyEditor.GetComponent(Index:Integer):TPersistent;
begin
  Result:=FPropList^[Index].Instance;
end;

function TPropertyEditor.GetFloatValue:Extended;
begin
  Result:=GetFloatValueAt(0);
end;

function TPropertyEditor.GetFloatValueAt(Index:Integer):Extended;
begin
  with FPropList^[Index] do Result:=GetFloatProp(Instance,PropInfo);
end;

function TPropertyEditor.GetMethodValue:TMethod;
begin
  Result:=GetMethodValueAt(0);
end;

function TPropertyEditor.GetMethodValueAt(Index:Integer):TMethod;
begin
  with FPropList^[Index] do Result:=GetMethodProp(Instance,PropInfo);
end;

function TPropertyEditor.GetEditLimit:Integer;
begin
  Result:=255;
end;

function TPropertyEditor.GetName:string;
begin
  Result:=FPropList^[0].PropInfo^.Name;
end;

function TPropertyEditor.GetOrdValue:Longint;
begin
  Result:=GetOrdValueAt(0);
end;

function TPropertyEditor.GetOrdValueAt(Index:Integer):Longint;
begin
  with FPropList^[Index] do Result:=GetOrdProp(Instance,PropInfo);
end;

function TPropertyEditor.GetPrivateDirectory:string;
begin
  Result:='';
  // XXX
  //if Designer<>nil then
  //  Result:=Designer.GetPrivateDirectory;
end;

procedure TPropertyEditor.GetProperties(Proc:TGetPropEditProc);
begin
  //
end;

function TPropertyEditor.GetPropInfo:PPropInfo;
begin
  Result:=FPropList^[0].PropInfo;
end;

function TPropertyEditor.GetPropType:PTypeInfo;
begin
  Result:=FPropList^[0].PropInfo^.PropType;
end;

function TPropertyEditor.GetStrValue:string;
begin
  Result:=GetStrValueAt(0);
end;

function TPropertyEditor.GetStrValueAt(Index:Integer):string;
begin
  with FPropList^[Index] do Result:=GetStrProp(Instance,PropInfo);
end;

function TPropertyEditor.GetVarValue:Variant;
begin
  Result:=GetVarValueAt(0);
end;

function TPropertyEditor.GetVarValueAt(Index:Integer):Variant;
begin
  with FPropList^[Index] do Result:=GetVariantProp(Instance,PropInfo);
end;

function TPropertyEditor.GetValue:string;
begin
  Result:=srUnknown;
end;

function TPropertyEditor.GetVisualValue:string;
begin
  if AllEqual then
    Result:=GetValue
  else
    Result:='';
end;

procedure TPropertyEditor.GetValues(Proc:TGetStringProc);
begin
end;

procedure TPropertyEditor.Initialize;
begin
  //
end;

procedure TPropertyEditor.Modified;
begin
  // XXX
  //if Designer<>nil then
  //  Designer.Modified;
end;

procedure TPropertyEditor.SetFloatValue(NewValue:Extended);
var
  I:Integer;
begin
  for I:=0 to FPropCount-1 do
    with FPropList^[I] do SetFloatProp(Instance,PropInfo,NewValue);
  Modified;
end;

procedure TPropertyEditor.SetMethodValue(const NewValue:TMethod);
var
  I:Integer;
begin
  for I:=0 to FPropCount-1 do
    with FPropList^[I] do SetMethodProp(Instance,PropInfo,NewValue);
  Modified;
end;

procedure TPropertyEditor.SetOrdValue(NewValue:Longint);
var
  I:Integer;
begin
  for I:=0 to FPropCount-1 do
    with FPropList^[I] do SetOrdProp(Instance,PropInfo,NewValue);
  Modified;
end;

procedure TPropertyEditor.SetPropEntry(Index:Integer;
  AInstance:TPersistent; APropInfo:PPropInfo);
begin
  with FPropList^[Index] do
  begin
    Instance:=AInstance;
    PropInfo:=APropInfo;
  end;
end;

procedure TPropertyEditor.SetStrValue(const NewValue:string);
var
  I:Integer;
begin
  for I:=0 to FPropCount-1 do
    with FPropList^[I] do SetStrProp(Instance,PropInfo,NewValue);
  Modified;
end;

procedure TPropertyEditor.SetVarValue(const NewValue:Variant);
var
  I:Integer;
begin
  for I:=0 to FPropCount-1 do
    with FPropList^[I] do SetVariantProp(Instance,PropInfo,NewValue);
  Modified;
end;

procedure TPropertyEditor.Revert;
//var I:Integer;
begin
  //if Designer<>nil then
  //  for I:=0 to FPropCount-1 do
  //    with FPropList^[I] do Designer.Revert(Instance,PropInfo);
end;

procedure TPropertyEditor.SetValue(const NewValue:string);
begin
end;

function TPropertyEditor.ValueAvailable:Boolean;
var
  I:Integer;
begin
  Result:=True;
  for I:=0 to FPropCount-1 do
  begin
    if (FPropList^[I].Instance is TComponent) and
      (csCheckPropAvail in TComponent(FPropList^[I].Instance).ComponentStyle) then
    begin
      try
        GetValue;
        AllEqual;
      except
        Result:=False;
      end;
      Exit;
    end;
  end;
end;

function TPropertyEditor.GetInt64Value:Int64;
begin
  Result:=GetInt64ValueAt(0);
end;

function TPropertyEditor.GetInt64ValueAt(Index:Integer):Int64;
begin
  with FPropList^[Index] do Result:=GetInt64Prop(Instance,PropInfo);
end;

procedure TPropertyEditor.SetInt64Value(NewValue:Int64);
var
  I:Integer;
begin
  for I:=0 to FPropCount-1 do
    with FPropList^[I] do SetInt64Prop(Instance,PropInfo,NewValue);
  Modified;
end;

{ these three procedures implement the default render behavior of the
  object/property inspector's drop down list editor. You don't need to
  override the two measure procedures if the default width or height don't
  need to be changed. }
procedure TPropertyEditor.ListMeasureHeight(const NewValue:string;
Index:integer;  ACanvas:TCanvas;  var AHeight:Integer);
begin
  //
end;

procedure TPropertyEditor.ListMeasureWidth(const NewValue:string; Index:integer;
  ACanvas:TCanvas;  var AWidth:Integer);
begin
  //
end;

procedure TPropertyEditor.ListDrawValue(const NewValue:string; Index:integer;
  ACanvas:TCanvas; const ARect:TRect; State: TPropEditDrawState);
var TextY:integer;
begin
  TextY:=((ARect.Bottom-ARect.Top-abs(ACanvas.Font.Height)) div 2)+ARect.Top-1;
  if ACanvas.Brush.Color<>clNone then
    ACanvas.FillRect(ARect);
  // XXX Todo: clipping
  ACanvas.TextOut(ARect.Left+1,TextY,NewValue);
end;

{ these three procedures implement the default render behavior of the
  object/property inspector. You don't need to override the measure procedure
  if the default width or height don't need to be changed.  }
procedure TPropertyEditor.PropMeasureHeight(const NewValue:string;
  ACanvas:TCanvas;  var AHeight:Integer);
begin
  //
end;

procedure TPropertyEditor.PropDrawName(ACanvas:TCanvas; const ARect:TRect;
  State:TPropEditDrawState);
var TextY:integer;
begin
  TextY:=((ARect.Bottom-ARect.Top-abs(ACanvas.Font.Height)) div 2)+ARect.Top-5;
  // XXX Todo: clipping
  ACanvas.TextOut(ARect.Left+2,TextY,GetName);
end;

procedure TPropertyEditor.PropDrawValue(ACanvas:TCanvas; const ARect:TRect;
  State:TPropEditDrawState);
var TextY:integer;
begin
  TextY:=((ARect.Bottom-ARect.Top-abs(ACanvas.Font.Height)) div 2)+ARect.Top-5;
  // XXX Todo: clipping
  ACanvas.TextOut(ARect.Left+2,TextY,GetVisualValue)
end;

{ TOrdinalPropertyEditor }

function TOrdinalPropertyEditor.AllEqual: Boolean;
var
  I: Integer;
  V: Longint;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetOrdValue;
    for I := 1 to PropCount - 1 do
      if GetOrdValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TOrdinalPropertyEditor.GetEditLimit: Integer;
begin
  Result := 63;
end;


{ TIntegerPropertyEditor }

function TIntegerPropertyEditor.GetValue: string;
begin
  with GetTypeData(GetPropType)^ do
    if OrdType = otULong then // unsigned
      Result := IntToStr(Cardinal(GetOrdValue))
    else
      Result := IntToStr(GetOrdValue);
end;

procedure TIntegerPropertyEditor.SetValue(const NewValue: String);

  procedure Error(const Args: array of const);
  begin
    // XXX
    {raise EPropertyError.CreateResFmt(@SOutOfRange, Args);}
  end;

var
  L: Int64;
begin
  L := StrToInt64(NewValue);
  with GetTypeData(GetPropType)^ do
    if OrdType = otULong then
    begin   // unsigned compare and reporting needed
      if (L < Cardinal(MinValue)) or (L > Cardinal(MaxValue)) then begin
        // bump up to Int64 to get past the %d in the format string
        Error([Int64(Cardinal(MinValue)), Int64(Cardinal(MaxValue))]);
        exit;
      end
    end
    else if (L < MinValue) or (L > MaxValue) then begin
      Error([MinValue, MaxValue]);
      exit;
    end;
  SetOrdValue(L);
end;

{ TCharPropertyEditor }

function TCharPropertyEditor.GetValue: string;
var
  Ch: Char;
begin
  Ch := Chr(GetOrdValue);
  if Ch in [#33..#127] then
    Result := Ch
  else
    Result:='#'+IntToStr(Ord(Ch));
end;

procedure TCharPropertyEditor.SetValue(const Value: string);
var
  L: Longint;
begin
  if Length(Value) = 0 then L := 0 else
    if Length(Value) = 1 then L := Ord(Value[1]) else
      if Value[1] = '#' then L := StrToInt(Copy(Value, 2, Maxint)) else begin
        {raise EPropertyError.CreateRes(@SInvalidPropertyValue)};
        exit;
      end;
  with GetTypeData(GetPropType)^ do
    if (L < MinValue) or (L > MaxValue) then begin
      {raise EPropertyError.CreateResFmt(@SOutOfRange, [MinValue, MaxValue])};
      exit;
    end;
  SetOrdValue(L);
end;

{ TEnumPropertyEditor }

function TEnumPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList, paRevertable];
end;

function TEnumPropertyEditor.GetValue: string;
var
  L: Longint;
begin
  L := GetOrdValue;
  with GetTypeData(GetPropType)^ do
    if (L < MinValue) or (L > MaxValue) then L := MaxValue;
  Result := GetEnumName(GetPropType, L);
end;

procedure TEnumPropertyEditor.GetValues(Proc: TGetStringProc);
var
  I: Integer;
  EnumType: PTypeInfo;
begin
  EnumType := GetPropType;
  with GetTypeData(EnumType)^ do
    for I := MinValue to MaxValue do Proc(GetEnumName(EnumType, I));
end;

procedure TEnumPropertyEditor.SetValue(const Value: string);
var
  I: Integer;
begin
  I := GetEnumValue(GetPropType, Value);
  if I < 0 then begin
    {raise EPropertyError.CreateRes(@SInvalidPropertyValue)};
    exit;
  end;
  SetOrdValue(I);
end;

{ TBoolPropertyEditor  }

function TBoolPropertyEditor.GetValue: string;
begin
  if GetOrdValue = 0 then
    Result := 'False'
  else
    Result := 'True';
end;

procedure TBoolPropertyEditor.GetValues(Proc: TGetStringProc);
begin
  Proc('False');
  Proc('True');
end;

procedure TBoolPropertyEditor.SetValue(const Value: string);
var
  I: Integer;
begin
  if CompareText(Value, 'False') = 0 then
    I := 0
  else if CompareText(Value, 'True') = 0 then
    I := -1
  else
    I := StrToInt(Value);
  SetOrdValue(I);
end;

{ TInt64PropertyEditor }

function TInt64PropertyEditor.AllEqual: Boolean;
var
  I: Integer;
  V: Int64;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetInt64Value;
    for I := 1 to PropCount - 1 do
      if GetInt64ValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TInt64PropertyEditor.GetEditLimit: Integer;
begin
  Result := 63;
end;

function TInt64PropertyEditor.GetValue: string;
begin
  Result := IntToStr(GetInt64Value);
end;

procedure TInt64PropertyEditor.SetValue(const Value: string);
begin
  SetInt64Value(StrToInt64(Value));
end;


{ TFloatPropertyEditor }

function TFloatPropertyEditor.AllEqual: Boolean;
var
  I: Integer;
  V: Extended;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetFloatValue;
    for I := 1 to PropCount - 1 do
      if GetFloatValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TFloatPropertyEditor.GetValue: string;
const
  Precisions: array[TFloatType] of Integer = (7, 15, 19, 19, 19, 15, 31);
begin
  Result := FloatToStrF(GetFloatValue, ffGeneral,
    Precisions[GetTypeData(GetPropType)^.FloatType], 0);
end;

procedure TFloatPropertyEditor.SetValue(const Value: string);
begin
  SetFloatValue(StrToFloat(Value));
end;

{ TStringPropertyEditor }

function TStringPropertyEditor.AllEqual: Boolean;
var
  I: Integer;
  V: string;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetStrValue;
    for I := 1 to PropCount - 1 do
      if GetStrValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TStringPropertyEditor.GetEditLimit: Integer;
begin
  if GetPropType^.Kind = tkString then
    Result := GetTypeData(GetPropType)^.MaxLength else
    Result := 255;
end;

function TStringPropertyEditor.GetValue: string;
begin
  Result := GetStrValue;
end;

procedure TStringPropertyEditor.SetValue(const Value: string);
begin
  SetStrValue(Value);
end;

{ TNestedPropertyEditor }

constructor TNestedPropertyEditor.Create(Parent: TPropertyEditor);
begin
  // XXX
  //FDesigner := Parent.Designer;
  FComponents:=Parent.FComponents;
  FPropList:=Parent.FPropList;
  FPropCount:=Parent.PropCount;
end;

destructor TNestedPropertyEditor.Destroy;
begin
end;

{ TSetElementPropertyEditor }

constructor TSetElementPropertyEditor.Create(Parent: TPropertyEditor;
 AElement: Integer);
begin
  inherited Create(Parent);
  FElement := AElement;
end;

function TSetElementPropertyEditor.AllEqual: Boolean;
var
  I: Integer;
  S: TIntegerSet;
  V: Boolean;
begin
  Result := False;
  if PropCount > 1 then begin
    Integer(S) := GetOrdValue;
    V := FElement in S;
    for I := 1 to PropCount - 1 do begin
      Integer(S) := GetOrdValueAt(I);
      if (FElement in S) <> V then Exit;
    end;
  end;
  Result := True;
end;

function TSetElementPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList];
end;

function TSetElementPropertyEditor.GetName: string;
begin
  Result := GetEnumName(GetTypeData(GetPropType)^.CompType, FElement);
end;

function TSetElementPropertyEditor.GetValue: string;
var
  S: TIntegerSet;
begin
  Integer(S) := GetOrdValue;
  Result := BooleanIdents[FElement in S];
end;

procedure TSetElementPropertyEditor.GetValues(Proc: TGetStringProc);
begin
  Proc(BooleanIdents[False]);
  Proc(BooleanIdents[True]);
end;

procedure TSetElementPropertyEditor.SetValue(const Value: string);
var
  S: TIntegerSet;
begin
  Integer(S) := GetOrdValue;
  if CompareText(Value, 'True') = 0 then
    Include(S, FElement) else
    Exclude(S, FElement);
  SetOrdValue(Integer(S));
end;

{ TSetPropertyEditor }

function TSetPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paSubProperties, paReadOnly, paRevertable];
end;

procedure TSetPropertyEditor.GetProperties(Proc: TGetPropEditProc);
var
  I: Integer;
begin
  with GetTypeData(GetTypeData(GetPropType)^.CompType)^ do
    for I := MinValue to MaxValue do
      Proc(TSetElementPropertyEditor.Create(Self, I));
end;

function TSetPropertyEditor.GetValue: string;
var
  S: TIntegerSet;
  TypeInfo: PTypeInfo;
  I: Integer;
begin
  Integer(S) := GetOrdValue;
  TypeInfo := GetTypeData(GetPropType)^.CompType;
  Result := '[';
  for I := 0 to SizeOf(Integer) * 8 - 1 do
    if I in S then
    begin
      if Length(Result) <> 1 then Result := Result + ',';
      Result := Result + GetEnumName(TypeInfo, I);
    end;
  Result := Result + ']';
end;

{ TClassPropertyEditor }

function TClassPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paSubProperties, paReadOnly];
end;

procedure TClassPropertyEditor.GetProperties(Proc: TGetPropEditProc);
var
  I: Integer;
  SubComponent: TComponent;
  Components: TComponentSelectionList;
begin
  Components := TComponentSelectionList.Create;
  try
    for I := 0 to PropCount - 1 do begin
      SubComponent:=TComponent(GetOrdValueAt(I));
      if SubComponent<>nil then
        Components.Add(SubComponent);
    end;
    GetComponentProperties(Components, tkProperties, Proc);
  finally
    Components.Free;
  end;
end;

function TClassPropertyEditor.GetValue: string;
begin
  Result:='('+GetPropType^.Name+')';
end;

{ TComponentPropertyEditor }

procedure TComponentPropertyEditor.Edit;
begin
  {if (GetKeyState(VK_CONTROL) < 0) and
     (GetKeyState(VK_LBUTTON) < 0) and
     (GetOrdValue <> 0) then begin
    Designer.SelectComponent(TPersistent(GetOrdValue))
  end else}
    inherited Edit;
end;

function TComponentPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList, paRevertable];
end;

function TComponentPropertyEditor.GetEditLimit: Integer;
begin
  Result := 127;
end;

function TComponentPropertyEditor.GetValue: string;
begin
  Result := '' {Designer.GetComponentName(TComponent(GetOrdValue))};
end;

procedure TComponentPropertyEditor.GetValues(Proc: TGetStringProc);
begin
  {Designer.GetComponentNames(GetTypeData(GetPropType), Proc);}
end;

procedure TComponentPropertyEditor.SetValue(const Value: string);
{var Component: TComponent;}
begin
  {if Value = '' then Component := nil else
  begin
    Component := Designer.GetComponent(Value);
    if not (Component is GetTypeData(GetPropType)^.ClassType) then
      raise EPropertyError.CreateRes(@SInvalidPropertyValue);
  end;
  SetOrdValue(Longint(Component));}
end;

{ TComponentNamePropertyEditor }

function TComponentNamePropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [];
end;

function TComponentNamePropertyEditor.GetEditLimit: Integer;
begin
  Result := MaxIdentLength;
end;

{ TColorPropertyEditor }

procedure TColorPropertyEditor.Edit;
var
  ColorDialog: TColorDialog;
  {IniFile: TRegIniFile;

  procedure GetCustomColors;
  begin
    if BaseRegistryKey = '' then Exit;
    IniFile := TRegIniFile.Create(BaseRegistryKey);
    try
      IniFile.ReadSectionValues(SCustomColors, ColorDialog.CustomColors);
    except
      // Ignore errors reading values
    end;
  end;

  procedure SaveCustomColors;
  var
    I, P: Integer;
    S: string;
  begin
    if IniFile <> nil then
      with ColorDialog do
        for I := 0 to CustomColors.Count - 1 do
        begin
          S := CustomColors.Strings[I];
          P := Pos('=', S);
          if P <> 0 then
          begin
            S := Copy(S, 1, P - 1);
            IniFile.WriteString(SCustomColors, S,
              CustomColors.Values[S]);
          end;
        end;
  end;
  }
begin
  {IniFile := nil;}
  ColorDialog := TColorDialog.Create(Application);
  try
    {GetCustomColors;}
    ColorDialog.Color := GetOrdValue;
    if ColorDialog.Execute then SetOrdValue(ColorDialog.Color);
    {SaveCustomColors;}
  finally
    {IniFile.Free;}
    ColorDialog.Free;
  end;
end;

function TColorPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paDialog, paValueList, paRevertable];
end;

function TColorPropertyEditor.GetValue: string;
begin
  Result := ColorToString(TColor(GetOrdValue));
end;

procedure TColorPropertyEditor.GetValues(Proc: TGetStringProc);
begin
  GetColorValues(Proc);
end;

procedure TColorPropertyEditor.PropDrawValue(ACanvas:TCanvas; const ARect:TRect;
  State:TPropEditDrawState);
begin
  if GetVisualValue <> '' then
    ListDrawValue(GetVisualValue, -1, ACanvas, ARect, [pedsInComboList])
  else
    inherited PropDrawValue(ACanvas, ARect, State);
end;

procedure TColorPropertyEditor.ListDrawValue(const NewValue:string;
Index:integer; ACanvas:TCanvas;  const ARect:TRect; State: TPropEditDrawState);

  function ColorToBorderColor(AColor: TColor): TColor;
  type
    TColorQuad = record
      Red,
      Green,
      Blue,
      Alpha: Byte;
    end;
  begin
    if (TColorQuad(AColor).Red > 192) or
       (TColorQuad(AColor).Green > 192) or
       (TColorQuad(AColor).Blue > 192) then
      Result := clBlack
    else if pedsSelected in State then
      Result := clWhite
    else
      Result := AColor;
  end;
var
  vRight: Integer;
  vOldPenColor, vOldBrushColor: TColor;
begin
  vRight := (ARect.Bottom - ARect.Top) {* 2} + ARect.Left;
  with ACanvas do
  try
    // save off things
    vOldPenColor := Pen.Color;
    vOldBrushColor := Brush.Color;

    // frame things
    Pen.Color := Brush.Color;
    Rectangle(ARect.Left, ARect.Top, vRight, ARect.Bottom);

    // set things up and do the work
    Brush.Color := StringToColor(NewValue);
    Pen.Color := ColorToBorderColor(ColorToRGB(Brush.Color));
    Rectangle(ARect.Left + 1, ARect.Top + 1, vRight - 1, ARect.Bottom - 1);

    // restore the things we twiddled with
    Brush.Color := vOldBrushColor;
    Pen.Color := vOldPenColor;
  finally
    inherited ListDrawValue(NewValue, Index, ACanvas,
                            Rect(vRight, ARect.Top, ARect.Right, ARect.Bottom),
                            State);
  end;
end;

procedure TColorPropertyEditor.ListMeasureWidth(const NewValue:string;
  Index:integer;  ACanvas:TCanvas;  var AWidth:Integer);
begin
  AWidth := AWidth + ACanvas.TextHeight('M') {* 2};
end;

procedure TColorPropertyEditor.SetValue(const Value: string);
var
  NewValue: Longint;
begin
  if IdentToColor(Value, NewValue) then
    SetOrdValue(NewValue)
  else
    inherited SetValue(Value);
end;

//==============================================================================

{ TComponentSelectionList }

function TComponentSelectionList.Add(c: TComponent): integer;
begin
  Result:=FComponents.Add(c);
end;

procedure TComponentSelectionList.Clear;
begin
  FComponents.Clear;
end;

constructor TComponentSelectionList.Create;
begin
  inherited Create;
  FComponents:=TList.Create;
end;

destructor TComponentSelectionList.Destroy;
begin
  FComponents.Free;
  inherited Destroy;
end;

function TComponentSelectionList.GetCount: integer;
begin
  Result:=FComponents.Count;
end;

function TComponentSelectionList.GetItems(Index: integer): TComponent;
begin
  Result:=TComponent(FComponents[Index]);
end;

procedure TComponentSelectionList.SetItems(Index: integer;
  const Value: TComponent);
begin
  FComponents[Index]:=Value;
end;

function TComponentSelectionList.GetCapacity:integer;
begin
  Result:=FComponents.Capacity;
end;

procedure TComponentSelectionList.SetCapacity(const NewCapacity:integer);
begin
  FComponents.Capacity:=NewCapacity;
end;

procedure TComponentSelectionList.Assign(
  SourceSelectionList:TComponentSelectionList);
var a:integer;
begin
  Clear;
  if (SourceSelectionList<>nil) and (SourceSelectionList.Count>0) then begin
    FComponents.Capacity:=SourceSelectionList.Count;
    for a:=0 to SourceSelectionList.Count-1 do
      Add(SourceSelectionList[a]);
  end;
end;


//******************************************************************************

initialization
  PropertyClassList:=TList.Create;
  PropertyEditorMapperList:=TList.Create;
  // register the standard property editors
  // the System.TypeInfo(Type) is missing
  //RegisterPropertyEditor(TypeInfo(TColor),nil,'',TColorPropertyEditor);

finalization
  PropertyEditorMapperList.Free;  PropertyEditorMapperList:=nil;
  PropertyClassList.Free;  PropertyClassList:=nil;

end.
