{
  Shared export I/O, globals, and record gates.
}
unit RobCoCommon;

var
  slRobCoExportLog: TStringList;
  gRobCoExportWriteAllFields: boolean;
  gRobCoExportForwardItms: boolean;
  gRobCoListExportAdd: boolean;
  gRobCoListExportRemove: boolean;
  gRobCoPerPlugin: boolean;
  gRobCoOverridesOnly: boolean;
  gRobCoSelectedOps: TStringList;
  gRobCoPatcherOutputDir: string;
  gRobCoPatcherDirBare: string;
  gRobCoIniWriterActive: boolean;
  gRobCoIniOutputDir: string;
  gRobCoIniPerPlugin: boolean;
  gRobCoIniCombinedFileName: string;
  gRobCoIniCurrentPlugin: string;
  gRobCoIniFilesCreated: integer;
  gRobCoIniFileActive: boolean;
  gRobCoIniActivePath: string;
  gRobCoIniLineBuffer: TStringList;
  gRobCoIniCombinedFileStarted: boolean;
  gRobCoIniNeedCombinedPluginHeader: boolean;
  gRobCoIniPluginsStarted: TStringList;
  gRobCoIniOverwriteOnFlush: boolean;

  gRobCoKeywordPartsScratch: TStringList;
  gRobCoDiffScratchPlugin: TStringList;
  gRobCoDiffScratchMaster: TStringList;
  gRobCoDiffScratchAdd: TStringList;
  gRobCoDiffScratchRem: TStringList;
  gRobCoIniDedupeSeenScratch: TStringList;
  gRobCoIniDedupeOutputScratch: TStringList;

  gRobCoSnapMasterCacheKeys: TStringList;
  gRobCoSnapMasterCacheVals: TStringList;

  gRobCoProgressLastReportMs: integer;
  gRobCoProgressPluginTotal: integer;
  gRobCoProgressOpNum: integer;
  gRobCoProgressOpTotal: integer;
  gRobCoProgressOpLabel: string;

const
  RobCoProgressMinIntervalMs = 30000;
  RobCoFilterLLs = 'filterByLLs=';
  RobCoFilterCONT = 'filterByContainers=';
  RobCoFilterNpcs = 'filterByNpcs=';
  RobCoFilterRaces = 'filterByRaces=';
  RobCoFilterFormLists = 'filterByFormLists=';
  RobCoFilterCobjs = 'filterByCobjs=';
  RobCoFilterMiscs = 'filterByMiscs=';
  RobCoFilterAlchs = 'filterByAlchs=';
  RobCoFilterArmors = 'filterByArmors=';
  RobCoFilterWeapons = 'filterByWeapons=';
  RobCoFilterAmmos = 'filterByAmmos=';
  RobCoFilterOmod = 'filterByOMod=';

  RobCoFO4VanillaPlugins =
    ',fallout4.esm,dlccoast.esm,dlcnukaworld.esm,dlcrobot.esm,' +
    'dlcworkshop01.esm,dlcworkshop02.esm,dlcworkshop03.esm,';
  RobCoSkyrimVanillaPlugins =
    ',skyrim.esm,update.esm,dawnguard.esm,hearthfires.esm,dragonborn.esm,';
  RobCoOblivionVanillaPlugins =
    ',oblivion.esm,knights.esp,shiveringisles.esp,';
  RobCoFO3VanillaPlugins =
    ',fallout3.esm,anchorage.esm,thepitt.esm,brokensteel.esm,pointlookout.esm,zeta.esm,';
  RobCoFNVVanillaPlugins =
    ',falloutnv.esm,deadmoney.esm,honesthearts.esm,oldworldblues.esm,lonesomeroad.esm,' +
    'gunrunnersarsenal.esm,classicpack.esm,mercenarypack.esm,tribalpack.esm,';

//============================================================================
function RobCoNowMs: integer;
begin
  Result := Trunc(Now * 86400000);
end;

//============================================================================
function FormatFormID(e: IInterface): string;
var
  s: string;
  i: integer;
begin
  s := UpperCase(IntToHex(GetLoadOrderFormID(e), 8));
  if Length(s) >= 2 then
    s := Copy(s, 3, MaxInt);
  i := 1;
  while (i < Length(s)) and (s[i] = '0') do
    Inc(i);
  Result := Copy(s, i, MaxInt);
end;

//============================================================================
function RobCoEditorID(e: IInterface): string;
begin
  Result := GetElementEditValues(e, 'EDID');
end;

//============================================================================
function FormIDRef(rec: IInterface): string;
begin
  Result := GetFileName(GetFile(rec)) + '|' + FormatFormID(rec);
end;

//============================================================================
// Linked-record refs for diff/export fields: master-file plugin|id so override vs
// master reads match (e.g. Fallout4.esm|150733 not patch.esp|150733).
function RobCoMasterFormIDRef(ref: IInterface): string;
begin
  Result := '';
  if not Assigned(ref) then
    Exit;

  Result := FormIDRef(MasterOrSelf(ref));
end;

//============================================================================
// Primary filterBy* on snapshot exports: winning master identity (plugin-local
// masters stay on their plugin; overrides use the master plugin|id).
function RobCoPatchFilterFormIDRef(e: IInterface): string;
begin
  Result := RobCoMasterFormIDRef(e);
end;

//============================================================================
function RobCoRecordUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
begin
  if not Assigned(e) then begin
    Result := False;
    Exit;
  end;
  if IsMaster(e) then begin
    Result := False;
    Exit;
  end;
  master := MasterOrSelf(e);
  if not Assigned(master) then begin
    Result := False;
    Exit;
  end;
  Result := ConflictAllForElements(e, master, False, False) <= caNoConflict;
end;

//============================================================================
function RobCoSubElementConflictFree(a, b: IInterface): boolean;
begin
  if not Assigned(a) then begin
    if not Assigned(b) then
      Result := True
    else
      Result := False;
    Exit;
  end;
  if not Assigned(b) then begin
    Result := False;
    Exit;
  end;
  Result := ConflictAllForElements(a, b, False, False) <= caNoConflict;
end;

//============================================================================
function RobCoSubElementConflictFreeByPath(e, master: IInterface; const path: string): boolean;
var
  a, b: IInterface;
begin
  a := ElementByPath(e, path);
  b := ElementByPath(master, path);
  Result := RobCoSubElementConflictFree(a, b);
end;

//============================================================================
function RobCoSubElementConflictFreeByName(e, master: IInterface; const name: string): boolean;
var
  a, b: IInterface;
begin
  a := ElementByName(e, name);
  b := ElementByName(master, name);
  Result := RobCoSubElementConflictFree(a, b);
end;

//============================================================================
function RobCoSubElementConflictFreeBySignature(e, master: IInterface; const sig: string): boolean;
var
  a, b: IInterface;
begin
  a := ElementBySignature(e, sig);
  b := ElementBySignature(master, sig);
  Result := RobCoSubElementConflictFree(a, b);
end;

//============================================================================
function RobCoEditScalarConflictFree(e, master: IInterface; const path: string): boolean;
var
  ve, vm: string;
begin
  if not ElementExists(e, path) then begin
    if not ElementExists(master, path) then
      Result := True
    else
      Result := False;
    Exit;
  end;
  if not ElementExists(master, path) then begin
    Result := False;
    Exit;
  end;
  ve := GetElementEditValues(e, path);
  vm := GetElementEditValues(master, path);
  Result := ve = vm;
end;

//============================================================================
// xEdit: IsMaster(e)=false means e is an override of a record from an earlier
// plugin in load order (see MasterOrSelf). Plugin-local masters are IsMaster.
function RobCoRecordHasExternalMaster(e: IInterface): boolean;
begin
  Result := False;
  if not Assigned(e) then
    Exit;
  Result := not IsMaster(e);
end;

//============================================================================
function RobCoShouldExportRecord(e: IInterface; overridesOnly: boolean): boolean;
begin
  if not overridesOnly then
    Result := True
  else
    Result := RobCoRecordHasExternalMaster(e);
end;

//============================================================================
// Record gate only: overridesOnly + Forward ITMs (ITM skip). Write all fields
// must never be read here — it affects line verbosity only (RobCoAppendField /
// RobCoAppendNumericField for scalar ops).
function RobCoShouldProcessOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := False;
  if not Assigned(e) then
    Exit;
  if not RobCoShouldExportRecord(e, overridesOnly) then
    Exit;
  if not forwardItms then
    if RobCoRecordUnchangedVsMaster(e) then
      Exit;
  Result := True;
end;

//============================================================================
function RobCoCompactExternalOverride(e: IInterface): boolean;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoScalarUnchangedVsMaster(const pluginVal, masterVal: string): boolean;
begin
  Result := pluginVal = masterVal;
end;

//============================================================================
function RobCoRefListDiffUnchangedVsMaster(const pluginList, masterList: string): boolean;
var
  refsToAdd, refsToRemove: string;
begin
  RobCoDiffCommaSeparatedRefs(pluginList, masterList, refsToAdd, refsToRemove);
  Result := True;
  if (refsToAdd <> '') then begin
    if refsToAdd <> 'none' then begin
      Result := False;
      Exit;
    end;
  end;
  if (refsToRemove <> '') then begin
    if refsToRemove <> 'none' then begin
      Result := False;
      Exit;
    end;
  end;
end;

//============================================================================
function RobCoKeywordRefsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  pluginKw, masterKw: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  pluginKw := RobCoReadKeywordRefsFromElement(e);
  masterKw := RobCoReadKeywordRefsFromElement(master);
  Result := RobCoRefListDiffUnchangedVsMaster(pluginKw, masterKw);
end;

//============================================================================
function RobCoListFieldUnchangedVsMaster(e: IInterface; const pluginList, masterList: string): boolean;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  Result := RobCoRefListDiffUnchangedVsMaster(pluginList, masterList);
end;

//============================================================================
procedure RobCoProgressReset;
begin
  gRobCoProgressLastReportMs := 0;
  gRobCoProgressPluginTotal := 0;
  gRobCoProgressOpNum := 0;
  gRobCoProgressOpTotal := 0;
  gRobCoProgressOpLabel := '';
end;

//============================================================================
procedure RobCoProgressSetPluginTotal(totalPlugins: integer);
begin
  gRobCoProgressPluginTotal := totalPlugins;
end;

//============================================================================
procedure RobCoProgressSetOp(opNum, opTotal: integer; const opLabel: string);
begin
  gRobCoProgressOpNum := opNum;
  gRobCoProgressOpTotal := opTotal;
  gRobCoProgressOpLabel := opLabel;
end;

//============================================================================
procedure RobCoReportProgress(const msg: string);
var
  nowMs: integer;
begin
  nowMs := RobCoNowMs;
  if gRobCoProgressLastReportMs > 0 then begin
    if (nowMs - gRobCoProgressLastReportMs) < RobCoProgressMinIntervalMs then
      Exit;
  end;
  gRobCoProgressLastReportMs := nowMs;
  AddMessage(msg);
end;

//============================================================================
// Always prints; updates last-write time (Started/Stopped record-type lines only).
procedure RobCoReportProgressOpBoundary(const msg: string);
begin
  gRobCoProgressLastReportMs := RobCoNowMs;
  AddMessage(msg);
end;

//============================================================================
procedure RobCoProgressReportPlugin(const pluginName: string; pluginIndex: integer);
var
  msg: string;
begin
  if gRobCoProgressOpLabel = '' then
    Exit;
  msg := 'RobCo [' + IntToStr(gRobCoProgressOpNum) + '/' +
    IntToStr(gRobCoProgressOpTotal) + '] ' + gRobCoProgressOpLabel +
    ': plugin ' + IntToStr(pluginIndex + 1) + '/' +
    IntToStr(gRobCoProgressPluginTotal) + ' ' + pluginName;
  RobCoReportProgress(msg);
end;

//============================================================================
procedure RobCoBeginExport;
begin
  RobCoProgressReset;
  if Assigned(slRobCoExportLog) then
    slRobCoExportLog.Free;
  slRobCoExportLog := nil;
  RobCoIniWriterInit;
end;

//============================================================================
procedure RobCoQueueExportLog(const msg: string);
begin
  if not Assigned(slRobCoExportLog) then
    slRobCoExportLog := TStringList.Create;
  slRobCoExportLog.Add(msg);
end;

//============================================================================
function RobCoPluginGroupHasOverrides(grp: IInterface): boolean;
var
  j: integer;
  e: IInterface;
begin
  Result := False;
  if not Assigned(grp) then
    Exit;
  for j := 0 to Pred(ElementCount(grp)) do begin
    e := ElementByIndex(grp, j);
    if RobCoRecordHasExternalMaster(e) then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
procedure RobCoFlushExportLog;
var
  i: integer;
begin
  if Assigned(slRobCoExportLog) then begin
    for i := 0 to Pred(slRobCoExportLog.Count) do
      AddMessage(slRobCoExportLog[i]);
    slRobCoExportLog.Free;
    slRobCoExportLog := nil;
  end;

  RobCoIniWriterShutdown;
end;

//============================================================================
procedure RobCoLogSkippedDuplicate(const msg: string);
begin
  RobCoQueueExportLog(msg);
end;

//============================================================================
// Caller must run RobCoShouldProcessOverride before gather/build.
procedure RobCoEmitSnapshotRecord(e: IInterface; const sig: string;
  shortComment: boolean; const line: string);
var
  pluginName, editorID: string;
begin
  if not RobCoSnapshotLineHasOperations(line) then
    Exit;

  if not gRobCoIniWriterActive then
    Exit;

  pluginName := GetFileName(GetFile(e));
  editorID := RobCoEditorID(e);

  RobCoIniWriterWriteRecordBlock(pluginName,
    RobCoRecordComment(editorID, pluginName, sig, e, shortComment), line);
end;

//============================================================================
function StringListHasRobCoFilter(aList: TStringList; const filterPrefix: string): boolean;
var
  i: integer;
begin
  Result := False;
  if not Assigned(aList) then
    Exit;

  for i := 0 to Pred(aList.Count) do
    if Pos(filterPrefix, aList[i]) = 1 then begin
      Result := True;
      Exit;
    end;
end;

//============================================================================
function StringListHasNPCPatchData(aList: TStringList): boolean;
begin
  Result :=
    StringListHasRobCoFilter(aList, RobCoFilterNpcs) or
    StringListHasRobCoFilter(aList, RobCoFilterRaces);
end;

//============================================================================
function StringListHasAnyRobCoData(aList: TStringList): boolean;
begin
  Result :=
    StringListHasRobCoFilter(aList, RobCoFilterLLs) or
    StringListHasRobCoFilter(aList, RobCoFilterCONT) or
    StringListHasRobCoFilter(aList, RobCoFilterNpcs) or
    StringListHasRobCoFilter(aList, RobCoFilterRaces) or
    StringListHasRobCoFilter(aList, RobCoFilterFormLists) or
    StringListHasRobCoFilter(aList, RobCoFilterCobjs) or
    StringListHasRobCoFilter(aList, RobCoFilterMiscs) or
    StringListHasRobCoFilter(aList, RobCoFilterAlchs) or
    StringListHasRobCoFilter(aList, RobCoFilterArmors) or
    StringListHasRobCoFilter(aList, RobCoFilterWeapons) or
    StringListHasRobCoFilter(aList, RobCoFilterAmmos) or
    StringListHasRobCoFilter(aList, RobCoFilterOmod);
end;

//============================================================================
function RobCoFO4Game: boolean;
begin
  Result := (wbGameMode = gmFO4) or (wbGameMode = gmFO4VR);
end;

//============================================================================
function RobCoSkyrimGame: boolean;
begin
  Result := (wbGameMode = gmTES5) or (wbGameMode = gmSSE);
end;

//============================================================================
function RobCoFrameworkSupported: boolean;
begin
  Result := RobCoFO4Game or RobCoSkyrimGame;
end;

//============================================================================
procedure RobCoMultisetInc(sl: TStringList; const key: string);
var
  idx, n: integer;
begin
  if key = '' then
    Exit;

  idx := sl.IndexOf(key);
  if idx < 0 then
    sl.AddObject(key, TObject(1))
  else begin
    n := Integer(sl.Objects[idx]);
    sl.Objects[idx] := TObject(n + 1);
  end;
end;

//============================================================================
procedure RobCoMultisetSort(sl: TStringList);
begin
  if not Assigned(sl) then
    Exit;
  if sl.Count < 2 then
    Exit;
  sl.Sorted := True;
end;

//============================================================================
function RobCoMultisetTryConsume(sl: TStringList; const key: string): boolean;
var
  idx, n: integer;
begin
  Result := False;
  if key = '' then
    Exit;

  idx := sl.IndexOf(key);
  if idx < 0 then
    Exit;

  n := Integer(sl.Objects[idx]);
  if n <= 0 then
    Exit;

  n := n - 1;
  if n = 0 then
    sl.Delete(idx)
  else
    sl.Objects[idx] := TObject(n);

  Result := True;
end;

//============================================================================
function RobCoMultisetCount(sl: TStringList; const key: string): integer;
var
  idx: integer;
begin
  idx := sl.IndexOf(key);
  if idx < 0 then
    Result := 0
  else
    Result := Integer(sl.Objects[idx]);
end;

//============================================================================
function RobCoMultisetEqual(a, b: TStringList): boolean;
var
  i, idx: integer;
begin
  Result := False;
  if a.Count <> b.Count then
    Exit;
  for i := 0 to Pred(a.Count) do begin
    idx := b.IndexOf(a[i]);
    if idx < 0 then
      Exit;
    if Integer(a.Objects[i]) <> Integer(b.Objects[idx]) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function RobCoTryAddUniqueKey(seen: TStringList; const key: string): boolean;
begin
  Result := seen.IndexOf(key) = -1;
  if Result then
    seen.Add(key);
end;

//============================================================================
function RobCoNoneIfEmpty(const s: string): string;
begin
  if s = '' then
    Result := 'none'
  else
    Result := s;
end;

//============================================================================
function RobCoJoinParts(parts: TStringList): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to Pred(parts.Count) do begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + parts[i];
  end;
end;

//============================================================================
procedure RobCoParseCommaList(sl: TStringList; const listText: string);
begin
  sl.Clear;
  if listText = '' then
    Exit;
  sl.Delimiter := ',';
  sl.StrictDelimiter := True;
  sl.DelimitedText := listText;
end;

//============================================================================
// Compact master diff for operation field values (keywords, scalars, lists).
// Forward ITMs off only. Write all fields is separate: RobCoAppendField uses
// gRobCoExportWriteAllFields to emit none/empty filter segments without changing
// whether values are diffed vs master here.
function RobCoSnapshotUseCompactFieldDiff: boolean;
begin
  Result := not gRobCoExportForwardItms;
end;

//============================================================================
function RobCoSnapshotOmitUnchangedFields: boolean;
begin
  Result := RobCoSnapshotUseCompactFieldDiff;
end;

//============================================================================
function RobCoExportFieldIfChanged(e: IInterface; const pluginValue, masterValue: string): string;
begin
  Result := pluginValue;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  if pluginValue = masterValue then
    Result := '';
end;

//============================================================================
function RobCoDataFieldIfChanged(e: IInterface; const fieldName: string): string;
var
  master: IInterface;
  pluginVal, masterVal: string;
begin
  pluginVal := RobCoReadDataField(e, fieldName);
  if not RobCoSnapshotUseCompactFieldDiff then begin
    Result := pluginVal;
    Exit;
  end;
  if not RobCoRecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := MasterOrSelf(e);
  masterVal := RobCoReadDataField(master, fieldName);
  if pluginVal = masterVal then
    Result := ''
  else
    Result := pluginVal;
end;

//============================================================================
function RobCoFullNameIfChanged(e: IInterface): string;
var
  master: IInterface;
  pluginVal, masterVal: string;
begin
  pluginVal := RobCoReadFullName(e);
  if not RobCoSnapshotUseCompactFieldDiff then begin
    Result := pluginVal;
    Exit;
  end;
  if not RobCoRecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := MasterOrSelf(e);
  masterVal := RobCoReadFullName(master);
  if pluginVal = masterVal then
    Result := ''
  else
    Result := pluginVal;
end;

//============================================================================
function RobCoPlainFullNameIfChanged(e: IInterface): string;
var
  master: IInterface;
  pluginVal, masterVal: string;
begin
  pluginVal := RobCoReadPlainFullName(e);
  if not RobCoSnapshotUseCompactFieldDiff then begin
    Result := pluginVal;
    Exit;
  end;
  if not RobCoRecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := MasterOrSelf(e);
  masterVal := RobCoReadPlainFullName(master);
  if pluginVal = masterVal then
    Result := ''
  else
    Result := pluginVal;
end;

//============================================================================
function RobCoExportListFieldIfChanged(e: IInterface; const pluginList, masterList: string): string;
begin
  Result := pluginList;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  if pluginList = masterList then
    Result := '';
end;

//============================================================================
procedure RobCoApplyRefListDiffIfCompact(e: IInterface; const pluginList, masterList: string;
  var refsToAdd, refsToRemove: string);
begin
  if not RobCoRecordHasExternalMaster(e) then begin
    refsToAdd := RobCoNoneIfEmpty(pluginList);
    refsToRemove := 'none';
    Exit;
  end;
  if RobCoSnapshotUseCompactFieldDiff then
    RobCoDiffCommaSeparatedRefs(pluginList, masterList, refsToAdd, refsToRemove)
  else begin
    refsToAdd := RobCoNoneIfEmpty(pluginList);
    refsToRemove := 'none';
  end;
end;

//============================================================================
procedure RobCoApplyKeywordDiffIfCompact(e: IInterface; const pluginKeywords: string;
  var keywordsToAdd, keywordsToRemove: string);
var
  master: IInterface;
  masterKeywords: string;
begin
  masterKeywords := '';
  if RobCoRecordHasExternalMaster(e) then begin
    master := MasterOrSelf(e);
    masterKeywords := RobCoReadKeywordRefsFromElement(master);
  end;
  RobCoApplyRefListDiffIfCompact(e, pluginKeywords, masterKeywords,
    keywordsToAdd, keywordsToRemove);
end;

//============================================================================
function RobCoSnapshotLineHasOperations(const line: string): boolean;
var
  rest, segment, key: string;
  colonPos, eqPos: integer;
begin
  Result := False;
  if line = '' then
    Exit;

  rest := line;
  while rest <> '' do begin
    colonPos := Pos(':', rest);
    if colonPos > 0 then begin
      segment := Copy(rest, 1, colonPos - 1);
      rest := Copy(rest, colonPos + 1, MaxInt);
    end else begin
      segment := rest;
      rest := '';
    end;

    eqPos := Pos('=', segment);
    if eqPos > 0 then begin
      key := Copy(segment, 1, eqPos - 1);
      if Pos('filterBy', key) <> 1 then begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

//============================================================================
function RobCoAppendField(const line, key, value: string; forceInclude: boolean): string;
begin
  if (value = '') or (value = 'none') then begin
    if not gRobCoExportWriteAllFields then begin
      Result := line;
      Exit;
    end;
  end;

  if line <> '' then
    Result := line + ':'
  else
    Result := '';

  Result := Result + key + '=' + RobCoNoneIfEmpty(value);
end;

//============================================================================
function RobCoAppendNumericField(const line, key, value: string): string;
begin
  // RobCo Patcher parses these with stof/stoi; =none crashes at game load.
  if (value = '') or (value = 'none') then begin
    Result := line;
    Exit;
  end;

  if line <> '' then
    Result := line + ':'
  else
    Result := '';

  Result := Result + key + '=' + value;
end;

//============================================================================
function RobCoAppendPatchField(const line, key, value: string): string;
begin
  Result := RobCoAppendField(line, key, value, True);
end;

//============================================================================
function RobCoGetKeywordsElement(e: IInterface): IInterface;
begin
  Result := ElementByPath(e, 'Keywords\KWDA');
  if not Assigned(Result) then
    Result := ElementBySignature(e, 'KWDA');
end;

//============================================================================
procedure RobCoEnsureKeywordPartsScratch;
begin
  if not Assigned(gRobCoKeywordPartsScratch) then
    gRobCoKeywordPartsScratch := TStringList.Create;
  gRobCoKeywordPartsScratch.Clear;
end;

//============================================================================
procedure RobCoEnsureDiffScratch;
begin
  if not Assigned(gRobCoDiffScratchPlugin) then begin
    gRobCoDiffScratchPlugin := TStringList.Create;
    gRobCoDiffScratchMaster := TStringList.Create;
    gRobCoDiffScratchAdd := TStringList.Create;
    gRobCoDiffScratchRem := TStringList.Create;
  end;
  gRobCoDiffScratchPlugin.Clear;
  gRobCoDiffScratchMaster.Clear;
  gRobCoDiffScratchAdd.Clear;
  gRobCoDiffScratchRem.Clear;
end;

//============================================================================
function RobCoReadKeywordRefs(kwda: IInterface): string;
var
  i: integer;
  kw: IInterface;
begin
  Result := '';
  if not Assigned(kwda) then
    Exit;

  RobCoEnsureKeywordPartsScratch;
  for i := 0 to Pred(ElementCount(kwda)) do begin
    kw := LinksTo(ElementByIndex(kwda, i));
    if not Assigned(kw) then
      Continue;
    if Signature(kw) <> 'KYWD' then
      Continue;
    gRobCoKeywordPartsScratch.Add(RobCoMasterFormIDRef(kw));
  end;
  Result := RobCoJoinParts(gRobCoKeywordPartsScratch);
end;

//============================================================================
function RobCoReadKeywordRefsFromElement(e: IInterface): string;
begin
  Result := RobCoReadKeywordRefs(RobCoGetKeywordsElement(e));
end;

//============================================================================
procedure RobCoDiffCommaSeparatedRefs(const pluginRefs, masterRefs: string;
  var refsToAdd, refsToRemove: string);
var
  i: integer;
  ref: string;
begin
  refsToAdd := 'none';
  refsToRemove := 'none';

  RobCoEnsureDiffScratch;
  RobCoParseCommaList(gRobCoDiffScratchPlugin, pluginRefs);
  RobCoParseCommaList(gRobCoDiffScratchMaster, masterRefs);

  for i := 0 to Pred(gRobCoDiffScratchPlugin.Count) do begin
    ref := Trim(gRobCoDiffScratchPlugin[i]);
    if ref = '' then
      Continue;
    if gRobCoDiffScratchMaster.IndexOf(ref) < 0 then
      gRobCoDiffScratchAdd.Add(ref);
  end;

  for i := 0 to Pred(gRobCoDiffScratchMaster.Count) do begin
    ref := Trim(gRobCoDiffScratchMaster[i]);
    if ref = '' then
      Continue;
    if gRobCoDiffScratchPlugin.IndexOf(ref) < 0 then
      gRobCoDiffScratchRem.Add(ref);
  end;

  refsToAdd := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoDiffScratchAdd));
  refsToRemove := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoDiffScratchRem));
end;

//============================================================================
function RobCoStripTrailingBackslash(const s: string): string;
begin
  Result := s;
  if Result = '' then
    Exit;
  if Result[Length(Result)] = '\' then
    SetLength(Result, Length(Result) - 1);
end;

//============================================================================
function RobCoEnsureTrailingBackslash(const s: string): string;
begin
  Result := s;
  if Result = '' then
    Exit;
  if Result[Length(Result)] = '\' then
    Exit;
  Result := Result + '\';
end;

//============================================================================
function RobCoPatcherFrameworkRoot: string;
begin
  if RobCoFO4Game then
    Result := 'F4SE\Plugins\RobCo_Patcher\'
  else
    Result := 'SKSE\Plugins\SkyPatcher\';
end;

//============================================================================
function RobCoPatcherCategoryForOperation(opIndex: integer): string;
begin
  // opIndex values match RobCo Tools.pas idx* constants.
  case opIndex of
    0: Result := 'leveledList';
    1:
      if RobCoFO4Game then
        Result := 'leveledList'
      else
        Result := 'container';
    2: Result := 'race';
    3: Result := 'npc';
    4: Result := 'formList';
    5: Result := 'constructibleObject';
    6: Result := 'misc';
    7: Result := 'ingestible';
    8: Result := 'armor';
    9: Result := 'weapon';
    10: Result := 'ammo';
    11: Result := 'objectModification';
  else
    Result := '';
  end;
end;

//============================================================================
procedure RobCoBuildPatcherCategoryDir(const basePath: string; opIndex: integer);
var
  cat, root, base, built: string;
begin
  gRobCoPatcherOutputDir := '';
  gRobCoPatcherDirBare := '';
  cat := RobCoPatcherCategoryForOperation(opIndex);
  if cat = '' then
    Exit;
  base := RobCoEnsureTrailingBackslash(basePath);
  root := RobCoPatcherFrameworkRoot;
  built := base;
  built := built + root;
  built := built + cat;
  // JvInterpreter: assign globals from local built only (not global-to-global).
  gRobCoPatcherDirBare := built;
  gRobCoPatcherOutputDir := built + '\';
end;

//============================================================================
function RobCoEnsurePatcherOutputDir(const basePath: string; opIndex: integer): boolean;
begin
  Result := False;
  if RobCoPatcherCategoryForOperation(opIndex) = '' then begin
    AddMessage('Export cancelled: unknown record type for patcher folder (opIndex=' +
      IntToStr(opIndex) + ').');
    Exit;
  end;
  RobCoBuildPatcherCategoryDir(basePath, opIndex);
  if Length(gRobCoPatcherDirBare) = 0 then begin
    AddMessage('Export cancelled: could not resolve patcher output folder (opIndex=' +
      IntToStr(opIndex) + ').');
    Exit;
  end;
  if DirectoryExists(gRobCoPatcherDirBare) then begin
    Result := True;
    Exit;
  end;
  if ForceDirectories(gRobCoPatcherDirBare) then
    Result := True
  else
    AddMessage('Export cancelled: could not create output folder: ' + gRobCoPatcherDirBare);
end;

//============================================================================
function RobCoPatcherDeployFolderHint: string;
var
  dataPath, gameRoot: string;
begin
  dataPath := RobCoStripTrailingBackslash(DataPath);
  gameRoot := RobCoEnsureTrailingBackslash(ExtractFilePath(dataPath));
  if RobCoFO4Game then
    Result := gameRoot + 'F4SE\Plugins\RobCo_Patcher\'
  else
    Result := gameRoot + 'SKSE\Plugins\SkyPatcher\';
end;

//============================================================================
function RobCoPatcherDeployHint(const outputPath: string): string;
begin
  Result :=
    'Copy the exported ' + RobCoPatcherFrameworkRoot + ' subtree into your game install:' + #13#10 +
    RobCoPatcherDeployFolderHint + #13#10 +
    'Exported to: ' + outputPath;
end;

//============================================================================
function RobCoGetApprElement(e: IInterface): IInterface;
begin
  Result := ElementBySignature(e, 'APPR');
  if not Assigned(Result) then
    Result := ElementByPath(e, 'Keywords\APPR');
end;

//============================================================================
function RobCoReadApprKeywordRefs(e: IInterface): string;
begin
  Result := RobCoReadKeywordRefs(RobCoGetApprElement(e));
end;

//============================================================================
function RobCoReadFullName(e: IInterface): string;
var
  s: string;
begin
  Result := '';
  s := GetElementEditValues(e, 'FULL');
  if s = '' then
    Exit;
  // Tilde-wrapped FULL for RobCo Patcher / SkyPatcher item and actor exports.
  Result := '~' + s + '~';
end;

//============================================================================
function RobCoReadPlainFullName(e: IInterface): string;
begin
  // Plain FULL (no tildes) for FO4 OMOD exports per RobCo OMOD schema.
  Result := GetElementEditValues(e, 'FULL');
end;

//============================================================================
function RobCoReadFormLinkFirst(e: IInterface; const path1, path2: string): string;
begin
  Result := RobCoReadFormLinkPath(e, path1);
  if Result = '' then
    Result := RobCoReadFormLinkPath(e, path2);
end;

//============================================================================
function RobCoReadFormLinkFirst3(e: IInterface; const path1, path2, path3: string): string;
begin
  Result := RobCoReadFormLinkFirst(e, path1, path2);
  if Result = '' then
    Result := RobCoReadFormLinkPath(e, path3);
end;

//============================================================================
function RobCoReadFormLinkPathOrRef(e: IInterface; const path, sigName: string): string;
begin
  Result := RobCoReadFormLinkPath(e, path);
  if Result = '' then
    Result := RobCoReadFormLinkRef(e, sigName);
end;

//============================================================================
function RobCoReadUnionFormLink(elem: IInterface): IInterface;
var
  obj: IInterface;
begin
  Result := nil;
  if not Assigned(elem) then
    Exit;

  if ElementExists(elem, 'Value\Object') then
    obj := ElementByPath(elem, 'Value\Object')
  else if ElementExists(elem, 'Value\Object Union\Object v2\FormID') then
    obj := ElementByPath(elem, 'Value\Object Union\Object v2\FormID')
  else if ElementExists(elem, 'Object') then
    obj := ElementByPath(elem, 'Object');

  if Assigned(obj) then
    Result := LinksTo(obj);
end;

//============================================================================
function RobCoReadFormLinkRef(e: IInterface; const sigName: string): string;
var
  link: IInterface;
begin
  Result := '';
  link := LinksTo(ElementBySignature(e, sigName));
  if Assigned(link) then
    Result := RobCoMasterFormIDRef(link);
end;

//============================================================================
function RobCoReadFormLinkPath(e: IInterface; const path: string): string;
var
  link: IInterface;
begin
  Result := '';
  if not ElementExists(e, path) then
    Exit;
  link := LinksTo(ElementByPath(e, path));
  if Assigned(link) then
    Result := RobCoMasterFormIDRef(link);
end;

//============================================================================
function RobCoReadDataField(e: IInterface; const fieldName: string): string;
begin
  Result := '';
  if ElementExists(e, 'DATA\' + fieldName) then
    Result := GetElementEditValues(e, 'DATA\' + fieldName);
end;

//============================================================================
function RobCoRecordComment(const editorID, pluginName, sig: string; rec: IInterface;
  shortComment: boolean): string;
begin
  if shortComment then
    Result := '//' + editorID + ' [' + sig + ':' + FormatFormID(rec) + ']'
  else
    Result := '//' + editorID + ' [' + pluginName + '|' + sig + ':' + FormatFormID(rec) + ']';
end;

//============================================================================
function RobCoIsVanillaOrCCPlugin(f: IInterface): boolean;
var
  name: string;
  vanillaList: string;
begin
  name := Lowercase(GetFileName(f));

  if Pos('.hardcoded.', name) > 0 then begin
    Result := True;
    Exit;
  end;

  if SameText(ExtractFileExt(name), '.exe') then begin
    Result := True;
    Exit;
  end;

  if (Length(name) >= 2) and (Copy(name, 1, 2) = 'cc') and SameText(ExtractFileExt(name), '.esl') then begin
    Result := True;
    Exit;
  end;

  case wbGameMode of
    gmFO4, gmFO4VR:
      vanillaList := RobCoFO4VanillaPlugins;
    gmTES5, gmSSE:
      vanillaList := RobCoSkyrimVanillaPlugins;
    gmTES4:
      vanillaList := RobCoOblivionVanillaPlugins;
    gmFO3:
      vanillaList := RobCoFO3VanillaPlugins;
    gmFNV:
      vanillaList := RobCoFNVVanillaPlugins;
  else
    vanillaList := '';
  end;

  Result := (vanillaList <> '') and (Pos(',' + name + ',', vanillaList) > 0);
end;

//============================================================================
function SelectPlugins(slSelected: TStringList; const caption: string): boolean;
var
  frm: TForm;
  clb: TCheckListBox;
  i: integer;
  f: IInterface;
begin
  Result := False;
  frm := frmFileSelect;
  try
    frm.Caption := caption;
    clb := TCheckListBox(frm.FindComponent('CheckListBox1'));
    for i := 0 to Pred(FileCount) do begin
      f := FileByIndex(i);
      clb.Items.AddObject(GetFileName(f), f);
      clb.Checked[clb.Items.Count - 1] := not RobCoIsVanillaOrCCPlugin(f);
    end;
    if frm.ShowModal <> mrOk then
      Exit;
    for i := 0 to Pred(clb.Items.Count) do
      if clb.Checked[i] then
        slSelected.AddObject(clb.Items[i], clb.Items.Objects[i]);
    Result := slSelected.Count > 0;
  finally
    frm.Free;
  end;
end;

//============================================================================
function SelectRobCoOutputDirectory(const prompt: string): string;
begin
  Result := SelectDirectory(prompt, '', DataPath, nil);
  if Result <> '' then begin
    if DirectoryExists(Result) then
      Result := RobCoEnsureTrailingBackslash(Result)
    else
      Result := '';
  end;
end;

//============================================================================
function SelectRobCoOutputFile(const defaultName: string): string;
var
  dlgSave: TSaveDialog;
begin
  Result := '';
  dlgSave := TSaveDialog.Create(nil);
  try
    dlgSave.Options := dlgSave.Options + [ofOverwritePrompt];
    dlgSave.Filter := 'INI files (*.ini)|*.ini';
    dlgSave.InitialDir := DataPath;
    dlgSave.FileName := defaultName;
    if dlgSave.Execute then
      Result := dlgSave.FileName;
  finally
    dlgSave.Free;
  end;
end;

//============================================================================
function RobCoIniLineIsCombinedSectionHeader(const line: string): boolean;
var
  trimmed: string;
begin
  trimmed := Trim(line);
  Result := (Length(trimmed) >= 7) and (Copy(trimmed, 1, 7) = '//=====');
end;

//============================================================================
function RobCoIniLineIsRecordComment(const line: string): boolean;
var
  trimmed: string;
begin
  trimmed := Trim(line);
  Result := (trimmed <> '') and (Copy(trimmed, 1, 2) = '//') and
    (not RobCoIniLineIsCombinedSectionHeader(trimmed));
end;

//============================================================================
function RobCoIniLineIsPatchDataLine(const line: string): boolean;
begin
  Result := (Trim(line) <> '') and (Copy(Trim(line), 1, 2) <> '//');
end;

//============================================================================
function RobCoNormalizePatchDataLine(const line: string): string;
var
  trimmed, head, tail: string;
  eqPos, i: integer;
begin
  trimmed := Trim(line);
  eqPos := Pos('=', trimmed);
  if eqPos <= 0 then begin
    Result := trimmed;
    Exit;
  end;
  head := Copy(trimmed, 1, eqPos);
  tail := Copy(trimmed, eqPos + 1, MaxInt);
  i := 1;
  while (i <= Length(tail)) and (tail[i] = ' ') do
    Inc(i);
  if i > 1 then
    tail := Copy(tail, i, MaxInt);
  Result := head + tail;
end;

//============================================================================
function RobCoIniWriterDedupeCombinedBuffer: integer;
var
  output, seen: TStringList;
  i, removed: integer;
  line, normalized, pendingComment: string;
begin
  Result := 0;
  if not Assigned(gRobCoIniLineBuffer) then
    Exit;
  if gRobCoIniLineBuffer.Count = 0 then
    Exit;

  if not Assigned(gRobCoIniDedupeOutputScratch) then
    gRobCoIniDedupeOutputScratch := TStringList.Create;
  gRobCoIniDedupeOutputScratch.Clear;
  output := gRobCoIniDedupeOutputScratch;
  if not Assigned(gRobCoIniDedupeSeenScratch) then
    gRobCoIniDedupeSeenScratch := TStringList.Create;
  gRobCoIniDedupeSeenScratch.Clear;
  gRobCoIniDedupeSeenScratch.Sorted := True;
  gRobCoIniDedupeSeenScratch.Duplicates := dupIgnore;
  seen := gRobCoIniDedupeSeenScratch;
  removed := 0;
  pendingComment := '';

  for i := 0 to Pred(gRobCoIniLineBuffer.Count) do begin
      line := gRobCoIniLineBuffer[i];

      if RobCoIniLineIsCombinedSectionHeader(line) then begin
        pendingComment := '';
        output.Add(line);
        Continue;
      end;

      if Trim(line) = '' then begin
        pendingComment := '';
        output.Add(line);
        Continue;
      end;

      if RobCoIniLineIsRecordComment(line) then begin
        pendingComment := line;
        Continue;
      end;

      if RobCoIniLineIsPatchDataLine(line) then begin
        normalized := RobCoNormalizePatchDataLine(line);
        if seen.IndexOf(normalized) >= 0 then begin
          Inc(removed);
          Continue;
        end;
        seen.Add(normalized);
        if pendingComment <> '' then begin
          output.Add(pendingComment);
          pendingComment := '';
        end;
        output.Add(normalized);
      end else
        output.Add(line);
    end;

  gRobCoIniLineBuffer.Clear;
  gRobCoIniLineBuffer.AddStrings(output);
  Result := removed;
end;

//============================================================================
procedure RobCoIniWriterFlushBuffer;
var
  merged: TStringList;
  removed: integer;
begin
  if not Assigned(gRobCoIniLineBuffer) then
    Exit;
  if gRobCoIniLineBuffer.Count = 0 then
    Exit;
  if gRobCoIniActivePath = '' then
    Exit;
  try
    if not gRobCoIniPerPlugin then begin
      removed := RobCoIniWriterDedupeCombinedBuffer;
      if removed > 0 then
        RobCoLogSkippedDuplicate(Format('Skipped %d duplicate patch line(s) in %s',
          [removed, gRobCoIniActivePath]));
    end;
    if (not gRobCoIniOverwriteOnFlush) and FileExists(gRobCoIniActivePath) then begin
      merged := TStringList.Create;
      try
        merged.LoadFromFile(gRobCoIniActivePath);
        merged.AddStrings(gRobCoIniLineBuffer);
        merged.SaveToFile(gRobCoIniActivePath);
      finally
        merged.Free;
      end;
    end else
      gRobCoIniLineBuffer.SaveToFile(gRobCoIniActivePath);
    gRobCoIniOverwriteOnFlush := False;
    gRobCoIniLineBuffer.Clear;
  except
    AddMessage('Error flushing INI: ' + gRobCoIniActivePath);
  end;
end;

//============================================================================
procedure RobCoIniWriterCloseActiveFile;
begin
  RobCoIniWriterFlushBuffer;
  gRobCoIniFileActive := False;
  gRobCoIniActivePath := '';
end;

//============================================================================
procedure RobCoIniWriterActivatePath(const path: string; countAsNewFile: boolean);
begin
  if gRobCoIniActivePath = path then
    Exit;
  RobCoIniWriterFlushBuffer;
  gRobCoIniActivePath := path;
  gRobCoIniFileActive := True;
  gRobCoIniOverwriteOnFlush := countAsNewFile;
  if countAsNewFile then begin
    Inc(gRobCoIniFilesCreated);
    RobCoQueueExportLog('Created INI: ' + path);
  end;
end;

//============================================================================
procedure RobCoIniWriterQueueLine(const line: string);
begin
  if not Assigned(gRobCoIniLineBuffer) then
    Exit;
  gRobCoIniLineBuffer.Add(line);
end;

//============================================================================
procedure RobCoIniWriterShutdown;
begin
  RobCoIniWriterCloseActiveFile;
  gRobCoIniWriterActive := False;
end;

//============================================================================
procedure RobCoIniWriterInit;
begin
  RobCoIniWriterShutdown;
  gRobCoIniWriterActive := True;
  if not Assigned(gRobCoIniPluginsStarted) then begin
    gRobCoIniPluginsStarted := TStringList.Create;
    gRobCoIniPluginsStarted.Sorted := True;
    gRobCoIniPluginsStarted.Duplicates := dupIgnore;
  end;
  if not Assigned(gRobCoIniLineBuffer) then
    gRobCoIniLineBuffer := TStringList.Create;
  gRobCoIniLineBuffer.Clear;
end;

//============================================================================
procedure RobCoIniWriterBeginOp(const outputDir: string; perPlugin: boolean;
  const combinedFileName: string);
begin
  RobCoIniWriterCloseActiveFile;
  gRobCoIniOutputDir := outputDir;
  gRobCoIniPerPlugin := perPlugin;
  gRobCoIniCombinedFileName := combinedFileName;
  gRobCoIniCurrentPlugin := '';
  gRobCoIniFilesCreated := 0;
  gRobCoIniCombinedFileStarted := False;
  gRobCoIniNeedCombinedPluginHeader := False;
  if Assigned(gRobCoIniPluginsStarted) then
    gRobCoIniPluginsStarted.Clear;
end;

//============================================================================
procedure RobCoIniWriterEnsurePlugin(const pluginName: string);
var
  path: string;
  newFile: boolean;
begin
  if gRobCoIniPerPlugin then begin
    path := gRobCoIniOutputDir + pluginName + '.ini';
    if gRobCoIniCurrentPlugin <> pluginName then begin
      RobCoIniWriterFlushBuffer;
      gRobCoIniCurrentPlugin := pluginName;
      gRobCoIniActivePath := '';
    end;
    newFile := gRobCoIniPluginsStarted.IndexOf(pluginName) < 0;
    if newFile then
      gRobCoIniPluginsStarted.Add(pluginName);
    RobCoIniWriterActivatePath(path, newFile);
  end else begin
    if gRobCoIniCurrentPlugin <> pluginName then begin
      gRobCoIniCurrentPlugin := pluginName;
      gRobCoIniNeedCombinedPluginHeader := True;
    end;
    path := gRobCoIniOutputDir + gRobCoIniCombinedFileName;
    newFile := not gRobCoIniCombinedFileStarted;
    if newFile then
      gRobCoIniCombinedFileStarted := True;
    RobCoIniWriterActivatePath(path, newFile);
  end;
end;

//============================================================================
procedure RobCoIniWriterWriteLine(const line: string);
begin
  if not gRobCoIniWriterActive then
    Exit;
  if (not gRobCoIniPerPlugin) and gRobCoIniNeedCombinedPluginHeader then begin
    RobCoIniWriterQueueLine('//===== ' + gRobCoIniCurrentPlugin + ' =====');
    RobCoIniWriterQueueLine('');
    gRobCoIniNeedCombinedPluginHeader := False;
  end;
  RobCoIniWriterQueueLine(line);
end;

//============================================================================
procedure RobCoIniWriterWriteRecordBlock(const pluginName, commentLine, dataLine: string);
begin
  RobCoIniWriterEnsurePlugin(pluginName);
  RobCoIniWriterWriteLine(commentLine);
  RobCoIniWriterWriteLine(dataLine);
  RobCoIniWriterWriteLine('');
end;

//============================================================================
procedure RobCoIniWriterWriteRecordLines(const pluginName, commentLine: string;
  lines: TStringList);
var
  i: integer;
begin
  RobCoIniWriterEnsurePlugin(pluginName);
  RobCoIniWriterWriteLine(commentLine);
  if Assigned(lines) then begin
    for i := 0 to Pred(lines.Count) do
      RobCoIniWriterWriteLine(lines[i]);
  end;
  RobCoIniWriterWriteLine('');
end;

//============================================================================
function RobCoIniWriterEndOp: integer;
begin
  RobCoIniWriterCloseActiveFile;
  Result := gRobCoIniFilesCreated;
end;

//============================================================================
procedure RobCoSnapEnsureMasterCache;
begin
  if not Assigned(gRobCoSnapMasterCacheKeys) then
    gRobCoSnapMasterCacheKeys := TStringList.Create;
  if not Assigned(gRobCoSnapMasterCacheVals) then begin
    gRobCoSnapMasterCacheVals := TStringList.Create;
  end;
end;

//============================================================================
procedure RobCoSnapMasterCacheClear;
begin
  if Assigned(gRobCoSnapMasterCacheKeys) then
    gRobCoSnapMasterCacheKeys.Clear;
  if Assigned(gRobCoSnapMasterCacheVals) then
    gRobCoSnapMasterCacheVals.Clear;
end;

//============================================================================
function RobCoSnapMasterCacheKey(master: IInterface; const fieldTag: string): string;
begin
  Result := RobCoMasterFormIDRef(master) + '|' + fieldTag;
end;

//============================================================================
function RobCoSnapMasterCacheIndex(const key: string): integer;
begin
  RobCoSnapEnsureMasterCache;
  Result := gRobCoSnapMasterCacheKeys.IndexOf(key);
end;

//============================================================================
procedure RobCoSnapMasterCachePut(const key, val: string);
var
  idx: integer;
begin
  RobCoSnapEnsureMasterCache;
  idx := gRobCoSnapMasterCacheKeys.IndexOf(key);
  if idx >= 0 then
    gRobCoSnapMasterCacheVals[idx] := val
  else begin
    gRobCoSnapMasterCacheKeys.Add(key);
    gRobCoSnapMasterCacheVals.Add(val);
  end;
end;

//============================================================================
function RobCoSnapMasterCacheValueAt(idx: integer): string;
begin
  Result := '';
  if idx < 0 then
    Exit;
  RobCoSnapEnsureMasterCache;
  if idx >= gRobCoSnapMasterCacheVals.Count then
    Exit;
  Result := gRobCoSnapMasterCacheVals[idx];
end;

end.
