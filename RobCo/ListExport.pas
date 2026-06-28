unit ListExport;

const
  ListKindLVLI = 0;
  ListKindCONT = 1;
  ListKindFLST = 2;

  LVLF_CalcForLevel = $01;
  LVLF_CalcEachItem = $02;
  LVLF_UseAll = $04;

var
  gListScratchPluginMultiset: TStringList;
  gListScratchMasterMultiset: TStringList;
  gListScratchWinnerMultiset: TStringList;
  gListScratchFlstOld: TStringList;
  gListScratchFlstNew: TStringList;
  gListScratchPluginRem: TStringList;
  gListScratchPluginAdd: TStringList;
  gListScratchMasterAdd: TStringList;
  gListScratchMasterRem: TStringList;
  gListScratchMinimalKeys: TStringList;
  gListScratchEmitLines: TStringList;
  gListScratchMidChainFilter: TStringList;
  gListScratchEntryItemRef: TStringList;
  gListScratchEntryAddKey: TStringList;
  gListScratchEntryRemoveKey: TStringList;
  gListScratchMasterEntryAddKey: TStringList;
  gListScratchMasterEntryRemoveKey: TStringList;
  gListScratchMasterSideItemRef: TStringList;
  gListScratchMasterSideItemSeen: TStringList;
  gListScratchMasterSideAddKey: TStringList;
  gListScratchMasterSideRemoveKey: TStringList;
  gListEntryCacheCount: integer;
  gListMasterSideCacheCount: integer;
  gListMasterSideCacheKey: string;
  gListEntryCacheContainerKey: string;
  gListMasterEntryCacheCount: integer;
  gListMasterEntryCacheContainerKey: string;
  gListEntryCacheLocked: boolean;
  gListMasterEntryCacheLocked: boolean;

  gListCachedEntryRefPath: string;
  gListCachedEntryLevelPath: string;
  gListCachedEntryCountPath: string;
  gListCachedEntryChancePath: string;
  gListCachedContainerItemPath: string;
  gListCachedContainerCountPath: string;

  gListMinimalMultisetReady: boolean;
  gListMinimalMultisetHasRemove: boolean;
  gListMinimalMultisetHasAdd: boolean;
  gListMinimalDiffIsEmpty: boolean;
  gListScratchFlstPluginAddKeys: TStringList;
  gListScratchFlstMasterRem: TStringList;
  gListScratchFlstPluginRem: TStringList;
  gListScratchMinimalFlstRemoveEmitKeys: TStringList;
  gListScratchMinimalFlstAddEmitKeys: TStringList;
  gListScratchFlstMultisetMap: TStringList;

  gListGateRecordKey: string;
  gListGateListKind: integer;
  gListGatePluginContainer: IInterface;
  gListGateAddMasterContainer: IInterface;
  gListGateRemoveMasterContainer: IInterface;
  gListGateContainersReady: boolean;
  gListGateNeedsContainerDiff: boolean;
  gListGateFlagsValid: boolean;

//============================================================================
procedure ListEnsurePathCache;
begin
  if gListCachedEntryRefPath <> '' then
    Exit;
  gListCachedEntryRefPath := ListEntryRefPath;
  gListCachedEntryLevelPath := ListEntryLevelPath;
  gListCachedEntryCountPath := ListEntryCountPath;
  gListCachedEntryChancePath := ListEntryChancePath;
  gListCachedContainerItemPath := ListContainerItemPath;
  gListCachedContainerCountPath := ListContainerCountPath;
end;

//============================================================================
function ListEntryContainerKey(container: IInterface): string;
var
  owner: IInterface;
  containerName: string;
begin
  Result := '';
  if not Assigned(container) then
    Exit;
  owner := ContainingMainRecord(container);
  if not Assigned(owner) then
    Exit;
  containerName := Name(container);
  if containerName = '' then
    Exit;
  Result := PluginNameForRecord(owner) + '|' + PatchFilterFormIDRef(owner) + '|' +
    containerName;
end;

//============================================================================
procedure ListClearEntryCache;
begin
  gListEntryCacheCount := 0;
  gListEntryCacheContainerKey := '';
  gListEntryCacheLocked := False;
  if Assigned(gListScratchEntryItemRef) then
    gListScratchEntryItemRef.Clear;
  if Assigned(gListScratchEntryAddKey) then
    gListScratchEntryAddKey.Clear;
  if Assigned(gListScratchEntryRemoveKey) then
    gListScratchEntryRemoveKey.Clear;
end;

//============================================================================
procedure ListClearMasterEntryCache;
begin
  gListMasterEntryCacheCount := 0;
  gListMasterEntryCacheContainerKey := '';
  gListMasterEntryCacheLocked := False;
  if Assigned(gListScratchMasterEntryAddKey) then
    gListScratchMasterEntryAddKey.Clear;
  if Assigned(gListScratchMasterEntryRemoveKey) then
    gListScratchMasterEntryRemoveKey.Clear;
end;

//============================================================================
procedure ListBuildEntryCache(container: IInterface; listKind: integer);
var
  i, n, level, count, chance: integer;
  ent: IInterface;
  ref: IInterface;
  itemRef, addKey, removeKey: string;
begin
  ListClearEntryCache;
  if not Assigned(container) then
    Exit;
  ListEnsurePathCache;
  if not Assigned(gListScratchEntryItemRef) then
    gListScratchEntryItemRef := TStringList.Create;
  if not Assigned(gListScratchEntryAddKey) then
    gListScratchEntryAddKey := TStringList.Create;
  if not Assigned(gListScratchEntryRemoveKey) then
    gListScratchEntryRemoveKey := TStringList.Create;
  n := ElementCount(container);
  gListEntryCacheCount := n;
  gListEntryCacheContainerKey := ListEntryContainerKey(container);
  if n > 0 then begin
    for i := 0 to Pred(n) do begin
      ent := ElementByIndex(container, i);
    itemRef := '';
    addKey := '';
    removeKey := '';
    case listKind of
      ListKindLVLI: begin
        ref := LinksTo(ElementByPath(ent, gListCachedEntryRefPath));
        if Assigned(ref) then begin
          itemRef := MasterFormIDRef(ref);
          level := Round(GetElementNativeValues(ent, gListCachedEntryLevelPath));
          count := Round(GetElementNativeValues(ent, gListCachedEntryCountPath));
          chance := Round(GetElementNativeValues(ent, gListCachedEntryChancePath));
          if FormIDRef(ref) <> '' then
            addKey := FormIDRef(ref) + '~' + IntToStr(level) + '~' + IntToStr(count) + '~' +
              IntToStr(chance);
          if itemRef <> '' then
            removeKey := itemRef + '~' + IntToStr(level) + '~' + IntToStr(count);
        end;
      end;
      ListKindCONT: begin
        ref := LinksTo(ElementByPath(ent, gListCachedContainerItemPath));
        if Assigned(ref) then begin
          itemRef := MasterFormIDRef(ref);
          count := Round(GetElementNativeValues(ent, gListCachedContainerCountPath));
          if FormIDRef(ref) <> '' then
            addKey := FormIDRef(ref) + '~' + IntToStr(count);
          if itemRef <> '' then
            removeKey := itemRef;
        end;
      end;
      ListKindFLST: begin
        ref := LinksTo(ent);
        if Assigned(ref) then begin
          itemRef := MasterFormIDRef(ref);
          if FormIDRef(ref) <> '' then
            addKey := FormIDRef(ref);
          if itemRef <> '' then
            removeKey := itemRef;
        end;
      end;
    end;
    gListScratchEntryItemRef.Add(itemRef);
    gListScratchEntryAddKey.Add(addKey);
      gListScratchEntryRemoveKey.Add(removeKey);
    end;
  end;
  gListEntryCacheLocked := True;
end;

//============================================================================
procedure ListEnsureEntryCache(container: IInterface; listKind: integer);
begin
  if not Assigned(container) then
    Exit;
  if gListEntryCacheLocked then begin
    if gListEntryCacheCount > 0 then begin
      if gListEntryCacheCount = ElementCount(container) then begin
        if ListEntryContainerKey(container) = gListEntryCacheContainerKey then
          Exit;
      end;
    end;
  end else begin
    if gListEntryCacheCount > 0 then begin
      if ListEntryContainerKey(container) = gListEntryCacheContainerKey then
        Exit;
    end;
  end;
  ListBuildEntryCache(container, listKind);
end;

//============================================================================
procedure ListBuildMasterEntryCache(container: IInterface; listKind: integer);
var
  i, n, level, count, chance: integer;
  ent: IInterface;
  ref: IInterface;
  addKey, removeKey: string;
begin
  ListClearMasterEntryCache;
  if not Assigned(container) then
    Exit;
  ListEnsurePathCache;
  if not Assigned(gListScratchMasterEntryAddKey) then
    gListScratchMasterEntryAddKey := TStringList.Create;
  if not Assigned(gListScratchMasterEntryRemoveKey) then
    gListScratchMasterEntryRemoveKey := TStringList.Create;
  n := ElementCount(container);
  gListMasterEntryCacheCount := n;
  gListMasterEntryCacheContainerKey := ListEntryContainerKey(container);
  if n > 0 then begin
    for i := 0 to Pred(n) do begin
      ent := ElementByIndex(container, i);
      addKey := '';
      removeKey := '';
      case listKind of
        ListKindLVLI: begin
          ref := LinksTo(ElementByPath(ent, gListCachedEntryRefPath));
          if Assigned(ref) then begin
            level := Round(GetElementNativeValues(ent, gListCachedEntryLevelPath));
            count := Round(GetElementNativeValues(ent, gListCachedEntryCountPath));
            chance := Round(GetElementNativeValues(ent, gListCachedEntryChancePath));
            if FormIDRef(ref) <> '' then
              addKey := FormIDRef(ref) + '~' + IntToStr(level) + '~' + IntToStr(count) + '~' +
                IntToStr(chance);
            removeKey := ListEntryRemoveKey(ent, listKind);
          end;
        end;
        ListKindCONT: begin
          ref := LinksTo(ElementByPath(ent, gListCachedContainerItemPath));
          if Assigned(ref) then begin
            count := Round(GetElementNativeValues(ent, gListCachedContainerCountPath));
            if FormIDRef(ref) <> '' then
              addKey := FormIDRef(ref) + '~' + IntToStr(count);
            removeKey := ListEntryRemoveKey(ent, listKind);
          end;
        end;
        ListKindFLST: begin
          ref := LinksTo(ent);
          if Assigned(ref) then begin
            if FormIDRef(ref) <> '' then
              addKey := FormIDRef(ref);
            removeKey := ListEntryRemoveKey(ent, listKind);
          end;
        end;
      end;
      gListScratchMasterEntryAddKey.Add(addKey);
      gListScratchMasterEntryRemoveKey.Add(removeKey);
    end;
  end;
  gListMasterEntryCacheLocked := True;
end;

//============================================================================
procedure ListEnsureMasterEntryCache(container: IInterface; listKind: integer);
begin
  if not Assigned(container) then
    Exit;
  if gListMasterEntryCacheLocked then begin
    if gListMasterEntryCacheCount > 0 then begin
      if gListMasterEntryCacheCount = ElementCount(container) then begin
        if ListEntryContainerKey(container) = gListMasterEntryCacheContainerKey then
          Exit;
      end;
    end;
  end else begin
    if gListMasterEntryCacheCount > 0 then begin
      if ListEntryContainerKey(container) = gListMasterEntryCacheContainerKey then
        Exit;
    end;
  end;
  ListBuildMasterEntryCache(container, listKind);
end;

//============================================================================
function ListCachedItemRef(index: integer): string;
begin
  Result := StringListItemAt(gListScratchEntryItemRef, index);
end;

//============================================================================
function ListCachedAddKey(index: integer): string;
begin
  Result := StringListItemAt(gListScratchEntryAddKey, index);
end;

//============================================================================
function ListCachedRemoveKey(index: integer): string;
begin
  Result := StringListItemAt(gListScratchEntryRemoveKey, index);
end;

//============================================================================
function ListCachedMasterAddKey(index: integer): string;
begin
  Result := StringListItemAt(gListScratchMasterEntryAddKey, index);
end;

//============================================================================
function ListCachedMasterRemoveKey(index: integer): string;
begin
  Result := StringListItemAt(gListScratchMasterEntryRemoveKey, index);
end;

//============================================================================
procedure ListEnsureScratchEmitLines;
begin
  if not Assigned(gListScratchEmitLines) then
    gListScratchEmitLines := TStringList.Create;
  gListScratchEmitLines.Clear;
end;

//============================================================================
procedure ListEnsureScratchMidChainFilter;
begin
  if not Assigned(gListScratchMidChainFilter) then
    gListScratchMidChainFilter := TStringList.Create;
  gListScratchMidChainFilter.Clear;
end;

//============================================================================
procedure ListEnsureScratchMultisets;
begin
  if not Assigned(gListScratchPluginMultiset) then
    gListScratchPluginMultiset := TStringList.Create;
  if not Assigned(gListScratchMasterMultiset) then
    gListScratchMasterMultiset := TStringList.Create;
  if not Assigned(gListScratchWinnerMultiset) then
    gListScratchWinnerMultiset := TStringList.Create;
  MultisetClear(gListScratchPluginMultiset);
  MultisetClear(gListScratchMasterMultiset);
  MultisetClear(gListScratchWinnerMultiset);
end;

//============================================================================
procedure ListEnsureScratchFlstReplace;
begin
  if not Assigned(gListScratchFlstOld) then
    gListScratchFlstOld := TStringList.Create;
  if not Assigned(gListScratchFlstNew) then
    gListScratchFlstNew := TStringList.Create;
  gListScratchFlstOld.Clear;
  gListScratchFlstNew.Clear;
end;

//============================================================================
procedure ListResetMinimalDiffCache;
begin
  gListMinimalMultisetReady := False;
  gListMinimalMultisetHasRemove := False;
  gListMinimalMultisetHasAdd := False;
  gListMinimalDiffIsEmpty := True;
end;

//============================================================================
procedure ListClearGateContainerCache;
begin
  gListGateRecordKey := '';
  gListGateListKind := -1;
  gListGatePluginContainer := nil;
  gListGateAddMasterContainer := nil;
  gListGateRemoveMasterContainer := nil;
  gListGateContainersReady := False;
  gListGateNeedsContainerDiff := False;
  gListGateFlagsValid := False;
end;

//============================================================================
function ListBuildGateRecordKey(e: IInterface; listKind: integer): string;
begin
  Result := PluginNameForRecord(e) + #1 + PatchFilterFormIDRef(e) + #1 + IntToStr(listKind);
end;

//============================================================================
procedure ListRememberGateContainers(e: IInterface; listKind: integer;
  pluginContainer, addMasterContainer, removeMasterContainer: IInterface;
  needsContainerDiff: boolean);
begin
  gListGateRecordKey := ListBuildGateRecordKey(e, listKind);
  gListGateListKind := listKind;
  gListGatePluginContainer := pluginContainer;
  gListGateAddMasterContainer := addMasterContainer;
  gListGateRemoveMasterContainer := removeMasterContainer;
  gListGateNeedsContainerDiff := needsContainerDiff;
  gListGateFlagsValid := True;
  gListGateContainersReady := True;
end;

//============================================================================
function ListTryReuseGateContainers(e: IInterface; listKind: integer;
  var pluginContainer, addMasterContainer, removeMasterContainer: IInterface): boolean;
begin
  Result := False;
  if not gListGateContainersReady then
    Exit;
  if listKind <> gListGateListKind then
    Exit;
  if ListBuildGateRecordKey(e, listKind) <> gListGateRecordKey then
    Exit;
  pluginContainer := gListGatePluginContainer;
  addMasterContainer := gListGateAddMasterContainer;
  removeMasterContainer := gListGateRemoveMasterContainer;
  Result := True;
end;

//============================================================================
procedure ListEnsureFlstMultisetMap;
begin
  if not Assigned(gListScratchFlstMultisetMap) then begin
    gListScratchFlstMultisetMap := TStringList.Create;
    gListScratchFlstMultisetMap.Sorted := True;
    gListScratchFlstMultisetMap.Duplicates := dupIgnore;
  end;
end;

//============================================================================
procedure ListFlstMultisetMapClear;
begin
  ListEnsureFlstMultisetMap;
  gListScratchFlstMultisetMap.Clear;
end;

//============================================================================
procedure ListFlstMultisetMapInc(const key: string; counts: TStringList;
  addKeysOut, addKeySource: TStringList; addKeyIndex: integer);
var
  idx, slot, n: integer;
  addKey: string;
begin
  if key = '' then
    Exit;
  if not Assigned(counts) then
    Exit;
  ListEnsureFlstMultisetMap;
  idx := gListScratchFlstMultisetMap.IndexOf(key);
  if idx < 0 then begin
    counts.AddObject(key, TObject(1));
    gListScratchFlstMultisetMap.AddObject(key, TObject(counts.Count - 1));
    if Assigned(addKeysOut) then begin
      addKey := '';
      if Assigned(addKeySource) then begin
        if addKeyIndex < addKeySource.Count then
          addKey := addKeySource[addKeyIndex];
      end;
      addKeysOut.Add(addKey);
    end;
  end else begin
    if idx >= gListScratchFlstMultisetMap.Count then
      Exit;
    slot := Integer(gListScratchFlstMultisetMap.Objects[idx]);
    if slot < 0 then
      Exit;
    if slot >= counts.Count then
      Exit;
    n := Integer(counts.Objects[slot]);
    counts.Objects[slot] := TObject(n + 1);
  end;
end;

//============================================================================
function ListFlstMasterSideItemRefAt(index: integer): string;
begin
  Result := StringListItemAt(gListScratchMasterSideItemRef, index);
end;

//============================================================================
function ListFlstMasterSideRemoveKeyAt(index: integer): string;
begin
  Result := StringListItemAt(gListScratchMasterSideRemoveKey, index);
end;

//============================================================================
function ListFlstFirstItemRefMismatch(pluginLimit, masterLimit: integer): integer;
var
  i, shared: integer;
begin
  Result := -1;
  shared := pluginLimit;
  if masterLimit < shared then
    shared := masterLimit;
  if shared > 0 then begin
    for i := 0 to Pred(shared) do begin
      if ListFlstMasterSideItemRefAt(i) <> ListCachedItemRef(i) then begin
        Result := i;
        Exit;
      end;
    end;
  end;
  if pluginLimit <> masterLimit then
    Result := shared;
end;

//============================================================================
function ListFlstTrySuffixMinimalDiff(pluginLimit, masterLimit, startIdx: integer;
  doAdd, doRemove: boolean): boolean;
var
  i, j, pluginN, masterN, emitN, loopLast: integer;
  removeKey, addKey: string;
  hadDiff: boolean;
begin
  Result := False;
  if startIdx < 0 then
    Exit;
  if startIdx > 0 then begin
    if not ListFlstPrefixItemRefsIdentical(startIdx) then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.suffix.prefix_reject 1
      Exit;
    end;
  end;
  // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.suffix.attempt 1
  Result := True;
  hadDiff := False;
  if doRemove then begin
    if masterLimit > startIdx then begin
      if startIdx < pluginLimit then begin
        MultisetClear(gListScratchPluginRem);
        for j := startIdx to Pred(pluginLimit) do begin
          removeKey := ListCachedRemoveKey(j);
          if removeKey <> '' then
            MultisetInc(gListScratchPluginRem, removeKey);
        end;
      end;
      ListFlstMultisetMapClear;
      MultisetClear(gListScratchFlstMasterRem);
      for i := startIdx to Pred(masterLimit) do begin
        removeKey := ListFlstMasterSideRemoveKeyAt(i);
        if removeKey <> '' then
          ListFlstMultisetMapInc(removeKey, gListScratchFlstMasterRem, nil, nil, 0);
      end;
      gListMinimalMultisetHasRemove := True;
loopLast := LoopLastIndex(gListScratchFlstMasterRem.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
        removeKey := StringListItemAt(gListScratchFlstMasterRem, i);
        if removeKey = '' then
          Continue;
        masterN := StringListObjectIntAt(gListScratchFlstMasterRem, i);
        pluginN := 0;
        if startIdx < pluginLimit then
          pluginN := MultisetCount(gListScratchPluginRem, removeKey);
        if masterN > pluginN then begin
          emitN := masterN - pluginN;
          gListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey, TObject(emitN));
          hadDiff := True;
        end;
      end;
    end;
  end;
  if doAdd then begin
    if pluginLimit > startIdx then begin
      ListFlstMultisetMapClear;
      MultisetClear(gListScratchPluginAdd);
      gListScratchFlstPluginAddKeys.Clear;
      for i := startIdx to Pred(pluginLimit) do begin
        removeKey := ListCachedRemoveKey(i);
        if removeKey = '' then
          Continue;
        ListFlstMultisetMapInc(removeKey, gListScratchPluginAdd,
          gListScratchFlstPluginAddKeys, gListScratchEntryAddKey, i);
      end;
      gListMinimalMultisetHasAdd := True;
      if startIdx > 0 then begin
        ListFlstMultisetMapClear;
        MultisetClear(gListScratchMasterAdd);
        for i := 0 to Pred(startIdx) do begin
          removeKey := ListFlstMasterSideRemoveKeyAt(i);
          if removeKey <> '' then
            ListFlstMultisetMapInc(removeKey, gListScratchMasterAdd, nil, nil, 0);
        end;
      end;
      loopLast := LoopLastIndex(gListScratchPluginAdd.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
        removeKey := StringListItemAt(gListScratchPluginAdd, i);
        if removeKey = '' then
          Continue;
        pluginN := StringListObjectIntAt(gListScratchPluginAdd, i);
        if startIdx > 0 then
          masterN := MultisetCount(gListScratchMasterAdd, removeKey)
        else
          masterN := 0;
        if pluginN > masterN then begin
          addKey := ListFlstAddKeyAtMultisetIndex(i);
          if addKey <> '' then begin
            gListScratchMinimalFlstAddEmitKeys.AddObject(addKey,
              TObject(pluginN - masterN));
            hadDiff := True;
          end;
        end;
      end;
    end;
  end;
  if not hadDiff then begin
    if gListScratchMinimalFlstRemoveEmitKeys.Count = 0 then begin
      if gListScratchMinimalFlstAddEmitKeys.Count = 0 then begin
        Result := False;
        // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.suffix.fail 1
      end;
    end;
  end;
  if Result then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.suffix.ok 1
  end;
end;

//============================================================================
function ListFlstMinimalCacheHasEmitWork: boolean;
begin
  Result := False;
  if not gListMinimalMultisetReady then
    Exit;
  if gListMinimalMultisetHasRemove then begin
    if gListScratchMinimalFlstRemoveEmitKeys.Count > 0 then begin
      Result := True;
      Exit;
    end;
  end;
  if gListMinimalMultisetHasAdd then begin
    if gListScratchMinimalFlstAddEmitKeys.Count > 0 then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
procedure ListEnsureScratchMinimalDiff;
begin
  if not Assigned(gListScratchPluginRem) then
    gListScratchPluginRem := TStringList.Create;
  if not Assigned(gListScratchPluginAdd) then
    gListScratchPluginAdd := TStringList.Create;
  if not Assigned(gListScratchMasterAdd) then
    gListScratchMasterAdd := TStringList.Create;
  if not Assigned(gListScratchMasterRem) then
    gListScratchMasterRem := TStringList.Create;
  if not Assigned(gListScratchMinimalKeys) then
    gListScratchMinimalKeys := TStringList.Create;
  if not Assigned(gListScratchFlstPluginAddKeys) then
    gListScratchFlstPluginAddKeys := TStringList.Create;
  if not Assigned(gListScratchFlstMasterRem) then
    gListScratchFlstMasterRem := TStringList.Create;
  if not Assigned(gListScratchFlstPluginRem) then
    gListScratchFlstPluginRem := TStringList.Create;
  if not Assigned(gListScratchMinimalFlstRemoveEmitKeys) then
    gListScratchMinimalFlstRemoveEmitKeys := TStringList.Create;
  if not Assigned(gListScratchMinimalFlstAddEmitKeys) then
    gListScratchMinimalFlstAddEmitKeys := TStringList.Create;
  MultisetClear(gListScratchPluginRem);
  MultisetClear(gListScratchPluginAdd);
  MultisetClear(gListScratchMasterAdd);
  MultisetClear(gListScratchMasterRem);
  MultisetClear(gListScratchFlstMasterRem);
  MultisetClear(gListScratchFlstPluginRem);
  gListScratchFlstPluginAddKeys.Clear;
  gListScratchMinimalKeys.Clear;
  gListScratchMinimalFlstRemoveEmitKeys.Clear;
  gListScratchMinimalFlstAddEmitKeys.Clear;
  ListFlstMultisetMapClear;
end;

//============================================================================
function ListContainerName(listKind: integer): string;
begin
  case listKind of
    ListKindLVLI: Result := 'Leveled List Entries';
    ListKindCONT: Result := 'Items';
    ListKindFLST: Result := 'FormIDs';
  else
    Result := '';
  end;
end;

//============================================================================
function ListRecordSig(listKind: integer): string;
begin
  case listKind of
    ListKindLVLI: Result := 'LVLI';
    ListKindCONT: Result := 'CONT';
    ListKindFLST: Result := 'FLST';
  else
    Result := '';
  end;
end;

//============================================================================
function ListFilterConstant(listKind: integer): string;
begin
  case listKind of
    ListKindLVLI: Result := FilterLLs;
    ListKindCONT: Result := FilterCONT;
    ListKindFLST: Result := FilterFormLists;
  else
    Result := '';
  end;
end;

//============================================================================
function ListFilterPrefix(e: IInterface; listKind: integer): string;
var
  editorID: string;
begin
  Result := ListFilterConstant(listKind) + PatchFilterFormIDRef(e);
  if SkyrimGame then begin
    if listKind <> ListKindFLST then begin
      editorID := RecordEditorId(e);
      if editorID <> '' then
        Result := Result + ':filterByEditorIdContains=' + editorID;
    end;
  end;
end;

//============================================================================
function ListLinesHaveData(lines: TStringList; listKind: integer): boolean;
begin
  Result := StringListHasFilter(lines, ListFilterConstant(listKind));
end;

//============================================================================
function ListLinesHaveAddOps(lines: TStringList; listKind: integer): boolean;
var
  i, loopLast: integer;
  line: string;
begin
  Result := False;
  if not Assigned(lines) then
    Exit;
  loopLast := LoopLastIndex(lines.Count);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    line := StringListItemAt(lines, i);
    case listKind of
      ListKindLVLI:
        if Pos(':addToLLs=', line) > 0 then begin
          Result := True;
          Exit;
        end;
      ListKindCONT:
        if Pos(':addToContainers=', line) > 0 then begin
          Result := True;
          Exit;
        end;
      ListKindFLST:
        if Pos(':formsToAdd=', line) > 0 then begin
          Result := True;
          Exit;
        end;
    end;
  end;
end;

//============================================================================
function ListEntryRefPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Reference'
  else
    Result := 'LVLO\Reference';
end;

//============================================================================
function ListEntryLevelPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Level'
  else
    Result := 'LVLO\Level';
end;

//============================================================================
function ListEntryCountPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Count'
  else
    Result := 'LVLO\Count';
end;

//============================================================================
function ListEntryChancePath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Chance None'
  else
    Result := 'LVLO\Chance None';
end;

//============================================================================
function ListContainerItemPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Item'
  else
    Result := 'CNTO\Item';
end;

//============================================================================
function ListContainerCountPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Count'
  else
    Result := 'CNTO\Count';
end;

//============================================================================
function ListAddOpcode(listKind: integer): string;
begin
  case listKind of
    ListKindLVLI: Result := 'addToLLs';
    ListKindCONT: Result := 'addToContainers';
    ListKindFLST: Result := 'formsToAdd';
  else
    Result := '';
  end;
end;

//============================================================================
function ListRemoveOpcode(listKind: integer): string;
begin
  case listKind of
    ListKindLVLI: Result := 'removeFromLLs';
    ListKindCONT: Result := 'removeFromContainers';
    ListKindFLST: Result := 'formsToRemove';
  else
    Result := '';
  end;
end;

//============================================================================
function ListEntryLinkedRef(ent: IInterface; listKind: integer): IInterface;
begin
  Result := nil;
  ListEnsurePathCache;
  case listKind of
    ListKindLVLI:
      Result := LinksTo(ElementByPath(ent, gListCachedEntryRefPath));
    ListKindCONT:
      Result := LinksTo(ElementByPath(ent, gListCachedContainerItemPath));
    ListKindFLST:
      Result := LinksTo(ent);
  end;
end;

//============================================================================
// Master plugin|id for remove keys and index-aligned FLST replace (vanilla identity).
function ListEntryItemRef(ent: IInterface; listKind: integer): string;
begin
  Result := MasterFormIDRef(ListEntryLinkedRef(ent, listKind));
end;

//============================================================================
// Owning plugin|id for add keys (golden uses plugin-local ids, e.g. communitytweaksmerged.esp|13C0F1).
function ListEntryAddItemRef(ent: IInterface; listKind: integer): string;
begin
  Result := FormIDRef(ListEntryLinkedRef(ent, listKind));
end;

//============================================================================
function ListEntryRemoveKey(ent: IInterface; listKind: integer): string;
var
  itemRef: string;
  level, count: integer;
begin
  Result := '';
  itemRef := ListEntryItemRef(ent, listKind);
  if itemRef = '' then
    Exit;

  ListEnsurePathCache;
  case listKind of
    ListKindLVLI: begin
      level := Round(GetElementNativeValues(ent, gListCachedEntryLevelPath));
      count := Round(GetElementNativeValues(ent, gListCachedEntryCountPath));
      Result := itemRef + '~' + IntToStr(level) + '~' + IntToStr(count);
    end;
    ListKindCONT, ListKindFLST:
      Result := itemRef;
  end;
end;

//============================================================================
function ListEntryAddKey(ent: IInterface; listKind: integer): string;
var
  itemRef: string;
  level, count, chance: integer;
begin
  Result := '';
  itemRef := ListEntryAddItemRef(ent, listKind);
  if itemRef = '' then
    Exit;

  ListEnsurePathCache;
  case listKind of
    ListKindLVLI: begin
      level := Round(GetElementNativeValues(ent, gListCachedEntryLevelPath));
      count := Round(GetElementNativeValues(ent, gListCachedEntryCountPath));
      chance := Round(GetElementNativeValues(ent, gListCachedEntryChancePath));
      Result := itemRef + '~' + IntToStr(level) + '~' + IntToStr(count) + '~' + IntToStr(chance);
    end;
    ListKindCONT: begin
      count := Round(GetElementNativeValues(ent, gListCachedContainerCountPath));
      Result := itemRef + '~' + IntToStr(count);
    end;
    ListKindFLST:
      Result := itemRef;
  end;
end;

//============================================================================
function ListAddLineValue(ent: IInterface; listKind: integer): string;
begin
  Result := ListEntryAddKey(ent, listKind);
end;

//============================================================================
procedure ListBuildMultiset(container: IInterface; sl: TStringList; listKind: integer; forAdd: boolean);
var
  i, n: integer;
  ent: IInterface;
  key: string;
begin
  if not Assigned(container) then
    Exit;

  ListFlstMultisetMapClear;
  MultisetClear(sl);
  n := ElementCount(container);
  if n <= 0 then
    Exit;
  if (n = gListEntryCacheCount) and
    (ListEntryContainerKey(container) = gListEntryCacheContainerKey) then begin
    for i := 0 to Pred(n) do begin
      if forAdd then
        key := ListCachedAddKey(i)
      else
        key := ListCachedRemoveKey(i);
      if key <> '' then
        ListFlstMultisetMapInc(key, sl, nil, nil, 0);
    end;
  end else if (n = gListMasterEntryCacheCount) and
    (ListEntryContainerKey(container) = gListMasterEntryCacheContainerKey) then begin
    for i := 0 to Pred(n) do begin
      if forAdd then
        key := ListCachedMasterAddKey(i)
      else
        key := ListCachedMasterRemoveKey(i);
      if key <> '' then
        ListFlstMultisetMapInc(key, sl, nil, nil, 0);
    end;
  end else begin
    for i := 0 to Pred(n) do begin
      ent := ElementByIndex(container, i);
      if forAdd then
        key := ListEntryAddKey(ent, listKind)
      else
        key := ListEntryRemoveKey(ent, listKind);
      if key <> '' then
        ListFlstMultisetMapInc(key, sl, nil, nil, 0);
    end;
  end;
  MultisetSort(sl);
end;

//============================================================================
function ListGetLVLFFlags(lvli: IInterface): integer;
begin
  if ElementExists(lvli, 'LVLF') then
    Result := GetElementNativeValues(lvli, 'LVLF')
  else if ElementExists(lvli, 'Flags') then
    Result := GetElementNativeValues(lvli, 'Flags')
  else
    Result := 0;
end;

//============================================================================
function ListGetLLCT(lvli: IInterface): integer;
begin
  if ElementExists(lvli, 'LLCT') then
    Result := GetElementNativeValues(lvli, 'LLCT')
  else
    Result := 0;
end;

//============================================================================
procedure ListResolveExportMaster(e: IInterface; var master: IInterface);
begin
  if not Assigned(master) then
    master := CompareBaselineRecord(e);
end;

//============================================================================
function ListLvlifFlagsUnchanged(e, master: IInterface): boolean;
begin
  Result := True;
  if wbGameMode = gmTES4 then
    Exit;
  if not Assigned(master) then
    Exit;
  if ListGetLVLFFlags(e) <> ListGetLVLFFlags(master) then begin
    Result := False;
    Exit;
  end;
  if ListGetLLCT(e) <> ListGetLLCT(master) then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
function ListLvlifFlagsRestorable(e, parent, winner: IInterface): boolean;
begin
  Result := False;
  if wbGameMode = gmTES4 then
    Exit;
  if not Assigned(e) then
    Exit;
  if not Assigned(parent) then
    Exit;
  if not Assigned(winner) then
    Exit;
  if ListLvlifFlagsUnchanged(e, parent) then
    Exit;
  if ListGetLVLFFlags(winner) <> ListGetLVLFFlags(parent) then
    Exit;
  if ListGetLLCT(winner) <> ListGetLLCT(parent) then
    Exit;
  Result := True;
end;

//============================================================================
function ListLvlifFlagsExportable(e, master: IInterface): boolean;
var
  winner: IInterface;
begin
  Result := False;
  if wbGameMode = gmTES4 then
    Exit;
  if not Assigned(master) then
    Exit;
  if gRestorationMode then begin
    MidChainPrepareRecord(e);
    winner := gMidChainWinner;
    if not Assigned(winner) then
      Exit;
    Result := ListLvlifFlagsRestorable(e, master, winner);
    Exit;
  end;
  if not ListLvlifFlagsUnchanged(e, master) then
    Result := True;
end;

//============================================================================
procedure ListEnsureLvliFlagsExportableCached(e: IInterface; var master: IInterface;
  var flagsKnown, flagsExportable: boolean);
begin
  if flagsKnown then
    Exit;
  ListResolveExportMaster(e, master);
  flagsExportable := ListLvlifFlagsExportable(e, master);
  flagsKnown := True;
end;

//============================================================================
function ListIdentityKeyForListValue(listKind: integer; const value: string): string;
var
  tildePos: integer;
begin
  Result := value;
  if value = '' then
    Exit;
  if listKind = ListKindLVLI then begin
    tildePos := Pos('~', value);
    if tildePos > 0 then
      Result := Copy(value, 1, tildePos - 1);
  end;
end;

//============================================================================
function ListItemCountOnRecord(rec: IInterface; listKind: integer;
  useIdentityKeys: boolean; const itemRef: string): integer;
var
  containerName: string;
  container: IInterface;
  limit: integer;
begin
  Result := 0;
  if not Assigned(rec) then
    Exit;
  if itemRef = '' then
    Exit;
  containerName := ListContainerName(listKind);
  if containerName = '' then
    Exit;
  if not ElementExists(rec, containerName) then
    Exit;
  container := ElementByName(rec, containerName);
  ListEnsureScratchMultisets;
  if listKind = ListKindFLST then begin
    ListEnsureFlstSideCache(container);
    limit := gListMasterSideCacheCount;
    ListBuildFlstMasterMultiset(limit, gListScratchWinnerMultiset);
    Result := MultisetCount(gListScratchWinnerMultiset, itemRef);
    Exit;
  end;
  ListEnsureMasterEntryCache(container, listKind);
  if useIdentityKeys then
    ListBuildMultiset(container, gListScratchWinnerMultiset, listKind, False)
  else
    ListBuildMultiset(container, gListScratchWinnerMultiset, listKind, True);
  Result := MultisetCount(gListScratchWinnerMultiset, itemRef);
end;

//============================================================================
function ListRestorationSkipAdd(e: IInterface; listKind: integer;
  useIdentityKeys: boolean; const addValue: string): boolean;
var
  itemRef: string;
  winnerCount: integer;
begin
  Result := False;
  if not gRestorationMode then
    Exit;
  itemRef := ListIdentityKeyForListValue(listKind, addValue);
  if itemRef = '' then
    Exit;
  MidChainPrepareRecord(e);
  if not Assigned(gMidChainWinner) then
    Exit;
  winnerCount := ListItemCountOnRecord(gMidChainWinner, listKind, useIdentityKeys,
    itemRef);
  if winnerCount > 0 then
    Result := True;
end;

//============================================================================
function ListRestorationCappedRemoveEmitN(e: IInterface; listKind: integer;
  useIdentityKeys: boolean; const removeKey: string; masterN, pluginN: integer): integer;
var
  itemRef: string;
  winnerN: integer;
begin
  Result := masterN - pluginN;
  if Result <= 0 then begin
    Result := 0;
    Exit;
  end;
  if not gRestorationMode then
    Exit;
  itemRef := ListIdentityKeyForListValue(listKind, removeKey);
  MidChainPrepareRecord(e);
  if not Assigned(gMidChainWinner) then
    Exit;
  winnerN := ListItemCountOnRecord(gMidChainWinner, listKind, useIdentityKeys, itemRef);
  if winnerN <= pluginN then begin
    Result := 0;
    Exit;
  end;
  if Result > winnerN - pluginN then
    Result := winnerN - pluginN;
end;

//============================================================================
procedure ListPrepareWinnerMultiset(e: IInterface; listKind: integer;
  useIdentityKeys: boolean; var hasWinnerMultiset: boolean);
var
  containerName: string;
  winnerContainer: IInterface;
begin
  hasWinnerMultiset := False;
  if not gRestorationMode then
    Exit;
  if not Assigned(e) then
    Exit;
  MidChainPrepareRecord(e);
  if not Assigned(gMidChainWinner) then
    Exit;
  containerName := ListContainerName(listKind);
  if containerName = '' then
    Exit;
  if not ElementExists(gMidChainWinner, containerName) then
    Exit;
  winnerContainer := ElementByName(gMidChainWinner, containerName);
  ListEnsureScratchMultisets;
  if listKind = ListKindFLST then begin
    ListEnsureFlstSideCache(winnerContainer);
    ListBuildFlstMasterMultiset(gListMasterSideCacheCount,
      gListScratchWinnerMultiset);
    hasWinnerMultiset := True;
    Exit;
  end;
  ListEnsureMasterEntryCache(winnerContainer, listKind);
  if useIdentityKeys then
    ListBuildMultiset(winnerContainer, gListScratchWinnerMultiset, listKind, False)
  else
    ListBuildMultiset(winnerContainer, gListScratchWinnerMultiset, listKind, True);
  hasWinnerMultiset := True;
end;

//============================================================================
function ListMidChainIsListAddOp(const key: string): boolean;
begin
  Result := False;
  if key = 'addToLLs' then
    Result := True;
  if key = 'addToContainers' then
    Result := True;
  if key = 'formsToAdd' then
    Result := True;
end;

//============================================================================
function ListMidChainIsListRemoveOp(const key: string): boolean;
begin
  Result := False;
  if key = 'removeFromLLs' then
    Result := True;
  if key = 'removeFromContainers' then
    Result := True;
  if key = 'formsToRemove' then
    Result := True;
end;

//============================================================================
function ListMidChainIsLvlifCalcOp(const key: string): boolean;
begin
  Result := False;
  if key = 'calcForLevel' then
    Result := True;
  if key = 'calcEachItem' then
    Result := True;
  if key = 'calcForLevelAndEachItem' then
    Result := True;
  if key = 'calcUseAll' then
    Result := True;
end;

//============================================================================
function ListMidChainFilterExportLine(e: IInterface; listKind: integer;
  const line: string): string;
var
  rest, segment, key, value, parentVal, winnerVal: string;
  colonPos, eqPos: integer;
  parent, master: IInterface;
  kept: TStringList;
  i, loopLast, masterN, pluginN, emitN: integer;
  useIdentityKeys: boolean;
  built, itemRef: string;
begin
  Result := line;
  if not gRestorationMode then
    Exit;
  if line = '' then
    Exit;
  MidChainPrepareRecord(e);
  parent := gMidChainParent;
  useIdentityKeys := False;
  if listKind = ListKindLVLI then
    useIdentityKeys := True;
  if listKind = ListKindCONT then
    useIdentityKeys := True;
  master := CompareBaselineRecord(e);
  kept := TStringList.Create;
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
    if eqPos <= 0 then begin
      kept.Add(segment);
      Continue;
    end;
    key := Copy(segment, 1, eqPos - 1);
    value := Copy(segment, eqPos + 1, MaxInt);
    if Pos('filterBy', key) = 1 then begin
      kept.Add(segment);
      Continue;
    end;
    if ListMidChainIsListAddOp(key) then begin
      if not ListRestorationSkipAdd(e, listKind, useIdentityKeys, value) then
        kept.Add(segment);
      Continue;
    end;
    if ListMidChainIsListRemoveOp(key) then begin
      itemRef := ListIdentityKeyForListValue(listKind, value);
      pluginN := ListItemCountOnRecord(e, listKind, useIdentityKeys, itemRef);
      masterN := ListItemCountOnRecord(parent, listKind, useIdentityKeys, itemRef);
      emitN := ListRestorationCappedRemoveEmitN(e, listKind, useIdentityKeys, value,
        masterN, pluginN);
      if emitN > 0 then
        kept.Add(segment);
      Continue;
    end;
    if ListMidChainIsLvlifCalcOp(key) then begin
      if ListLvlifFlagsExportable(e, master) then
        kept.Add(segment);
      Continue;
    end;
    if Pos('ToAdd', key) > 0 then begin
      winnerVal := MidChainReadListForOp(gMidChainWinner, key);
      MidChainFilterAddsNotInWinner(value, winnerVal);
      if value <> '' then
        kept.Add(key + '=' + value);
      Continue;
    end;
    if MidChainOpIsListRemove(key) then begin
      kept.Add(segment);
      Continue;
    end;
    if MidChainOpIsMapMerge(key) then begin
      kept.Add(segment);
      Continue;
    end;
    if MidChainTryReadScalarForOp(parent, key, parentVal) then begin
      if MidChainTryReadScalarForOp(gMidChainWinner, key, winnerVal) then begin
        if MidChainScalarRestorable(value, parentVal, winnerVal) then
          kept.Add(segment);
      end;
      Continue;
    end;
  end;
  built := '';
  loopLast := LoopLastIndex(kept.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    segment := StringListItemAt(kept, i);
    if built <> '' then
      built := built + ':';
    built := built + segment;
  end;
  Result := built;
  kept.Free;
end;

//============================================================================
procedure ListMidChainFilterEmitLines(e: IInterface; listKind: integer;
  lines: TStringList);
var
  i, loopLast: integer;
  line: string;
begin
  if not gRestorationMode then
    Exit;
  if not Assigned(lines) then
    Exit;
  if lines.Count = 0 then
    Exit;
  ListEnsureScratchMidChainFilter;
  loopLast := LoopLastIndex(lines.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    line := ListMidChainFilterExportLine(e, listKind, StringListItemAt(lines, i));
    if SnapshotLineHasOperations(line) then
      gListScratchMidChainFilter.Add(line);
  end;
  lines.Clear;
  if gListScratchMidChainFilter.Count > 0 then
    lines.AddStrings(gListScratchMidChainFilter);
end;

//============================================================================
procedure ListAppendLVLIFlags(lines: TStringList; const filterPrefix: string; lvli: IInterface);
var
  flags, llct: integer;
  flagLine: string;
begin
  if wbGameMode = gmTES4 then
    Exit;

  flags := ListGetLVLFFlags(lvli);
  if flags = 0 then
    Exit;

  flagLine := filterPrefix;

  if flags and LVLF_CalcForLevel <> 0 then begin
    if flags and LVLF_CalcEachItem <> 0 then
      flagLine := flagLine + ':calcForLevelAndEachItem=yes'
    else
      flagLine := flagLine + ':calcForLevel=yes';
  end else if flags and LVLF_CalcEachItem <> 0 then
    flagLine := flagLine + ':calcEachItem=yes';

  if flags and LVLF_UseAll <> 0 then begin
    llct := ListGetLLCT(lvli);
    flagLine := flagLine + ':calcUseAll=' + IntToStr(llct);
  end;

  if flagLine <> filterPrefix then
    lines.Add(flagLine);
end;

//============================================================================
function ListFindEntForAddKey(container: IInterface; listKind: integer; const addKey: string): IInterface;
var
  i, loopLast: integer;
  ent: IInterface;
begin
  Result := nil;
  if not Assigned(container) then
    Exit;
  if addKey = '' then
    Exit;

  loopLast := LoopLastIndex(ElementCount(container));
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    ent := ElementByIndex(container, i);
    if ListEntryAddKey(ent, listKind) = addKey then begin
      Result := ent;
      Exit;
    end;
  end;
end;

//============================================================================
function ListFirstAddKeyForRemoveKey(container: IInterface; listKind: integer;
  const removeKey: string): string;
var
  i, n, loopLast: integer;
  ent: IInterface;
begin
  Result := '';
  if removeKey = '' then
    Exit;
  if not Assigned(container) then
    Exit;
  if gListEntryCacheLocked then begin
    if gListEntryCacheCount > 0 then begin
      if ListEntryContainerKey(container) = gListEntryCacheContainerKey then begin
        for i := 0 to Pred(gListEntryCacheCount) do begin
          if ListCachedRemoveKey(i) = removeKey then begin
            Result := ListCachedAddKey(i);
            if Result <> '' then
              Exit;
          end;
        end;
        Exit;
      end;
    end;
  end;
  n := gListEntryCacheCount;
  if (n > 0) then begin
    if ListEntryContainerKey(container) = gListEntryCacheContainerKey then begin
      for i := 0 to Pred(n) do begin
        if ListCachedRemoveKey(i) = removeKey then begin
          Result := ListCachedAddKey(i);
          if Result <> '' then
            Exit;
        end;
      end;
    end;
  end;
  loopLast := LoopLastIndex(ElementCount(container));
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    ent := ElementByIndex(container, i);
    if ListEntryRemoveKey(ent, listKind) = removeKey then begin
      Result := ListEntryAddKey(ent, listKind);
      if Result <> '' then
        Exit;
    end;
  end;
end;

//============================================================================
function ListUseNetGate(forwardItms, overridesOnly: boolean): boolean;
begin
  Result := False;
  if forwardItms then
    Exit;
  if not overridesOnly then
    Exit;
  Result := True;
end;

//============================================================================
function ListNetCompareRecordForAdd(e: IInterface; forwardItms, overridesOnly: boolean): IInterface;
begin
  // Net-gate adds diff vs compare baseline (load order or declared masters).
  // Prior-override baseline over-suppressed rows reintroduced by later plugins (e.g.
  // communitytweaksmerged on Fallout4.esm|28667 after UFO4P) and inflated FLST tails
  // (e.g. DLCworkshop02.esm|C1D vs hundreds of UFO4P-local formsToAdd).
  Result := CompareBaselineRecord(e);
end;

//============================================================================
function ListNetCompareRecordForRemove(e: IInterface; forwardItms, overridesOnly: boolean): IInterface;
begin
  Result := CompareBaselineRecord(e);
end;

//============================================================================
function ListNetCompareContainerFromRecord(compareRec: IInterface; listKind: integer): IInterface;
var
  containerName: string;
begin
  Result := nil;
  if not Assigned(compareRec) then
    Exit;
  containerName := ListContainerName(listKind);
  if containerName = '' then
    Exit;
  if ElementExists(compareRec, containerName) then
    Result := ElementByName(compareRec, containerName);
end;

//============================================================================
function ListNetCompareAddContainer(e: IInterface; listKind: integer;
  forwardItms, overridesOnly: boolean): IInterface;
begin
  Result := ListNetCompareContainerFromRecord(
    ListNetCompareRecordForAdd(e, forwardItms, overridesOnly), listKind);
end;

//============================================================================
function ListNetCompareRemoveContainer(e: IInterface; listKind: integer;
  forwardItms, overridesOnly: boolean): IInterface;
begin
  Result := ListNetCompareContainerFromRecord(
    ListNetCompareRecordForRemove(e, forwardItms, overridesOnly), listKind);
end;

//============================================================================
function ListContainerIndexIdentical(pluginContainer, masterContainer: IInterface;
  listKind: integer): boolean;
var
  i, j, pluginCount: integer;
  entP, entM: IInterface;
begin
  Result := False;
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(masterContainer) then
    Exit;
  pluginCount := ElementCount(pluginContainer);
  if pluginCount <> ElementCount(masterContainer) then
    Exit;
  if pluginCount <= 0 then begin
    Result := True;
    Exit;
  end;
  ListEnsurePathCache;

  if (pluginCount > 0) and (pluginCount = gListEntryCacheCount) then begin
    if ListEntryContainerKey(pluginContainer) = gListEntryCacheContainerKey then begin
      if listKind = ListKindFLST then begin
        ListEnsureFlstSideCache(masterContainer);
        if pluginCount <> gListMasterSideCacheCount then
          Exit;
        Result := ListFlstPrefixItemRefsIdentical(pluginCount);
        Exit;
      end;
      for j := 0 to Pred(pluginCount) do begin
        entM := ElementByIndex(masterContainer, j);
        if ListCachedAddKey(j) <> ListEntryAddKey(entM, listKind) then
          Exit;
      end;
      Result := True;
      Exit;
    end;
  end;

  if listKind = ListKindFLST then begin
    for i := 0 to Pred(pluginCount) do begin
      entP := ElementByIndex(pluginContainer, i);
      entM := ElementByIndex(masterContainer, i);
      if ListEntryItemRef(entP, listKind) <> ListEntryItemRef(entM, listKind) then
        Exit;
    end;
    Result := True;
    Exit;
  end;

  for i := 0 to Pred(pluginCount) do begin
    entP := ElementByIndex(pluginContainer, i);
    entM := ElementByIndex(masterContainer, i);
    case listKind of
      ListKindLVLI, ListKindCONT: begin
        if ListEntryAddKey(entP, listKind) <> ListEntryAddKey(entM, listKind) then
          Exit;
      end;
    else begin
        if ListEntryItemRef(entP, listKind) <> ListEntryItemRef(entM, listKind) then
          Exit;
      end;
    end;
  end;
  Result := True;
end;

//============================================================================
// Caller must run ShouldProcessOverride in the plugin loop before export.
function ListRecordNeedsContainerDiff(e, pluginContainer, masterContainer: IInterface;
  listKind: integer; forwardItms: boolean): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not forwardItms then begin
    if RecordHasExternalMaster(e) then begin
      if Assigned(pluginContainer) then begin
        if Assigned(masterContainer) then begin
          if ListContainerIndexIdentical(pluginContainer, masterContainer, listKind) then begin
            if listKind = ListKindLVLI then begin
              master := CompareBaselineRecord(e);
              if ListLvlifFlagsExportable(e, master) then
                Result := True;
            end;
            Exit;
          end;
        end;
      end;
    end;
  end;
  Result := True;
end;

//============================================================================
function ListAddMultisetUsesAddKeys(listKind: integer; minimalAddDiff: boolean): boolean;
begin
  Result := True;
end;

//============================================================================
function ListAddEmitCount(listKind: integer; forwardItms, minimalAddDiff: boolean;
  pluginCount, masterCount: integer): integer;
begin
  Result := 0;
  if pluginCount <= 0 then
    Exit;
  if forwardItms then begin
    Result := pluginCount;
    Exit;
  end;
  if not minimalAddDiff then begin
    Result := pluginCount;
    Exit;
  end;
  if pluginCount > masterCount then
    Result := pluginCount - masterCount;
end;

//============================================================================
procedure ListEmitAddLines(e: IInterface; pluginContainer, masterContainer: IInterface;
  lines: TStringList; listKind: integer; forwardItms, overridesOnly: boolean;
  const filterPrefix, addOpcode, editorID: string; skipAddKeys: TStringList);
var
  i, emitCount, pluginCount, masterCount, winnerCount, keyCount, loopLast: integer;
  addKey, identityKey, line: string;
  hasMaster, hasWinnerMultiset, minimalAddDiff, addMultisetUsesAddKeys: boolean;
begin
  if not Assigned(pluginContainer) then
    Exit;

  hasMaster := Assigned(masterContainer);
  minimalAddDiff := ListUseNetGate(forwardItms, overridesOnly);
  addMultisetUsesAddKeys := ListAddMultisetUsesAddKeys(listKind, minimalAddDiff);

  ListEnsureScratchMultisets;
  if gListMinimalMultisetReady and gListMinimalMultisetHasAdd and minimalAddDiff then
    MultisetAssign(gListScratchPluginMultiset, gListScratchPluginAdd)
  else if addMultisetUsesAddKeys then
    ListBuildMultiset(pluginContainer, gListScratchPluginMultiset, listKind, True)
  else
    ListBuildMultiset(pluginContainer, gListScratchPluginMultiset, listKind, False);
  if hasMaster then begin
    ListEnsureMasterEntryCache(masterContainer, listKind);
    if gListMinimalMultisetReady and gListMinimalMultisetHasAdd and minimalAddDiff then begin
      MultisetAssign(gListScratchMasterMultiset, gListScratchMasterAdd);
    end else begin
      if addMultisetUsesAddKeys then
        ListBuildMultiset(masterContainer, gListScratchMasterMultiset, listKind, True)
      else
        ListBuildMultiset(masterContainer, gListScratchMasterMultiset, listKind, False);
    end;
  end;

  hasWinnerMultiset := False;

  keyCount := gListScratchPluginMultiset.Count;
  loopLast := LoopLastIndex(keyCount);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    identityKey := StringListItemAt(gListScratchPluginMultiset, i);
    if identityKey = '' then
      Continue;

    pluginCount := StringListObjectIntAt(gListScratchPluginMultiset, i);
    if pluginCount <= 0 then
      pluginCount := MultisetCount(gListScratchPluginMultiset, identityKey);
    if hasMaster then
      masterCount := MultisetCount(gListScratchMasterMultiset, identityKey)
    else
      masterCount := 0;

    addKey := identityKey;
    if addKey = '' then
      Continue;

    emitCount := ListAddEmitCount(listKind, forwardItms, minimalAddDiff,
      pluginCount, masterCount);
    if emitCount <= 0 then
      Continue;

    if gRestorationMode then begin
      if not hasWinnerMultiset then
        ListPrepareWinnerMultiset(e, listKind, False, hasWinnerMultiset);
      if hasWinnerMultiset then begin
        winnerCount := MultisetCount(gListScratchWinnerMultiset, identityKey);
        if winnerCount > 0 then
          Continue;
      end;
    end;

    if Assigned(skipAddKeys) then begin
      if MultisetTryConsume(skipAddKeys, addKey) then
        Continue;
    end;

    line := filterPrefix + ':' + addOpcode + '=' + addKey;
    while emitCount > 0 do begin
      lines.Add(line);
      emitCount := emitCount - 1;
    end;
  end;
end;

//============================================================================
function ListLvliPluginHasAddForRemoveKey(pluginContainer: IInterface;
  const removeKey: string): boolean;
var
  i, loopLast: integer;
  ent: IInterface;
begin
  Result := False;
  if not Assigned(pluginContainer) then
    Exit;
  if removeKey = '' then
    Exit;
  if gListEntryCacheLocked then begin
    if gListEntryCacheCount > 0 then begin
      loopLast := LoopLastIndex(gListEntryCacheCount);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
        if ListCachedRemoveKey(i) = removeKey then begin
          Result := True;
          Exit;
        end;
      end;
      Exit;
    end;
  end;
  loopLast := LoopLastIndex(ElementCount(pluginContainer));
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    ent := ElementByIndex(pluginContainer, i);
    if ListEntryRemoveKey(ent, ListKindLVLI) = removeKey then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
procedure ListEmitRemoveLines(e: IInterface; pluginContainer, masterContainer: IInterface;
  lines: TStringList; listKind: integer; const filterPrefix: string; useScratchFlst,
  replacedOld: TStringList);
var
  i, masterN, pluginN, emitN, loopLast: integer;
  removeKey, line: string;
  useIdentityKeys: boolean;
begin
  if not Assigned(masterContainer) then
    Exit;
  if not Assigned(pluginContainer) then
    Exit;

  useIdentityKeys := False;
  if listKind = ListKindLVLI then
    useIdentityKeys := True;
  if listKind = ListKindCONT then
    useIdentityKeys := True;

  ListEnsureScratchMultisets;
  if gListMinimalMultisetReady and gListMinimalMultisetHasRemove then
    MultisetAssign(gListScratchPluginMultiset, gListScratchPluginRem)
  else
    ListBuildMultiset(pluginContainer, gListScratchPluginMultiset, listKind, False);
  if gListMinimalMultisetReady and gListMinimalMultisetHasRemove then begin
    MultisetAssign(gListScratchMasterMultiset, gListScratchMasterRem);
  end else begin
    ListEnsureMasterEntryCache(masterContainer, listKind);
    ListBuildMultiset(masterContainer, gListScratchMasterMultiset, listKind, False);
  end;

  loopLast := LoopLastIndex(gListScratchMasterMultiset.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    removeKey := StringListItemAt(gListScratchMasterMultiset, i);
    if removeKey = '' then
      Continue;

    if useScratchFlst then begin
      if Assigned(replacedOld) then begin
        if MultisetTryConsume(replacedOld, removeKey) then
          Continue;
      end;
    end;

    if listKind = ListKindLVLI then begin
      if ListLvliPluginHasAddForRemoveKey(pluginContainer, removeKey) then
        Continue;
    end;

    masterN := StringListObjectIntAt(gListScratchMasterMultiset, i);
    if masterN <= 0 then
      masterN := MultisetCount(gListScratchMasterMultiset, removeKey);
    pluginN := MultisetCount(gListScratchPluginMultiset, removeKey);
    if masterN <= pluginN then
      Continue;

    emitN := masterN - pluginN;
    if gRestorationMode then
      emitN := ListRestorationCappedRemoveEmitN(e, listKind, useIdentityKeys, removeKey,
        masterN, pluginN);
    if emitN <= 0 then
      Continue;

    while emitN > 0 do begin
      line := filterPrefix + ':' + ListRemoveOpcode(listKind) + '=' + removeKey;
      lines.Add(line);
      Dec(emitN);
    end;
  end;
end;

//============================================================================
procedure ListEmitFlstRemoveLinesFast(e: IInterface; pluginContainer,
  removeMasterContainer: IInterface; lines: TStringList; const filterPrefix: string;
  replacedOld: TStringList);
var
  i, masterN, pluginN, emitN, pluginLimit, masterLimit, loopLast: integer;
  removeKey, line, itemRef: string;
  masterCounts, pluginCounts: TStringList;
  parent: IInterface;
begin
  if not Assigned(removeMasterContainer) then
    Exit;
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(lines) then
    Exit;

  ListEnsureFlstSideCache(removeMasterContainer);
  pluginLimit := gListEntryCacheCount;
  masterLimit := gListMasterSideCacheCount;

  if ListFlstOrderedRefsIdentical(pluginLimit, masterLimit) then
    Exit;

  if gListMinimalMultisetReady and gListMinimalMultisetHasRemove then begin
    if gListScratchMinimalFlstRemoveEmitKeys.Count = 0 then
      Exit;
    loopLast := LoopLastIndex(gListScratchMinimalFlstRemoveEmitKeys.Count);
    if loopLast >= 0 then
    for i := 0 to loopLast do begin
      removeKey := StringListItemAt(gListScratchMinimalFlstRemoveEmitKeys, i);
      if removeKey = '' then
        Continue;
      if Assigned(replacedOld) then begin
        if MultisetTryConsume(replacedOld, removeKey) then
          Continue;
      end;
      emitN := StringListObjectIntAt(gListScratchMinimalFlstRemoveEmitKeys, i);
      if gRestorationMode then begin
        itemRef := ListIdentityKeyForListValue(ListKindFLST, removeKey);
        pluginN := ListItemCountOnRecord(e, ListKindFLST, False, itemRef);
        parent := CompareBaselineRecord(e);
        masterN := ListItemCountOnRecord(parent, ListKindFLST, False, itemRef);
        emitN := ListRestorationCappedRemoveEmitN(e, ListKindFLST, False, removeKey,
          masterN, pluginN);
      end;
      if emitN <= 0 then
        Continue;
      while emitN > 0 do begin
        line := filterPrefix + ':' + ListRemoveOpcode(ListKindFLST) + '=' + removeKey;
        lines.Add(line);
        Dec(emitN);
      end;
    end;
    Exit;
  end;

  ListEnsureScratchMultisets;
  ListBuildFlstMasterMultiset(masterLimit, gListScratchMasterMultiset);
  ListBuildFlstEntryMultiset(pluginLimit, gListScratchPluginMultiset, nil);
  masterCounts := gListScratchMasterMultiset;
  pluginCounts := gListScratchPluginMultiset;

  loopLast := LoopLastIndex(masterCounts.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    removeKey := StringListItemAt(masterCounts, i);
    if removeKey = '' then
      Continue;

    if Assigned(replacedOld) then begin
      if MultisetTryConsume(replacedOld, removeKey) then
          Continue;
    end;

    masterN := StringListObjectIntAt(masterCounts, i);
    pluginN := MultisetCount(pluginCounts, removeKey);
    if masterN <= pluginN then
      Continue;

    emitN := masterN - pluginN;
    if gRestorationMode then
      emitN := ListRestorationCappedRemoveEmitN(e, ListKindFLST, False, removeKey,
        masterN, pluginN);
    if emitN <= 0 then
      Continue;

    while emitN > 0 do begin
      line := filterPrefix + ':' + ListRemoveOpcode(ListKindFLST) + '=' + removeKey;
      lines.Add(line);
      Dec(emitN);
    end;
  end;
end;

//============================================================================
procedure ListEmitFlstAddLinesFast(e: IInterface; pluginContainer, addMasterContainer: IInterface;
  lines: TStringList; forwardItms, overridesOnly: boolean; const filterPrefix, addOpcode,
  editorID: string; skipAddKeys: TStringList);
var
  i, emitCount, pluginCount, masterCount, pluginLimit, masterLimit, loopLast: integer;
  addKey, itemRef, line: string;
  hasMaster, minimalAddDiff: boolean;
  pluginCounts, masterCounts: TStringList;
begin
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(lines) then
    Exit;

  hasMaster := Assigned(addMasterContainer);
  minimalAddDiff := ListUseNetGate(forwardItms, overridesOnly);
  if hasMaster then
    ListEnsureFlstSideCache(addMasterContainer);

  pluginLimit := gListEntryCacheCount;
  masterLimit := 0;
  if hasMaster then
    masterLimit := gListMasterSideCacheCount;

  if minimalAddDiff then begin
    if hasMaster then begin
      if ListFlstOrderedRefsIdentical(pluginLimit, masterLimit) then
        Exit;
    end else begin
      if pluginLimit <= 0 then
        Exit;
    end;
  end else begin
    if pluginLimit <= 0 then
      Exit;
  end;

  if minimalAddDiff and gListMinimalMultisetReady and gListMinimalMultisetHasAdd then begin
    if gListScratchMinimalFlstAddEmitKeys.Count = 0 then
      Exit;
    loopLast := LoopLastIndex(gListScratchMinimalFlstAddEmitKeys.Count);
    if loopLast >= 0 then
    for i := 0 to loopLast do begin
      addKey := StringListItemAt(gListScratchMinimalFlstAddEmitKeys, i);
      if addKey = '' then
        Continue;
      pluginCount := StringListObjectIntAt(gListScratchMinimalFlstAddEmitKeys, i);
      if Assigned(skipAddKeys) then begin
        if MultisetTryConsume(skipAddKeys, addKey) then
          Continue;
      end;
      if ListRestorationSkipAdd(e, ListKindFLST, False, addKey) then
        Continue;
      emitCount := pluginCount;
      if emitCount <= 0 then
        Continue;
      line := filterPrefix + ':' + addOpcode + '=' + addKey;
      while emitCount > 0 do begin
        lines.Add(line);
        emitCount := emitCount - 1;
      end;
    end;
    Exit;
  end;

  ListEnsureScratchMultisets;
  if gListMinimalMultisetReady and gListMinimalMultisetHasAdd and minimalAddDiff then begin
    pluginCounts := gListScratchPluginAdd;
    masterCounts := gListScratchMasterAdd;
  end else begin
    ListBuildFlstEntryMultiset(pluginLimit, gListScratchPluginMultiset,
      gListScratchFlstPluginAddKeys);
    if hasMaster then
      ListBuildFlstMasterMultiset(masterLimit, gListScratchMasterMultiset)
    else
      MultisetClear(gListScratchMasterMultiset);
    pluginCounts := gListScratchPluginMultiset;
    masterCounts := gListScratchMasterMultiset;
  end;

  loopLast := LoopLastIndex(pluginCounts.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    itemRef := StringListItemAt(pluginCounts, i);
    if itemRef = '' then
      Continue;

    pluginCount := StringListObjectIntAt(pluginCounts, i);
    if hasMaster then
      masterCount := MultisetCount(masterCounts, itemRef)
    else
      masterCount := 0;

    addKey := ListFlstAddKeyAtMultisetIndex(i);
    if addKey = '' then
      Continue;

    emitCount := ListAddEmitCount(ListKindFLST, forwardItms, minimalAddDiff,
      pluginCount, masterCount);
    if emitCount <= 0 then
      Continue;

    if ListRestorationSkipAdd(e, ListKindFLST, False, addKey) then
      Continue;

    if Assigned(skipAddKeys) then begin
      if MultisetTryConsume(skipAddKeys, addKey) then
        Continue;
    end;

    line := filterPrefix + ':' + addOpcode + '=' + addKey;
    while emitCount > 0 do begin
      lines.Add(line);
      emitCount := emitCount - 1;
    end;
  end;
end;

//============================================================================
procedure ListAppendLvlifFlagsIfNeeded(e, master: IInterface; lines: TStringList;
  const filterPrefix: string);
begin
  if wbGameMode = gmTES4 then
    Exit;
  if not Assigned(lines) then
    Exit;
  if not ElementExists(e, ListContainerName(ListKindLVLI)) then
    Exit;

  if ListLvlifFlagsExportable(e, master) then
    ListAppendLVLIFlags(lines, filterPrefix, e);
end;

//============================================================================
procedure ListEnsureFlstSideCache(container: IInterface);
var
  key: string;
begin
  if not Assigned(container) then
    Exit;
  key := ListEntryContainerKey(container);
  if (key <> '') and (key = gListMasterSideCacheKey) and
    (gListMasterSideCacheCount = ElementCount(container)) then
    Exit;
  ListBuildFlstSideCache(container);
end;

//============================================================================
procedure ListBuildFlstSideCache(container: IInterface);
var
  i, n: integer;
  ent, ref: IInterface;
  itemRef, addKey, removeKey: string;
begin
  gListMasterSideCacheCount := 0;
  gListMasterSideCacheKey := '';
  if not Assigned(container) then
    Exit;
  n := ElementCount(container);
  if not Assigned(gListScratchMasterSideItemRef) then
    gListScratchMasterSideItemRef := TStringList.Create;
  if not Assigned(gListScratchMasterSideAddKey) then
    gListScratchMasterSideAddKey := TStringList.Create;
  if not Assigned(gListScratchMasterSideRemoveKey) then
    gListScratchMasterSideRemoveKey := TStringList.Create;
  if not Assigned(gListScratchMasterSideItemSeen) then
    gListScratchMasterSideItemSeen := TStringList.Create;
  gListScratchMasterSideItemRef.Clear;
  gListScratchMasterSideAddKey.Clear;
  gListScratchMasterSideRemoveKey.Clear;
  if Assigned(gListScratchMasterSideItemSeen) then begin
    gListScratchMasterSideItemSeen.Sorted := False;
    gListScratchMasterSideItemSeen.Clear;
  end;
  gListMasterSideCacheCount := n;
  if n > 0 then
    for i := 0 to Pred(n) do begin
    ent := ElementByIndex(container, i);
    itemRef := '';
    addKey := '';
    removeKey := '';
    ref := LinksTo(ent);
    if Assigned(ref) then begin
      itemRef := MasterFormIDRef(ref);
      if FormIDRef(ref) <> '' then
        addKey := FormIDRef(ref);
      if itemRef <> '' then
        removeKey := itemRef;
    end;
    gListScratchMasterSideItemRef.Add(itemRef);
    gListScratchMasterSideAddKey.Add(addKey);
    gListScratchMasterSideRemoveKey.Add(removeKey);
    if itemRef <> '' then
      gListScratchMasterSideItemSeen.Add(itemRef);
  end;
  gListMasterSideCacheKey := ListEntryContainerKey(container);
  if Assigned(gListScratchMasterSideItemSeen) then
    gListScratchMasterSideItemSeen.Sorted := True;
end;

//============================================================================
function ListFlstSideCacheHasItemRef(const itemRef: string): boolean;
begin
  Result := False;
  if itemRef = '' then
    Exit;
  if not Assigned(gListScratchMasterSideItemSeen) then
    Exit;
  Result := gListScratchMasterSideItemSeen.IndexOf(itemRef) >= 0;
end;

//============================================================================
// True when index-aligned FLST FormIDs differ (requires plugin entry cache).
function ListFlstIndexDiffers(pluginContainer, masterContainer: IInterface): boolean;
var
  pluginCount: integer;
begin
  Result := True;
  if not Assigned(pluginContainer) then
    Exit;
  if gListEntryCacheCount <= 0 then
    Exit;
  if ListEntryContainerKey(pluginContainer) <> gListEntryCacheContainerKey then
    Exit;
  pluginCount := gListEntryCacheCount;
  if not Assigned(masterContainer) then begin
    if pluginCount > 0 then
      Result := True
    else
      Result := False;
    Exit;
  end;
  if pluginCount <> ElementCount(masterContainer) then
    Exit;
  ListEnsureFlstSideCache(masterContainer);
  if ListFlstOrderedRefsIdentical(pluginCount, gListMasterSideCacheCount) then
    Result := False;
end;

//============================================================================
procedure ListBuildFlstMultisetFromKeys(keys: TStringList; limit: integer; counts: TStringList);
var
  i, loopLast: integer;
begin
  MultisetClear(counts);
  if not Assigned(keys) then
    Exit;
  if limit <= 0 then
    Exit;
  if limit > keys.Count then
    limit := keys.Count;
  ListFlstMultisetMapClear;
  loopLast := LoopLastIndex(limit);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do
    ListFlstMultisetMapInc(StringListItemAt(keys, i), counts, nil, nil, 0);
end;

//============================================================================
procedure ListBuildFlstMultisetFromKeys(keys: TStringList; limit: integer;
  counts, addKeysOut: TStringList; addKeySource: TStringList);
var
  i, loopLast: integer;
  key: string;
begin
  MultisetClear(counts);
  if Assigned(addKeysOut) then
    addKeysOut.Clear;
  if not Assigned(keys) then
    Exit;
  if limit <= 0 then
    Exit;
  if limit > keys.Count then
    limit := keys.Count;

  loopLast := LoopLastIndex(limit);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    key := StringListItemAt(keys, i);
    if key = '' then
      Continue;
    ListFlstMultisetMapInc(key, counts, addKeysOut, addKeySource, i);
  end;
end;

//============================================================================
procedure ListBuildFlstEntryMultiset(limit: integer; counts, addKeysOut: TStringList);
begin
  ListBuildFlstMultisetFromKeys(gListScratchEntryRemoveKey, limit, counts,
    addKeysOut, gListScratchEntryAddKey);
end;

//============================================================================
procedure ListBuildFlstMasterMultiset(limit: integer; counts: TStringList);
begin
  ListBuildFlstMultisetFromKeys(gListScratchMasterSideRemoveKey, limit, counts,
    nil, gListScratchMasterSideAddKey);
end;

//============================================================================
function ListFlstOrderedRefsIdentical(pluginLimit, masterLimit: integer): boolean;
begin
  Result := False;
  if pluginLimit <> masterLimit then
    Exit;
  if pluginLimit <= 0 then begin
    Result := True;
    Exit;
  end;
  Result := ListFlstPrefixItemRefsIdentical(pluginLimit);
end;

//============================================================================
function ListFlstPrefixRemoveKeysIdentical(sharedCount: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if sharedCount <= 0 then begin
    Result := True;
    Exit;
  end;
  for i := 0 to Pred(sharedCount) do begin
    if ListFlstMasterSideRemoveKeyAt(i) <> ListCachedRemoveKey(i) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function ListFlstPrefixItemRefsIdentical(sharedCount: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if sharedCount <= 0 then begin
    Result := True;
    Exit;
  end;
  for i := 0 to Pred(sharedCount) do begin
    if ListFlstMasterSideItemRefAt(i) <> ListCachedItemRef(i) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function ListFlstAddKeyAtMultisetIndex(index: integer): string;
begin
  Result := StringListItemAt(gListScratchFlstPluginAddKeys, index);
end;

//============================================================================
function ListFlstContainersIndexIdentical(pluginContainer, masterContainer: IInterface): boolean;
var
  i, loopLast: integer;
begin
  Result := False;
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(masterContainer) then
    Exit;
  if gListEntryCacheCount <= 0 then
    Exit;
  ListBuildFlstSideCache(masterContainer);
  if gListEntryCacheCount <> gListMasterSideCacheCount then
    Exit;
  loopLast := LoopLastIndex(gListEntryCacheCount);
  if loopLast < 0 then begin
    Result := True;
    Exit;
  end;
  for i := 0 to loopLast do begin
    if ListCachedItemRef(i) <> ListFlstMasterSideItemRefAt(i) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function ListFlstPrefixRemoveKeyCount(const removeKey: string; prefixLimit: integer): integer;
var
  i, n: integer;
begin
  n := 0;
  if removeKey = '' then
    Exit;
  if prefixLimit <= 0 then
    Exit;
  for i := 0 to Pred(prefixLimit) do begin
    if ListCachedRemoveKey(i) = removeKey then
      n := n + 1;
  end;
  Result := n;
end;

//============================================================================
procedure ListFlstEnsurePrefixRemoveKeySeen(prefixLimit: integer);
var
  i: integer;
  removeKey: string;
begin
  if not Assigned(gListScratchMasterSideItemSeen) then
    gListScratchMasterSideItemSeen := TStringList.Create;
  gListScratchMasterSideItemSeen.Sorted := False;
  gListScratchMasterSideItemSeen.Duplicates := dupIgnore;
  gListScratchMasterSideItemSeen.Clear;
  if prefixLimit <= 0 then begin
    gListScratchMasterSideItemSeen.Sorted := True;
    Exit;
  end;
  for i := 0 to Pred(prefixLimit) do begin
    removeKey := ListCachedRemoveKey(i);
    if removeKey <> '' then
      gListScratchMasterSideItemSeen.Add(removeKey);
  end;
  gListScratchMasterSideItemSeen.Sorted := True;
end;

//============================================================================
function ListFlstTailAddKeysDisjointFromPrefix(tailStart, pluginLimit,
  prefixLimit: integer): boolean;
var
  i: integer;
  removeKey: string;
begin
  Result := True;
  if tailStart >= pluginLimit then begin
    Result := False;
    Exit;
  end;
  ListFlstEnsurePrefixRemoveKeySeen(prefixLimit);
  for i := tailStart to Pred(pluginLimit) do begin
    removeKey := ListCachedRemoveKey(i);
    if removeKey = '' then
      Continue;
    if gListScratchMasterSideItemSeen.IndexOf(removeKey) >= 0 then begin
      Result := False;
      Exit;
    end;
  end;
end;

//============================================================================
procedure ListFlstFillTailRemoveEmitKeys(tailStart, masterLimit: integer);
var
  i, masterN, emitN, loopLast: integer;
  removeKey: string;
begin
  MultisetClear(gListScratchFlstMasterRem);
  if masterLimit > tailStart then
    for i := tailStart to Pred(masterLimit) do begin
      removeKey := ListFlstMasterSideRemoveKeyAt(i);
      if removeKey <> '' then
        MultisetInc(gListScratchFlstMasterRem, removeKey);
    end;
  loopLast := LoopLastIndex(gListScratchFlstMasterRem.Count);
  if loopLast >= 0 then
    for i := 0 to loopLast do begin
      removeKey := StringListItemAt(gListScratchFlstMasterRem, i);
      if removeKey = '' then
        Continue;
      masterN := StringListObjectIntAt(gListScratchFlstMasterRem, i);
      if masterN <= 0 then
        Continue;
      emitN := masterN;
      gListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey, TObject(emitN));
    end;
end;

//============================================================================
function ListFlstFillTailAddEmitKeys(tailStart, pluginLimit: integer): boolean;
var
  i, pluginN, emitN, loopLast: integer;
  removeKey, addKey: string;
begin
  Result := False;
  if tailStart >= pluginLimit then
    Exit;
  MultisetClear(gListScratchPluginAdd);
  gListScratchFlstPluginAddKeys.Clear;
  for i := tailStart to Pred(pluginLimit) do begin
    removeKey := ListCachedRemoveKey(i);
    addKey := ListCachedAddKey(i);
    if removeKey = '' then
      Continue;
    if addKey = '' then
      Continue;
    MultisetInc(gListScratchPluginAdd, removeKey);
    pluginN := MultisetCount(gListScratchPluginAdd, removeKey);
    if pluginN = 1 then
      gListScratchFlstPluginAddKeys.Add(addKey);
  end;
  loopLast := LoopLastIndex(gListScratchPluginAdd.Count);
  if loopLast >= 0 then
    for i := 0 to loopLast do begin
      removeKey := StringListItemAt(gListScratchPluginAdd, i);
      if removeKey = '' then
        Continue;
      pluginN := StringListObjectIntAt(gListScratchPluginAdd, i);
      if pluginN <= 0 then
        Continue;
      addKey := ListFlstAddKeyAtMultisetIndex(i);
      if addKey = '' then
        Continue;
      emitN := pluginN;
      gListScratchMinimalFlstAddEmitKeys.AddObject(addKey, TObject(emitN));
    end;
  Result := True;
end;

//============================================================================
function ListMinimalDiffEmpty(pluginContainer, addMasterContainer, removeMasterContainer: IInterface;
  listKind: integer; doAdd, doRemove: boolean): boolean;
var
  i, pluginN, masterN, pluginLimit, masterLimit, mismatchIdx, loopLast: integer;
  ent: IInterface;
  removeKey, addKey: string;
  flstSideCached: boolean;
begin
  if gListMinimalMultisetReady then begin
    Result := gListMinimalDiffIsEmpty;
    Exit;
  end;

  Result := True;
  if not Assigned(pluginContainer) then begin
    gListMinimalMultisetReady := True;
    gListMinimalDiffIsEmpty := True;
    Exit;
  end;

  ListEnsureScratchMinimalDiff;
  flstSideCached := False;
  pluginLimit := gListEntryCacheCount;
  masterLimit := 0;

  if doRemove then begin
    if Assigned(removeMasterContainer) then begin
      if listKind = ListKindFLST then begin
        ListEnsureFlstSideCache(removeMasterContainer);
        flstSideCached := True;
        masterLimit := gListMasterSideCacheCount;
        if ListFlstOrderedRefsIdentical(pluginLimit, masterLimit) then begin
          // Ordered refs match; multiset remove diff is empty.
        end else if masterLimit > pluginLimit then begin
          if ListFlstPrefixRemoveKeysIdentical(pluginLimit) then begin
            ListFlstFillTailRemoveEmitKeys(pluginLimit, masterLimit);
            gListMinimalMultisetHasRemove := True;
            if gListScratchMinimalFlstRemoveEmitKeys.Count > 0 then
              Result := False;
          end else begin
            mismatchIdx := ListFlstFirstItemRefMismatch(pluginLimit, masterLimit);
            if mismatchIdx >= 0 then begin
              if ListFlstTrySuffixMinimalDiff(pluginLimit, masterLimit, mismatchIdx,
                False, True) then begin
                gListMinimalMultisetHasRemove := True;
                if gListScratchMinimalFlstRemoveEmitKeys.Count > 0 then
                  Result := False;
              end else begin
                // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.suffix.fallback 1
                ListBuildFlstMasterMultiset(masterLimit, gListScratchFlstMasterRem);
                ListBuildFlstEntryMultiset(pluginLimit, gListScratchFlstPluginRem, nil);
                gListMinimalMultisetHasRemove := True;
                loopLast := LoopLastIndex(gListScratchFlstMasterRem.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
                  removeKey := StringListItemAt(gListScratchFlstMasterRem, i);
                  if removeKey = '' then
                    Continue;
                  masterN := StringListObjectIntAt(gListScratchFlstMasterRem, i);
                  pluginN := MultisetCount(gListScratchFlstPluginRem, removeKey);
                  if masterN > pluginN then begin
                    Result := False;
                    gListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey,
                      TObject(masterN - pluginN));
                  end;
                end;
              end;
            end else begin
              ListBuildFlstMasterMultiset(masterLimit, gListScratchFlstMasterRem);
              ListBuildFlstEntryMultiset(pluginLimit, gListScratchFlstPluginRem, nil);
              gListMinimalMultisetHasRemove := True;
              loopLast := LoopLastIndex(gListScratchFlstMasterRem.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
                removeKey := StringListItemAt(gListScratchFlstMasterRem, i);
                if removeKey = '' then
                  Continue;
                masterN := StringListObjectIntAt(gListScratchFlstMasterRem, i);
                pluginN := MultisetCount(gListScratchFlstPluginRem, removeKey);
                if masterN > pluginN then begin
                  Result := False;
                  gListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey,
                    TObject(masterN - pluginN));
                end;
              end;
            end;
          end;
        end else begin
          ListBuildFlstMasterMultiset(masterLimit, gListScratchFlstMasterRem);
          ListBuildFlstEntryMultiset(pluginLimit, gListScratchFlstPluginRem, nil);
          gListMinimalMultisetHasRemove := True;
          loopLast := LoopLastIndex(gListScratchFlstMasterRem.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
            removeKey := StringListItemAt(gListScratchFlstMasterRem, i);
            if removeKey = '' then
              Continue;
            masterN := StringListObjectIntAt(gListScratchFlstMasterRem, i);
            pluginN := MultisetCount(gListScratchFlstPluginRem, removeKey);
            if masterN > pluginN then begin
              Result := False;
              gListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey,
                TObject(masterN - pluginN));
            end;
          end;
        end;
      end else begin
        ListBuildMultiset(pluginContainer, gListScratchPluginRem, listKind, False);
        ListEnsureMasterEntryCache(removeMasterContainer, listKind);
        ListBuildMultiset(removeMasterContainer, gListScratchMasterRem, listKind, False);
        gListMinimalMultisetHasRemove := True;
        loopLast := LoopLastIndex(ElementCount(removeMasterContainer));
        if loopLast >= 0 then
          for i := 0 to loopLast do begin
            ent := ElementByIndex(removeMasterContainer, i);
          removeKey := ListEntryRemoveKey(ent, listKind);
          if removeKey = '' then
            Continue;
          if MultisetCount(gListScratchPluginRem, removeKey) > 0 then
            Continue;
          Result := False;
          gListMinimalDiffIsEmpty := False;
          gListMinimalMultisetReady := True;
          Exit;
        end;
      end;
    end;
  end;

  if not doAdd then begin
    gListMinimalDiffIsEmpty := Result;
    gListMinimalMultisetReady := True;
    Exit;
  end;

  if listKind = ListKindFLST then begin
    if Assigned(addMasterContainer) then begin
      if not flstSideCached then begin
        ListEnsureFlstSideCache(addMasterContainer);
        masterLimit := gListMasterSideCacheCount;
      end else begin
        if removeMasterContainer <> addMasterContainer then begin
          ListEnsureFlstSideCache(addMasterContainer);
          masterLimit := gListMasterSideCacheCount;
        end;
      end;
      if ListFlstOrderedRefsIdentical(pluginLimit, masterLimit) then begin
        gListMinimalDiffIsEmpty := Result;
        gListMinimalMultisetReady := True;
        Exit;
      end;
      if pluginLimit > masterLimit then begin
        if ListFlstPrefixRemoveKeysIdentical(masterLimit) then begin
          if ListFlstTailAddKeysDisjointFromPrefix(masterLimit, pluginLimit, masterLimit) then begin
            if ListFlstFillTailAddEmitKeys(masterLimit, pluginLimit) then begin
              gListMinimalMultisetHasAdd := True;
              if gListScratchMinimalFlstAddEmitKeys.Count > 0 then
                Result := False;
              gListMinimalDiffIsEmpty := Result;
              gListMinimalMultisetReady := True;
              Exit;
            end;
          end;
        end;
      end;
      mismatchIdx := ListFlstFirstItemRefMismatch(pluginLimit, masterLimit);
      if mismatchIdx >= 0 then begin
        if ListFlstTrySuffixMinimalDiff(pluginLimit, masterLimit, mismatchIdx, True, False) then begin
          gListMinimalMultisetHasAdd := True;
          if gListScratchMinimalFlstAddEmitKeys.Count > 0 then
            Result := False;
          gListMinimalDiffIsEmpty := Result;
          gListMinimalMultisetReady := True;
          Exit;
        end;
      end;
      // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.suffix.fallback 1
      ListBuildFlstEntryMultiset(pluginLimit, gListScratchPluginAdd,
        gListScratchFlstPluginAddKeys);
      ListBuildFlstMasterMultiset(masterLimit, gListScratchMasterAdd);
      gListMinimalMultisetHasAdd := True;
      loopLast := LoopLastIndex(gListScratchPluginAdd.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
        removeKey := StringListItemAt(gListScratchPluginAdd, i);
        if removeKey = '' then
          Continue;
        pluginN := StringListObjectIntAt(gListScratchPluginAdd, i);
        masterN := MultisetCount(gListScratchMasterAdd, removeKey);
        if pluginN > masterN then begin
          Result := False;
          addKey := ListFlstAddKeyAtMultisetIndex(i);
          if addKey <> '' then
            gListScratchMinimalFlstAddEmitKeys.AddObject(addKey,
              TObject(pluginN - masterN));
        end;
      end;
    end else if doAdd and (pluginLimit > 0) then begin
      // Master record has no FormIDs container; plugin-local net adds still emit.
      Result := False;
    end;
    gListMinimalDiffIsEmpty := Result;
    gListMinimalMultisetReady := True;
    Exit;
  end;

  ListBuildMultiset(pluginContainer, gListScratchPluginAdd, listKind,
    ListAddMultisetUsesAddKeys(listKind, True));
  gListMinimalMultisetHasAdd := True;
  if Assigned(addMasterContainer) then begin
    ListEnsureMasterEntryCache(addMasterContainer, listKind);
    ListBuildMultiset(addMasterContainer, gListScratchMasterAdd, listKind,
      ListAddMultisetUsesAddKeys(listKind, True));
  end else
    gListScratchMasterAdd.Clear;
  loopLast := LoopLastIndex(gListScratchPluginAdd.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
    removeKey := StringListItemAt(gListScratchPluginAdd, i);
    if removeKey = '' then
      Continue;
    pluginN := StringListObjectIntAt(gListScratchPluginAdd, i);
    if pluginN <= 0 then
      pluginN := MultisetCount(gListScratchPluginAdd, removeKey);
    masterN := MultisetCount(gListScratchMasterAdd, removeKey);
    if pluginN > masterN then begin
      Result := False;
      gListMinimalDiffIsEmpty := False;
      gListMinimalMultisetReady := True;
      Exit;
    end;
  end;
  gListMinimalDiffIsEmpty := Result;
  gListMinimalMultisetReady := True;
end;

//============================================================================
procedure ListEmitFlstReplaceLines(pluginContainer, masterContainer: IInterface;
  lines: TStringList; const filterPrefix: string; replacedOld, replacedNew: TStringList);
var
  i, masterCount, startIdx: integer;
  oldRef, newRef: string;
begin
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(masterContainer) then
    Exit;
  if not Assigned(replacedOld) then
    Exit;
  if not Assigned(replacedNew) then
    Exit;

  masterCount := gListEntryCacheCount;
  if masterCount <> gListMasterSideCacheCount then
    Exit;
  if masterCount <= 0 then
    Exit;

  ListEnsureFlstSideCache(masterContainer);
  startIdx := ListFlstFirstItemRefMismatch(masterCount, masterCount);
  if startIdx < 0 then
    startIdx := 0;

  for i := startIdx to Pred(masterCount) do begin
    oldRef := ListFlstMasterSideItemRefAt(i);
    newRef := ListCachedItemRef(i);
    if oldRef = '' then
      Continue;
    if newRef = '' then
      Continue;
    if oldRef = newRef then
      Continue;

    // formsToReplace swaps two forms that already exist in the master list.
    // If newRef was not in the master list, emit formsToAdd / formsToRemove instead.
    if not ListFlstSideCacheHasItemRef(newRef) then
      Continue;

    lines.Add(filterPrefix + ':formsToReplace=' + oldRef + '=' + newRef);
    // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.replace 1
    MultisetInc(replacedOld, oldRef);
    MultisetInc(replacedNew, newRef);
  end;
end;

//============================================================================
procedure ListDiffToLines(e: IInterface; lines: TStringList; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly: boolean; const filterPrefix: string;
  pluginContainer, addMasterContainer, removeMasterContainer: IInterface);
var
  addOpcode, containerName, editorID: string;
  useScratchFlst, cacheEmit: boolean;
begin
  if not doAdd then begin
    if not doRemove then
      Exit;
  end;

  containerName := ListContainerName(listKind);
  if containerName = '' then
    Exit;

  if not Assigned(pluginContainer) then begin
    if not ElementExists(e, containerName) then
      Exit;
    pluginContainer := ElementByName(e, containerName);
    addMasterContainer := ListNetCompareAddContainer(e, listKind, forwardItms, overridesOnly);
    removeMasterContainer := ListNetCompareRemoveContainer(e, listKind, forwardItms, overridesOnly);
  end;

  if not Assigned(pluginContainer) then
    Exit;

  addOpcode := ListAddOpcode(listKind);
  editorID := RecordEditorId(e);

  useScratchFlst := False;

  if listKind = ListKindFLST then begin
    cacheEmit := gListMinimalMultisetReady and ListFlstMinimalCacheHasEmitWork;
    useScratchFlst := False;

    if cacheEmit then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.diff.cache_emit 1
    end;

    if doAdd then begin
      if doRemove then begin
        if RecordHasExternalMaster(e) then begin
          if Assigned(addMasterContainer) then begin
            ListEnsureFlstSideCache(addMasterContainer);
            if gListEntryCacheCount = gListMasterSideCacheCount then begin
              ListEnsureScratchFlstReplace;
              useScratchFlst := True;
              // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.diff.scratch_replace 1
              ListEmitFlstReplaceLines(pluginContainer, addMasterContainer, lines,
                filterPrefix, gListScratchFlstOld, gListScratchFlstNew);
            end;
          end;
        end;
      end;
    end;

    if doRemove then begin
      if RecordHasExternalMaster(e) then begin
        if Assigned(removeMasterContainer) then begin
          if useScratchFlst then
            ListEmitFlstRemoveLinesFast(e, pluginContainer, removeMasterContainer, lines,
              filterPrefix, gListScratchFlstOld)
          else
            ListEmitFlstRemoveLinesFast(e, pluginContainer, removeMasterContainer, lines,
              filterPrefix, nil);
        end;
      end;
    end;

    if doAdd then begin
      if RecordHasExternalMaster(e) then begin
        if useScratchFlst then
          ListEmitFlstAddLinesFast(e, pluginContainer, addMasterContainer, lines,
            forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, gListScratchFlstNew)
        else
          ListEmitFlstAddLinesFast(e, pluginContainer, addMasterContainer, lines,
            forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
      end else
        ListEmitFlstAddLinesFast(e, pluginContainer, nil, lines,
          forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
    end;
    Exit;
  end;

  if not gListMinimalMultisetReady then
    ListEnsureScratchMultisets;

  if doRemove then begin
    if RecordHasExternalMaster(e) then begin
      if Assigned(removeMasterContainer) then
        ListEmitRemoveLines(e, pluginContainer, removeMasterContainer, lines, listKind,
          filterPrefix, False, nil);
    end;
  end;

  if doAdd then begin
    if RecordHasExternalMaster(e) then
      ListEmitAddLines(e, pluginContainer, addMasterContainer, lines, listKind,
        forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil)
    else
      ListEmitAddLines(e, pluginContainer, nil, lines, listKind,
        forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
  end;
end;

//============================================================================
// List export gate: ITM gate + override gate must not use whole-record ITM
// skip, because LVLI/FLST/CONT list edits may be invisible to ConflictAll.
function ShouldProcessListOverride(e: IInterface; listKind: integer;
  forwardItms, overridesOnly, doAdd, doRemove: boolean): boolean;
var
  containerName: string;
  pluginContainer, addMasterContainer, removeMasterContainer, master: IInterface;
begin
  ListResetMinimalDiffCache;
  ListClearGateContainerCache;
  ListClearEntryCache;
  ListClearMasterEntryCache;
  Result := False;
  if not Assigned(e) then
    Exit;
  if not ShouldExportRecord(e, overridesOnly) then
    Exit;
  if gRestorationMode then begin
    if IsWinningOverride(e) then
      Exit;
  end;
  if forwardItms then begin
    if listKind <> ListKindFLST then begin
      Result := True;
      Exit;
    end;
  end;
  if not overridesOnly then begin
    if RecordUnchangedVsMaster(e) then
      Exit;
    Result := True;
    Exit;
  end;

  containerName := ListContainerName(listKind);
  if containerName = '' then
    Exit;
  pluginContainer := nil;
  addMasterContainer := nil;
  removeMasterContainer := nil;
  master := nil;
  if ElementExists(e, containerName) then begin
    pluginContainer := ElementByName(e, containerName);
    addMasterContainer := ListNetCompareAddContainer(e, listKind, forwardItms, overridesOnly);
    removeMasterContainer := ListNetCompareRemoveContainer(e, listKind, forwardItms, overridesOnly);
  end;
  if not Assigned(pluginContainer) then
    Exit;

  ListEnsureEntryCache(pluginContainer, listKind);

  if listKind = ListKindFLST then begin
    if ListFlstIndexDiffers(pluginContainer, addMasterContainer) then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.flst_index_only 1
      ListRememberGateContainers(e, listKind, pluginContainer, addMasterContainer,
        removeMasterContainer, True);
      Result := True;
      Exit;
    end;
  end else begin
    if ListRecordNeedsContainerDiff(e, pluginContainer, addMasterContainer, listKind,
      forwardItms) then begin
      ListRememberGateContainers(e, listKind, pluginContainer, addMasterContainer,
        removeMasterContainer, True);
      Result := True;
      Exit;
    end;

    if listKind = ListKindLVLI then begin
      master := CompareBaselineRecord(e);
      if ListLvlifFlagsExportable(e, master) then begin
        ListRememberGateContainers(e, listKind, pluginContainer, addMasterContainer,
          removeMasterContainer, False);
        Result := True;
        Exit;
      end;
    end;
  end;

  if not RecordHasExternalMaster(e) then
    Exit;
  if listKind = ListKindFLST then begin
    if not ListFlstIndexDiffers(pluginContainer, addMasterContainer) then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.flst_itm_identical 1
      Exit;
    end;
  end;
  if not ListMinimalDiffEmpty(pluginContainer, addMasterContainer, removeMasterContainer,
    listKind, doAdd, doRemove) then begin
    ListRememberGateContainers(e, listKind, pluginContainer, addMasterContainer,
      removeMasterContainer, False);
    Result := True;
  end;
end;

//============================================================================
procedure ExportListRecord(e: IInterface; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  pluginName, editorID, filterPrefix, sig, containerName, targetRef: string;
  pluginContainer, addMasterContainer, removeMasterContainer, master: IInterface;
  skipListDiff, hasData, needsContainerDiff, allowNoIndexDiff, gateContainersReused,
    minimalDiffEmpty, minimalDiffEvaluated, lvliFlagsKnown, lvliFlagsExportable: boolean;
begin
  sig := ListRecordSig(listKind);
  if sig = '' then
    Exit;
  if Signature(e) <> sig then
    Exit;

  if not doAdd then begin
    if not doRemove then
      Exit;
  end;

  if not gIniWriterActive then
    Exit;

  targetRef := PatchFilterFormIDRef(e);
  pluginName := PluginNameForRecord(e);
  MidChainClearRecordContext;

  containerName := ListContainerName(listKind);
  pluginContainer := nil;
  addMasterContainer := nil;
  removeMasterContainer := nil;
  master := nil;
  lvliFlagsKnown := False;
  lvliFlagsExportable := False;
  if not ListTryReuseGateContainers(e, listKind, pluginContainer, addMasterContainer,
    removeMasterContainer) then begin
    gateContainersReused := False;
    if ElementExists(e, containerName) then begin
      pluginContainer := ElementByName(e, containerName);
      addMasterContainer := ListNetCompareAddContainer(e, listKind, forwardItms, overridesOnly);
      removeMasterContainer := ListNetCompareRemoveContainer(e, listKind, forwardItms, overridesOnly);
    end;
  end else
    gateContainersReused := True;

  if not Assigned(pluginContainer) then begin
    if listKind = ListKindLVLI then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.container.skip.lvli 1
    end else if listKind = ListKindCONT then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.container.skip.cont 1
    end else begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.container.skip.flst 1
    end;
    Exit;
  end;

  ListEnsureEntryCache(pluginContainer, listKind);

  minimalDiffEmpty := False;
  minimalDiffEvaluated := False;
  if gateContainersReused then begin
    if gListMinimalMultisetReady then begin
      minimalDiffEmpty := gListMinimalDiffIsEmpty;
      minimalDiffEvaluated := True;
      // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.minimal_diff_reuse 1
    end;
  end;
  if ListUseNetGate(forwardItms, overridesOnly) then begin
    if RecordHasExternalMaster(e) then begin
      if not minimalDiffEvaluated then begin
        minimalDiffEmpty := ListMinimalDiffEmpty(pluginContainer, addMasterContainer,
          removeMasterContainer, listKind, doAdd, doRemove);
        minimalDiffEvaluated := True;
      end;
    end;
  end else begin
    if forwardItms then begin
      if overridesOnly then begin
        if listKind = ListKindFLST then begin
          if RecordHasExternalMaster(e) then begin
            if not minimalDiffEvaluated then begin
              minimalDiffEmpty := ListMinimalDiffEmpty(pluginContainer, addMasterContainer,
                removeMasterContainer, listKind, doAdd, doRemove);
              minimalDiffEvaluated := True;
            end;
          end;
        end;
      end;
    end;
  end;
  if gateContainersReused then begin
    if gListGateFlagsValid then
      needsContainerDiff := gListGateNeedsContainerDiff
    else
      needsContainerDiff := ListRecordNeedsContainerDiff(e, pluginContainer,
        addMasterContainer, listKind, forwardItms);
  end else if listKind = ListKindFLST then
    needsContainerDiff := ListFlstIndexDiffers(pluginContainer, addMasterContainer)
  else
    needsContainerDiff := ListRecordNeedsContainerDiff(e, pluginContainer,
      addMasterContainer, listKind, forwardItms);
  if not needsContainerDiff then begin
    allowNoIndexDiff := False;
    if listKind = ListKindLVLI then begin
      ListEnsureLvliFlagsExportableCached(e, master, lvliFlagsKnown, lvliFlagsExportable);
      if lvliFlagsExportable then
        allowNoIndexDiff := True;
    end;
    if not allowNoIndexDiff then begin
      if ListUseNetGate(forwardItms, overridesOnly) then begin
        if RecordHasExternalMaster(e) then begin
          if not minimalDiffEmpty then
            allowNoIndexDiff := True;
        end;
      end else begin
        if forwardItms then begin
          if overridesOnly then begin
            if listKind = ListKindFLST then begin
              if RecordHasExternalMaster(e) then begin
                if not minimalDiffEmpty then
                  allowNoIndexDiff := True;
              end;
            end;
          end;
        end;
      end;
    end;
    if not allowNoIndexDiff then begin
      if listKind = ListKindLVLI then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.nodiff.skip.lvli 1
      end else if listKind = ListKindCONT then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.nodiff.skip.cont 1
      end else begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.nodiff.skip.flst 1
      end;
      Exit;
    end;
  end;

  skipListDiff := False;
  if ListUseNetGate(forwardItms, overridesOnly) then begin
    if RecordHasExternalMaster(e) then begin
      if minimalDiffEmpty then begin
        skipListDiff := True;
        // DEBUG_INJECT_PERFMON_COUNTER count.list.minimal.skip 1
        if listKind = ListKindLVLI then begin
          ListEnsureLvliFlagsExportableCached(e, master, lvliFlagsKnown, lvliFlagsExportable);
          if lvliFlagsExportable then
            skipListDiff := False;
        end;
      end;
    end;
  end;

  editorID := RecordEditorId(e);
  filterPrefix := ListFilterPrefix(e, listKind);

  ListEnsureScratchEmitLines;
  if not skipListDiff then
    ListDiffToLines(e, gListScratchEmitLines, listKind, doAdd, doRemove,
      forwardItms, overridesOnly, filterPrefix, pluginContainer, addMasterContainer,
      removeMasterContainer);

  if doAdd then begin
    if listKind = ListKindLVLI then begin
      ListEnsureLvliFlagsExportableCached(e, master, lvliFlagsKnown, lvliFlagsExportable);
      ListAppendLvlifFlagsIfNeeded(e, master, gListScratchEmitLines, filterPrefix);
    end;
  end;

  hasData := ListLinesHaveData(gListScratchEmitLines, listKind);
  if not hasData then begin
    if listKind = ListKindLVLI then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.nodata.skip.lvli 1
    end else if listKind = ListKindCONT then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.nodata.skip.cont 1
    end else begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.nodata.skip.flst 1
    end;
    Exit;
  end;

  if skipListDiff then begin
    if listKind = ListKindLVLI then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.lvli.flag.only 1
    end;
  end;

  if gRestorationMode then
    ListMidChainFilterEmitLines(e, listKind, gListScratchEmitLines);

  IniWriterWriteRecordLines(pluginName,
    RecordComment(editorID, pluginName, sig, e, shortComment), gListScratchEmitLines);
  // DEBUG_INJECT_PERFMON_COUNTER count.list.emitted 1
end;

//============================================================================
function ListFlstGateOverride(e: IInterface; forwardItms, overridesOnly,
  doAdd, doRemove: boolean): boolean;
begin
  Result := ShouldProcessListOverride(e, ListKindFLST, forwardItms,
    overridesOnly, doAdd, doRemove);
end;

//============================================================================
procedure ListFlstExportRecord(e: IInterface; doAdd, doRemove, forwardItms,
  overridesOnly, shortComment: boolean);
begin
  ExportListRecord(e, ListKindFLST, doAdd, doRemove,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function ListLvliGateOverride(e: IInterface; forwardItms, overridesOnly,
  doAdd, doRemove: boolean): boolean;
begin
  Result := ShouldProcessListOverride(e, ListKindLVLI, forwardItms,
    overridesOnly, doAdd, doRemove);
end;

//============================================================================
procedure ListLvliExportRecord(e: IInterface; doAdd, doRemove, forwardItms,
  overridesOnly, shortComment: boolean);
begin
  ExportListRecord(e, ListKindLVLI, doAdd, doRemove,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function ListContGateOverride(e: IInterface; forwardItms, overridesOnly,
  doAdd, doRemove: boolean): boolean;
begin
  Result := ShouldProcessListOverride(e, ListKindCONT, forwardItms,
    overridesOnly, doAdd, doRemove);
end;

//============================================================================
procedure ListContExportRecord(e: IInterface; doAdd, doRemove, forwardItms,
  overridesOnly, shortComment: boolean);
begin
  ExportListRecord(e, ListKindCONT, doAdd, doRemove,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ListGateAndExportRecord(e: IInterface; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  case listKind of
    ListKindFLST: begin
      if not ListFlstGateOverride(e, forwardItms, overridesOnly, doAdd, doRemove) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.skip 1
        Exit;
      end;
      ListFlstExportRecord(e, doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    end;
    ListKindLVLI: begin
      if not ListLvliGateOverride(e, forwardItms, overridesOnly, doAdd, doRemove) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.skip 1
        Exit;
      end;
      ListLvliExportRecord(e, doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    end;
    ListKindCONT: begin
      if not ListContGateOverride(e, forwardItms, overridesOnly, doAdd, doRemove) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.skip 1
        Exit;
      end;
      ListContExportRecord(e, doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    end;
  end;
end;

//============================================================================
procedure ExportPluginsList(slSelected: TStringList; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  i, j, loopLast, grpLast: integer;
  f, grp, e: IInterface;
  pluginName, sig: string;
begin
  sig := ListRecordSig(listKind);
  if sig = '' then
    Exit;

  loopLast := LoopLastIndex(slSelected.Count);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    if i >= slSelected.Count then
      Continue;
    f := ObjectToElement(slSelected.Objects[i]);
    pluginName := GetFileName(f);
    grp := GroupBySignature(f, sig);
    if not Assigned(grp) then
      Continue;
    if overridesOnly then begin
      if not PluginGroupHasOverridesCachedGrp(f, sig, grp) then
        Continue;
    end;
    grpLast := LoopLastIndex(ElementCount(grp));
    if grpLast >= 0 then
      for j := 0 to grpLast do begin
        e := ElementByIndex(grp, j);
        if Signature(e) <> sig then
          Continue;
        ListGateAndExportRecord(e, listKind, doAdd, doRemove,
          forwardItms, overridesOnly, shortComment);
      end;
    ProgressReportPlugin(pluginName, i);
  end;
end;

//============================================================================
procedure ExportPluginsListGroup(slSelected: TStringList; f: IInterface;
  listKind: integer; doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  j, loopLast: integer;
  grp, e: IInterface;
  sig: string;
begin
  sig := ListRecordSig(listKind);
  if sig = '' then
    Exit;
  grp := GroupBySignature(f, sig);
  if not Assigned(grp) then
    Exit;
  if overridesOnly then begin
    if not PluginGroupHasOverridesCachedGrp(f, sig, grp) then
      Exit;
  end;
  loopLast := LoopLastIndex(ElementCount(grp));
  if loopLast < 0 then
    Exit;
  for j := 0 to loopLast do begin
    e := ElementByIndex(grp, j);
    if Signature(e) <> sig then
      Continue;
    ListGateAndExportRecord(e, listKind, doAdd, doRemove,
      forwardItms, overridesOnly, shortComment);
  end;
end;

//============================================================================
procedure ExportPluginsLvli(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsList(slSelected, ListKindLVLI,
    doAdd, doRemove, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsCont(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsList(slSelected, ListKindCONT,
    doAdd, doRemove, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsFlst(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsList(slSelected, ListKindFLST,
    doAdd, doRemove, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsLeveledListAndContainers(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  i, loopLast: integer;
  f: IInterface;
  pluginName: string;
begin
  loopLast := LoopLastIndex(slSelected.Count);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    if i >= slSelected.Count then
      Continue;
    f := ObjectToElement(slSelected.Objects[i]);
    pluginName := GetFileName(f);
    ExportPluginsListGroup(slSelected, f, ListKindLVLI,
      doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    ExportPluginsListGroup(slSelected, f, ListKindCONT,
      doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    ProgressReportPlugin(pluginName, i);
  end;
end;


end.
