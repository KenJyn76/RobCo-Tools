{
  Snapshot exports: MISC, AMMO, COBJ, ARMO, WEAP, ALCH, OMOD (FO4), NPC_, RACE.
}
unit RobCoSnapshot;

//============================================================================
// Read-once scratch (populated by RobCoRead*PatchInputs per record)
//============================================================================
var
  gRobCoSnapMaster: IInterface;
  gRobCoSnapKeywords, gRobCoSnapMasterKeywords: string;
  gRobCoSnapPerks, gRobCoSnapMasterPerks: string;
  gRobCoSnapSpells, gRobCoSnapMasterSpells: string;
  gRobCoSnapChangeAvif, gRobCoSnapMasterChangeAvif: string;
  gRobCoSnapFactions, gRobCoSnapMasterFactions: string;
  gRobCoSnapInventory, gRobCoSnapMasterInventory: string;
  gRobCoSnapFullName, gRobCoSnapMasterFullName: string;
  gRobCoSnapDeathItem, gRobCoSnapMasterDeathItem: string;
  gRobCoSnapRaceRef, gRobCoSnapMasterRaceRef: string;
  gRobCoSnapClassRef, gRobCoSnapMasterClassRef: string;
  gRobCoSnapValue, gRobCoSnapMasterValue: string;
  gRobCoSnapWeight, gRobCoSnapMasterWeight: string;
  gRobCoSnapDamage, gRobCoSnapMasterDamage: string;
  gRobCoSnapAttackDamage, gRobCoSnapMasterAttackDamage: string;
  gRobCoSnapProjectile, gRobCoSnapMasterProjectile: string;
  gRobCoSnapCategoryKw, gRobCoSnapMasterCategoryKw: string;
  gRobCoSnapWorkbench, gRobCoSnapMasterWorkbench: string;
  gRobCoSnapObjectEffect, gRobCoSnapMasterObjectEffect: string;
  gRobCoSnapApprKw, gRobCoSnapMasterApprKw: string;
  gRobCoSnapArmorRating, gRobCoSnapMasterArmorRating: string;
  gRobCoSnapHealth, gRobCoSnapMasterHealth: string;
  gRobCoSnapBashDamage, gRobCoSnapMasterBashDamage: string;
  gRobCoSnapAmmoRef, gRobCoSnapMasterAmmoRef: string;
  gRobCoSnapAimModel, gRobCoSnapMasterAimModel: string;
  gRobCoSnapMgefs, gRobCoSnapMasterMgefs: string;
  gRobCoSnapAcbsAutoCalc, gRobCoSnapAcbsPcLevelMult, gRobCoSnapAcbsEssential: string;
  gRobCoSnapAcbsLevel, gRobCoSnapAcbsCalcMin, gRobCoSnapAcbsCalcMax: string;
  gRobCoSnapMasterAcbsAutoCalc, gRobCoSnapMasterAcbsPcLevelMult, gRobCoSnapMasterAcbsEssential: string;
  gRobCoSnapMasterAcbsLevel, gRobCoSnapMasterAcbsCalcMin, gRobCoSnapMasterAcbsCalcMax: string;
  gRobCoSnapOmodAttach, gRobCoSnapMasterOmodAttach: string;
  gRobCoSnapOmodPlainName, gRobCoSnapMasterOmodPlainName: string;
  gRobCoSnapOmodApprKw, gRobCoSnapMasterOmodApprKw: string;
  gRobCoSnapRefPartsScratch: TStringList;
  gRobCoSnapRefSeenScratch: TStringList;
  gRobCoSnapPartsScratch: TStringList;
  gRobCoSnapCommaScratch: TStringList;
  gRobCoSnapCommaScratch2: TStringList;
  // NPC incremental pregather stash (bitmask; cleared per ExportNPCToRobCo record)
  gRobCoSnapNpcStashMask: integer;

//============================================================================
procedure RobCoSnapInitRefSeenScratch;
begin
  if not Assigned(gRobCoSnapRefSeenScratch) then begin
    gRobCoSnapRefSeenScratch := TStringList.Create;
    gRobCoSnapRefSeenScratch.Sorted := True;
    gRobCoSnapRefSeenScratch.Duplicates := dupIgnore;
  end;
end;

//============================================================================
procedure RobCoSnapEnsureRefSeenScratch;
begin
  RobCoSnapInitRefSeenScratch;
  gRobCoSnapRefSeenScratch.Clear;
end;

//============================================================================
procedure RobCoSnapRefPartsAddUnique(const refKey: string);
begin
  RobCoSnapInitRefSeenScratch;
  if gRobCoSnapRefSeenScratch.IndexOf(refKey) >= 0 then
    Exit;
  gRobCoSnapRefSeenScratch.Add(refKey);
  gRobCoSnapRefPartsScratch.Add(refKey);
end;

//============================================================================
procedure RobCoSnapEnsureRefPartsScratch;
begin
  if not Assigned(gRobCoSnapRefPartsScratch) then
    gRobCoSnapRefPartsScratch := TStringList.Create;
  gRobCoSnapRefPartsScratch.Clear;
  RobCoSnapEnsureRefSeenScratch;
end;

//============================================================================
procedure RobCoSnapEnsurePartsScratch;
begin
  if not Assigned(gRobCoSnapPartsScratch) then
    gRobCoSnapPartsScratch := TStringList.Create;
  gRobCoSnapPartsScratch.Clear;
end;

//============================================================================
procedure RobCoSnapEnsureCommaScratch;
begin
  if not Assigned(gRobCoSnapCommaScratch) then
    gRobCoSnapCommaScratch := TStringList.Create;
  if not Assigned(gRobCoSnapCommaScratch2) then
    gRobCoSnapCommaScratch2 := TStringList.Create;
  gRobCoSnapCommaScratch.Clear;
  gRobCoSnapCommaScratch2.Clear;
end;

//============================================================================
procedure RobCoSnapClearMaster;
begin
  gRobCoSnapMaster := nil;
end;

//============================================================================
procedure RobCoSnapReadMasterIfAny(e: IInterface);
begin
  RobCoSnapClearMaster;
  if RobCoRecordHasExternalMaster(e) then
    gRobCoSnapMaster := MasterOrSelf(e);
end;

//============================================================================
// MISC
//============================================================================


var
  gMiscPatchFilterByMiscs, gMiscPatchFilterByHasComponent, gMiscPatchFilterByHasNoComponent: string;
  gMiscPatchFilterByKeywords, gMiscPatchFilterByKeywordsOr, gMiscPatchFilterByKeywordsExcluded: string;
  gMiscPatchValue, gMiscPatchWeight, gMiscPatchWeightMultiply: string;

//============================================================================
procedure InitRobCoMISCPatchData;
begin
  gMiscPatchFilterByMiscs := 'none';
  gMiscPatchFilterByHasComponent := 'none';
  gMiscPatchFilterByHasNoComponent := 'none';
  gMiscPatchFilterByKeywords := 'none';
  gMiscPatchFilterByKeywordsOr := 'none';
  gMiscPatchFilterByKeywordsExcluded := 'none';
  gMiscPatchValue := '';
  gMiscPatchWeight := '';
  gMiscPatchWeightMultiply := '1';
end;

//============================================================================
function ReadMiscValue(e: IInterface): string;
begin
  Result := '';
  if ElementExists(e, 'DATA\Value') then
    Result := IntToStr(Round(GetElementNativeValues(e, 'DATA\Value')));
end;

//============================================================================
function ReadMiscWeight(e: IInterface): string;
begin
  Result := '';
  if ElementExists(e, 'DATA\Weight') then
    Result := GetElementEditValues(e, 'DATA\Weight');
end;

//============================================================================
function RobCoMiscFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  pluginValue, pluginWeight, masterValue, masterWeight: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if not Assigned(master) then
    Exit;
  pluginValue := ReadMiscValue(e);
  pluginWeight := ReadMiscWeight(e);
  masterValue := ReadMiscValue(master);
  masterWeight := ReadMiscWeight(master);
  if pluginValue <> masterValue then
    Exit;
  if pluginWeight <> masterWeight then
    Exit;
  Result := True;
end;

//============================================================================
procedure RobCoReadMiscPatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  gRobCoSnapValue := ReadMiscValue(e);
  gRobCoSnapWeight := ReadMiscWeight(e);
  gRobCoSnapMasterValue := '';
  gRobCoSnapMasterWeight := '';
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterValue := ReadMiscValue(gRobCoSnapMaster);
    gRobCoSnapMasterWeight := ReadMiscWeight(gRobCoSnapMaster);
  end;
end;

//============================================================================
function RobCoMiscFieldsUnchangedFromScratch: boolean;
begin
  Result := False;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapValue <> gRobCoSnapMasterValue then
    Exit;
  if gRobCoSnapWeight <> gRobCoSnapMasterWeight then
    Exit;
  Result := True;
end;

//============================================================================
procedure GatherMiscPatchDataFromScratch(e: IInterface);
begin
  InitRobCoMISCPatchData;
  gMiscPatchFilterByMiscs := RobCoPatchFilterFormIDRef(e);
  gMiscPatchValue := RobCoExportFieldIfChanged(e, gRobCoSnapValue, gRobCoSnapMasterValue);
  gMiscPatchWeight := RobCoExportFieldIfChanged(e, gRobCoSnapWeight, gRobCoSnapMasterWeight);
  if gRobCoExportWriteAllFields then
    gMiscPatchWeightMultiply := '1'
  else
    gMiscPatchWeightMultiply := '';
end;

//============================================================================
procedure GatherMiscPatchData(e: IInterface);
var
  master: IInterface;
  pluginValue, pluginWeight, masterValue, masterWeight: string;
begin
  InitRobCoMISCPatchData;

  gMiscPatchFilterByMiscs := RobCoPatchFilterFormIDRef(e);

  pluginValue := ReadMiscValue(e);
  pluginWeight := ReadMiscWeight(e);
  masterValue := '';
  masterWeight := '';
  if RobCoRecordHasExternalMaster(e) then begin
    master := MasterOrSelf(e);
    masterValue := ReadMiscValue(master);
    masterWeight := ReadMiscWeight(master);
  end;
  gMiscPatchValue := RobCoExportFieldIfChanged(e, pluginValue, masterValue);
  gMiscPatchWeight := RobCoExportFieldIfChanged(e, pluginWeight, masterWeight);
  if gRobCoExportWriteAllFields then
    gMiscPatchWeightMultiply := '1'
  else
    gMiscPatchWeightMultiply := '';
end;

//============================================================================
function BuildRobCoMISCLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByMiscs', gMiscPatchFilterByMiscs);
  Result := RobCoAppendPatchField(Result, 'filterByHasComponent', gMiscPatchFilterByHasComponent);
  Result := RobCoAppendPatchField(Result, 'filterByHasNoComponent', gMiscPatchFilterByHasNoComponent);
  Result := RobCoAppendPatchField(Result, 'filterByKeywords', gMiscPatchFilterByKeywords);
  Result := RobCoAppendPatchField(Result, 'filterByKeywordsOr', gMiscPatchFilterByKeywordsOr);
  Result := RobCoAppendPatchField(Result, 'filterByKeywordsExcluded', gMiscPatchFilterByKeywordsExcluded);

  Result := RobCoAppendNumericField(Result, 'value', gMiscPatchValue);
  Result := RobCoAppendNumericField(Result, 'weight', gMiscPatchWeight);
  Result := RobCoAppendNumericField(Result, 'weightMultiply', gMiscPatchWeightMultiply);
end;

//============================================================================
procedure ExportMISCToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'MISC' then
    Exit;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoMiscFieldsUnchangedVsMaster(e) then begin
      Exit;
    end;
  end;

  RobCoReadMiscPatchInputs(e);
  GatherMiscPatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'MISC', shortComment, BuildRobCoMISCLine);
end;


//============================================================================
// AMMO
//============================================================================


var
  gAmmoPatchFilterByAmmos, gAmmoPatchFilterByWeightLessThan: string;
  gAmmoPatchFullName, gAmmoPatchWeight, gAmmoPatchAttackDamage: string;
  gAmmoPatchKeywordsToAdd, gAmmoPatchKeywordsToRemove: string;
  gAmmoPatchAmmoCategory, gAmmoPatchSetNewProjectile: string;

//============================================================================
function ReadAmmoAttackDamage(e: IInterface): string;
begin
  Result := '';
  if ElementExists(e, 'DNAM\Damage') then
    Result := GetElementEditValues(e, 'DNAM\Damage')
  else if ElementExists(e, 'DATA\Damage') then
    Result := GetElementEditValues(e, 'DATA\Damage');
end;

//============================================================================
function ReadAmmoProjectileRef(e: IInterface): string;
begin
  Result := RobCoReadFormLinkRef(e, 'PNAM');
  if Result = '' then
    Result := RobCoReadFormLinkPathOrRef(e, 'Projectile', 'INAM');
end;

//============================================================================
procedure InitRobCoAMMOPatchData;
begin
  gAmmoPatchFilterByAmmos := 'none';
  gAmmoPatchFilterByWeightLessThan := 'none';
  gAmmoPatchFullName := '';
  gAmmoPatchWeight := '';
  gAmmoPatchAttackDamage := '';
  gAmmoPatchKeywordsToAdd := 'none';
  gAmmoPatchKeywordsToRemove := 'none';
  gAmmoPatchAmmoCategory := 'none';
  gAmmoPatchSetNewProjectile := 'none';
end;

//============================================================================
procedure GatherAmmoPatchData(e: IInterface);
var
  keywords, projectile, masterProjectile, masterAttack: string;
begin
  InitRobCoAMMOPatchData;

  gAmmoPatchFilterByAmmos := RobCoPatchFilterFormIDRef(e);
  keywords := RobCoReadKeywordRefsFromElement(e);
  RobCoApplyKeywordDiffIfCompact(e, keywords, gAmmoPatchKeywordsToAdd, gAmmoPatchKeywordsToRemove);
  gAmmoPatchFullName := RobCoFullNameIfChanged(e);
  gAmmoPatchWeight := RobCoDataFieldIfChanged(e, 'Weight');

  if RobCoFO4Game then begin
    masterProjectile := '';
    masterAttack := '';
    if RobCoRecordHasExternalMaster(e) then begin
      masterProjectile := ReadAmmoProjectileRef(MasterOrSelf(e));
      masterAttack := ReadAmmoAttackDamage(MasterOrSelf(e));
    end;
    gAmmoPatchAttackDamage := RobCoExportFieldIfChanged(e, ReadAmmoAttackDamage(e), masterAttack);
    projectile := ReadAmmoProjectileRef(e);
    gAmmoPatchSetNewProjectile := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(projectile),
      RobCoNoneIfEmpty(masterProjectile));
  end;
end;

//============================================================================
function BuildRobCoAMMOLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByAmmos', gAmmoPatchFilterByAmmos);
  Result := RobCoAppendPatchField(Result, 'filterByWeightLessThan', gAmmoPatchFilterByWeightLessThan);

  Result := RobCoAppendField(Result, 'fullName', gAmmoPatchFullName, False);
  Result := RobCoAppendNumericField(Result, 'weight', gAmmoPatchWeight);
  Result := RobCoAppendField(Result, 'keywordsToAdd', gAmmoPatchKeywordsToAdd, True);

  if RobCoFO4Game then begin
    Result := RobCoAppendNumericField(Result, 'attackDamage', gAmmoPatchAttackDamage);
    Result := RobCoAppendField(Result, 'ammoCategory', gAmmoPatchAmmoCategory, True);
    Result := RobCoAppendField(Result, 'setNewProjectile', gAmmoPatchSetNewProjectile, True);
  end;
end;

//============================================================================
function RobCoAmmoFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  masterProjectile, masterAttack: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if not RobCoKeywordRefsUnchangedVsMaster(e) then
    Exit;
  if RobCoFO4Game then begin
    if ReadAmmoAttackDamage(e) <> ReadAmmoAttackDamage(master) then
      Exit;
    masterProjectile := ReadAmmoProjectileRef(master);
    if ReadAmmoProjectileRef(e) <> masterProjectile then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure RobCoReadAmmoPatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  RobCoSnapReadKeywordsToScratch(e);
  gRobCoSnapFullName := RobCoReadFullName(e);
  gRobCoSnapMasterFullName := '';
  gRobCoSnapWeight := RobCoReadDataField(e, 'Weight');
  gRobCoSnapMasterWeight := '';
  gRobCoSnapAttackDamage := '';
  gRobCoSnapMasterAttackDamage := '';
  gRobCoSnapProjectile := '';
  gRobCoSnapMasterProjectile := '';
  if RobCoFO4Game then begin
    gRobCoSnapAttackDamage := ReadAmmoAttackDamage(e);
    gRobCoSnapProjectile := ReadAmmoProjectileRef(e);
  end;
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterFullName := RobCoReadFullName(gRobCoSnapMaster);
    gRobCoSnapMasterWeight := RobCoReadDataField(gRobCoSnapMaster, 'Weight');
    if RobCoFO4Game then begin
      gRobCoSnapMasterAttackDamage := ReadAmmoAttackDamage(gRobCoSnapMaster);
      gRobCoSnapMasterProjectile := ReadAmmoProjectileRef(gRobCoSnapMaster);
    end;
  end;
end;

//============================================================================
function RobCoAmmoFieldsUnchangedFromScratch: boolean;
begin
  Result := False;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapFullName <> gRobCoSnapMasterFullName then
    Exit;
  if gRobCoSnapWeight <> gRobCoSnapMasterWeight then
    Exit;
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapKeywords, gRobCoSnapMasterKeywords) then
    Exit;
  if RobCoFO4Game then begin
    if gRobCoSnapAttackDamage <> gRobCoSnapMasterAttackDamage then
      Exit;
    if gRobCoSnapProjectile <> gRobCoSnapMasterProjectile then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure GatherAmmoPatchDataFromScratch(e: IInterface);
begin
  InitRobCoAMMOPatchData;
  gAmmoPatchFilterByAmmos := RobCoPatchFilterFormIDRef(e);
  RobCoApplyKeywordDiffIfCompact(e, gRobCoSnapKeywords,
    gAmmoPatchKeywordsToAdd, gAmmoPatchKeywordsToRemove);
  gAmmoPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapFullName, gRobCoSnapMasterFullName);
  gAmmoPatchWeight := RobCoExportFieldIfChanged(e, gRobCoSnapWeight, gRobCoSnapMasterWeight);
  if RobCoFO4Game then begin
    gAmmoPatchAttackDamage := RobCoExportFieldIfChanged(e, gRobCoSnapAttackDamage,
      gRobCoSnapMasterAttackDamage);
    gAmmoPatchSetNewProjectile := RobCoExportFieldIfChanged(e,
      RobCoNoneIfEmpty(gRobCoSnapProjectile), RobCoNoneIfEmpty(gRobCoSnapMasterProjectile));
  end;
end;

//============================================================================
procedure ExportAMMOToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'AMMO' then
    Exit;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoSnapTryEarlyPregatherSkipAmmo(e) then begin
      RobCoSnapRecordEarlyPregatherSkip;
      Exit;
    end;
  end;

  RobCoReadAmmoPatchInputs(e);
  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoAmmoFieldsUnchangedFromScratch then begin
      Exit;
    end;
  end;

  GatherAmmoPatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'AMMO', shortComment, BuildRobCoAMMOLine);
end;


//============================================================================
// COBJ
//============================================================================


var
  gCobjPatchFilterByCobjs, gCobjPatchFilterByWorkbenchKeywordsOr, gCobjPatchFilterByCategoryKeywordsOr: string;
  gCobjPatchCategoryKeywordsToAdd, gCobjPatchCategoryKeywordsToRemove, gCobjPatchWorkbenchKeyword: string;

//============================================================================
function GetCobjCategoryKeywordsElement(e: IInterface): IInterface;
begin
  Result := ElementBySignature(e, 'FNAM');
  if not Assigned(Result) then
    Result := ElementByPath(e, 'Keywords\KWDA');
end;

//============================================================================
function ReadCobjCategoryKeywordRefs(e: IInterface): string;
var
  kwda, kw: IInterface;
  i: integer;
begin
  Result := '';
  kwda := GetCobjCategoryKeywordsElement(e);
  if not Assigned(kwda) then
    Exit;

  RobCoSnapEnsureRefPartsScratch;
  for i := 0 to Pred(ElementCount(kwda)) do begin
    kw := LinksTo(ElementByIndex(kwda, i));
    if not Assigned(kw) then
      Continue;
    if Signature(kw) <> 'KYWD' then
      Continue;
    RobCoSnapRefPartsAddUnique(RobCoMasterFormIDRef(kw));
  end;
  Result := RobCoJoinParts(gRobCoSnapRefPartsScratch);
end;

//============================================================================
function ReadWorkbenchKeywordRef(e: IInterface): string;
var
  link: IInterface;
begin
  Result := '';
  if not ElementExists(e, 'BNAM') then begin
    Result := 'null';
    Exit;
  end;
  link := LinksTo(ElementBySignature(e, 'BNAM'));
  if Assigned(link) then
    Result := RobCoMasterFormIDRef(link)
  else
    Result := 'null';
end;

//============================================================================
procedure InitRobCoCOBJPatchData;
begin
  gCobjPatchFilterByCobjs := 'none';
  gCobjPatchFilterByWorkbenchKeywordsOr := 'none';
  gCobjPatchFilterByCategoryKeywordsOr := 'none';
  gCobjPatchCategoryKeywordsToAdd := 'none';
  gCobjPatchCategoryKeywordsToRemove := 'none';
  gCobjPatchWorkbenchKeyword := 'null';
end;

//============================================================================
procedure GatherCobjPatchData(e: IInterface);
var
  categoryKeywords, workbench, masterCategory, masterWorkbench: string;
  workbenchLink: IInterface;
begin
  InitRobCoCOBJPatchData;

  categoryKeywords := ReadCobjCategoryKeywordRefs(e);
  workbench := ReadWorkbenchKeywordRef(e);
  masterCategory := '';
  masterWorkbench := 'null';
  if RobCoRecordHasExternalMaster(e) then begin
    masterCategory := ReadCobjCategoryKeywordRefs(MasterOrSelf(e));
    masterWorkbench := ReadWorkbenchKeywordRef(MasterOrSelf(e));
  end;

  gCobjPatchFilterByCobjs := RobCoPatchFilterFormIDRef(e);
  gCobjPatchFilterByCategoryKeywordsOr := RobCoNoneIfEmpty(categoryKeywords);
  RobCoApplyRefListDiffIfCompact(e, RobCoNoneIfEmpty(categoryKeywords),
    RobCoNoneIfEmpty(masterCategory), gCobjPatchCategoryKeywordsToAdd,
    gCobjPatchCategoryKeywordsToRemove);
  if gCobjPatchCategoryKeywordsToAdd = '' then
    gCobjPatchCategoryKeywordsToAdd := 'none';
  if gCobjPatchCategoryKeywordsToRemove = '' then
    gCobjPatchCategoryKeywordsToRemove := 'none';
  gCobjPatchWorkbenchKeyword := RobCoExportFieldIfChanged(e, workbench, masterWorkbench);

  if ElementExists(e, 'BNAM') then begin
    workbenchLink := LinksTo(ElementBySignature(e, 'BNAM'));
    if Assigned(workbenchLink) then begin
      if Signature(workbenchLink) = 'KYWD' then
        gCobjPatchFilterByWorkbenchKeywordsOr := RobCoMasterFormIDRef(workbenchLink);
    end;
  end;
end;

//============================================================================
function BuildRobCoCOBJLine: string;
begin
  Result := '';
  // RobCo Patcher COBJ filters are independent (OR across types), not ANDed.
  // Per-record snapshot export must use filterByCobjs only; secondary filters
  // would apply operations to unrelated constructible objects and can crash.
  Result := RobCoAppendPatchField(Result, 'filterByCobjs', gCobjPatchFilterByCobjs);

  Result := RobCoAppendField(Result, 'categoryKeywordsToAdd', gCobjPatchCategoryKeywordsToAdd, True);
  Result := RobCoAppendField(Result, 'categoryKeywordsToRemove', gCobjPatchCategoryKeywordsToRemove, True);
  Result := RobCoAppendField(Result, 'workbenchKeyword', gCobjPatchWorkbenchKeyword, True);
end;

//============================================================================
function RobCoCobjFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  categoryKeywords, masterCategory, workbench, masterWorkbench: string;
  addKw, remKw: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  categoryKeywords := ReadCobjCategoryKeywordRefs(e);
  masterCategory := ReadCobjCategoryKeywordRefs(master);
  RobCoDiffCommaSeparatedRefs(RobCoNoneIfEmpty(categoryKeywords),
    RobCoNoneIfEmpty(masterCategory), addKw, remKw);
  if addKw <> 'none' then
    Exit;
  if remKw <> 'none' then
    Exit;
  workbench := ReadWorkbenchKeywordRef(e);
  masterWorkbench := ReadWorkbenchKeywordRef(master);
  if workbench <> masterWorkbench then
    Exit;
  Result := True;
end;

//============================================================================
procedure RobCoReadCobjPatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  RobCoSnapReadCobjCategoryKwToScratch(e);
  gRobCoSnapWorkbench := ReadWorkbenchKeywordRef(e);
  gRobCoSnapMasterWorkbench := 'null';
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterWorkbench := ReadWorkbenchKeywordRef(gRobCoSnapMaster);
end;

//============================================================================
function RobCoCobjFieldsUnchangedFromScratch: boolean;
var
  addKw, remKw: string;
begin
  Result := False;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  RobCoDiffCommaSeparatedRefs(RobCoNoneIfEmpty(gRobCoSnapCategoryKw),
    RobCoNoneIfEmpty(gRobCoSnapMasterCategoryKw), addKw, remKw);
  if addKw <> 'none' then
    Exit;
  if remKw <> 'none' then
    Exit;
  if gRobCoSnapWorkbench <> gRobCoSnapMasterWorkbench then
    Exit;
  Result := True;
end;

//============================================================================
procedure GatherCobjPatchDataFromScratch(e: IInterface);
var
  workbenchLink: IInterface;
begin
  InitRobCoCOBJPatchData;
  gCobjPatchFilterByCobjs := RobCoPatchFilterFormIDRef(e);
  gCobjPatchFilterByCategoryKeywordsOr := RobCoNoneIfEmpty(gRobCoSnapCategoryKw);
  RobCoApplyRefListDiffIfCompact(e, RobCoNoneIfEmpty(gRobCoSnapCategoryKw),
    RobCoNoneIfEmpty(gRobCoSnapMasterCategoryKw), gCobjPatchCategoryKeywordsToAdd,
    gCobjPatchCategoryKeywordsToRemove);
  if gCobjPatchCategoryKeywordsToAdd = '' then
    gCobjPatchCategoryKeywordsToAdd := 'none';
  if gCobjPatchCategoryKeywordsToRemove = '' then
    gCobjPatchCategoryKeywordsToRemove := 'none';
  gCobjPatchWorkbenchKeyword := RobCoExportFieldIfChanged(e, gRobCoSnapWorkbench,
    gRobCoSnapMasterWorkbench);
  if ElementExists(e, 'BNAM') then begin
    workbenchLink := LinksTo(ElementBySignature(e, 'BNAM'));
    if Assigned(workbenchLink) then begin
      if Signature(workbenchLink) = 'KYWD' then
        gCobjPatchFilterByWorkbenchKeywordsOr := RobCoMasterFormIDRef(workbenchLink);
    end;
  end;
end;

//============================================================================
procedure ExportCOBJToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'COBJ' then
    Exit;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoSnapTryEarlyPregatherSkipCobj(e) then begin
      RobCoSnapRecordEarlyPregatherSkip;
      Exit;
    end;
  end;

  RobCoReadCobjPatchInputs(e);
  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoCobjFieldsUnchangedFromScratch then begin
      Exit;
    end;
  end;

  GatherCobjPatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'COBJ', shortComment, BuildRobCoCOBJLine);
end;


//============================================================================
// ARMO
//============================================================================


var
  gArmoPatchFilterByArmors, gArmoPatchFilterByArmorsExcluded: string;
  gArmoPatchFilterByKeywords, gArmoPatchFilterByKeywordsOr, gArmoPatchFilterByKeywordsExcluded: string;
  gArmoPatchFilterByBipedSlots, gArmoPatchFilterByBipedSlotsOr, gArmoPatchFilterByBipedSlotsExcluded: string;
  gArmoPatchFilterByArmorTypes: string;
  gArmoPatchFullName, gArmoPatchDamageResist, gArmoPatchWeight, gArmoPatchValue, gArmoPatchHealth: string;
  gArmoPatchObjectEffect, gArmoPatchKeywordsToAdd, gArmoPatchKeywordsToRemove: string;
  gArmoPatchAttachParentSlotKeywordsToAdd, gArmoPatchAttachParentSlotKeywordsToRemove: string;
  gArmoPatchChangeDamageTypes, gArmoPatchWeightMult, gArmoPatchHealthMult: string;
  gArmoPatchBipedSlotsToAdd, gArmoPatchBipedSlotsToRemove: string;

//============================================================================
function ReadSkyrimArmorTypeFilter(e: IInterface): string;
var
  armorType: integer;
begin
  Result := 'none';
  if RobCoFO4Game then
    Exit;
  if not ElementExists(e, 'BOD2\Armor Type') then
    Exit;

  armorType := Round(GetElementNativeValues(e, 'BOD2\Armor Type'));
  case armorType of
    1: Result := 'LightArmor';
    2: Result := 'HeavyArmor';
    3: Result := 'Clothing';
  end;
end;

//============================================================================
function ReadArmoObjectEffect(e: IInterface): string;
begin
  Result := RobCoReadFormLinkPathOrRef(e, 'Object Effect', 'EITM');
  if Result = '' then
    Result := 'null';
end;

//============================================================================
procedure InitRobCoARMOPatchData;
begin
  gArmoPatchFilterByArmors := 'none';
  gArmoPatchFilterByArmorsExcluded := 'none';
  gArmoPatchFilterByKeywords := 'none';
  gArmoPatchFilterByKeywordsOr := 'none';
  gArmoPatchFilterByKeywordsExcluded := 'none';
  gArmoPatchFilterByBipedSlots := 'none';
  gArmoPatchFilterByBipedSlotsOr := 'none';
  gArmoPatchFilterByBipedSlotsExcluded := 'none';
  gArmoPatchFullName := '';
  gArmoPatchDamageResist := '';
  gArmoPatchWeight := '';
  gArmoPatchValue := '';
  gArmoPatchHealth := '';
  gArmoPatchObjectEffect := 'null';
  gArmoPatchKeywordsToAdd := 'none';
  gArmoPatchKeywordsToRemove := 'none';
  gArmoPatchAttachParentSlotKeywordsToAdd := 'none';
  gArmoPatchAttachParentSlotKeywordsToRemove := 'none';
  gArmoPatchChangeDamageTypes := 'none';
  gArmoPatchWeightMult := 'none';
  gArmoPatchHealthMult := 'none';
  gArmoPatchBipedSlotsToAdd := 'none';
  gArmoPatchBipedSlotsToRemove := 'none';
  gArmoPatchFilterByArmorTypes := 'none';
end;

//============================================================================
procedure GatherArmoPatchData(e: IInterface);
var
  keywords, apprKeywords, masterAppr, masterObjectEffect: string;
  master: IInterface;
begin
  InitRobCoARMOPatchData;

  gArmoPatchFilterByArmors := RobCoPatchFilterFormIDRef(e);
  keywords := RobCoReadKeywordRefsFromElement(e);
  RobCoApplyKeywordDiffIfCompact(e, keywords, gArmoPatchKeywordsToAdd, gArmoPatchKeywordsToRemove);

  gArmoPatchFullName := RobCoFullNameIfChanged(e);
  gArmoPatchWeight := RobCoDataFieldIfChanged(e, 'Weight');
  gArmoPatchValue := RobCoDataFieldIfChanged(e, 'Value');
  gArmoPatchDamageResist := RobCoDataFieldIfChanged(e, 'Armor Rating');

  if not RobCoFO4Game then
    gArmoPatchFilterByArmorTypes := ReadSkyrimArmorTypeFilter(e);

  if RobCoFO4Game then begin
    gArmoPatchHealth := RobCoDataFieldIfChanged(e, 'Health');
    masterObjectEffect := 'null';
    if RobCoRecordHasExternalMaster(e) then begin
      master := MasterOrSelf(e);
      masterObjectEffect := ReadArmoObjectEffect(master);
    end;
    gArmoPatchObjectEffect := RobCoExportFieldIfChanged(e, ReadArmoObjectEffect(e),
      masterObjectEffect);
    apprKeywords := RobCoReadApprKeywordRefs(e);
    masterAppr := '';
    if RobCoRecordHasExternalMaster(e) then
      masterAppr := RobCoReadApprKeywordRefs(MasterOrSelf(e));
    gArmoPatchAttachParentSlotKeywordsToAdd := RobCoExportListFieldIfChanged(e,
      RobCoNoneIfEmpty(apprKeywords), RobCoNoneIfEmpty(masterAppr));
    if gArmoPatchAttachParentSlotKeywordsToAdd = '' then
      gArmoPatchAttachParentSlotKeywordsToAdd := 'none';
  end;
end;

//============================================================================
function BuildRobCoARMOLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByArmors', gArmoPatchFilterByArmors);
  Result := RobCoAppendPatchField(Result, 'filterByArmorsExcluded', gArmoPatchFilterByArmorsExcluded);
  Result := RobCoAppendPatchField(Result, 'filterByKeywords', gArmoPatchFilterByKeywords);
  Result := RobCoAppendPatchField(Result, 'filterByKeywordsOr', gArmoPatchFilterByKeywordsOr);
  Result := RobCoAppendPatchField(Result, 'filterByKeywordsExcluded', gArmoPatchFilterByKeywordsExcluded);
  Result := RobCoAppendPatchField(Result, 'filterByBipedSlots', gArmoPatchFilterByBipedSlots);
  Result := RobCoAppendPatchField(Result, 'filterByBipedSlotsOr', gArmoPatchFilterByBipedSlotsOr);
  Result := RobCoAppendPatchField(Result, 'filterByBipedSlotsExcluded', gArmoPatchFilterByBipedSlotsExcluded);
  Result := RobCoAppendPatchField(Result, 'filterByArmorTypes', gArmoPatchFilterByArmorTypes);

  Result := RobCoAppendField(Result, 'fullName', gArmoPatchFullName, False);
  Result := RobCoAppendNumericField(Result, 'damageResist', gArmoPatchDamageResist);
  Result := RobCoAppendNumericField(Result, 'weight', gArmoPatchWeight);
  Result := RobCoAppendNumericField(Result, 'value', gArmoPatchValue);

  if RobCoFO4Game then begin
    Result := RobCoAppendNumericField(Result, 'health', gArmoPatchHealth);
    Result := RobCoAppendField(Result, 'objectEffect', gArmoPatchObjectEffect, True);
    Result := RobCoAppendField(Result, 'changeDamageTypes', gArmoPatchChangeDamageTypes, True);
    Result := RobCoAppendNumericField(Result, 'weightMult', gArmoPatchWeightMult);
    Result := RobCoAppendNumericField(Result, 'healthMult', gArmoPatchHealthMult);
    Result := RobCoAppendField(Result, 'keywordsToAdd', gArmoPatchKeywordsToAdd, True);
    Result := RobCoAppendField(Result, 'keywordsToRemove', gArmoPatchKeywordsToRemove, True);
    Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToAdd',
      gArmoPatchAttachParentSlotKeywordsToAdd, True);
    Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToRemove',
      gArmoPatchAttachParentSlotKeywordsToRemove, True);
    Result := RobCoAppendField(Result, 'bipedSlotsToAdd', gArmoPatchBipedSlotsToAdd, True);
    Result := RobCoAppendField(Result, 'bipedSlotsToRemove', gArmoPatchBipedSlotsToRemove, True);
  end else begin
    Result := RobCoAppendField(Result, 'keywordsToAdd', gArmoPatchKeywordsToAdd, False);
    Result := RobCoAppendField(Result, 'keywordsToRemove', gArmoPatchKeywordsToRemove, True);
  end;
end;

//============================================================================
function RobCoArmoFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  apprKeywords, masterAppr: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if RobCoReadDataField(e, 'Value') <> RobCoReadDataField(master, 'Value') then
    Exit;
  if RobCoReadDataField(e, 'Armor Rating') <> RobCoReadDataField(master, 'Armor Rating') then
    Exit;
  if not RobCoKeywordRefsUnchangedVsMaster(e) then
    Exit;
  if RobCoFO4Game then begin
    if RobCoReadDataField(e, 'Health') <> RobCoReadDataField(master, 'Health') then
      Exit;
    if ReadArmoObjectEffect(e) <> ReadArmoObjectEffect(master) then
      Exit;
    apprKeywords := RobCoReadApprKeywordRefs(e);
    masterAppr := RobCoReadApprKeywordRefs(master);
    if not RobCoListFieldUnchangedVsMaster(e, apprKeywords, masterAppr) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure RobCoReadArmoPatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  RobCoSnapReadKeywordsToScratch(e);
  gRobCoSnapFullName := RobCoReadFullName(e);
  gRobCoSnapMasterFullName := '';
  gRobCoSnapWeight := RobCoReadDataField(e, 'Weight');
  gRobCoSnapMasterWeight := '';
  gRobCoSnapValue := RobCoReadDataField(e, 'Value');
  gRobCoSnapMasterValue := '';
  gRobCoSnapArmorRating := RobCoReadDataField(e, 'Armor Rating');
  gRobCoSnapMasterArmorRating := '';
  gRobCoSnapHealth := '';
  gRobCoSnapMasterHealth := '';
  gRobCoSnapObjectEffect := 'null';
  gRobCoSnapMasterObjectEffect := 'null';
  gRobCoSnapApprKw := '';
  gRobCoSnapMasterApprKw := '';
  if RobCoFO4Game then begin
    gRobCoSnapHealth := RobCoReadDataField(e, 'Health');
    gRobCoSnapObjectEffect := ReadArmoObjectEffect(e);
    RobCoSnapReadApprKwToScratch(e);
  end;
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterFullName := RobCoReadFullName(gRobCoSnapMaster);
    gRobCoSnapMasterWeight := RobCoReadDataField(gRobCoSnapMaster, 'Weight');
    gRobCoSnapMasterValue := RobCoReadDataField(gRobCoSnapMaster, 'Value');
    gRobCoSnapMasterArmorRating := RobCoReadDataField(gRobCoSnapMaster, 'Armor Rating');
    if RobCoFO4Game then begin
      gRobCoSnapMasterHealth := RobCoReadDataField(gRobCoSnapMaster, 'Health');
      gRobCoSnapMasterObjectEffect := ReadArmoObjectEffect(gRobCoSnapMaster);
    end;
  end;
end;

//============================================================================
function RobCoArmoFieldsUnchangedFromScratch: boolean;
begin
  Result := False;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapFullName <> gRobCoSnapMasterFullName then
    Exit;
  if gRobCoSnapWeight <> gRobCoSnapMasterWeight then
    Exit;
  if gRobCoSnapValue <> gRobCoSnapMasterValue then
    Exit;
  if gRobCoSnapArmorRating <> gRobCoSnapMasterArmorRating then
    Exit;
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapKeywords, gRobCoSnapMasterKeywords) then
    Exit;
  if RobCoFO4Game then begin
    if gRobCoSnapHealth <> gRobCoSnapMasterHealth then
      Exit;
    if gRobCoSnapObjectEffect <> gRobCoSnapMasterObjectEffect then
      Exit;
    if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapApprKw, gRobCoSnapMasterApprKw) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure GatherArmoPatchDataFromScratch(e: IInterface);
begin
  InitRobCoARMOPatchData;
  gArmoPatchFilterByArmors := RobCoPatchFilterFormIDRef(e);
  RobCoApplyKeywordDiffIfCompact(e, gRobCoSnapKeywords,
    gArmoPatchKeywordsToAdd, gArmoPatchKeywordsToRemove);
  gArmoPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapFullName, gRobCoSnapMasterFullName);
  gArmoPatchWeight := RobCoExportFieldIfChanged(e, gRobCoSnapWeight, gRobCoSnapMasterWeight);
  gArmoPatchValue := RobCoExportFieldIfChanged(e, gRobCoSnapValue, gRobCoSnapMasterValue);
  gArmoPatchDamageResist := RobCoExportFieldIfChanged(e, gRobCoSnapArmorRating,
    gRobCoSnapMasterArmorRating);
  if not RobCoFO4Game then
    gArmoPatchFilterByArmorTypes := ReadSkyrimArmorTypeFilter(e);
  if RobCoFO4Game then begin
    gArmoPatchHealth := RobCoExportFieldIfChanged(e, gRobCoSnapHealth, gRobCoSnapMasterHealth);
    gArmoPatchObjectEffect := RobCoExportFieldIfChanged(e, gRobCoSnapObjectEffect,
      gRobCoSnapMasterObjectEffect);
    gArmoPatchAttachParentSlotKeywordsToAdd := RobCoExportListFieldIfChanged(e,
      RobCoNoneIfEmpty(gRobCoSnapApprKw), RobCoNoneIfEmpty(gRobCoSnapMasterApprKw));
    if gArmoPatchAttachParentSlotKeywordsToAdd = '' then
      gArmoPatchAttachParentSlotKeywordsToAdd := 'none';
  end;
end;

//============================================================================
procedure ExportARMOToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'ARMO' then
    Exit;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoSnapTryEarlyPregatherSkipArmo(e) then begin
      RobCoSnapRecordEarlyPregatherSkip;
      Exit;
    end;
  end;

  RobCoReadArmoPatchInputs(e);
  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoArmoFieldsUnchangedFromScratch then begin
      Exit;
    end;
  end;

  GatherArmoPatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'ARMO', shortComment, BuildRobCoARMOLine);
end;


//============================================================================
// WEAP
//============================================================================


var
  gWeapPatchFilterByWeapons, gWeapPatchFilterByAmmos, gWeapPatchFilterByWeaponsExcluded: string;
  gWeapPatchFilterByKeywords, gWeapPatchFilterByKeywordsOr, gWeapPatchFilterByKeywordsExcluded: string;
  gWeapPatchFilterByHasAmmoFromWeaponList: string;
  gWeapPatchFullName, gWeapPatchAttackDamage, gWeapPatchBashDamage, gWeapPatchWeight, gWeapPatchValue: string;
  gWeapPatchOutOfRangeDamageMult, gWeapPatchKeywordsToAdd, gWeapPatchKeywordsToRemove, gWeapPatchSetNewAmmo, gWeapPatchAimModel: string;
  gWeapPatchDamageTypesToChange, gWeapPatchDamageTypesToRemove: string;
  gWeapPatchConeIronSightsMultiplier, gWeapPatchRecoilDiminishSpringForce: string;
  gWeapPatchRecoilPerShotMin, gWeapPatchRecoilPerShotMax, gWeapPatchAttackActionPointCost: string;
  gWeapPatchWeaponHitType, gWeapPatchSoundLevel, gWeapPatchOverrideProjectile, gWeapPatchSetNewAmmoList: string;
  gWeapPatchAttachParentSlotKeywordsToAdd, gWeapPatchAttachParentSlotKeywordsToRemove: string;

//============================================================================
function ReadWeapBashDamage(e: IInterface): string;
begin
  Result := '';
  if ElementExists(e, 'DNAM\Secondary Damage') then
    Result := GetElementEditValues(e, 'DNAM\Secondary Damage')
  else if ElementExists(e, 'DNAM\Bash Damage') then
    Result := GetElementEditValues(e, 'DNAM\Bash Damage');
end;

//============================================================================
function ReadWeapAmmoRef(e: IInterface): string;
begin
  Result := RobCoReadFormLinkFirst(e, 'DNAM\Ammo', 'DNAM\Ammunition');
  if Result = '' then
    Result := RobCoReadFormLinkRef(e, 'CNAM');
end;

//============================================================================
function ReadWeapAimModelRef(e: IInterface): string;
begin
  Result := RobCoReadFormLinkPathOrRef(e, 'Aim Model', 'AIMP');
end;

//============================================================================
procedure InitRobCoWEAPPatchData;
begin
  gWeapPatchFilterByWeapons := 'none';
  gWeapPatchFilterByAmmos := 'none';
  gWeapPatchFilterByWeaponsExcluded := 'none';
  gWeapPatchFilterByKeywords := 'none';
  gWeapPatchFilterByKeywordsOr := 'none';
  gWeapPatchFilterByKeywordsExcluded := 'none';
  gWeapPatchFilterByHasAmmoFromWeaponList := 'none';
  gWeapPatchFullName := '';
  gWeapPatchAttackDamage := '';
  gWeapPatchBashDamage := '';
  gWeapPatchWeight := '';
  gWeapPatchValue := '';
  gWeapPatchOutOfRangeDamageMult := 'none';
  gWeapPatchKeywordsToAdd := 'none';
  gWeapPatchKeywordsToRemove := 'none';
  gWeapPatchSetNewAmmo := 'none';
  gWeapPatchAimModel := 'none';
  gWeapPatchDamageTypesToChange := 'none';
  gWeapPatchDamageTypesToRemove := 'none';
  gWeapPatchConeIronSightsMultiplier := 'none';
  gWeapPatchRecoilDiminishSpringForce := 'none';
  gWeapPatchRecoilPerShotMin := 'none';
  gWeapPatchRecoilPerShotMax := 'none';
  gWeapPatchAttackActionPointCost := 'none';
  gWeapPatchWeaponHitType := 'none';
  gWeapPatchSoundLevel := 'none';
  gWeapPatchOverrideProjectile := 'none';
  gWeapPatchSetNewAmmoList := 'none';
  gWeapPatchAttachParentSlotKeywordsToAdd := 'none';
  gWeapPatchAttachParentSlotKeywordsToRemove := 'none';
end;

//============================================================================
procedure GatherWeapPatchData(e: IInterface);
var
  keywords, ammoRef, aimModel, apprKeywords, masterAppr, masterAmmo, masterAim, masterBash: string;
  master: IInterface;
begin
  InitRobCoWEAPPatchData;

  gWeapPatchFilterByWeapons := RobCoPatchFilterFormIDRef(e);
  keywords := RobCoReadKeywordRefsFromElement(e);
  RobCoApplyKeywordDiffIfCompact(e, keywords, gWeapPatchKeywordsToAdd, gWeapPatchKeywordsToRemove);

  gWeapPatchFullName := RobCoFullNameIfChanged(e);
  gWeapPatchAttackDamage := RobCoDataFieldIfChanged(e, 'Damage');
  gWeapPatchWeight := RobCoDataFieldIfChanged(e, 'Weight');
  gWeapPatchValue := RobCoDataFieldIfChanged(e, 'Value');

  if RobCoFO4Game then begin
    masterBash := '';
    masterAmmo := '';
    masterAim := '';
    masterAppr := '';
    if RobCoRecordHasExternalMaster(e) then begin
      master := MasterOrSelf(e);
      masterBash := ReadWeapBashDamage(master);
      masterAmmo := ReadWeapAmmoRef(master);
      masterAim := ReadWeapAimModelRef(master);
      masterAppr := RobCoReadApprKeywordRefs(master);
    end;
    gWeapPatchBashDamage := RobCoExportFieldIfChanged(e, ReadWeapBashDamage(e), masterBash);
    ammoRef := ReadWeapAmmoRef(e);
    gWeapPatchSetNewAmmo := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(ammoRef),
      RobCoNoneIfEmpty(masterAmmo));
    aimModel := ReadWeapAimModelRef(e);
    gWeapPatchAimModel := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(aimModel),
      RobCoNoneIfEmpty(masterAim));
    apprKeywords := RobCoReadApprKeywordRefs(e);
    gWeapPatchAttachParentSlotKeywordsToAdd := RobCoExportListFieldIfChanged(e,
      RobCoNoneIfEmpty(apprKeywords), RobCoNoneIfEmpty(masterAppr));
    if gWeapPatchAttachParentSlotKeywordsToAdd = '' then
      gWeapPatchAttachParentSlotKeywordsToAdd := 'none';
  end;
end;

//============================================================================
function BuildRobCoWEAPLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByWeapons', gWeapPatchFilterByWeapons);
  Result := RobCoAppendPatchField(Result, 'filterByAmmos', gWeapPatchFilterByAmmos);
  Result := RobCoAppendPatchField(Result, 'filterByWeaponsExcluded', gWeapPatchFilterByWeaponsExcluded);
  Result := RobCoAppendPatchField(Result, 'filterByKeywords', gWeapPatchFilterByKeywords);
  Result := RobCoAppendPatchField(Result, 'filterByKeywordsOr', gWeapPatchFilterByKeywordsOr);
  Result := RobCoAppendPatchField(Result, 'filterByKeywordsExcluded', gWeapPatchFilterByKeywordsExcluded);
  Result := RobCoAppendPatchField(Result, 'filterByHasAmmoFromWeaponList', gWeapPatchFilterByHasAmmoFromWeaponList);

  Result := RobCoAppendField(Result, 'fullName', gWeapPatchFullName, False);

  if RobCoFO4Game then begin
    Result := RobCoAppendNumericField(Result, 'attackDamage', gWeapPatchAttackDamage);
    Result := RobCoAppendNumericField(Result, 'bashDamage', gWeapPatchBashDamage);
    Result := RobCoAppendNumericField(Result, 'outOfRangeDamageMult', gWeapPatchOutOfRangeDamageMult);
    Result := RobCoAppendField(Result, 'keywordsToAdd', gWeapPatchKeywordsToAdd, True);
    Result := RobCoAppendField(Result, 'keywordsToRemove', gWeapPatchKeywordsToRemove, True);
    Result := RobCoAppendField(Result, 'setNewAmmo', gWeapPatchSetNewAmmo, True);
    Result := RobCoAppendField(Result, 'aimModel', gWeapPatchAimModel, True);
    Result := RobCoAppendNumericField(Result, 'weight', gWeapPatchWeight);
    Result := RobCoAppendNumericField(Result, 'value', gWeapPatchValue);
    Result := RobCoAppendField(Result, 'damageTypesToChange', gWeapPatchDamageTypesToChange, True);
    Result := RobCoAppendField(Result, 'damageTypesToRemove', gWeapPatchDamageTypesToRemove, True);
    Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToAdd',
      gWeapPatchAttachParentSlotKeywordsToAdd, True);
    Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToRemove',
      gWeapPatchAttachParentSlotKeywordsToRemove, True);
  end else begin
    Result := RobCoAppendNumericField(Result, 'attackDamage', gWeapPatchAttackDamage);
    Result := RobCoAppendNumericField(Result, 'weight', gWeapPatchWeight);
    Result := RobCoAppendNumericField(Result, 'value', gWeapPatchValue);
    Result := RobCoAppendField(Result, 'keywordsToAdd', gWeapPatchKeywordsToAdd, False);
    Result := RobCoAppendField(Result, 'keywordsToRemove', gWeapPatchKeywordsToRemove, True);
  end;
end;

//============================================================================
function RobCoWeapFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  apprKeywords, masterAppr: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Damage') <> RobCoReadDataField(master, 'Damage') then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if RobCoReadDataField(e, 'Value') <> RobCoReadDataField(master, 'Value') then
    Exit;
  if not RobCoKeywordRefsUnchangedVsMaster(e) then
    Exit;
  if RobCoFO4Game then begin
    if ReadWeapBashDamage(e) <> ReadWeapBashDamage(master) then
      Exit;
    if ReadWeapAmmoRef(e) <> ReadWeapAmmoRef(master) then
      Exit;
    if ReadWeapAimModelRef(e) <> ReadWeapAimModelRef(master) then
      Exit;
    apprKeywords := RobCoReadApprKeywordRefs(e);
    masterAppr := RobCoReadApprKeywordRefs(master);
    if not RobCoListFieldUnchangedVsMaster(e, apprKeywords, masterAppr) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure RobCoReadWeapPatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  RobCoSnapReadKeywordsToScratch(e);
  gRobCoSnapFullName := RobCoReadFullName(e);
  gRobCoSnapMasterFullName := '';
  gRobCoSnapDamage := RobCoReadDataField(e, 'Damage');
  gRobCoSnapMasterDamage := '';
  gRobCoSnapWeight := RobCoReadDataField(e, 'Weight');
  gRobCoSnapMasterWeight := '';
  gRobCoSnapValue := RobCoReadDataField(e, 'Value');
  gRobCoSnapMasterValue := '';
  gRobCoSnapBashDamage := '';
  gRobCoSnapMasterBashDamage := '';
  gRobCoSnapAmmoRef := '';
  gRobCoSnapMasterAmmoRef := '';
  gRobCoSnapAimModel := '';
  gRobCoSnapMasterAimModel := '';
  gRobCoSnapApprKw := '';
  gRobCoSnapMasterApprKw := '';
  if RobCoFO4Game then begin
    gRobCoSnapBashDamage := ReadWeapBashDamage(e);
    gRobCoSnapAmmoRef := ReadWeapAmmoRef(e);
    gRobCoSnapAimModel := ReadWeapAimModelRef(e);
    RobCoSnapReadApprKwToScratch(e);
  end;
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterFullName := RobCoReadFullName(gRobCoSnapMaster);
    gRobCoSnapMasterDamage := RobCoReadDataField(gRobCoSnapMaster, 'Damage');
    gRobCoSnapMasterWeight := RobCoReadDataField(gRobCoSnapMaster, 'Weight');
    gRobCoSnapMasterValue := RobCoReadDataField(gRobCoSnapMaster, 'Value');
    if RobCoFO4Game then begin
      gRobCoSnapMasterBashDamage := ReadWeapBashDamage(gRobCoSnapMaster);
      gRobCoSnapMasterAmmoRef := ReadWeapAmmoRef(gRobCoSnapMaster);
      gRobCoSnapMasterAimModel := ReadWeapAimModelRef(gRobCoSnapMaster);
    end;
  end;
end;

//============================================================================
function RobCoWeapFieldsUnchangedFromScratch: boolean;
begin
  Result := False;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapFullName <> gRobCoSnapMasterFullName then
    Exit;
  if gRobCoSnapDamage <> gRobCoSnapMasterDamage then
    Exit;
  if gRobCoSnapWeight <> gRobCoSnapMasterWeight then
    Exit;
  if gRobCoSnapValue <> gRobCoSnapMasterValue then
    Exit;
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapKeywords, gRobCoSnapMasterKeywords) then
    Exit;
  if RobCoFO4Game then begin
    if gRobCoSnapBashDamage <> gRobCoSnapMasterBashDamage then
      Exit;
    if gRobCoSnapAmmoRef <> gRobCoSnapMasterAmmoRef then
      Exit;
    if gRobCoSnapAimModel <> gRobCoSnapMasterAimModel then
      Exit;
    if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapApprKw, gRobCoSnapMasterApprKw) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure GatherWeapPatchDataFromScratch(e: IInterface);
begin
  InitRobCoWEAPPatchData;
  gWeapPatchFilterByWeapons := RobCoPatchFilterFormIDRef(e);
  RobCoApplyKeywordDiffIfCompact(e, gRobCoSnapKeywords,
    gWeapPatchKeywordsToAdd, gWeapPatchKeywordsToRemove);
  gWeapPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapFullName, gRobCoSnapMasterFullName);
  gWeapPatchAttackDamage := RobCoExportFieldIfChanged(e, gRobCoSnapDamage, gRobCoSnapMasterDamage);
  gWeapPatchWeight := RobCoExportFieldIfChanged(e, gRobCoSnapWeight, gRobCoSnapMasterWeight);
  gWeapPatchValue := RobCoExportFieldIfChanged(e, gRobCoSnapValue, gRobCoSnapMasterValue);
  if RobCoFO4Game then begin
    gWeapPatchBashDamage := RobCoExportFieldIfChanged(e, gRobCoSnapBashDamage,
      gRobCoSnapMasterBashDamage);
    gWeapPatchSetNewAmmo := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(gRobCoSnapAmmoRef),
      RobCoNoneIfEmpty(gRobCoSnapMasterAmmoRef));
    gWeapPatchAimModel := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(gRobCoSnapAimModel),
      RobCoNoneIfEmpty(gRobCoSnapMasterAimModel));
    gWeapPatchAttachParentSlotKeywordsToAdd := RobCoExportListFieldIfChanged(e,
      RobCoNoneIfEmpty(gRobCoSnapApprKw), RobCoNoneIfEmpty(gRobCoSnapMasterApprKw));
    if gWeapPatchAttachParentSlotKeywordsToAdd = '' then
      gWeapPatchAttachParentSlotKeywordsToAdd := 'none';
  end;
end;

//============================================================================
procedure ExportWEAPToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'WEAP' then
    Exit;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoSnapTryEarlyPregatherSkipWeap(e) then begin
      RobCoSnapRecordEarlyPregatherSkip;
      Exit;
    end;
  end;

  RobCoReadWeapPatchInputs(e);
  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoWeapFieldsUnchangedFromScratch then begin
      Exit;
    end;
  end;

  GatherWeapPatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'WEAP', shortComment, BuildRobCoWEAPLine);
end;


//============================================================================
// ALCH
//============================================================================


var
  gAlchPatchFilterByAlchs, gAlchPatchFilterByAlchsExcluded: string;
  gAlchPatchFilterByKeywords, gAlchPatchFilterByKeywordsOr, gAlchPatchFilterByKeywordsExcluded: string;
  gAlchPatchFilterByMgefs, gAlchPatchFilterByMgefsOr, gAlchPatchFilterByMgefsExcluded: string;
  gAlchPatchFullName, gAlchPatchKeywordsToAdd, gAlchPatchKeywordsToRemove: string;
  gAlchPatchMgefsToAdd, gAlchPatchMgefsToChange, gAlchPatchMgefsToRemove: string;
  gAlchPatchWeight, gAlchPatchValue: string;

//============================================================================
function ReadAlchMgefsToAdd(e: IInterface): string;
var
  effects, effect, mgef: IInterface;
  i, magnitude, duration, area: integer;
begin
  Result := '';
  effects := ElementByName(e, 'Effects');
  if not Assigned(effects) then
    Exit;

  RobCoSnapEnsurePartsScratch;
  for i := 0 to Pred(ElementCount(effects)) do begin
      effect := ElementByIndex(effects, i);
      mgef := LinksTo(ElementByPath(effect, 'EFID'));
      if not Assigned(mgef) then
        Continue;

      magnitude := 0;
      duration := 0;
      area := 0;
      if ElementExists(effect, 'EFIT\Magnitude') then
        magnitude := Round(GetElementNativeValues(effect, 'EFIT\Magnitude'))
      else if ElementExists(effect, 'DATA\Magnitude') then
        magnitude := Round(GetElementNativeValues(effect, 'DATA\Magnitude'));
      if ElementExists(effect, 'EFIT\Duration') then
        duration := Round(GetElementNativeValues(effect, 'EFIT\Duration'))
      else if ElementExists(effect, 'DATA\Duration') then
        duration := Round(GetElementNativeValues(effect, 'DATA\Duration'));
      if ElementExists(effect, 'EFIT\Area') then
        area := Round(GetElementNativeValues(effect, 'EFIT\Area'))
      else if ElementExists(effect, 'DATA\Area') then
        area := Round(GetElementNativeValues(effect, 'DATA\Area'));

      gRobCoSnapPartsScratch.Add(
        RobCoMasterFormIDRef(mgef) + '~' + IntToStr(magnitude) + '~' +
        IntToStr(duration) + '~' + IntToStr(area)
      );
    end;
  Result := RobCoJoinParts(gRobCoSnapPartsScratch);
end;

//============================================================================
function RobCoAlchMgefRefFromKey(const effectKey: string): string;
var
  p: integer;
begin
  p := Pos('~', effectKey);
  if p > 0 then
    Result := Copy(effectKey, 1, p - 1)
  else
    Result := Trim(effectKey);
end;

//============================================================================
procedure RobCoAlchMgefBuildMultiset(const listText: string; ms: TStringList);
var
  i: integer;
  key: string;
begin
  ms.Clear;
  RobCoSnapEnsureCommaScratch;
  RobCoParseCommaList(gRobCoSnapCommaScratch, listText);
  for i := 0 to Pred(gRobCoSnapCommaScratch.Count) do begin
    key := Trim(gRobCoSnapCommaScratch[i]);
    if key <> '' then
      RobCoMultisetInc(ms, key);
  end;
end;

//============================================================================
procedure RobCoAlchMgefPairAddRemove(addParts, remParts, changeParts: TStringList);
var
  i, j, k: integer;
  addKey, remKey, addRef, remRef: string;
begin
  i := 0;
  while i < addParts.Count do begin
    addKey := addParts[i];
    addRef := RobCoAlchMgefRefFromKey(addKey);
    j := -1;
    for k := 0 to Pred(remParts.Count) do begin
      remRef := RobCoAlchMgefRefFromKey(remParts[k]);
      if SameText(addRef, remRef) then begin
        j := k;
        Break;
      end;
    end;
    if j < 0 then begin
      Inc(i);
      Continue;
    end;
    remKey := remParts[j];
    if addKey = remKey then begin
      addParts.Delete(i);
      remParts.Delete(j);
    end else begin
      changeParts.Add(addKey);
      addParts.Delete(i);
      remParts.Delete(j);
    end;
  end;
end;

//============================================================================
var
  gRobCoAlchDiffPluginMs: TStringList;
  gRobCoAlchDiffMasterMs: TStringList;
  gRobCoAlchDiffUnionKeys: TStringList;
  gRobCoAlchDiffAdd: TStringList;
  gRobCoAlchDiffChange: TStringList;
  gRobCoAlchDiffRem: TStringList;

//============================================================================
procedure RobCoEnsureAlchDiffScratch;
begin
  if not Assigned(gRobCoAlchDiffPluginMs) then begin
    gRobCoAlchDiffPluginMs := TStringList.Create;
    gRobCoAlchDiffMasterMs := TStringList.Create;
    gRobCoAlchDiffUnionKeys := TStringList.Create;
    gRobCoAlchDiffAdd := TStringList.Create;
    gRobCoAlchDiffChange := TStringList.Create;
    gRobCoAlchDiffRem := TStringList.Create;
  end;
  gRobCoAlchDiffPluginMs.Clear;
  gRobCoAlchDiffMasterMs.Clear;
  gRobCoAlchDiffUnionKeys.Clear;
  gRobCoAlchDiffAdd.Clear;
  gRobCoAlchDiffChange.Clear;
  gRobCoAlchDiffRem.Clear;
  gRobCoAlchDiffUnionKeys.Sorted := True;
  gRobCoAlchDiffUnionKeys.Duplicates := dupIgnore;
end;

//============================================================================
procedure DiffAlchMgefs(const pluginMgefs, masterMgefs: string;
  var mgefsToAdd, mgefsToChange, mgefsToRemove: string);
var
  i, j, pluginCount, masterCount, n: integer;
  key: string;
begin
  mgefsToAdd := 'none';
  mgefsToChange := 'none';
  mgefsToRemove := 'none';

  RobCoEnsureAlchDiffScratch;
  RobCoAlchMgefBuildMultiset(pluginMgefs, gRobCoAlchDiffPluginMs);
  RobCoAlchMgefBuildMultiset(masterMgefs, gRobCoAlchDiffMasterMs);
  RobCoMultisetSort(gRobCoAlchDiffPluginMs);
  RobCoMultisetSort(gRobCoAlchDiffMasterMs);

  if RobCoMultisetEqual(gRobCoAlchDiffPluginMs, gRobCoAlchDiffMasterMs) then
    Exit;

  for i := 0 to Pred(gRobCoAlchDiffPluginMs.Count) do
    gRobCoAlchDiffUnionKeys.Add(gRobCoAlchDiffPluginMs[i]);
  for i := 0 to Pred(gRobCoAlchDiffMasterMs.Count) do
    gRobCoAlchDiffUnionKeys.Add(gRobCoAlchDiffMasterMs[i]);

  for i := 0 to Pred(gRobCoAlchDiffUnionKeys.Count) do begin
    key := gRobCoAlchDiffUnionKeys[i];
    pluginCount := RobCoMultisetCount(gRobCoAlchDiffPluginMs, key);
    masterCount := RobCoMultisetCount(gRobCoAlchDiffMasterMs, key);
    n := pluginCount - masterCount;
    if n > 0 then
      for j := 1 to n do
        gRobCoAlchDiffAdd.Add(key);
    n := masterCount - pluginCount;
    if n > 0 then
      for j := 1 to n do
        gRobCoAlchDiffRem.Add(key);
  end;

  RobCoAlchMgefPairAddRemove(gRobCoAlchDiffAdd, gRobCoAlchDiffRem, gRobCoAlchDiffChange);

  mgefsToAdd := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoAlchDiffAdd));
  mgefsToChange := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoAlchDiffChange));
  mgefsToRemove := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoAlchDiffRem));
end;

//============================================================================
procedure InitRobCoALCHPatchData;
begin
  gAlchPatchFilterByAlchs := 'none';
  gAlchPatchFilterByAlchsExcluded := 'none';
  gAlchPatchFilterByKeywords := 'none';
  gAlchPatchFilterByKeywordsOr := 'none';
  gAlchPatchFilterByKeywordsExcluded := 'none';
  gAlchPatchFilterByMgefs := 'none';
  gAlchPatchFilterByMgefsOr := 'none';
  gAlchPatchFilterByMgefsExcluded := 'none';
  gAlchPatchFullName := '';
  gAlchPatchKeywordsToAdd := 'none';
  gAlchPatchKeywordsToRemove := 'none';
  gAlchPatchMgefsToAdd := 'none';
  gAlchPatchMgefsToChange := 'none';
  gAlchPatchMgefsToRemove := 'none';
  gAlchPatchWeight := '';
  gAlchPatchValue := '';
end;

//============================================================================
procedure GatherAlchPatchData(e: IInterface);
var
  keywords, mgefs, masterMgefs: string;
  master: IInterface;
begin
  InitRobCoALCHPatchData;

  gAlchPatchFilterByAlchs := RobCoPatchFilterFormIDRef(e);
  keywords := RobCoReadKeywordRefsFromElement(e);
  mgefs := ReadAlchMgefsToAdd(e);

  gAlchPatchFullName := RobCoFullNameIfChanged(e);
  gAlchPatchWeight := RobCoDataFieldIfChanged(e, 'Weight');
  gAlchPatchValue := RobCoDataFieldIfChanged(e, 'Value');

  RobCoApplyKeywordDiffIfCompact(e, keywords, gAlchPatchKeywordsToAdd, gAlchPatchKeywordsToRemove);

  if RobCoRecordHasExternalMaster(e) then begin
    if RobCoSnapshotUseCompactFieldDiff then begin
      master := MasterOrSelf(e);
      masterMgefs := ReadAlchMgefsToAdd(master);
      DiffAlchMgefs(mgefs, masterMgefs, gAlchPatchMgefsToAdd, gAlchPatchMgefsToChange, gAlchPatchMgefsToRemove);
    end else
      gAlchPatchMgefsToAdd := RobCoNoneIfEmpty(mgefs);
  end else
    gAlchPatchMgefsToAdd := RobCoNoneIfEmpty(mgefs);
end;

//============================================================================
//============================================================================
function BuildRobCoALCHLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByAlchs', gAlchPatchFilterByAlchs);
  Result := RobCoAppendPatchField(Result, 'filterByAlchsExcluded', gAlchPatchFilterByAlchsExcluded);
  Result := RobCoAppendPatchField(Result, 'filterByKeywords', gAlchPatchFilterByKeywords);
  Result := RobCoAppendPatchField(Result, 'filterByKeywordsOr', gAlchPatchFilterByKeywordsOr);
  Result := RobCoAppendPatchField(Result, 'filterByKeywordsExcluded', gAlchPatchFilterByKeywordsExcluded);
  Result := RobCoAppendPatchField(Result, 'filterByMgefs', gAlchPatchFilterByMgefs);
  Result := RobCoAppendPatchField(Result, 'filterByMgefsOr', gAlchPatchFilterByMgefsOr);
  Result := RobCoAppendPatchField(Result, 'filterByMgefsExcluded', gAlchPatchFilterByMgefsExcluded);

  Result := RobCoAppendField(Result, 'fullName', gAlchPatchFullName, False);
  Result := RobCoAppendField(Result, 'keywordsToAdd', gAlchPatchKeywordsToAdd, True);
  Result := RobCoAppendField(Result, 'keywordsToRemove', gAlchPatchKeywordsToRemove, True);
  Result := RobCoAppendField(Result, 'mgefsToAdd', gAlchPatchMgefsToAdd, True);
  Result := RobCoAppendField(Result, 'mgefsToChange', gAlchPatchMgefsToChange, True);
  Result := RobCoAppendField(Result, 'mgefsToRemove', gAlchPatchMgefsToRemove, True);
  Result := RobCoAppendNumericField(Result, 'weight', gAlchPatchWeight);
  Result := RobCoAppendNumericField(Result, 'value', gAlchPatchValue);
end;

//============================================================================
function RobCoAlchFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  mgefs, masterMgefs: string;
  mgefsToAdd, mgefsToChange, mgefsToRemove: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if RobCoReadDataField(e, 'Value') <> RobCoReadDataField(master, 'Value') then
    Exit;
  if not RobCoKeywordRefsUnchangedVsMaster(e) then
    Exit;
  mgefs := ReadAlchMgefsToAdd(e);
  masterMgefs := ReadAlchMgefsToAdd(master);
  DiffAlchMgefs(mgefs, masterMgefs, mgefsToAdd, mgefsToChange, mgefsToRemove);
  if mgefsToAdd <> 'none' then
    Exit;
  if mgefsToChange <> 'none' then
    Exit;
  if mgefsToRemove <> 'none' then
    Exit;
  Result := True;
end;

//============================================================================
procedure RobCoReadAlchPatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  RobCoSnapReadKeywordsToScratch(e);
  RobCoSnapReadAlchMgefsToScratch(e);
  gRobCoSnapFullName := RobCoReadFullName(e);
  gRobCoSnapMasterFullName := '';
  gRobCoSnapWeight := RobCoReadDataField(e, 'Weight');
  gRobCoSnapMasterWeight := '';
  gRobCoSnapValue := RobCoReadDataField(e, 'Value');
  gRobCoSnapMasterValue := '';
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterFullName := RobCoReadFullName(gRobCoSnapMaster);
    gRobCoSnapMasterWeight := RobCoReadDataField(gRobCoSnapMaster, 'Weight');
    gRobCoSnapMasterValue := RobCoReadDataField(gRobCoSnapMaster, 'Value');
  end;
end;

//============================================================================
function RobCoAlchFieldsUnchangedFromScratch: boolean;
var
  mgefsToAdd, mgefsToChange, mgefsToRemove: string;
begin
  Result := False;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapFullName <> gRobCoSnapMasterFullName then
    Exit;
  if gRobCoSnapWeight <> gRobCoSnapMasterWeight then
    Exit;
  if gRobCoSnapValue <> gRobCoSnapMasterValue then
    Exit;
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapKeywords, gRobCoSnapMasterKeywords) then
    Exit;
  DiffAlchMgefs(gRobCoSnapMgefs, gRobCoSnapMasterMgefs, mgefsToAdd, mgefsToChange, mgefsToRemove);
  if mgefsToAdd <> 'none' then
    Exit;
  if mgefsToChange <> 'none' then
    Exit;
  if mgefsToRemove <> 'none' then
    Exit;
  Result := True;
end;

//============================================================================
procedure GatherAlchPatchDataFromScratch(e: IInterface);
begin
  InitRobCoALCHPatchData;
  gAlchPatchFilterByAlchs := RobCoPatchFilterFormIDRef(e);
  gAlchPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapFullName, gRobCoSnapMasterFullName);
  gAlchPatchWeight := RobCoExportFieldIfChanged(e, gRobCoSnapWeight, gRobCoSnapMasterWeight);
  gAlchPatchValue := RobCoExportFieldIfChanged(e, gRobCoSnapValue, gRobCoSnapMasterValue);
  RobCoApplyKeywordDiffIfCompact(e, gRobCoSnapKeywords,
    gAlchPatchKeywordsToAdd, gAlchPatchKeywordsToRemove);
  if Assigned(gRobCoSnapMaster) then begin
    if RobCoSnapshotUseCompactFieldDiff then
      DiffAlchMgefs(gRobCoSnapMgefs, gRobCoSnapMasterMgefs,
        gAlchPatchMgefsToAdd, gAlchPatchMgefsToChange, gAlchPatchMgefsToRemove)
    else
      gAlchPatchMgefsToAdd := RobCoNoneIfEmpty(gRobCoSnapMgefs);
  end else
    gAlchPatchMgefsToAdd := RobCoNoneIfEmpty(gRobCoSnapMgefs);
end;

//============================================================================
procedure ExportALCHToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'ALCH' then
    Exit;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoSnapTryEarlyPregatherSkipAlch(e) then begin
      RobCoSnapRecordEarlyPregatherSkip;
      Exit;
    end;
  end;

  RobCoReadAlchPatchInputs(e);
  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoAlchFieldsUnchangedFromScratch then begin
      Exit;
    end;
  end;

  GatherAlchPatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'ALCH', shortComment, BuildRobCoALCHLine);
end;


//============================================================================
// OMOD
//============================================================================


var
  gOmodPatchConnectionAnd, gOmodPatchFilterByOMod, gOmodPatchFilterByOModExcluded: string;
  gOmodPatchFilterByFormType, gOmodPatchFilterByNameContainsAnd, gOmodPatchFilterByNameContainsOr: string;
  gOmodPatchFilterByNameContainsExclude, gOmodPatchFilterByPropertiesAnd, gOmodPatchFilterByPropertiesOr: string;
  gOmodPatchFilterByPropertiesExclude, gOmodPatchFilterByAttachPoint: string;
  gOmodPatchFullName, gOmodPatchSetAttachPoint, gOmodPatchAttachParentSlotKeywordsToAdd: string;
  gOmodPatchChangeOModPropertiesFloat, gOmodPatchChangeOModPropertiesVP, gOmodPatchChangeOModPropertiesForm: string;

  gRobCoOmodScratchSeenFloat, gRobCoOmodScratchSeenVp, gRobCoOmodScratchSeenForm: TStringList;
  gRobCoOmodScratchFloat, gRobCoOmodScratchVp, gRobCoOmodScratchForm: TStringList;
  gRobCoOmodScratchMasterFloat, gRobCoOmodScratchMasterVp, gRobCoOmodScratchMasterForm: TStringList;

//============================================================================
procedure RobCoOmodEnsurePropListScratch;
begin
  if not Assigned(gRobCoOmodScratchFloat) then begin
    gRobCoOmodScratchFloat := TStringList.Create;
    gRobCoOmodScratchVp := TStringList.Create;
    gRobCoOmodScratchForm := TStringList.Create;
    gRobCoOmodScratchMasterFloat := TStringList.Create;
    gRobCoOmodScratchMasterVp := TStringList.Create;
    gRobCoOmodScratchMasterForm := TStringList.Create;
  end;
  gRobCoOmodScratchFloat.Clear;
  gRobCoOmodScratchVp.Clear;
  gRobCoOmodScratchForm.Clear;
  gRobCoOmodScratchMasterFloat.Clear;
  gRobCoOmodScratchMasterVp.Clear;
  gRobCoOmodScratchMasterForm.Clear;
end;

//============================================================================
procedure RobCoOmodEnsureSeenScratch;
begin
  if not Assigned(gRobCoOmodScratchSeenFloat) then
    gRobCoOmodScratchSeenFloat := TStringList.Create;
  if not Assigned(gRobCoOmodScratchSeenVp) then
    gRobCoOmodScratchSeenVp := TStringList.Create;
  if not Assigned(gRobCoOmodScratchSeenForm) then
    gRobCoOmodScratchSeenForm := TStringList.Create;
  gRobCoOmodScratchSeenFloat.Clear;
  gRobCoOmodScratchSeenVp.Clear;
  gRobCoOmodScratchSeenForm.Clear;
end;

//============================================================================
function OmodPropertyKeyForExport(const propName: string): string;
var
  s: string;
begin
  Result := '';
  s := Trim(propName);
  if s = '' then
    Exit;

  if (Length(s) >= 2) and (s[2] in ['A'..'Z']) and (s[1] in ['a'..'z']) then
    Delete(s, 1, 1);

  Result := LowerCase(Copy(s, 1, 1)) + Copy(s, 2, MaxInt);
end;

//============================================================================
function OmodValueTypeIsVP(const valueType: string): boolean;
begin
  Result :=
    (Pos('FormID', valueType) > 0) and
    (Pos('Float', valueType) > 0);
end;

//============================================================================
function OmodValueTypeIsForm(const valueType: string): boolean;
begin
  Result :=
    (Pos('FormID', valueType) > 0) and
    (Pos('Int', valueType) > 0) and
    (Pos('Float', valueType) = 0);
end;

//============================================================================
function OmodPropObjectLink(prop: IInterface): IInterface;
begin
  Result := RobCoReadUnionFormLink(prop);
end;

//============================================================================
function OmodPropFloatValue(prop: IInterface): string;
begin
  Result := '';
  if not Assigned(prop) then
    Exit;

  if ElementExists(prop, 'Value\Float') then
    Result := GetElementEditValues(prop, 'Value\Float')
  else if ElementExists(prop, 'Float') then
    Result := GetElementEditValues(prop, 'Float')
  else if ElementExists(prop, 'First Value') then
    Result := GetElementEditValues(prop, 'First Value')
  else if ElementExists(prop, 'Value 1') then
    Result := GetElementEditValues(prop, 'Value 1');
end;

//============================================================================
function OmodPropIntValue(prop: IInterface): string;
begin
  Result := '';
  if not Assigned(prop) then
    Exit;

  if ElementExists(prop, 'Value\Int') then
    Result := GetElementEditValues(prop, 'Value\Int')
  else if ElementExists(prop, 'Int') then
    Result := GetElementEditValues(prop, 'Int')
  else if ElementExists(prop, 'Second Value') then
    Result := GetElementEditValues(prop, 'Second Value')
  else if ElementExists(prop, 'Value 2') then
    Result := GetElementEditValues(prop, 'Value 2');
end;

//============================================================================
function OmodPropFormPairEntry(prop: IInterface): string;
var
  link, link2: IInterface;
  leftRef, rightRef, intVal: string;
begin
  Result := '';
  link := OmodPropObjectLink(prop);
  if not Assigned(link) then
    Exit;

  rightRef := RobCoMasterFormIDRef(link);
  link2 := nil;
  if ElementExists(prop, 'Value\Object Union\Object v1\FormID') then
    link2 := LinksTo(ElementByPath(prop, 'Value\Object Union\Object v1\FormID'));

  if Assigned(link2) then begin
    leftRef := RobCoMasterFormIDRef(link2);
    Result := leftRef + '=' + rightRef;
    Exit;
  end;

  intVal := OmodPropIntValue(prop);
  if intVal <> '' then
    Result := rightRef + '=' + intVal
  else
    Result := rightRef + '=' + rightRef;
end;

//============================================================================
procedure GatherOmodProperties(e: IInterface; floatParts, vpParts, formParts: TStringList);
var
  props, prop: IInterface;
  i: integer;
  valueType, propName, propKey, floatVal, vpEntry, floatEntry: string;
  link: IInterface;
begin
  if not Assigned(floatParts) then
    Exit;
  if not Assigned(vpParts) then
    Exit;
  if not Assigned(formParts) then
    Exit;

  props := ElementByName(e, 'Properties');
  if not Assigned(props) then
    Exit;

  RobCoOmodEnsureSeenScratch;
  for i := 0 to Pred(ElementCount(props)) do begin
    prop := ElementByIndex(props, i);
    valueType := GetElementEditValues(prop, 'Value Type');
    if valueType = '' then
      valueType := GetElementEditValues(prop, 'Type');
    propName := GetElementEditValues(prop, 'Property');
    if propName = '' then
      Continue;

    if OmodValueTypeIsVP(valueType) then begin
      link := OmodPropObjectLink(prop);
      floatVal := OmodPropFloatValue(prop);
      if Assigned(link) then begin
        if floatVal <> '' then begin
          vpEntry := RobCoMasterFormIDRef(link) + '=' + floatVal;
          if gRobCoOmodScratchSeenVp.IndexOf(vpEntry) < 0 then begin
            gRobCoOmodScratchSeenVp.Add(vpEntry);
            vpParts.Add(vpEntry);
          end;
        end;
      end;
      Continue;
    end;

    if OmodValueTypeIsForm(valueType) or
       ((Pos('Form', valueType) > 0) and (Pos('Float', valueType) = 0) and
        (Pos('Bool', valueType) = 0)) then begin
      vpEntry := OmodPropFormPairEntry(prop);
      if vpEntry <> '' then begin
        if gRobCoOmodScratchSeenForm.IndexOf(vpEntry) < 0 then begin
          gRobCoOmodScratchSeenForm.Add(vpEntry);
          formParts.Add(vpEntry);
        end;
      end;
      Continue;
    end;

    propKey := OmodPropertyKeyForExport(propName);
    floatVal := OmodPropFloatValue(prop);
    if floatVal = '' then
      floatVal := OmodPropIntValue(prop);
    if (propKey <> '') and (floatVal <> '') then begin
      floatEntry := propKey + '=' + floatVal;
      if gRobCoOmodScratchSeenFloat.IndexOf(floatEntry) < 0 then begin
        gRobCoOmodScratchSeenFloat.Add(floatEntry);
        floatParts.Add(floatEntry);
      end;
    end;
  end;
end;

//============================================================================
function ReadOmodAttachPoint(e: IInterface): string;
begin
  Result := RobCoReadFormLinkPathOrRef(e, 'DATA\Attach Point', 'BNAM');
end;

//============================================================================
function RobCoOmodHasProperties(e: IInterface): boolean;
var
  props: IInterface;
begin
  Result := False;
  if not ElementExists(e, 'Properties') then
    Exit;
  props := ElementByName(e, 'Properties');
  if not Assigned(props) then
    Exit;
  Result := ElementCount(props) > 0;
end;

//============================================================================
function RobCoOmodHeaderUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  attach, masterAttach, appr, masterAppr: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if RobCoReadPlainFullName(e) <> RobCoReadPlainFullName(master) then
    Exit;
  attach := ReadOmodAttachPoint(e);
  masterAttach := ReadOmodAttachPoint(master);
  if attach <> masterAttach then
    Exit;
  appr := RobCoReadApprKeywordRefs(e);
  masterAppr := RobCoReadApprKeywordRefs(master);
  if not RobCoListFieldUnchangedVsMaster(e, appr, masterAppr) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoOmodExportFieldsUnchangedVsMaster(e: IInterface): boolean;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  if not RobCoOmodHeaderUnchangedVsMaster(e) then
    Exit;
  if RobCoOmodHasProperties(e) then
    Exit;
  Result := True;
end;

//============================================================================
procedure RobCoReadOmodPatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  gRobCoSnapOmodPlainName := RobCoReadPlainFullName(e);
  gRobCoSnapOmodAttach := ReadOmodAttachPoint(e);
  gRobCoSnapMasterOmodPlainName := '';
  gRobCoSnapMasterOmodAttach := '';
  gRobCoSnapOmodApprKw := '';
  gRobCoSnapMasterOmodApprKw := '';
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterOmodPlainName := RobCoReadPlainFullName(gRobCoSnapMaster);
    gRobCoSnapMasterOmodAttach := ReadOmodAttachPoint(gRobCoSnapMaster);
    if RobCoSnapApprKwSubgraphConflictFree(e, gRobCoSnapMaster) then begin
      gRobCoSnapOmodApprKw := RobCoSnapCacheApprKw(gRobCoSnapMaster);
      gRobCoSnapMasterOmodApprKw := gRobCoSnapOmodApprKw;
    end else begin
      gRobCoSnapOmodApprKw := RobCoReadApprKeywordRefs(e);
      gRobCoSnapMasterOmodApprKw := RobCoSnapCacheApprKw(gRobCoSnapMaster);
    end;
  end else
    gRobCoSnapOmodApprKw := RobCoReadApprKeywordRefs(e);
end;

//============================================================================
function RobCoOmodFieldsUnchangedFromScratch(e: IInterface): boolean;
begin
  Result := False;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapOmodPlainName <> gRobCoSnapMasterOmodPlainName then
    Exit;
  if gRobCoSnapOmodAttach <> gRobCoSnapMasterOmodAttach then
    Exit;
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapOmodApprKw, gRobCoSnapMasterOmodApprKw) then
    Exit;
  if RobCoOmodHasProperties(e) then
    Exit;
  Result := True;
end;

//============================================================================
procedure GatherOmodPatchDataFromScratch(e: IInterface);
var
  headerUnchanged, skipMasterProps: boolean;
begin
  InitRobCoOMODPatchData;

  gOmodPatchFilterByOMod := RobCoPatchFilterFormIDRef(e);
  gOmodPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapOmodPlainName, gRobCoSnapMasterOmodPlainName);
  gOmodPatchSetAttachPoint := RobCoExportFieldIfChanged(e, gRobCoSnapOmodAttach, gRobCoSnapMasterOmodAttach);
  gOmodPatchAttachParentSlotKeywordsToAdd := RobCoExportListFieldIfChanged(e,
    gRobCoSnapOmodApprKw, gRobCoSnapMasterOmodApprKw);

  headerUnchanged := False;
  if RobCoCompactExternalOverride(e) then
    headerUnchanged := RobCoOmodFieldsUnchangedFromScratch(e);
  if headerUnchanged then begin
    if not RobCoOmodHasProperties(e) then
      Exit;
  end;

  RobCoOmodEnsurePropListScratch;
  GatherOmodProperties(e, gRobCoOmodScratchFloat, gRobCoOmodScratchVp, gRobCoOmodScratchForm);
  skipMasterProps := False;
  if RobCoRecordHasExternalMaster(e) then begin
    if headerUnchanged then begin
      if gRobCoOmodScratchFloat.Count = 0 then begin
        if gRobCoOmodScratchVp.Count = 0 then begin
          if gRobCoOmodScratchForm.Count = 0 then
            skipMasterProps := True;
        end;
      end;
    end;
    if not skipMasterProps then
      GatherOmodProperties(gRobCoSnapMaster, gRobCoOmodScratchMasterFloat,
        gRobCoOmodScratchMasterVp, gRobCoOmodScratchMasterForm);
  end;
  gOmodPatchChangeOModPropertiesFloat := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchFloat), RobCoJoinParts(gRobCoOmodScratchMasterFloat));
  gOmodPatchChangeOModPropertiesVP := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchVp), RobCoJoinParts(gRobCoOmodScratchMasterVp));
  gOmodPatchChangeOModPropertiesForm := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchForm), RobCoJoinParts(gRobCoOmodScratchMasterForm));
end;

//============================================================================
procedure InitRobCoOMODPatchData;
begin
  gOmodPatchConnectionAnd := 'none';
  gOmodPatchFilterByOMod := 'none';
  gOmodPatchFilterByOModExcluded := 'none';
  gOmodPatchFilterByFormType := 'none';
  gOmodPatchFilterByNameContainsAnd := 'none';
  gOmodPatchFilterByNameContainsOr := 'none';
  gOmodPatchFilterByNameContainsExclude := 'none';
  gOmodPatchFilterByPropertiesAnd := 'none';
  gOmodPatchFilterByPropertiesOr := 'none';
  gOmodPatchFilterByPropertiesExclude := 'none';
  gOmodPatchFilterByAttachPoint := 'none';
  gOmodPatchFullName := '';
  gOmodPatchSetAttachPoint := '';
  gOmodPatchAttachParentSlotKeywordsToAdd := '';
  gOmodPatchChangeOModPropertiesFloat := '';
  gOmodPatchChangeOModPropertiesVP := '';
  gOmodPatchChangeOModPropertiesForm := '';
end;

//============================================================================
procedure GatherOmodPatchData(e: IInterface);
var
  apprKeywords, masterAppr: string;
  masterAttach: string;
  headerUnchanged, skipMasterProps: boolean;
begin
  InitRobCoOMODPatchData;

  gOmodPatchFilterByOMod := RobCoPatchFilterFormIDRef(e);
  gOmodPatchFullName := RobCoPlainFullNameIfChanged(e);
  masterAttach := '';
  masterAppr := '';
  if RobCoRecordHasExternalMaster(e) then begin
    masterAttach := ReadOmodAttachPoint(MasterOrSelf(e));
    masterAppr := RobCoReadApprKeywordRefs(MasterOrSelf(e));
  end;
  gOmodPatchSetAttachPoint := RobCoExportFieldIfChanged(e, ReadOmodAttachPoint(e), masterAttach);
  apprKeywords := RobCoReadApprKeywordRefs(e);
  gOmodPatchAttachParentSlotKeywordsToAdd := RobCoExportListFieldIfChanged(e, apprKeywords, masterAppr);

  headerUnchanged := False;
  if RobCoCompactExternalOverride(e) then
    headerUnchanged := RobCoOmodHeaderUnchangedVsMaster(e);
  if headerUnchanged then begin
    if not RobCoOmodHasProperties(e) then
      Exit;
  end;

  RobCoOmodEnsurePropListScratch;
  GatherOmodProperties(e, gRobCoOmodScratchFloat, gRobCoOmodScratchVp, gRobCoOmodScratchForm);
  skipMasterProps := False;
  if RobCoRecordHasExternalMaster(e) then begin
    if headerUnchanged then begin
      if gRobCoOmodScratchFloat.Count = 0 then begin
        if gRobCoOmodScratchVp.Count = 0 then begin
          if gRobCoOmodScratchForm.Count = 0 then
            skipMasterProps := True;
        end;
      end;
    end;
    if not skipMasterProps then
      GatherOmodProperties(MasterOrSelf(e), gRobCoOmodScratchMasterFloat,
        gRobCoOmodScratchMasterVp, gRobCoOmodScratchMasterForm);
  end;
  gOmodPatchChangeOModPropertiesFloat := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchFloat), RobCoJoinParts(gRobCoOmodScratchMasterFloat));
  gOmodPatchChangeOModPropertiesVP := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchVp), RobCoJoinParts(gRobCoOmodScratchMasterVp));
  gOmodPatchChangeOModPropertiesForm := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchForm), RobCoJoinParts(gRobCoOmodScratchMasterForm));
end;

//============================================================================
function BuildRobCoOMODLine: string;
begin
  Result := '';
  // filterByOMod must be first on each OMOD patch line
  Result := RobCoAppendPatchField(Result, 'filterByOMod', gOmodPatchFilterByOMod);
  Result := RobCoAppendPatchField(Result, 'connectionAnd', gOmodPatchConnectionAnd);
  Result := RobCoAppendPatchField(Result, 'filterByOModExcluded', gOmodPatchFilterByOModExcluded);
  Result := RobCoAppendPatchField(Result, 'filterByFormType', gOmodPatchFilterByFormType);
  Result := RobCoAppendPatchField(Result, 'filterByNameContainsAnd', gOmodPatchFilterByNameContainsAnd);
  Result := RobCoAppendPatchField(Result, 'filterByNameContainsOr', gOmodPatchFilterByNameContainsOr);
  Result := RobCoAppendPatchField(Result, 'filterByNameContainsExclude', gOmodPatchFilterByNameContainsExclude);
  Result := RobCoAppendPatchField(Result, 'filterByPropertiesAnd', gOmodPatchFilterByPropertiesAnd);
  Result := RobCoAppendPatchField(Result, 'filterByPropertiesOr', gOmodPatchFilterByPropertiesOr);
  Result := RobCoAppendPatchField(Result, 'filterByPropertiesExclude', gOmodPatchFilterByPropertiesExclude);
  Result := RobCoAppendPatchField(Result, 'filterByAttachPoint', gOmodPatchFilterByAttachPoint);

  Result := RobCoAppendField(Result, 'fullName', gOmodPatchFullName, False);
  Result := RobCoAppendField(Result, 'setAttachPoint', gOmodPatchSetAttachPoint, False);
  Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToAdd',
    gOmodPatchAttachParentSlotKeywordsToAdd, False);
  Result := RobCoAppendField(Result, 'changeOModPropertiesFloat',
    gOmodPatchChangeOModPropertiesFloat, False);
  Result := RobCoAppendField(Result, 'changeOModPropertiesVP',
    gOmodPatchChangeOModPropertiesVP, False);
  Result := RobCoAppendField(Result, 'changeOModPropertiesForm',
    gOmodPatchChangeOModPropertiesForm, False);
end;

//============================================================================
procedure ExportOMODToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
var
  line: string;
begin
  if Signature(e) <> 'OMOD' then
    Exit;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoSnapTryEarlyPregatherSkipOmod(e) then begin
      RobCoSnapRecordEarlyPregatherSkip;
      Exit;
    end;
  end;

  RobCoReadOmodPatchInputs(e);
  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoOmodFieldsUnchangedFromScratch(e) then begin
      Exit;
    end;
  end;

  GatherOmodPatchDataFromScratch(e);
  line := BuildRobCoOMODLine;
  RobCoEmitSnapshotRecord(e, 'OMOD', shortComment, line);
end;


//============================================================================
// NPC / RACE
//============================================================================




const

  ACBS_Female = 1;

  ACBS_Essential = 2;

  ACBS_AutoCalcStats = $10;

  ACBS_PCLevelMult = $80;



var

  bLoggedSkyrimAVSkip: boolean;



  gNpcPatchFilterByNpcs, gNpcPatchFilterByNpcsExcluded, gNpcPatchFilterByRaces, gNpcPatchFilterByRacesExcluded: string;

  gNpcPatchFilterByKeywords, gNpcPatchFilterByKeywordsOr, gNpcPatchFilterByKeywordsExcluded: string;

  gNpcPatchFilterByFactions, gNpcPatchFilterByFactionsOr, gNpcPatchFilterByFactionsExcluded: string;

  gNpcPatchFilterByClass, gNpcPatchFilterByGender: string;

  gNpcPatchChangeAVIFS, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove, gNpcPatchPerksToAdd, gNpcPatchSpellsToAdd: string;

  gNpcPatchFullName, gNpcPatchAutoCalcStats, gNpcPatchSetPcLevelMult, gNpcPatchSetEssential: string;

  gNpcPatchLevel, gNpcPatchCalcLevelMin, gNpcPatchCalcLevelMax: string;

  gNpcPatchFactionsToAdd, gNpcPatchFactionsToRemove, gNpcPatchDeathItem, gNpcPatchRace, gNpcPatchClassOp: string;

  gNpcPatchObjectsToAdd, gNpcPatchObjectsToRemove: string;



//============================================================================

function RobCoBoolFlag(flags, mask: integer): string;

begin

  if (flags and mask) <> 0 then

    Result := 'yes'

  else

    Result := 'no';

end;



//============================================================================

procedure CollectSpellFormIDs(elem: IInterface; parts: TStringList);

var

  i: integer;

  link: IInterface;

  sig: string;

begin

  if not Assigned(elem) then

    Exit;



  link := LinksTo(elem);

  if Assigned(link) then begin

    sig := Signature(link);

    if (sig = 'SPEL') or (sig = 'SHOU') then

      RobCoSnapRefPartsAddUnique(RobCoMasterFormIDRef(link));

  end;



  for i := 0 to Pred(ElementCount(elem)) do

    CollectSpellFormIDs(ElementByIndex(elem, i), parts);

end;



//============================================================================

function ReadSpellRefs(e: IInterface): string;

var

  i: integer;

  elem, spell: IInterface;

  refKey: string;

begin

  Result := '';

  RobCoSnapEnsureRefPartsScratch;

  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin

    if ElementExists(e, 'SPLO') then

      for i := 0 to Pred(ElementCount(ElementBySignature(e, 'SPLO'))) do begin

        spell := LinksTo(ElementByIndex(ElementBySignature(e, 'SPLO'), i));

        if Assigned(spell) then begin

          refKey := RobCoMasterFormIDRef(spell);

          RobCoSnapRefPartsAddUnique(refKey);

        end;

      end;

  end else begin

    elem := ElementByName(e, 'Actor Effects');

    if Assigned(elem) then

      CollectSpellFormIDs(elem, gRobCoSnapRefPartsScratch);

    if ElementExists(e, 'SPLO') then

      for i := 0 to Pred(ElementCount(ElementBySignature(e, 'SPLO'))) do begin

        spell := LinksTo(ElementByIndex(ElementBySignature(e, 'SPLO'), i));

        if Assigned(spell) then begin

          refKey := RobCoMasterFormIDRef(spell);

          RobCoSnapRefPartsAddUnique(refKey);

        end;

      end;

  end;

  Result := RobCoJoinParts(gRobCoSnapRefPartsScratch);

end;



//============================================================================

function ReadPerkRefs(e: IInterface): string;

var

  perks, i: integer;

  perk, link, perksElem: IInterface;

  refKey: string;

begin

  Result := '';

  if not ElementExists(e, 'Perks') then

    Exit;

  perksElem := ElementByName(e, 'Perks');

  RobCoSnapEnsureRefPartsScratch;

  perks := ElementCount(perksElem);

  for i := 0 to Pred(perks) do begin

    perk := ElementByIndex(perksElem, i);

    link := LinksTo(ElementByPath(perk, 'PKPR - Perk'));

    if not Assigned(link) then

      link := LinksTo(perk);

    if not Assigned(link) then

      Continue;

    if Signature(link) <> 'PERK' then

      Continue;

    refKey := RobCoMasterFormIDRef(link);

    RobCoSnapRefPartsAddUnique(refKey);

  end;

  Result := RobCoJoinParts(gRobCoSnapRefPartsScratch);

end;



//============================================================================

function ReadFactionRefs(e: IInterface): string;

var

  ents, ent, faction: IInterface;

  i, rank: integer;

begin

  Result := '';

  ents := ElementByName(e, 'Factions');

  if not Assigned(ents) then

    Exit;

  RobCoSnapEnsureRefPartsScratch;

  for i := 0 to Pred(ElementCount(ents)) do begin

    ent := ElementByIndex(ents, i);

    faction := LinksTo(ElementByName(ent, 'Faction'));

    if not Assigned(faction) then

      Continue;

    rank := Round(GetElementNativeValues(ent, 'Rank'));

    gRobCoSnapRefPartsScratch.Add(RobCoMasterFormIDRef(faction) + '=' + IntToStr(rank));

  end;

  Result := RobCoJoinParts(gRobCoSnapRefPartsScratch);

end;



//============================================================================

function NpcItemPath: string;

begin

  if wbGameMode = gmTES4 then

    Result := 'Item'

  else

    Result := 'CNTO\Item';

end;



//============================================================================

function NpcItemCountPath: string;

begin

  if wbGameMode = gmTES4 then

    Result := 'Count'

  else

    Result := 'CNTO\Count';

end;



//============================================================================

function ReadInventoryRefs(e: IInterface): string;

var

  items, item, ref: IInterface;

  i, count: integer;

begin

  Result := '';

  items := ElementByName(e, 'Items');

  if not Assigned(items) then

    Exit;

  RobCoSnapEnsureRefPartsScratch;

  for i := 0 to Pred(ElementCount(items)) do begin

    item := ElementByIndex(items, i);

    ref := LinksTo(ElementByPath(item, NpcItemPath));

    if not Assigned(ref) then

      Continue;

    count := Round(GetElementNativeValues(item, NpcItemCountPath));

    if count <= 0 then

      count := 1;

    gRobCoSnapRefPartsScratch.Add(RobCoMasterFormIDRef(ref) + '=' + IntToStr(count));

  end;

  Result := RobCoJoinParts(gRobCoSnapRefPartsScratch);

end;



//============================================================================

function ReadDeathItemRef(e: IInterface): string;

var

  link: IInterface;

begin

  Result := '';

  link := LinksTo(ElementBySignature(e, 'INAM'));

  if Assigned(link) then

    Result := RobCoMasterFormIDRef(link);

end;



//============================================================================

function ReadACBSUInt(e: IInterface; const path: string): integer;

begin

  Result := 0;

  if not ElementExists(e, 'ACBS') then

    Exit;

  Result := Round(GetElementNativeValues(e, path));

end;



//============================================================================

procedure ReadACBSFields(e: IInterface);

var

  flags, levelVal: integer;

begin

  gNpcPatchAutoCalcStats := 'none';

  gNpcPatchSetPcLevelMult := 'none';

  gNpcPatchSetEssential := 'none';

  gNpcPatchLevel := '';

  gNpcPatchCalcLevelMin := '';

  gNpcPatchCalcLevelMax := '';



  if not ElementExists(e, 'ACBS') then

    Exit;



  flags := Round(GetElementNativeValues(e, 'ACBS\Flags'));

  gNpcPatchAutoCalcStats := RobCoBoolFlag(flags, ACBS_AutoCalcStats);

  gNpcPatchSetPcLevelMult := RobCoBoolFlag(flags, ACBS_PCLevelMult);

  gNpcPatchSetEssential := RobCoBoolFlag(flags, ACBS_Essential);



  levelVal := ReadACBSUInt(e, 'ACBS\Level');

  if (flags and ACBS_PCLevelMult) <> 0 then begin

    if levelVal <> 0 then

      gNpcPatchLevel := IntToStr(levelVal div 1000);

  end else if levelVal <> 0 then

    gNpcPatchLevel := IntToStr(levelVal);



  levelVal := ReadACBSUInt(e, 'ACBS\Calc min level');

  if levelVal = 0 then

    levelVal := ReadACBSUInt(e, 'ACBS\Calc Min');

  if levelVal <> 0 then

    gNpcPatchCalcLevelMin := IntToStr(levelVal);



  levelVal := ReadACBSUInt(e, 'ACBS\Calc max level');

  if levelVal = 0 then

    levelVal := ReadACBSUInt(e, 'ACBS\Calc Max');

  if levelVal <> 0 then

    gNpcPatchCalcLevelMax := IntToStr(levelVal);

end;



//============================================================================

procedure ReadACBSFieldStrings(e: IInterface; var autoCalc, pcLevelMult, essential, level, calcMin, calcMax: string);

var

  flags, levelVal: integer;

begin

  autoCalc := 'none';

  pcLevelMult := 'none';

  essential := 'none';

  level := '';

  calcMin := '';

  calcMax := '';



  if not ElementExists(e, 'ACBS') then

    Exit;



  flags := Round(GetElementNativeValues(e, 'ACBS\Flags'));

  autoCalc := RobCoBoolFlag(flags, ACBS_AutoCalcStats);

  pcLevelMult := RobCoBoolFlag(flags, ACBS_PCLevelMult);

  essential := RobCoBoolFlag(flags, ACBS_Essential);



  levelVal := ReadACBSUInt(e, 'ACBS\Level');

  if (flags and ACBS_PCLevelMult) <> 0 then begin

    if levelVal <> 0 then

      level := IntToStr(levelVal div 1000);

  end else if levelVal <> 0 then

    level := IntToStr(levelVal);



  levelVal := ReadACBSUInt(e, 'ACBS\Calc min level');

  if levelVal = 0 then

    levelVal := ReadACBSUInt(e, 'ACBS\Calc Min');

  if levelVal <> 0 then

    calcMin := IntToStr(levelVal);



  levelVal := ReadACBSUInt(e, 'ACBS\Calc max level');

  if levelVal = 0 then

    levelVal := ReadACBSUInt(e, 'ACBS\Calc Max');

  if levelVal <> 0 then

    calcMax := IntToStr(levelVal);

end;



//============================================================================

procedure RobCoSnapReadAcbsToScratch(e: IInterface);

begin

  ReadACBSFieldStrings(e, gRobCoSnapAcbsAutoCalc, gRobCoSnapAcbsPcLevelMult, gRobCoSnapAcbsEssential,

    gRobCoSnapAcbsLevel, gRobCoSnapAcbsCalcMin, gRobCoSnapAcbsCalcMax);

  gRobCoSnapMasterAcbsAutoCalc := 'none';

  gRobCoSnapMasterAcbsPcLevelMult := 'none';

  gRobCoSnapMasterAcbsEssential := 'none';

  gRobCoSnapMasterAcbsLevel := '';

  gRobCoSnapMasterAcbsCalcMin := '';

  gRobCoSnapMasterAcbsCalcMax := '';

  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'ACBS') then begin
    gRobCoSnapMasterAcbsAutoCalc := gRobCoSnapAcbsAutoCalc;
    gRobCoSnapMasterAcbsPcLevelMult := gRobCoSnapAcbsPcLevelMult;
    gRobCoSnapMasterAcbsEssential := gRobCoSnapAcbsEssential;
    gRobCoSnapMasterAcbsLevel := gRobCoSnapAcbsLevel;
    gRobCoSnapMasterAcbsCalcMin := gRobCoSnapAcbsCalcMin;
    gRobCoSnapMasterAcbsCalcMax := gRobCoSnapAcbsCalcMax;
  end else
    ReadACBSFieldStrings(gRobCoSnapMaster, gRobCoSnapMasterAcbsAutoCalc, gRobCoSnapMasterAcbsPcLevelMult,
      gRobCoSnapMasterAcbsEssential, gRobCoSnapMasterAcbsLevel, gRobCoSnapMasterAcbsCalcMin,
      gRobCoSnapMasterAcbsCalcMax);

end;



//============================================================================

function RobCoAcbsFieldsUnchangedFromScratch: boolean;

begin

  Result := False;

  if not Assigned(gRobCoSnapMaster) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(gRobCoSnapAcbsAutoCalc, gRobCoSnapMasterAcbsAutoCalc) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(gRobCoSnapAcbsPcLevelMult, gRobCoSnapMasterAcbsPcLevelMult) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(gRobCoSnapAcbsEssential, gRobCoSnapMasterAcbsEssential) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(gRobCoSnapAcbsLevel, gRobCoSnapMasterAcbsLevel) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(gRobCoSnapAcbsCalcMin, gRobCoSnapMasterAcbsCalcMin) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(gRobCoSnapAcbsCalcMax, gRobCoSnapMasterAcbsCalcMax) then

    Exit;

  Result := True;

end;



//============================================================================

procedure RobCoApplyAcbsPatchDiffFromScratch(e: IInterface);

begin

  if not RobCoSnapshotUseCompactFieldDiff then

    Exit;

  if not Assigned(gRobCoSnapMaster) then

    Exit;

  gNpcPatchAutoCalcStats := RobCoExportFieldIfChanged(e, gRobCoSnapAcbsAutoCalc, gRobCoSnapMasterAcbsAutoCalc);

  gNpcPatchSetPcLevelMult := RobCoExportFieldIfChanged(e, gRobCoSnapAcbsPcLevelMult, gRobCoSnapMasterAcbsPcLevelMult);

  gNpcPatchSetEssential := RobCoExportFieldIfChanged(e, gRobCoSnapAcbsEssential, gRobCoSnapMasterAcbsEssential);

  gNpcPatchLevel := RobCoExportFieldIfChanged(e, gRobCoSnapAcbsLevel, gRobCoSnapMasterAcbsLevel);

  gNpcPatchCalcLevelMin := RobCoExportFieldIfChanged(e, gRobCoSnapAcbsCalcMin, gRobCoSnapMasterAcbsCalcMin);

  gNpcPatchCalcLevelMax := RobCoExportFieldIfChanged(e, gRobCoSnapAcbsCalcMax, gRobCoSnapMasterAcbsCalcMax);

end;



//============================================================================

function RobCoAcbsFieldsUnchangedVsMaster(e, master: IInterface): boolean;

var

  pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax: string;

  mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax: string;

begin

  Result := False;

  if not Assigned(e) then

    Exit;

  if not Assigned(master) then

    Exit;

  ReadACBSFieldStrings(e, pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax);

  ReadACBSFieldStrings(master, mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax);

  if not RobCoScalarUnchangedVsMaster(pAutoCalc, mAutoCalc) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(pPcLevelMult, mPcLevelMult) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(pEssential, mEssential) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(pLevel, mLevel) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(pCalcMin, mCalcMin) then

    Exit;

  if not RobCoScalarUnchangedVsMaster(pCalcMax, mCalcMax) then

    Exit;

  Result := True;

end;



//============================================================================

procedure RobCoApplyAcbsPatchDiffIfCompact(e, master: IInterface);

var

  pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax: string;

  mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax: string;

begin

  if not RobCoSnapshotUseCompactFieldDiff then

    Exit;

  if not Assigned(master) then

    Exit;

  ReadACBSFieldStrings(e, pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax);

  ReadACBSFieldStrings(master, mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax);

  gNpcPatchAutoCalcStats := RobCoExportFieldIfChanged(e, pAutoCalc, mAutoCalc);

  gNpcPatchSetPcLevelMult := RobCoExportFieldIfChanged(e, pPcLevelMult, mPcLevelMult);

  gNpcPatchSetEssential := RobCoExportFieldIfChanged(e, pEssential, mEssential);

  gNpcPatchLevel := RobCoExportFieldIfChanged(e, pLevel, mLevel);

  gNpcPatchCalcLevelMin := RobCoExportFieldIfChanged(e, pCalcMin, mCalcMin);

  gNpcPatchCalcLevelMax := RobCoExportFieldIfChanged(e, pCalcMax, mCalcMax);

end;



//============================================================================

procedure AppendAVIFFromProperties(props: IInterface; parts: TStringList);

var

  i, j: integer;

  entry, link: IInterface;

  valStr: string;

begin

  if not Assigned(props) then

    Exit;



  for i := 0 to Pred(ElementCount(props)) do begin

    entry := ElementByIndex(props, i);

    link := LinksTo(entry);

    if not Assigned(link) then

      for j := 0 to Pred(ElementCount(entry)) do begin

        link := LinksTo(ElementByIndex(entry, j));

        if Assigned(link) then begin
          if Signature(link) = 'AVIF' then
            Break;
        end;

        link := nil;

      end;



    if not Assigned(link) then
      Continue;
    if Signature(link) <> 'AVIF' then
      Continue;



    valStr := GetElementEditValues(entry, 'Value');

    if valStr = '' then

      valStr := GetElementEditValues(entry, 'Data');

    if valStr = '' then

      Continue;



    parts.Add(RobCoMasterFormIDRef(link) + '=' + valStr);

  end;

end;



//============================================================================

function ReadSkyrimAVIFS(e: IInterface): string;

var
  health, magicka, stamina: integer;
begin
  Result := 'none';
  RobCoSnapEnsurePartsScratch;

  health := 0;

  magicka := 0;

  stamina := 0;



  if Signature(e) = 'NPC_' then begin

      if ElementExists(e, 'NPC Attributes') then begin

        health := Round(GetElementNativeValues(e, 'NPC Attributes\Health'));

        magicka := Round(GetElementNativeValues(e, 'NPC Attributes\Magicka'));

        stamina := Round(GetElementNativeValues(e, 'NPC Attributes\Stamina'));

      end;

    end else if ElementExists(e, 'Attributes') then begin

      health := Round(GetElementNativeValues(e, 'Attributes\Health'));

      magicka := Round(GetElementNativeValues(e, 'Attributes\Magicka'));

      stamina := Round(GetElementNativeValues(e, 'Attributes\Stamina'));

    end;



    if (health = 0) and (magicka = 0) and (stamina = 0) then begin
      if ElementExists(e, 'DATA') then begin
        health := Round(GetElementNativeValues(e, 'DATA\Health'));
        magicka := Round(GetElementNativeValues(e, 'DATA\Magicka'));
        stamina := Round(GetElementNativeValues(e, 'DATA\Stamina'));
      end;
    end;



    if health > 0 then

      gRobCoSnapPartsScratch.Add('Skyrim.esm|3E8=' + IntToStr(health));

    if magicka > 0 then

      gRobCoSnapPartsScratch.Add('Skyrim.esm|3FC=' + IntToStr(magicka));

    if stamina > 0 then

      gRobCoSnapPartsScratch.Add('Skyrim.esm|3F2=' + IntToStr(stamina));



    if gRobCoSnapPartsScratch.Count = 0 then begin

      if not bLoggedSkyrimAVSkip then begin

        RobCoQueueExportLog('RobCo NPC: no mappable Skyrim actor values on ' + Name(e) + '; using changeAVIFS=none.');

        bLoggedSkyrimAVSkip := True;

      end;

      Exit;

    end;



    Result := RobCoJoinParts(gRobCoSnapPartsScratch);

end;



//============================================================================

function ReadFO4AVIFS(e: IInterface): string;
var
  props: IInterface;
begin
  Result := 'none';
  RobCoSnapEnsurePartsScratch;
  props := ElementByName(e, 'Properties');
  if Assigned(props) then
    AppendAVIFFromProperties(props, gRobCoSnapPartsScratch);
  if gRobCoSnapPartsScratch.Count = 0 then begin
    props := ElementByPath(e, 'Actor Data\Properties');
    if Assigned(props) then
      AppendAVIFFromProperties(props, gRobCoSnapPartsScratch);
  end;
  if gRobCoSnapPartsScratch.Count = 0 then
    Exit;
  Result := RobCoJoinParts(gRobCoSnapPartsScratch);
end;



//============================================================================

function ReadChangeAVIFS(e: IInterface): string;

begin

  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then

    Result := ReadSkyrimAVIFS(e)

  else

    Result := ReadFO4AVIFS(e);

end;



//============================================================================

function NpcStripRankSuffixFromRefList(const listText: string): string;
var
  i, eqPos: integer;
  entry, refKey: string;
begin
  Result := listText;
  if (listText = '') or (listText = 'none') then
    Exit;
  RobCoSnapEnsureCommaScratch;
  RobCoParseCommaList(gRobCoSnapCommaScratch, listText);
  for i := 0 to Pred(gRobCoSnapCommaScratch.Count) do begin
    entry := Trim(gRobCoSnapCommaScratch[i]);
    if entry = '' then
      Continue;
    eqPos := Pos('=', entry);
    if eqPos > 0 then
      refKey := Copy(entry, 1, eqPos - 1)
    else
      refKey := entry;
    if gRobCoSnapCommaScratch2.IndexOf(refKey) < 0 then
      gRobCoSnapCommaScratch2.Add(refKey);
  end;
  Result := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoSnapCommaScratch2));
end;



//============================================================================

procedure InitRobCoNPCPatchData;

begin

  gNpcPatchFilterByNpcs := 'none';

  gNpcPatchFilterByNpcsExcluded := 'none';

  gNpcPatchFilterByRaces := 'none';

  gNpcPatchFilterByRacesExcluded := 'none';

  gNpcPatchFilterByKeywords := 'none';

  gNpcPatchFilterByKeywordsOr := 'none';

  gNpcPatchFilterByKeywordsExcluded := 'none';

  gNpcPatchFilterByFactions := 'none';

  gNpcPatchFilterByFactionsOr := 'none';

  gNpcPatchFilterByFactionsExcluded := 'none';

  gNpcPatchFilterByClass := 'none';

  gNpcPatchFilterByGender := 'none';

  gNpcPatchChangeAVIFS := 'none';

  gNpcPatchKeywordsToAdd := 'none';

  gNpcPatchKeywordsToRemove := 'none';

  gNpcPatchPerksToAdd := 'none';

  gNpcPatchSpellsToAdd := 'none';

  gNpcPatchFullName := '';

  gNpcPatchAutoCalcStats := 'none';

  gNpcPatchSetPcLevelMult := 'none';

  gNpcPatchSetEssential := 'none';

  gNpcPatchLevel := '';

  gNpcPatchCalcLevelMin := '';

  gNpcPatchCalcLevelMax := '';

  gNpcPatchFactionsToAdd := 'none';

  gNpcPatchFactionsToRemove := 'none';

  gNpcPatchDeathItem := '';

  gNpcPatchRace := '';

  gNpcPatchClassOp := '';

  gNpcPatchObjectsToAdd := 'none';

  gNpcPatchObjectsToRemove := 'none';

end;



//============================================================================

procedure GatherRacePatchData(e: IInterface);

var

  keywords, perks, spells, changeAvif: string;

  master: IInterface;

  masterPerks, masterSpells, masterChangeAvif: string;

  perksRem, spellsRem: string;

begin

  InitRobCoNPCPatchData;



  keywords := RobCoReadKeywordRefsFromElement(e);

  perks := ReadPerkRefs(e);

  spells := ReadSpellRefs(e);



  master := nil;

  masterPerks := '';

  masterSpells := '';

  masterChangeAvif := 'none';

  if RobCoRecordHasExternalMaster(e) then begin

    master := MasterOrSelf(e);

    masterPerks := ReadPerkRefs(master);

    masterSpells := ReadSpellRefs(master);

    masterChangeAvif := ReadChangeAVIFS(master);

  end;



  changeAvif := ReadChangeAVIFS(e);

  gNpcPatchChangeAVIFS := RobCoExportFieldIfChanged(e, changeAvif, masterChangeAvif);

  RobCoApplyRefListDiffIfCompact(e, perks, masterPerks, gNpcPatchPerksToAdd, perksRem);

  RobCoApplyRefListDiffIfCompact(e, spells, masterSpells, gNpcPatchSpellsToAdd, spellsRem);



  gNpcPatchFilterByRaces := RobCoPatchFilterFormIDRef(e);

  // Keywords on RACE lines are operations (keywordsToAdd/Remove), not filterByKeywords.
  gNpcPatchFilterByKeywords := 'none';

  RobCoApplyKeywordDiffIfCompact(e, keywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

  if Assigned(master) then begin
    if RobCoSnapshotUseCompactFieldDiff then
      RobCoApplyAcbsPatchDiffIfCompact(e, master)
    else
      ReadACBSFields(e);
  end else
    ReadACBSFields(e);

end;



//============================================================================

function RobCoRaceFieldsUnchangedVsMaster(e: IInterface): boolean;

var

  master: IInterface;

  changeAvif, masterChangeAvif: string;

begin

  Result := False;

  if not RobCoRecordHasExternalMaster(e) then

    Exit;

  master := MasterOrSelf(e);

  if not RobCoKeywordRefsUnchangedVsMaster(e) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(ReadPerkRefs(e), ReadPerkRefs(master)) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(ReadSpellRefs(e), ReadSpellRefs(master)) then

    Exit;

  changeAvif := ReadChangeAVIFS(e);

  masterChangeAvif := ReadChangeAVIFS(master);

  if changeAvif <> masterChangeAvif then

    Exit;

  if not RobCoAcbsFieldsUnchangedVsMaster(e, master) then

    Exit;

  Result := True;

end;



//============================================================================

procedure GatherNpcPatchData(e: IInterface);

var

  keywords, perks, spells, factions, inventory, fullNameVal, deathItemVal, changeAvif: string;

  raceRef, classRef: string;

  master: IInterface;

  masterPerks, masterSpells, masterFactions, masterInventory, masterChangeAvif: string;

  masterDeathItem, masterRace, masterClass, masterFullName: string;

  perksRem, spellsRem, factionsRem, objectsRem: string;

begin

  InitRobCoNPCPatchData;



  keywords := RobCoReadKeywordRefsFromElement(e);

  perks := ReadPerkRefs(e);

  spells := ReadSpellRefs(e);

  factions := ReadFactionRefs(e);

  inventory := ReadInventoryRefs(e);

  fullNameVal := RobCoReadFullName(e);

  deathItemVal := ReadDeathItemRef(e);

  raceRef := RobCoReadFormLinkRef(e, 'RNAM');

  classRef := RobCoReadFormLinkRef(e, 'CNAM');



  master := nil;

  masterPerks := '';

  masterSpells := '';

  masterFactions := '';

  masterInventory := '';

  masterChangeAvif := 'none';

  masterDeathItem := '';

  masterRace := '';

  masterClass := '';

  masterFullName := '';

  if RobCoRecordHasExternalMaster(e) then begin

    master := MasterOrSelf(e);

    masterFullName := RobCoReadFullName(master);

    masterPerks := ReadPerkRefs(master);

    masterSpells := ReadSpellRefs(master);

    masterFactions := ReadFactionRefs(master);

    masterInventory := ReadInventoryRefs(master);

    masterChangeAvif := ReadChangeAVIFS(master);

    masterDeathItem := ReadDeathItemRef(master);

    masterRace := RobCoReadFormLinkRef(master, 'RNAM');

    masterClass := RobCoReadFormLinkRef(master, 'CNAM');

  end;



  changeAvif := ReadChangeAVIFS(e);

  gNpcPatchChangeAVIFS := RobCoExportFieldIfChanged(e, changeAvif, masterChangeAvif);

  RobCoApplyRefListDiffIfCompact(e, perks, masterPerks, gNpcPatchPerksToAdd, perksRem);

  RobCoApplyRefListDiffIfCompact(e, spells, masterSpells, gNpcPatchSpellsToAdd, spellsRem);

  RobCoApplyRefListDiffIfCompact(e, factions, masterFactions, gNpcPatchFactionsToAdd, factionsRem);

  RobCoApplyRefListDiffIfCompact(e, inventory, masterInventory, gNpcPatchObjectsToAdd, objectsRem);

  gNpcPatchFactionsToRemove := NpcStripRankSuffixFromRefList(factionsRem);

  gNpcPatchObjectsToRemove := NpcStripRankSuffixFromRefList(objectsRem);



  gNpcPatchFilterByNpcs := RobCoPatchFilterFormIDRef(e);

  RobCoApplyKeywordDiffIfCompact(e, keywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

  gNpcPatchFullName := RobCoExportFieldIfChanged(e, fullNameVal, masterFullName);

  gNpcPatchDeathItem := RobCoExportFieldIfChanged(e, deathItemVal, masterDeathItem);

  gNpcPatchRace := RobCoExportFieldIfChanged(e, raceRef, masterRace);

  gNpcPatchClassOp := RobCoExportFieldIfChanged(e, classRef, masterClass);

  if Assigned(master) then begin
    if RobCoSnapshotUseCompactFieldDiff then
      RobCoApplyAcbsPatchDiffIfCompact(e, master)
    else
      ReadACBSFields(e);
  end else
    ReadACBSFields(e);

end;



//============================================================================

function RobCoNpcFieldsUnchangedVsMaster(e: IInterface): boolean;

var

  master: IInterface;

begin

  Result := False;

  if not RobCoRecordHasExternalMaster(e) then

    Exit;

  master := MasterOrSelf(e);

  if not RobCoRaceFieldsUnchangedVsMaster(e) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(ReadFactionRefs(e), ReadFactionRefs(master)) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(ReadInventoryRefs(e), ReadInventoryRefs(master)) then

    Exit;

  if RobCoReadFullName(e) <> RobCoReadFullName(master) then

    Exit;

  if ReadDeathItemRef(e) <> ReadDeathItemRef(master) then

    Exit;

  if RobCoReadFormLinkRef(e, 'RNAM') <> RobCoReadFormLinkRef(master, 'RNAM') then

    Exit;

  if RobCoReadFormLinkRef(e, 'CNAM') <> RobCoReadFormLinkRef(master, 'CNAM') then

    Exit;

  Result := True;

end;



//============================================================================

function BuildRobCoNPCLine: string;

begin

  Result := '';

  Result := RobCoAppendPatchField(Result, 'filterByNpcs', gNpcPatchFilterByNpcs);

  Result := RobCoAppendPatchField(Result, 'filterByNpcsExcluded', gNpcPatchFilterByNpcsExcluded);

  Result := RobCoAppendPatchField(Result, 'filterByRaces', gNpcPatchFilterByRaces);

  Result := RobCoAppendPatchField(Result, 'filterByRacesExcluded', gNpcPatchFilterByRacesExcluded);

  Result := RobCoAppendPatchField(Result, 'filterByKeywords', gNpcPatchFilterByKeywords);

  Result := RobCoAppendPatchField(Result, 'filterByKeywordsOr', gNpcPatchFilterByKeywordsOr);

  Result := RobCoAppendPatchField(Result, 'filterByKeywordsExcluded', gNpcPatchFilterByKeywordsExcluded);

  Result := RobCoAppendPatchField(Result, 'filterByFactions', gNpcPatchFilterByFactions);

  Result := RobCoAppendPatchField(Result, 'filterByFactionsOr', gNpcPatchFilterByFactionsOr);

  Result := RobCoAppendPatchField(Result, 'filterByFactionsExcluded', gNpcPatchFilterByFactionsExcluded);

  Result := RobCoAppendPatchField(Result, 'filterByClass', gNpcPatchFilterByClass);

  Result := RobCoAppendPatchField(Result, 'filterByGender', gNpcPatchFilterByGender);



  Result := RobCoAppendField(Result, 'changeAVIFS', gNpcPatchChangeAVIFS, True);

  Result := RobCoAppendField(Result, 'keywordsToAdd', gNpcPatchKeywordsToAdd, True);

  Result := RobCoAppendField(Result, 'keywordsToRemove', gNpcPatchKeywordsToRemove, True);

  Result := RobCoAppendField(Result, 'perksToAdd', gNpcPatchPerksToAdd, True);

  Result := RobCoAppendField(Result, 'spellsToAdd', gNpcPatchSpellsToAdd, True);

  Result := RobCoAppendField(Result, 'factionsToAdd', gNpcPatchFactionsToAdd, False);

  Result := RobCoAppendField(Result, 'factionsToRemove', gNpcPatchFactionsToRemove, False);

  Result := RobCoAppendField(Result, 'fullName', gNpcPatchFullName, False);

  Result := RobCoAppendNumericField(Result, 'autoCalcStats', gNpcPatchAutoCalcStats);

  Result := RobCoAppendNumericField(Result, 'setPcLevelMult', gNpcPatchSetPcLevelMult);

  Result := RobCoAppendNumericField(Result, 'setEssential', gNpcPatchSetEssential);

  Result := RobCoAppendNumericField(Result, 'level', gNpcPatchLevel);

  Result := RobCoAppendNumericField(Result, 'calcLevelMin', gNpcPatchCalcLevelMin);

  Result := RobCoAppendNumericField(Result, 'calcLevelMax', gNpcPatchCalcLevelMax);

  Result := RobCoAppendField(Result, 'deathItem', gNpcPatchDeathItem, False);

  Result := RobCoAppendField(Result, 'race', gNpcPatchRace, False);

  Result := RobCoAppendField(Result, 'class', gNpcPatchClassOp, False);

  Result := RobCoAppendField(Result, 'objectsToAdd', gNpcPatchObjectsToAdd, False);

  Result := RobCoAppendField(Result, 'objectsToRemove', gNpcPatchObjectsToRemove, False);

end;



//============================================================================

function BuildRobCoRACELine: string;

begin

  Result := '';

  Result := RobCoAppendPatchField(Result, 'filterByRaces', gNpcPatchFilterByRaces);

  Result := RobCoAppendPatchField(Result, 'filterByRacesExcluded', gNpcPatchFilterByRacesExcluded);

  Result := RobCoAppendPatchField(Result, 'filterByKeywords', gNpcPatchFilterByKeywords);

  Result := RobCoAppendPatchField(Result, 'filterByKeywordsOr', gNpcPatchFilterByKeywordsOr);

  Result := RobCoAppendPatchField(Result, 'filterByKeywordsExcluded', gNpcPatchFilterByKeywordsExcluded);



  Result := RobCoAppendField(Result, 'changeAVIFS', gNpcPatchChangeAVIFS, True);

  Result := RobCoAppendField(Result, 'keywordsToAdd', gNpcPatchKeywordsToAdd, True);

  Result := RobCoAppendField(Result, 'keywordsToRemove', gNpcPatchKeywordsToRemove, True);

  Result := RobCoAppendField(Result, 'perksToAdd', gNpcPatchPerksToAdd, True);

  Result := RobCoAppendField(Result, 'spellsToAdd', gNpcPatchSpellsToAdd, True);

  Result := RobCoAppendNumericField(Result, 'autoCalcStats', gNpcPatchAutoCalcStats);

  Result := RobCoAppendNumericField(Result, 'setPcLevelMult', gNpcPatchSetPcLevelMult);

  Result := RobCoAppendNumericField(Result, 'setEssential', gNpcPatchSetEssential);

  Result := RobCoAppendNumericField(Result, 'level', gNpcPatchLevel);

  Result := RobCoAppendNumericField(Result, 'calcLevelMin', gNpcPatchCalcLevelMin);

  Result := RobCoAppendNumericField(Result, 'calcLevelMax', gNpcPatchCalcLevelMax);

end;



//============================================================================
// Subgraph conflict gates, master cache, gated scratch reads
//============================================================================

function RobCoSnapKeywordsSubgraphConflictFree(e, master: IInterface): boolean;
var
  kwE, kwM: IInterface;
begin
  kwE := RobCoGetKeywordsElement(e);
  kwM := RobCoGetKeywordsElement(master);
  Result := RobCoSubElementConflictFree(kwE, kwM);
end;

//============================================================================
function RobCoSnapApprKwSubgraphConflictFree(e, master: IInterface): boolean;
var
  aE, aM: IInterface;
begin
  aE := RobCoGetApprElement(e);
  aM := RobCoGetApprElement(master);
  Result := RobCoSubElementConflictFree(aE, aM);
end;

//============================================================================
function RobCoSnapCobjCategoryKwSubgraphConflictFree(e, master: IInterface): boolean;
var
  a, b: IInterface;
begin
  a := GetCobjCategoryKeywordsElement(e);
  b := GetCobjCategoryKeywordsElement(master);
  Result := RobCoSubElementConflictFree(a, b);
end;

//============================================================================
function RobCoSnapSpellsSubgraphConflictFree(e, master: IInterface): boolean;
begin
  Result := False;
  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin
    Result := RobCoSubElementConflictFreeBySignature(e, master, 'SPLO');
    Exit;
  end;
  if not RobCoSubElementConflictFreeByName(e, master, 'Actor Effects') then
    Exit;
  Result := RobCoSubElementConflictFreeBySignature(e, master, 'SPLO');
end;

//============================================================================
function RobCoSnapAvifSubgraphConflictFree(e, master: IInterface): boolean;
begin
  Result := False;
  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin
    if not RobCoSubElementConflictFreeByPath(e, master, 'NPC Attributes') then
      Exit;
    if not RobCoSubElementConflictFreeByPath(e, master, 'Attributes') then
      Exit;
    Result := RobCoSubElementConflictFreeByPath(e, master, 'DATA');
    Exit;
  end;
  if not RobCoSubElementConflictFreeByName(e, master, 'Properties') then
    Exit;
  Result := RobCoSubElementConflictFreeByPath(e, master, 'Actor Data\Properties');
end;

//============================================================================
function RobCoSnapCacheKeywords(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'keywords');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := RobCoReadKeywordRefsFromElement(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCachePerks(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'perks');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadPerkRefs(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheSpells(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'spells');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadSpellRefs(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheChangeAvif(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'avif');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadChangeAVIFS(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheFactions(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'factions');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadFactionRefs(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheInventory(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'inventory');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadInventoryRefs(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheApprKw(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'apprkw');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := RobCoReadApprKeywordRefs(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheCobjCategoryKw(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'cobjcatkw');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadCobjCategoryKeywordRefs(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheAlchMgefs(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'alchmgefs');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadAlchMgefsToAdd(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
procedure RobCoSnapReadKeywordsToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := '';
    Exit;
  end;
  if RobCoSnapKeywordsSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapMasterKeywords := gRobCoSnapKeywords;
  end else begin
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapReadPerksToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := '';
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Perks') then begin
    gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterPerks := gRobCoSnapPerks;
  end else begin
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapReadSpellsToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := '';
    Exit;
  end;
  if RobCoSnapSpellsSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := gRobCoSnapSpells;
  end else begin
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapReadChangeAvifToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapChangeAvif := ReadChangeAVIFS(e);
    gRobCoSnapMasterChangeAvif := 'none';
    Exit;
  end;
  if RobCoSnapAvifSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapMasterChangeAvif := gRobCoSnapChangeAvif;
  end else begin
    gRobCoSnapChangeAvif := ReadChangeAVIFS(e);
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapReadFactionsToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapFactions := ReadFactionRefs(e);
    gRobCoSnapMasterFactions := '';
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Factions') then begin
    gRobCoSnapFactions := RobCoSnapCacheFactions(gRobCoSnapMaster);
    gRobCoSnapMasterFactions := gRobCoSnapFactions;
  end else begin
    gRobCoSnapFactions := ReadFactionRefs(e);
    gRobCoSnapMasterFactions := RobCoSnapCacheFactions(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapReadInventoryToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapInventory := ReadInventoryRefs(e);
    gRobCoSnapMasterInventory := '';
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Items') then begin
    gRobCoSnapInventory := RobCoSnapCacheInventory(gRobCoSnapMaster);
    gRobCoSnapMasterInventory := gRobCoSnapInventory;
  end else begin
    gRobCoSnapInventory := ReadInventoryRefs(e);
    gRobCoSnapMasterInventory := RobCoSnapCacheInventory(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapReadApprKwToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapApprKw := RobCoReadApprKeywordRefs(e);
    gRobCoSnapMasterApprKw := '';
    Exit;
  end;
  if RobCoSnapApprKwSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapApprKw := RobCoSnapCacheApprKw(gRobCoSnapMaster);
    gRobCoSnapMasterApprKw := gRobCoSnapApprKw;
  end else begin
    gRobCoSnapApprKw := RobCoReadApprKeywordRefs(e);
    gRobCoSnapMasterApprKw := RobCoSnapCacheApprKw(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapReadCobjCategoryKwToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapCategoryKw := ReadCobjCategoryKeywordRefs(e);
    gRobCoSnapMasterCategoryKw := '';
    Exit;
  end;
  if RobCoSnapCobjCategoryKwSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapCategoryKw := RobCoSnapCacheCobjCategoryKw(gRobCoSnapMaster);
    gRobCoSnapMasterCategoryKw := gRobCoSnapCategoryKw;
  end else begin
    gRobCoSnapCategoryKw := ReadCobjCategoryKeywordRefs(e);
    gRobCoSnapMasterCategoryKw := RobCoSnapCacheCobjCategoryKw(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapReadAlchMgefsToScratch(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMgefs := ReadAlchMgefsToAdd(e);
    gRobCoSnapMasterMgefs := '';
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Effects') then begin
    gRobCoSnapMgefs := RobCoSnapCacheAlchMgefs(gRobCoSnapMaster);
    gRobCoSnapMasterMgefs := gRobCoSnapMgefs;
  end else begin
    gRobCoSnapMgefs := ReadAlchMgefsToAdd(e);
    gRobCoSnapMasterMgefs := RobCoSnapCacheAlchMgefs(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapNpcClearStash;
begin
  gRobCoSnapNpcStashMask := 0;
end;

//============================================================================
procedure RobCoSnapStashNpcKeywords(e: IInterface);
begin
  gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster)
  else
    gRobCoSnapMasterKeywords := '';
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 1;
end;

//============================================================================
procedure RobCoSnapStashNpcPerks(e: IInterface);
begin
  gRobCoSnapPerks := ReadPerkRefs(e);
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster)
  else
    gRobCoSnapMasterPerks := '';
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 2;
end;

//============================================================================
procedure RobCoSnapStashNpcSpells(e: IInterface);
begin
  gRobCoSnapSpells := ReadSpellRefs(e);
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster)
  else
    gRobCoSnapMasterSpells := '';
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 4;
end;

//============================================================================
procedure RobCoSnapStashNpcAcbs(e: IInterface);
begin
  ReadACBSFieldStrings(e, gRobCoSnapAcbsAutoCalc, gRobCoSnapAcbsPcLevelMult, gRobCoSnapAcbsEssential,
    gRobCoSnapAcbsLevel, gRobCoSnapAcbsCalcMin, gRobCoSnapAcbsCalcMax);
  gRobCoSnapMasterAcbsAutoCalc := '';
  gRobCoSnapMasterAcbsPcLevelMult := '';
  gRobCoSnapMasterAcbsEssential := '';
  gRobCoSnapMasterAcbsLevel := '';
  gRobCoSnapMasterAcbsCalcMin := '';
  gRobCoSnapMasterAcbsCalcMax := '';
  if Assigned(gRobCoSnapMaster) then
    ReadACBSFieldStrings(gRobCoSnapMaster, gRobCoSnapMasterAcbsAutoCalc, gRobCoSnapMasterAcbsPcLevelMult,
      gRobCoSnapMasterAcbsEssential, gRobCoSnapMasterAcbsLevel, gRobCoSnapMasterAcbsCalcMin,
      gRobCoSnapMasterAcbsCalcMax);
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 8;
end;

//============================================================================
procedure RobCoSnapStashNpcAvif(e: IInterface);
begin
  gRobCoSnapChangeAvif := ReadChangeAVIFS(e);
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster)
  else
    gRobCoSnapMasterChangeAvif := 'none';
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 16;
end;

//============================================================================
procedure RobCoSnapStashNpcFactions(e: IInterface);
begin
  gRobCoSnapFactions := ReadFactionRefs(e);
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterFactions := RobCoSnapCacheFactions(gRobCoSnapMaster)
  else
    gRobCoSnapMasterFactions := '';
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 32;
end;

//============================================================================
procedure RobCoSnapStashNpcInventory(e: IInterface);
begin
  gRobCoSnapInventory := ReadInventoryRefs(e);
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterInventory := RobCoSnapCacheInventory(gRobCoSnapMaster)
  else
    gRobCoSnapMasterInventory := '';
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 64;
end;

//============================================================================
procedure RobCoSnapStashNpcScalars(e: IInterface);
begin
  gRobCoSnapFullName := RobCoReadFullName(e);
  gRobCoSnapDeathItem := ReadDeathItemRef(e);
  gRobCoSnapRaceRef := RobCoReadFormLinkRef(e, 'RNAM');
  gRobCoSnapClassRef := RobCoReadFormLinkRef(e, 'CNAM');
  gRobCoSnapMasterFullName := '';
  gRobCoSnapMasterDeathItem := '';
  gRobCoSnapMasterRaceRef := '';
  gRobCoSnapMasterClassRef := '';
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterFullName := RobCoReadFullName(gRobCoSnapMaster);
    gRobCoSnapMasterDeathItem := ReadDeathItemRef(gRobCoSnapMaster);
    gRobCoSnapMasterRaceRef := RobCoReadFormLinkRef(gRobCoSnapMaster, 'RNAM');
    gRobCoSnapMasterClassRef := RobCoReadFormLinkRef(gRobCoSnapMaster, 'CNAM');
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 128;
end;

//============================================================================
procedure RobCoSnapReadNpcBilateralFieldsIfNeeded(e: IInterface);
begin
  if (gRobCoSnapNpcStashMask and 1) = 0 then
    RobCoSnapStashNpcKeywords(e);
  if (gRobCoSnapNpcStashMask and 2) = 0 then
    RobCoSnapStashNpcPerks(e);
  if (gRobCoSnapNpcStashMask and 4) = 0 then
    RobCoSnapStashNpcSpells(e);
  if (gRobCoSnapNpcStashMask and 8) = 0 then
    RobCoSnapStashNpcAcbs(e);
  if (gRobCoSnapNpcStashMask and 16) = 0 then
    RobCoSnapStashNpcAvif(e);
  if (gRobCoSnapNpcStashMask and 32) = 0 then
    RobCoSnapStashNpcFactions(e);
  if (gRobCoSnapNpcStashMask and 64) = 0 then
    RobCoSnapStashNpcInventory(e);
  if (gRobCoSnapNpcStashMask and 128) = 0 then
    RobCoSnapStashNpcScalars(e);
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipRaceSubgraph(e, master: IInterface): boolean;
begin
  Result := False;
  if not RobCoSnapKeywordsSubgraphConflictFree(e, master) then
    Exit;
  if not RobCoSubElementConflictFreeByName(e, master, 'Perks') then
    Exit;
  if not RobCoSnapSpellsSubgraphConflictFree(e, master) then
    Exit;
  if not RobCoSnapAvifSubgraphConflictFree(e, master) then
    Exit;
  if not RobCoSubElementConflictFreeByName(e, master, 'ACBS') then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipNpcRaceSubgraph(e, master: IInterface): boolean;
begin
  Result := False;
  if not RobCoSnapKeywordsSubgraphConflictFree(e, master) then
    Exit;
  if not RobCoSubElementConflictFreeByName(e, master, 'Perks') then
    Exit;
  if not RobCoSnapSpellsSubgraphConflictFree(e, master) then
    Exit;
  if not RobCoSnapAvifSubgraphConflictFree(e, master) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipRace(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if not Assigned(master) then
    Exit;
  Result := RobCoSnapTryEarlyPregatherSkipRaceSubgraph(e, master);
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipNpc(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  RobCoSnapReadMasterIfAny(e);
  master := gRobCoSnapMaster;
  if not Assigned(master) then
    Exit;
  if not RobCoSnapTryEarlyPregatherSkipNpcRaceSubgraph(e, master) then
    Exit;
  RobCoSnapStashNpcKeywords(e);
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapKeywords, gRobCoSnapMasterKeywords) then
    Exit;
  RobCoSnapStashNpcPerks(e);
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapPerks, gRobCoSnapMasterPerks) then
    Exit;
  RobCoSnapStashNpcSpells(e);
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapSpells, gRobCoSnapMasterSpells) then
    Exit;
  RobCoSnapStashNpcAcbs(e);
  if not RobCoAcbsFieldsUnchangedFromScratch then
    Exit;
  RobCoSnapStashNpcAvif(e);
  if gRobCoSnapChangeAvif <> gRobCoSnapMasterChangeAvif then
    Exit;
  if not RobCoSubElementConflictFreeByName(e, master, 'Factions') then
    Exit;
  RobCoSnapStashNpcFactions(e);
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapFactions, gRobCoSnapMasterFactions) then
    Exit;
  if not RobCoSubElementConflictFreeByName(e, master, 'Items') then
    Exit;
  RobCoSnapStashNpcInventory(e);
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapInventory, gRobCoSnapMasterInventory) then
    Exit;
  RobCoSnapStashNpcScalars(e);
  if gRobCoSnapFullName <> gRobCoSnapMasterFullName then
    Exit;
  if gRobCoSnapDeathItem <> gRobCoSnapMasterDeathItem then
    Exit;
  if gRobCoSnapRaceRef <> gRobCoSnapMasterRaceRef then
    Exit;
  if gRobCoSnapClassRef <> gRobCoSnapMasterClassRef then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipAmmo(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if not Assigned(master) then
    Exit;
  if not RobCoSnapKeywordsSubgraphConflictFree(e, master) then
    Exit;
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if RobCoFO4Game then begin
    if ReadAmmoAttackDamage(e) <> ReadAmmoAttackDamage(master) then
      Exit;
    if ReadAmmoProjectileRef(e) <> ReadAmmoProjectileRef(master) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipCobj(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if not Assigned(master) then
    Exit;
  if not RobCoSnapCobjCategoryKwSubgraphConflictFree(e, master) then
    Exit;
  if ReadWorkbenchKeywordRef(e) <> ReadWorkbenchKeywordRef(master) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipArmo(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if not Assigned(master) then
    Exit;
  if not RobCoSnapKeywordsSubgraphConflictFree(e, master) then
    Exit;
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if RobCoReadDataField(e, 'Value') <> RobCoReadDataField(master, 'Value') then
    Exit;
  if RobCoReadDataField(e, 'Armor Rating') <> RobCoReadDataField(master, 'Armor Rating') then
    Exit;
  if RobCoFO4Game then begin
    if RobCoReadDataField(e, 'Health') <> RobCoReadDataField(master, 'Health') then
      Exit;
    if ReadArmoObjectEffect(e) <> ReadArmoObjectEffect(master) then
      Exit;
    if not RobCoSnapApprKwSubgraphConflictFree(e, master) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipWeap(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if not Assigned(master) then
    Exit;
  if not RobCoSnapKeywordsSubgraphConflictFree(e, master) then
    Exit;
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Damage') <> RobCoReadDataField(master, 'Damage') then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if RobCoReadDataField(e, 'Value') <> RobCoReadDataField(master, 'Value') then
    Exit;
  if RobCoFO4Game then begin
    if ReadWeapBashDamage(e) <> ReadWeapBashDamage(master) then
      Exit;
    if ReadWeapAmmoRef(e) <> ReadWeapAmmoRef(master) then
      Exit;
    if ReadWeapAimModelRef(e) <> ReadWeapAimModelRef(master) then
      Exit;
    if not RobCoSnapApprKwSubgraphConflictFree(e, master) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipAlch(e: IInterface): boolean;
var
  master: IInterface;
  mgefsToAdd, mgefsToChange, mgefsToRemove: string;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := MasterOrSelf(e);
  if not Assigned(master) then
    Exit;
  if not RobCoSnapKeywordsSubgraphConflictFree(e, master) then
    Exit;
  if not RobCoSubElementConflictFreeByName(e, master, 'Effects') then
    Exit;
  DiffAlchMgefs(ReadAlchMgefsToAdd(e), ReadAlchMgefsToAdd(master),
    mgefsToAdd, mgefsToChange, mgefsToRemove);
  if mgefsToAdd <> 'none' then
    Exit;
  if mgefsToChange <> 'none' then
    Exit;
  if mgefsToRemove <> 'none' then
    Exit;
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if RobCoReadDataField(e, 'Value') <> RobCoReadDataField(master, 'Value') then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipOmod(e: IInterface): boolean;
begin
  Result := False;
  if not RobCoSnapshotUseCompactFieldDiff then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  if not RobCoOmodHeaderUnchangedVsMaster(e) then
    Exit;
  if RobCoOmodHasProperties(e) then
    Exit;
  Result := True;
end;

//============================================================================
procedure RobCoSnapRecordEarlyPregatherSkip;
begin
end;

//============================================================================
procedure RobCoReadRacePatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  RobCoSnapReadAcbsToScratch(e);
  RobCoSnapReadKeywordsToScratch(e);
  RobCoSnapReadPerksToScratch(e);
  RobCoSnapReadSpellsToScratch(e);
  RobCoSnapReadChangeAvifToScratch(e);
end;

//============================================================================
procedure RobCoReadNpcPatchInputs(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  RobCoSnapReadNpcBilateralFieldsIfNeeded(e);
end;



//============================================================================

function RobCoRaceFieldsUnchangedFromScratch(e: IInterface): boolean;

begin

  Result := False;

  if not Assigned(gRobCoSnapMaster) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapKeywords, gRobCoSnapMasterKeywords) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapPerks, gRobCoSnapMasterPerks) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapSpells, gRobCoSnapMasterSpells) then

    Exit;

  if gRobCoSnapChangeAvif <> gRobCoSnapMasterChangeAvif then

    Exit;

  if not RobCoAcbsFieldsUnchangedFromScratch then

    Exit;

  Result := True;

end;



//============================================================================

function RobCoNpcFieldsUnchangedFromScratch(e: IInterface): boolean;

begin

  Result := False;

  if not RobCoRaceFieldsUnchangedFromScratch(e) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapFactions, gRobCoSnapMasterFactions) then

    Exit;

  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapInventory, gRobCoSnapMasterInventory) then

    Exit;

  if gRobCoSnapFullName <> gRobCoSnapMasterFullName then

    Exit;

  if gRobCoSnapDeathItem <> gRobCoSnapMasterDeathItem then

    Exit;

  if gRobCoSnapRaceRef <> gRobCoSnapMasterRaceRef then

    Exit;

  if gRobCoSnapClassRef <> gRobCoSnapMasterClassRef then

    Exit;

  Result := True;

end;



//============================================================================

procedure GatherRacePatchDataFromScratch(e: IInterface);

var

  perksRem, spellsRem: string;

begin

  InitRobCoNPCPatchData;

  gNpcPatchChangeAVIFS := RobCoExportFieldIfChanged(e, gRobCoSnapChangeAvif, gRobCoSnapMasterChangeAvif);

  RobCoApplyRefListDiffIfCompact(e, gRobCoSnapPerks, gRobCoSnapMasterPerks, gNpcPatchPerksToAdd, perksRem);

  RobCoApplyRefListDiffIfCompact(e, gRobCoSnapSpells, gRobCoSnapMasterSpells, gNpcPatchSpellsToAdd, spellsRem);

  gNpcPatchFilterByRaces := RobCoPatchFilterFormIDRef(e);

  gNpcPatchFilterByKeywords := 'none';

  RobCoApplyKeywordDiffIfCompact(e, gRobCoSnapKeywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

  if Assigned(gRobCoSnapMaster) then begin

    if RobCoSnapshotUseCompactFieldDiff then

      RobCoApplyAcbsPatchDiffFromScratch(e)

    else

      ReadACBSFields(e);

  end else

    ReadACBSFields(e);

end;



//============================================================================

procedure GatherNpcPatchDataFromScratch(e: IInterface);

var

  perksRem, spellsRem, factionsRem, objectsRem: string;

begin

  InitRobCoNPCPatchData;

  gNpcPatchChangeAVIFS := RobCoExportFieldIfChanged(e, gRobCoSnapChangeAvif, gRobCoSnapMasterChangeAvif);

  RobCoApplyRefListDiffIfCompact(e, gRobCoSnapPerks, gRobCoSnapMasterPerks, gNpcPatchPerksToAdd, perksRem);

  RobCoApplyRefListDiffIfCompact(e, gRobCoSnapSpells, gRobCoSnapMasterSpells, gNpcPatchSpellsToAdd, spellsRem);

  RobCoApplyRefListDiffIfCompact(e, gRobCoSnapFactions, gRobCoSnapMasterFactions, gNpcPatchFactionsToAdd, factionsRem);

  RobCoApplyRefListDiffIfCompact(e, gRobCoSnapInventory, gRobCoSnapMasterInventory, gNpcPatchObjectsToAdd, objectsRem);

  gNpcPatchFactionsToRemove := NpcStripRankSuffixFromRefList(factionsRem);

  gNpcPatchObjectsToRemove := NpcStripRankSuffixFromRefList(objectsRem);

  gNpcPatchFilterByNpcs := RobCoPatchFilterFormIDRef(e);

  RobCoApplyKeywordDiffIfCompact(e, gRobCoSnapKeywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

  gNpcPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapFullName, gRobCoSnapMasterFullName);

  gNpcPatchDeathItem := RobCoExportFieldIfChanged(e, gRobCoSnapDeathItem, gRobCoSnapMasterDeathItem);

  gNpcPatchRace := RobCoExportFieldIfChanged(e, gRobCoSnapRaceRef, gRobCoSnapMasterRaceRef);

  gNpcPatchClassOp := RobCoExportFieldIfChanged(e, gRobCoSnapClassRef, gRobCoSnapMasterClassRef);

  if Assigned(gRobCoSnapMaster) then begin

    if RobCoSnapshotUseCompactFieldDiff then

      RobCoApplyAcbsPatchDiffFromScratch(e)

    else

      ReadACBSFields(e);

  end else

    ReadACBSFields(e);

end;



//============================================================================

procedure ExportRACEToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'RACE' then
    Exit;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoSnapTryEarlyPregatherSkipRace(e) then begin
      RobCoSnapRecordEarlyPregatherSkip;
      Exit;
    end;
  end;

  RobCoReadRacePatchInputs(e);
  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoRaceFieldsUnchangedFromScratch(e) then begin
      Exit;
    end;
  end;

  GatherRacePatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'RACE', shortComment, BuildRobCoRACELine);
end;



//============================================================================

procedure ExportNPCToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'NPC_' then
    Exit;

  RobCoSnapNpcClearStash;

  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoSnapTryEarlyPregatherSkipNpc(e) then begin
      RobCoSnapRecordEarlyPregatherSkip;
      Exit;
    end;
  end;

  RobCoReadNpcPatchInputs(e);
  if RobCoSnapshotUseCompactFieldDiff then begin
    if RobCoNpcFieldsUnchangedFromScratch(e) then begin
      Exit;
    end;
  end;

  GatherNpcPatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'NPC_', shortComment, BuildRobCoNPCLine);
end;



//============================================================================

procedure RobCoBeginNpcPluginExport;

begin

  bLoggedSkyrimAVSkip := False;

end;

end.
