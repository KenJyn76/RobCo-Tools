unit RobCoListExport;

const
  RobCoListKindLVLI = 0;
  RobCoListKindCONT = 1;
  RobCoListKindFLST = 2;

  LVLF_CalcForLevel = $01;
  LVLF_CalcEachItem = $02;
  LVLF_UseAll = $04;

var
  gRobCoListScratchPluginMultiset: TStringList;
  gRobCoListScratchMasterMultiset: TStringList;
  gRobCoListScratchFlstOld: TStringList;
  gRobCoListScratchFlstNew: TStringList;
  gRobCoListScratchPluginRem: TStringList;
  gRobCoListScratchPluginAdd: TStringList;
  gRobCoListScratchMasterAdd: TStringList;
  gRobCoListScratchMinimalKeys: TStringList;
  gRobCoListScratchEmitLines: TStringList;
  gRobCoListScratchEntryItemRef: TStringList;
  gRobCoListScratchEntryAddKey: TStringList;
  gRobCoListScratchEntryRemoveKey: TStringList;
  gRobCoListScratchMasterEntryAddKey: TStringList;
  gRobCoListScratchMasterEntryRemoveKey: TStringList;
  gRobCoListScratchMasterSideItemRef: TStringList;
  gRobCoListScratchMasterSideItemSeen: TStringList;
  gRobCoListScratchMasterSideAddKey: TStringList;
  gRobCoListScratchMasterSideRemoveKey: TStringList;
  gRobCoListEntryCacheCount: integer;
  gRobCoListMasterSideCacheCount: integer;
  gRobCoListMasterSideCacheKey: string;
  gRobCoListEntryCacheContainerKey: string;
  gRobCoListMasterEntryCacheCount: integer;
  gRobCoListMasterEntryCacheContainerKey: string;
  gRobCoListEntryCacheLocked: boolean;
  gRobCoListMasterEntryCacheLocked: boolean;

  gRobCoListCachedEntryRefPath: string;
  gRobCoListCachedEntryLevelPath: string;
  gRobCoListCachedEntryCountPath: string;
  gRobCoListCachedEntryChancePath: string;
  gRobCoListCachedContainerItemPath: string;
  gRobCoListCachedContainerCountPath: string;

  gRobCoListMinimalMultisetReady: boolean;
  gRobCoListMinimalMultisetHasRemove: boolean;
  gRobCoListMinimalMultisetHasAdd: boolean;
  gRobCoListMinimalDiffIsEmpty: boolean;
  gRobCoListScratchFlstPluginAddKeys: TStringList;
  gRobCoListScratchFlstMasterRem: TStringList;
  gRobCoListScratchFlstPluginRem: TStringList;
  gRobCoListScratchMinimalFlstRemoveEmitKeys: TStringList;
  gRobCoListScratchMinimalFlstAddEmitKeys: TStringList;
  gRobCoListScratchFlstMultisetMap: TStringList;

  gRobCoListGateRecordKey: string;
  gRobCoListGateListKind: integer;
  gRobCoListGatePluginContainer: IInterface;
  gRobCoListGateAddMasterContainer: IInterface;
  gRobCoListGateRemoveMasterContainer: IInterface;
  gRobCoListGateContainersReady: boolean;
  gRobCoListGateNeedsContainerDiff: boolean;
  gRobCoListGateFlagsValid: boolean;

//============================================================================
procedure RobCoListEnsurePathCache;
begin
  if gRobCoListCachedEntryRefPath <> '' then
    Exit;
  gRobCoListCachedEntryRefPath := RobCoListEntryRefPath;
  gRobCoListCachedEntryLevelPath := RobCoListEntryLevelPath;
  gRobCoListCachedEntryCountPath := RobCoListEntryCountPath;
  gRobCoListCachedEntryChancePath := RobCoListEntryChancePath;
  gRobCoListCachedContainerItemPath := RobCoListContainerItemPath;
  gRobCoListCachedContainerCountPath := RobCoListContainerCountPath;
end;

//============================================================================
function RobCoListEntryContainerKey(container: IInterface): string;
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
  Result := RobCoPluginNameForRecord(owner) + '|' + RobCoPatchFilterFormIDRef(owner) + '|' +
    containerName;
end;

//============================================================================
procedure RobCoListClearEntryCache;
begin
  gRobCoListEntryCacheCount := 0;
  gRobCoListEntryCacheContainerKey := '';
  gRobCoListEntryCacheLocked := False;
  if Assigned(gRobCoListScratchEntryItemRef) then
    gRobCoListScratchEntryItemRef.Clear;
  if Assigned(gRobCoListScratchEntryAddKey) then
    gRobCoListScratchEntryAddKey.Clear;
  if Assigned(gRobCoListScratchEntryRemoveKey) then
    gRobCoListScratchEntryRemoveKey.Clear;
end;

//============================================================================
procedure RobCoListClearMasterEntryCache;
begin
  gRobCoListMasterEntryCacheCount := 0;
  gRobCoListMasterEntryCacheContainerKey := '';
  gRobCoListMasterEntryCacheLocked := False;
  if Assigned(gRobCoListScratchMasterEntryAddKey) then
    gRobCoListScratchMasterEntryAddKey.Clear;
  if Assigned(gRobCoListScratchMasterEntryRemoveKey) then
    gRobCoListScratchMasterEntryRemoveKey.Clear;
end;

//============================================================================
procedure RobCoListBuildEntryCache(container: IInterface; listKind: integer);
var
  i, n, level, count, chance: integer;
  ent: IInterface;
  ref: IInterface;
  itemRef, addKey, removeKey: string;
begin
  RobCoListClearEntryCache;
  if not Assigned(container) then
    Exit;
  RobCoListEnsurePathCache;
  if not Assigned(gRobCoListScratchEntryItemRef) then
    gRobCoListScratchEntryItemRef := TStringList.Create;
  if not Assigned(gRobCoListScratchEntryAddKey) then
    gRobCoListScratchEntryAddKey := TStringList.Create;
  if not Assigned(gRobCoListScratchEntryRemoveKey) then
    gRobCoListScratchEntryRemoveKey := TStringList.Create;
  n := ElementCount(container);
  gRobCoListEntryCacheCount := n;
  gRobCoListEntryCacheContainerKey := RobCoListEntryContainerKey(container);
  if n > 0 then begin
    for i := 0 to Pred(n) do begin
      ent := ElementByIndex(container, i);
    itemRef := '';
    addKey := '';
    removeKey := '';
    case listKind of
      RobCoListKindLVLI: begin
        ref := LinksTo(ElementByPath(ent, gRobCoListCachedEntryRefPath));
        if Assigned(ref) then begin
          itemRef := RobCoMasterFormIDRef(ref);
          level := Round(GetElementNativeValues(ent, gRobCoListCachedEntryLevelPath));
          count := Round(GetElementNativeValues(ent, gRobCoListCachedEntryCountPath));
          chance := Round(GetElementNativeValues(ent, gRobCoListCachedEntryChancePath));
          if FormIDRef(ref) <> '' then
            addKey := FormIDRef(ref) + '~' + IntToStr(level) + '~' + IntToStr(count) + '~' +
              IntToStr(chance);
          if itemRef <> '' then
            removeKey := itemRef + '~' + IntToStr(level) + '~' + IntToStr(count);
        end;
      end;
      RobCoListKindCONT: begin
        ref := LinksTo(ElementByPath(ent, gRobCoListCachedContainerItemPath));
        if Assigned(ref) then begin
          itemRef := RobCoMasterFormIDRef(ref);
          count := Round(GetElementNativeValues(ent, gRobCoListCachedContainerCountPath));
          if FormIDRef(ref) <> '' then
            addKey := FormIDRef(ref) + '~' + IntToStr(count);
          if itemRef <> '' then
            removeKey := itemRef;
        end;
      end;
      RobCoListKindFLST: begin
        ref := LinksTo(ent);
        if Assigned(ref) then begin
          itemRef := RobCoMasterFormIDRef(ref);
          if FormIDRef(ref) <> '' then
            addKey := FormIDRef(ref);
          if itemRef <> '' then
            removeKey := itemRef;
        end;
      end;
    end;
    gRobCoListScratchEntryItemRef.Add(itemRef);
    gRobCoListScratchEntryAddKey.Add(addKey);
      gRobCoListScratchEntryRemoveKey.Add(removeKey);
    end;
  end;
  gRobCoListEntryCacheLocked := True;
end;

//============================================================================
procedure RobCoListEnsureEntryCache(container: IInterface; listKind: integer);
begin
  if not Assigned(container) then
    Exit;
  if gRobCoListEntryCacheLocked then begin
    if gRobCoListEntryCacheCount > 0 then begin
      if gRobCoListEntryCacheCount = ElementCount(container) then begin
        if RobCoListEntryContainerKey(container) = gRobCoListEntryCacheContainerKey then
          Exit;
      end;
    end;
  end else begin
    if gRobCoListEntryCacheCount > 0 then begin
      if RobCoListEntryContainerKey(container) = gRobCoListEntryCacheContainerKey then
        Exit;
    end;
  end;
  RobCoListBuildEntryCache(container, listKind);
end;

//============================================================================
procedure RobCoListBuildMasterEntryCache(container: IInterface; listKind: integer);
var
  i, n, level, count, chance: integer;
  ent: IInterface;
  ref: IInterface;
  addKey, removeKey: string;
begin
  RobCoListClearMasterEntryCache;
  if not Assigned(container) then
    Exit;
  RobCoListEnsurePathCache;
  if not Assigned(gRobCoListScratchMasterEntryAddKey) then
    gRobCoListScratchMasterEntryAddKey := TStringList.Create;
  if not Assigned(gRobCoListScratchMasterEntryRemoveKey) then
    gRobCoListScratchMasterEntryRemoveKey := TStringList.Create;
  n := ElementCount(container);
  gRobCoListMasterEntryCacheCount := n;
  gRobCoListMasterEntryCacheContainerKey := RobCoListEntryContainerKey(container);
  if n > 0 then begin
    for i := 0 to Pred(n) do begin
      ent := ElementByIndex(container, i);
      addKey := '';
      removeKey := '';
      case listKind of
        RobCoListKindLVLI: begin
          ref := LinksTo(ElementByPath(ent, gRobCoListCachedEntryRefPath));
          if Assigned(ref) then begin
            level := Round(GetElementNativeValues(ent, gRobCoListCachedEntryLevelPath));
            count := Round(GetElementNativeValues(ent, gRobCoListCachedEntryCountPath));
            chance := Round(GetElementNativeValues(ent, gRobCoListCachedEntryChancePath));
            if FormIDRef(ref) <> '' then
              addKey := FormIDRef(ref) + '~' + IntToStr(level) + '~' + IntToStr(count) + '~' +
                IntToStr(chance);
            removeKey := RobCoListEntryRemoveKey(ent, listKind);
          end;
        end;
        RobCoListKindCONT: begin
          ref := LinksTo(ElementByPath(ent, gRobCoListCachedContainerItemPath));
          if Assigned(ref) then begin
            count := Round(GetElementNativeValues(ent, gRobCoListCachedContainerCountPath));
            if FormIDRef(ref) <> '' then
              addKey := FormIDRef(ref) + '~' + IntToStr(count);
            removeKey := RobCoListEntryRemoveKey(ent, listKind);
          end;
        end;
        RobCoListKindFLST: begin
          ref := LinksTo(ent);
          if Assigned(ref) then begin
            if FormIDRef(ref) <> '' then
              addKey := FormIDRef(ref);
            removeKey := RobCoListEntryRemoveKey(ent, listKind);
          end;
        end;
      end;
      gRobCoListScratchMasterEntryAddKey.Add(addKey);
      gRobCoListScratchMasterEntryRemoveKey.Add(removeKey);
    end;
  end;
  gRobCoListMasterEntryCacheLocked := True;
end;

//============================================================================
procedure RobCoListEnsureMasterEntryCache(container: IInterface; listKind: integer);
begin
  if not Assigned(container) then
    Exit;
  if gRobCoListMasterEntryCacheLocked then begin
    if gRobCoListMasterEntryCacheCount > 0 then begin
      if gRobCoListMasterEntryCacheCount = ElementCount(container) then begin
        if RobCoListEntryContainerKey(container) = gRobCoListMasterEntryCacheContainerKey then
          Exit;
      end;
    end;
  end else begin
    if gRobCoListMasterEntryCacheCount > 0 then begin
      if RobCoListEntryContainerKey(container) = gRobCoListMasterEntryCacheContainerKey then
        Exit;
    end;
  end;
  RobCoListBuildMasterEntryCache(container, listKind);
end;

//============================================================================
function RobCoListCachedItemRef(index: integer): string;
begin
  Result := RobCoStringListItemAt(gRobCoListScratchEntryItemRef, index);
end;

//============================================================================
function RobCoListCachedAddKey(index: integer): string;
begin
  Result := RobCoStringListItemAt(gRobCoListScratchEntryAddKey, index);
end;

//============================================================================
function RobCoListCachedRemoveKey(index: integer): string;
begin
  Result := RobCoStringListItemAt(gRobCoListScratchEntryRemoveKey, index);
end;

//============================================================================
function RobCoListCachedMasterAddKey(index: integer): string;
begin
  Result := RobCoStringListItemAt(gRobCoListScratchMasterEntryAddKey, index);
end;

//============================================================================
function RobCoListCachedMasterRemoveKey(index: integer): string;
begin
  Result := RobCoStringListItemAt(gRobCoListScratchMasterEntryRemoveKey, index);
end;

//============================================================================
procedure RobCoListEnsureScratchEmitLines;
begin
  if not Assigned(gRobCoListScratchEmitLines) then
    gRobCoListScratchEmitLines := TStringList.Create;
  gRobCoListScratchEmitLines.Clear;
end;

//============================================================================
procedure RobCoListEnsureScratchMultisets;
begin
  if not Assigned(gRobCoListScratchPluginMultiset) then
    gRobCoListScratchPluginMultiset := TStringList.Create;
  if not Assigned(gRobCoListScratchMasterMultiset) then
    gRobCoListScratchMasterMultiset := TStringList.Create;
  RobCoMultisetClear(gRobCoListScratchPluginMultiset);
  RobCoMultisetClear(gRobCoListScratchMasterMultiset);
end;

//============================================================================
procedure RobCoListEnsureScratchFlstReplace;
begin
  if not Assigned(gRobCoListScratchFlstOld) then
    gRobCoListScratchFlstOld := TStringList.Create;
  if not Assigned(gRobCoListScratchFlstNew) then
    gRobCoListScratchFlstNew := TStringList.Create;
  gRobCoListScratchFlstOld.Clear;
  gRobCoListScratchFlstNew.Clear;
end;

//============================================================================
procedure RobCoListResetMinimalDiffCache;
begin
  gRobCoListMinimalMultisetReady := False;
  gRobCoListMinimalMultisetHasRemove := False;
  gRobCoListMinimalMultisetHasAdd := False;
  gRobCoListMinimalDiffIsEmpty := True;
end;

//============================================================================
procedure RobCoListClearGateContainerCache;
begin
  gRobCoListGateRecordKey := '';
  gRobCoListGateListKind := -1;
  gRobCoListGatePluginContainer := nil;
  gRobCoListGateAddMasterContainer := nil;
  gRobCoListGateRemoveMasterContainer := nil;
  gRobCoListGateContainersReady := False;
  gRobCoListGateNeedsContainerDiff := False;
  gRobCoListGateFlagsValid := False;
end;

//============================================================================
function RobCoListBuildGateRecordKey(e: IInterface; listKind: integer): string;
begin
  Result := RobCoPluginNameForRecord(e) + #1 + RobCoPatchFilterFormIDRef(e) + #1 + IntToStr(listKind);
end;

//============================================================================
procedure RobCoListRememberGateContainers(e: IInterface; listKind: integer;
  pluginContainer, addMasterContainer, removeMasterContainer: IInterface;
  needsContainerDiff: boolean);
begin
  gRobCoListGateRecordKey := RobCoListBuildGateRecordKey(e, listKind);
  gRobCoListGateListKind := listKind;
  gRobCoListGatePluginContainer := pluginContainer;
  gRobCoListGateAddMasterContainer := addMasterContainer;
  gRobCoListGateRemoveMasterContainer := removeMasterContainer;
  gRobCoListGateNeedsContainerDiff := needsContainerDiff;
  gRobCoListGateFlagsValid := True;
  gRobCoListGateContainersReady := True;
end;

//============================================================================
function RobCoListTryReuseGateContainers(e: IInterface; listKind: integer;
  var pluginContainer, addMasterContainer, removeMasterContainer: IInterface): boolean;
begin
  Result := False;
  if not gRobCoListGateContainersReady then
    Exit;
  if listKind <> gRobCoListGateListKind then
    Exit;
  if RobCoListBuildGateRecordKey(e, listKind) <> gRobCoListGateRecordKey then
    Exit;
  pluginContainer := gRobCoListGatePluginContainer;
  addMasterContainer := gRobCoListGateAddMasterContainer;
  removeMasterContainer := gRobCoListGateRemoveMasterContainer;
  Result := True;
end;

//============================================================================
procedure RobCoListEnsureFlstMultisetMap;
begin
  if not Assigned(gRobCoListScratchFlstMultisetMap) then begin
    gRobCoListScratchFlstMultisetMap := TStringList.Create;
    gRobCoListScratchFlstMultisetMap.Sorted := True;
    gRobCoListScratchFlstMultisetMap.Duplicates := dupIgnore;
  end;
end;

//============================================================================
procedure RobCoListFlstMultisetMapClear;
begin
  RobCoListEnsureFlstMultisetMap;
  gRobCoListScratchFlstMultisetMap.Clear;
end;

//============================================================================
procedure RobCoListFlstMultisetMapInc(const key: string; counts: TStringList;
  addKeysOut, addKeySource: TStringList; addKeyIndex: integer);
var
  idx, slot, n: integer;
  addKey: string;
begin
  if key = '' then
    Exit;
  if not Assigned(counts) then
    Exit;
  RobCoListEnsureFlstMultisetMap;
  idx := gRobCoListScratchFlstMultisetMap.IndexOf(key);
  if idx < 0 then begin
    counts.AddObject(key, TObject(1));
    gRobCoListScratchFlstMultisetMap.AddObject(key, TObject(counts.Count - 1));
    if Assigned(addKeysOut) then begin
      addKey := '';
      if Assigned(addKeySource) then begin
        if addKeyIndex < addKeySource.Count then
          addKey := addKeySource[addKeyIndex];
      end;
      addKeysOut.Add(addKey);
    end;
  end else begin
    if idx >= gRobCoListScratchFlstMultisetMap.Count then
      Exit;
    slot := Integer(gRobCoListScratchFlstMultisetMap.Objects[idx]);
    if slot < 0 then
      Exit;
    if slot >= counts.Count then
      Exit;
    n := Integer(counts.Objects[slot]);
    counts.Objects[slot] := TObject(n + 1);
  end;
end;

//============================================================================
function RobCoListFlstMasterSideItemRefAt(index: integer): string;
begin
  Result := RobCoStringListItemAt(gRobCoListScratchMasterSideItemRef, index);
end;

//============================================================================
function RobCoListFlstMasterSideRemoveKeyAt(index: integer): string;
begin
  Result := RobCoStringListItemAt(gRobCoListScratchMasterSideRemoveKey, index);
end;

//============================================================================
function RobCoListFlstFirstItemRefMismatch(pluginLimit, masterLimit: integer): integer;
var
  i, shared: integer;
begin
  Result := -1;
  shared := pluginLimit;
  if masterLimit < shared then
    shared := masterLimit;
  if shared > 0 then begin
    for i := 0 to Pred(shared) do begin
      if RobCoListFlstMasterSideItemRefAt(i) <> RobCoListCachedItemRef(i) then begin
        Result := i;
        Exit;
      end;
    end;
  end;
  if pluginLimit <> masterLimit then
    Result := shared;
end;

//============================================================================
function RobCoListFlstTrySuffixMinimalDiff(pluginLimit, masterLimit, startIdx: integer;
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
    if not RobCoListFlstPrefixItemRefsIdentical(startIdx) then begin
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
        RobCoMultisetClear(gRobCoListScratchPluginRem);
        for j := startIdx to Pred(pluginLimit) do begin
          removeKey := RobCoListCachedRemoveKey(j);
          if removeKey <> '' then
            RobCoMultisetInc(gRobCoListScratchPluginRem, removeKey);
        end;
      end;
      RobCoListFlstMultisetMapClear;
      RobCoMultisetClear(gRobCoListScratchFlstMasterRem);
      for i := startIdx to Pred(masterLimit) do begin
        removeKey := RobCoListFlstMasterSideRemoveKeyAt(i);
        if removeKey <> '' then
          RobCoListFlstMultisetMapInc(removeKey, gRobCoListScratchFlstMasterRem, nil, nil, 0);
      end;
      gRobCoListMinimalMultisetHasRemove := True;
loopLast := RobCoLoopLastIndex(gRobCoListScratchFlstMasterRem.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
        removeKey := RobCoStringListItemAt(gRobCoListScratchFlstMasterRem, i);
        if removeKey = '' then
          Continue;
        masterN := RobCoStringListObjectIntAt(gRobCoListScratchFlstMasterRem, i);
        pluginN := 0;
        if startIdx < pluginLimit then
          pluginN := RobCoMultisetCount(gRobCoListScratchPluginRem, removeKey);
        if masterN > pluginN then begin
          emitN := masterN - pluginN;
          gRobCoListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey, TObject(emitN));
          hadDiff := True;
        end;
      end;
    end;
  end;
  if doAdd then begin
    if pluginLimit > startIdx then begin
      RobCoListFlstMultisetMapClear;
      RobCoMultisetClear(gRobCoListScratchPluginAdd);
      gRobCoListScratchFlstPluginAddKeys.Clear;
      for i := startIdx to Pred(pluginLimit) do begin
        removeKey := RobCoListCachedRemoveKey(i);
        if removeKey = '' then
          Continue;
        RobCoListFlstMultisetMapInc(removeKey, gRobCoListScratchPluginAdd,
          gRobCoListScratchFlstPluginAddKeys, gRobCoListScratchEntryAddKey, i);
      end;
      gRobCoListMinimalMultisetHasAdd := True;
      if startIdx > 0 then begin
        RobCoListFlstMultisetMapClear;
        RobCoMultisetClear(gRobCoListScratchMasterAdd);
        for i := 0 to Pred(startIdx) do begin
          removeKey := RobCoListFlstMasterSideRemoveKeyAt(i);
          if removeKey <> '' then
            RobCoListFlstMultisetMapInc(removeKey, gRobCoListScratchMasterAdd, nil, nil, 0);
        end;
      end;
      loopLast := RobCoLoopLastIndex(gRobCoListScratchPluginAdd.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
        removeKey := RobCoStringListItemAt(gRobCoListScratchPluginAdd, i);
        if removeKey = '' then
          Continue;
        pluginN := RobCoStringListObjectIntAt(gRobCoListScratchPluginAdd, i);
        if startIdx > 0 then
          masterN := RobCoMultisetCount(gRobCoListScratchMasterAdd, removeKey)
        else
          masterN := 0;
        if pluginN > masterN then begin
          addKey := RobCoListFlstAddKeyAtMultisetIndex(i);
          if addKey <> '' then begin
            gRobCoListScratchMinimalFlstAddEmitKeys.AddObject(addKey,
              TObject(pluginN - masterN));
            hadDiff := True;
          end;
        end;
      end;
    end;
  end;
  if not hadDiff then begin
    if gRobCoListScratchMinimalFlstRemoveEmitKeys.Count = 0 then begin
      if gRobCoListScratchMinimalFlstAddEmitKeys.Count = 0 then begin
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
function RobCoListFlstMinimalCacheHasEmitWork: boolean;
begin
  Result := False;
  if not gRobCoListMinimalMultisetReady then
    Exit;
  if gRobCoListMinimalMultisetHasRemove then begin
    if gRobCoListScratchMinimalFlstRemoveEmitKeys.Count > 0 then begin
      Result := True;
      Exit;
    end;
  end;
  if gRobCoListMinimalMultisetHasAdd then begin
    if gRobCoListScratchMinimalFlstAddEmitKeys.Count > 0 then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
procedure RobCoListEnsureScratchMinimalDiff;
begin
  if not Assigned(gRobCoListScratchPluginRem) then
    gRobCoListScratchPluginRem := TStringList.Create;
  if not Assigned(gRobCoListScratchPluginAdd) then
    gRobCoListScratchPluginAdd := TStringList.Create;
  if not Assigned(gRobCoListScratchMasterAdd) then
    gRobCoListScratchMasterAdd := TStringList.Create;
  if not Assigned(gRobCoListScratchMinimalKeys) then
    gRobCoListScratchMinimalKeys := TStringList.Create;
  if not Assigned(gRobCoListScratchFlstPluginAddKeys) then
    gRobCoListScratchFlstPluginAddKeys := TStringList.Create;
  if not Assigned(gRobCoListScratchFlstMasterRem) then
    gRobCoListScratchFlstMasterRem := TStringList.Create;
  if not Assigned(gRobCoListScratchFlstPluginRem) then
    gRobCoListScratchFlstPluginRem := TStringList.Create;
  if not Assigned(gRobCoListScratchMinimalFlstRemoveEmitKeys) then
    gRobCoListScratchMinimalFlstRemoveEmitKeys := TStringList.Create;
  if not Assigned(gRobCoListScratchMinimalFlstAddEmitKeys) then
    gRobCoListScratchMinimalFlstAddEmitKeys := TStringList.Create;
  RobCoMultisetClear(gRobCoListScratchPluginRem);
  RobCoMultisetClear(gRobCoListScratchPluginAdd);
  RobCoMultisetClear(gRobCoListScratchMasterAdd);
  RobCoMultisetClear(gRobCoListScratchFlstMasterRem);
  RobCoMultisetClear(gRobCoListScratchFlstPluginRem);
  gRobCoListScratchFlstPluginAddKeys.Clear;
  gRobCoListScratchMinimalKeys.Clear;
  gRobCoListScratchMinimalFlstRemoveEmitKeys.Clear;
  gRobCoListScratchMinimalFlstAddEmitKeys.Clear;
  RobCoListFlstMultisetMapClear;
end;

//============================================================================
function RobCoListContainerName(listKind: integer): string;
begin
  case listKind of
    RobCoListKindLVLI: Result := 'Leveled List Entries';
    RobCoListKindCONT: Result := 'Items';
    RobCoListKindFLST: Result := 'FormIDs';
  else
    Result := '';
  end;
end;

//============================================================================
function RobCoListRecordSig(listKind: integer): string;
begin
  case listKind of
    RobCoListKindLVLI: Result := 'LVLI';
    RobCoListKindCONT: Result := 'CONT';
    RobCoListKindFLST: Result := 'FLST';
  else
    Result := '';
  end;
end;

//============================================================================
function RobCoListFilterConstant(listKind: integer): string;
begin
  case listKind of
    RobCoListKindLVLI: Result := RobCoFilterLLs;
    RobCoListKindCONT: Result := RobCoFilterCONT;
    RobCoListKindFLST: Result := RobCoFilterFormLists;
  else
    Result := '';
  end;
end;

//============================================================================
function RobCoListFilterPrefix(e: IInterface; listKind: integer): string;
var
  editorID: string;
begin
  Result := RobCoListFilterConstant(listKind) + RobCoPatchFilterFormIDRef(e);
  if RobCoSkyrimGame then begin
    if listKind <> RobCoListKindFLST then begin
      editorID := RobCoEditorID(e);
      if editorID <> '' then
        Result := Result + ':filterByEditorIdContains=' + editorID;
    end;
  end;
end;

//============================================================================
function RobCoListLinesHaveData(lines: TStringList; listKind: integer): boolean;
begin
  Result := StringListHasRobCoFilter(lines, RobCoListFilterConstant(listKind));
end;

//============================================================================
function RobCoListLinesHaveAddOps(lines: TStringList; listKind: integer): boolean;
var
  i, loopLast: integer;
  line: string;
begin
  Result := False;
  if not Assigned(lines) then
    Exit;
  loopLast := RobCoLoopLastIndex(lines.Count);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    line := RobCoStringListItemAt(lines, i);
    case listKind of
      RobCoListKindLVLI:
        if Pos(':addToLLs=', line) > 0 then begin
          Result := True;
          Exit;
        end;
      RobCoListKindCONT:
        if Pos(':addToContainers=', line) > 0 then begin
          Result := True;
          Exit;
        end;
      RobCoListKindFLST:
        if Pos(':formsToAdd=', line) > 0 then begin
          Result := True;
          Exit;
        end;
    end;
  end;
end;

//============================================================================
function RobCoListEntryRefPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Reference'
  else
    Result := 'LVLO\Reference';
end;

//============================================================================
function RobCoListEntryLevelPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Level'
  else
    Result := 'LVLO\Level';
end;

//============================================================================
function RobCoListEntryCountPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Count'
  else
    Result := 'LVLO\Count';
end;

//============================================================================
function RobCoListEntryChancePath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Chance None'
  else
    Result := 'LVLO\Chance None';
end;

//============================================================================
function RobCoListContainerItemPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Item'
  else
    Result := 'CNTO\Item';
end;

//============================================================================
function RobCoListContainerCountPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Count'
  else
    Result := 'CNTO\Count';
end;

//============================================================================
function RobCoListAddOpcode(listKind: integer): string;
begin
  case listKind of
    RobCoListKindLVLI: Result := 'addToLLs';
    RobCoListKindCONT: Result := 'addToContainers';
    RobCoListKindFLST: Result := 'formsToAdd';
  else
    Result := '';
  end;
end;

//============================================================================
function RobCoListRemoveOpcode(listKind: integer): string;
begin
  case listKind of
    RobCoListKindLVLI: Result := 'removeFromLLs';
    RobCoListKindCONT: Result := 'removeFromContainers';
    RobCoListKindFLST: Result := 'formsToRemove';
  else
    Result := '';
  end;
end;

//============================================================================
function RobCoListEntryLinkedRef(ent: IInterface; listKind: integer): IInterface;
begin
  Result := nil;
  RobCoListEnsurePathCache;
  case listKind of
    RobCoListKindLVLI:
      Result := LinksTo(ElementByPath(ent, gRobCoListCachedEntryRefPath));
    RobCoListKindCONT:
      Result := LinksTo(ElementByPath(ent, gRobCoListCachedContainerItemPath));
    RobCoListKindFLST:
      Result := LinksTo(ent);
  end;
end;

//============================================================================
// Master plugin|id for remove keys and index-aligned FLST replace (vanilla identity).
function RobCoListEntryItemRef(ent: IInterface; listKind: integer): string;
begin
  Result := RobCoMasterFormIDRef(RobCoListEntryLinkedRef(ent, listKind));
end;

//============================================================================
// Owning plugin|id for add keys (golden uses plugin-local ids, e.g. communitytweaksmerged.esp|13C0F1).
function RobCoListEntryAddItemRef(ent: IInterface; listKind: integer): string;
begin
  Result := FormIDRef(RobCoListEntryLinkedRef(ent, listKind));
end;

//============================================================================
function RobCoListEntryRemoveKey(ent: IInterface; listKind: integer): string;
var
  itemRef: string;
  level, count: integer;
begin
  Result := '';
  itemRef := RobCoListEntryItemRef(ent, listKind);
  if itemRef = '' then
    Exit;

  RobCoListEnsurePathCache;
  case listKind of
    RobCoListKindLVLI: begin
      level := Round(GetElementNativeValues(ent, gRobCoListCachedEntryLevelPath));
      count := Round(GetElementNativeValues(ent, gRobCoListCachedEntryCountPath));
      Result := itemRef + '~' + IntToStr(level) + '~' + IntToStr(count);
    end;
    RobCoListKindCONT, RobCoListKindFLST:
      Result := itemRef;
  end;
end;

//============================================================================
function RobCoListEntryAddKey(ent: IInterface; listKind: integer): string;
var
  itemRef: string;
  level, count, chance: integer;
begin
  Result := '';
  itemRef := RobCoListEntryAddItemRef(ent, listKind);
  if itemRef = '' then
    Exit;

  RobCoListEnsurePathCache;
  case listKind of
    RobCoListKindLVLI: begin
      level := Round(GetElementNativeValues(ent, gRobCoListCachedEntryLevelPath));
      count := Round(GetElementNativeValues(ent, gRobCoListCachedEntryCountPath));
      chance := Round(GetElementNativeValues(ent, gRobCoListCachedEntryChancePath));
      Result := itemRef + '~' + IntToStr(level) + '~' + IntToStr(count) + '~' + IntToStr(chance);
    end;
    RobCoListKindCONT: begin
      count := Round(GetElementNativeValues(ent, gRobCoListCachedContainerCountPath));
      Result := itemRef + '~' + IntToStr(count);
    end;
    RobCoListKindFLST:
      Result := itemRef;
  end;
end;

//============================================================================
function RobCoListAddLineValue(ent: IInterface; listKind: integer): string;
begin
  Result := RobCoListEntryAddKey(ent, listKind);
end;

//============================================================================
procedure RobCoListBuildMultiset(container: IInterface; sl: TStringList; listKind: integer; forAdd: boolean);
var
  i, n: integer;
  ent: IInterface;
  key: string;
begin
  if not Assigned(container) then
    Exit;

  RobCoListFlstMultisetMapClear;
  RobCoMultisetClear(sl);
  n := ElementCount(container);
  if n <= 0 then
    Exit;
  if (n = gRobCoListEntryCacheCount) and
    (RobCoListEntryContainerKey(container) = gRobCoListEntryCacheContainerKey) then begin
    for i := 0 to Pred(n) do begin
      if forAdd then
        key := RobCoListCachedAddKey(i)
      else
        key := RobCoListCachedRemoveKey(i);
      if key <> '' then
        RobCoListFlstMultisetMapInc(key, sl, nil, nil, 0);
    end;
  end else if (n = gRobCoListMasterEntryCacheCount) and
    (RobCoListEntryContainerKey(container) = gRobCoListMasterEntryCacheContainerKey) then begin
    for i := 0 to Pred(n) do begin
      if forAdd then
        key := RobCoListCachedMasterAddKey(i)
      else
        key := RobCoListCachedMasterRemoveKey(i);
      if key <> '' then
        RobCoListFlstMultisetMapInc(key, sl, nil, nil, 0);
    end;
  end else begin
    for i := 0 to Pred(n) do begin
      ent := ElementByIndex(container, i);
      if forAdd then
        key := RobCoListEntryAddKey(ent, listKind)
      else
        key := RobCoListEntryRemoveKey(ent, listKind);
      if key <> '' then
        RobCoListFlstMultisetMapInc(key, sl, nil, nil, 0);
    end;
  end;
  RobCoMultisetSort(sl);
end;

//============================================================================
function RobCoListGetLVLFFlags(lvli: IInterface): integer;
begin
  if ElementExists(lvli, 'LVLF') then
    Result := GetElementNativeValues(lvli, 'LVLF')
  else if ElementExists(lvli, 'Flags') then
    Result := GetElementNativeValues(lvli, 'Flags')
  else
    Result := 0;
end;

//============================================================================
function RobCoListGetLLCT(lvli: IInterface): integer;
begin
  if ElementExists(lvli, 'LLCT') then
    Result := GetElementNativeValues(lvli, 'LLCT')
  else
    Result := 0;
end;

//============================================================================
function RobCoListLvlifFlagsUnchanged(e, master: IInterface): boolean;
begin
  Result := True;
  if wbGameMode = gmTES4 then
    Exit;
  if not Assigned(master) then
    Exit;
  if RobCoListGetLVLFFlags(e) <> RobCoListGetLVLFFlags(master) then begin
    Result := False;
    Exit;
  end;
  if RobCoListGetLLCT(e) <> RobCoListGetLLCT(master) then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
procedure RobCoListAppendLVLIFlags(lines: TStringList; const filterPrefix: string; lvli: IInterface);
var
  flags, llct: integer;
  flagLine: string;
begin
  if wbGameMode = gmTES4 then
    Exit;

  flags := RobCoListGetLVLFFlags(lvli);
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
    llct := RobCoListGetLLCT(lvli);
    flagLine := flagLine + ':calcUseAll=' + IntToStr(llct);
  end;

  if flagLine <> filterPrefix then
    lines.Add(flagLine);
end;

//============================================================================
function RobCoListFindEntForAddKey(container: IInterface; listKind: integer; const addKey: string): IInterface;
var
  i, loopLast: integer;
  ent: IInterface;
begin
  Result := nil;
  if not Assigned(container) then
    Exit;
  if addKey = '' then
    Exit;

  loopLast := RobCoLoopLastIndex(ElementCount(container));
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    ent := ElementByIndex(container, i);
    if RobCoListEntryAddKey(ent, listKind) = addKey then begin
      Result := ent;
      Exit;
    end;
  end;
end;

//============================================================================
function RobCoListFirstAddKeyForRemoveKey(container: IInterface; listKind: integer;
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
  if gRobCoListEntryCacheLocked then begin
    if gRobCoListEntryCacheCount > 0 then begin
      if RobCoListEntryContainerKey(container) = gRobCoListEntryCacheContainerKey then begin
        for i := 0 to Pred(gRobCoListEntryCacheCount) do begin
          if RobCoListCachedRemoveKey(i) = removeKey then begin
            Result := RobCoListCachedAddKey(i);
            if Result <> '' then
              Exit;
          end;
        end;
        Exit;
      end;
    end;
  end;
  n := gRobCoListEntryCacheCount;
  if (n > 0) then begin
    if RobCoListEntryContainerKey(container) = gRobCoListEntryCacheContainerKey then begin
      for i := 0 to Pred(n) do begin
        if RobCoListCachedRemoveKey(i) = removeKey then begin
          Result := RobCoListCachedAddKey(i);
          if Result <> '' then
            Exit;
        end;
      end;
    end;
  end;
  loopLast := RobCoLoopLastIndex(ElementCount(container));
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    ent := ElementByIndex(container, i);
    if RobCoListEntryRemoveKey(ent, listKind) = removeKey then begin
      Result := RobCoListEntryAddKey(ent, listKind);
      if Result <> '' then
        Exit;
    end;
  end;
end;

//============================================================================
function RobCoListUseNetGate(forwardItms, overridesOnly: boolean): boolean;
begin
  Result := False;
  if forwardItms then
    Exit;
  if not overridesOnly then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoListNetCompareRecordForAdd(e: IInterface; forwardItms, overridesOnly: boolean): IInterface;
begin
  // Net-gate adds diff vs compare baseline (load order or declared masters).
  // Prior-override baseline over-suppressed rows reintroduced by later plugins (e.g.
  // communitytweaksmerged on Fallout4.esm|28667 after UFO4P) and inflated FLST tails
  // (e.g. DLCworkshop02.esm|C1D vs hundreds of UFO4P-local formsToAdd).
  Result := RobCoCompareBaselineRecord(e);
end;

//============================================================================
function RobCoListNetCompareRecordForRemove(e: IInterface; forwardItms, overridesOnly: boolean): IInterface;
begin
  Result := RobCoCompareBaselineRecord(e);
end;

//============================================================================
function RobCoListNetCompareContainerFromRecord(compareRec: IInterface; listKind: integer): IInterface;
var
  containerName: string;
begin
  Result := nil;
  if not Assigned(compareRec) then
    Exit;
  containerName := RobCoListContainerName(listKind);
  if containerName = '' then
    Exit;
  if ElementExists(compareRec, containerName) then
    Result := ElementByName(compareRec, containerName);
end;

//============================================================================
function RobCoListNetCompareAddContainer(e: IInterface; listKind: integer;
  forwardItms, overridesOnly: boolean): IInterface;
begin
  Result := RobCoListNetCompareContainerFromRecord(
    RobCoListNetCompareRecordForAdd(e, forwardItms, overridesOnly), listKind);
end;

//============================================================================
function RobCoListNetCompareRemoveContainer(e: IInterface; listKind: integer;
  forwardItms, overridesOnly: boolean): IInterface;
begin
  Result := RobCoListNetCompareContainerFromRecord(
    RobCoListNetCompareRecordForRemove(e, forwardItms, overridesOnly), listKind);
end;

//============================================================================
function RobCoListContainerIndexIdentical(pluginContainer, masterContainer: IInterface;
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
  RobCoListEnsurePathCache;

  if (pluginCount > 0) and (pluginCount = gRobCoListEntryCacheCount) then begin
    if RobCoListEntryContainerKey(pluginContainer) = gRobCoListEntryCacheContainerKey then begin
      if listKind = RobCoListKindFLST then begin
        RobCoListEnsureFlstSideCache(masterContainer);
        if pluginCount <> gRobCoListMasterSideCacheCount then
          Exit;
        Result := RobCoListFlstPrefixItemRefsIdentical(pluginCount);
        Exit;
      end;
      for j := 0 to Pred(pluginCount) do begin
        entM := ElementByIndex(masterContainer, j);
        if RobCoListCachedAddKey(j) <> RobCoListEntryAddKey(entM, listKind) then
          Exit;
      end;
      Result := True;
      Exit;
    end;
  end;

  if listKind = RobCoListKindFLST then begin
    for i := 0 to Pred(pluginCount) do begin
      entP := ElementByIndex(pluginContainer, i);
      entM := ElementByIndex(masterContainer, i);
      if RobCoListEntryItemRef(entP, listKind) <> RobCoListEntryItemRef(entM, listKind) then
        Exit;
    end;
    Result := True;
    Exit;
  end;

  for i := 0 to Pred(pluginCount) do begin
    entP := ElementByIndex(pluginContainer, i);
    entM := ElementByIndex(masterContainer, i);
    case listKind of
      RobCoListKindLVLI, RobCoListKindCONT: begin
        if RobCoListEntryAddKey(entP, listKind) <> RobCoListEntryAddKey(entM, listKind) then
          Exit;
      end;
    else begin
        if RobCoListEntryItemRef(entP, listKind) <> RobCoListEntryItemRef(entM, listKind) then
          Exit;
      end;
    end;
  end;
  Result := True;
end;

//============================================================================
// Caller must run RobCoShouldProcessOverride in the plugin loop before export.
function RobCoListRecordNeedsContainerDiff(e, pluginContainer, masterContainer: IInterface;
  listKind: integer; forwardItms: boolean): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not forwardItms then begin
    if RobCoRecordHasExternalMaster(e) then begin
      if Assigned(pluginContainer) then begin
        if Assigned(masterContainer) then begin
          if RobCoListContainerIndexIdentical(pluginContainer, masterContainer, listKind) then begin
            if listKind = RobCoListKindLVLI then begin
              master := RobCoCompareBaselineRecord(e);
              if not RobCoListLvlifFlagsUnchanged(e, master) then
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
procedure RobCoListEmitAddLines(pluginContainer, masterContainer: IInterface; lines: TStringList;
  listKind: integer; forwardItms, overridesOnly: boolean;
  const filterPrefix, addOpcode, editorID: string; skipAddKeys: TStringList);
var
  i, emitCount, pluginCount, masterCount, keyCount, loopLast: integer;
  addKey, identityKey, line: string;
  hasMaster, minimalAddDiff, useIdentityKeys: boolean;
begin
  if not Assigned(pluginContainer) then
    Exit;

  hasMaster := Assigned(masterContainer);
  minimalAddDiff := RobCoListUseNetGate(forwardItms, overridesOnly);
  useIdentityKeys := minimalAddDiff;
  if listKind = RobCoListKindFLST then
    useIdentityKeys := False;
  if listKind = RobCoListKindLVLI then
    useIdentityKeys := True;
  if listKind = RobCoListKindCONT then
    useIdentityKeys := True;
  if not minimalAddDiff then
    useIdentityKeys := False;

  RobCoListEnsureScratchMultisets;
  if gRobCoListMinimalMultisetReady and gRobCoListMinimalMultisetHasAdd and minimalAddDiff then
    RobCoMultisetAssign(gRobCoListScratchPluginMultiset, gRobCoListScratchPluginAdd)
  else if useIdentityKeys then
    RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginMultiset, listKind, False)
  else
    RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginMultiset, listKind, True);
  if hasMaster then begin
    RobCoListEnsureMasterEntryCache(masterContainer, listKind);
    if useIdentityKeys then
      RobCoListBuildMultiset(masterContainer, gRobCoListScratchMasterMultiset, listKind, False)
    else
      RobCoListBuildMultiset(masterContainer, gRobCoListScratchMasterMultiset, listKind, True);
  end;

  keyCount := gRobCoListScratchPluginMultiset.Count;
  loopLast := RobCoLoopLastIndex(keyCount);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    identityKey := RobCoStringListItemAt(gRobCoListScratchPluginMultiset, i);
    if identityKey = '' then
      Continue;

    pluginCount := RobCoStringListObjectIntAt(gRobCoListScratchPluginMultiset, i);
    if pluginCount <= 0 then
      pluginCount := RobCoMultisetCount(gRobCoListScratchPluginMultiset, identityKey);
    if hasMaster then
      masterCount := RobCoMultisetCount(gRobCoListScratchMasterMultiset, identityKey)
    else
      masterCount := 0;

    if useIdentityKeys then
      addKey := RobCoListFirstAddKeyForRemoveKey(pluginContainer, listKind, identityKey)
    else
      addKey := identityKey;
    if addKey = '' then
      Continue;

    if forwardItms then begin
      if pluginCount > 0 then
        emitCount := 1
      else
        emitCount := 0;
    end else if not minimalAddDiff then begin
      if pluginCount > 0 then
        emitCount := 1
      else
        emitCount := 0;
    end else if masterCount = 0 then begin
      if pluginCount > 0 then
        emitCount := 1
      else
        emitCount := 0;
    end else if pluginCount > masterCount then
      emitCount := 1
    else
      emitCount := 0;

    if emitCount <= 0 then begin
      Continue;
    end;

    if Assigned(skipAddKeys) then begin
      if RobCoMultisetTryConsume(skipAddKeys, addKey) then
        Continue;
    end;

    if pluginCount > 1 then
      RobCoLogSkippedDuplicate(Format(
        'Skipped %d duplicate(s) in %s',
        [pluginCount - 1, editorID]
      ));

    line := filterPrefix + ':' + addOpcode + '=' + addKey;
    lines.Add(line);
  end;
end;

//============================================================================
function RobCoListLvliPluginHasAddForRemoveKey(pluginContainer: IInterface;
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
  if gRobCoListEntryCacheLocked then begin
    if gRobCoListEntryCacheCount > 0 then begin
      loopLast := RobCoLoopLastIndex(gRobCoListEntryCacheCount);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
        if RobCoListCachedRemoveKey(i) = removeKey then begin
          Result := True;
          Exit;
        end;
      end;
      Exit;
    end;
  end;
  loopLast := RobCoLoopLastIndex(ElementCount(pluginContainer));
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    ent := ElementByIndex(pluginContainer, i);
    if RobCoListEntryRemoveKey(ent, RobCoListKindLVLI) = removeKey then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
procedure RobCoListEmitRemoveLines(pluginContainer, masterContainer: IInterface; lines: TStringList;
  listKind: integer; const filterPrefix: string; useScratchFlst, replacedOld: TStringList);
var
  i, masterN, pluginN, emitN, loopLast: integer;
  removeKey, line: string;
begin
  if not Assigned(masterContainer) then
    Exit;
  if not Assigned(pluginContainer) then
    Exit;

  RobCoListEnsureScratchMultisets;
  if gRobCoListMinimalMultisetReady and gRobCoListMinimalMultisetHasRemove then
    RobCoMultisetAssign(gRobCoListScratchPluginMultiset, gRobCoListScratchPluginRem)
  else
    RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginMultiset, listKind, False);
  RobCoListEnsureMasterEntryCache(masterContainer, listKind);
  RobCoListBuildMultiset(masterContainer, gRobCoListScratchMasterMultiset, listKind, False);

  loopLast := RobCoLoopLastIndex(gRobCoListScratchMasterMultiset.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    removeKey := RobCoStringListItemAt(gRobCoListScratchMasterMultiset, i);
    if removeKey = '' then
      Continue;

    if useScratchFlst then begin
      if Assigned(replacedOld) then begin
        if RobCoMultisetTryConsume(replacedOld, removeKey) then
          Continue;
      end;
    end;

    if listKind = RobCoListKindLVLI then begin
      if RobCoListLvliPluginHasAddForRemoveKey(pluginContainer, removeKey) then
        Continue;
    end;

    masterN := RobCoStringListObjectIntAt(gRobCoListScratchMasterMultiset, i);
    if masterN <= 0 then
      masterN := RobCoMultisetCount(gRobCoListScratchMasterMultiset, removeKey);
    pluginN := RobCoMultisetCount(gRobCoListScratchPluginMultiset, removeKey);
    if masterN <= pluginN then
      Continue;

    emitN := masterN - pluginN;
    while emitN > 0 do begin
      line := filterPrefix + ':' + RobCoListRemoveOpcode(listKind) + '=' + removeKey;
      lines.Add(line);
      Dec(emitN);
    end;
  end;
end;

//============================================================================
procedure RobCoListEmitFlstRemoveLinesFast(pluginContainer, removeMasterContainer: IInterface;
  lines: TStringList; const filterPrefix: string; replacedOld: TStringList);
var
  i, masterN, pluginN, emitN, pluginLimit, masterLimit, loopLast: integer;
  removeKey, line: string;
  masterCounts, pluginCounts: TStringList;
begin
  if not Assigned(removeMasterContainer) then
    Exit;
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(lines) then
    Exit;

  RobCoListEnsureFlstSideCache(removeMasterContainer);
  pluginLimit := gRobCoListEntryCacheCount;
  masterLimit := gRobCoListMasterSideCacheCount;

  if RobCoListFlstOrderedRefsIdentical(pluginLimit, masterLimit) then
    Exit;

  if gRobCoListMinimalMultisetReady and gRobCoListMinimalMultisetHasRemove then begin
    if gRobCoListScratchMinimalFlstRemoveEmitKeys.Count = 0 then
      Exit;
    loopLast := RobCoLoopLastIndex(gRobCoListScratchMinimalFlstRemoveEmitKeys.Count);
    if loopLast >= 0 then
    for i := 0 to loopLast do begin
      removeKey := RobCoStringListItemAt(gRobCoListScratchMinimalFlstRemoveEmitKeys, i);
      if removeKey = '' then
        Continue;
      if Assigned(replacedOld) then begin
        if RobCoMultisetTryConsume(replacedOld, removeKey) then
          Continue;
      end;
      emitN := RobCoStringListObjectIntAt(gRobCoListScratchMinimalFlstRemoveEmitKeys, i);
      while emitN > 0 do begin
        line := filterPrefix + ':' + RobCoListRemoveOpcode(RobCoListKindFLST) + '=' + removeKey;
        lines.Add(line);
        Dec(emitN);
      end;
    end;
    Exit;
  end;

  RobCoListEnsureScratchMultisets;
  RobCoListBuildFlstMasterMultiset(masterLimit, gRobCoListScratchMasterMultiset);
  RobCoListBuildFlstEntryMultiset(pluginLimit, gRobCoListScratchPluginMultiset, nil);
  masterCounts := gRobCoListScratchMasterMultiset;
  pluginCounts := gRobCoListScratchPluginMultiset;

  loopLast := RobCoLoopLastIndex(masterCounts.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    removeKey := RobCoStringListItemAt(masterCounts, i);
    if removeKey = '' then
      Continue;

    if Assigned(replacedOld) then begin
      if RobCoMultisetTryConsume(replacedOld, removeKey) then
          Continue;
    end;

    masterN := RobCoStringListObjectIntAt(masterCounts, i);
    pluginN := RobCoMultisetCount(pluginCounts, removeKey);
    if masterN <= pluginN then
      Continue;

    emitN := masterN - pluginN;
    while emitN > 0 do begin
      line := filterPrefix + ':' + RobCoListRemoveOpcode(RobCoListKindFLST) + '=' + removeKey;
      lines.Add(line);
      Dec(emitN);
    end;
  end;
end;

//============================================================================
procedure RobCoListEmitFlstAddLinesFast(pluginContainer, addMasterContainer: IInterface;
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
  minimalAddDiff := RobCoListUseNetGate(forwardItms, overridesOnly);
  if hasMaster then
    RobCoListEnsureFlstSideCache(addMasterContainer);

  pluginLimit := gRobCoListEntryCacheCount;
  masterLimit := 0;
  if hasMaster then
    masterLimit := gRobCoListMasterSideCacheCount;

  if minimalAddDiff then begin
    if hasMaster then begin
      if RobCoListFlstOrderedRefsIdentical(pluginLimit, masterLimit) then
        Exit;
    end else begin
      if pluginLimit <= 0 then
        Exit;
    end;
  end else begin
    if pluginLimit <= 0 then
      Exit;
  end;

  if minimalAddDiff and gRobCoListMinimalMultisetReady and gRobCoListMinimalMultisetHasAdd then begin
    if gRobCoListScratchMinimalFlstAddEmitKeys.Count = 0 then
      Exit;
    loopLast := RobCoLoopLastIndex(gRobCoListScratchMinimalFlstAddEmitKeys.Count);
    if loopLast >= 0 then
    for i := 0 to loopLast do begin
      addKey := RobCoStringListItemAt(gRobCoListScratchMinimalFlstAddEmitKeys, i);
      if addKey = '' then
        Continue;
      pluginCount := RobCoStringListObjectIntAt(gRobCoListScratchMinimalFlstAddEmitKeys, i);
      if Assigned(skipAddKeys) then begin
        if RobCoMultisetTryConsume(skipAddKeys, addKey) then
          Continue;
      end;
      if pluginCount > 1 then
        RobCoLogSkippedDuplicate(Format(
          'Skipped %d duplicate(s) in %s',
          [pluginCount - 1, editorID]
        ));
      line := filterPrefix + ':' + addOpcode + '=' + addKey;
      lines.Add(line);
    end;
    Exit;
  end;

  RobCoListEnsureScratchMultisets;
  if gRobCoListMinimalMultisetReady and gRobCoListMinimalMultisetHasAdd and minimalAddDiff then begin
    pluginCounts := gRobCoListScratchPluginAdd;
    masterCounts := gRobCoListScratchMasterAdd;
  end else begin
    RobCoListBuildFlstEntryMultiset(pluginLimit, gRobCoListScratchPluginMultiset,
      gRobCoListScratchFlstPluginAddKeys);
    if hasMaster then
      RobCoListBuildFlstMasterMultiset(masterLimit, gRobCoListScratchMasterMultiset)
    else
      RobCoMultisetClear(gRobCoListScratchMasterMultiset);
    pluginCounts := gRobCoListScratchPluginMultiset;
    masterCounts := gRobCoListScratchMasterMultiset;
  end;

  loopLast := RobCoLoopLastIndex(pluginCounts.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    itemRef := RobCoStringListItemAt(pluginCounts, i);
    if itemRef = '' then
      Continue;

    pluginCount := RobCoStringListObjectIntAt(pluginCounts, i);
    if hasMaster then
      masterCount := RobCoMultisetCount(masterCounts, itemRef)
    else
      masterCount := 0;

    addKey := RobCoListFlstAddKeyAtMultisetIndex(i);
    if addKey = '' then
      Continue;

    if forwardItms then begin
      if pluginCount > 0 then
        emitCount := 1
      else
        emitCount := 0;
    end else if not minimalAddDiff then begin
      if pluginCount > 0 then
        emitCount := 1
      else
        emitCount := 0;
    end else if masterCount = 0 then begin
      if pluginCount > 0 then
        emitCount := 1
      else
        emitCount := 0;
    end else if pluginCount > masterCount then
      emitCount := 1
    else
      emitCount := 0;

    if emitCount <= 0 then
      Continue;

    if Assigned(skipAddKeys) then begin
      if RobCoMultisetTryConsume(skipAddKeys, addKey) then
        Continue;
    end;

    if pluginCount > 1 then
      RobCoLogSkippedDuplicate(Format(
        'Skipped %d duplicate(s) in %s',
        [pluginCount - 1, editorID]
      ));

    line := filterPrefix + ':' + addOpcode + '=' + addKey;
    lines.Add(line);
  end;
end;

//============================================================================
procedure RobCoListAppendLvlifFlagsIfNeeded(e, master: IInterface; lines: TStringList;
  const filterPrefix: string);
begin
  if wbGameMode = gmTES4 then
    Exit;
  if not Assigned(lines) then
    Exit;
  if not ElementExists(e, RobCoListContainerName(RobCoListKindLVLI)) then
    Exit;

  if not RobCoListLvlifFlagsUnchanged(e, master) then
    RobCoListAppendLVLIFlags(lines, filterPrefix, e);
end;

//============================================================================
procedure RobCoListEnsureFlstSideCache(container: IInterface);
var
  key: string;
begin
  if not Assigned(container) then
    Exit;
  key := RobCoListEntryContainerKey(container);
  if (key <> '') and (key = gRobCoListMasterSideCacheKey) and
    (gRobCoListMasterSideCacheCount = ElementCount(container)) then
    Exit;
  RobCoListBuildFlstSideCache(container);
end;

//============================================================================
procedure RobCoListBuildFlstSideCache(container: IInterface);
var
  i, n: integer;
  ent, ref: IInterface;
  itemRef, addKey, removeKey: string;
begin
  gRobCoListMasterSideCacheCount := 0;
  gRobCoListMasterSideCacheKey := '';
  if not Assigned(container) then
    Exit;
  n := ElementCount(container);
  if not Assigned(gRobCoListScratchMasterSideItemRef) then
    gRobCoListScratchMasterSideItemRef := TStringList.Create;
  if not Assigned(gRobCoListScratchMasterSideAddKey) then
    gRobCoListScratchMasterSideAddKey := TStringList.Create;
  if not Assigned(gRobCoListScratchMasterSideRemoveKey) then
    gRobCoListScratchMasterSideRemoveKey := TStringList.Create;
  if not Assigned(gRobCoListScratchMasterSideItemSeen) then
    gRobCoListScratchMasterSideItemSeen := TStringList.Create;
  gRobCoListScratchMasterSideItemRef.Clear;
  gRobCoListScratchMasterSideAddKey.Clear;
  gRobCoListScratchMasterSideRemoveKey.Clear;
  if Assigned(gRobCoListScratchMasterSideItemSeen) then begin
    gRobCoListScratchMasterSideItemSeen.Sorted := False;
    gRobCoListScratchMasterSideItemSeen.Clear;
  end;
  gRobCoListMasterSideCacheCount := n;
  if n > 0 then
    for i := 0 to Pred(n) do begin
    ent := ElementByIndex(container, i);
    itemRef := '';
    addKey := '';
    removeKey := '';
    ref := LinksTo(ent);
    if Assigned(ref) then begin
      itemRef := RobCoMasterFormIDRef(ref);
      if FormIDRef(ref) <> '' then
        addKey := FormIDRef(ref);
      if itemRef <> '' then
        removeKey := itemRef;
    end;
    gRobCoListScratchMasterSideItemRef.Add(itemRef);
    gRobCoListScratchMasterSideAddKey.Add(addKey);
    gRobCoListScratchMasterSideRemoveKey.Add(removeKey);
    if itemRef <> '' then
      gRobCoListScratchMasterSideItemSeen.Add(itemRef);
  end;
  gRobCoListMasterSideCacheKey := RobCoListEntryContainerKey(container);
  if Assigned(gRobCoListScratchMasterSideItemSeen) then
    gRobCoListScratchMasterSideItemSeen.Sorted := True;
end;

//============================================================================
function RobCoListFlstSideCacheHasItemRef(const itemRef: string): boolean;
begin
  Result := False;
  if itemRef = '' then
    Exit;
  if not Assigned(gRobCoListScratchMasterSideItemSeen) then
    Exit;
  Result := gRobCoListScratchMasterSideItemSeen.IndexOf(itemRef) >= 0;
end;

//============================================================================
// True when index-aligned FLST FormIDs differ (requires plugin entry cache).
function RobCoListFlstIndexDiffers(pluginContainer, masterContainer: IInterface): boolean;
var
  pluginCount: integer;
begin
  Result := True;
  if not Assigned(pluginContainer) then
    Exit;
  if gRobCoListEntryCacheCount <= 0 then
    Exit;
  if RobCoListEntryContainerKey(pluginContainer) <> gRobCoListEntryCacheContainerKey then
    Exit;
  pluginCount := gRobCoListEntryCacheCount;
  if not Assigned(masterContainer) then begin
    if pluginCount > 0 then
      Result := True
    else
      Result := False;
    Exit;
  end;
  if pluginCount <> ElementCount(masterContainer) then
    Exit;
  RobCoListEnsureFlstSideCache(masterContainer);
  if RobCoListFlstOrderedRefsIdentical(pluginCount, gRobCoListMasterSideCacheCount) then
    Result := False;
end;

//============================================================================
procedure RobCoListBuildFlstMultisetFromKeys(keys: TStringList; limit: integer; counts: TStringList);
var
  i, loopLast: integer;
begin
  RobCoMultisetClear(counts);
  if not Assigned(keys) then
    Exit;
  if limit <= 0 then
    Exit;
  if limit > keys.Count then
    limit := keys.Count;
  RobCoListFlstMultisetMapClear;
  loopLast := RobCoLoopLastIndex(limit);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do
    RobCoListFlstMultisetMapInc(RobCoStringListItemAt(keys, i), counts, nil, nil, 0);
end;

//============================================================================
procedure RobCoListBuildFlstMultisetFromKeys(keys: TStringList; limit: integer;
  counts, addKeysOut: TStringList; addKeySource: TStringList);
var
  i, loopLast: integer;
  key: string;
begin
  RobCoMultisetClear(counts);
  if Assigned(addKeysOut) then
    addKeysOut.Clear;
  if not Assigned(keys) then
    Exit;
  if limit <= 0 then
    Exit;
  if limit > keys.Count then
    limit := keys.Count;

  loopLast := RobCoLoopLastIndex(limit);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    key := RobCoStringListItemAt(keys, i);
    if key = '' then
      Continue;
    RobCoListFlstMultisetMapInc(key, counts, addKeysOut, addKeySource, i);
  end;
end;

//============================================================================
procedure RobCoListBuildFlstEntryMultiset(limit: integer; counts, addKeysOut: TStringList);
begin
  RobCoListBuildFlstMultisetFromKeys(gRobCoListScratchEntryRemoveKey, limit, counts,
    addKeysOut, gRobCoListScratchEntryAddKey);
end;

//============================================================================
procedure RobCoListBuildFlstMasterMultiset(limit: integer; counts: TStringList);
begin
  RobCoListBuildFlstMultisetFromKeys(gRobCoListScratchMasterSideRemoveKey, limit, counts,
    nil, gRobCoListScratchMasterSideAddKey);
end;

//============================================================================
function RobCoListFlstOrderedRefsIdentical(pluginLimit, masterLimit: integer): boolean;
begin
  Result := False;
  if pluginLimit <> masterLimit then
    Exit;
  if pluginLimit <= 0 then begin
    Result := True;
    Exit;
  end;
  Result := RobCoListFlstPrefixItemRefsIdentical(pluginLimit);
end;

//============================================================================
function RobCoListFlstPrefixRemoveKeysIdentical(sharedCount: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if sharedCount <= 0 then begin
    Result := True;
    Exit;
  end;
  for i := 0 to Pred(sharedCount) do begin
    if RobCoListFlstMasterSideRemoveKeyAt(i) <> RobCoListCachedRemoveKey(i) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function RobCoListFlstPrefixItemRefsIdentical(sharedCount: integer): boolean;
var
  i: integer;
begin
  Result := False;
  if sharedCount <= 0 then begin
    Result := True;
    Exit;
  end;
  for i := 0 to Pred(sharedCount) do begin
    if RobCoListFlstMasterSideItemRefAt(i) <> RobCoListCachedItemRef(i) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function RobCoListFlstAddKeyAtMultisetIndex(index: integer): string;
begin
  Result := RobCoStringListItemAt(gRobCoListScratchFlstPluginAddKeys, index);
end;

//============================================================================
function RobCoListFlstContainersIndexIdentical(pluginContainer, masterContainer: IInterface): boolean;
var
  i, loopLast: integer;
begin
  Result := False;
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(masterContainer) then
    Exit;
  if gRobCoListEntryCacheCount <= 0 then
    Exit;
  RobCoListBuildFlstSideCache(masterContainer);
  if gRobCoListEntryCacheCount <> gRobCoListMasterSideCacheCount then
    Exit;
  loopLast := RobCoLoopLastIndex(gRobCoListEntryCacheCount);
  if loopLast < 0 then begin
    Result := True;
    Exit;
  end;
  for i := 0 to loopLast do begin
    if RobCoListCachedItemRef(i) <> RobCoListFlstMasterSideItemRefAt(i) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function RobCoListFlstPrefixRemoveKeyCount(const removeKey: string; prefixLimit: integer): integer;
var
  i, n: integer;
begin
  n := 0;
  if removeKey = '' then
    Exit;
  if prefixLimit <= 0 then
    Exit;
  for i := 0 to Pred(prefixLimit) do begin
    if RobCoListCachedRemoveKey(i) = removeKey then
      n := n + 1;
  end;
  Result := n;
end;

//============================================================================
procedure RobCoListFlstEnsurePrefixRemoveKeySeen(prefixLimit: integer);
var
  i: integer;
  removeKey: string;
begin
  if not Assigned(gRobCoListScratchMasterSideItemSeen) then
    gRobCoListScratchMasterSideItemSeen := TStringList.Create;
  gRobCoListScratchMasterSideItemSeen.Sorted := False;
  gRobCoListScratchMasterSideItemSeen.Duplicates := dupIgnore;
  gRobCoListScratchMasterSideItemSeen.Clear;
  if prefixLimit <= 0 then begin
    gRobCoListScratchMasterSideItemSeen.Sorted := True;
    Exit;
  end;
  for i := 0 to Pred(prefixLimit) do begin
    removeKey := RobCoListCachedRemoveKey(i);
    if removeKey <> '' then
      gRobCoListScratchMasterSideItemSeen.Add(removeKey);
  end;
  gRobCoListScratchMasterSideItemSeen.Sorted := True;
end;

//============================================================================
function RobCoListFlstTailAddKeysDisjointFromPrefix(tailStart, pluginLimit,
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
  RobCoListFlstEnsurePrefixRemoveKeySeen(prefixLimit);
  for i := tailStart to Pred(pluginLimit) do begin
    removeKey := RobCoListCachedRemoveKey(i);
    if removeKey = '' then
      Continue;
    if gRobCoListScratchMasterSideItemSeen.IndexOf(removeKey) >= 0 then begin
      Result := False;
      Exit;
    end;
  end;
end;

//============================================================================
procedure RobCoListFlstFillTailRemoveEmitKeys(tailStart, masterLimit: integer);
var
  i, masterN, emitN, loopLast: integer;
  removeKey: string;
begin
  RobCoMultisetClear(gRobCoListScratchFlstMasterRem);
  if masterLimit > tailStart then
    for i := tailStart to Pred(masterLimit) do begin
      removeKey := RobCoListFlstMasterSideRemoveKeyAt(i);
      if removeKey <> '' then
        RobCoMultisetInc(gRobCoListScratchFlstMasterRem, removeKey);
    end;
  loopLast := RobCoLoopLastIndex(gRobCoListScratchFlstMasterRem.Count);
  if loopLast >= 0 then
    for i := 0 to loopLast do begin
      removeKey := RobCoStringListItemAt(gRobCoListScratchFlstMasterRem, i);
      if removeKey = '' then
        Continue;
      masterN := RobCoStringListObjectIntAt(gRobCoListScratchFlstMasterRem, i);
      if masterN <= 0 then
        Continue;
      emitN := masterN;
      gRobCoListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey, TObject(emitN));
    end;
end;

//============================================================================
function RobCoListFlstFillTailAddEmitKeys(tailStart, pluginLimit: integer): boolean;
var
  i, pluginN, emitN, loopLast: integer;
  removeKey, addKey: string;
begin
  Result := False;
  if tailStart >= pluginLimit then
    Exit;
  RobCoMultisetClear(gRobCoListScratchPluginAdd);
  gRobCoListScratchFlstPluginAddKeys.Clear;
  for i := tailStart to Pred(pluginLimit) do begin
    removeKey := RobCoListCachedRemoveKey(i);
    addKey := RobCoListCachedAddKey(i);
    if removeKey = '' then
      Continue;
    if addKey = '' then
      Continue;
    RobCoMultisetInc(gRobCoListScratchPluginAdd, removeKey);
    pluginN := RobCoMultisetCount(gRobCoListScratchPluginAdd, removeKey);
    if pluginN = 1 then
      gRobCoListScratchFlstPluginAddKeys.Add(addKey);
  end;
  loopLast := RobCoLoopLastIndex(gRobCoListScratchPluginAdd.Count);
  if loopLast >= 0 then
    for i := 0 to loopLast do begin
      removeKey := RobCoStringListItemAt(gRobCoListScratchPluginAdd, i);
      if removeKey = '' then
        Continue;
      pluginN := RobCoStringListObjectIntAt(gRobCoListScratchPluginAdd, i);
      if pluginN <= 0 then
        Continue;
      addKey := RobCoListFlstAddKeyAtMultisetIndex(i);
      if addKey = '' then
        Continue;
      emitN := pluginN;
      gRobCoListScratchMinimalFlstAddEmitKeys.AddObject(addKey, TObject(emitN));
    end;
  Result := True;
end;

//============================================================================
function RobCoListMinimalDiffEmpty(pluginContainer, addMasterContainer, removeMasterContainer: IInterface;
  listKind: integer; doAdd, doRemove: boolean): boolean;
var
  i, pluginN, masterN, pluginLimit, masterLimit, mismatchIdx, loopLast: integer;
  ent: IInterface;
  removeKey, addKey: string;
  flstSideCached: boolean;
begin
  if gRobCoListMinimalMultisetReady then begin
    Result := gRobCoListMinimalDiffIsEmpty;
    Exit;
  end;

  Result := True;
  if not Assigned(pluginContainer) then begin
    gRobCoListMinimalMultisetReady := True;
    gRobCoListMinimalDiffIsEmpty := True;
    Exit;
  end;

  RobCoListEnsureScratchMinimalDiff;
  flstSideCached := False;
  pluginLimit := gRobCoListEntryCacheCount;
  masterLimit := 0;

  if doRemove then begin
    if Assigned(removeMasterContainer) then begin
      if listKind = RobCoListKindFLST then begin
        RobCoListEnsureFlstSideCache(removeMasterContainer);
        flstSideCached := True;
        masterLimit := gRobCoListMasterSideCacheCount;
        if RobCoListFlstOrderedRefsIdentical(pluginLimit, masterLimit) then begin
          // Ordered refs match; multiset remove diff is empty.
        end else if masterLimit > pluginLimit then begin
          if RobCoListFlstPrefixRemoveKeysIdentical(pluginLimit) then begin
            RobCoListFlstFillTailRemoveEmitKeys(pluginLimit, masterLimit);
            gRobCoListMinimalMultisetHasRemove := True;
            if gRobCoListScratchMinimalFlstRemoveEmitKeys.Count > 0 then
              Result := False;
          end else begin
            mismatchIdx := RobCoListFlstFirstItemRefMismatch(pluginLimit, masterLimit);
            if mismatchIdx >= 0 then begin
              if RobCoListFlstTrySuffixMinimalDiff(pluginLimit, masterLimit, mismatchIdx,
                False, True) then begin
                gRobCoListMinimalMultisetHasRemove := True;
                if gRobCoListScratchMinimalFlstRemoveEmitKeys.Count > 0 then
                  Result := False;
              end else begin
                // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.suffix.fallback 1
                RobCoListBuildFlstMasterMultiset(masterLimit, gRobCoListScratchFlstMasterRem);
                RobCoListBuildFlstEntryMultiset(pluginLimit, gRobCoListScratchFlstPluginRem, nil);
                gRobCoListMinimalMultisetHasRemove := True;
                loopLast := RobCoLoopLastIndex(gRobCoListScratchFlstMasterRem.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
                  removeKey := RobCoStringListItemAt(gRobCoListScratchFlstMasterRem, i);
                  if removeKey = '' then
                    Continue;
                  masterN := RobCoStringListObjectIntAt(gRobCoListScratchFlstMasterRem, i);
                  pluginN := RobCoMultisetCount(gRobCoListScratchFlstPluginRem, removeKey);
                  if masterN > pluginN then begin
                    Result := False;
                    gRobCoListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey,
                      TObject(masterN - pluginN));
                  end;
                end;
              end;
            end else begin
              RobCoListBuildFlstMasterMultiset(masterLimit, gRobCoListScratchFlstMasterRem);
              RobCoListBuildFlstEntryMultiset(pluginLimit, gRobCoListScratchFlstPluginRem, nil);
              gRobCoListMinimalMultisetHasRemove := True;
              loopLast := RobCoLoopLastIndex(gRobCoListScratchFlstMasterRem.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
                removeKey := RobCoStringListItemAt(gRobCoListScratchFlstMasterRem, i);
                if removeKey = '' then
                  Continue;
                masterN := RobCoStringListObjectIntAt(gRobCoListScratchFlstMasterRem, i);
                pluginN := RobCoMultisetCount(gRobCoListScratchFlstPluginRem, removeKey);
                if masterN > pluginN then begin
                  Result := False;
                  gRobCoListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey,
                    TObject(masterN - pluginN));
                end;
              end;
            end;
          end;
        end else begin
          RobCoListBuildFlstMasterMultiset(masterLimit, gRobCoListScratchFlstMasterRem);
          RobCoListBuildFlstEntryMultiset(pluginLimit, gRobCoListScratchFlstPluginRem, nil);
          gRobCoListMinimalMultisetHasRemove := True;
          loopLast := RobCoLoopLastIndex(gRobCoListScratchFlstMasterRem.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
            removeKey := RobCoStringListItemAt(gRobCoListScratchFlstMasterRem, i);
            if removeKey = '' then
              Continue;
            masterN := RobCoStringListObjectIntAt(gRobCoListScratchFlstMasterRem, i);
            pluginN := RobCoMultisetCount(gRobCoListScratchFlstPluginRem, removeKey);
            if masterN > pluginN then begin
              Result := False;
              gRobCoListScratchMinimalFlstRemoveEmitKeys.AddObject(removeKey,
                TObject(masterN - pluginN));
            end;
          end;
        end;
      end else begin
        RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginRem, listKind, False);
        gRobCoListMinimalMultisetHasRemove := True;
        loopLast := RobCoLoopLastIndex(ElementCount(removeMasterContainer));
        if loopLast >= 0 then
          for i := 0 to loopLast do begin
            ent := ElementByIndex(removeMasterContainer, i);
          removeKey := RobCoListEntryRemoveKey(ent, listKind);
          if removeKey = '' then
            Continue;
          if RobCoMultisetCount(gRobCoListScratchPluginRem, removeKey) > 0 then
            Continue;
          Result := False;
          gRobCoListMinimalDiffIsEmpty := False;
          gRobCoListMinimalMultisetReady := True;
          Exit;
        end;
      end;
    end;
  end;

  if not doAdd then begin
    gRobCoListMinimalDiffIsEmpty := Result;
    gRobCoListMinimalMultisetReady := True;
    Exit;
  end;

  if listKind = RobCoListKindFLST then begin
    if Assigned(addMasterContainer) then begin
      if not flstSideCached then begin
        RobCoListEnsureFlstSideCache(addMasterContainer);
        masterLimit := gRobCoListMasterSideCacheCount;
      end else begin
        if removeMasterContainer <> addMasterContainer then begin
          RobCoListEnsureFlstSideCache(addMasterContainer);
          masterLimit := gRobCoListMasterSideCacheCount;
        end;
      end;
      if RobCoListFlstOrderedRefsIdentical(pluginLimit, masterLimit) then begin
        gRobCoListMinimalDiffIsEmpty := Result;
        gRobCoListMinimalMultisetReady := True;
        Exit;
      end;
      if pluginLimit > masterLimit then begin
        if RobCoListFlstPrefixRemoveKeysIdentical(masterLimit) then begin
          if RobCoListFlstTailAddKeysDisjointFromPrefix(masterLimit, pluginLimit, masterLimit) then begin
            if RobCoListFlstFillTailAddEmitKeys(masterLimit, pluginLimit) then begin
              gRobCoListMinimalMultisetHasAdd := True;
              if gRobCoListScratchMinimalFlstAddEmitKeys.Count > 0 then
                Result := False;
              gRobCoListMinimalDiffIsEmpty := Result;
              gRobCoListMinimalMultisetReady := True;
              Exit;
            end;
          end;
        end;
      end;
      mismatchIdx := RobCoListFlstFirstItemRefMismatch(pluginLimit, masterLimit);
      if mismatchIdx >= 0 then begin
        if RobCoListFlstTrySuffixMinimalDiff(pluginLimit, masterLimit, mismatchIdx, True, False) then begin
          gRobCoListMinimalMultisetHasAdd := True;
          if gRobCoListScratchMinimalFlstAddEmitKeys.Count > 0 then
            Result := False;
          gRobCoListMinimalDiffIsEmpty := Result;
          gRobCoListMinimalMultisetReady := True;
          Exit;
        end;
      end;
      // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.suffix.fallback 1
      RobCoListBuildFlstEntryMultiset(pluginLimit, gRobCoListScratchPluginAdd,
        gRobCoListScratchFlstPluginAddKeys);
      RobCoListBuildFlstMasterMultiset(masterLimit, gRobCoListScratchMasterAdd);
      gRobCoListMinimalMultisetHasAdd := True;
      loopLast := RobCoLoopLastIndex(gRobCoListScratchPluginAdd.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
        removeKey := RobCoStringListItemAt(gRobCoListScratchPluginAdd, i);
        if removeKey = '' then
          Continue;
        pluginN := RobCoStringListObjectIntAt(gRobCoListScratchPluginAdd, i);
        masterN := RobCoMultisetCount(gRobCoListScratchMasterAdd, removeKey);
        if pluginN > masterN then begin
          Result := False;
          addKey := RobCoListFlstAddKeyAtMultisetIndex(i);
          if addKey <> '' then
            gRobCoListScratchMinimalFlstAddEmitKeys.AddObject(addKey,
              TObject(pluginN - masterN));
        end;
      end;
    end else if doAdd and (pluginLimit > 0) then begin
      // Master record has no FormIDs container; plugin-local net adds still emit.
      Result := False;
    end;
    gRobCoListMinimalDiffIsEmpty := Result;
    gRobCoListMinimalMultisetReady := True;
    Exit;
  end;

  RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginAdd, listKind, False);
  gRobCoListMinimalMultisetHasAdd := True;
  if Assigned(addMasterContainer) then begin
    RobCoListEnsureMasterEntryCache(addMasterContainer, listKind);
    RobCoListBuildMultiset(addMasterContainer, gRobCoListScratchMasterAdd, listKind, False);
  end else
    gRobCoListScratchMasterAdd.Clear;
  loopLast := RobCoLoopLastIndex(gRobCoListScratchPluginAdd.Count);
      if loopLast >= 0 then
      for i := 0 to loopLast do begin
    removeKey := RobCoStringListItemAt(gRobCoListScratchPluginAdd, i);
    if removeKey = '' then
      Continue;
    pluginN := RobCoStringListObjectIntAt(gRobCoListScratchPluginAdd, i);
    if pluginN <= 0 then
      pluginN := RobCoMultisetCount(gRobCoListScratchPluginAdd, removeKey);
    masterN := RobCoMultisetCount(gRobCoListScratchMasterAdd, removeKey);
    if pluginN > masterN then begin
      Result := False;
      gRobCoListMinimalDiffIsEmpty := False;
      gRobCoListMinimalMultisetReady := True;
      Exit;
    end;
  end;
  gRobCoListMinimalDiffIsEmpty := Result;
  gRobCoListMinimalMultisetReady := True;
end;

//============================================================================
procedure RobCoListEmitFlstReplaceLines(pluginContainer, masterContainer: IInterface;
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

  masterCount := gRobCoListEntryCacheCount;
  if masterCount <> gRobCoListMasterSideCacheCount then
    Exit;
  if masterCount <= 0 then
    Exit;

  RobCoListEnsureFlstSideCache(masterContainer);
  startIdx := RobCoListFlstFirstItemRefMismatch(masterCount, masterCount);
  if startIdx < 0 then
    startIdx := 0;

  for i := startIdx to Pred(masterCount) do begin
    oldRef := RobCoListFlstMasterSideItemRefAt(i);
    newRef := RobCoListCachedItemRef(i);
    if oldRef = '' then
      Continue;
    if newRef = '' then
      Continue;
    if oldRef = newRef then
      Continue;

    // formsToReplace swaps two forms that already exist in the master list.
    // If newRef was not in the master list, emit formsToAdd / formsToRemove instead.
    if not RobCoListFlstSideCacheHasItemRef(newRef) then
      Continue;

    lines.Add(filterPrefix + ':formsToReplace=' + oldRef + '=' + newRef);
    // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.replace 1
    RobCoMultisetInc(replacedOld, oldRef);
    RobCoMultisetInc(replacedNew, newRef);
  end;
end;

//============================================================================
procedure RobCoListDiffToLines(e: IInterface; lines: TStringList; listKind: integer;
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

  containerName := RobCoListContainerName(listKind);
  if containerName = '' then
    Exit;

  if not Assigned(pluginContainer) then begin
    if not ElementExists(e, containerName) then
      Exit;
    pluginContainer := ElementByName(e, containerName);
    addMasterContainer := RobCoListNetCompareAddContainer(e, listKind, forwardItms, overridesOnly);
    removeMasterContainer := RobCoListNetCompareRemoveContainer(e, listKind, forwardItms, overridesOnly);
  end;

  if not Assigned(pluginContainer) then
    Exit;

  addOpcode := RobCoListAddOpcode(listKind);
  editorID := RobCoEditorID(e);

  useScratchFlst := False;

  if listKind = RobCoListKindFLST then begin
    cacheEmit := gRobCoListMinimalMultisetReady and RobCoListFlstMinimalCacheHasEmitWork;
    useScratchFlst := False;

    if cacheEmit then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.diff.cache_emit 1
    end;

    if doAdd then begin
      if doRemove then begin
        if RobCoRecordHasExternalMaster(e) then begin
          if Assigned(addMasterContainer) then begin
            RobCoListEnsureFlstSideCache(addMasterContainer);
            if gRobCoListEntryCacheCount = gRobCoListMasterSideCacheCount then begin
              RobCoListEnsureScratchFlstReplace;
              useScratchFlst := True;
              // DEBUG_INJECT_PERFMON_COUNTER count.list.flst.diff.scratch_replace 1
              RobCoListEmitFlstReplaceLines(pluginContainer, addMasterContainer, lines,
                filterPrefix, gRobCoListScratchFlstOld, gRobCoListScratchFlstNew);
            end;
          end;
        end;
      end;
    end;

    if doRemove then begin
      if RobCoRecordHasExternalMaster(e) then begin
        if Assigned(removeMasterContainer) then begin
          if useScratchFlst then
            RobCoListEmitFlstRemoveLinesFast(pluginContainer, removeMasterContainer, lines,
              filterPrefix, gRobCoListScratchFlstOld)
          else
            RobCoListEmitFlstRemoveLinesFast(pluginContainer, removeMasterContainer, lines,
              filterPrefix, nil);
        end;
      end;
    end;

    if doAdd then begin
      if RobCoRecordHasExternalMaster(e) then begin
        if useScratchFlst then
          RobCoListEmitFlstAddLinesFast(pluginContainer, addMasterContainer, lines,
            forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, gRobCoListScratchFlstNew)
        else
          RobCoListEmitFlstAddLinesFast(pluginContainer, addMasterContainer, lines,
            forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
      end else
        RobCoListEmitFlstAddLinesFast(pluginContainer, nil, lines,
          forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
    end;
    Exit;
  end;

  if not gRobCoListMinimalMultisetReady then
    RobCoListEnsureScratchMultisets;

  if doRemove then begin
    if RobCoRecordHasExternalMaster(e) then begin
      if Assigned(removeMasterContainer) then
        RobCoListEmitRemoveLines(pluginContainer, removeMasterContainer, lines, listKind,
          filterPrefix, False, nil);
    end;
  end;

  if doAdd then begin
    if RobCoRecordHasExternalMaster(e) then
      RobCoListEmitAddLines(pluginContainer, addMasterContainer, lines, listKind,
        forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil)
    else
      RobCoListEmitAddLines(pluginContainer, nil, lines, listKind,
        forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
  end;
end;

//============================================================================
// List export gate: ITM gate + override gate must not use whole-record ITM
// skip, because LVLI/FLST/CONT list edits may be invisible to ConflictAll.
function RobCoShouldProcessListOverride(e: IInterface; listKind: integer;
  forwardItms, overridesOnly, doAdd, doRemove: boolean): boolean;
var
  containerName: string;
  pluginContainer, addMasterContainer, removeMasterContainer, master: IInterface;
begin
  RobCoListResetMinimalDiffCache;
  RobCoListClearGateContainerCache;
  RobCoListClearEntryCache;
  RobCoListClearMasterEntryCache;
  Result := False;
  if not Assigned(e) then
    Exit;
  if not RobCoShouldExportRecord(e, overridesOnly) then
    Exit;
  if forwardItms then begin
    Result := True;
    Exit;
  end;
  if not overridesOnly then begin
    if RobCoRecordUnchangedVsMaster(e) then
      Exit;
    Result := True;
    Exit;
  end;

  containerName := RobCoListContainerName(listKind);
  if containerName = '' then
    Exit;
  pluginContainer := nil;
  addMasterContainer := nil;
  removeMasterContainer := nil;
  master := RobCoCompareBaselineRecord(e);
  if ElementExists(e, containerName) then begin
    pluginContainer := ElementByName(e, containerName);
    addMasterContainer := RobCoListNetCompareAddContainer(e, listKind, forwardItms, overridesOnly);
    removeMasterContainer := RobCoListNetCompareRemoveContainer(e, listKind, forwardItms, overridesOnly);
  end;
  if not Assigned(pluginContainer) then
    Exit;

  RobCoListEnsureEntryCache(pluginContainer, listKind);

  if listKind = RobCoListKindFLST then begin
    if RobCoListFlstIndexDiffers(pluginContainer, addMasterContainer) then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.flst_index_only 1
      RobCoListRememberGateContainers(e, listKind, pluginContainer, addMasterContainer,
        removeMasterContainer, True);
      Result := True;
      Exit;
    end;
  end else begin
    if RobCoListRecordNeedsContainerDiff(e, pluginContainer, addMasterContainer, listKind,
      forwardItms) then begin
      RobCoListRememberGateContainers(e, listKind, pluginContainer, addMasterContainer,
        removeMasterContainer, True);
      Result := True;
      Exit;
    end;

    if listKind = RobCoListKindLVLI then begin
      if not RobCoListLvlifFlagsUnchanged(e, master) then begin
        RobCoListRememberGateContainers(e, listKind, pluginContainer, addMasterContainer,
          removeMasterContainer, False);
        Result := True;
        Exit;
      end;
    end;
  end;

  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  if not RobCoListMinimalDiffEmpty(pluginContainer, addMasterContainer, removeMasterContainer,
    listKind, doAdd, doRemove) then begin
    RobCoListRememberGateContainers(e, listKind, pluginContainer, addMasterContainer,
      removeMasterContainer, False);
    Result := True;
  end;
end;

//============================================================================
procedure RobCoExportListRecord(e: IInterface; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  pluginName, editorID, filterPrefix, sig, containerName, targetRef: string;
  pluginContainer, addMasterContainer, removeMasterContainer, master: IInterface;
  skipListDiff, hasData, needsContainerDiff, allowNoIndexDiff, gateContainersReused,
    minimalDiffEmpty, minimalDiffEvaluated: boolean;
begin
  sig := RobCoListRecordSig(listKind);
  if sig = '' then
    Exit;
  if Signature(e) <> sig then
    Exit;

  if not doAdd then begin
    if not doRemove then
      Exit;
  end;

  if not gRobCoIniWriterActive then
    Exit;

  targetRef := RobCoPatchFilterFormIDRef(e);
  pluginName := RobCoPluginNameForRecord(e);

  containerName := RobCoListContainerName(listKind);
  pluginContainer := nil;
  addMasterContainer := nil;
  removeMasterContainer := nil;
  master := RobCoCompareBaselineRecord(e);
  if not RobCoListTryReuseGateContainers(e, listKind, pluginContainer, addMasterContainer,
    removeMasterContainer) then begin
    gateContainersReused := False;
    if ElementExists(e, containerName) then begin
      pluginContainer := ElementByName(e, containerName);
      addMasterContainer := RobCoListNetCompareAddContainer(e, listKind, forwardItms, overridesOnly);
      removeMasterContainer := RobCoListNetCompareRemoveContainer(e, listKind, forwardItms, overridesOnly);
    end;
  end else
    gateContainersReused := True;

  if not Assigned(pluginContainer) then begin
    if listKind = RobCoListKindLVLI then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.container.skip.lvli 1
    end else if listKind = RobCoListKindCONT then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.container.skip.cont 1
    end else begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.container.skip.flst 1
    end;
    Exit;
  end;

  RobCoListEnsureEntryCache(pluginContainer, listKind);

  minimalDiffEmpty := False;
  minimalDiffEvaluated := False;
  if gateContainersReused then begin
    if gRobCoListMinimalMultisetReady then begin
      minimalDiffEmpty := gRobCoListMinimalDiffIsEmpty;
      minimalDiffEvaluated := True;
      // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.minimal_diff_reuse 1
    end;
  end;
  if RobCoListUseNetGate(forwardItms, overridesOnly) then begin
    if RobCoRecordHasExternalMaster(e) then begin
      if not minimalDiffEvaluated then begin
        minimalDiffEmpty := RobCoListMinimalDiffEmpty(pluginContainer, addMasterContainer,
          removeMasterContainer, listKind, doAdd, doRemove);
        minimalDiffEvaluated := True;
      end;
    end;
  end;
  if gateContainersReused then begin
    if gRobCoListGateFlagsValid then
      needsContainerDiff := gRobCoListGateNeedsContainerDiff
    else
      needsContainerDiff := RobCoListRecordNeedsContainerDiff(e, pluginContainer,
        addMasterContainer, listKind, forwardItms);
  end else if listKind = RobCoListKindFLST then
    needsContainerDiff := RobCoListFlstIndexDiffers(pluginContainer, addMasterContainer)
  else
    needsContainerDiff := RobCoListRecordNeedsContainerDiff(e, pluginContainer,
      addMasterContainer, listKind, forwardItms);
  if not needsContainerDiff then begin
    allowNoIndexDiff := False;
    if listKind = RobCoListKindLVLI then begin
      if not RobCoListLvlifFlagsUnchanged(e, master) then
        allowNoIndexDiff := True;
    end;
    if not allowNoIndexDiff then begin
      if RobCoListUseNetGate(forwardItms, overridesOnly) then begin
        if RobCoRecordHasExternalMaster(e) then begin
          if not minimalDiffEmpty then
            allowNoIndexDiff := True;
        end;
      end;
    end;
    if not allowNoIndexDiff then begin
      if listKind = RobCoListKindLVLI then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.nodiff.skip.lvli 1
      end else if listKind = RobCoListKindCONT then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.nodiff.skip.cont 1
      end else begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.nodiff.skip.flst 1
      end;
      Exit;
    end;
  end;

  skipListDiff := False;
  if RobCoListUseNetGate(forwardItms, overridesOnly) then begin
    if RobCoRecordHasExternalMaster(e) then begin
      if minimalDiffEmpty then begin
        skipListDiff := True;
        // DEBUG_INJECT_PERFMON_COUNTER count.list.minimal.skip 1
        if listKind = RobCoListKindLVLI then begin
          if not RobCoListLvlifFlagsUnchanged(e, master) then
            skipListDiff := False;
        end;
      end;
    end;
  end;

  editorID := RobCoEditorID(e);
  filterPrefix := RobCoListFilterPrefix(e, listKind);

  RobCoListEnsureScratchEmitLines;
  if not skipListDiff then
    RobCoListDiffToLines(e, gRobCoListScratchEmitLines, listKind, doAdd, doRemove,
      forwardItms, overridesOnly, filterPrefix, pluginContainer, addMasterContainer,
      removeMasterContainer);

  if doAdd then begin
    if listKind = RobCoListKindLVLI then
      RobCoListAppendLvlifFlagsIfNeeded(e, master, gRobCoListScratchEmitLines, filterPrefix);
  end;

  hasData := RobCoListLinesHaveData(gRobCoListScratchEmitLines, listKind);
  if not hasData then begin
    if listKind = RobCoListKindLVLI then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.nodata.skip.lvli 1
    end else if listKind = RobCoListKindCONT then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.nodata.skip.cont 1
    end else begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.nodata.skip.flst 1
    end;
    Exit;
  end;

  if skipListDiff then begin
    if listKind = RobCoListKindLVLI then begin
      // DEBUG_INJECT_PERFMON_COUNTER count.list.lvli.flag.only 1
    end;
  end;

  RobCoIniWriterWriteRecordLines(pluginName,
    RobCoRecordComment(editorID, pluginName, sig, e, shortComment), gRobCoListScratchEmitLines);
  // DEBUG_INJECT_PERFMON_COUNTER count.list.emitted 1
end;

//============================================================================
function RobCoListFlstGateOverride(e: IInterface; forwardItms, overridesOnly,
  doAdd, doRemove: boolean): boolean;
begin
  Result := RobCoShouldProcessListOverride(e, RobCoListKindFLST, forwardItms,
    overridesOnly, doAdd, doRemove);
end;

//============================================================================
procedure RobCoListFlstExportRecord(e: IInterface; doAdd, doRemove, forwardItms,
  overridesOnly, shortComment: boolean);
begin
  RobCoExportListRecord(e, RobCoListKindFLST, doAdd, doRemove,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoListLvliGateOverride(e: IInterface; forwardItms, overridesOnly,
  doAdd, doRemove: boolean): boolean;
begin
  Result := RobCoShouldProcessListOverride(e, RobCoListKindLVLI, forwardItms,
    overridesOnly, doAdd, doRemove);
end;

//============================================================================
procedure RobCoListLvliExportRecord(e: IInterface; doAdd, doRemove, forwardItms,
  overridesOnly, shortComment: boolean);
begin
  RobCoExportListRecord(e, RobCoListKindLVLI, doAdd, doRemove,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoListContGateOverride(e: IInterface; forwardItms, overridesOnly,
  doAdd, doRemove: boolean): boolean;
begin
  Result := RobCoShouldProcessListOverride(e, RobCoListKindCONT, forwardItms,
    overridesOnly, doAdd, doRemove);
end;

//============================================================================
procedure RobCoListContExportRecord(e: IInterface; doAdd, doRemove, forwardItms,
  overridesOnly, shortComment: boolean);
begin
  RobCoExportListRecord(e, RobCoListKindCONT, doAdd, doRemove,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoListGateAndExportRecord(e: IInterface; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  case listKind of
    RobCoListKindFLST: begin
      if not RobCoListFlstGateOverride(e, forwardItms, overridesOnly, doAdd, doRemove) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.skip 1
        Exit;
      end;
      RobCoListFlstExportRecord(e, doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    end;
    RobCoListKindLVLI: begin
      if not RobCoListLvliGateOverride(e, forwardItms, overridesOnly, doAdd, doRemove) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.skip 1
        Exit;
      end;
      RobCoListLvliExportRecord(e, doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    end;
    RobCoListKindCONT: begin
      if not RobCoListContGateOverride(e, forwardItms, overridesOnly, doAdd, doRemove) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.list.gate.skip 1
        Exit;
      end;
      RobCoListContExportRecord(e, doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    end;
  end;
end;

//============================================================================
procedure RobCoExportPluginsList(slSelected: TStringList; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  i, j, loopLast, grpLast: integer;
  f, grp, e: IInterface;
  pluginName, sig: string;
begin
  sig := RobCoListRecordSig(listKind);
  if sig = '' then
    Exit;

  loopLast := RobCoLoopLastIndex(slSelected.Count);
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
      if not RobCoPluginGroupHasOverridesCachedGrp(f, sig, grp) then
        Continue;
    end;
    grpLast := RobCoLoopLastIndex(ElementCount(grp));
    if grpLast >= 0 then
      for j := 0 to grpLast do begin
        e := ElementByIndex(grp, j);
        if Signature(e) <> sig then
          Continue;
        RobCoListGateAndExportRecord(e, listKind, doAdd, doRemove,
          forwardItms, overridesOnly, shortComment);
      end;
    RobCoProgressReportPlugin(pluginName, i);
  end;
end;

//============================================================================
procedure RobCoExportPluginsListGroup(slSelected: TStringList; f: IInterface;
  listKind: integer; doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  j, loopLast: integer;
  grp, e: IInterface;
  sig: string;
begin
  sig := RobCoListRecordSig(listKind);
  if sig = '' then
    Exit;
  grp := GroupBySignature(f, sig);
  if not Assigned(grp) then
    Exit;
  if overridesOnly then begin
    if not RobCoPluginGroupHasOverridesCachedGrp(f, sig, grp) then
      Exit;
  end;
  loopLast := RobCoLoopLastIndex(ElementCount(grp));
  if loopLast < 0 then
    Exit;
  for j := 0 to loopLast do begin
    e := ElementByIndex(grp, j);
    if Signature(e) <> sig then
      Continue;
    RobCoListGateAndExportRecord(e, listKind, doAdd, doRemove,
      forwardItms, overridesOnly, shortComment);
  end;
end;

//============================================================================
procedure RobCoExportPluginsLvli(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsList(slSelected, RobCoListKindLVLI,
    doAdd, doRemove, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsCont(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsList(slSelected, RobCoListKindCONT,
    doAdd, doRemove, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsFlst(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsList(slSelected, RobCoListKindFLST,
    doAdd, doRemove, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsLeveledListAndContainers(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  i, loopLast: integer;
  f: IInterface;
  pluginName: string;
begin
  loopLast := RobCoLoopLastIndex(slSelected.Count);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    if i >= slSelected.Count then
      Continue;
    f := ObjectToElement(slSelected.Objects[i]);
    pluginName := GetFileName(f);
    RobCoExportPluginsListGroup(slSelected, f, RobCoListKindLVLI,
      doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    RobCoExportPluginsListGroup(slSelected, f, RobCoListKindCONT,
      doAdd, doRemove, forwardItms, overridesOnly, shortComment);
    RobCoProgressReportPlugin(pluginName, i);
  end;
end;


end.
