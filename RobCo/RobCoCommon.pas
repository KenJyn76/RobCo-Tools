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

const
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
  if not Assigned(e) or IsMaster(e) then begin
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
function RobCoShouldProcessOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := False;
  if not Assigned(e) then
    Exit;
  if not RobCoShouldExportRecord(e, overridesOnly) then
    Exit;
  if (not forwardItms) and RobCoRecordUnchangedVsMaster(e) then
    Exit;
  Result := True;
end;

//============================================================================
procedure RobCoBeginExport;
begin
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
  AddMessage(msg);
end;

//============================================================================
procedure RobCoEmitSnapshotRecord(e: IInterface; const sig: string;
  forwardItms, overridesOnly, shortComment: boolean; const line: string);
var
  pluginName, editorID, msgLabel: string;
begin
  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  if not RobCoSnapshotLineHasOperations(line) then
    Exit;

  if not gRobCoIniWriterActive then
    Exit;

  pluginName := GetFileName(GetFile(e));
  editorID := RobCoEditorID(e);

  RobCoIniWriterWriteRecordBlock(pluginName,
    RobCoRecordComment(editorID, pluginName, sig, e, shortComment), line);

  if sig = 'NPC_' then
    msgLabel := 'NPC'
  else
    msgLabel := sig;

  AddMessage(Format('Processed ' + msgLabel + ': %s [%s|' + sig + ':%s]', [
    editorID, pluginName, FormatFormID(e)
  ]));
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
function RobCoSnapshotOmitUnchangedFields: boolean;
begin
  Result := (not gRobCoExportWriteAllFields) and (not gRobCoExportForwardItms);
end;

//============================================================================
function RobCoExportFieldIfChanged(e: IInterface; const pluginValue, masterValue: string): string;
begin
  Result := pluginValue;
  if not RobCoSnapshotOmitUnchangedFields then
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
  if not RobCoSnapshotOmitUnchangedFields then begin
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
  if not RobCoSnapshotOmitUnchangedFields then begin
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
  if not RobCoSnapshotOmitUnchangedFields then begin
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
  if not RobCoSnapshotOmitUnchangedFields then
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
  if RobCoSnapshotOmitUnchangedFields then
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
function RobCoReadKeywordRefs(kwda: IInterface): string;
var
  i: integer;
  kw: IInterface;
  parts: TStringList;
begin
  Result := '';
  if not Assigned(kwda) then
    Exit;

  parts := TStringList.Create;
  try
    for i := 0 to Pred(ElementCount(kwda)) do begin
      kw := LinksTo(ElementByIndex(kwda, i));
      if not Assigned(kw) then
        Continue;
      if Signature(kw) <> 'KYWD' then
        Continue;
      parts.Add(RobCoMasterFormIDRef(kw));
    end;
    Result := RobCoJoinParts(parts);
  finally
    parts.Free;
  end;
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
  pluginSl, masterSl, addParts, remParts: TStringList;
  i: integer;
  ref: string;
begin
  refsToAdd := 'none';
  refsToRemove := 'none';

  pluginSl := TStringList.Create;
  masterSl := TStringList.Create;
  addParts := TStringList.Create;
  remParts := TStringList.Create;
  try
    RobCoParseCommaList(pluginSl, pluginRefs);
    RobCoParseCommaList(masterSl, masterRefs);

    for i := 0 to Pred(pluginSl.Count) do begin
      ref := Trim(pluginSl[i]);
      if ref = '' then
        Continue;
      if masterSl.IndexOf(ref) < 0 then
        addParts.Add(ref);
    end;

    for i := 0 to Pred(masterSl.Count) do begin
      ref := Trim(masterSl[i]);
      if ref = '' then
        Continue;
      if pluginSl.IndexOf(ref) < 0 then
        remParts.Add(ref);
    end;

    refsToAdd := RobCoNoneIfEmpty(RobCoJoinParts(addParts));
    refsToRemove := RobCoNoneIfEmpty(RobCoJoinParts(remParts));
  finally
    remParts.Free;
    addParts.Free;
    masterSl.Free;
    pluginSl.Free;
  end;
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
procedure RobCoIniWriterFlushBuffer;
var
  merged: TStringList;
begin
  if not Assigned(gRobCoIniLineBuffer) then
    Exit;
  if gRobCoIniLineBuffer.Count = 0 then
    Exit;
  if gRobCoIniActivePath = '' then
    Exit;
  try
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
    AddMessage('Created INI: ' + path);
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

end.
