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
  Result := RobCoListFilterConstant(listKind) + ' ' + RobCoPatchFilterFormIDRef(e);
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
function RobCoListShouldDiffOverride(e, pluginContainer, masterContainer: IInterface;
  listKind: integer; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := False;
  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;
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
  pluginMultiset, masterMultiset: TStringList;
  i, emitCount, pluginCount, masterCount, keyCount: integer;
  addKey, line: string;
  hasMaster, minimalAddDiff: boolean;
begin
  if not Assigned(pluginContainer) then
    Exit;

  hasMaster := Assigned(masterContainer);
  minimalAddDiff := RobCoListMinimalAddDiff(forwardItms, overridesOnly);

  pluginMultiset := TStringList.Create;
  masterMultiset := TStringList.Create;
  try
    RobCoListBuildMultiset(pluginContainer, pluginMultiset, listKind, True);
    if hasMaster then
      RobCoListBuildMultiset(masterContainer, masterMultiset, listKind, True);

    keyCount := pluginMultiset.Count;
    for i := 0 to Pred(keyCount) do begin
      addKey := pluginMultiset[i];
      if addKey = '' then
        Continue;

      pluginCount := RobCoMultisetCount(pluginMultiset, addKey);
      if hasMaster then
        masterCount := RobCoMultisetCount(masterMultiset, addKey)
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
  finally
    masterMultiset.Free;
    pluginMultiset.Free;
  end;
end;

//============================================================================
function RobCoListMinimalDiffEmpty(pluginContainer, masterContainer: IInterface;
  listKind: integer; doAdd, doRemove: boolean): boolean;
var
  pluginRem, pluginAdd, masterAdd, keys: TStringList;
  i: integer;
  ent: IInterface;
  removeKey, addKey: string;
begin
  Result := True;
  if not Assigned(pluginContainer) then
    Exit;

  if doRemove then begin
    if Assigned(masterContainer) then begin
      pluginRem := TStringList.Create;
      try
        RobCoListBuildMultiset(pluginContainer, pluginRem, listKind, False);
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
          if RobCoMultisetTryConsume(pluginRem, removeKey) then
            Continue;
          Result := False;
          Exit;
        end;
      finally
        pluginRem.Free;
      end;
    end;
  end;

  if not Result then
    Exit;
  if not doAdd then
    Exit;

  pluginAdd := TStringList.Create;
    masterAdd := TStringList.Create;
    keys := TStringList.Create;
    try
      RobCoListBuildMultiset(pluginContainer, pluginAdd, listKind, True);
      if Assigned(masterContainer) then
        RobCoListBuildMultiset(masterContainer, masterAdd, listKind, True);
      for i := 0 to Pred(ElementCount(pluginContainer)) do begin
        ent := ElementByIndex(pluginContainer, i);
        addKey := RobCoListEntryAddKey(ent, listKind);
        if addKey <> '' then begin
          if keys.IndexOf(addKey) < 0 then
            keys.Add(addKey);
        end;
      end;
      for i := 0 to Pred(keys.Count) do begin
        addKey := keys[i];
        if RobCoMultisetCount(masterAdd, addKey) = 0 then begin
          if RobCoMultisetCount(pluginAdd, addKey) > 0 then begin
            Result := False;
            Exit;
          end;
        end;
      end;
    finally
      keys.Free;
      masterAdd.Free;
      pluginAdd.Free;
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

  masterMultiset := TStringList.Create;
  try
    RobCoListBuildMultiset(masterContainer, masterMultiset, RobCoListKindFLST, True);

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
      if RobCoMultisetCount(masterMultiset, oldRef) = 0 then
        Continue;
      if RobCoMultisetCount(masterMultiset, newRef) = 0 then
        Continue;

      lines.Add(filterPrefix + ':formsToReplace=' + oldRef + '=' + newRef);
      RobCoMultisetInc(replacedOld, oldRef);
      RobCoMultisetInc(replacedNew, newRef);
    end;
  finally
    masterMultiset.Free;
  end;
end;

//============================================================================
procedure RobCoListDiffToLines(e: IInterface; lines: TStringList; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly: boolean; const filterPrefix: string);
var
  pluginName, editorID, line, addKey, removeKey, addOpcode, sig: string;
  containerName: string;
  pluginContainer, masterContainer, master, ent: IInterface;
  pluginMultiset, masterMultiset, flstReplacedOld, flstReplacedNew: TStringList;
  i: integer;
  minimalAddDiff: boolean;
begin
  if not doAdd then begin
    if not doRemove then
      Exit;
  end;

  containerName := RobCoListContainerName(listKind);
  if containerName = '' then
    Exit;

  if not ElementExists(e, containerName) then
    Exit;

  pluginName := GetFileName(GetFile(e));
  editorID := RobCoEditorID(e);
  sig := RobCoListRecordSig(listKind);

  addOpcode := RobCoListAddOpcode(listKind);

  pluginMultiset := TStringList.Create;
  masterMultiset := TStringList.Create;
  flstReplacedOld := nil;
  flstReplacedNew := nil;
  try
    pluginContainer := ElementByName(e, containerName);
    master := MasterOrSelf(e);
    masterContainer := ElementByName(master, containerName);

    minimalAddDiff := RobCoListMinimalAddDiff(forwardItms, overridesOnly);

    if minimalAddDiff then begin
      if RobCoRecordHasExternalMaster(e) then begin
        if RobCoListMinimalDiffEmpty(pluginContainer, masterContainer, listKind, doAdd, doRemove) then
          Exit;
      end;
    end;

    if listKind = RobCoListKindFLST then begin
      if doAdd then begin
        if doRemove then begin
          if RobCoRecordHasExternalMaster(e) then begin
            if Assigned(masterContainer) then begin
              if Assigned(pluginContainer) then begin
                flstReplacedOld := TStringList.Create;
                flstReplacedNew := TStringList.Create;
                RobCoListEmitFlstReplaceLines(pluginContainer, masterContainer, lines,
                  filterPrefix, flstReplacedOld, flstReplacedNew);
              end;
            end;
          end;
        end;
      end;
    end;

    if doRemove then begin
      if RobCoRecordHasExternalMaster(e) then begin
        if Assigned(masterContainer) then begin
          if Assigned(pluginContainer) then begin
            RobCoListBuildMultiset(pluginContainer, pluginMultiset, listKind, False);
            for i := 0 to Pred(ElementCount(masterContainer)) do begin
              ent := ElementByIndex(masterContainer, i);
              removeKey := RobCoListEntryRemoveKey(ent, listKind);
              if removeKey = '' then
                Continue;

              if Assigned(flstReplacedOld) then begin
                if RobCoMultisetTryConsume(flstReplacedOld, removeKey) then
                  Continue;
              end;

              if RobCoMultisetTryConsume(pluginMultiset, removeKey) then
                Continue;

              line := filterPrefix + ':' + RobCoListRemoveOpcode(listKind) + '=' + removeKey;
              lines.Add(line);
            end;
          end;
        end;
      end;
    end;

    if doAdd then begin
      if Assigned(pluginContainer) then begin
        if RobCoRecordHasExternalMaster(e) then
          RobCoListEmitAddLines(pluginContainer, masterContainer, lines, listKind,
            forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, flstReplacedNew)
        else
          RobCoListEmitAddLines(pluginContainer, nil, lines, listKind,
            forwardItms, overridesOnly, filterPrefix, addOpcode, editorID, nil);
      end;
    end;
  finally
    if Assigned(flstReplacedNew) then
      flstReplacedNew.Free;
    if Assigned(flstReplacedOld) then
      flstReplacedOld.Free;
    masterMultiset.Free;
    pluginMultiset.Free;
  end;
end;

//============================================================================
procedure RobCoExportListRecord(e: IInterface; listKind: integer;
  doAdd, doRemove, forwardItms, overridesOnly, shortComment: boolean);
var
  pluginName, editorID, filterPrefix, sig, containerName: string;
  lines: TStringList;
  pluginContainer, masterContainer, master: IInterface;
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

  if not RobCoListShouldDiffOverride(e, pluginContainer, masterContainer, listKind,
    forwardItms, overridesOnly) then
    Exit;

  pluginName := GetFileName(GetFile(e));
  editorID := RobCoEditorID(e);
  filterPrefix := RobCoListFilterPrefix(e, listKind);

  lines := TStringList.Create;
  try
    RobCoListDiffToLines(e, lines, listKind, doAdd, doRemove,
      forwardItms, overridesOnly, filterPrefix);

    if doAdd then begin
      if listKind = RobCoListKindLVLI then begin
        if ElementExists(e, RobCoListContainerName(listKind)) then
          RobCoListAppendLVLIFlags(lines, filterPrefix, e);
      end;
    end;

    if not RobCoListLinesHaveData(lines, listKind) then
      Exit;

    RobCoIniWriterWriteRecordLines(pluginName,
      RobCoRecordComment(editorID, pluginName, sig, e, shortComment), lines);
    AddMessage(Format('Processed %s: %s [%s|%s:%s]', [
      sig, editorID, pluginName, sig, FormatFormID(e)
    ]));
  finally
    lines.Free;
  end;
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
    grp := GroupBySignature(f, sig);
    if not Assigned(grp) then
      Continue;

    for j := 0 to Pred(ElementCount(grp)) do begin
      e := ElementByIndex(grp, j);
      RobCoExportListRecord(e, listKind, doAdd, doRemove,
        forwardItms, overridesOnly, shortComment);
    end;
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
