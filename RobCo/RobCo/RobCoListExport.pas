{
  LVLI, CONT, and FLST list-diff export.
}
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
  gRobCoListScratchFlstReplaceMs: TStringList;
  gRobCoListScratchEmitLines: TStringList;

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
  gRobCoListScratchPluginMultiset.Clear;
  gRobCoListScratchMasterMultiset.Clear;
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
  gRobCoListScratchPluginRem.Clear;
  gRobCoListScratchPluginAdd.Clear;
  gRobCoListScratchMasterAdd.Clear;
  gRobCoListScratchMinimalKeys.Clear;
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
function RobCoListEntryItemRef(ent: IInterface; listKind: integer): string;
var
  ref: IInterface;
begin
  Result := '';
  case listKind of
    RobCoListKindLVLI:
      ref := LinksTo(ElementByPath(ent, RobCoListEntryRefPath));
    RobCoListKindCONT:
      ref := LinksTo(ElementByPath(ent, RobCoListContainerItemPath));
    RobCoListKindFLST:
      ref := LinksTo(ent);
  else
    Exit;
  end;

  Result := RobCoMasterFormIDRef(ref);
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

  case listKind of
    RobCoListKindLVLI: begin
      level := Round(GetElementNativeValues(ent, RobCoListEntryLevelPath));
      count := Round(GetElementNativeValues(ent, RobCoListEntryCountPath));
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
  itemRef := RobCoListEntryItemRef(ent, listKind);
  if itemRef = '' then
    Exit;

  case listKind of
    RobCoListKindLVLI: begin
      level := Round(GetElementNativeValues(ent, RobCoListEntryLevelPath));
      count := Round(GetElementNativeValues(ent, RobCoListEntryCountPath));
      chance := Round(GetElementNativeValues(ent, RobCoListEntryChancePath));
      Result := itemRef + '~' + IntToStr(level) + '~' + IntToStr(count) + '~' + IntToStr(chance);
    end;
    RobCoListKindCONT: begin
      count := Round(GetElementNativeValues(ent, RobCoListContainerCountPath));
      Result := itemRef + '~' + IntToStr(count);
    end;
    RobCoListKindFLST:
      Result := itemRef;
  end;
end;

//============================================================================
function RobCoListAddLineValue(ent: IInterface; listKind: integer): string;
var
  itemRef: string;
  level, count, chance: integer;
begin
  Result := '';
  itemRef := RobCoListEntryItemRef(ent, listKind);
  if itemRef = '' then
    Exit;

  case listKind of
    RobCoListKindLVLI: begin
      level := Round(GetElementNativeValues(ent, RobCoListEntryLevelPath));
      count := Round(GetElementNativeValues(ent, RobCoListEntryCountPath));
      chance := Round(GetElementNativeValues(ent, RobCoListEntryChancePath));
      Result := itemRef + '~' + IntToStr(level) + '~' + IntToStr(count) + '~' + IntToStr(chance);
    end;
    RobCoListKindCONT: begin
      count := Round(GetElementNativeValues(ent, RobCoListContainerCountPath));
      Result := itemRef + '~' + IntToStr(count);
    end;
    RobCoListKindFLST:
      Result := itemRef;
  end;
end;

//============================================================================
procedure RobCoListBuildMultiset(container: IInterface; sl: TStringList; listKind: integer; forAdd: boolean);
var
  i: integer;
  ent: IInterface;
  key: string;
begin
  if not Assigned(container) then
    Exit;

  for i := 0 to Pred(ElementCount(container)) do begin
    ent := ElementByIndex(container, i);
    if forAdd then
      key := RobCoListEntryAddKey(ent, listKind)
    else
      key := RobCoListEntryRemoveKey(ent, listKind);
    if key <> '' then
      RobCoMultisetInc(sl, key);
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
  i: integer;
  ent: IInterface;
begin
  Result := nil;
  if not Assigned(container) then
    Exit;
  if addKey = '' then
    Exit;

  for i := 0 to Pred(ElementCount(container)) do begin
    ent := ElementByIndex(container, i);
    if RobCoListEntryAddKey(ent, listKind) = addKey then begin
      Result := ent;
      Exit;
    end;
  end;
end;

//============================================================================
function RobCoListMinimalAddDiff(forwardItms, overridesOnly: boolean): boolean;
begin
  Result := False;
  if forwardItms then
    Exit;
  if not overridesOnly then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoListContainerIndexIdentical(pluginContainer, masterContainer: IInterface;
  listKind: integer): boolean;
var
  i, pluginCount: integer;
begin
  Result := False;
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(masterContainer) then
    Exit;
  pluginCount := ElementCount(pluginContainer);
  if pluginCount <> ElementCount(masterContainer) then
    Exit;
  for i := 0 to Pred(pluginCount) do begin
    if RobCoListEntryItemRef(ElementByIndex(pluginContainer, i), listKind) <>
      RobCoListEntryItemRef(ElementByIndex(masterContainer, i), listKind) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
// Caller must run RobCoShouldProcessOverride in the plugin loop before export.
function RobCoListRecordNeedsContainerDiff(e, pluginContainer, masterContainer: IInterface;
  listKind: integer; forwardItms: boolean): boolean;
begin
  Result := False;
  if not forwardItms then begin
    if RobCoRecordHasExternalMaster(e) then begin
      if Assigned(pluginContainer) then begin
        if Assigned(masterContainer) then begin
          if RobCoListContainerIndexIdentical(pluginContainer, masterContainer, listKind) then
            Exit;
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
  i, emitCount, pluginCount, masterCount, keyCount: integer;
  addKey, line: string;
  hasMaster, minimalAddDiff: boolean;
begin
  if not Assigned(pluginContainer) then
    Exit;

  hasMaster := Assigned(masterContainer);
  minimalAddDiff := RobCoListMinimalAddDiff(forwardItms, overridesOnly);

  RobCoListEnsureScratchMultisets;
  RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginMultiset, listKind, True);
  if hasMaster then
    RobCoListBuildMultiset(masterContainer, gRobCoListScratchMasterMultiset, listKind, True);

  keyCount := gRobCoListScratchPluginMultiset.Count;
  for i := 0 to Pred(keyCount) do begin
    addKey := gRobCoListScratchPluginMultiset[i];
    if addKey = '' then
      Continue;

    pluginCount := RobCoMultisetCount(gRobCoListScratchPluginMultiset, addKey);
    if hasMaster then
      masterCount := RobCoMultisetCount(gRobCoListScratchMasterMultiset, addKey)
    else
      masterCount := 0;

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
    end else
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
function RobCoListMinimalDiffEmpty(pluginContainer, masterContainer: IInterface;
  listKind: integer; doAdd, doRemove: boolean): boolean;
var
  i: integer;
  ent: IInterface;
  removeKey, addKey: string;
begin
  Result := True;
  if not Assigned(pluginContainer) then
    Exit;

  RobCoListEnsureScratchMinimalDiff;

  if doRemove then begin
    if Assigned(masterContainer) then begin
      RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginRem, listKind, False);
      for i := 0 to Pred(ElementCount(masterContainer)) do begin
        ent := ElementByIndex(masterContainer, i);
        removeKey := RobCoListEntryRemoveKey(ent, listKind);
        if removeKey = '' then
          Continue;
        if listKind = RobCoListKindFLST then begin
          if i < ElementCount(pluginContainer) then begin
            if RobCoListEntryItemRef(ElementByIndex(pluginContainer, i), listKind) <>
              RobCoListEntryItemRef(ent, listKind) then begin
              Result := False;
              Exit;
            end;
          end;
        end;
        if RobCoMultisetTryConsume(gRobCoListScratchPluginRem, removeKey) then
          Continue;
        Result := False;
        Exit;
      end;
    end;
  end;

  if not Result then
    Exit;
  if not doAdd then
    Exit;

  RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginAdd, listKind, True);
  if Assigned(masterContainer) then
    RobCoListBuildMultiset(masterContainer, gRobCoListScratchMasterAdd, listKind, True);
  for i := 0 to Pred(ElementCount(pluginContainer)) do begin
    ent := ElementByIndex(pluginContainer, i);
    addKey := RobCoListEntryAddKey(ent, listKind);
    if addKey <> '' then begin
      if gRobCoListScratchMinimalKeys.IndexOf(addKey) < 0 then
        gRobCoListScratchMinimalKeys.Add(addKey);
    end;
  end;
  for i := 0 to Pred(gRobCoListScratchMinimalKeys.Count) do begin
    addKey := gRobCoListScratchMinimalKeys[i];
    if RobCoMultisetCount(gRobCoListScratchMasterAdd, addKey) = 0 then begin
      if RobCoMultisetCount(gRobCoListScratchPluginAdd, addKey) > 0 then begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;

//============================================================================
procedure RobCoListEmitFlstReplaceLines(pluginContainer, masterContainer: IInterface;
  lines: TStringList; const filterPrefix: string; replacedOld, replacedNew: TStringList);
var
  i, masterCount: integer;
  entM, entP: IInterface;
  oldRef, newRef: string;
  masterMultiset: TStringList;
begin
  if not Assigned(pluginContainer) then
    Exit;
  if not Assigned(masterContainer) then
    Exit;
  if not Assigned(replacedOld) then
    Exit;
  if not Assigned(replacedNew) then
    Exit;

  masterCount := ElementCount(masterContainer);
  if masterCount <> ElementCount(pluginContainer) then
    Exit;

  if not Assigned(gRobCoListScratchFlstReplaceMs) then
    gRobCoListScratchFlstReplaceMs := TStringList.Create;
  gRobCoListScratchFlstReplaceMs.Clear;
  RobCoListBuildMultiset(masterContainer, gRobCoListScratchFlstReplaceMs, RobCoListKindFLST, True);

  for i := 0 to Pred(masterCount) do begin
      entM := ElementByIndex(masterContainer, i);
      entP := ElementByIndex(pluginContainer, i);
      oldRef := RobCoListEntryItemRef(entM, RobCoListKindFLST);
      newRef := RobCoListEntryItemRef(entP, RobCoListKindFLST);
      if oldRef = '' then
        Continue;
      if newRef = '' then
        Continue;
      if oldRef = newRef then
        Continue;

      // formsToReplace is for swapping two forms that already exist in the master list.
      // If newRef was not in the master list, emit formsToAdd (and formsToRemove) instead.
      if RobCoMultisetCount(gRobCoListScratchFlstReplaceMs, oldRef) = 0 then
        Continue;
      if RobCoMultisetCount(gRobCoListScratchFlstReplaceMs, newRef) = 0 then
        Continue;

      lines.Add(filterPrefix + ':formsToReplace=' + oldRef + '=' + newRef);
      RobCoMultisetInc(replacedOld, oldRef);
      RobCoMultisetInc(replacedNew, newRef);
    end;
end;

//============================================================================
procedure RobCoListDiffToLines(e: IInterface; lines: TStringList; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly: boolean; const filterPrefix: string;
  pluginContainer, masterContainer: IInterface);
var
  pluginName, editorID, line, addKey, removeKey, addOpcode, sig, containerName: string;
  master, ent: IInterface;
  i: integer;
  useScratchFlst: boolean;
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
    master := MasterOrSelf(e);
    if ElementExists(master, containerName) then
      masterContainer := ElementByName(master, containerName)
    else
      masterContainer := nil;
  end;

  if not Assigned(pluginContainer) then
    Exit;

  pluginName := GetFileName(GetFile(e));
  editorID := RobCoEditorID(e);
  sig := RobCoListRecordSig(listKind);

  addOpcode := RobCoListAddOpcode(listKind);

  RobCoListEnsureScratchMultisets;
  useScratchFlst := False;

  if listKind = RobCoListKindFLST then begin
    if doAdd then begin
      if doRemove then begin
        if RobCoRecordHasExternalMaster(e) then begin
          if Assigned(masterContainer) then begin
            RobCoListEnsureScratchFlstReplace;
            useScratchFlst := True;
            RobCoListEmitFlstReplaceLines(pluginContainer, masterContainer, lines,
              filterPrefix, gRobCoListScratchFlstOld, gRobCoListScratchFlstNew);
          end;
        end;
      end;
    end;
  end;

  if doRemove then begin
    if RobCoRecordHasExternalMaster(e) then begin
      if Assigned(masterContainer) then begin
        RobCoListBuildMultiset(pluginContainer, gRobCoListScratchPluginMultiset, listKind, False);
        for i := 0 to Pred(ElementCount(masterContainer)) do begin
          ent := ElementByIndex(masterContainer, i);
          removeKey := RobCoListEntryRemoveKey(ent, listKind);
          if removeKey = '' then
            Continue;

          if useScratchFlst then begin
            if RobCoMultisetTryConsume(gRobCoListScratchFlstOld, removeKey) then
              Continue;
          end;

          if RobCoMultisetTryConsume(gRobCoListScratchPluginMultiset, removeKey) then
            Continue;

          line := filterPrefix + ':' + RobCoListRemoveOpcode(listKind) + '=' + removeKey;
          lines.Add(line);
        end;
      end;
    end;
  end;

  if doAdd then begin
    if RobCoRecordHasExternalMaster(e) then begin
      if useScratchFlst then
        RobCoListEmitAddLines(pluginContainer, masterContainer, lines, listKind,
          forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, gRobCoListScratchFlstNew)
      else
        RobCoListEmitAddLines(pluginContainer, masterContainer, lines, listKind,
          forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
    end else
      RobCoListEmitAddLines(pluginContainer, nil, lines, listKind,
        forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
  end;
end;

//============================================================================
procedure RobCoExportListRecord(e: IInterface; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  pluginName, editorID, filterPrefix, sig, containerName: string;
  pluginContainer, masterContainer, master: IInterface;
  skipListDiff, hasData: boolean;
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

  containerName := RobCoListContainerName(listKind);
  pluginContainer := nil;
  masterContainer := nil;
  if ElementExists(e, containerName) then begin
    pluginContainer := ElementByName(e, containerName);
    master := MasterOrSelf(e);
    if ElementExists(master, containerName) then
      masterContainer := ElementByName(master, containerName);
  end;

  if not Assigned(pluginContainer) then
    Exit;

  if not RobCoListRecordNeedsContainerDiff(e, pluginContainer, masterContainer, listKind,
    forwardItms) then
    Exit;

  skipListDiff := False;
  if RobCoListMinimalAddDiff(forwardItms, overridesOnly) then begin
    if RobCoRecordHasExternalMaster(e) then begin
      if RobCoListMinimalDiffEmpty(pluginContainer, masterContainer, listKind, doAdd, doRemove) then begin
        skipListDiff := True;
        if listKind = RobCoListKindLVLI then begin
          if not RobCoListLvlifFlagsUnchanged(e, master) then
            skipListDiff := False;
        end;
      end;
    end;
  end;

  pluginName := GetFileName(GetFile(e));
  editorID := RobCoEditorID(e);
  filterPrefix := RobCoListFilterPrefix(e, listKind);

  RobCoListEnsureScratchEmitLines;
  if not skipListDiff then
    RobCoListDiffToLines(e, gRobCoListScratchEmitLines, listKind, doAdd, doRemove,
      forwardItms, overridesOnly, filterPrefix, pluginContainer, masterContainer);

  if doAdd then begin
    if listKind = RobCoListKindLVLI then begin
      if ElementExists(e, RobCoListContainerName(listKind)) then
        RobCoListAppendLVLIFlags(gRobCoListScratchEmitLines, filterPrefix, e);
    end;
  end;

  hasData := RobCoListLinesHaveData(gRobCoListScratchEmitLines, listKind);
  if not hasData then
    Exit;

  RobCoIniWriterWriteRecordLines(pluginName,
    RobCoRecordComment(editorID, pluginName, sig, e, shortComment), gRobCoListScratchEmitLines);
end;

//============================================================================
procedure RobCoExportPluginsList(slSelected: TStringList; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  i, j: integer;
  f, grp, e: IInterface;
  pluginName, sig: string;
begin
  sig := RobCoListRecordSig(listKind);
  if sig = '' then
    Exit;

  for i := 0 to Pred(slSelected.Count) do begin
    f := ObjectToElement(slSelected.Objects[i]);
    pluginName := GetFileName(f);
    grp := GroupBySignature(f, sig);
    if not Assigned(grp) then
      Continue;
    if overridesOnly then begin
      if not RobCoPluginGroupHasOverrides(grp) then
        Continue;
    end;
    for j := 0 to Pred(ElementCount(grp)) do begin
      e := ElementByIndex(grp, j);
      if Signature(e) <> sig then
        Continue;
      if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
        Continue;
      RobCoExportListRecord(e, listKind, doAdd, doRemove,
        forwardItms, overridesOnly, shortComment);
    end;
    RobCoProgressReportPlugin(pluginName, i);
  end;
end;

//============================================================================
procedure RobCoExportPluginsLeveledListAndContainers(slSelected: TStringList;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsList(slSelected, RobCoListKindLVLI,
    doAdd, doRemove, forwardItms, overridesOnly, shortComment);
  RobCoExportPluginsList(slSelected, RobCoListKindCONT,
    doAdd, doRemove, forwardItms, overridesOnly, shortComment);
end;

end.
