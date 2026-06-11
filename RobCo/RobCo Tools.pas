{
  Unified export hub for RobCo Patcher (Fallout 4) and SkyPatcher (Skyrim).
}
unit UserScript;

uses 'RobCo\RobCoHubDialog';

const
  RobCoNoDataMessage = 'No records exported from selected plugins.';

//============================================================================
function Initialize: integer;
var
  slSelected: TStringList;
  totalFiles, combinedFiles: integer;
  exportBasePath: string;
begin
  Result := 0;
  if not RobCoFrameworkSupported then begin
    AddMessage('RobCo Tools export is only supported in Fallout 4 and Skyrim.');
    Result := 1;
    Exit;
  end;

  RobCoBeginExport;

  gRobCoListExportAdd := True;
  gRobCoListExportRemove := True;
  gRobCoExportForwardItms := False;
  gRobCoPerPlugin := True;
  gRobCoOverridesOnly := True;
  gRobCoExportWriteAllFields := False;
  gRobCoSelectedOps := TStringList.Create;

  try
    if not ShowRobCoToolsDialog then begin
      AddMessage('Export cancelled.');
      Result := 1;
      Exit;
    end;

    if gRobCoSelectedOps.Count = 0 then begin
      AddMessage('Export cancelled: no record type selected.');
      Result := 1;
      Exit;
    end;

    if not gRobCoPerPlugin then
      gRobCoExportForwardItms := False;

    slSelected := TStringList.Create;
    try
      if not SelectPlugins(slSelected, 'Select plugins to export from') then begin
        AddMessage('Export cancelled: no plugins selected.');
        Result := 1;
        Exit;
      end;
      RobCoProgressSetPluginTotal(slSelected.Count);
      RobCoReportProgress('RobCo: exporting from ' + IntToStr(slSelected.Count) + ' plugins...');

      exportBasePath := SelectRobCoOutputDirectory('Folder to save exported RobCo INI files');
      if exportBasePath = '' then begin
        AddMessage('Export cancelled: no output folder selected.');
        Result := 1;
        Exit;
      end;

      if not RobCoExportRunSelectedOps(slSelected, exportBasePath, totalFiles, combinedFiles) then begin
        Result := 1;
        Exit;
      end;

      if gRobCoPerPlugin then begin
        if totalFiles > 0 then
          RobCoQueueExportLog(Format('Created %d INI file(s).', [totalFiles]))
        else
          RobCoQueueExportLog(RobCoNoDataMessage);
      end else begin
        if combinedFiles > 0 then
          RobCoQueueExportLog(Format('Created %d INI file(s).', [combinedFiles]))
        else
          RobCoQueueExportLog(RobCoNoDataMessage);
      end;
    finally
      slSelected.Free;
    end;
  finally
    gRobCoSelectedOps.Free;
    gRobCoSelectedOps := nil;
  end;
end;

//============================================================================
function Process(e: IInterface): integer;
begin
  Result := 0;
end;

//============================================================================
function Finalize: integer;
begin
  Result := 0;
  RobCoFlushExportLog;
end;

end.
