{
  Shared export I/O, globals, and record gates.
}
unit RobCoCommon;

var
  slRobCoExportLog: TStringList;
  gRobCoExportWriteAllFields: boolean;
  gRobCoExportForwardItms: boolean;
  gRobCoSnapItmGateActive: boolean;
  gRobCoListExportAdd: boolean;
  gRobCoListExportRemove: boolean;
  gRobCoPerPlugin: boolean;
  gRobCoOverridesOnly: boolean;
  gRobCoCompareDeclaredMasters: boolean;
  gRobCoSelectedOps: TStringList;
  gRobCoPatcherOutputDir: string;
  gRobCoPatcherDirBare: string;
  gRobCoPatcherRootDirBare: string;
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
  gRobCoIniMergeScratch: TStringList;
  gRobCoIniDeferredAggregate: TStringList;
  gRobCoPluginNameByLoadOrder: TStringList;

  gRobCoSnapMasterCacheKeys: TStringList;
  gRobCoSnapMasterCacheVals: TStringList;
  gRobCoSnapRecordCacheKeys: TStringList;
  gRobCoSnapRecordCacheVals: TStringList;
  gRobCoSnapConflictProbeKeys: TStringList;

  gRobCoProgressLastReportMs: integer;
  gRobCoProgressPluginTotal: integer;
  gRobCoProgressOpNum: integer;
  gRobCoProgressOpTotal: integer;
  gRobCoProgressOpLabel: string;

{ DEBUG_INJECT_SYNC_GLOBALS: debug injection site — sync-profile splices stat globals (profile_markers.json) }
// DEBUG_INJECT_SYNC_GLOBALS

  gRobCoPluginGroupCache: TStringList;
  gRobCoIniCachedPerPluginName: string;
  gRobCoIniCachedPerPluginPath: string;
  gRobCoIniCachedCombinedPath: string;
  gRobCoExportRunId: string;
  gRobCoReliedPluginsByFile: TStringList;
  gRobCoGameMasterFileName: string;

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

  RobCoIniDeferredPathMarker = '//@@ROBCO_DEFERRED_PATH:';
  { Peak line buffer before chunk flush — same ceiling as load-order catalog exporter (~327680 lines).
    Catalog OOM at FlushLineCount=0 held ~1.55M Fallout4.esm lines; combined INI must not grow unbounded. }
  RobCoIniFlushLineCount = 327680;
  RobCoIniDeferAggregateFlushLineCount = 327680;
  RobCoIniDeferDiskFlush = True;

//============================================================================
function RobCoNowMs: integer;
begin
  Result := Trunc(Now * 86400000);
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

{ DEBUG_INJECT_SYNC_PROCS: debug injection site — sync-profile splices debug/perfmon procedures until function RobCoJsonEscape }
// DEBUG_INJECT_SYNC_PROCS
//============================================================================
procedure RobCoLogSkippedDuplicate(const msg: string);
begin
  RobCoQueueExportLog(msg);
end;

//============================================================================
function RobCoJsonEscape(const s: string): string;
var
  i: integer;
  ch: string;
begin
  Result := '';
  for i := 1 to Length(s) do begin
    ch := Copy(s, i, 1);
    if ch = '\' then
      Result := Result + '\\'
    else if ch = '"' then
      Result := Result + '\"'
    else
      Result := Result + ch;
  end;
end;

//============================================================================
function RobCoJsonBool(flag: boolean): string;
begin
  if flag then
    Result := 'true'
  else
    Result := 'false';
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
procedure RobCoEnsurePluginNameCache;
begin
  if not Assigned(gRobCoPluginNameByLoadOrder) then
    gRobCoPluginNameByLoadOrder := TStringList.Create;
end;

//============================================================================
procedure RobCoBuildPluginNameCache;
var
  i, lo, maxLo: integer;
  f: IInterface;
begin
  RobCoEnsurePluginNameCache;
  gRobCoPluginNameByLoadOrder.Clear;
  maxLo := 0;
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if not Assigned(f) then
      Continue;
    lo := GetLoadOrder(f);
    if lo > maxLo then
      maxLo := lo;
  end;
  while gRobCoPluginNameByLoadOrder.Count <= maxLo do
    gRobCoPluginNameByLoadOrder.Add('');
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if not Assigned(f) then
      Continue;
    lo := GetLoadOrder(f);
    gRobCoPluginNameByLoadOrder[lo] := GetFileName(f);
  end;
end;

//============================================================================
function RobCoPluginNameForFile(af: IInterface): string;
var
  lo: integer;
begin
  Result := '';
  if not Assigned(af) then
    Exit;
  lo := GetLoadOrder(af);
  if Assigned(gRobCoPluginNameByLoadOrder) then begin
    if lo >= 0 then begin
      if lo < gRobCoPluginNameByLoadOrder.Count then begin
        Result := gRobCoPluginNameByLoadOrder[lo];
        if Result <> '' then
          Exit;
      end;
    end;
  end;
  Result := GetFileName(af);
end;

//============================================================================
function RobCoPluginNameForRecord(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := RobCoPluginNameForFile(GetFile(e));
end;

//============================================================================
function FormIDRef(rec: IInterface): string;
begin
  Result := RobCoPluginNameForRecord(rec) + '|' + FormatFormID(rec);
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
  master := RobCoCompareBaselineRecord(e);
  if not Assigned(master) then begin
    Result := False;
    Exit;
  end;
  Result := ConflictAllForElements(e, master, False, False) <= caNoConflict;
end;

//============================================================================
function RobCoSubElementConflictFree(a, b: IInterface): boolean;
var
  countA, countB: integer;
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
  countA := ElementCount(a);
  countB := ElementCount(b);
  if countA = 0 then begin
    if countB = 0 then
      Result := True
    else
      Result := False;
    Exit;
  end;
  Result := ConflictAllForElements(a, b, False, False) <= caNoConflict;
end;

//============================================================================
// Key must include the override's own identity (FormIDRef(e)) so that different
// plugins overriding the same master weapon/NPC do not share cache entries.
// Using RobCoPatchFilterFormIDRef(e) = FormIDRef(MasterOrSelf(e)) collapses all
// overrides of the same master to the same key, causing stale conflictFree=True
// hits that silently suppress keyword/subgraph changes in later override plugins.
function RobCoSnapConflictProbeCacheKey(e, master: IInterface; const tag: string): string;
begin
  Result := FormIDRef(e) + #1 + RobCoPatchFilterFormIDRef(master) + #1 + tag;
end;

//============================================================================
procedure RobCoSnapEnsureConflictProbeCache;
begin
  if not Assigned(gRobCoSnapConflictProbeKeys) then begin
    gRobCoSnapConflictProbeKeys := TStringList.Create;
    gRobCoSnapConflictProbeKeys.Sorted := True;
    gRobCoSnapConflictProbeKeys.Duplicates := dupIgnore;
  end;
end;

//============================================================================
function RobCoSnapConflictProbeCacheTryGet(const key: string; var conflictFree: boolean): boolean;
var
  idx: integer;
begin
  Result := False;
  if not Assigned(gRobCoSnapConflictProbeKeys) then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.conflict.probe.cache.miss 1
    Exit;
  end;
  idx := gRobCoSnapConflictProbeKeys.IndexOf(key);
  if idx < 0 then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.conflict.probe.cache.miss 1
    Exit;
  end;
  conflictFree := Integer(gRobCoSnapConflictProbeKeys.Objects[idx]) <> 0;
  // DEBUG_INJECT_PERFMON_COUNTER count.conflict.probe.cache.hit 1
  Result := True;
end;

//============================================================================
procedure RobCoSnapConflictProbeCachePut(const key: string; conflictFree: boolean);
var
  idx: integer;
  flag: integer;
begin
  RobCoSnapEnsureConflictProbeCache;
  if conflictFree then
    flag := 1
  else
    flag := 0;
  idx := gRobCoSnapConflictProbeKeys.IndexOf(key);
  if idx >= 0 then
    gRobCoSnapConflictProbeKeys.Objects[idx] := TObject(flag)
  else
    gRobCoSnapConflictProbeKeys.AddObject(key, TObject(flag));
end;

//============================================================================
function RobCoSubElementConflictFreeByPath(e, master: IInterface; const path: string): boolean;
var
  a, b: IInterface;
  key: string;
begin
  key := RobCoSnapConflictProbeCacheKey(e, master, 'p:' + path);
  if RobCoSnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  if not ElementExists(e, path) then begin
    if not ElementExists(master, path) then
      Result := True
    else
      Result := False;
    RobCoSnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  if not ElementExists(master, path) then begin
    Result := False;
    RobCoSnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  a := ElementByPath(e, path);
  b := ElementByPath(master, path);
  Result := RobCoSubElementConflictFree(a, b);
  RobCoSnapConflictProbeCachePut(key, Result);
end;

//============================================================================
function RobCoSubElementConflictFreeByName(e, master: IInterface; const name: string): boolean;
var
  a, b: IInterface;
  key: string;
begin
  key := RobCoSnapConflictProbeCacheKey(e, master, 'n:' + name);
  if RobCoSnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  if not ElementExists(e, name) then begin
    if not ElementExists(master, name) then
      Result := True
    else
      Result := False;
    RobCoSnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  if not ElementExists(master, name) then begin
    Result := False;
    RobCoSnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  a := ElementByName(e, name);
  b := ElementByName(master, name);
  Result := RobCoSubElementConflictFree(a, b);
  RobCoSnapConflictProbeCachePut(key, Result);
end;

//============================================================================
function RobCoSubElementConflictFreeBySignature(e, master: IInterface; const sig: string): boolean;
var
  a, b: IInterface;
  key: string;
begin
  key := RobCoSnapConflictProbeCacheKey(e, master, 's:' + sig);
  if RobCoSnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  a := ElementBySignature(e, sig);
  b := ElementBySignature(master, sig);
  if not Assigned(a) then begin
    if not Assigned(b) then
      Result := True
    else
      Result := False;
    RobCoSnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  if not Assigned(b) then begin
    Result := False;
    RobCoSnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  Result := RobCoSubElementConflictFree(a, b);
  RobCoSnapConflictProbeCachePut(key, Result);
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
function RobCoFileByPluginName(const pluginName: string): IInterface;
var
  i: integer;
  f: IInterface;
begin
  Result := nil;
  if pluginName = '' then
    Exit;
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if not Assigned(f) then
      Continue;
    if SameText(GetFileName(f), pluginName) then begin
      Result := f;
      Exit;
    end;
  end;
end;

//============================================================================
function RobCoReliedPluginSetHas(relied: TStringList; const pluginNameLower: string): boolean;
var
  i: integer;
begin
  Result := False;
  if not Assigned(relied) then
    Exit;
  if pluginNameLower = '' then
    Exit;
  for i := 0 to Pred(relied.Count) do begin
    if SameText(relied[i], pluginNameLower) then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
procedure RobCoReliedPluginSetAdd(relied: TStringList; const pluginNameLower: string);
begin
  if not Assigned(relied) then
    Exit;
  if pluginNameLower = '' then
    Exit;
  if RobCoReliedPluginSetHas(relied, pluginNameLower) then
    Exit;
  relied.Add(pluginNameLower);
end;

//============================================================================
procedure RobCoReliedPluginsAppendDirectMasters(af: IInterface; relied, queue: TStringList);
var
  masters, ent: IInterface;
  i: integer;
  mastName, mastLower: string;
begin
  if not Assigned(af) then
    Exit;
  if not Assigned(relied) then
    Exit;
  if not Assigned(queue) then
    Exit;
  if ElementCount(af) <= 0 then
    Exit;
  masters := ElementByName(ElementByIndex(af, 0), 'Master Files');
  if not Assigned(masters) then
    Exit;
  for i := 0 to Pred(ElementCount(masters)) do begin
    ent := ElementByIndex(masters, i);
    mastName := Trim(GetElementEditValues(ent, 'MAST'));
    if mastName = '' then
      Continue;
    mastLower := LowerCase(mastName);
    RobCoReliedPluginSetAdd(relied, mastLower);
    if not RobCoReliedPluginSetHas(queue, mastLower) then
      queue.Add(mastLower);
  end;
end;

//============================================================================
function RobCoReliedPluginsForFile(af: IInterface): TStringList;
var
  cacheKey, gameLower, queueName: string;
  cacheIdx, i: integer;
  relied, queue: TStringList;
  nextFile: IInterface;
begin
  Result := nil;
  if not Assigned(af) then
    Exit;
  if not Assigned(gRobCoReliedPluginsByFile) then
    gRobCoReliedPluginsByFile := TStringList.Create;
  cacheKey := LowerCase(GetFileName(af));
  cacheIdx := gRobCoReliedPluginsByFile.IndexOf(cacheKey);
  if cacheIdx >= 0 then begin
    Result := TStringList(gRobCoReliedPluginsByFile.Objects[cacheIdx]);
    Exit;
  end;

  relied := TStringList.Create;
  queue := TStringList.Create;
  gameLower := LowerCase(gRobCoGameMasterFileName);
  if gameLower <> '' then
    RobCoReliedPluginSetAdd(relied, gameLower);
  RobCoReliedPluginsAppendDirectMasters(af, relied, queue);

  i := 0;
  while i < queue.Count do begin
    queueName := queue[i];
    nextFile := RobCoFileByPluginName(queueName);
    if Assigned(nextFile) then begin
      if gRobCoGameMasterFileName = '' then
        RobCoReliedPluginsAppendDirectMasters(nextFile, relied, queue)
      else if not SameText(GetFileName(nextFile), gRobCoGameMasterFileName) then
        RobCoReliedPluginsAppendDirectMasters(nextFile, relied, queue);
    end;
    i := i + 1;
  end;

  queue.Free;
  gRobCoReliedPluginsByFile.AddObject(cacheKey, relied);
  Result := relied;
end;

//============================================================================
procedure RobCoReliedPluginsCacheReset;
var
  i: integer;
begin
  if Assigned(gRobCoReliedPluginsByFile) then begin
    for i := 0 to Pred(gRobCoReliedPluginsByFile.Count) do begin
      if Assigned(gRobCoReliedPluginsByFile.Objects[i]) then
        TStringList(gRobCoReliedPluginsByFile.Objects[i]).Free;
    end;
    gRobCoReliedPluginsByFile.Clear;
  end;
  gRobCoGameMasterFileName := '';
  if FileCount > 0 then begin
    if Assigned(FileByIndex(0)) then
      gRobCoGameMasterFileName := GetFileName(FileByIndex(0));
  end;
end;

//============================================================================
function RobCoCompareBaselineRecord(e: IInterface): IInterface;
var
  ownerFile, walk: IInterface;
  relied: TStringList;
  ownerNameLower: string;
begin
  Result := nil;
  if not Assigned(e) then
    Exit;
  if not gRobCoCompareDeclaredMasters then begin
    Result := MasterOrSelf(e);
    Exit;
  end;
  if IsMaster(e) then begin
    Result := e;
    Exit;
  end;
  ownerFile := GetFile(e);
  if not Assigned(ownerFile) then begin
    Result := MasterOrSelf(e);
    Exit;
  end;
  relied := RobCoReliedPluginsForFile(ownerFile);
  walk := Master(e);
  while Assigned(walk) do begin
    ownerNameLower := LowerCase(GetFileName(GetFile(walk)));
    if RobCoReliedPluginSetHas(relied, ownerNameLower) then begin
      Result := walk;
      Exit;
    end;
    if IsMaster(walk) then begin
      Result := walk;
      Exit;
    end;
    walk := Master(walk);
  end;
  Result := walk;
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
  if forwardItms then begin
    Result := True;
    Exit;
  end;
  if overridesOnly then begin
    // Record-level ConflictAll is too coarse for LVLI-style subgraph edits and many
    // snapshot field diffs; Export* routines apply fine-grained ITM gates.
    Result := True;
    Exit;
  end;
  if RobCoRecordUnchangedVsMaster(e) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoItmGateExternalOverride(e: IInterface): boolean;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
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
function RobCoCommaListRefCount(const listText: string): integer;
begin
  Result := 0;
  if listText = '' then
    Exit;
  RobCoEnsureDiffScratch;
  RobCoParseCommaList(gRobCoDiffScratchPlugin, listText);
  Result := gRobCoDiffScratchPlugin.Count;
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
function RobCoRefListDiffUnchangedFromLists(slPlugin, slMaster: TStringList): boolean;
var
  i: integer;
  ref: string;
begin
  Result := True;
  if not Assigned(slPlugin) then
    Exit;
  if not Assigned(slMaster) then
    Exit;
  RobCoEnsureDiffScratch;
  gRobCoDiffScratchMaster.Clear;
  for i := 0 to Pred(slMaster.Count) do
    gRobCoDiffScratchMaster.Add(slMaster[i]);
  gRobCoDiffScratchMaster.Sorted := True;

  for i := 0 to Pred(slPlugin.Count) do begin
    ref := Trim(slPlugin[i]);
    if ref = '' then
      Continue;
    if gRobCoDiffScratchMaster.IndexOf(ref) < 0 then begin
      Result := False;
      Exit;
    end;
  end;

  gRobCoDiffScratchPlugin.Clear;
  for i := 0 to Pred(slPlugin.Count) do
    gRobCoDiffScratchPlugin.Add(slPlugin[i]);
  gRobCoDiffScratchPlugin.Sorted := True;
  for i := 0 to Pred(slMaster.Count) do begin
    ref := Trim(slMaster[i]);
    if ref = '' then
      Continue;
    if gRobCoDiffScratchPlugin.IndexOf(ref) < 0 then begin
      Result := False;
      Exit;
    end;
  end;
  gRobCoDiffScratchPlugin.Sorted := False;
  gRobCoDiffScratchMaster.Sorted := False;
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
  master := RobCoCompareBaselineRecord(e);
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
procedure RobCoBeginExport;
begin
  RobCoProgressReset;
  // DEBUG_INJECT_PERFMON_HOOK stat_reset_begin_export
  RobCoReliedPluginsCacheReset;
  RobCoPluginGroupCacheReset;
  if Assigned(slRobCoExportLog) then
    slRobCoExportLog.Free;
  slRobCoExportLog := nil;
  gRobCoExportRunId := IntToStr(RobCoNowMs);
  gRobCoPatcherRootDirBare := '';
  RobCoBuildPluginNameCache;
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
procedure RobCoPluginGroupCacheReset;
begin
  if Assigned(gRobCoPluginGroupCache) then begin
    gRobCoPluginGroupCache.Free;
    gRobCoPluginGroupCache := nil;
  end;
end;

//============================================================================
procedure RobCoPluginGroupCacheEnsure;
begin
  if not Assigned(gRobCoPluginGroupCache) then begin
    gRobCoPluginGroupCache := TStringList.Create;
    gRobCoPluginGroupCache.Sorted := True;
    gRobCoPluginGroupCache.Duplicates := dupIgnore;
  end;
end;

//============================================================================
function RobCoPluginGroupHasOverridesCachedGrp(f: IInterface; const sig: string;
  grp: IInterface): boolean;
var
  pluginName, cacheKey: string;
  idx: integer;
begin
  Result := False;
  if not Assigned(f) then
    Exit;
  if sig = '' then
    Exit;
  if not Assigned(grp) then
    Exit;
  RobCoPluginGroupCacheEnsure;
  pluginName := GetFileName(f);
  cacheKey := pluginName + #1 + sig;
  idx := gRobCoPluginGroupCache.IndexOf(cacheKey);
  if idx >= 0 then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.cache.plugin.group.hit 1
    Result := Integer(gRobCoPluginGroupCache.Objects[idx]) <> 0;
    Exit;
  end;
  // DEBUG_INJECT_PERFMON_COUNTER count.cache.plugin.group.miss 1
  Result := RobCoPluginGroupHasOverrides(grp);
  gRobCoPluginGroupCache.AddObject(cacheKey, TObject(Integer(Result)));
end;

//============================================================================
function RobCoPluginGroupHasOverridesCached(f: IInterface; const sig: string): boolean;
var
  grp: IInterface;
begin
  Result := False;
  if not Assigned(f) then
    Exit;
  if sig = '' then
    Exit;
  grp := GroupBySignature(f, sig);
  Result := RobCoPluginGroupHasOverridesCachedGrp(f, sig, grp);
end;

//============================================================================
procedure RobCoFlushExportLog;
var
  i: integer;
begin
  // DEBUG_INJECT_PERFMON_HOOK stat_summary_flush_export_log
  if Assigned(slRobCoExportLog) then begin
    for i := 0 to Pred(slRobCoExportLog.Count) do
      AddMessage(slRobCoExportLog[i]);
    slRobCoExportLog.Free;
    slRobCoExportLog := nil;
  end;

  // DEBUG_INJECT_PERFMON_HOOK manifest_write_flush_export_log
  RobCoIniWriterShutdown;
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

  pluginName := RobCoPluginNameForRecord(e);
  editorID := RobCoEditorID(e);

  RobCoIniWriterWriteRecordBlock(pluginName,
    RobCoRecordComment(editorID, pluginName, sig, e, shortComment), line);
  // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.emitted 1
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
procedure RobCoMultisetClear(sl: TStringList);
begin
  if not Assigned(sl) then
    Exit;
  sl.Clear;
  sl.Sorted := False;
end;

//============================================================================
function RobCoStringListItemAt(sl: TStringList; index: integer): string;
begin
  Result := '';
  if index < 0 then
    Exit;
  if not Assigned(sl) then
    Exit;
  if index >= sl.Count then
    Exit;
  Result := sl[index];
end;

//============================================================================
function RobCoStringListObjectIntAt(sl: TStringList; index: integer): integer;
begin
  Result := 0;
  if index < 0 then
    Exit;
  if not Assigned(sl) then
    Exit;
  if index >= sl.Count then
    Exit;
  Result := Integer(sl.Objects[index]);
end;

//============================================================================
function RobCoLoopLastIndex(count: integer): integer;
begin
  Result := -1;
  if count <= 0 then
    Exit;
  Result := Pred(count);
end;

//============================================================================
function RobCoMultisetFindIdxLinear(sl: TStringList; const key: string): integer;
var
  i, loopLast: integer;
begin
  Result := -1;
  if not Assigned(sl) then
    Exit;
  if key = '' then
    Exit;
  loopLast := RobCoLoopLastIndex(sl.Count);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    if CompareStr(RobCoStringListItemAt(sl, i), key) = 0 then begin
      Result := i;
      Exit;
    end;
  end;
end;

//============================================================================
function RobCoMultisetFindIdx(sl: TStringList; const key: string): integer;
begin
  Result := RobCoMultisetFindIdxLinear(sl, key);
end;

//============================================================================
procedure RobCoMultisetAddCount(sl: TStringList; const key: string; count: integer);
var
  idx, n: integer;
begin
  if key = '' then
    Exit;
  if count <= 0 then
    Exit;

  idx := RobCoMultisetFindIdxLinear(sl, key);
  if idx < 0 then
    sl.AddObject(key, TObject(count))
  else begin
    n := Integer(sl.Objects[idx]);
    sl.Objects[idx] := TObject(n + count);
  end;
end;

//============================================================================
procedure RobCoMultisetInc(sl: TStringList; const key: string);
begin
  RobCoMultisetAddCount(sl, key, 1);
end;

//============================================================================
procedure RobCoMultisetSort(sl: TStringList);
begin
  // Unsorted lists only: TStringList.Sorted breaks Object pairing in JvInterpreter;
  // sorting thousands of FLST keys here was O(n^2) and stalled exports.
end;

//============================================================================
procedure RobCoMultisetAssign(dst, src: TStringList);
var
  i, n: integer;
begin
  RobCoMultisetClear(dst);
  if not Assigned(src) then
    Exit;
  // Multiset keys are unique; copy directly instead of RobCoMultisetAddCount (O(n^2)).
  for i := 0 to Pred(src.Count) do begin
    n := Integer(src.Objects[i]);
    if n <= 0 then
      Continue;
    dst.AddObject(src[i], TObject(n));
  end;
end;

//============================================================================
function RobCoMultisetTryConsume(sl: TStringList; const key: string): boolean;
var
  idx, n: integer;
begin
  Result := False;
  if key = '' then
    Exit;

  idx := RobCoMultisetFindIdxLinear(sl, key);
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
  idx := RobCoMultisetFindIdxLinear(sl, key);
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
// ITM gate: diff operation field values vs master when Forward ITMs is off.
// Write all fields (verbose vs sparse lines) is separate: RobCoAppendField and
// RobCoAppendAuthoringBatchField pad =none for patch-author templates without
// changing ITM skip or which records are exported.
function RobCoSnapshotUseItmGate: boolean;
begin
  Result := gRobCoSnapItmGateActive;
end;

//============================================================================
function RobCoSnapshotOmitUnchangedFields: boolean;
begin
  Result := RobCoSnapshotUseItmGate;
end;

//============================================================================
function RobCoExportFieldIfChanged(e: IInterface; const pluginValue, masterValue: string): string;
begin
  Result := pluginValue;
  if not RobCoSnapshotUseItmGate then
    Exit;
  if Assigned(gRobCoSnapMaster) then begin
    if pluginValue = masterValue then
      Result := '';
    Exit;
  end;
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
  if not RobCoSnapshotUseItmGate then begin
    Result := pluginVal;
    Exit;
  end;
  if not RobCoRecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := RobCoCompareBaselineRecord(e);
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
  if not RobCoSnapshotUseItmGate then begin
    Result := pluginVal;
    Exit;
  end;
  if not RobCoRecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := RobCoCompareBaselineRecord(e);
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
  if not RobCoSnapshotUseItmGate then begin
    Result := pluginVal;
    Exit;
  end;
  if not RobCoRecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := RobCoCompareBaselineRecord(e);
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
  if not RobCoSnapshotUseItmGate then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  if pluginList = masterList then
    Result := '';
end;

//============================================================================
procedure RobCoApplyRefListDiffIfItmGate(e: IInterface; const pluginList, masterList: string;
  var refsToAdd, refsToRemove: string);
begin
  if not RobCoRecordHasExternalMaster(e) then begin
    refsToAdd := RobCoNoneIfEmpty(pluginList);
    refsToRemove := 'none';
    Exit;
  end;
  if RobCoSnapshotUseItmGate then
    RobCoDiffCommaSeparatedRefs(pluginList, masterList, refsToAdd, refsToRemove)
  else begin
    refsToAdd := RobCoNoneIfEmpty(pluginList);
    refsToRemove := 'none';
  end;
end;

//============================================================================
procedure RobCoApplyKeywordDiffIfItmGate(e: IInterface; const pluginKeywords: string;
  var keywordsToAdd, keywordsToRemove: string);
var
  master: IInterface;
  masterKeywords: string;
begin
  masterKeywords := '';
  if RobCoRecordHasExternalMaster(e) then begin
    master := RobCoCompareBaselineRecord(e);
    masterKeywords := RobCoReadKeywordRefsFromElement(master);
  end;
  RobCoApplyRefListDiffIfItmGate(e, pluginKeywords, masterKeywords,
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
function RobCoAppendAuthoringBatchField(const line, key, value: string): string;
begin
  // Batch-only article filters: omitted on sparse mirror lines (=none), included
  // when Write all fields is on so patch authors get a full template.
  if gRobCoExportWriteAllFields then
    Result := RobCoAppendPatchField(line, key, value)
  else
    Result := line;
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
function RobCoJoinTwoCommaLists(const leftList, rightList: string): string;
begin
  if leftList = '' then begin
    Result := rightList;
    Exit;
  end;
  if rightList = '' then begin
    Result := leftList;
    Exit;
  end;
  RobCoEnsureDiffScratch;
  gRobCoDiffScratchPlugin.Clear;
  RobCoParseCommaList(gRobCoDiffScratchPlugin, leftList);
  RobCoParseCommaList(gRobCoDiffScratchPlugin, rightList);
  Result := RobCoJoinParts(gRobCoDiffScratchPlugin);
end;

//============================================================================
// Clears per-record field cache while keeping master + session conflict-probe
// caches warm across records and snapshot ops.
procedure RobCoSnapRecordCacheClear;
begin
  if Assigned(gRobCoSnapRecordCacheKeys) then begin
    gRobCoSnapRecordCacheKeys.Free;
    gRobCoSnapRecordCacheKeys := nil;
  end;
  if Assigned(gRobCoSnapRecordCacheVals) then begin
    gRobCoSnapRecordCacheVals.Free;
    gRobCoSnapRecordCacheVals := nil;
  end;
end;

//============================================================================
procedure RobCoSnapConflictProbeCacheClear;
begin
  if Assigned(gRobCoSnapConflictProbeKeys) then begin
    gRobCoSnapConflictProbeKeys.Free;
    gRobCoSnapConflictProbeKeys := nil;
  end;
end;

//============================================================================
procedure RobCoSnapRecordAndProbeCacheClear;
begin
  RobCoSnapRecordCacheClear;
  RobCoSnapConflictProbeCacheClear;
end;

//============================================================================
// Diff/dedupe TStringList pools only — safe inside plugin loops while INI writer
// is active (must not free gRobCoIniDeferredAggregate or session caches).
procedure RobCoReleaseExportDiffScratch;
begin
  if Assigned(gRobCoKeywordPartsScratch) then begin
    gRobCoKeywordPartsScratch.Free;
    gRobCoKeywordPartsScratch := nil;
  end;
  if Assigned(gRobCoDiffScratchPlugin) then begin
    gRobCoDiffScratchPlugin.Free;
    gRobCoDiffScratchPlugin := nil;
  end;
  if Assigned(gRobCoDiffScratchMaster) then begin
    gRobCoDiffScratchMaster.Free;
    gRobCoDiffScratchMaster := nil;
  end;
  if Assigned(gRobCoDiffScratchAdd) then begin
    gRobCoDiffScratchAdd.Free;
    gRobCoDiffScratchAdd := nil;
  end;
  if Assigned(gRobCoDiffScratchRem) then begin
    gRobCoDiffScratchRem.Free;
    gRobCoDiffScratchRem := nil;
  end;
  if Assigned(gRobCoIniDedupeSeenScratch) then begin
    gRobCoIniDedupeSeenScratch.Free;
    gRobCoIniDedupeSeenScratch := nil;
  end;
  if Assigned(gRobCoIniDedupeOutputScratch) then begin
    gRobCoIniDedupeOutputScratch.Free;
    gRobCoIniDedupeOutputScratch := nil;
  end;
  if Assigned(gRobCoIniMergeScratch) then begin
    gRobCoIniMergeScratch.Free;
    gRobCoIniMergeScratch := nil;
  end;
end;

//============================================================================
procedure RobCoReleaseHeavyExportScratch;
begin
  RobCoReleaseExportDiffScratch;
  if Assigned(gRobCoPluginNameByLoadOrder) then begin
    gRobCoPluginNameByLoadOrder.Free;
    gRobCoPluginNameByLoadOrder := nil;
  end;
  RobCoPluginGroupCacheReset;
  RobCoSnapRecordAndProbeCacheClear;
end;

//============================================================================
procedure RobCoIniWriterEnsureLineBuffer;
begin
  if not Assigned(gRobCoIniLineBuffer) then
    gRobCoIniLineBuffer := TStringList.Create;
end;

//============================================================================
procedure RobCoIniWriterReleaseLineBuffer;
begin
  if Assigned(gRobCoIniLineBuffer) then begin
    gRobCoIniLineBuffer.Free;
    gRobCoIniLineBuffer := nil;
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
  i: integer;
  ref: string;
begin
  refsToAdd := 'none';
  refsToRemove := 'none';

  RobCoEnsureDiffScratch;
  RobCoParseCommaList(gRobCoDiffScratchPlugin, pluginRefs);
  RobCoParseCommaList(gRobCoDiffScratchMaster, masterRefs);
  gRobCoDiffScratchMaster.Sorted := True;

  for i := 0 to Pred(gRobCoDiffScratchPlugin.Count) do begin
    ref := Trim(gRobCoDiffScratchPlugin[i]);
    if ref = '' then
      Continue;
    if gRobCoDiffScratchMaster.IndexOf(ref) < 0 then
      gRobCoDiffScratchAdd.Add(ref);
  end;

  gRobCoDiffScratchPlugin.Sorted := True;
  for i := 0 to Pred(gRobCoDiffScratchMaster.Count) do begin
    ref := Trim(gRobCoDiffScratchMaster[i]);
    if ref = '' then
      Continue;
    if gRobCoDiffScratchPlugin.IndexOf(ref) < 0 then
      gRobCoDiffScratchRem.Add(ref);
  end;
  gRobCoDiffScratchPlugin.Sorted := False;
  gRobCoDiffScratchMaster.Sorted := False;

  gRobCoDiffScratchAdd.Sorted := True;
  gRobCoDiffScratchRem.Sorted := True;
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
// Empty APPR on an override inherits the master list (no attachParent* emission).
function RobCoEffectiveApprKeywordRefs(e: IInterface): string;
var
  appr: string;
  master: IInterface;
begin
  appr := RobCoReadApprKeywordRefs(e);
  if appr <> '' then begin
    Result := appr;
    Exit;
  end;
  if RobCoRecordHasExternalMaster(e) then begin
    master := RobCoCompareBaselineRecord(e);
    Result := RobCoReadApprKeywordRefs(master);
    Exit;
  end;
  Result := '';
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
  // RobCo Patcher articles require ~...~ for fullName on all record types including OMOD.
  Result := RobCoReadFullName(e);
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
function RobCoSnapCacheFormLinkRef(e: IInterface; const sigName: string): string;
var
  key: string;
begin
  key := RobCoSnapRecordCacheKey(e, 'flref:' + sigName);
  if RobCoSnapRecordCacheLookup(key, Result) then
    Exit;
  Result := RobCoReadFormLinkRef(e, sigName);
  RobCoSnapRecordCachePut(key, Result);
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
  frm.Caption := caption;
  clb := TCheckListBox(frm.FindComponent('CheckListBox1'));
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    clb.Items.AddObject(GetFileName(f), f);
    clb.Checked[clb.Items.Count - 1] := not RobCoIsVanillaOrCCPlugin(f);
  end;
  if frm.ShowModal <> mrOk then begin
    frm.Free;
    Exit;
  end;
  for i := 0 to Pred(clb.Items.Count) do
    if clb.Checked[i] then
      slSelected.AddObject(clb.Items[i], clb.Items.Objects[i]);
  Result := slSelected.Count > 0;
  frm.Free;
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
  dlgSave.Options := dlgSave.Options + [ofOverwritePrompt];
  dlgSave.Filter := 'INI files (*.ini)|*.ini';
  dlgSave.InitialDir := DataPath;
  dlgSave.FileName := defaultName;
  if dlgSave.Execute then
    Result := dlgSave.FileName;
  dlgSave.Free;
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
procedure RobCoIniWriterEnsureDeferredAggregate;
begin
  if not Assigned(gRobCoIniDeferredAggregate) then
    gRobCoIniDeferredAggregate := TStringList.Create;
end;

//============================================================================
procedure RobCoIniWriterClearDeferredAggregate;
begin
  if Assigned(gRobCoIniDeferredAggregate) then
    gRobCoIniDeferredAggregate.Clear;
end;

//============================================================================
procedure RobCoIniWriterAppendBufferToDeferred;
var
  i: integer;
begin
  if gRobCoIniLineBuffer.Count = 0 then
    Exit;
  if gRobCoIniActivePath = '' then
    Exit;
  RobCoIniWriterEnsureDeferredAggregate;
  gRobCoIniDeferredAggregate.Add(RobCoIniDeferredPathMarker + gRobCoIniActivePath);
  for i := 0 to Pred(gRobCoIniLineBuffer.Count) do
    gRobCoIniDeferredAggregate.Add(gRobCoIniLineBuffer[i]);
  gRobCoIniLineBuffer.Clear;
  RobCoIniWriterMaybeFlushDeferredAggregate;
end;

//============================================================================
procedure RobCoIniWriterMaybeFlushOnLineCount;
begin
  if RobCoIniFlushLineCount <= 0 then
    Exit;
  if gRobCoIniLineBuffer.Count < RobCoIniFlushLineCount then
    Exit;
  RobCoIniWriterFlushBuffer;
end;

//============================================================================
procedure RobCoIniWriterMaybeFlushDeferredAggregate;
begin
  if RobCoIniDeferAggregateFlushLineCount <= 0 then
    Exit;
  if not RobCoIniDeferDiskFlush then
    Exit;
  if not Assigned(gRobCoIniDeferredAggregate) then
    Exit;
  if gRobCoIniDeferredAggregate.Count < RobCoIniDeferAggregateFlushLineCount then
    Exit;
  RobCoIniWriterFlushDeferredAggregateToDisk;
end;

//============================================================================
procedure RobCoIniWriterSaveBufferToPath(const path: string; overwriteOnFlush: boolean);
var
  removed: integer;
  savedPath: string;
  savedOverwrite: boolean;
begin
  if gRobCoIniLineBuffer.Count = 0 then
    Exit;
  if path = '' then
    Exit;
  savedPath := gRobCoIniActivePath;
  savedOverwrite := gRobCoIniOverwriteOnFlush;
  gRobCoIniActivePath := path;
  gRobCoIniOverwriteOnFlush := overwriteOnFlush;
  if not gRobCoIniPerPlugin then begin
    removed := RobCoIniWriterDedupeCombinedBuffer;
    // DEBUG_INJECT_PERFMON_COUNTER count.ini.dedupe.removed removed
    if removed > 0 then
      RobCoLogSkippedDuplicate(Format('Skipped %d duplicate patch line(s) in %s',
        [removed, path]));
  end;
  // DEBUG_INJECT_PERFMON_COUNTER count.ini.flush 1
  if (not gRobCoIniOverwriteOnFlush) and FileExists(path) then begin
    if not Assigned(gRobCoIniMergeScratch) then
      gRobCoIniMergeScratch := TStringList.Create;
    gRobCoIniMergeScratch.Clear;
    gRobCoIniMergeScratch.LoadFromFile(path);
    gRobCoIniMergeScratch.AddStrings(gRobCoIniLineBuffer);
    gRobCoIniMergeScratch.SaveToFile(path);
  end else
    gRobCoIniLineBuffer.SaveToFile(path);
  gRobCoIniActivePath := savedPath;
  gRobCoIniOverwriteOnFlush := savedOverwrite;
  gRobCoIniLineBuffer.Clear;
end;

//============================================================================
procedure RobCoIniWriterFlushDeferredAggregateToDisk;
var
  i: integer;
  line, path, built: string;
begin
  if not Assigned(gRobCoIniDeferredAggregate) then
    Exit;
  if gRobCoIniDeferredAggregate.Count = 0 then
    Exit;
  RobCoIniWriterEnsureLineBuffer;
  path := '';
  gRobCoIniLineBuffer.Clear;
  for i := 0 to Pred(gRobCoIniDeferredAggregate.Count) do begin
    line := gRobCoIniDeferredAggregate[i];
    if Pos(RobCoIniDeferredPathMarker, line) = 1 then begin
      if path <> '' then
        RobCoIniWriterSaveBufferToPath(path, True);
      built := Copy(line, Length(RobCoIniDeferredPathMarker) + 1, MaxInt);
      path := built;
      gRobCoIniLineBuffer.Clear;
      Continue;
    end;
    gRobCoIniLineBuffer.Add(line);
  end;
  if path <> '' then
    RobCoIniWriterSaveBufferToPath(path, True);
  gRobCoIniDeferredAggregate.Clear;
end;

//============================================================================
procedure RobCoIniWriterFlushBuffer;
begin
  RobCoIniWriterEnsureLineBuffer;
  if gRobCoIniLineBuffer.Count = 0 then
    Exit;
  if gRobCoIniActivePath = '' then
    Exit;
  if RobCoIniDeferDiskFlush then begin
    RobCoIniWriterAppendBufferToDeferred;
    Exit;
  end;
  RobCoIniWriterSaveBufferToPath(gRobCoIniActivePath, gRobCoIniOverwriteOnFlush);
  gRobCoIniOverwriteOnFlush := False;
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
  RobCoIniWriterEnsureLineBuffer;
  gRobCoIniLineBuffer.Add(line);
  RobCoIniWriterMaybeFlushOnLineCount;
end;

//============================================================================
procedure RobCoIniWriterShutdown;
begin
  RobCoIniWriterCloseActiveFile;
  if RobCoIniDeferDiskFlush then
    RobCoIniWriterFlushDeferredAggregateToDisk;
  RobCoIniWriterClearDeferredAggregate;
  if Assigned(gRobCoIniDeferredAggregate) then begin
    gRobCoIniDeferredAggregate.Free;
    gRobCoIniDeferredAggregate := nil;
  end;
  gRobCoIniWriterActive := False;
  RobCoIniWriterReleaseLineBuffer;
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
  RobCoIniWriterEnsureLineBuffer;
  gRobCoIniLineBuffer.Clear;
end;

//============================================================================
procedure RobCoIniWriterResetPathCache;
begin
  gRobCoIniCachedPerPluginName := '';
  gRobCoIniCachedPerPluginPath := '';
  gRobCoIniCachedCombinedPath := '';
end;

//============================================================================
function RobCoIniWriterPerPluginPath(const pluginName: string): string;
begin
  if gRobCoIniCachedPerPluginName = pluginName then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.cache.ini.path.hit 1
    Result := gRobCoIniCachedPerPluginPath;
    Exit;
  end;
  // DEBUG_INJECT_PERFMON_COUNTER count.cache.ini.path.miss 1
  Result := gRobCoIniOutputDir + pluginName + '.ini';
  gRobCoIniCachedPerPluginName := pluginName;
  gRobCoIniCachedPerPluginPath := Result;
end;

//============================================================================
function RobCoIniWriterCombinedPath: string;
begin
  if gRobCoIniCachedCombinedPath <> '' then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.cache.ini.path.hit 1
    Result := gRobCoIniCachedCombinedPath;
    Exit;
  end;
  // DEBUG_INJECT_PERFMON_COUNTER count.cache.ini.path.miss 1
  Result := gRobCoIniOutputDir + gRobCoIniCombinedFileName;
  gRobCoIniCachedCombinedPath := Result;
end;

//============================================================================
procedure RobCoIniWriterBeginOp(const outputDir: string; perPlugin: boolean;
  const combinedFileName: string);
begin
  RobCoIniWriterCloseActiveFile;
  RobCoReleaseHeavyExportScratch;
  RobCoIniWriterEnsureLineBuffer;
  gRobCoIniOutputDir := outputDir;
  gRobCoIniPerPlugin := perPlugin;
  gRobCoIniCombinedFileName := combinedFileName;
  gRobCoIniCurrentPlugin := '';
  gRobCoIniFilesCreated := 0;
  gRobCoIniCombinedFileStarted := False;
  gRobCoIniNeedCombinedPluginHeader := False;
  RobCoIniWriterResetPathCache;
  RobCoPluginGroupCacheReset;
  if Assigned(gRobCoIniPluginsStarted) then
    gRobCoIniPluginsStarted.Clear;
  RobCoIniWriterClearDeferredAggregate;
end;

//============================================================================
procedure RobCoIniWriterEnsurePlugin(const pluginName: string);
var
  path: string;
  newFile: boolean;
begin
  if gRobCoIniPerPlugin then begin
    path := RobCoIniWriterPerPluginPath(pluginName);
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
    path := RobCoIniWriterCombinedPath;
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
  if RobCoIniDeferDiskFlush then
    RobCoIniWriterFlushDeferredAggregateToDisk;
  RobCoReleaseHeavyExportScratch;
  if Assigned(gRobCoIniLineBuffer) then
    gRobCoIniLineBuffer.Clear;
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
  if Assigned(gRobCoSnapMasterCacheKeys) then begin
    gRobCoSnapMasterCacheKeys.Free;
    gRobCoSnapMasterCacheKeys := nil;
  end;
  if Assigned(gRobCoSnapMasterCacheVals) then begin
    gRobCoSnapMasterCacheVals.Free;
    gRobCoSnapMasterCacheVals := nil;
  end;
  RobCoSnapRecordCacheClear;
end;

//============================================================================
procedure RobCoSnapEnsureRecordCache;
begin
  if not Assigned(gRobCoSnapRecordCacheKeys) then
    gRobCoSnapRecordCacheKeys := TStringList.Create;
  if not Assigned(gRobCoSnapRecordCacheVals) then
    gRobCoSnapRecordCacheVals := TStringList.Create;
end;

//============================================================================
function RobCoSnapRecordCacheKey(e: IInterface; const fieldTag: string): string;
begin
  // Override identity (FormIDRef), not filter/master identity — multiple plugins
  // overriding the same master must not share keywords/perks/spells cache rows.
  Result := FormIDRef(e) + '|' + fieldTag;
end;

//============================================================================
function RobCoSnapRecordCacheLookup(const key: string; var cached: string): boolean;
var
  idx: integer;
begin
  Result := False;
  cached := '';
  RobCoSnapEnsureRecordCache;
  idx := gRobCoSnapRecordCacheKeys.IndexOf(key);
  if idx < 0 then
    Exit;
  if idx >= gRobCoSnapRecordCacheVals.Count then
    Exit;
  cached := gRobCoSnapRecordCacheVals[idx];
  Result := True;
end;

//============================================================================
procedure RobCoSnapRecordCachePut(const key, val: string);
var
  idx: integer;
begin
  RobCoSnapEnsureRecordCache;
  idx := gRobCoSnapRecordCacheKeys.IndexOf(key);
  if idx >= 0 then
    gRobCoSnapRecordCacheVals[idx] := val
  else begin
    gRobCoSnapRecordCacheKeys.Add(key);
    gRobCoSnapRecordCacheVals.Add(val);
  end;
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
  Result := RobCoStringListItemAt(gRobCoSnapMasterCacheVals, idx);
end;

end.
