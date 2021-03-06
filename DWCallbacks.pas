unit DWCallbacks;

interface

uses Classes, System.SysUtils, DWTypes;

type

  // This Object represent one CallBack to be Handled in UserSession
  // on receive one POST CallBack
  TDWCallback = class(TObject)
  private
  protected
    // type of event, see DWTypes --> TDWAsyncEventType
    FEventType: TDWAsyncEventType;
    // if EventType = none, FEventName is used to compound QualifiedName;
    FEventName: string;
    // Control that will originate Callback
    FControl: TObject;
    // UserSession owner for this CallBack
    FSession: TObject;
    { Procedure to execute in Form on CallBack
      Note that for all callback is first called the TDWForm.ExecuteCallback method,
      and only then, TDWForm.ExecuteCallback event call the procedure FCallBackProc.
      The procedure FCallBackProc represent the DWComponent Internal Event Procedure
      DoOnxxxxx and this Internal Event Procedure call FOnxxxx
      Ex: When  TDWForm.TDWEDIT Async Change Event is received on server, this is processed in
      this order:
      1- TDWHttpServer.TriggerPostDocument (All POSTs is Handled here)
      2- TDWHttpServer.PostDispatchCallback (All Callbacks is Handled here)
      3- TDWForm.ExecuteCallBack (The browser changed components are updated in Form)
      4- TDWEDIT.DoOnAsyncChange (internal Component code is executed)
      5- TDWEDIT.FOnAsyncChange (OnAsyncChange is called and user defined code is executed) }
    FCallBackProc: TDWCallbackProcedure;
  public
    constructor Create(ASession: TObject; aControl: TObject; AType: TDWAsyncEventType;
      ACallbackProcedure: TDWCallbackProcedure); overload;
    constructor Create(ASession: TObject; aControl: TObject; aName: string;
      ACallbackProcedure: TDWCallbackProcedure); overload;
    destructor Destroy; override;
    // Return the type of event in string, ex: 'change'
    function TypeName: String;
    // Return the Qualified Name of Callback in format FormName.ControlName.EventName
    // if Form is nil return NIL.ControlName.EventName
    // if Control is nil return NIL.NIL.EventName
    function QualifiedName: string;
    // Return the CallBack procedure to be executted in this callBack
    property CallBackProcedure: TDWCallbackProcedure read FCallBackProc write FCallBackProc;
  end;

  // This Object mantain one list of CallBacks registered for the UserSession
  TDWCallBacks = class(TStringList)
  protected
    FSession: TObject;
    property OwnsObjects; // Hide Property OwnsObjects to avoid change
  public
    constructor Create(ASession: TObject);
    // Add one Callback to List and return QualifiedName
    function RegisterCallBack(aControl: TObject; AType: TDWAsyncEventType;
      ACallbackProcedure: TDWCallbackProcedure): string; overload;
    // Add one Callback for Custom Event to List and return QualifiedName
    function RegisterCallBack(aControl: TObject; aName: string;
      ACallbackProcedure: TDWCallbackProcedure): string; overload;
    // Remove One CallBack of List
    procedure UnregisterCallBack(const AQualifiedName: String);
    // Get the Callback index from Callback Qualified Name
    // aQualifiedName is in format(FormName.ControlName.EventTypeName)
    function FindCallback(const AQualifiedName: String): Integer;

  end;

implementation

uses DW.VCL.Control;

{ TDWCallback }

constructor TDWCallback.Create(ASession: TObject; aControl: TObject; AType: TDWAsyncEventType;
  ACallbackProcedure: TDWCallbackProcedure);
begin
  inherited Create;
  FSession      := ASession;
  FControl      := aControl;
  FEventType    := AType;
  FCallBackProc := ACallbackProcedure;
end;

constructor TDWCallback.Create(ASession, aControl: TObject; aName: string;
  ACallbackProcedure: TDWCallbackProcedure);
begin
  Create(ASession, aControl, ae_none, ACallbackProcedure);
  FEventName := aName;
end;

destructor TDWCallback.Destroy;
begin

  inherited;
end;

function TDWCallback.QualifiedName: string;
begin
  if FEventType = ae_none then
    Result := TDWControl(FControl).Form.Name + '.' + TDWControl(FControl).Name + '.' + FEventName
  else
    Result := TDWControl(FControl).Form.Name + '.' + TDWControl(FControl).Name + '.' + TypeName;
  { TODO 1 -oDELCIO -cIMPLEMENT :  TDWCallback.QualifiedName in format described }
  // Return the Qualified Name of Callback in format FormName.ControlName.EventName
  // if Form is nil return NIL.ControlName.EventName
  // if Control is nil return NIL.NIL.EventName

end;

function TDWCallback.TypeName: String;
begin
  Result := AsyncEventTypeToName(FEventType);
end;

{ TDWCallBacks }

constructor TDWCallBacks.Create(ASession: TObject);
begin
  FSession    := ASession;
  OwnsObjects := True;
end;

function TDWCallBacks.FindCallback(const AQualifiedName: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I  := 0 to Count - 1 do
    begin
      if (SameText((Objects[I] as TDWCallback).QualifiedName, AQualifiedName)) then
        Begin
          Result := I;
          Break;
        End
    end;
end;

function TDWCallBacks.RegisterCallBack(aControl: TObject; aName: string;
  ACallbackProcedure: TDWCallbackProcedure): string;
var
  LCallback: TDWCallback;
begin
  LCallback := TDWCallback.Create(Self.FSession, aControl, aName, ACallbackProcedure);
  AddObject(LCallback.QualifiedName, LCallback);
  Result := LCallback.QualifiedName;
end;

function TDWCallBacks.RegisterCallBack(aControl: TObject; AType: TDWAsyncEventType;
  ACallbackProcedure: TDWCallbackProcedure): string;
var
  LCallback: TDWCallback;
begin
  LCallback := TDWCallback.Create(Self.FSession, aControl, AType, ACallbackProcedure);
  AddObject(LCallback.QualifiedName, LCallback);
  Result := LCallback.QualifiedName;
end;

procedure TDWCallBacks.UnregisterCallBack(const AQualifiedName: String);
var
  LIndex: Integer;
begin
  LIndex := IndexOfName(AQualifiedName);
  if LIndex >= 0 then
    begin
      Delete(LIndex);
      // Not necessary Free because TDWCallBacks.OwnsObjects = True;
    end;
end;

end.
