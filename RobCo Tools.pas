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
  gRobCoSnapSkin, gRobCoSnapMasterSkin: string;
  gRobCoSnapPowerArmorStand, gRobCoSnapMasterPowerArmorStand: string;
  gRobCoSnapXpValueOffset, gRobCoSnapMasterXpValueOffset: string;
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
  gRobCoSnapAttackActionPointCost, gRobCoSnapMasterAttackActionPointCost: string;
  gRobCoSnapSoundLevel, gRobCoSnapMasterSoundLevel: string;
  gRobCoSnapAmmoRef, gRobCoSnapMasterAmmoRef: string;
  gRobCoSnapAimModel, gRobCoSnapMasterAimModel: string;
  gRobCoSnapDamageTypes, gRobCoSnapMasterDamageTypes: string;
  gRobCoSnapOutOfRangeDamageMult, gRobCoSnapMasterOutOfRangeDamageMult: string;
  gRobCoSnapConeIronSightsMult, gRobCoSnapMasterConeIronSightsMult: string;
  gRobCoSnapRecoilSpringForce, gRobCoSnapMasterRecoilSpringForce: string;
  gRobCoSnapRecoilPerShotMin, gRobCoSnapMasterRecoilPerShotMin: string;
  gRobCoSnapRecoilPerShotMax, gRobCoSnapMasterRecoilPerShotMax: string;
  gRobCoSnapWeaponHitType, gRobCoSnapMasterWeaponHitType: string;
  gRobCoSnapOverrideProjectile, gRobCoSnapMasterOverrideProjectile: string;
  gRobCoSnapNpcAmmoList, gRobCoSnapMasterNpcAmmoList: string;
  gRobCoSnapBipedSlots, gRobCoSnapMasterBipedSlots: string;
  gRobCoSnapWeightMult, gRobCoSnapMasterWeightMult: string;
  gRobCoSnapHealthMult, gRobCoSnapMasterHealthMult: string;
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
  // NPC subgraph conflict-free cache (cleared per ExportNPCToRobCo record)
  gRobCoSnapNpcSubgraphMask: integer;
  // RACE read-once subgraph mask (cleared per ExportRACEToRobCo record)
  gRobCoSnapRaceSubgraphMask: integer;
  // RACE bilateral read progress (cleared per ExportRACEToRobCo record)
  gRobCoSnapRaceStashMask: integer;
  // OMOD header stash (set when early-skip header probe already read fields)
  gRobCoSnapOmodHeaderStashed: boolean;
  // MISC lazy pregather stashed value/weight (avoid double-read in read path)
  gRobCoSnapMiscScalarsStashed: boolean;
  gRobCoSnapCachedNpcItemPath: string;
  gRobCoSnapCachedNpcItemCountPath: string;

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
procedure RobCoSnapClearFieldScratch;
begin
  RobCoSnapClearMaster;
  gRobCoSnapKeywords := '';
  gRobCoSnapMasterKeywords := '';
  gRobCoSnapPerks := '';
  gRobCoSnapMasterPerks := '';
  gRobCoSnapSpells := '';
  gRobCoSnapMasterSpells := '';
  gRobCoSnapChangeAvif := '';
  gRobCoSnapMasterChangeAvif := '';
  gRobCoSnapFactions := '';
  gRobCoSnapMasterFactions := '';
  gRobCoSnapInventory := '';
  gRobCoSnapMasterInventory := '';
  gRobCoSnapFullName := '';
  gRobCoSnapMasterFullName := '';
  gRobCoSnapDeathItem := '';
  gRobCoSnapMasterDeathItem := '';
  gRobCoSnapSkin := '';
  gRobCoSnapMasterSkin := '';
  gRobCoSnapPowerArmorStand := '';
  gRobCoSnapMasterPowerArmorStand := '';
  gRobCoSnapXpValueOffset := '';
  gRobCoSnapMasterXpValueOffset := '';
  gRobCoSnapRaceRef := '';
  gRobCoSnapMasterRaceRef := '';
  gRobCoSnapClassRef := '';
  gRobCoSnapMasterClassRef := '';
  gRobCoSnapValue := '';
  gRobCoSnapMasterValue := '';
  gRobCoSnapWeight := '';
  gRobCoSnapMasterWeight := '';
  gRobCoSnapDamage := '';
  gRobCoSnapMasterDamage := '';
  gRobCoSnapAttackDamage := '';
  gRobCoSnapMasterAttackDamage := '';
  gRobCoSnapProjectile := '';
  gRobCoSnapMasterProjectile := '';
  gRobCoSnapCategoryKw := '';
  gRobCoSnapMasterCategoryKw := '';
  gRobCoSnapWorkbench := '';
  gRobCoSnapMasterWorkbench := '';
  gRobCoSnapObjectEffect := '';
  gRobCoSnapMasterObjectEffect := '';
  gRobCoSnapApprKw := '';
  gRobCoSnapMasterApprKw := '';
  gRobCoSnapArmorRating := '';
  gRobCoSnapMasterArmorRating := '';
  gRobCoSnapHealth := '';
  gRobCoSnapMasterHealth := '';
  gRobCoSnapBashDamage := '';
  gRobCoSnapMasterBashDamage := '';
  gRobCoSnapAttackActionPointCost := '';
  gRobCoSnapMasterAttackActionPointCost := '';
  gRobCoSnapSoundLevel := '';
  gRobCoSnapMasterSoundLevel := '';
  gRobCoSnapAmmoRef := '';
  gRobCoSnapMasterAmmoRef := '';
  gRobCoSnapAimModel := '';
  gRobCoSnapMasterAimModel := '';
  gRobCoSnapDamageTypes := '';
  gRobCoSnapMasterDamageTypes := '';
  gRobCoSnapOutOfRangeDamageMult := '';
  gRobCoSnapMasterOutOfRangeDamageMult := '';
  gRobCoSnapConeIronSightsMult := '';
  gRobCoSnapMasterConeIronSightsMult := '';
  gRobCoSnapRecoilSpringForce := '';
  gRobCoSnapMasterRecoilSpringForce := '';
  gRobCoSnapRecoilPerShotMin := '';
  gRobCoSnapMasterRecoilPerShotMin := '';
  gRobCoSnapRecoilPerShotMax := '';
  gRobCoSnapMasterRecoilPerShotMax := '';
  gRobCoSnapWeaponHitType := '';
  gRobCoSnapMasterWeaponHitType := '';
  gRobCoSnapOverrideProjectile := '';
  gRobCoSnapMasterOverrideProjectile := '';
  gRobCoSnapNpcAmmoList := '';
  gRobCoSnapMasterNpcAmmoList := '';
  gRobCoSnapBipedSlots := '';
  gRobCoSnapMasterBipedSlots := '';
  gRobCoSnapWeightMult := '';
  gRobCoSnapMasterWeightMult := '';
  gRobCoSnapHealthMult := '';
  gRobCoSnapMasterHealthMult := '';
  gRobCoSnapMgefs := '';
  gRobCoSnapMasterMgefs := '';
  gRobCoSnapAcbsAutoCalc := '';
  gRobCoSnapAcbsPcLevelMult := '';
  gRobCoSnapAcbsEssential := '';
  gRobCoSnapAcbsLevel := '';
  gRobCoSnapAcbsCalcMin := '';
  gRobCoSnapAcbsCalcMax := '';
  gRobCoSnapMasterAcbsAutoCalc := '';
  gRobCoSnapMasterAcbsPcLevelMult := '';
  gRobCoSnapMasterAcbsEssential := '';
  gRobCoSnapMasterAcbsLevel := '';
  gRobCoSnapMasterAcbsCalcMin := '';
  gRobCoSnapMasterAcbsCalcMax := '';
  gRobCoSnapOmodAttach := '';
  gRobCoSnapMasterOmodAttach := '';
  gRobCoSnapOmodPlainName := '';
  gRobCoSnapMasterOmodPlainName := '';
  gRobCoSnapOmodApprKw := '';
  gRobCoSnapMasterOmodApprKw := '';
  gRobCoSnapNpcStashMask := 0;
  gRobCoSnapNpcSubgraphMask := 0;
  gRobCoSnapRaceSubgraphMask := 0;
  gRobCoSnapRaceStashMask := 0;
  gRobCoSnapOmodHeaderStashed := False;
  gRobCoSnapMiscScalarsStashed := False;
end;

//============================================================================
procedure RobCoSnapReleaseListScratch;
begin
  if Assigned(gRobCoSnapRefPartsScratch) then begin
    gRobCoSnapRefPartsScratch.Free;
    gRobCoSnapRefPartsScratch := nil;
  end;
  if Assigned(gRobCoSnapRefSeenScratch) then begin
    gRobCoSnapRefSeenScratch.Free;
    gRobCoSnapRefSeenScratch := nil;
  end;
  if Assigned(gRobCoSnapPartsScratch) then begin
    gRobCoSnapPartsScratch.Free;
    gRobCoSnapPartsScratch := nil;
  end;
  if Assigned(gRobCoSnapCommaScratch) then begin
    gRobCoSnapCommaScratch.Free;
    gRobCoSnapCommaScratch := nil;
  end;
  if Assigned(gRobCoSnapCommaScratch2) then begin
    gRobCoSnapCommaScratch2.Free;
    gRobCoSnapCommaScratch2 := nil;
  end;
end;

//============================================================================
procedure RobCoSnapshotClearNpcPatchOutput;
begin
  InitRobCoNPCPatchData;
end;

//============================================================================
procedure RobCoSnapReadMasterIfAny(e: IInterface);
begin
  RobCoSnapClearMaster;
  if RobCoRecordHasExternalMaster(e) then
    gRobCoSnapMaster := RobCoCompareBaselineRecord(e);
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
  RobCoSnapReadMasterIfAny(e);
  master := gRobCoSnapMaster;
  if not Assigned(master) then
    Exit;
  pluginValue := ReadMiscValue(e);
  pluginWeight := ReadMiscWeight(e);
  masterValue := ReadMiscValue(master);
  masterWeight := ReadMiscWeight(master);
  gRobCoSnapValue := pluginValue;
  gRobCoSnapWeight := pluginWeight;
  gRobCoSnapMasterValue := masterValue;
  gRobCoSnapMasterWeight := masterWeight;
  gRobCoSnapMiscScalarsStashed := True;
  if pluginValue <> masterValue then
    Exit;
  if pluginWeight <> masterWeight then
    Exit;
  Result := True;
end;

//============================================================================
procedure RobCoReadMiscPatchInputs(e: IInterface);
begin
  if gRobCoSnapMiscScalarsStashed then begin
    RobCoSnapReadMasterIfAny(e);
    Exit;
  end;
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
    master := RobCoCompareBaselineRecord(e);
    masterValue := ReadMiscValue(master);
    masterWeight := ReadMiscWeight(master);
  end;
  gMiscPatchValue := RobCoExportFieldIfChanged(e, pluginValue, masterValue);
  gMiscPatchWeight := RobCoExportFieldIfChanged(e, pluginWeight, masterWeight);
end;

//============================================================================
function BuildRobCoMISCLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByMiscs', gMiscPatchFilterByMiscs);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByHasComponent', gMiscPatchFilterByHasComponent);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByHasNoComponent', gMiscPatchFilterByHasNoComponent);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywords', gMiscPatchFilterByKeywords);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsOr', gMiscPatchFilterByKeywordsOr);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gMiscPatchFilterByKeywordsExcluded);
  Result := RobCoAppendNumericField(Result, 'value', gMiscPatchValue);
  Result := RobCoAppendNumericField(Result, 'weight', gMiscPatchWeight);
end;

//============================================================================
procedure ExportMISCToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'MISC' then
    Exit;

  if RobCoSnapshotUseItmGate then begin
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
  RobCoApplyKeywordDiffIfItmGate(e, keywords, gAmmoPatchKeywordsToAdd, gAmmoPatchKeywordsToRemove);
  gAmmoPatchFullName := RobCoFullNameIfChanged(e);
  gAmmoPatchWeight := RobCoDataFieldIfChanged(e, 'Weight');

  if RobCoFO4Game then begin
    masterProjectile := '';
    masterAttack := '';
    if RobCoRecordHasExternalMaster(e) then begin
      masterProjectile := ReadAmmoProjectileRef(RobCoCompareBaselineRecord(e));
      masterAttack := ReadAmmoAttackDamage(RobCoCompareBaselineRecord(e));
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
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByWeightLessThan', gAmmoPatchFilterByWeightLessThan);

  Result := RobCoAppendField(Result, 'fullName', gAmmoPatchFullName, False);
  Result := RobCoAppendNumericField(Result, 'weight', gAmmoPatchWeight);
  Result := RobCoAppendField(Result, 'keywordsToAdd', gAmmoPatchKeywordsToAdd, True);
  Result := RobCoAppendField(Result, 'keywordsToRemove', gAmmoPatchKeywordsToRemove, True);

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
  masterProjectile: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := RobCoCompareBaselineRecord(e);
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
  RobCoApplyKeywordDiffIfItmGate(e, gRobCoSnapKeywords,
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

  gRobCoSnapRaceSubgraphMask := 0;

  if RobCoSnapshotUseItmGate then begin
    if RobCoSnapTryEarlyPregatherSkipAmmo(e) then begin
      RobCoSnapRecordEarlyPregatherSkip('ExportAMMOToRobCo');
      Exit;
    end;
  end;

  RobCoReadAmmoPatchInputs(e);
  if RobCoSnapshotUseItmGate then begin
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
begin
  InitRobCoCOBJPatchData;

  categoryKeywords := ReadCobjCategoryKeywordRefs(e);
  workbench := ReadWorkbenchKeywordRef(e);
  masterCategory := '';
  masterWorkbench := 'null';
  if RobCoRecordHasExternalMaster(e) then begin
    masterCategory := ReadCobjCategoryKeywordRefs(RobCoCompareBaselineRecord(e));
    masterWorkbench := ReadWorkbenchKeywordRef(RobCoCompareBaselineRecord(e));
  end;

  gCobjPatchFilterByCobjs := RobCoPatchFilterFormIDRef(e);
  RobCoApplyRefListDiffIfItmGate(e, RobCoNoneIfEmpty(categoryKeywords),
    RobCoNoneIfEmpty(masterCategory), gCobjPatchCategoryKeywordsToAdd,
    gCobjPatchCategoryKeywordsToRemove);
  if gCobjPatchCategoryKeywordsToAdd = '' then
    gCobjPatchCategoryKeywordsToAdd := 'none';
  if gCobjPatchCategoryKeywordsToRemove = '' then
    gCobjPatchCategoryKeywordsToRemove := 'none';
  gCobjPatchWorkbenchKeyword := RobCoExportFieldIfChanged(e, workbench, masterWorkbench);
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
  master := RobCoCompareBaselineRecord(e);
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
    gRobCoSnapMasterWorkbench := RobCoSnapCacheCobjWorkbench(gRobCoSnapMaster);
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
begin
  InitRobCoCOBJPatchData;
  gCobjPatchFilterByCobjs := RobCoPatchFilterFormIDRef(e);
  RobCoApplyRefListDiffIfItmGate(e, RobCoNoneIfEmpty(gRobCoSnapCategoryKw),
    RobCoNoneIfEmpty(gRobCoSnapMasterCategoryKw), gCobjPatchCategoryKeywordsToAdd,
    gCobjPatchCategoryKeywordsToRemove);
  if gCobjPatchCategoryKeywordsToAdd = '' then
    gCobjPatchCategoryKeywordsToAdd := 'none';
  if gCobjPatchCategoryKeywordsToRemove = '' then
    gCobjPatchCategoryKeywordsToRemove := 'none';
  gCobjPatchWorkbenchKeyword := RobCoExportFieldIfChanged(e, gRobCoSnapWorkbench,
    gRobCoSnapMasterWorkbench);
end;

//============================================================================
procedure ExportCOBJToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'COBJ' then
    Exit;

  if RobCoSnapshotUseItmGate then begin
    if RobCoSnapTryEarlyPregatherSkipCobj(e) then begin
      RobCoSnapRecordEarlyPregatherSkip('ExportCOBJToRobCo');
      Exit;
    end;
  end;

  RobCoReadCobjPatchInputs(e);
  if RobCoSnapshotUseItmGate then begin
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
procedure GatherArmoFO4PatchExtras(e: IInterface; fromScratch: boolean);
var
  apprKeywords, masterAppr, masterObjectEffect, pluginDmgTypes, masterDmgTypes, dmgRemove: string;
  pluginSlots, masterSlots, slotsAdd, slotsRem: string;
  master: IInterface;
begin
  master := nil;
  masterObjectEffect := 'null';
  masterAppr := '';
  masterDmgTypes := '';
  masterSlots := '';
  if RobCoRecordHasExternalMaster(e) then begin
    master := RobCoCompareBaselineRecord(e);
    if fromScratch then begin
      masterObjectEffect := gRobCoSnapMasterObjectEffect;
      masterAppr := gRobCoSnapMasterApprKw;
      masterDmgTypes := gRobCoSnapMasterDamageTypes;
      masterSlots := gRobCoSnapMasterBipedSlots;
    end else begin
      masterObjectEffect := ReadArmoObjectEffect(master);
      masterAppr := RobCoEffectiveApprKeywordRefs(master);
      masterDmgTypes := ReadRecordDamageTypePairs(master);
      masterSlots := ReadArmoBipedSlotIndices(master);
    end;
  end;
  if fromScratch then
    gArmoPatchHealth := RobCoExportFieldIfChanged(e, gRobCoSnapHealth, gRobCoSnapMasterHealth)
  else
    gArmoPatchHealth := RobCoDataFieldIfChanged(e, 'Health');
  if fromScratch then
    gArmoPatchObjectEffect := RobCoExportFieldIfChanged(e, gRobCoSnapObjectEffect,
      masterObjectEffect)
  else
    gArmoPatchObjectEffect := RobCoExportFieldIfChanged(e, ReadArmoObjectEffect(e),
      masterObjectEffect);
  if fromScratch then
    apprKeywords := gRobCoSnapApprKw
  else
    apprKeywords := RobCoEffectiveApprKeywordRefs(e);
  RobCoApplyApprKeywordDiffIfItmGate(e, RobCoNoneIfEmpty(apprKeywords),
    RobCoNoneIfEmpty(masterAppr), gArmoPatchAttachParentSlotKeywordsToAdd,
    gArmoPatchAttachParentSlotKeywordsToRemove);
  if fromScratch then
    pluginDmgTypes := gRobCoSnapDamageTypes
  else
    pluginDmgTypes := ReadRecordDamageTypePairs(e);
  if Assigned(master) then begin
    DiffDamageTypeMap(pluginDmgTypes, masterDmgTypes, gArmoPatchChangeDamageTypes, dmgRemove);
    // Armor article documents changeDamageTypes only (no separate remove op).
  end else
    gArmoPatchChangeDamageTypes := RobCoNoneIfEmpty(pluginDmgTypes);
  if Assigned(master) then begin
    if fromScratch then begin
      gArmoPatchWeightMult := RobCoExportFieldIfChanged(e, gRobCoSnapWeightMult,
        gRobCoSnapMasterWeightMult);
      gArmoPatchHealthMult := RobCoExportFieldIfChanged(e, gRobCoSnapHealthMult,
        gRobCoSnapMasterHealthMult);
    end else begin
      gArmoPatchWeightMult := RobCoExportFieldIfChanged(e,
        ReadWeapDnamNativeValue(e, 'DNAM\Weight Mod'),
        ReadWeapDnamNativeValue(master, 'DNAM\Weight Mod'));
      gArmoPatchHealthMult := RobCoExportFieldIfChanged(e,
        ReadWeapDnamNativeValue(e, 'DNAM\Health Mod'),
        ReadWeapDnamNativeValue(master, 'DNAM\Health Mod'));
    end;
  end;
  if fromScratch then
    pluginSlots := gRobCoSnapBipedSlots
  else
    pluginSlots := ReadArmoBipedSlotIndices(e);
  RobCoApplyRefListDiffIfItmGate(e, pluginSlots, masterSlots, gArmoPatchBipedSlotsToAdd, slotsRem);
  gArmoPatchBipedSlotsToRemove := slotsRem;
end;

//============================================================================
procedure GatherArmoPatchData(e: IInterface);
var
  keywords: string;
begin
  InitRobCoARMOPatchData;

  gArmoPatchFilterByArmors := RobCoPatchFilterFormIDRef(e);
  keywords := RobCoReadKeywordRefsFromElement(e);
  RobCoApplyKeywordDiffIfItmGate(e, keywords, gArmoPatchKeywordsToAdd, gArmoPatchKeywordsToRemove);

  gArmoPatchFullName := RobCoFullNameIfChanged(e);
  gArmoPatchWeight := RobCoDataFieldIfChanged(e, 'Weight');
  gArmoPatchDamageResist := RobCoDataFieldIfChanged(e, 'Armor Rating');
  if RobCoFO4Game then
    gArmoPatchValue := ''
  else
    gArmoPatchValue := RobCoDataFieldIfChanged(e, 'Value');

  if not RobCoFO4Game then
    gArmoPatchFilterByArmorTypes := ReadSkyrimArmorTypeFilter(e);

  if RobCoFO4Game then
    GatherArmoFO4PatchExtras(e, False);
end;

//============================================================================
function BuildRobCoARMOLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByArmors', gArmoPatchFilterByArmors);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByArmorsExcluded', gArmoPatchFilterByArmorsExcluded);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywords', gArmoPatchFilterByKeywords);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsOr', gArmoPatchFilterByKeywordsOr);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gArmoPatchFilterByKeywordsExcluded);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByBipedSlots', gArmoPatchFilterByBipedSlots);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByBipedSlotsOr', gArmoPatchFilterByBipedSlotsOr);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByBipedSlotsExcluded', gArmoPatchFilterByBipedSlotsExcluded);
  if not RobCoFO4Game then
    Result := RobCoAppendPatchField(Result, 'filterByArmorTypes', gArmoPatchFilterByArmorTypes);

  Result := RobCoAppendField(Result, 'fullName', gArmoPatchFullName, False);
  Result := RobCoAppendNumericField(Result, 'damageResist', gArmoPatchDamageResist);
  Result := RobCoAppendNumericField(Result, 'weight', gArmoPatchWeight);
  if not RobCoFO4Game then
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
  master := RobCoCompareBaselineRecord(e);
  if RobCoReadFullName(e) <> RobCoReadFullName(master) then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(master, 'Weight') then
    Exit;
  if not RobCoFO4Game then begin
    if RobCoReadDataField(e, 'Value') <> RobCoReadDataField(master, 'Value') then
      Exit;
  end;
  if RobCoReadDataField(e, 'Armor Rating') <> RobCoReadDataField(master, 'Armor Rating') then
    Exit;
  if not RobCoKeywordRefsUnchangedVsMaster(e) then
    Exit;
  if RobCoFO4Game then begin
    if RobCoReadDataField(e, 'Health') <> RobCoReadDataField(master, 'Health') then
      Exit;
    if ReadArmoObjectEffect(e) <> ReadArmoObjectEffect(master) then
      Exit;
    apprKeywords := RobCoEffectiveApprKeywordRefs(e);
    masterAppr := RobCoEffectiveApprKeywordRefs(master);
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
  gRobCoSnapValue := '';
  gRobCoSnapMasterValue := '';
  if not RobCoFO4Game then begin
    gRobCoSnapValue := RobCoReadDataField(e, 'Value');
    gRobCoSnapMasterValue := '';
  end;
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
    gRobCoSnapDamageTypes := ReadRecordDamageTypePairs(e);
    gRobCoSnapBipedSlots := ReadArmoBipedSlotIndices(e);
    gRobCoSnapWeightMult := ReadWeapDnamNativeValue(e, 'DNAM\Weight Mod');
    gRobCoSnapHealthMult := ReadWeapDnamNativeValue(e, 'DNAM\Health Mod');
    RobCoSnapReadApprKwToScratch(e);
  end;
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterFullName := RobCoReadFullName(gRobCoSnapMaster);
    gRobCoSnapMasterWeight := RobCoReadDataField(gRobCoSnapMaster, 'Weight');
    if not RobCoFO4Game then
      gRobCoSnapMasterValue := RobCoReadDataField(gRobCoSnapMaster, 'Value');
    gRobCoSnapMasterArmorRating := RobCoReadDataField(gRobCoSnapMaster, 'Armor Rating');
    if RobCoFO4Game then begin
      gRobCoSnapMasterHealth := RobCoReadDataField(gRobCoSnapMaster, 'Health');
      gRobCoSnapMasterObjectEffect := ReadArmoObjectEffect(gRobCoSnapMaster);
      gRobCoSnapMasterDamageTypes := ReadRecordDamageTypePairs(gRobCoSnapMaster);
      gRobCoSnapMasterBipedSlots := ReadArmoBipedSlotIndices(gRobCoSnapMaster);
      gRobCoSnapMasterWeightMult := ReadWeapDnamNativeValue(gRobCoSnapMaster, 'DNAM\Weight Mod');
      gRobCoSnapMasterHealthMult := ReadWeapDnamNativeValue(gRobCoSnapMaster, 'DNAM\Health Mod');
    end;
  end;
end;

//============================================================================
function RobCoArmoFieldsUnchangedFromScratch(e: IInterface): boolean;
begin
  Result := False;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapFullName <> gRobCoSnapMasterFullName then
    Exit;
  if gRobCoSnapWeight <> gRobCoSnapMasterWeight then
    Exit;
  if not RobCoFO4Game then begin
    if gRobCoSnapValue <> gRobCoSnapMasterValue then
      Exit;
  end;
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
    if not RobCoArmoFo4ExtrasUnchangedFromScratch then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure GatherArmoPatchDataFromScratch(e: IInterface);
begin
  InitRobCoARMOPatchData;
  gArmoPatchFilterByArmors := RobCoPatchFilterFormIDRef(e);
  RobCoApplyKeywordDiffIfItmGate(e, gRobCoSnapKeywords,
    gArmoPatchKeywordsToAdd, gArmoPatchKeywordsToRemove);
  gArmoPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapFullName, gRobCoSnapMasterFullName);
  gArmoPatchWeight := RobCoExportFieldIfChanged(e, gRobCoSnapWeight, gRobCoSnapMasterWeight);
  gArmoPatchDamageResist := RobCoExportFieldIfChanged(e, gRobCoSnapArmorRating,
    gRobCoSnapMasterArmorRating);
  if RobCoFO4Game then
    gArmoPatchValue := ''
  else
    gArmoPatchValue := RobCoExportFieldIfChanged(e, gRobCoSnapValue, gRobCoSnapMasterValue);
  if not RobCoFO4Game then
    gArmoPatchFilterByArmorTypes := ReadSkyrimArmorTypeFilter(e);
  if RobCoFO4Game then
    GatherArmoFO4PatchExtras(e, True);
end;

//============================================================================
procedure ExportARMOToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'ARMO' then
    Exit;

  gRobCoSnapRaceSubgraphMask := 0;

  if RobCoSnapshotUseItmGate then begin
    if RobCoSnapTryEarlyPregatherSkipArmo(e) then begin
      RobCoSnapRecordEarlyPregatherSkip('ExportARMOToRobCo');
      Exit;
    end;
  end;

  RobCoReadArmoPatchInputs(e);
  if RobCoSnapshotUseItmGate then begin
    if RobCoArmoFieldsUnchangedFromScratch(e) then begin
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
function ReadWeapDnamEditValue(e: IInterface; const path: string): string;
begin
  Result := '';
  if ElementExists(e, path) then
    Result := GetElementEditValues(e, path);
end;

//============================================================================
function ReadWeapDnamNativeValue(e: IInterface; const path: string): string;
begin
  Result := '';
  if ElementExists(e, path) then
    Result := FloatToStr(GetElementNativeValues(e, path));
end;

//============================================================================
function ReadWeapAimModelElement(e: IInterface): IInterface;
begin
  Result := LinksTo(ElementByPath(e, 'DNAM\Aim Model'));
  if not Assigned(Result) then
    Result := LinksTo(ElementBySignature(e, 'AIMP'));
end;

//============================================================================
function ReadWeapAimModelScalar(e: IInterface; const path: string): string;
var
  aim: IInterface;
begin
  Result := '';
  aim := ReadWeapAimModelElement(e);
  if not Assigned(aim) then
    Exit;
  if ElementExists(aim, path) then
    Result := GetElementEditValues(aim, path);
end;

//============================================================================
function ReadWeapOverrideProjectile(e: IInterface): string;
begin
  Result := RobCoReadFormLinkPathOrRef(e, 'DNAM\Projectile', 'PNAM');
end;

//============================================================================
function ReadWeapNpcAmmoList(e: IInterface): string;
begin
  Result := RobCoReadFormLinkPathOrRef(e, 'DNAM\NPC Ammo List', 'VNAM');
end;

//============================================================================
function ReadRecordDamageTypePairs(e: IInterface): string;
var
  arr, entry, dtLink: IInterface;
  i: integer;
  pairEntry, dmgVal: string;
begin
  Result := '';
  if not RobCoFO4Game then
    Exit;
  if not ElementExists(e, 'DNAM\Damage Types') then
    Exit;
  arr := ElementByPath(e, 'DNAM\Damage Types');
  RobCoSnapEnsurePartsScratch;
  for i := 0 to Pred(ElementCount(arr)) do begin
    entry := ElementByIndex(arr, i);
    dtLink := LinksTo(ElementByPath(entry, 'Damage Type'));
    if not Assigned(dtLink) then
      Continue;
    dmgVal := '';
    if ElementExists(entry, 'Damage') then
      dmgVal := GetElementEditValues(entry, 'Damage');
    if dmgVal = '' then
      Continue;
    pairEntry := RobCoMasterFormIDRef(dtLink) + '=' + dmgVal;
    gRobCoSnapPartsScratch.Add(pairEntry);
  end;
  Result := RobCoJoinParts(gRobCoSnapPartsScratch);
end;

//============================================================================
procedure DiffDamageTypeMap(const pluginPairs, masterPairs: string;
  var changeOut, removeOut: string);
var
  i, j, eqPos: integer;
  entry, key, val, mEntry, mKey, mVal: string;
  found: boolean;
begin
  changeOut := 'none';
  removeOut := 'none';
  RobCoSnapEnsureCommaScratch;
  RobCoParseCommaList(gRobCoSnapCommaScratch, pluginPairs);
  RobCoParseCommaList(gRobCoSnapCommaScratch2, masterPairs);

  RobCoSnapEnsurePartsScratch;
  for i := 0 to Pred(gRobCoSnapCommaScratch.Count) do begin
    entry := Trim(gRobCoSnapCommaScratch[i]);
    if entry = '' then
      Continue;
    eqPos := Pos('=', entry);
    if eqPos > 0 then begin
      key := Copy(entry, 1, eqPos - 1);
      val := Copy(entry, eqPos + 1, MaxInt);
    end else begin
      key := entry;
      val := '';
    end;
    found := False;
    for j := 0 to Pred(gRobCoSnapCommaScratch2.Count) do begin
      mEntry := Trim(gRobCoSnapCommaScratch2[j]);
      if mEntry = '' then
        Continue;
      eqPos := Pos('=', mEntry);
      if eqPos > 0 then begin
        mKey := Copy(mEntry, 1, eqPos - 1);
        mVal := Copy(mEntry, eqPos + 1, MaxInt);
      end else begin
        mKey := mEntry;
        mVal := '';
      end;
      if mKey <> key then
        Continue;
      found := True;
      if val <> mVal then
        gRobCoSnapPartsScratch.Add(entry);
      Break;
    end;
    if not found then
      gRobCoSnapPartsScratch.Add(entry);
  end;
  changeOut := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoSnapPartsScratch));

  RobCoSnapEnsurePartsScratch;
  for j := 0 to Pred(gRobCoSnapCommaScratch2.Count) do begin
    mEntry := Trim(gRobCoSnapCommaScratch2[j]);
    if mEntry = '' then
      Continue;
    eqPos := Pos('=', mEntry);
    if eqPos > 0 then
      mKey := Copy(mEntry, 1, eqPos - 1)
    else
      mKey := mEntry;
    found := False;
    for i := 0 to Pred(gRobCoSnapCommaScratch.Count) do begin
      entry := Trim(gRobCoSnapCommaScratch[i]);
      if entry = '' then
        Continue;
      eqPos := Pos('=', entry);
      if eqPos > 0 then
        key := Copy(entry, 1, eqPos - 1)
      else
        key := entry;
      if key = mKey then begin
        found := True;
        Break;
      end;
    end;
    if not found then
      if gRobCoSnapPartsScratch.IndexOf(mKey) < 0 then
        gRobCoSnapPartsScratch.Add(mKey);
  end;
  removeOut := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoSnapPartsScratch));
end;

//============================================================================
function ReadArmoBipedSlotIndices(e: IInterface): string;
var
  flags, i: integer;
begin
  Result := '';
  if not RobCoFO4Game then
    Exit;
  if not ElementExists(e, 'BOD2\Biped Slots') then
    Exit;
  flags := Round(GetElementNativeValues(e, 'BOD2\Biped Slots'));
  RobCoSnapEnsurePartsScratch;
  for i := 0 to 31 do begin
    if (flags and (1 shl i)) <> 0 then
      gRobCoSnapPartsScratch.Add(IntToStr(i));
  end;
  Result := RobCoJoinParts(gRobCoSnapPartsScratch);
end;

//============================================================================
function RobCoArmoFo4ExtrasUnchanged(e, master: IInterface): boolean;
var
  pluginSlots, masterSlots, pluginAppr, masterAppr: string;
begin
  Result := True;
  if not RobCoFO4Game then
    Exit;
  if not Assigned(master) then
    Exit;
  if ReadArmoObjectEffect(e) <> ReadArmoObjectEffect(master) then begin
    Result := False;
    Exit;
  end;
  pluginAppr := RobCoEffectiveApprKeywordRefs(e);
  masterAppr := RobCoEffectiveApprKeywordRefs(master);
  if not RobCoRefListDiffUnchangedVsMaster(pluginAppr, masterAppr) then begin
    Result := False;
    Exit;
  end;
  if ReadRecordDamageTypePairs(e) <> ReadRecordDamageTypePairs(master) then begin
    Result := False;
    Exit;
  end;
  pluginSlots := ReadArmoBipedSlotIndices(e);
  masterSlots := ReadArmoBipedSlotIndices(master);
  if not RobCoRefListDiffUnchangedVsMaster(pluginSlots, masterSlots) then begin
    Result := False;
    Exit;
  end;
  if ReadWeapDnamNativeValue(e, 'DNAM\Weight Mod') <>
    ReadWeapDnamNativeValue(master, 'DNAM\Weight Mod') then begin
    Result := False;
    Exit;
  end;
  if ReadWeapDnamNativeValue(e, 'DNAM\Health Mod') <>
    ReadWeapDnamNativeValue(master, 'DNAM\Health Mod') then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
function RobCoArmoFo4ExtrasUnchangedFromScratch: boolean;
begin
  Result := True;
  if not RobCoFO4Game then
    Exit;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapObjectEffect <> gRobCoSnapMasterObjectEffect then begin
    Result := False;
    Exit;
  end;
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapApprKw, gRobCoSnapMasterApprKw) then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapDamageTypes <> gRobCoSnapMasterDamageTypes then begin
    Result := False;
    Exit;
  end;
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapBipedSlots, gRobCoSnapMasterBipedSlots) then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapWeightMult <> gRobCoSnapMasterWeightMult then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapHealthMult <> gRobCoSnapMasterHealthMult then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
procedure RobCoApplyApprKeywordDiffIfItmGate(e: IInterface; const pluginAppr, masterAppr: string;
  var toAdd, toRemove: string);
begin
  // Same diff semantics as keywordsToAdd/Remove per Armor/Weapon/OMOD patcher articles.
  RobCoApplyRefListDiffIfItmGate(e, pluginAppr, masterAppr, toAdd, toRemove);
end;

//============================================================================
function ReadNpcSkinRef(e: IInterface): string;
begin
  Result := RobCoReadFormLinkPathOrRef(e, 'DNAM\Skin', 'GNAM');
end;

//============================================================================
function ReadNpcPowerArmorStandRef(e: IInterface): string;
begin
  Result := RobCoReadFormLinkPathOrRef(e, 'DNAM\Power Armor Stand', 'SNAM');
end;

//============================================================================
function ReadNpcXpValueOffset(e: IInterface): string;
begin
  Result := '';
  if ElementExists(e, 'EAMX') then
    Result := IntToStr(Round(GetElementNativeValues(e, 'EAMX')))
  else if ElementExists(e, 'ACBS\XP Value Offset') then
    Result := IntToStr(Round(GetElementNativeValues(e, 'ACBS\XP Value Offset')));
end;

//============================================================================
function RobCoNpcXpValueOffsetUnchanged(const pluginVal, masterVal: string): boolean;
begin
  if pluginVal = masterVal then
    Result := True
  else if (pluginVal = '') and (masterVal = '0') then
    Result := True
  else if (pluginVal = '0') and (masterVal = '') then
    Result := True
  else
    Result := False;
end;

//============================================================================
function RobCoNpcXpValueOffsetExportVal(const pluginVal, masterVal: string): string;
begin
  if RobCoNpcXpValueOffsetUnchanged(pluginVal, masterVal) then
    Result := ''
  else
    Result := pluginVal;
end;

//============================================================================
function ReadRaceSpellAndPerkRefs(e: IInterface): string;
var
  perks, spells: string;
begin
  perks := ReadPerkRefs(e);
  spells := ReadSpellRefs(e);
  if perks = '' then
    Result := spells
  else if spells = '' then
    Result := perks
  else
    Result := perks + ',' + spells;
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
function RobCoWeapDnamItmGateUnchanged(e, master: IInterface; const path: string;
  pluginValue, masterValue: string): boolean;
begin
  Result := True;
  if pluginValue = masterValue then
    Exit;
  if not RobCoSubElementConflictFreeByPath(e, master, path) then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
function RobCoExportWeapDnamFieldIfItmGate(e, master: IInterface; const path: string;
  pluginValue, masterValue: string): string;
begin
  Result := '';
  if not Assigned(master) then begin
    Result := pluginValue;
    Exit;
  end;
  if not RobCoSnapshotUseItmGate then begin
    Result := pluginValue;
    Exit;
  end;
  if RobCoSubElementConflictFreeByPath(e, master, path) then
    Exit;
  Result := RobCoExportFieldIfChanged(e, pluginValue, masterValue);
end;

//============================================================================
procedure GatherWeapFO4PatchExtras(e: IInterface; fromScratch: boolean);
var
  ammoRef, aimModel, apprKeywords, masterAppr, masterAmmo, masterAim, masterBash: string;
  pluginDmgTypes, masterDmgTypes: string;
  master: IInterface;
begin
  master := nil;
  masterBash := '';
  masterAmmo := '';
  masterAim := '';
  masterAppr := '';
  masterDmgTypes := '';
  if RobCoRecordHasExternalMaster(e) then begin
    master := RobCoCompareBaselineRecord(e);
    if fromScratch then begin
      masterBash := gRobCoSnapMasterBashDamage;
      masterAmmo := gRobCoSnapMasterAmmoRef;
      masterAim := gRobCoSnapMasterAimModel;
      masterAppr := gRobCoSnapMasterApprKw;
      masterDmgTypes := gRobCoSnapMasterDamageTypes;
    end else begin
      masterBash := ReadWeapBashDamage(master);
      masterAmmo := ReadWeapAmmoRef(master);
      masterAim := ReadWeapAimModelRef(master);
      masterAppr := RobCoEffectiveApprKeywordRefs(master);
      masterDmgTypes := ReadRecordDamageTypePairs(master);
    end;
  end;
  if fromScratch then
    gWeapPatchBashDamage := RobCoExportFieldIfChanged(e, gRobCoSnapBashDamage, masterBash)
  else
    gWeapPatchBashDamage := RobCoExportFieldIfChanged(e, ReadWeapBashDamage(e), masterBash);
  if fromScratch then
    ammoRef := gRobCoSnapAmmoRef
  else
    ammoRef := ReadWeapAmmoRef(e);
  gWeapPatchSetNewAmmo := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(ammoRef),
    RobCoNoneIfEmpty(masterAmmo));
  if fromScratch then
    aimModel := gRobCoSnapAimModel
  else
    aimModel := ReadWeapAimModelRef(e);
  gWeapPatchAimModel := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(aimModel),
    RobCoNoneIfEmpty(masterAim));
  if fromScratch then
    apprKeywords := gRobCoSnapApprKw
  else
    apprKeywords := RobCoEffectiveApprKeywordRefs(e);
  RobCoApplyApprKeywordDiffIfItmGate(e, RobCoNoneIfEmpty(apprKeywords),
    RobCoNoneIfEmpty(masterAppr), gWeapPatchAttachParentSlotKeywordsToAdd,
    gWeapPatchAttachParentSlotKeywordsToRemove);
  if fromScratch then
    pluginDmgTypes := gRobCoSnapDamageTypes
  else
    pluginDmgTypes := ReadRecordDamageTypePairs(e);
  if Assigned(master) then
    DiffDamageTypeMap(pluginDmgTypes, masterDmgTypes,
      gWeapPatchDamageTypesToChange, gWeapPatchDamageTypesToRemove)
  else begin
    gWeapPatchDamageTypesToChange := RobCoNoneIfEmpty(pluginDmgTypes);
    gWeapPatchDamageTypesToRemove := 'none';
  end;
  if Assigned(master) then begin
    if fromScratch then begin
      gWeapPatchOutOfRangeDamageMult := RobCoExportFieldIfChanged(e,
        gRobCoSnapOutOfRangeDamageMult, gRobCoSnapMasterOutOfRangeDamageMult);
      gWeapPatchConeIronSightsMultiplier := RobCoExportFieldIfChanged(e,
        gRobCoSnapConeIronSightsMult, gRobCoSnapMasterConeIronSightsMult);
      gWeapPatchRecoilDiminishSpringForce := RobCoExportFieldIfChanged(e,
        gRobCoSnapRecoilSpringForce, gRobCoSnapMasterRecoilSpringForce);
      gWeapPatchRecoilPerShotMin := RobCoExportFieldIfChanged(e,
        gRobCoSnapRecoilPerShotMin, gRobCoSnapMasterRecoilPerShotMin);
      gWeapPatchRecoilPerShotMax := RobCoExportFieldIfChanged(e,
        gRobCoSnapRecoilPerShotMax, gRobCoSnapMasterRecoilPerShotMax);
      gWeapPatchAttackActionPointCost := RobCoExportWeapDnamFieldIfItmGate(e, master,
        'DNAM\Action Point Cost',
        gRobCoSnapAttackActionPointCost, gRobCoSnapMasterAttackActionPointCost);
      gWeapPatchSoundLevel := RobCoExportWeapDnamFieldIfItmGate(e, master,
        'DNAM\Sound Level',
        gRobCoSnapSoundLevel, gRobCoSnapMasterSoundLevel);
      gWeapPatchWeaponHitType := RobCoExportFieldIfChanged(e,
        gRobCoSnapWeaponHitType, gRobCoSnapMasterWeaponHitType);
      gWeapPatchOverrideProjectile := RobCoExportFieldIfChanged(e,
        gRobCoSnapOverrideProjectile, gRobCoSnapMasterOverrideProjectile);
      gWeapPatchSetNewAmmoList := RobCoExportFieldIfChanged(e,
        gRobCoSnapNpcAmmoList, gRobCoSnapMasterNpcAmmoList);
    end else begin
      gWeapPatchOutOfRangeDamageMult := RobCoExportFieldIfChanged(e,
        ReadWeapDnamNativeValue(e, 'DNAM\Out of Range Damage Mult'),
        ReadWeapDnamNativeValue(master, 'DNAM\Out of Range Damage Mult'));
      gWeapPatchConeIronSightsMultiplier := RobCoExportFieldIfChanged(e,
        ReadWeapAimModelScalar(e, 'DNAM\Cone Iron Sights Mult'),
        ReadWeapAimModelScalar(master, 'DNAM\Cone Iron Sights Mult'));
      gWeapPatchRecoilDiminishSpringForce := RobCoExportFieldIfChanged(e,
        ReadWeapAimModelScalar(e, 'DNAM\Recoil Diminish Spring Force'),
        ReadWeapAimModelScalar(master, 'DNAM\Recoil Diminish Spring Force'));
      gWeapPatchRecoilPerShotMin := RobCoExportFieldIfChanged(e,
        ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Min Degrees'),
        ReadWeapAimModelScalar(master, 'DNAM\Recoil Per Shot - Min Degrees'));
      gWeapPatchRecoilPerShotMax := RobCoExportFieldIfChanged(e,
        ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Max Degrees'),
        ReadWeapAimModelScalar(master, 'DNAM\Recoil Per Shot - Max Degrees'));
      gWeapPatchAttackActionPointCost := RobCoExportWeapDnamFieldIfItmGate(e, master,
        'DNAM\Action Point Cost',
        ReadWeapDnamNativeValue(e, 'DNAM\Action Point Cost'),
        ReadWeapDnamNativeValue(master, 'DNAM\Action Point Cost'));
      gWeapPatchSoundLevel := RobCoExportWeapDnamFieldIfItmGate(e, master,
        'DNAM\Sound Level',
        ReadWeapDnamEditValue(e, 'DNAM\Sound Level'),
        ReadWeapDnamEditValue(master, 'DNAM\Sound Level'));
      gWeapPatchWeaponHitType := RobCoExportFieldIfChanged(e,
        ReadWeapDnamEditValue(e, 'DNAM\Weapon Hit Type'),
        ReadWeapDnamEditValue(master, 'DNAM\Weapon Hit Type'));
      gWeapPatchOverrideProjectile := RobCoExportFieldIfChanged(e,
        RobCoNoneIfEmpty(ReadWeapOverrideProjectile(e)),
        RobCoNoneIfEmpty(ReadWeapOverrideProjectile(master)));
      gWeapPatchSetNewAmmoList := RobCoExportFieldIfChanged(e,
        RobCoNoneIfEmpty(ReadWeapNpcAmmoList(e)),
        RobCoNoneIfEmpty(ReadWeapNpcAmmoList(master)));
    end;
  end else begin
    gWeapPatchOutOfRangeDamageMult := ReadWeapDnamNativeValue(e, 'DNAM\Out of Range Damage Mult');
    gWeapPatchConeIronSightsMultiplier := ReadWeapAimModelScalar(e, 'DNAM\Cone Iron Sights Mult');
    gWeapPatchRecoilDiminishSpringForce := ReadWeapAimModelScalar(e, 'DNAM\Recoil Diminish Spring Force');
    gWeapPatchRecoilPerShotMin := ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Min Degrees');
    gWeapPatchRecoilPerShotMax := ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Max Degrees');
    if fromScratch then begin
      gWeapPatchAttackActionPointCost := gRobCoSnapAttackActionPointCost;
      gWeapPatchSoundLevel := gRobCoSnapSoundLevel;
    end else begin
      gWeapPatchAttackActionPointCost := ReadWeapDnamNativeValue(e, 'DNAM\Action Point Cost');
      gWeapPatchSoundLevel := ReadWeapDnamEditValue(e, 'DNAM\Sound Level');
    end;
    gWeapPatchWeaponHitType := ReadWeapDnamEditValue(e, 'DNAM\Weapon Hit Type');
    gWeapPatchOverrideProjectile := RobCoNoneIfEmpty(ReadWeapOverrideProjectile(e));
    gWeapPatchSetNewAmmoList := RobCoNoneIfEmpty(ReadWeapNpcAmmoList(e));
  end;
end;

//============================================================================
function RobCoWeapFo4ExtrasUnchanged(e, master: IInterface): boolean;
var
  pluginDmg, masterDmg, changeOut, removeOut, pluginAppr, masterAppr: string;
begin
  Result := True;
  if not RobCoFO4Game then
    Exit;
  if not Assigned(master) then
    Exit;
  if ReadWeapBashDamage(e) <> ReadWeapBashDamage(master) then begin
    Result := False;
    Exit;
  end;
  if ReadWeapAmmoRef(e) <> ReadWeapAmmoRef(master) then begin
    Result := False;
    Exit;
  end;
  if ReadWeapAimModelRef(e) <> ReadWeapAimModelRef(master) then begin
    Result := False;
    Exit;
  end;
  pluginAppr := RobCoEffectiveApprKeywordRefs(e);
  masterAppr := RobCoEffectiveApprKeywordRefs(master);
  if not RobCoRefListDiffUnchangedVsMaster(pluginAppr, masterAppr) then begin
    Result := False;
    Exit;
  end;
  pluginDmg := ReadRecordDamageTypePairs(e);
  masterDmg := ReadRecordDamageTypePairs(master);
  DiffDamageTypeMap(pluginDmg, masterDmg, changeOut, removeOut);
  if (changeOut <> '') and (changeOut <> 'none') then begin
    Result := False;
    Exit;
  end;
  if (removeOut <> '') and (removeOut <> 'none') then begin
    Result := False;
    Exit;
  end;
  if ReadWeapDnamNativeValue(e, 'DNAM\Out of Range Damage Mult') <>
    ReadWeapDnamNativeValue(master, 'DNAM\Out of Range Damage Mult') then begin
    Result := False;
    Exit;
  end;
  if ReadWeapAimModelScalar(e, 'DNAM\Cone Iron Sights Mult') <>
    ReadWeapAimModelScalar(master, 'DNAM\Cone Iron Sights Mult') then begin
    Result := False;
    Exit;
  end;
  if ReadWeapAimModelScalar(e, 'DNAM\Recoil Diminish Spring Force') <>
    ReadWeapAimModelScalar(master, 'DNAM\Recoil Diminish Spring Force') then begin
    Result := False;
    Exit;
  end;
  if ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Min Degrees') <>
    ReadWeapAimModelScalar(master, 'DNAM\Recoil Per Shot - Min Degrees') then begin
    Result := False;
    Exit;
  end;
  if ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Max Degrees') <>
    ReadWeapAimModelScalar(master, 'DNAM\Recoil Per Shot - Max Degrees') then begin
    Result := False;
    Exit;
  end;
  if ReadWeapDnamNativeValue(e, 'DNAM\Action Point Cost') <>
    ReadWeapDnamNativeValue(master, 'DNAM\Action Point Cost') then begin
    if not RobCoSubElementConflictFreeByPath(e, master, 'DNAM\Action Point Cost') then begin
      Result := False;
      Exit;
    end;
  end;
  if ReadWeapDnamEditValue(e, 'DNAM\Sound Level') <>
    ReadWeapDnamEditValue(master, 'DNAM\Sound Level') then begin
    if not RobCoSubElementConflictFreeByPath(e, master, 'DNAM\Sound Level') then begin
      Result := False;
      Exit;
    end;
  end;
  if ReadWeapDnamEditValue(e, 'DNAM\Weapon Hit Type') <>
    ReadWeapDnamEditValue(master, 'DNAM\Weapon Hit Type') then begin
    Result := False;
    Exit;
  end;
  if RobCoNoneIfEmpty(ReadWeapOverrideProjectile(e)) <>
    RobCoNoneIfEmpty(ReadWeapOverrideProjectile(master)) then begin
    Result := False;
    Exit;
  end;
  if RobCoNoneIfEmpty(ReadWeapNpcAmmoList(e)) <>
    RobCoNoneIfEmpty(ReadWeapNpcAmmoList(master)) then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
function RobCoWeapFo4ExtrasUnchangedFromScratch(e: IInterface): boolean;
var
  changeOut, removeOut: string;
begin
  Result := True;
  if not RobCoFO4Game then
    Exit;
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if gRobCoSnapBashDamage <> gRobCoSnapMasterBashDamage then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapAmmoRef <> gRobCoSnapMasterAmmoRef then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapAimModel <> gRobCoSnapMasterAimModel then begin
    Result := False;
    Exit;
  end;
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapApprKw, gRobCoSnapMasterApprKw) then begin
    Result := False;
    Exit;
  end;
  DiffDamageTypeMap(gRobCoSnapDamageTypes, gRobCoSnapMasterDamageTypes, changeOut, removeOut);
  if (changeOut <> '') and (changeOut <> 'none') then begin
    Result := False;
    Exit;
  end;
  if (removeOut <> '') and (removeOut <> 'none') then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapOutOfRangeDamageMult <> gRobCoSnapMasterOutOfRangeDamageMult then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapConeIronSightsMult <> gRobCoSnapMasterConeIronSightsMult then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapRecoilSpringForce <> gRobCoSnapMasterRecoilSpringForce then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapRecoilPerShotMin <> gRobCoSnapMasterRecoilPerShotMin then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapRecoilPerShotMax <> gRobCoSnapMasterRecoilPerShotMax then begin
    Result := False;
    Exit;
  end;
  if not RobCoWeapDnamItmGateUnchanged(e, gRobCoSnapMaster, 'DNAM\Action Point Cost',
    gRobCoSnapAttackActionPointCost, gRobCoSnapMasterAttackActionPointCost) then begin
    Result := False;
    Exit;
  end;
  if not RobCoWeapDnamItmGateUnchanged(e, gRobCoSnapMaster, 'DNAM\Sound Level',
    gRobCoSnapSoundLevel, gRobCoSnapMasterSoundLevel) then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapWeaponHitType <> gRobCoSnapMasterWeaponHitType then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapOverrideProjectile <> gRobCoSnapMasterOverrideProjectile then begin
    Result := False;
    Exit;
  end;
  if gRobCoSnapNpcAmmoList <> gRobCoSnapMasterNpcAmmoList then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
procedure GatherWeapPatchData(e: IInterface);
var
  keywords: string;
begin
  InitRobCoWEAPPatchData;

  gWeapPatchFilterByWeapons := RobCoPatchFilterFormIDRef(e);
  keywords := RobCoReadKeywordRefsFromElement(e);
  RobCoApplyKeywordDiffIfItmGate(e, keywords, gWeapPatchKeywordsToAdd, gWeapPatchKeywordsToRemove);

  gWeapPatchFullName := RobCoFullNameIfChanged(e);
  gWeapPatchAttackDamage := RobCoDataFieldIfChanged(e, 'Damage');
  gWeapPatchWeight := RobCoDataFieldIfChanged(e, 'Weight');
  gWeapPatchValue := RobCoDataFieldIfChanged(e, 'Value');

  if RobCoFO4Game then
    GatherWeapFO4PatchExtras(e, False);
end;

//============================================================================
function BuildRobCoWEAPLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByWeapons', gWeapPatchFilterByWeapons);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByAmmos', gWeapPatchFilterByAmmos);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByWeaponsExcluded', gWeapPatchFilterByWeaponsExcluded);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywords', gWeapPatchFilterByKeywords);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsOr', gWeapPatchFilterByKeywordsOr);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gWeapPatchFilterByKeywordsExcluded);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByHasAmmoFromWeaponList',
    gWeapPatchFilterByHasAmmoFromWeaponList);

  Result := RobCoAppendField(Result, 'fullName', gWeapPatchFullName, False);

  if RobCoFO4Game then begin
    Result := RobCoAppendNumericField(Result, 'attackDamage', gWeapPatchAttackDamage);
    Result := RobCoAppendNumericField(Result, 'bashDamage', gWeapPatchBashDamage);
    Result := RobCoAppendNumericField(Result, 'outOfRangeDamageMult', gWeapPatchOutOfRangeDamageMult);
    Result := RobCoAppendNumericField(Result, 'coneIronSightsMultiplier', gWeapPatchConeIronSightsMultiplier);
    Result := RobCoAppendNumericField(Result, 'recoilDiminishSpringForce', gWeapPatchRecoilDiminishSpringForce);
    Result := RobCoAppendNumericField(Result, 'recoilPerShotMin', gWeapPatchRecoilPerShotMin);
    Result := RobCoAppendNumericField(Result, 'recoilPerShotMax', gWeapPatchRecoilPerShotMax);
    Result := RobCoAppendNumericField(Result, 'attackActionPointCost', gWeapPatchAttackActionPointCost);
    Result := RobCoAppendField(Result, 'soundLevel', gWeapPatchSoundLevel, True);
    Result := RobCoAppendField(Result, 'weaponHitType', gWeapPatchWeaponHitType, True);
    Result := RobCoAppendField(Result, 'keywordsToAdd', gWeapPatchKeywordsToAdd, True);
    Result := RobCoAppendField(Result, 'keywordsToRemove', gWeapPatchKeywordsToRemove, True);
    Result := RobCoAppendField(Result, 'setNewAmmo', gWeapPatchSetNewAmmo, True);
    Result := RobCoAppendField(Result, 'setNewAmmoList', gWeapPatchSetNewAmmoList, True);
    Result := RobCoAppendField(Result, 'aimModel', gWeapPatchAimModel, True);
    Result := RobCoAppendField(Result, 'overrideProjectile', gWeapPatchOverrideProjectile, True);
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
  master := RobCoCompareBaselineRecord(e);
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
    apprKeywords := RobCoEffectiveApprKeywordRefs(e);
    masterAppr := RobCoEffectiveApprKeywordRefs(master);
    if not RobCoListFieldUnchangedVsMaster(e, apprKeywords, masterAppr) then
      Exit;
    if not RobCoWeapFo4ExtrasUnchanged(e, master) then
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
  gRobCoSnapAttackActionPointCost := '';
  gRobCoSnapMasterAttackActionPointCost := '';
  gRobCoSnapSoundLevel := '';
  gRobCoSnapMasterSoundLevel := '';
  if RobCoFO4Game then begin
    gRobCoSnapBashDamage := ReadWeapBashDamage(e);
    gRobCoSnapAmmoRef := ReadWeapAmmoRef(e);
    gRobCoSnapAimModel := ReadWeapAimModelRef(e);
    gRobCoSnapAttackActionPointCost := ReadWeapDnamNativeValue(e, 'DNAM\Action Point Cost');
    gRobCoSnapSoundLevel := ReadWeapDnamEditValue(e, 'DNAM\Sound Level');
    gRobCoSnapDamageTypes := ReadRecordDamageTypePairs(e);
    gRobCoSnapOutOfRangeDamageMult := ReadWeapDnamNativeValue(e, 'DNAM\Out of Range Damage Mult');
    gRobCoSnapConeIronSightsMult := ReadWeapAimModelScalar(e, 'DNAM\Cone Iron Sights Mult');
    gRobCoSnapRecoilSpringForce := ReadWeapAimModelScalar(e, 'DNAM\Recoil Diminish Spring Force');
    gRobCoSnapRecoilPerShotMin := ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Min Degrees');
    gRobCoSnapRecoilPerShotMax := ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Max Degrees');
    gRobCoSnapWeaponHitType := ReadWeapDnamEditValue(e, 'DNAM\Weapon Hit Type');
    gRobCoSnapOverrideProjectile := RobCoNoneIfEmpty(ReadWeapOverrideProjectile(e));
    gRobCoSnapNpcAmmoList := RobCoNoneIfEmpty(ReadWeapNpcAmmoList(e));
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
      gRobCoSnapMasterAttackActionPointCost := ReadWeapDnamNativeValue(gRobCoSnapMaster,
        'DNAM\Action Point Cost');
      gRobCoSnapMasterSoundLevel := ReadWeapDnamEditValue(gRobCoSnapMaster, 'DNAM\Sound Level');
      gRobCoSnapMasterDamageTypes := ReadRecordDamageTypePairs(gRobCoSnapMaster);
      gRobCoSnapMasterOutOfRangeDamageMult := ReadWeapDnamNativeValue(gRobCoSnapMaster,
        'DNAM\Out of Range Damage Mult');
      gRobCoSnapMasterConeIronSightsMult := ReadWeapAimModelScalar(gRobCoSnapMaster,
        'DNAM\Cone Iron Sights Mult');
      gRobCoSnapMasterRecoilSpringForce := ReadWeapAimModelScalar(gRobCoSnapMaster,
        'DNAM\Recoil Diminish Spring Force');
      gRobCoSnapMasterRecoilPerShotMin := ReadWeapAimModelScalar(gRobCoSnapMaster,
        'DNAM\Recoil Per Shot - Min Degrees');
      gRobCoSnapMasterRecoilPerShotMax := ReadWeapAimModelScalar(gRobCoSnapMaster,
        'DNAM\Recoil Per Shot - Max Degrees');
      gRobCoSnapMasterWeaponHitType := ReadWeapDnamEditValue(gRobCoSnapMaster, 'DNAM\Weapon Hit Type');
      gRobCoSnapMasterOverrideProjectile := RobCoNoneIfEmpty(ReadWeapOverrideProjectile(gRobCoSnapMaster));
      gRobCoSnapMasterNpcAmmoList := RobCoNoneIfEmpty(ReadWeapNpcAmmoList(gRobCoSnapMaster));
    end;
  end;
end;

//============================================================================
function RobCoWeapFieldsUnchangedFromScratch(e: IInterface): boolean;
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
    if not RobCoWeapDnamItmGateUnchanged(e, gRobCoSnapMaster, 'DNAM\Action Point Cost',
      gRobCoSnapAttackActionPointCost, gRobCoSnapMasterAttackActionPointCost) then
      Exit;
    if not RobCoWeapDnamItmGateUnchanged(e, gRobCoSnapMaster, 'DNAM\Sound Level',
      gRobCoSnapSoundLevel, gRobCoSnapMasterSoundLevel) then
      Exit;
    if not RobCoWeapFo4ExtrasUnchangedFromScratch(e) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure GatherWeapPatchDataFromScratch(e: IInterface);
begin
  InitRobCoWEAPPatchData;
  gWeapPatchFilterByWeapons := RobCoPatchFilterFormIDRef(e);
  RobCoApplyKeywordDiffIfItmGate(e, gRobCoSnapKeywords,
    gWeapPatchKeywordsToAdd, gWeapPatchKeywordsToRemove);
  gWeapPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapFullName, gRobCoSnapMasterFullName);
  gWeapPatchAttackDamage := RobCoExportFieldIfChanged(e, gRobCoSnapDamage, gRobCoSnapMasterDamage);
  gWeapPatchWeight := RobCoExportFieldIfChanged(e, gRobCoSnapWeight, gRobCoSnapMasterWeight);
  gWeapPatchValue := RobCoExportFieldIfChanged(e, gRobCoSnapValue, gRobCoSnapMasterValue);
  if RobCoFO4Game then
    GatherWeapFO4PatchExtras(e, True);
end;

//============================================================================
procedure ExportWEAPToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'WEAP' then
    Exit;

  RobCoReadWeapPatchInputs(e);
  if RobCoSnapshotUseItmGate then begin
    if RobCoWeapFieldsUnchangedFromScratch(e) then begin
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

  RobCoApplyKeywordDiffIfItmGate(e, keywords, gAlchPatchKeywordsToAdd, gAlchPatchKeywordsToRemove);

  if RobCoRecordHasExternalMaster(e) then begin
    if RobCoSnapshotUseItmGate then begin
      master := RobCoCompareBaselineRecord(e);
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
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByAlchsExcluded', gAlchPatchFilterByAlchsExcluded);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywords', gAlchPatchFilterByKeywords);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsOr', gAlchPatchFilterByKeywordsOr);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gAlchPatchFilterByKeywordsExcluded);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByMgefs', gAlchPatchFilterByMgefs);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByMgefsOr', gAlchPatchFilterByMgefsOr);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByMgefsExcluded', gAlchPatchFilterByMgefsExcluded);

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
  master := RobCoCompareBaselineRecord(e);
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
  RobCoApplyKeywordDiffIfItmGate(e, gRobCoSnapKeywords,
    gAlchPatchKeywordsToAdd, gAlchPatchKeywordsToRemove);
  if Assigned(gRobCoSnapMaster) then begin
    if RobCoSnapshotUseItmGate then
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

  gRobCoSnapRaceSubgraphMask := 0;

  if RobCoSnapshotUseItmGate then begin
    if RobCoSnapTryEarlyPregatherSkipAlch(e) then begin
      RobCoSnapRecordEarlyPregatherSkip('ExportALCHToRobCo');
      Exit;
    end;
  end;

  RobCoReadAlchPatchInputs(e);
  if RobCoSnapshotUseItmGate then begin
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
  gOmodPatchFullName, gOmodPatchSetAttachPoint: string;
  gOmodPatchAttachParentSlotKeywordsToAdd, gOmodPatchAttachParentSlotKeywordsToRemove: string;
  gOmodPatchChangeOModPropertiesFloat, gOmodPatchChangeOModPropertiesVP, gOmodPatchChangeOModPropertiesForm: string;
  gOmodPatchChangeOModFunctionType, gOmodPatchRemoveOModProperties: string;
  gOmodPatchRemoveOModPropertiesVP, gOmodPatchRemoveOModPropertiesForm: string;

  gRobCoOmodScratchSeenFloat, gRobCoOmodScratchSeenVp, gRobCoOmodScratchSeenForm: TStringList;
  gRobCoOmodScratchFloat, gRobCoOmodScratchVp, gRobCoOmodScratchForm: TStringList;
  gRobCoOmodScratchFn: TStringList;
  gRobCoOmodScratchMasterFloat, gRobCoOmodScratchMasterVp, gRobCoOmodScratchMasterForm: TStringList;

//============================================================================
procedure RobCoOmodEnsurePropListScratch;
begin
  if not Assigned(gRobCoOmodScratchFloat) then begin
    gRobCoOmodScratchFloat := TStringList.Create;
    gRobCoOmodScratchVp := TStringList.Create;
    gRobCoOmodScratchForm := TStringList.Create;
    gRobCoOmodScratchFn := TStringList.Create;
    gRobCoOmodScratchMasterFloat := TStringList.Create;
    gRobCoOmodScratchMasterVp := TStringList.Create;
    gRobCoOmodScratchMasterForm := TStringList.Create;
  end;
  gRobCoOmodScratchFloat.Clear;
  gRobCoOmodScratchVp.Clear;
  gRobCoOmodScratchForm.Clear;
  gRobCoOmodScratchFn.Clear;
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
  valueType, propName, propKey, floatVal, vpEntry, floatEntry, fnType, fnEntry: string;
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

    propKey := OmodPropertyKeyForExport(propName);
    fnType := OmodFunctionTypeToken(prop);
    if (propKey <> '') and (fnType <> '') then begin
      fnEntry := propKey + '=' + fnType;
      if gRobCoOmodScratchFn.IndexOf(fnEntry) < 0 then
        gRobCoOmodScratchFn.Add(fnEntry);
    end;

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
function OmodFunctionTypeToken(prop: IInterface): string;
var
  s: string;
begin
  Result := '';
  if not Assigned(prop) then
    Exit;
  s := LowerCase(Trim(GetElementEditValues(prop, 'Function Type')));
  if s = '' then
    Exit;
  if Pos('mult', s) > 0 then
    Result := 'multandadd'
  else if Pos('add', s) > 0 then
    Result := 'add'
  else if Pos('set', s) > 0 then
    Result := 'set'
  else if (Pos('rem', s) > 0) or (Pos('remove', s) > 0) then
    Result := 'rem'
  else
    Result := s;
end;

//============================================================================
procedure RobCoOmodPluginPatchKeysIntoSeen(const patchText: string);
var
  i, eqPos: integer;
  part, key: string;
begin
  if (patchText = '') or (patchText = 'none') then
    Exit;
  RobCoSnapEnsureCommaScratch;
  gRobCoSnapCommaScratch.StrictDelimiter := True;
  gRobCoSnapCommaScratch.Delimiter := ',';
  gRobCoSnapCommaScratch.DelimitedText := patchText;
  for i := 0 to Pred(gRobCoSnapCommaScratch.Count) do begin
    part := gRobCoSnapCommaScratch[i];
    if part = '' then
      Continue;
    eqPos := Pos('=', part);
    if eqPos > 0 then
      key := Copy(part, 1, eqPos - 1)
    else
      key := part;
    if gRobCoSnapRefSeenScratch.IndexOf(key) < 0 then
      gRobCoSnapRefSeenScratch.Add(key);
  end;
end;

//============================================================================
procedure GatherOmodPropertyExtras(e, master: IInterface;
  const pluginFloatText, pluginVpText, pluginFormText: string);
var
  props, prop, link: IInterface;
  i, eqPos: integer;
  valueType, propName, propKey, formEntry, leftRef: string;
  floatRem, vpRem, formRem: string;
begin
  gOmodPatchChangeOModFunctionType := 'none';
  gOmodPatchRemoveOModProperties := 'none';
  gOmodPatchRemoveOModPropertiesVP := 'none';
  gOmodPatchRemoveOModPropertiesForm := 'none';
  if not Assigned(master) then
    Exit;

  gOmodPatchChangeOModFunctionType := RobCoExportFieldIfChanged(e,
    RobCoNoneIfEmpty(RobCoJoinParts(gRobCoOmodScratchFn)), 'none');

  RobCoSnapEnsureRefSeenScratch;
  RobCoOmodPluginPatchKeysIntoSeen(pluginFloatText);
  RobCoOmodPluginPatchKeysIntoSeen(pluginVpText);
  RobCoOmodPluginPatchKeysIntoSeen(pluginFormText);

  props := ElementByName(master, 'Properties');
  if not Assigned(props) then
    Exit;

  RobCoSnapEnsureCommaScratch;
  RobCoSnapEnsurePartsScratch;
  for i := 0 to Pred(ElementCount(props)) do begin
    prop := ElementByIndex(props, i);
    propName := GetElementEditValues(prop, 'Property');
    propKey := OmodPropertyKeyForExport(propName);
    valueType := GetElementEditValues(prop, 'Value Type');
    if valueType = '' then
      valueType := GetElementEditValues(prop, 'Type');
    if OmodValueTypeIsVP(valueType) then begin
      link := OmodPropObjectLink(prop);
      if Assigned(link) then begin
        leftRef := RobCoMasterFormIDRef(link);
        if gRobCoSnapRefSeenScratch.IndexOf(leftRef) < 0 then
          if gRobCoSnapCommaScratch2.IndexOf(leftRef) < 0 then
            gRobCoSnapCommaScratch2.Add(leftRef);
      end;
    end else if OmodValueTypeIsForm(valueType) then begin
      formEntry := OmodPropFormPairEntry(prop);
      if formEntry <> '' then begin
        eqPos := Pos('=', formEntry);
        if eqPos > 0 then
          leftRef := Copy(formEntry, 1, eqPos - 1)
        else
          leftRef := formEntry;
        if gRobCoSnapRefSeenScratch.IndexOf(leftRef) < 0 then
          if gRobCoSnapPartsScratch.IndexOf(leftRef) < 0 then
            gRobCoSnapPartsScratch.Add(leftRef);
      end;
    end else if propKey <> '' then begin
      if gRobCoSnapRefSeenScratch.IndexOf(propKey) < 0 then
        if gRobCoSnapCommaScratch.IndexOf(propKey) < 0 then
          gRobCoSnapCommaScratch.Add(propKey);
    end;
  end;
  floatRem := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoSnapCommaScratch));
  vpRem := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoSnapCommaScratch2));
  formRem := RobCoNoneIfEmpty(RobCoJoinParts(gRobCoSnapPartsScratch));
  gOmodPatchRemoveOModProperties := RobCoExportFieldIfChanged(e, floatRem, 'none');
  gOmodPatchRemoveOModPropertiesVP := RobCoExportFieldIfChanged(e, vpRem, 'none');
  gOmodPatchRemoveOModPropertiesForm := RobCoExportFieldIfChanged(e, formRem, 'none');
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
procedure RobCoSnapStashOmodHeader(e, master: IInterface; const plainName, masterPlainName,
  attach, masterAttach, appr, masterAppr: string);
begin
  gRobCoSnapOmodHeaderStashed := True;
  gRobCoSnapOmodPlainName := plainName;
  gRobCoSnapMasterOmodPlainName := masterPlainName;
  gRobCoSnapOmodAttach := attach;
  gRobCoSnapMasterOmodAttach := masterAttach;
  gRobCoSnapOmodApprKw := appr;
  gRobCoSnapMasterOmodApprKw := masterAppr;
end;

//============================================================================
function RobCoOmodHeaderUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  attach, masterAttach, appr, masterAppr, plainName, masterPlainName: string;
begin
  Result := False;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := RobCoCompareBaselineRecord(e);
  plainName := RobCoReadPlainFullName(e);
  masterPlainName := RobCoReadPlainFullName(master);
  if plainName <> masterPlainName then
    Exit;
  attach := ReadOmodAttachPoint(e);
  masterAttach := ReadOmodAttachPoint(master);
  if attach <> masterAttach then
    Exit;
  appr := RobCoEffectiveApprKeywordRefs(e);
  masterAppr := RobCoEffectiveApprKeywordRefs(master);
  if not RobCoListFieldUnchangedVsMaster(e, appr, masterAppr) then
    Exit;
  RobCoSnapStashOmodHeader(e, master, plainName, masterPlainName, attach, masterAttach, appr, masterAppr);
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
  if gRobCoSnapOmodHeaderStashed then
    Exit;
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
  RobCoApplyApprKeywordDiffIfItmGate(e, gRobCoSnapOmodApprKw, gRobCoSnapMasterOmodApprKw,
    gOmodPatchAttachParentSlotKeywordsToAdd, gOmodPatchAttachParentSlotKeywordsToRemove);

  headerUnchanged := False;
  if RobCoItmGateExternalOverride(e) then
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
  if RobCoRecordHasExternalMaster(e) then
    GatherOmodPropertyExtras(e, gRobCoSnapMaster,
      gOmodPatchChangeOModPropertiesFloat, gOmodPatchChangeOModPropertiesVP,
      gOmodPatchChangeOModPropertiesForm);
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
  gOmodPatchAttachParentSlotKeywordsToRemove := 'none';
  gOmodPatchChangeOModPropertiesFloat := '';
  gOmodPatchChangeOModPropertiesVP := '';
  gOmodPatchChangeOModPropertiesForm := '';
  gOmodPatchChangeOModFunctionType := 'none';
  gOmodPatchRemoveOModProperties := 'none';
  gOmodPatchRemoveOModPropertiesVP := 'none';
  gOmodPatchRemoveOModPropertiesForm := 'none';
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
    masterAttach := ReadOmodAttachPoint(RobCoCompareBaselineRecord(e));
    masterAppr := RobCoEffectiveApprKeywordRefs(RobCoCompareBaselineRecord(e));
  end;
  gOmodPatchSetAttachPoint := RobCoExportFieldIfChanged(e, ReadOmodAttachPoint(e), masterAttach);
  apprKeywords := RobCoEffectiveApprKeywordRefs(e);
  RobCoApplyApprKeywordDiffIfItmGate(e, apprKeywords, masterAppr,
    gOmodPatchAttachParentSlotKeywordsToAdd, gOmodPatchAttachParentSlotKeywordsToRemove);

  headerUnchanged := False;
  if RobCoItmGateExternalOverride(e) then
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
      GatherOmodProperties(RobCoCompareBaselineRecord(e), gRobCoOmodScratchMasterFloat,
        gRobCoOmodScratchMasterVp, gRobCoOmodScratchMasterForm);
  end;
  gOmodPatchChangeOModPropertiesFloat := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchFloat), RobCoJoinParts(gRobCoOmodScratchMasterFloat));
  gOmodPatchChangeOModPropertiesVP := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchVp), RobCoJoinParts(gRobCoOmodScratchMasterVp));
  gOmodPatchChangeOModPropertiesForm := RobCoExportListFieldIfChanged(e,
    RobCoJoinParts(gRobCoOmodScratchForm), RobCoJoinParts(gRobCoOmodScratchMasterForm));
  if RobCoRecordHasExternalMaster(e) then
    GatherOmodPropertyExtras(e, RobCoCompareBaselineRecord(e),
      gOmodPatchChangeOModPropertiesFloat, gOmodPatchChangeOModPropertiesVP,
      gOmodPatchChangeOModPropertiesForm);
end;

//============================================================================
function BuildRobCoOMODLine: string;
begin
  Result := '';
  Result := RobCoAppendPatchField(Result, 'filterByOMod', gOmodPatchFilterByOMod);
  Result := RobCoAppendAuthoringBatchField(Result, 'connectionAnd', gOmodPatchConnectionAnd);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByOModExcluded', gOmodPatchFilterByOModExcluded);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByFormType', gOmodPatchFilterByFormType);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByNameContainsAnd', gOmodPatchFilterByNameContainsAnd);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByNameContainsOr', gOmodPatchFilterByNameContainsOr);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByNameContainsExclude',
    gOmodPatchFilterByNameContainsExclude);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByPropertiesAnd', gOmodPatchFilterByPropertiesAnd);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByPropertiesOr', gOmodPatchFilterByPropertiesOr);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByPropertiesExclude',
    gOmodPatchFilterByPropertiesExclude);
  Result := RobCoAppendAuthoringBatchField(Result, 'filterByAttachPoint', gOmodPatchFilterByAttachPoint);

  Result := RobCoAppendField(Result, 'fullName', gOmodPatchFullName, False);
  Result := RobCoAppendField(Result, 'setAttachPoint', gOmodPatchSetAttachPoint, False);
  Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToAdd',
    gOmodPatchAttachParentSlotKeywordsToAdd, False);
  Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToRemove',
    gOmodPatchAttachParentSlotKeywordsToRemove, True);
  Result := RobCoAppendField(Result, 'changeOModPropertiesFloat',
    gOmodPatchChangeOModPropertiesFloat, False);
  Result := RobCoAppendField(Result, 'changeOModPropertiesVP',
    gOmodPatchChangeOModPropertiesVP, False);
  Result := RobCoAppendField(Result, 'changeOModPropertiesForm',
    gOmodPatchChangeOModPropertiesForm, False);
  Result := RobCoAppendField(Result, 'changeOModFunctionType',
    gOmodPatchChangeOModFunctionType, True);
  Result := RobCoAppendField(Result, 'removeOModProperties',
    gOmodPatchRemoveOModProperties, True);
  Result := RobCoAppendField(Result, 'removeOModPropertiesVP',
    gOmodPatchRemoveOModPropertiesVP, True);
  Result := RobCoAppendField(Result, 'removeOModPropertiesForm',
    gOmodPatchRemoveOModPropertiesForm, True);
end;

//============================================================================
procedure ExportOMODToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
var
  line: string;
begin
  if Signature(e) <> 'OMOD' then
    Exit;

  gRobCoSnapOmodHeaderStashed := False;

  if RobCoSnapshotUseItmGate then begin
    if RobCoSnapTryEarlyPregatherSkipOmod(e) then begin
      RobCoSnapRecordEarlyPregatherSkip('ExportOMODToRobCo');
      Exit;
    end;
  end;

  RobCoReadOmodPatchInputs(e);
  if RobCoSnapshotUseItmGate then begin
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
  gNpcPatchSkin, gNpcPatchPowerArmorStand, gNpcPatchXpValueOffset: string;



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
  if gRobCoSnapCachedNpcItemPath <> '' then begin
    Result := gRobCoSnapCachedNpcItemPath;
    Exit;
  end;
  if wbGameMode = gmTES4 then
    gRobCoSnapCachedNpcItemPath := 'Item'
  else
    gRobCoSnapCachedNpcItemPath := 'CNTO\Item';
  Result := gRobCoSnapCachedNpcItemPath;
end;

//============================================================================
function NpcItemCountPath: string;
begin
  if gRobCoSnapCachedNpcItemCountPath <> '' then begin
    Result := gRobCoSnapCachedNpcItemCountPath;
    Exit;
  end;
  if wbGameMode = gmTES4 then
    gRobCoSnapCachedNpcItemCountPath := 'Count'
  else
    gRobCoSnapCachedNpcItemCountPath := 'CNTO\Count';
  Result := gRobCoSnapCachedNpcItemCountPath;
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
  if (gRobCoSnapRaceSubgraphMask and 16) <> 0 then begin
    gRobCoSnapMasterAcbsAutoCalc := gRobCoSnapAcbsAutoCalc;
    gRobCoSnapMasterAcbsPcLevelMult := gRobCoSnapAcbsPcLevelMult;
    gRobCoSnapMasterAcbsEssential := gRobCoSnapAcbsEssential;
    gRobCoSnapMasterAcbsLevel := gRobCoSnapAcbsLevel;
    gRobCoSnapMasterAcbsCalcMin := gRobCoSnapAcbsCalcMin;
    gRobCoSnapMasterAcbsCalcMax := gRobCoSnapAcbsCalcMax;
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'ACBS') then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 16;
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

  if not RobCoSnapshotUseItmGate then

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

procedure RobCoApplyAcbsPatchDiffIfItmGate(e, master: IInterface);

var

  pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax: string;

  mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax: string;

begin

  if not RobCoSnapshotUseItmGate then

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
  if RobCoSnapRacePropertiesCount(e) = 0 then
    Exit;
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

  gNpcPatchSkin := '';

  gNpcPatchPowerArmorStand := '';

  gNpcPatchXpValueOffset := '';

end;

//============================================================================
procedure RobCoSnapInitRacePatchOutput;
begin
  gNpcPatchFilterByRaces := 'none';
  gNpcPatchFilterByRacesExcluded := 'none';
  gNpcPatchFilterByKeywords := 'none';
  gNpcPatchFilterByKeywordsOr := 'none';
  gNpcPatchFilterByKeywordsExcluded := 'none';
  gNpcPatchChangeAVIFS := 'none';
  gNpcPatchKeywordsToAdd := 'none';
  gNpcPatchKeywordsToRemove := 'none';
  gNpcPatchSpellsToAdd := 'none';
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

    master := RobCoCompareBaselineRecord(e);

    masterPerks := ReadPerkRefs(master);

    masterSpells := ReadSpellRefs(master);

    masterChangeAvif := ReadChangeAVIFS(master);

  end;



  changeAvif := ReadChangeAVIFS(e);

  gNpcPatchChangeAVIFS := RobCoExportFieldIfChanged(e, changeAvif, masterChangeAvif);

  if Assigned(master) then
    RobCoApplyRefListDiffIfItmGate(e, ReadRaceSpellAndPerkRefs(e),
      ReadRaceSpellAndPerkRefs(master), gNpcPatchSpellsToAdd, spellsRem)
  else
    RobCoApplyRefListDiffIfItmGate(e, ReadRaceSpellAndPerkRefs(e), '',
      gNpcPatchSpellsToAdd, spellsRem);

  gNpcPatchFilterByRaces := RobCoPatchFilterFormIDRef(e);

  // Keywords on RACE lines are operations (keywordsToAdd/Remove), not filterByKeywords.
  gNpcPatchFilterByKeywords := 'none';

  RobCoApplyKeywordDiffIfItmGate(e, keywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

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

  master := RobCoCompareBaselineRecord(e);

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

    master := RobCoCompareBaselineRecord(e);

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

  RobCoApplyRefListDiffIfItmGate(e, perks, masterPerks, gNpcPatchPerksToAdd, perksRem);

  RobCoApplyRefListDiffIfItmGate(e, spells, masterSpells, gNpcPatchSpellsToAdd, spellsRem);

  RobCoApplyRefListDiffIfItmGate(e, factions, masterFactions, gNpcPatchFactionsToAdd, factionsRem);

  RobCoApplyRefListDiffIfItmGate(e, inventory, masterInventory, gNpcPatchObjectsToAdd, objectsRem);

  gNpcPatchFactionsToRemove := NpcStripRankSuffixFromRefList(factionsRem);

  gNpcPatchObjectsToRemove := NpcStripRankSuffixFromRefList(objectsRem);



  gNpcPatchFilterByNpcs := RobCoPatchFilterFormIDRef(e);

  RobCoApplyKeywordDiffIfItmGate(e, keywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

  gNpcPatchFullName := RobCoExportFieldIfChanged(e, fullNameVal, masterFullName);

  if (deathItemVal = '') and (masterDeathItem <> '') then
    gNpcPatchDeathItem := 'null'
  else
    gNpcPatchDeathItem := RobCoExportFieldIfChanged(e, deathItemVal, masterDeathItem);

  gNpcPatchRace := RobCoExportFieldIfChanged(e, raceRef, masterRace);

  gNpcPatchClassOp := RobCoExportFieldIfChanged(e, classRef, masterClass);

  if Assigned(master) then begin
    if RobCoSnapshotUseItmGate then
      RobCoApplyAcbsPatchDiffIfItmGate(e, master)
    else
      ReadACBSFields(e);
  end else
    ReadACBSFields(e);

  if Assigned(master) then begin
    gNpcPatchSkin := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(ReadNpcSkinRef(e)),
      RobCoNoneIfEmpty(ReadNpcSkinRef(master)));
    gNpcPatchPowerArmorStand := RobCoExportFieldIfChanged(e,
      RobCoNoneIfEmpty(ReadNpcPowerArmorStandRef(e)),
      RobCoNoneIfEmpty(ReadNpcPowerArmorStandRef(master)));
    gNpcPatchXpValueOffset := RobCoNpcXpValueOffsetExportVal(ReadNpcXpValueOffset(e),
      ReadNpcXpValueOffset(master));
  end;

end;



//============================================================================

function BuildRobCoNPCLine: string;

begin

  Result := '';

  Result := RobCoAppendPatchField(Result, 'filterByNpcs', gNpcPatchFilterByNpcs);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByNpcsExcluded', gNpcPatchFilterByNpcsExcluded);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByRaces', gNpcPatchFilterByRaces);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByRacesExcluded', gNpcPatchFilterByRacesExcluded);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywords', gNpcPatchFilterByKeywords);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsOr', gNpcPatchFilterByKeywordsOr);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gNpcPatchFilterByKeywordsExcluded);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByFactions', gNpcPatchFilterByFactions);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByFactionsOr', gNpcPatchFilterByFactionsOr);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByFactionsExcluded', gNpcPatchFilterByFactionsExcluded);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByClass', gNpcPatchFilterByClass);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByGender', gNpcPatchFilterByGender);

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

  Result := RobCoAppendField(Result, 'skin', gNpcPatchSkin, False);

  Result := RobCoAppendField(Result, 'powerArmorStand', gNpcPatchPowerArmorStand, False);

  if not RobCoSnapshotUseItmGate then
    Result := RobCoAppendNumericField(Result, 'xpValueOffset', gNpcPatchXpValueOffset)
  else if gNpcPatchXpValueOffset <> '' then
    Result := RobCoAppendNumericField(Result, 'xpValueOffset', gNpcPatchXpValueOffset);

end;



//============================================================================

function BuildRobCoRACELine: string;

begin

  Result := '';

  Result := RobCoAppendPatchField(Result, 'filterByRaces', gNpcPatchFilterByRaces);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByRacesExcluded', gNpcPatchFilterByRacesExcluded);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywords', gNpcPatchFilterByKeywords);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsOr', gNpcPatchFilterByKeywordsOr);

  Result := RobCoAppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gNpcPatchFilterByKeywordsExcluded);

  Result := RobCoAppendField(Result, 'changeAVIFS', gNpcPatchChangeAVIFS, True);

  Result := RobCoAppendField(Result, 'keywordsToAdd', gNpcPatchKeywordsToAdd, True);

  Result := RobCoAppendField(Result, 'keywordsToRemove', gNpcPatchKeywordsToRemove, True);

  Result := RobCoAppendField(Result, 'spellsToAdd', gNpcPatchSpellsToAdd, True);

end;



//============================================================================
// Subgraph conflict gates, master cache, gated scratch reads
//============================================================================

function RobCoSnapKeywordsSubgraphConflictFree(e, master: IInterface): boolean;
var
  kwE, kwM: IInterface;
  key: string;
begin
  key := RobCoSnapConflictProbeCacheKey(e, master, 'kw');
  if RobCoSnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  kwE := RobCoGetKeywordsElement(e);
  kwM := RobCoGetKeywordsElement(master);
  Result := RobCoSubElementConflictFree(kwE, kwM);
  RobCoSnapConflictProbeCachePut(key, Result);
end;

//============================================================================
function RobCoSnapApprKwSubgraphConflictFree(e, master: IInterface): boolean;
var
  aE, aM: IInterface;
  key: string;
begin
  key := RobCoSnapConflictProbeCacheKey(e, master, 'apprkw');
  if RobCoSnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  aE := RobCoGetApprElement(e);
  aM := RobCoGetApprElement(master);
  Result := RobCoSubElementConflictFree(aE, aM);
  RobCoSnapConflictProbeCachePut(key, Result);
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
  if (RobCoSnapRacePropertiesCount(e) = 0) then begin
    if RobCoSnapRacePropertiesCount(master) = 0 then begin
      Result := True;
      Exit;
    end;
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
function RobCoSnapCacheCobjWorkbench(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'cobjbench');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadWorkbenchKeywordRef(master);
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
  if (gRobCoSnapRaceSubgraphMask and 1) <> 0 then begin
    gRobCoSnapKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapMasterKeywords := gRobCoSnapKeywords;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and $100) <> 0 then begin
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    Exit;
  end;
  if RobCoSnapKeywordsSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 1;
    gRobCoSnapKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapMasterKeywords := gRobCoSnapKeywords;
  end else begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $100;
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
  if (gRobCoSnapRaceSubgraphMask and 2) <> 0 then begin
    gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterPerks := gRobCoSnapPerks;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and $200) <> 0 then begin
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Perks') then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 2;
    gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterPerks := gRobCoSnapPerks;
  end else begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $200;
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
  if (gRobCoSnapRaceSubgraphMask and 4) <> 0 then begin
    gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := gRobCoSnapSpells;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and $400) <> 0 then begin
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    Exit;
  end;
  if RobCoSnapSpellsSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 4;
    gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := gRobCoSnapSpells;
  end else begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $400;
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
  if (gRobCoSnapRaceSubgraphMask and 8) <> 0 then begin
    gRobCoSnapChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapMasterChangeAvif := gRobCoSnapChangeAvif;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and $800) <> 0 then begin
    gRobCoSnapChangeAvif := RobCoSnapCacheRecordChangeAvif(e);
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    Exit;
  end;
  if RobCoSnapAvifSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 8;
    gRobCoSnapChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapMasterChangeAvif := gRobCoSnapChangeAvif;
  end else begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $800;
    gRobCoSnapChangeAvif := RobCoSnapCacheRecordChangeAvif(e);
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
  end;
end;

//============================================================================
procedure RobCoSnapStashRaceKeywords(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := '';
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 1;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and 1) <> 0 then begin
    gRobCoSnapKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapMasterKeywords := gRobCoSnapKeywords;
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 1;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and $100) <> 0 then begin
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 1;
    Exit;
  end;
  if RobCoSnapKeywordsSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 1;
    gRobCoSnapKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapMasterKeywords := gRobCoSnapKeywords;
  end else begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $100;
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
  end;
  gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 1;
end;

//============================================================================
procedure RobCoSnapStashRacePerks(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := '';
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 2;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and 2) <> 0 then begin
    gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterPerks := gRobCoSnapPerks;
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 2;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and $200) <> 0 then begin
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 2;
    Exit;
  end;
  if (RobCoSnapRaceNamedListContainerCount(e, 'Perks') = 0) then begin
    if RobCoSnapRaceNamedListContainerCount(gRobCoSnapMaster, 'Perks') = 0 then begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 2;
      gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
      gRobCoSnapMasterPerks := gRobCoSnapPerks;
    end else begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $200;
      gRobCoSnapPerks := ReadPerkRefs(e);
      gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    end;
  end else if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Perks') then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 2;
    gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterPerks := gRobCoSnapPerks;
  end else begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $200;
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
  end;
  gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 2;
end;

//============================================================================
procedure RobCoSnapStashRaceSpells(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := '';
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 4;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and 4) <> 0 then begin
    gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := gRobCoSnapSpells;
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 4;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and $400) <> 0 then begin
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 4;
    Exit;
  end;
  if (RobCoSnapRaceSpellsFootprintCount(e) = 0) then begin
    if RobCoSnapRaceSpellsFootprintCount(gRobCoSnapMaster) = 0 then begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 4;
      gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
      gRobCoSnapMasterSpells := gRobCoSnapSpells;
    end else begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $400;
      gRobCoSnapSpells := ReadSpellRefs(e);
      gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    end;
  end else if RobCoSnapSpellsSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 4;
    gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := gRobCoSnapSpells;
  end else begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $400;
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
  end;
  gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 4;
end;

//============================================================================
procedure RobCoSnapStashRaceAvif(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapChangeAvif := ReadChangeAVIFS(e);
    gRobCoSnapMasterChangeAvif := 'none';
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 8;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and 8) <> 0 then begin
    gRobCoSnapChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapMasterChangeAvif := gRobCoSnapChangeAvif;
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 8;
    Exit;
  end;
  if (gRobCoSnapRaceSubgraphMask and $800) <> 0 then begin
    gRobCoSnapChangeAvif := RobCoSnapCacheRecordChangeAvif(e);
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 8;
    Exit;
  end;
  if RobCoSnapAvifSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 8;
    gRobCoSnapChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapMasterChangeAvif := gRobCoSnapChangeAvif;
  end else begin
    gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $800;
    gRobCoSnapChangeAvif := RobCoSnapCacheRecordChangeAvif(e);
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
  end;
  gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 8;
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
    gRobCoSnapApprKw := RobCoEffectiveApprKeywordRefs(e);
    gRobCoSnapMasterApprKw := '';
    Exit;
  end;
  if RobCoSnapApprKwSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapApprKw := RobCoEffectiveApprKeywordRefs(gRobCoSnapMaster);
    gRobCoSnapMasterApprKw := gRobCoSnapApprKw;
  end else begin
    gRobCoSnapApprKw := RobCoEffectiveApprKeywordRefs(e);
    gRobCoSnapMasterApprKw := RobCoEffectiveApprKeywordRefs(gRobCoSnapMaster);
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
  gRobCoSnapNpcSubgraphMask := 0;
end;

//============================================================================
procedure RobCoSnapStashNpcKeywords(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := '';
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 1;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and 1) <> 0 then begin
    gRobCoSnapKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapMasterKeywords := gRobCoSnapKeywords;
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 1;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and $100) <> 0 then begin
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 1;
    Exit;
  end;
  if RobCoSnapKeywordsSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 1;
    gRobCoSnapKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapMasterKeywords := gRobCoSnapKeywords;
  end else begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $100;
    gRobCoSnapKeywords := RobCoReadKeywordRefsFromElement(e);
    gRobCoSnapMasterKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 1;
end;

//============================================================================
procedure RobCoSnapStashNpcPerks(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := '';
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 2;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and 2) <> 0 then begin
    gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterPerks := gRobCoSnapPerks;
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 2;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and $200) <> 0 then begin
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 2;
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Perks') then begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 2;
    gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterPerks := gRobCoSnapPerks;
  end else begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $200;
    gRobCoSnapPerks := ReadPerkRefs(e);
    gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 2;
end;

//============================================================================
procedure RobCoSnapStashNpcSpells(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := '';
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 4;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and 4) <> 0 then begin
    gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := gRobCoSnapSpells;
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 4;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and $400) <> 0 then begin
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 4;
    Exit;
  end;
  if RobCoSnapSpellsSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 4;
    gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := gRobCoSnapSpells;
  end else begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $400;
    gRobCoSnapSpells := ReadSpellRefs(e);
    gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 4;
end;

//============================================================================
procedure RobCoSnapStashNpcAcbs(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    ReadACBSFieldStrings(e, gRobCoSnapAcbsAutoCalc, gRobCoSnapAcbsPcLevelMult, gRobCoSnapAcbsEssential,
      gRobCoSnapAcbsLevel, gRobCoSnapAcbsCalcMin, gRobCoSnapAcbsCalcMax);
    gRobCoSnapMasterAcbsAutoCalc := '';
    gRobCoSnapMasterAcbsPcLevelMult := '';
    gRobCoSnapMasterAcbsEssential := '';
    gRobCoSnapMasterAcbsLevel := '';
    gRobCoSnapMasterAcbsCalcMin := '';
    gRobCoSnapMasterAcbsCalcMax := '';
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 8;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and 8) <> 0 then begin
    ReadACBSFieldStrings(e, gRobCoSnapAcbsAutoCalc, gRobCoSnapAcbsPcLevelMult, gRobCoSnapAcbsEssential,
      gRobCoSnapAcbsLevel, gRobCoSnapAcbsCalcMin, gRobCoSnapAcbsCalcMax);
    gRobCoSnapMasterAcbsAutoCalc := gRobCoSnapAcbsAutoCalc;
    gRobCoSnapMasterAcbsPcLevelMult := gRobCoSnapAcbsPcLevelMult;
    gRobCoSnapMasterAcbsEssential := gRobCoSnapAcbsEssential;
    gRobCoSnapMasterAcbsLevel := gRobCoSnapAcbsLevel;
    gRobCoSnapMasterAcbsCalcMin := gRobCoSnapAcbsCalcMin;
    gRobCoSnapMasterAcbsCalcMax := gRobCoSnapAcbsCalcMax;
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 8;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and $800) <> 0 then begin
    ReadACBSFieldStrings(e, gRobCoSnapAcbsAutoCalc, gRobCoSnapAcbsPcLevelMult, gRobCoSnapAcbsEssential,
      gRobCoSnapAcbsLevel, gRobCoSnapAcbsCalcMin, gRobCoSnapAcbsCalcMax);
    ReadACBSFieldStrings(gRobCoSnapMaster, gRobCoSnapMasterAcbsAutoCalc, gRobCoSnapMasterAcbsPcLevelMult,
      gRobCoSnapMasterAcbsEssential, gRobCoSnapMasterAcbsLevel, gRobCoSnapMasterAcbsCalcMin,
      gRobCoSnapMasterAcbsCalcMax);
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 8;
    Exit;
  end;
  ReadACBSFieldStrings(e, gRobCoSnapAcbsAutoCalc, gRobCoSnapAcbsPcLevelMult, gRobCoSnapAcbsEssential,
    gRobCoSnapAcbsLevel, gRobCoSnapAcbsCalcMin, gRobCoSnapAcbsCalcMax);
  gRobCoSnapMasterAcbsAutoCalc := '';
  gRobCoSnapMasterAcbsPcLevelMult := '';
  gRobCoSnapMasterAcbsEssential := '';
  gRobCoSnapMasterAcbsLevel := '';
  gRobCoSnapMasterAcbsCalcMin := '';
  gRobCoSnapMasterAcbsCalcMax := '';
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'ACBS') then begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 8;
    gRobCoSnapMasterAcbsAutoCalc := gRobCoSnapAcbsAutoCalc;
    gRobCoSnapMasterAcbsPcLevelMult := gRobCoSnapAcbsPcLevelMult;
    gRobCoSnapMasterAcbsEssential := gRobCoSnapAcbsEssential;
    gRobCoSnapMasterAcbsLevel := gRobCoSnapAcbsLevel;
    gRobCoSnapMasterAcbsCalcMin := gRobCoSnapAcbsCalcMin;
    gRobCoSnapMasterAcbsCalcMax := gRobCoSnapAcbsCalcMax;
  end else begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $800;
    ReadACBSFieldStrings(gRobCoSnapMaster, gRobCoSnapMasterAcbsAutoCalc, gRobCoSnapMasterAcbsPcLevelMult,
      gRobCoSnapMasterAcbsEssential, gRobCoSnapMasterAcbsLevel, gRobCoSnapMasterAcbsCalcMin,
      gRobCoSnapMasterAcbsCalcMax);
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 8;
end;

//============================================================================
procedure RobCoSnapStashNpcAvif(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapChangeAvif := ReadChangeAVIFS(e);
    gRobCoSnapMasterChangeAvif := 'none';
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 16;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and 16) <> 0 then begin
    gRobCoSnapChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapMasterChangeAvif := gRobCoSnapChangeAvif;
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 16;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and $1000) <> 0 then begin
    gRobCoSnapChangeAvif := RobCoSnapCacheRecordChangeAvif(e);
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 16;
    Exit;
  end;
  if RobCoSnapAvifSubgraphConflictFree(e, gRobCoSnapMaster) then begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 16;
    gRobCoSnapChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapMasterChangeAvif := gRobCoSnapChangeAvif;
  end else begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $1000;
    gRobCoSnapChangeAvif := RobCoSnapCacheRecordChangeAvif(e);
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 16;
end;

//============================================================================
procedure RobCoSnapStashNpcFactions(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapFactions := ReadFactionRefs(e);
    gRobCoSnapMasterFactions := '';
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 32;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and 32) <> 0 then begin
    gRobCoSnapFactions := RobCoSnapCacheFactions(gRobCoSnapMaster);
    gRobCoSnapMasterFactions := gRobCoSnapFactions;
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 32;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and $2000) <> 0 then begin
    gRobCoSnapFactions := ReadFactionRefs(e);
    gRobCoSnapMasterFactions := RobCoSnapCacheFactions(gRobCoSnapMaster);
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 32;
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Factions') then begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 32;
    gRobCoSnapFactions := RobCoSnapCacheFactions(gRobCoSnapMaster);
    gRobCoSnapMasterFactions := gRobCoSnapFactions;
  end else begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $2000;
    gRobCoSnapFactions := ReadFactionRefs(e);
    gRobCoSnapMasterFactions := RobCoSnapCacheFactions(gRobCoSnapMaster);
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 32;
end;

//============================================================================
procedure RobCoSnapStashNpcInventory(e: IInterface);
begin
  if not Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapInventory := ReadInventoryRefs(e);
    gRobCoSnapMasterInventory := '';
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 64;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and 64) <> 0 then begin
    gRobCoSnapInventory := RobCoSnapCacheInventory(gRobCoSnapMaster);
    gRobCoSnapMasterInventory := gRobCoSnapInventory;
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 64;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and $4000) <> 0 then begin
    gRobCoSnapInventory := ReadInventoryRefs(e);
    gRobCoSnapMasterInventory := RobCoSnapCacheInventory(gRobCoSnapMaster);
    gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 64;
    Exit;
  end;
  if RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Items') then begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 64;
    gRobCoSnapInventory := RobCoSnapCacheInventory(gRobCoSnapMaster);
    gRobCoSnapMasterInventory := gRobCoSnapInventory;
  end else begin
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $4000;
    gRobCoSnapInventory := ReadInventoryRefs(e);
    gRobCoSnapMasterInventory := RobCoSnapCacheInventory(gRobCoSnapMaster);
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 64;
end;

//============================================================================
procedure RobCoSnapStashNpcScalars(e: IInterface);
begin
  gRobCoSnapFullName := RobCoReadFullName(e);
  gRobCoSnapDeathItem := ReadDeathItemRef(e);
  gRobCoSnapRaceRef := RobCoReadFormLinkRef(e, 'RNAM');
  gRobCoSnapClassRef := RobCoReadFormLinkRef(e, 'CNAM');
  gRobCoSnapSkin := ReadNpcSkinRef(e);
  gRobCoSnapPowerArmorStand := ReadNpcPowerArmorStandRef(e);
  gRobCoSnapXpValueOffset := ReadNpcXpValueOffset(e);
  gRobCoSnapMasterFullName := '';
  gRobCoSnapMasterDeathItem := '';
  gRobCoSnapMasterRaceRef := '';
  gRobCoSnapMasterClassRef := '';
  gRobCoSnapMasterSkin := '';
  gRobCoSnapMasterPowerArmorStand := '';
  gRobCoSnapMasterXpValueOffset := '';
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterFullName := RobCoSnapCacheNpcMasterFullName(gRobCoSnapMaster);
    gRobCoSnapMasterDeathItem := RobCoSnapCacheNpcMasterDeathItem(gRobCoSnapMaster);
    gRobCoSnapMasterRaceRef := RobCoReadFormLinkRef(gRobCoSnapMaster, 'RNAM');
    gRobCoSnapMasterClassRef := RobCoReadFormLinkRef(gRobCoSnapMaster, 'CNAM');
    gRobCoSnapMasterSkin := RobCoSnapCacheNpcMasterSkin(gRobCoSnapMaster);
    gRobCoSnapMasterPowerArmorStand := RobCoSnapCacheNpcMasterPowerArmorStand(gRobCoSnapMaster);
    gRobCoSnapMasterXpValueOffset := RobCoSnapCacheNpcMasterXpValueOffset(gRobCoSnapMaster);
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
function RobCoSnapProbeRaceExportSubgraphs(e, master: IInterface): boolean;
begin
  Result := False;
  if (gRobCoSnapRaceSubgraphMask and $100) <> 0 then
    Exit;
  if (gRobCoSnapRaceSubgraphMask and 1) = 0 then begin
    if (gRobCoSnapRaceStashMask and 1) <> 0 then begin
      if RobCoRefListDiffUnchangedVsMaster(gRobCoSnapKeywords, gRobCoSnapMasterKeywords) then begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 1;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 1;
      end else begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $100;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $100;
        Exit;
      end;
    end else if RobCoSnapKeywordsSubgraphConflictFree(e, master) then begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 1;
      gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 1;
    end else begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $100;
      gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $100;
      Exit;
    end;
  end;
  if (gRobCoSnapRaceSubgraphMask and $200) <> 0 then
    Exit;
  if (gRobCoSnapRaceSubgraphMask and 2) = 0 then begin
    if (gRobCoSnapRaceStashMask and 2) <> 0 then begin
      if RobCoRefListDiffUnchangedVsMaster(
        RobCoJoinTwoCommaLists(gRobCoSnapPerks, gRobCoSnapSpells),
        RobCoJoinTwoCommaLists(gRobCoSnapMasterPerks, gRobCoSnapMasterSpells)) then begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 2;
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 4;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 2;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 4;
      end else begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $200;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $200;
        Exit;
      end;
    end else if (RobCoSnapRaceNamedListContainerCount(e, 'Perks') = 0) then begin
      if RobCoSnapRaceNamedListContainerCount(master, 'Perks') = 0 then begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 2;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 2;
      end else begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $200;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $200;
        Exit;
      end;
    end else if RobCoSubElementConflictFreeByName(e, master, 'Perks') then begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 2;
      gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 2;
    end else begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $200;
      gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $200;
      Exit;
    end;
  end;
  if (gRobCoSnapRaceSubgraphMask and $400) <> 0 then
    Exit;
  if (gRobCoSnapRaceSubgraphMask and 4) = 0 then begin
    if (RobCoSnapRaceSpellsFootprintCount(e) = 0) then begin
      if RobCoSnapRaceSpellsFootprintCount(master) = 0 then begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 4;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 4;
      end else begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $400;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $400;
        Exit;
      end;
    end else if RobCoSnapSpellsSubgraphConflictFree(e, master) then begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 4;
      gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 4;
    end else begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $400;
      gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $400;
      Exit;
    end;
  end;
  if (gRobCoSnapRaceSubgraphMask and $800) <> 0 then
    Exit;
  if (gRobCoSnapRaceSubgraphMask and 8) = 0 then begin
    if (gRobCoSnapRaceStashMask and 8) <> 0 then begin
      if gRobCoSnapChangeAvif = gRobCoSnapMasterChangeAvif then begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 8;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 16;
      end else begin
        gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $800;
        gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $1000;
        Exit;
      end;
    end else if RobCoSnapAvifSubgraphConflictFree(e, master) then begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or 8;
      gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or 16;
    end else begin
      gRobCoSnapRaceSubgraphMask := gRobCoSnapRaceSubgraphMask or $800;
      gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or $1000;
      Exit;
    end;
  end;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipNpcRaceSubgraph(e, master: IInterface): boolean;
begin
  Result := RobCoSnapProbeRaceExportSubgraphs(e, master);
end;

//============================================================================
procedure RobCoSnapProbeNpcItmSubgraphBit(e, master: IInterface; conflictFreeBit, conflictBit: integer;
  conflictFree: boolean);
begin
  if (gRobCoSnapNpcSubgraphMask and conflictFreeBit) <> 0 then
    Exit;
  if (gRobCoSnapNpcSubgraphMask and conflictBit) <> 0 then
    Exit;
  if conflictFree then
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or conflictFreeBit
  else
    gRobCoSnapNpcSubgraphMask := gRobCoSnapNpcSubgraphMask or conflictBit;
end;

//============================================================================
procedure RobCoSnapProbeNpcItmSubgraphs(e, master: IInterface);
begin
  if (gRobCoSnapNpcSubgraphMask and 1) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $100) = 0 then
      RobCoSnapProbeNpcItmSubgraphBit(e, master, 1, $100,
        RobCoSnapKeywordsSubgraphConflictFree(e, master));
  end;
  if (gRobCoSnapNpcSubgraphMask and 2) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $200) = 0 then
      RobCoSnapProbeNpcItmSubgraphBit(e, master, 2, $200,
        RobCoSubElementConflictFreeByName(e, master, 'Perks'));
  end;
  if (gRobCoSnapNpcSubgraphMask and 4) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $400) = 0 then
      RobCoSnapProbeNpcItmSubgraphBit(e, master, 4, $400,
        RobCoSnapSpellsSubgraphConflictFree(e, master));
  end;
  if (gRobCoSnapNpcSubgraphMask and 16) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $1000) = 0 then
      RobCoSnapProbeNpcItmSubgraphBit(e, master, 16, $1000,
        RobCoSnapAvifSubgraphConflictFree(e, master));
  end;
  if (gRobCoSnapNpcSubgraphMask and 8) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $800) = 0 then
      RobCoSnapProbeNpcItmSubgraphBit(e, master, 8, $800,
        RobCoSubElementConflictFreeByName(e, master, 'ACBS'));
  end;
  if (gRobCoSnapNpcSubgraphMask and 32) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $2000) = 0 then
      RobCoSnapProbeNpcItmSubgraphBit(e, master, 32, $2000,
        RobCoSubElementConflictFreeByName(e, master, 'Factions'));
  end;
  if (gRobCoSnapNpcSubgraphMask and 64) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $4000) = 0 then
      RobCoSnapProbeNpcItmSubgraphBit(e, master, 64, $4000,
        RobCoSubElementConflictFreeByName(e, master, 'Items'));
  end;
end;

//============================================================================
function RobCoSnapNpcCachedListItmUnchanged(conflictFreeBit, conflictBit: integer;
  const pluginList, masterList: string): boolean;
begin
  Result := False;
  if (gRobCoSnapNpcSubgraphMask and conflictFreeBit) <> 0 then begin
    Result := True;
    Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and conflictBit) <> 0 then begin
    Result := RobCoRefListDiffUnchangedVsMaster(pluginList, masterList);
    Exit;
  end;
end;

//============================================================================
function RobCoSnapCacheRecordFactions(e: IInterface): string;
var
  key: string;
begin
  key := RobCoSnapRecordCacheKey(e, 'factions');
  if RobCoSnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadFactionRefs(e);
  RobCoSnapRecordCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheRecordInventory(e: IInterface): string;
var
  key: string;
begin
  key := RobCoSnapRecordCacheKey(e, 'inventory');
  if RobCoSnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadInventoryRefs(e);
  RobCoSnapRecordCachePut(key, Result);
end;

//============================================================================
procedure RobCoSnapReadRaceBilateralFieldsIfNeeded(e: IInterface);
begin
  if (gRobCoSnapRaceStashMask and 1) = 0 then
    RobCoSnapStashRaceKeywords(e);
  if (gRobCoSnapRaceStashMask and 2) = 0 then
    RobCoSnapStashRacePerks(e);
  if (gRobCoSnapRaceStashMask and 4) = 0 then
    RobCoSnapStashRaceSpells(e);
  if (gRobCoSnapRaceStashMask and 8) = 0 then
    RobCoSnapStashRaceAvif(e);
end;

//============================================================================
procedure RobCoSnapApplyRaceConflictFreeMasterStash;
begin
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if (gRobCoSnapRaceSubgraphMask and 1) <> 0 then begin
    gRobCoSnapKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster);
    gRobCoSnapMasterKeywords := gRobCoSnapKeywords;
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 1;
  end;
  if (gRobCoSnapRaceSubgraphMask and 2) <> 0 then begin
    gRobCoSnapPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterPerks := gRobCoSnapPerks;
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 2;
  end;
  if (gRobCoSnapRaceSubgraphMask and 4) <> 0 then begin
    gRobCoSnapSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := gRobCoSnapSpells;
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 4;
  end;
  if (gRobCoSnapRaceSubgraphMask and 8) <> 0 then begin
    gRobCoSnapChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster);
    gRobCoSnapMasterChangeAvif := gRobCoSnapChangeAvif;
    gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 8;
  end;
end;

//============================================================================
function RobCoSnapRaceKeywordListsItmUnchanged(e, master: IInterface): boolean;
begin
  if (gRobCoSnapRaceSubgraphMask and 1) <> 0 then begin
    Result := True;
    Exit;
  end;
  Result := RobCoRefListDiffUnchangedVsMaster(RobCoSnapCacheRecordKeywords(e),
    RobCoSnapCacheKeywords(master));
end;

//============================================================================
function RobCoSnapRaceCombinedPerksSpellsListsItmUnchanged(e, master: IInterface): boolean;
var
  pluginPerks, pluginSpells, masterPerks, masterSpells: string;
  masterSpellCount: integer;
  perksConflictFree, spellsConflictFree: boolean;
begin
  Result := False;
  if not Assigned(master) then
    Exit;
  perksConflictFree := False;
  if (gRobCoSnapRaceSubgraphMask and 2) <> 0 then
    perksConflictFree := True;
  spellsConflictFree := False;
  if (gRobCoSnapRaceSubgraphMask and 4) <> 0 then
    spellsConflictFree := True;
  masterPerks := RobCoSnapCachePerks(master);
  if perksConflictFree then
    pluginPerks := masterPerks
  else begin
    if RobCoSnapRaceNamedListContainerCount(e, 'Perks') <>
      RobCoSnapRaceNamedListContainerCount(master, 'Perks') then
      Exit;
    pluginPerks := RobCoSnapCacheRecordPerks(e);
    if RobCoCommaListRefCount(pluginPerks) <> RobCoCommaListRefCount(masterPerks) then
      Exit;
    if not RobCoRefListDiffUnchangedVsMaster(pluginPerks, masterPerks) then
      Exit;
  end;
  masterSpells := RobCoSnapCacheSpells(master);
  masterSpellCount := RobCoCommaListRefCount(masterSpells);
  if spellsConflictFree then
    pluginSpells := masterSpells
  else begin
    if RobCoSnapRaceSpellsFootprintCount(e) <>
      RobCoSnapRaceSpellsFootprintCount(master) then
      Exit;
    pluginSpells := RobCoSnapCacheRecordSpells(e);
    if RobCoCommaListRefCount(pluginSpells) <> masterSpellCount then
      Exit;
    if masterSpellCount = 0 then begin
      Result := True;
      Exit;
    end;
    if not RobCoRefListDiffUnchangedVsMaster(pluginSpells, masterSpells) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
function RobCoSnapCacheRecordKeywords(e: IInterface): string;
var
  key: string;
begin
  key := RobCoSnapRecordCacheKey(e, 'keywords');
  if RobCoSnapRecordCacheLookup(key, Result) then
    Exit;
  Result := RobCoReadKeywordRefsFromElement(e);
  RobCoSnapRecordCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheRecordPerks(e: IInterface): string;
var
  key: string;
begin
  key := RobCoSnapRecordCacheKey(e, 'perks');
  if RobCoSnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadPerkRefs(e);
  RobCoSnapRecordCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheRecordSpells(e: IInterface): string;
var
  key: string;
begin
  key := RobCoSnapRecordCacheKey(e, 'spells');
  if RobCoSnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadSpellRefs(e);
  RobCoSnapRecordCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheRecordChangeAvif(e: IInterface): string;
var
  key: string;
begin
  key := RobCoSnapRecordCacheKey(e, 'avif');
  if RobCoSnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadChangeAVIFS(e);
  RobCoSnapRecordCachePut(key, Result);
end;

//============================================================================
function RobCoSnapRacePropertiesCount(e: IInterface): integer;
var
  props: IInterface;
begin
  Result := 0;
  if not Assigned(e) then
    Exit;
  props := ElementByPath(e, 'Properties');
  if Assigned(props) then
    Result := Result + ElementCount(props);
  props := ElementByPath(e, 'Actor Data\Properties');
  if Assigned(props) then
    Result := Result + ElementCount(props);
end;

//============================================================================
function RobCoSnapRaceNamedListContainerCount(e: IInterface; const name: string): integer;
var
  container: IInterface;
begin
  Result := 0;
  if not Assigned(e) then
    Exit;
  container := ElementByName(e, name);
  if Assigned(container) then
    Result := ElementCount(container);
end;

//============================================================================
function RobCoSnapRaceSpellsFootprintCount(e: IInterface): integer;
var
  ae, splo: IInterface;
begin
  Result := 0;
  if not Assigned(e) then
    Exit;
  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin
    splo := ElementBySignature(e, 'SPLO');
    if Assigned(splo) then
      Result := ElementCount(splo);
    Exit;
  end;
  ae := ElementByName(e, 'Actor Effects');
  if Assigned(ae) then
    Result := Result + ElementCount(ae);
  splo := ElementBySignature(e, 'SPLO');
  if Assigned(splo) then
    Result := Result + ElementCount(splo);
end;

//============================================================================
function RobCoSnapCacheNpcMasterFullName(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'npc.fullname');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := RobCoReadFullName(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheNpcMasterDeathItem(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'npc.deathitem');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadDeathItemRef(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheNpcMasterSkin(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'npc.skin');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadNpcSkinRef(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheNpcMasterPowerArmorStand(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'npc.pastand');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadNpcPowerArmorStandRef(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
function RobCoSnapCacheNpcMasterXpValueOffset(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := RobCoSnapMasterCacheKey(master, 'npc.xpoffset');
  idx := RobCoSnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := RobCoSnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadNpcXpValueOffset(master);
  RobCoSnapMasterCachePut(key, Result);
end;

//============================================================================
procedure RobCoSnapReadRaceItmCompareFieldAvif(e: IInterface);
begin
  gRobCoSnapChangeAvif := RobCoSnapCacheRecordChangeAvif(e);
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterChangeAvif := RobCoSnapCacheChangeAvif(gRobCoSnapMaster)
  else
    gRobCoSnapMasterChangeAvif := '';
  gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 8;
end;

//============================================================================
procedure RobCoSnapReadRaceItmCompareFieldKeywords(e: IInterface);
begin
  gRobCoSnapKeywords := RobCoSnapCacheRecordKeywords(e);
  if Assigned(gRobCoSnapMaster) then
    gRobCoSnapMasterKeywords := RobCoSnapCacheKeywords(gRobCoSnapMaster)
  else
    gRobCoSnapMasterKeywords := '';
  gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 1;
end;

//============================================================================
procedure RobCoSnapReadRaceItmCompareFieldPerksSpells(e: IInterface);
begin
  gRobCoSnapPerks := RobCoSnapCacheRecordPerks(e);
  gRobCoSnapSpells := RobCoSnapCacheRecordSpells(e);
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterPerks := RobCoSnapCachePerks(gRobCoSnapMaster);
    gRobCoSnapMasterSpells := RobCoSnapCacheSpells(gRobCoSnapMaster);
  end else begin
    gRobCoSnapMasterPerks := '';
    gRobCoSnapMasterSpells := '';
  end;
  gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 2;
  gRobCoSnapRaceStashMask := gRobCoSnapRaceStashMask or 4;
end;

//============================================================================
procedure RobCoSnapFinishRaceItmCompareFields(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  if (gRobCoSnapRaceStashMask and 8) = 0 then
    RobCoSnapReadRaceItmCompareFieldAvif(e);
  if (gRobCoSnapRaceStashMask and 1) = 0 then
    RobCoSnapReadRaceItmCompareFieldKeywords(e);
  if (gRobCoSnapRaceStashMask and 2) = 0 then
    RobCoSnapReadRaceItmCompareFieldPerksSpells(e)
  else if (gRobCoSnapRaceStashMask and 4) = 0 then
    RobCoSnapReadRaceItmCompareFieldPerksSpells(e);
end;

//============================================================================
procedure RobCoSnapReadRaceItmCompareFields(e: IInterface);
begin
  RobCoSnapReadMasterIfAny(e);
  RobCoSnapReadRaceItmCompareFieldAvif(e);
  RobCoSnapReadRaceItmCompareFieldKeywords(e);
  RobCoSnapReadRaceItmCompareFieldPerksSpells(e);
end;

//============================================================================
function RobCoSnapTryReadRaceItmUnchanged(e: IInterface): boolean;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  RobCoSnapReadMasterIfAny(e);
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if RobCoSnapRacePropertiesCount(e) <> RobCoSnapRacePropertiesCount(gRobCoSnapMaster) then
    Exit;
  RobCoSnapReadRaceItmCompareFieldKeywords(e);
  if not RobCoRefListDiffUnchangedVsMaster(gRobCoSnapKeywords, gRobCoSnapMasterKeywords) then
    Exit;
  RobCoSnapReadRaceItmCompareFieldPerksSpells(e);
  if not RobCoRefListDiffUnchangedVsMaster(
    RobCoJoinTwoCommaLists(gRobCoSnapPerks, gRobCoSnapSpells),
    RobCoJoinTwoCommaLists(gRobCoSnapMasterPerks, gRobCoSnapMasterSpells)) then
    Exit;
  RobCoSnapReadRaceItmCompareFieldAvif(e);
  if gRobCoSnapChangeAvif <> gRobCoSnapMasterChangeAvif then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipRace(e: IInterface): boolean;
begin
  Result := RobCoSnapTryReadRaceItmUnchanged(e);
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipNpc(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  RobCoSnapReadMasterIfAny(e);
  master := gRobCoSnapMaster;
  if not Assigned(master) then
    Exit;
  gRobCoSnapFullName := RobCoReadFullName(e);
  gRobCoSnapDeathItem := ReadDeathItemRef(e);
  gRobCoSnapRaceRef := RobCoSnapCacheFormLinkRef(e, 'RNAM');
  gRobCoSnapClassRef := RobCoSnapCacheFormLinkRef(e, 'CNAM');
  gRobCoSnapSkin := ReadNpcSkinRef(e);
  gRobCoSnapPowerArmorStand := ReadNpcPowerArmorStandRef(e);
  gRobCoSnapXpValueOffset := ReadNpcXpValueOffset(e);
  gRobCoSnapMasterFullName := '';
  gRobCoSnapMasterDeathItem := '';
  gRobCoSnapMasterRaceRef := '';
  gRobCoSnapMasterClassRef := '';
  gRobCoSnapMasterSkin := '';
  gRobCoSnapMasterPowerArmorStand := '';
  gRobCoSnapMasterXpValueOffset := '';
  if Assigned(gRobCoSnapMaster) then begin
    gRobCoSnapMasterFullName := RobCoSnapCacheNpcMasterFullName(master);
    gRobCoSnapMasterDeathItem := RobCoSnapCacheNpcMasterDeathItem(master);
    gRobCoSnapMasterRaceRef := RobCoSnapCacheFormLinkRef(master, 'RNAM');
    gRobCoSnapMasterClassRef := RobCoSnapCacheFormLinkRef(master, 'CNAM');
    gRobCoSnapMasterSkin := RobCoSnapCacheNpcMasterSkin(master);
    gRobCoSnapMasterPowerArmorStand := RobCoSnapCacheNpcMasterPowerArmorStand(master);
    gRobCoSnapMasterXpValueOffset := RobCoSnapCacheNpcMasterXpValueOffset(master);
  end;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 128;
  if gRobCoSnapFullName <> gRobCoSnapMasterFullName then
    Exit;
  if gRobCoSnapDeathItem <> gRobCoSnapMasterDeathItem then
    Exit;
  if gRobCoSnapRaceRef <> gRobCoSnapMasterRaceRef then
    Exit;
  if gRobCoSnapClassRef <> gRobCoSnapMasterClassRef then
    Exit;
  if gRobCoSnapSkin <> gRobCoSnapMasterSkin then
    Exit;
  if gRobCoSnapPowerArmorStand <> gRobCoSnapMasterPowerArmorStand then
    Exit;
  if not RobCoNpcXpValueOffsetUnchanged(gRobCoSnapXpValueOffset, gRobCoSnapMasterXpValueOffset) then
    Exit;
  RobCoSnapProbeNpcItmSubgraphs(e, master);
  if not RobCoSnapNpcCachedListItmUnchanged(1, $100, RobCoSnapCacheRecordKeywords(e),
    RobCoSnapCacheKeywords(master)) then
    Exit;
  if not RobCoSnapNpcCachedListItmUnchanged(2, $200, RobCoSnapCacheRecordPerks(e),
    RobCoSnapCachePerks(master)) then
    Exit;
  if (gRobCoSnapNpcSubgraphMask and 8) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $800) <> 0 then begin
      ReadACBSFieldStrings(e, gRobCoSnapAcbsAutoCalc, gRobCoSnapAcbsPcLevelMult, gRobCoSnapAcbsEssential,
        gRobCoSnapAcbsLevel, gRobCoSnapAcbsCalcMin, gRobCoSnapAcbsCalcMax);
      ReadACBSFieldStrings(master, gRobCoSnapMasterAcbsAutoCalc, gRobCoSnapMasterAcbsPcLevelMult,
        gRobCoSnapMasterAcbsEssential, gRobCoSnapMasterAcbsLevel, gRobCoSnapMasterAcbsCalcMin,
        gRobCoSnapMasterAcbsCalcMax);
      gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 8;
      if not RobCoAcbsFieldsUnchangedFromScratch then
        Exit;
    end else
      Exit;
  end;
  if (gRobCoSnapNpcSubgraphMask and 16) = 0 then begin
    if (gRobCoSnapNpcSubgraphMask and $1000) <> 0 then begin
      if RobCoSnapCacheRecordChangeAvif(e) <> RobCoSnapCacheChangeAvif(master) then
        Exit;
    end else
      Exit;
  end;
  if not RobCoSnapNpcCachedListItmUnchanged(32, $2000, RobCoSnapCacheRecordFactions(e),
    RobCoSnapCacheFactions(master)) then
    Exit;
  if not RobCoSnapNpcCachedListItmUnchanged(64, $4000, RobCoSnapCacheRecordInventory(e),
    RobCoSnapCacheInventory(master)) then
    Exit;
  if not RobCoSnapNpcCachedListItmUnchanged(4, $400, RobCoSnapCacheRecordSpells(e),
    RobCoSnapCacheSpells(master)) then
    Exit;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 1;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 2;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 4;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 8;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 16;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 32;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 64;
  gRobCoSnapNpcStashMask := gRobCoSnapNpcStashMask or 128;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipAmmo(e: IInterface): boolean;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  if not RobCoAmmoFieldsUnchangedVsMaster(e) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipCobj(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := RobCoCompareBaselineRecord(e);
  if not Assigned(master) then
    Exit;
  if not RobCoSnapCobjCategoryKwSubgraphConflictFree(e, master) then
    Exit;
  if ReadWorkbenchKeywordRef(e) <> RobCoSnapCacheCobjWorkbench(master) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipArmo(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := RobCoCompareBaselineRecord(e);
  if not Assigned(master) then
    Exit;
  if not RobCoArmoFieldsUnchangedVsMaster(e) then
    Exit;
  if not RobCoArmoFo4ExtrasUnchanged(e, master) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipWeap(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  master := RobCoCompareBaselineRecord(e);
  if not Assigned(master) then
    Exit;
  if not RobCoWeapFieldsUnchangedVsMaster(e) then
    Exit;
  if not RobCoWeapFo4ExtrasUnchanged(e, master) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipAlch(e: IInterface): boolean;
var
  mgefsToAdd, mgefsToChange, mgefsToRemove: string;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
    Exit;
  if not RobCoRecordHasExternalMaster(e) then
    Exit;
  RobCoSnapReadMasterIfAny(e);
  if not Assigned(gRobCoSnapMaster) then
    Exit;
  if RobCoReadFullName(e) <> RobCoReadFullName(gRobCoSnapMaster) then
    Exit;
  if RobCoReadDataField(e, 'Weight') <> RobCoReadDataField(gRobCoSnapMaster, 'Weight') then
    Exit;
  if RobCoReadDataField(e, 'Value') <> RobCoReadDataField(gRobCoSnapMaster, 'Value') then
    Exit;
  if not RobCoSnapKeywordsSubgraphConflictFree(e, gRobCoSnapMaster) then
    Exit;
  if not RobCoSubElementConflictFreeByName(e, gRobCoSnapMaster, 'Effects') then
    Exit;
  RobCoSnapReadAlchMgefsToScratch(e);
  DiffAlchMgefs(gRobCoSnapMgefs, gRobCoSnapMasterMgefs,
    mgefsToAdd, mgefsToChange, mgefsToRemove);
  if mgefsToAdd <> 'none' then
    Exit;
  if mgefsToChange <> 'none' then
    Exit;
  if mgefsToRemove <> 'none' then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoSnapTryEarlyPregatherSkipOmod(e: IInterface): boolean;
begin
  Result := False;
  if not RobCoSnapshotUseItmGate then
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
procedure RobCoSnapRecordEarlyPregatherSkip(const exportFn: string);
begin
  // DEBUG_INJECT_PERFMON_COUNTER count.snap.early.pregather.skip 1
end;

//============================================================================
procedure RobCoReadRacePatchInputs(e: IInterface);
begin
  RobCoSnapReadRaceBilateralFieldsIfNeeded(e);
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

  if not RobCoRefListDiffUnchangedVsMaster(
    RobCoJoinTwoCommaLists(gRobCoSnapPerks, gRobCoSnapSpells),
    RobCoJoinTwoCommaLists(gRobCoSnapMasterPerks, gRobCoSnapMasterSpells)) then
    Exit;

  if gRobCoSnapChangeAvif <> gRobCoSnapMasterChangeAvif then

    Exit;

  Result := True;

end;



//============================================================================

function RobCoNpcFieldsUnchangedFromScratch(e: IInterface): boolean;

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

  if gRobCoSnapSkin <> gRobCoSnapMasterSkin then
    Exit;

  if gRobCoSnapPowerArmorStand <> gRobCoSnapMasterPowerArmorStand then
    Exit;

  if not RobCoNpcXpValueOffsetUnchanged(gRobCoSnapXpValueOffset, gRobCoSnapMasterXpValueOffset) then
    Exit;

  Result := True;

end;



//============================================================================

procedure GatherRacePatchDataFromScratch(e: IInterface);

var

  perksRem, spellsRem: string;

begin

  RobCoSnapInitRacePatchOutput;

  gNpcPatchChangeAVIFS := RobCoExportFieldIfChanged(e, gRobCoSnapChangeAvif, gRobCoSnapMasterChangeAvif);

  if Assigned(gRobCoSnapMaster) then begin
    RobCoApplyRefListDiffIfItmGate(e,
      RobCoJoinTwoCommaLists(gRobCoSnapPerks, gRobCoSnapSpells),
      RobCoJoinTwoCommaLists(gRobCoSnapMasterPerks, gRobCoSnapMasterSpells),
      gNpcPatchSpellsToAdd, spellsRem);
  end else begin
    if (gRobCoSnapPerks <> '') and (gRobCoSnapSpells <> '') then
      gNpcPatchSpellsToAdd := RobCoNoneIfEmpty(
        RobCoJoinTwoCommaLists(gRobCoSnapPerks, gRobCoSnapSpells))
    else if gRobCoSnapPerks <> '' then
      gNpcPatchSpellsToAdd := RobCoNoneIfEmpty(gRobCoSnapPerks)
    else
      gNpcPatchSpellsToAdd := RobCoNoneIfEmpty(gRobCoSnapSpells);
  end;

  gNpcPatchFilterByRaces := RobCoPatchFilterFormIDRef(e);

  RobCoApplyKeywordDiffIfItmGate(e, gRobCoSnapKeywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

end;



//============================================================================

procedure GatherNpcPatchDataFromScratch(e: IInterface);

var

  perksRem, spellsRem, factionsRem, objectsRem: string;

begin

  InitRobCoNPCPatchData;

  gNpcPatchChangeAVIFS := RobCoExportFieldIfChanged(e, gRobCoSnapChangeAvif, gRobCoSnapMasterChangeAvif);

  RobCoApplyRefListDiffIfItmGate(e, gRobCoSnapPerks, gRobCoSnapMasterPerks, gNpcPatchPerksToAdd, perksRem);

  RobCoApplyRefListDiffIfItmGate(e, gRobCoSnapSpells, gRobCoSnapMasterSpells, gNpcPatchSpellsToAdd, spellsRem);

  RobCoApplyRefListDiffIfItmGate(e, gRobCoSnapFactions, gRobCoSnapMasterFactions, gNpcPatchFactionsToAdd, factionsRem);

  RobCoApplyRefListDiffIfItmGate(e, gRobCoSnapInventory, gRobCoSnapMasterInventory, gNpcPatchObjectsToAdd, objectsRem);

  gNpcPatchFactionsToRemove := NpcStripRankSuffixFromRefList(factionsRem);

  gNpcPatchObjectsToRemove := NpcStripRankSuffixFromRefList(objectsRem);

  gNpcPatchFilterByNpcs := RobCoPatchFilterFormIDRef(e);

  RobCoApplyKeywordDiffIfItmGate(e, gRobCoSnapKeywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

  gNpcPatchFullName := RobCoExportFieldIfChanged(e, gRobCoSnapFullName, gRobCoSnapMasterFullName);

  if (gRobCoSnapDeathItem = '') and (gRobCoSnapMasterDeathItem <> '') then
    gNpcPatchDeathItem := 'null'
  else
    gNpcPatchDeathItem := RobCoExportFieldIfChanged(e, gRobCoSnapDeathItem, gRobCoSnapMasterDeathItem);

  gNpcPatchRace := RobCoExportFieldIfChanged(e, gRobCoSnapRaceRef, gRobCoSnapMasterRaceRef);

  gNpcPatchClassOp := RobCoExportFieldIfChanged(e, gRobCoSnapClassRef, gRobCoSnapMasterClassRef);

  gNpcPatchSkin := RobCoExportFieldIfChanged(e, RobCoNoneIfEmpty(gRobCoSnapSkin),
    RobCoNoneIfEmpty(gRobCoSnapMasterSkin));
  gNpcPatchPowerArmorStand := RobCoExportFieldIfChanged(e,
    RobCoNoneIfEmpty(gRobCoSnapPowerArmorStand),
    RobCoNoneIfEmpty(gRobCoSnapMasterPowerArmorStand));
  gNpcPatchXpValueOffset := RobCoNpcXpValueOffsetExportVal(gRobCoSnapXpValueOffset,
    gRobCoSnapMasterXpValueOffset);

  if Assigned(gRobCoSnapMaster) then begin

    if RobCoSnapshotUseItmGate then

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

  RobCoSnapClearFieldScratch;

  RobCoSnapReadMasterIfAny(e);

  if RobCoSnapshotUseItmGate then begin
    if RobCoSnapTryEarlyPregatherSkipRace(e) then begin
      RobCoSnapRecordEarlyPregatherSkip('ExportRACEToRobCo');
      Exit;
    end;
  end;

  RobCoReadRacePatchInputs(e);
  if RobCoSnapshotUseItmGate then begin
    if RobCoRaceFieldsUnchangedFromScratch(e) then begin
      RobCoSnapRecordEarlyPregatherSkip('ExportRACEToRobCo');
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

  RobCoSnapClearFieldScratch;

  if RobCoSnapshotUseItmGate then begin
    if RobCoSnapTryEarlyPregatherSkipNpc(e) then begin
      RobCoSnapRecordEarlyPregatherSkip('ExportNPCToRobCo');
      Exit;
    end;
  end;

  RobCoReadNpcPatchInputs(e);

  GatherNpcPatchDataFromScratch(e);
  RobCoEmitSnapshotRecord(e, 'NPC_', shortComment, BuildRobCoNPCLine);
end;



//============================================================================

procedure RobCoBeginNpcPluginExport;

begin

  bLoggedSkyrimAVSkip := False;

end;


end.
