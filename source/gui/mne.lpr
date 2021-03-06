program mne;

{$mode objfpc}

{**
 * Mini Edit
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 * @url       http://sourceforge.net/projects/minilib
 *}

{
  rev: 50962

  good fonts
  http://www.lowing.org/fonts/
}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Dialogs,
  Controls,
  Forms,
  Registry,
  SysUtils,
  LCLVersion,
  simpleipc,
  Themes, Interfaces,
  MainUnit in 'MainUnit.pas' {MainForm},
  mneProjectOptions in 'mneProjectOptions.pas' {ProjectForm},
  SearchForms in '..\editor\SearchForms.pas' {SearchForm},
  EditorOptions in '..\editor\EditorOptions.pas' {EditorOptionsForm},
  EditorProfiles in '..\editor\EditorProfiles.pas',
  EditorEngine in '..\editor\EditorEngine.pas',
  mneResources in 'mneResources.pas' {EditorResource: TDataModule},
  SelectFiles in '..\editor\SelectFiles.pas' {SelectFileForm},
  mneConsts in 'mneConsts.pas',
  AboutForms in 'AboutForms.pas' {AboutForm},
  GotoForms in '..\editor\GotoForms.pas' {GotoLineForm},
  EditorRun in '..\editor\EditorRun.pas',
  mneBreakpoints in 'mneBreakpoints.pas' {BreakpointsForm},
  SearchInFilesForms in '..\editor\SearchInFilesForms.pas' {SearchInFilesForm},
  SearchProgressForms, EditorDebugger, SelectList, IniFiles, mneAssociateForm,
  mneExtends, mneCMDClasses, mneGoClasses, mneSARDClasses, sqlvManager,
  mneDBClasses, mneBoardClasses, mneBoardForms, mneSelectComponents,
  mneBoardComponents, mneFontGenForm, mneCppClasses, mneVerilogClasses,
  SynHighlighterVerilog, mneCustomClasses, mnePasProjectFrames, mnePASClasses,
  mneCSVClasses, mneDClasses, mneLuaClasses, LuaDBGServers, MsgBox, GUIMsgBox,
  Classes, PHPUtils, ntvThemes, mneSetups, mneSettings, EditorClasses,
  EditorColors, gdbClasses, mneCompilerProjectFrames, mneRunFrames, mneClasses,
  mneManageRecentsForms, mneTendencyOptions, mneCSVForms, mnUtils, mnStreams,
  mncCSV, sqlvOpenDatabases;

{$R *.res}
{$i '..\lib\mne.inc'}

function InitEngine: Boolean;
var
  aIniFile: TIniFile;
  aIni, aPath: string;
  procedure Check;
  var
    aWorkspace: string;
  begin
    Result := FileExists(aIni);
    if Result then
    begin
      aIniFile := TIniFile.Create(aIni);
      try
        aPath := aIniFile.ReadString('options', 'Workspace', '');
        Result := aPath <> '';
        if Result then
        begin
          aWorkspace := aIniFile.ReadString('options', 'Workspace', '');
          aWorkspace := IncludeTrailingPathDelimiter(Engine.EnvReplace(aWorkspace, True));
          Engine.Workspace := ExpandToPath(aWorkspace, Application.Location);
          Engine.Environment.Add('Workspace=' + aWorkspace);
          ForceDirectories(Engine.Workspace);
        end
      finally
        aIniFile.Free;
      end;
      //Engine.Shutdown to del
    end;
  end;
begin
  Result := False;
  aIni := ExtractFilePath(Application.ExeName) + 'setting.ini';
  Check;
  if not Result then
  begin
    with TEditorSetupForm.Create(Application) do
    begin
      Result := ShowModal = mrOK;
      Free;
    end;
    Check;
  end;
end;

function IsAnotherInstance: Boolean;
var
  aClient: TSimpleIPCClient;
  aFile: string;
begin
  if (ParamCount > 0) and not (SameText(ParamStr(1), '/dde')) then
  begin
    aFile := ExpandFileName(ParamStr(1));
    aClient := TSimpleIPCClient.Create(nil);
    try
      aClient.ServerID := sApplicationID;
      Result := aClient.ServerRunning;//There is another instance
      if Result then
      begin
        aClient.Connect;
        try
          aClient.SendStringMessage(1, aFile);
        finally
          aClient.Disconnect;
        end;
      end
    finally
      aClient.Free;
    end;
  end
  else
  begin
    Result := False;
  end
end;

procedure Run;
begin
  {$IFDEF DEBUG}
  //* http://wiki.freepascal.org/leakview
  if FileExists(Application.Location+'heap.trc') then
    DeleteFile(Application.Location+'heap.trc');
  //SetHeapTraceOutput(Application.Location+'heap.trc');
  {$ENDIF DEBUG}
  Application.CreateForm(TEditorResource, EditorResource);
  Application.CreateForm(TMainForm, MainForm);
end;

begin
  if not IsAnotherInstance then
  begin
    //DefaultSystemCodePage := widestringmanager.GetStandardCodePageProc(scpAnsi); //I fix it temporary that needed for AnsiToUtf8; //i commented cuz i cant convert to ansi in TTextEditorFile.DoSave
    Application.Scaled :=True;
    Application.Initialize;
    Application.Title :='miniEdit';
    Application.Name := 'miniEdit';
    Application.BidiMode := bdLeftToRight;
    if InitEngine then
    begin
      Run;
      Application.Run;
    end;
  end;
end.

