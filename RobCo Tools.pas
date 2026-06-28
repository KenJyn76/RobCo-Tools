{
  Unified export hub for RobCo Patcher (Fallout 4) and SkyPatcher (Skyrim).
}
unit UserScript;

uses 'RobCo\HubDialog';

const
  NoDataMessage = 'No records exported from selected plugins.';

//============================================================================
function Initialize: integer;
var
  slSelected: TStringList;
  totalFiles, combinedFiles: integer;
  exportBasePath: string;
begin
  Result := 0;
  if not FrameworkSupported then begin
    AddMessage('RobCo Tools export is only supported in Fallout 4 and Skyrim.');
    Result := 1;
    Exit;
  end;

  BeginExport;

  gSelectedOps := TStringList.Create;

  if not ShowToolsDialog then begin
    AddMessage('Export cancelled.');
    Result := 1;
  end else if gSelectedOps.Count = 0 then begin
    AddMessage('Export cancelled: no record type selected.');
    Result := 1;
  end else begin
    slSelected := TStringList.Create;
    if not SelectPlugins(slSelected, 'Select plugins to export from') then begin
      AddMessage('Export cancelled: no plugins selected.');
      Result := 1;
    end else begin
      ProgressSetPluginTotal(slSelected.Count);
      ReportProgress('RobCo: exporting from ' + IntToStr(slSelected.Count) + ' plugins...');

      exportBasePath := SelectOutputDirectory('Folder to save exported RobCo INI files');
      if exportBasePath = '' then begin
        AddMessage('Export cancelled: no output folder selected.');
        Result := 1;
      end else if not ExportRunSelectedOps(slSelected, exportBasePath, totalFiles, combinedFiles) then begin
        Result := 1;
      end else begin
        if gPerPlugin then begin
          if totalFiles > 0 then
            QueueExportLog(Format('Created %d INI file(s).', [totalFiles]))
          else
            QueueExportLog(NoDataMessage);
        end else begin
          if combinedFiles > 0 then
            QueueExportLog(Format('Created %d INI file(s).', [combinedFiles]))
          else
            QueueExportLog(NoDataMessage);
        end;
      end;
    end;
    slSelected.Free;
  end;

  gSelectedOps.Free;
  gSelectedOps := nil;
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
  FlushExportLog;
end;

end.
