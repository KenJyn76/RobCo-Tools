unit Snapshot;

//============================================================================
// Read-once scratch (populated by Read*PatchInputs per record)
//============================================================================
var
  gSnapMaster: IInterface;
  gSnapKeywords, gSnapMasterKeywords: string;
  gSnapPerks, gSnapMasterPerks: string;
  gSnapSpells, gSnapMasterSpells: string;
  gSnapChangeAvif, gSnapMasterChangeAvif: string;
  gSnapFactions, gSnapMasterFactions: string;
  gSnapInventory, gSnapMasterInventory: string;
  gSnapFullName, gSnapMasterFullName: string;
  gSnapDeathItem, gSnapMasterDeathItem: string;
  gSnapSkin, gSnapMasterSkin: string;
  gSnapPowerArmorStand, gSnapMasterPowerArmorStand: string;
  gSnapXpValueOffset, gSnapMasterXpValueOffset: string;
  gSnapRaceRef, gSnapMasterRaceRef: string;
  gSnapClassRef, gSnapMasterClassRef: string;
  gSnapValue, gSnapMasterValue: string;
  gSnapWeight, gSnapMasterWeight: string;
  gSnapDamage, gSnapMasterDamage: string;
  gSnapAttackDamage, gSnapMasterAttackDamage: string;
  gSnapProjectile, gSnapMasterProjectile: string;
  gSnapCategoryKw, gSnapMasterCategoryKw: string;
  gSnapWorkbench, gSnapMasterWorkbench: string;
  gSnapObjectEffect, gSnapMasterObjectEffect: string;
  gSnapApprKw, gSnapMasterApprKw: string;
  gSnapArmorRating, gSnapMasterArmorRating: string;
  gSnapHealth, gSnapMasterHealth: string;
  gSnapBashDamage, gSnapMasterBashDamage: string;
  gSnapAttackActionPointCost, gSnapMasterAttackActionPointCost: string;
  gSnapSoundLevel, gSnapMasterSoundLevel: string;
  gSnapAmmoRef, gSnapMasterAmmoRef: string;
  gSnapAimModel, gSnapMasterAimModel: string;
  gSnapDamageTypes, gSnapMasterDamageTypes: string;
  gSnapOutOfRangeDamageMult, gSnapMasterOutOfRangeDamageMult: string;
  gSnapConeIronSightsMult, gSnapMasterConeIronSightsMult: string;
  gSnapRecoilSpringForce, gSnapMasterRecoilSpringForce: string;
  gSnapRecoilPerShotMin, gSnapMasterRecoilPerShotMin: string;
  gSnapRecoilPerShotMax, gSnapMasterRecoilPerShotMax: string;
  gSnapWeaponHitType, gSnapMasterWeaponHitType: string;
  gSnapOverrideProjectile, gSnapMasterOverrideProjectile: string;
  gSnapNpcAmmoList, gSnapMasterNpcAmmoList: string;
  gSnapBipedSlots, gSnapMasterBipedSlots: string;
  gSnapWeightMult, gSnapMasterWeightMult: string;
  gSnapHealthMult, gSnapMasterHealthMult: string;
  gSnapMgefs, gSnapMasterMgefs: string;
  gSnapAcbsAutoCalc, gSnapAcbsPcLevelMult, gSnapAcbsEssential: string;
  gSnapAcbsLevel, gSnapAcbsCalcMin, gSnapAcbsCalcMax: string;
  gSnapMasterAcbsAutoCalc, gSnapMasterAcbsPcLevelMult, gSnapMasterAcbsEssential: string;
  gSnapMasterAcbsLevel, gSnapMasterAcbsCalcMin, gSnapMasterAcbsCalcMax: string;
  gSnapOmodAttach, gSnapMasterOmodAttach: string;
  gSnapOmodPlainName, gSnapMasterOmodPlainName: string;
  gSnapOmodApprKw, gSnapMasterOmodApprKw: string;
  gSnapRefPartsScratch: TStringList;
  gSnapRefSeenScratch: TStringList;
  gSnapPartsScratch: TStringList;
  gSnapCommaScratch: TStringList;
  gSnapCommaScratch2: TStringList;
  // NPC incremental pregather stash (bitmask; cleared per ExportNPC record)
  gSnapNpcStashMask: integer;
  // NPC subgraph conflict-free cache (cleared per ExportNPC record)
  gSnapNpcSubgraphMask: integer;
  // RACE read-once subgraph mask (cleared per ExportRACE record)
  gSnapRaceSubgraphMask: integer;
  // RACE bilateral read progress (cleared per ExportRACE record)
  gSnapRaceStashMask: integer;
  // FO4 RACE Properties container cache (cleared per ExportRACE record)
  gSnapRacePropsFormId: cardinal;
  gSnapRacePropsTop: IInterface;
  gSnapRacePropsActor: IInterface;
  gSnapRacePropsCount: integer;
  // OMOD header stash (set when early-skip header probe already read fields)
  gSnapOmodHeaderStashed: boolean;
  // MISC lazy pregather stashed value/weight (avoid double-read in read path)
  gSnapMiscScalarsStashed: boolean;
  // MISC ITM early skip: omit trailing SnapClearFieldScratch in export wrapper
  gSnapDeferWrapperClear: boolean;
  // ALCH mgef diff stash (avoid duplicate diff work per record)
  gSnapAlchMgefDiffStashed: boolean;
  gSnapAlchMgefsToAdd: string;
  gSnapAlchMgefsToChange: string;
  gSnapAlchMgefsToRemove: string;
  // COBJ category subgraph cache (cleared per ExportCOBJ record)
  gSnapCobjSubgraphMask: integer;
  gSnapCachedNpcItemPath: string;
  gSnapCachedNpcItemCountPath: string;

//============================================================================
procedure SnapInitRefSeenScratch;
begin
  if not Assigned(gSnapRefSeenScratch) then begin
    gSnapRefSeenScratch := TStringList.Create;
    gSnapRefSeenScratch.Sorted := True;
    gSnapRefSeenScratch.Duplicates := dupIgnore;
  end;
end;

//============================================================================
procedure SnapEnsureRefSeenScratch;
begin
  SnapInitRefSeenScratch;
  gSnapRefSeenScratch.Clear;
end;

//============================================================================
procedure SnapRefPartsAddUnique(const refKey: string);
begin
  SnapInitRefSeenScratch;
  if gSnapRefSeenScratch.IndexOf(refKey) >= 0 then
    Exit;
  gSnapRefSeenScratch.Add(refKey);
  gSnapRefPartsScratch.Add(refKey);
end;

//============================================================================
procedure SnapEnsureRefPartsScratch;
begin
  if not Assigned(gSnapRefPartsScratch) then
    gSnapRefPartsScratch := TStringList.Create;
  gSnapRefPartsScratch.Clear;
  SnapEnsureRefSeenScratch;
end;

//============================================================================
procedure SnapEnsurePartsScratch;
begin
  if not Assigned(gSnapPartsScratch) then
    gSnapPartsScratch := TStringList.Create;
  gSnapPartsScratch.Clear;
end;

//============================================================================
procedure SnapEnsureCommaScratch;
begin
  if not Assigned(gSnapCommaScratch) then
    gSnapCommaScratch := TStringList.Create;
  if not Assigned(gSnapCommaScratch2) then
    gSnapCommaScratch2 := TStringList.Create;
  gSnapCommaScratch.Clear;
  gSnapCommaScratch2.Clear;
end;

//============================================================================
procedure SnapClearMaster;
begin
  gSnapMaster := nil;
end;

//============================================================================
function SnapConsumeDeferWrapperClear: boolean;
begin
  Result := gSnapDeferWrapperClear;
  gSnapDeferWrapperClear := False;
end;

//============================================================================
procedure SnapClearFieldScratch;
begin
  SnapClearMaster;
  gSnapKeywords := '';
  gSnapMasterKeywords := '';
  gSnapPerks := '';
  gSnapMasterPerks := '';
  gSnapSpells := '';
  gSnapMasterSpells := '';
  gSnapChangeAvif := '';
  gSnapMasterChangeAvif := '';
  gSnapFactions := '';
  gSnapMasterFactions := '';
  gSnapInventory := '';
  gSnapMasterInventory := '';
  gSnapFullName := '';
  gSnapMasterFullName := '';
  gSnapDeathItem := '';
  gSnapMasterDeathItem := '';
  gSnapSkin := '';
  gSnapMasterSkin := '';
  gSnapPowerArmorStand := '';
  gSnapMasterPowerArmorStand := '';
  gSnapXpValueOffset := '';
  gSnapMasterXpValueOffset := '';
  gSnapRaceRef := '';
  gSnapMasterRaceRef := '';
  gSnapClassRef := '';
  gSnapMasterClassRef := '';
  gSnapValue := '';
  gSnapMasterValue := '';
  gSnapWeight := '';
  gSnapMasterWeight := '';
  gSnapDamage := '';
  gSnapMasterDamage := '';
  gSnapAttackDamage := '';
  gSnapMasterAttackDamage := '';
  gSnapProjectile := '';
  gSnapMasterProjectile := '';
  gSnapCategoryKw := '';
  gSnapMasterCategoryKw := '';
  gSnapWorkbench := '';
  gSnapMasterWorkbench := '';
  gSnapObjectEffect := '';
  gSnapMasterObjectEffect := '';
  gSnapApprKw := '';
  gSnapMasterApprKw := '';
  gSnapArmorRating := '';
  gSnapMasterArmorRating := '';
  gSnapHealth := '';
  gSnapMasterHealth := '';
  gSnapBashDamage := '';
  gSnapMasterBashDamage := '';
  gSnapAttackActionPointCost := '';
  gSnapMasterAttackActionPointCost := '';
  gSnapSoundLevel := '';
  gSnapMasterSoundLevel := '';
  gSnapAmmoRef := '';
  gSnapMasterAmmoRef := '';
  gSnapAimModel := '';
  gSnapMasterAimModel := '';
  gSnapDamageTypes := '';
  gSnapMasterDamageTypes := '';
  gSnapOutOfRangeDamageMult := '';
  gSnapMasterOutOfRangeDamageMult := '';
  gSnapConeIronSightsMult := '';
  gSnapMasterConeIronSightsMult := '';
  gSnapRecoilSpringForce := '';
  gSnapMasterRecoilSpringForce := '';
  gSnapRecoilPerShotMin := '';
  gSnapMasterRecoilPerShotMin := '';
  gSnapRecoilPerShotMax := '';
  gSnapMasterRecoilPerShotMax := '';
  gSnapWeaponHitType := '';
  gSnapMasterWeaponHitType := '';
  gSnapOverrideProjectile := '';
  gSnapMasterOverrideProjectile := '';
  gSnapNpcAmmoList := '';
  gSnapMasterNpcAmmoList := '';
  gSnapBipedSlots := '';
  gSnapMasterBipedSlots := '';
  gSnapWeightMult := '';
  gSnapMasterWeightMult := '';
  gSnapHealthMult := '';
  gSnapMasterHealthMult := '';
  gSnapMgefs := '';
  gSnapMasterMgefs := '';
  gSnapAcbsAutoCalc := '';
  gSnapAcbsPcLevelMult := '';
  gSnapAcbsEssential := '';
  gSnapAcbsLevel := '';
  gSnapAcbsCalcMin := '';
  gSnapAcbsCalcMax := '';
  gSnapMasterAcbsAutoCalc := '';
  gSnapMasterAcbsPcLevelMult := '';
  gSnapMasterAcbsEssential := '';
  gSnapMasterAcbsLevel := '';
  gSnapMasterAcbsCalcMin := '';
  gSnapMasterAcbsCalcMax := '';
  gSnapOmodAttach := '';
  gSnapMasterOmodAttach := '';
  gSnapOmodPlainName := '';
  gSnapMasterOmodPlainName := '';
  gSnapOmodApprKw := '';
  gSnapMasterOmodApprKw := '';
  gSnapNpcStashMask := 0;
  gSnapNpcSubgraphMask := 0;
  gSnapRaceSubgraphMask := 0;
  gSnapRaceStashMask := 0;
  gSnapRacePropsFormId := 0;
  gSnapRacePropsTop := nil;
  gSnapRacePropsActor := nil;
  gSnapRacePropsCount := 0;
  gSnapOmodHeaderStashed := False;
  gSnapMiscScalarsStashed := False;
  gSnapAlchMgefDiffStashed := False;
  gSnapAlchMgefsToAdd := 'none';
  gSnapAlchMgefsToChange := 'none';
  gSnapAlchMgefsToRemove := 'none';
  gSnapCobjSubgraphMask := 0;
end;

//============================================================================
procedure SnapReleaseListScratch;
begin
  if Assigned(gSnapRefPartsScratch) then begin
    gSnapRefPartsScratch.Free;
    gSnapRefPartsScratch := nil;
  end;
  if Assigned(gSnapRefSeenScratch) then begin
    gSnapRefSeenScratch.Free;
    gSnapRefSeenScratch := nil;
  end;
  if Assigned(gSnapPartsScratch) then begin
    gSnapPartsScratch.Free;
    gSnapPartsScratch := nil;
  end;
  if Assigned(gSnapCommaScratch) then begin
    gSnapCommaScratch.Free;
    gSnapCommaScratch := nil;
  end;
  if Assigned(gSnapCommaScratch2) then begin
    gSnapCommaScratch2.Free;
    gSnapCommaScratch2 := nil;
  end;
end;

//============================================================================
procedure SnapshotClearNpcPatchOutput;
begin
  InitNPCPatchData;
end;

//============================================================================
procedure SnapReadMasterIfAny(e: IInterface);
begin
  SnapClearMaster;
  if RecordHasExternalMaster(e) then
    gSnapMaster := CompareBaselineRecord(e);
end;

//============================================================================
// MISC
//============================================================================


var
  gMiscPatchFilterByMiscs, gMiscPatchFilterByHasComponent, gMiscPatchFilterByHasNoComponent: string;
  gMiscPatchFilterByKeywords, gMiscPatchFilterByKeywordsOr, gMiscPatchFilterByKeywordsExcluded: string;
  gMiscPatchValue, gMiscPatchWeight, gMiscPatchWeightMultiply: string;

//============================================================================
procedure InitMISCPatchData;
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
procedure MiscStashScalarsFromScratch(e: IInterface);
begin
  gSnapValue := ReadMiscValue(e);
  gSnapWeight := ReadMiscWeight(e);
  gSnapMasterValue := '';
  gSnapMasterWeight := '';
  if Assigned(gSnapMaster) then begin
    gSnapMasterValue := ReadMiscValue(gSnapMaster);
    gSnapMasterWeight := ReadMiscWeight(gSnapMaster);
  end;
  gSnapMiscScalarsStashed := True;
end;

//============================================================================
function MiscFieldsUnchangedFromScratch: boolean;
begin
  Result := False;
  if not Assigned(gSnapMaster) then
    Exit;
  if gSnapValue <> gSnapMasterValue then
    Exit;
  if gSnapWeight <> gSnapMasterWeight then
    Exit;
  Result := True;
end;

//============================================================================
function MiscFieldsUnchangedVsMaster(e: IInterface): boolean;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  SnapReadMasterIfAny(e);
  if not Assigned(gSnapMaster) then
    Exit;
  MiscStashScalarsFromScratch(e);
  Result := MiscFieldsUnchangedFromScratch;
end;

//============================================================================
procedure ReadMiscPatchInputs(e: IInterface);
begin
  if gSnapMiscScalarsStashed then
    Exit;
  if not Assigned(gSnapMaster) then
    SnapReadMasterIfAny(e);
  gSnapValue := ReadMiscValue(e);
  gSnapWeight := ReadMiscWeight(e);
  gSnapMasterValue := '';
  gSnapMasterWeight := '';
  if Assigned(gSnapMaster) then begin
    gSnapMasterValue := ReadMiscValue(gSnapMaster);
    gSnapMasterWeight := ReadMiscWeight(gSnapMaster);
  end;
end;

//============================================================================
procedure GatherMiscPatchDataFromScratch(e: IInterface);
begin
  InitMISCPatchData;
  gMiscPatchFilterByMiscs := PatchFilterFormIDRef(e);
  gMiscPatchValue := ExportFieldIfChanged(e, gSnapValue, gSnapMasterValue);
  gMiscPatchWeight := ExportFieldIfChanged(e, gSnapWeight, gSnapMasterWeight);
end;

//============================================================================
procedure GatherMiscPatchData(e: IInterface);
var
  master: IInterface;
  pluginValue, pluginWeight, masterValue, masterWeight: string;
begin
  InitMISCPatchData;

  gMiscPatchFilterByMiscs := PatchFilterFormIDRef(e);

  pluginValue := ReadMiscValue(e);
  pluginWeight := ReadMiscWeight(e);
  masterValue := '';
  masterWeight := '';
  if RecordHasExternalMaster(e) then begin
    master := CompareBaselineRecord(e);
    masterValue := ReadMiscValue(master);
    masterWeight := ReadMiscWeight(master);
  end;
  gMiscPatchValue := ExportFieldIfChanged(e, pluginValue, masterValue);
  gMiscPatchWeight := ExportFieldIfChanged(e, pluginWeight, masterWeight);
end;

//============================================================================
function BuildMISCLine: string;
begin
  Result := '';
  Result := AppendPatchField(Result, 'filterByMiscs', gMiscPatchFilterByMiscs);
  Result := AppendAuthoringBatchField(Result, 'filterByHasComponent', gMiscPatchFilterByHasComponent);
  Result := AppendAuthoringBatchField(Result, 'filterByHasNoComponent', gMiscPatchFilterByHasNoComponent);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywords', gMiscPatchFilterByKeywords);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsOr', gMiscPatchFilterByKeywordsOr);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gMiscPatchFilterByKeywordsExcluded);
  Result := AppendNumericField(Result, 'value', gMiscPatchValue);
  Result := AppendNumericField(Result, 'weight', gMiscPatchWeight);
end;

//============================================================================
procedure ExportMISC(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
var
  miscScalarsReady: boolean;
begin
  if Signature(e) <> 'MISC' then
    Exit;

  gSnapDeferWrapperClear := False;
  miscScalarsReady := False;
  if SnapshotUseItmGate then begin
    if MiscFieldsUnchangedVsMaster(e) then begin
      SnapRecordEarlyPregatherSkip('ExportMISC');
      gSnapDeferWrapperClear := True;
      Exit;
    end;
    if gSnapMiscScalarsStashed then
      miscScalarsReady := True;
  end;

  if not miscScalarsReady then begin
    SnapClearFieldScratch;
    ReadMiscPatchInputs(e);
  end;
  GatherMiscPatchDataFromScratch(e);
  EmitSnapshotRecord(e, 'MISC', shortComment, BuildMISCLine);
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
  Result := ReadFormLinkRef(e, 'PNAM');
  if Result = '' then
    Result := ReadFormLinkPathOrRef(e, 'Projectile', 'INAM');
end;

//============================================================================
procedure InitAMMOPatchData;
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
  InitAMMOPatchData;

  gAmmoPatchFilterByAmmos := PatchFilterFormIDRef(e);
  keywords := ReadKeywordRefsFromElement(e);
  ApplyKeywordDiffIfItmGate(e, keywords, gAmmoPatchKeywordsToAdd, gAmmoPatchKeywordsToRemove);
  gAmmoPatchFullName := FullNameIfChanged(e);
  gAmmoPatchWeight := DataFieldIfChanged(e, 'Weight');

  if FO4Game then begin
    masterProjectile := '';
    masterAttack := '';
    if RecordHasExternalMaster(e) then begin
      masterProjectile := ReadAmmoProjectileRef(CompareBaselineRecord(e));
      masterAttack := ReadAmmoAttackDamage(CompareBaselineRecord(e));
    end;
    gAmmoPatchAttackDamage := ExportFieldIfChanged(e, ReadAmmoAttackDamage(e), masterAttack);
    projectile := ReadAmmoProjectileRef(e);
    gAmmoPatchSetNewProjectile := ExportFieldIfChanged(e, NoneIfEmpty(projectile),
      NoneIfEmpty(masterProjectile));
  end;
end;

//============================================================================
function BuildAMMOLine: string;
begin
  Result := '';
  Result := AppendPatchField(Result, 'filterByAmmos', gAmmoPatchFilterByAmmos);
  Result := AppendAuthoringBatchField(Result, 'filterByWeightLessThan', gAmmoPatchFilterByWeightLessThan);

  Result := AppendField(Result, 'fullName', gAmmoPatchFullName, False);
  Result := AppendNumericField(Result, 'weight', gAmmoPatchWeight);
  Result := AppendField(Result, 'keywordsToAdd', gAmmoPatchKeywordsToAdd, True);
  Result := AppendField(Result, 'keywordsToRemove', gAmmoPatchKeywordsToRemove, True);

  if FO4Game then begin
    Result := AppendNumericField(Result, 'attackDamage', gAmmoPatchAttackDamage);
    Result := AppendField(Result, 'ammoCategory', gAmmoPatchAmmoCategory, True);
    Result := AppendField(Result, 'setNewProjectile', gAmmoPatchSetNewProjectile, True);
  end;
end;

//============================================================================
function AmmoFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  masterProjectile: string;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  if ReadFullName(e) <> ReadFullName(master) then
    Exit;
  if ReadDataField(e, 'Weight') <> ReadDataField(master, 'Weight') then
    Exit;
  if not KeywordRefsUnchangedVsMaster(e) then
    Exit;
  if FO4Game then begin
    if ReadAmmoAttackDamage(e) <> ReadAmmoAttackDamage(master) then
      Exit;
    masterProjectile := ReadAmmoProjectileRef(master);
    if ReadAmmoProjectileRef(e) <> masterProjectile then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure ReadAmmoPatchInputs(e: IInterface);
begin
  gSnapKeywords := ReadKeywordRefsFromElement(e);
  gSnapMasterKeywords := '';
  gSnapFullName := ReadFullName(e);
  gSnapMasterFullName := '';
  gSnapWeight := ReadDataField(e, 'Weight');
  gSnapMasterWeight := '';
  gSnapAttackDamage := '';
  gSnapMasterAttackDamage := '';
  gSnapProjectile := '';
  gSnapMasterProjectile := '';
  if FO4Game then begin
    gSnapAttackDamage := ReadAmmoAttackDamage(e);
    gSnapProjectile := ReadAmmoProjectileRef(e);
  end;
  if Assigned(gSnapMaster) then begin
    gSnapMasterKeywords := ReadKeywordRefsFromElement(gSnapMaster);
    gSnapMasterFullName := ReadFullName(gSnapMaster);
    gSnapMasterWeight := ReadDataField(gSnapMaster, 'Weight');
    if FO4Game then begin
      gSnapMasterAttackDamage := ReadAmmoAttackDamage(gSnapMaster);
      gSnapMasterProjectile := ReadAmmoProjectileRef(gSnapMaster);
    end;
  end;
end;

//============================================================================
procedure ReadAmmoPatchInputsFromScratch(e: IInterface);
begin
  ReadAmmoPatchInputs(e);
end;

//============================================================================
function AmmoFieldsUnchangedFromScratch: boolean;
begin
  Result := False;
  if not Assigned(gSnapMaster) then
    Exit;
  if gSnapFullName <> gSnapMasterFullName then
    Exit;
  if gSnapWeight <> gSnapMasterWeight then
    Exit;
  if not RefListDiffUnchangedVsMaster(gSnapKeywords, gSnapMasterKeywords) then
    Exit;
  if FO4Game then begin
    if gSnapAttackDamage <> gSnapMasterAttackDamage then
      Exit;
    if gSnapProjectile <> gSnapMasterProjectile then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure GatherAmmoPatchDataFromScratch(e: IInterface);
begin
  InitAMMOPatchData;
  gAmmoPatchFilterByAmmos := PatchFilterFormIDRef(e);
  ApplyKeywordDiffIfItmGate(e, gSnapKeywords,
    gAmmoPatchKeywordsToAdd, gAmmoPatchKeywordsToRemove);
  gAmmoPatchFullName := ExportFieldIfChanged(e, gSnapFullName, gSnapMasterFullName);
  gAmmoPatchWeight := ExportFieldIfChanged(e, gSnapWeight, gSnapMasterWeight);
  if FO4Game then begin
    gAmmoPatchAttackDamage := ExportFieldIfChanged(e, gSnapAttackDamage,
      gSnapMasterAttackDamage);
    gAmmoPatchSetNewProjectile := ExportFieldIfChanged(e,
      NoneIfEmpty(gSnapProjectile), NoneIfEmpty(gSnapMasterProjectile));
  end;
end;

//============================================================================
procedure ExportAMMO(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'AMMO' then
    Exit;
  SnapClearFieldScratch;
  SnapReadMasterIfAny(e);

  if SnapshotUseItmGate then begin
    if SnapTryEarlyPregatherSkipAmmo(e) then begin
      SnapRecordEarlyPregatherSkip('ExportAMMO');
      Exit;
    end;
  end;

  ReadAmmoPatchInputsFromScratch(e);
  if SnapshotUseItmGate then begin
    if AmmoFieldsUnchangedFromScratch then begin
      SnapRecordEarlyPregatherSkip('ExportAMMO');
      Exit;
    end;
  end;

  GatherAmmoPatchDataFromScratch(e);
  EmitSnapshotRecord(e, 'AMMO', shortComment, BuildAMMOLine);
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

  SnapEnsureRefPartsScratch;
  for i := 0 to Pred(ElementCount(kwda)) do begin
    kw := LinksTo(ElementByIndex(kwda, i));
    if not Assigned(kw) then
      Continue;
    if Signature(kw) <> 'KYWD' then
      Continue;
    SnapRefPartsAddUnique(MasterFormIDRef(kw));
  end;
  Result := JoinParts(gSnapRefPartsScratch);
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
    Result := MasterFormIDRef(link)
  else
    Result := 'null';
end;

//============================================================================
procedure InitCOBJPatchData;
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
  InitCOBJPatchData;

  categoryKeywords := ReadCobjCategoryKeywordRefs(e);
  workbench := ReadWorkbenchKeywordRef(e);
  masterCategory := '';
  masterWorkbench := 'null';
  if RecordHasExternalMaster(e) then begin
    masterCategory := ReadCobjCategoryKeywordRefs(CompareBaselineRecord(e));
    masterWorkbench := ReadWorkbenchKeywordRef(CompareBaselineRecord(e));
  end;

  gCobjPatchFilterByCobjs := PatchFilterFormIDRef(e);
  ApplyRefListDiffIfItmGate(e, NoneIfEmpty(categoryKeywords),
    NoneIfEmpty(masterCategory), gCobjPatchCategoryKeywordsToAdd,
    gCobjPatchCategoryKeywordsToRemove);
  if gCobjPatchCategoryKeywordsToAdd = '' then
    gCobjPatchCategoryKeywordsToAdd := 'none';
  if gCobjPatchCategoryKeywordsToRemove = '' then
    gCobjPatchCategoryKeywordsToRemove := 'none';
  gCobjPatchWorkbenchKeyword := ExportFieldIfChanged(e, workbench, masterWorkbench);
end;

//============================================================================
function BuildCOBJLine: string;
begin
  Result := '';
  // RobCo Patcher COBJ filters are independent (OR across types), not ANDed.
  // Per-record snapshot export must use filterByCobjs only; secondary filters
  // would apply operations to unrelated constructible objects and can crash.
  Result := AppendPatchField(Result, 'filterByCobjs', gCobjPatchFilterByCobjs);

  Result := AppendField(Result, 'categoryKeywordsToAdd', gCobjPatchCategoryKeywordsToAdd, True);
  Result := AppendField(Result, 'categoryKeywordsToRemove', gCobjPatchCategoryKeywordsToRemove, True);
  Result := AppendField(Result, 'workbenchKeyword', gCobjPatchWorkbenchKeyword, True);
end;

//============================================================================
function CobjFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  categoryKeywords, masterCategory, workbench, masterWorkbench: string;
  addKw, remKw: string;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  categoryKeywords := ReadCobjCategoryKeywordRefs(e);
  masterCategory := ReadCobjCategoryKeywordRefs(master);
  DiffCommaSeparatedRefs(NoneIfEmpty(categoryKeywords),
    NoneIfEmpty(masterCategory), addKw, remKw);
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
procedure ReadCobjPatchInputs(e: IInterface);
begin
  SnapReadMasterIfAny(e);
  SnapReadCobjCategoryKwToScratch(e);
  gSnapWorkbench := ReadWorkbenchKeywordRef(e);
  gSnapMasterWorkbench := 'null';
  if Assigned(gSnapMaster) then
    gSnapMasterWorkbench := SnapCacheCobjWorkbench(gSnapMaster);
end;

//============================================================================
function CobjFieldsUnchangedFromScratch: boolean;
var
  addKw, remKw: string;
begin
  Result := False;
  if not Assigned(gSnapMaster) then
    Exit;
  DiffCommaSeparatedRefs(NoneIfEmpty(gSnapCategoryKw),
    NoneIfEmpty(gSnapMasterCategoryKw), addKw, remKw);
  if addKw <> 'none' then
    Exit;
  if remKw <> 'none' then
    Exit;
  if gSnapWorkbench <> gSnapMasterWorkbench then
    Exit;
  Result := True;
end;

//============================================================================
procedure GatherCobjPatchDataFromScratch(e: IInterface);
begin
  InitCOBJPatchData;
  gCobjPatchFilterByCobjs := PatchFilterFormIDRef(e);
  ApplyRefListDiffIfItmGate(e, NoneIfEmpty(gSnapCategoryKw),
    NoneIfEmpty(gSnapMasterCategoryKw), gCobjPatchCategoryKeywordsToAdd,
    gCobjPatchCategoryKeywordsToRemove);
  if gCobjPatchCategoryKeywordsToAdd = '' then
    gCobjPatchCategoryKeywordsToAdd := 'none';
  if gCobjPatchCategoryKeywordsToRemove = '' then
    gCobjPatchCategoryKeywordsToRemove := 'none';
  gCobjPatchWorkbenchKeyword := ExportFieldIfChanged(e, gSnapWorkbench,
    gSnapMasterWorkbench);
end;

//============================================================================
procedure ExportCOBJ(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'COBJ' then
    Exit;
  gSnapCobjSubgraphMask := 0;

  if SnapshotUseItmGate then begin
    if SnapTryEarlyPregatherSkipCobj(e) then begin
      SnapRecordEarlyPregatherSkip('ExportCOBJ');
      Exit;
    end;
  end;

  ReadCobjPatchInputs(e);
  if SnapshotUseItmGate then begin
    if CobjFieldsUnchangedFromScratch then begin
      SnapRecordEarlyPregatherSkip('ExportCOBJ');
      Exit;
    end;
  end;

  GatherCobjPatchDataFromScratch(e);
  EmitSnapshotRecord(e, 'COBJ', shortComment, BuildCOBJLine);
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
  if FO4Game then
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
  Result := ReadFormLinkPathOrRef(e, 'Object Effect', 'EITM');
  if Result = '' then
    Result := 'null';
end;

//============================================================================
procedure InitARMOPatchData;
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
  if RecordHasExternalMaster(e) then begin
    master := CompareBaselineRecord(e);
    if fromScratch then begin
      masterObjectEffect := gSnapMasterObjectEffect;
      masterAppr := gSnapMasterApprKw;
      masterDmgTypes := gSnapMasterDamageTypes;
      masterSlots := gSnapMasterBipedSlots;
    end else begin
      masterObjectEffect := ReadArmoObjectEffect(master);
      masterAppr := EffectiveApprKeywordRefs(master);
      masterDmgTypes := ReadRecordDamageTypePairs(master);
      masterSlots := ReadArmoBipedSlotIndices(master);
    end;
  end;
  if fromScratch then
    gArmoPatchHealth := ExportFieldIfChanged(e, gSnapHealth, gSnapMasterHealth)
  else
    gArmoPatchHealth := DataFieldIfChanged(e, 'Health');
  if fromScratch then
    gArmoPatchObjectEffect := ExportFieldIfChanged(e, gSnapObjectEffect,
      masterObjectEffect)
  else
    gArmoPatchObjectEffect := ExportFieldIfChanged(e, ReadArmoObjectEffect(e),
      masterObjectEffect);
  if fromScratch then
    apprKeywords := gSnapApprKw
  else
    apprKeywords := EffectiveApprKeywordRefs(e);
  ApplyApprKeywordDiffIfItmGate(e, NoneIfEmpty(apprKeywords),
    NoneIfEmpty(masterAppr), gArmoPatchAttachParentSlotKeywordsToAdd,
    gArmoPatchAttachParentSlotKeywordsToRemove);
  if fromScratch then
    pluginDmgTypes := gSnapDamageTypes
  else
    pluginDmgTypes := ReadRecordDamageTypePairs(e);
  if Assigned(master) then begin
    DiffDamageTypeMap(pluginDmgTypes, masterDmgTypes, gArmoPatchChangeDamageTypes, dmgRemove);
    // Armor article documents changeDamageTypes only (no separate remove op).
  end else
    gArmoPatchChangeDamageTypes := NoneIfEmpty(pluginDmgTypes);
  if Assigned(master) then begin
    if fromScratch then begin
      gArmoPatchWeightMult := ExportFieldIfChanged(e, gSnapWeightMult,
        gSnapMasterWeightMult);
      gArmoPatchHealthMult := ExportFieldIfChanged(e, gSnapHealthMult,
        gSnapMasterHealthMult);
    end else begin
      gArmoPatchWeightMult := ExportFieldIfChanged(e,
        ReadWeapDnamNativeValue(e, 'DNAM\Weight Mod'),
        ReadWeapDnamNativeValue(master, 'DNAM\Weight Mod'));
      gArmoPatchHealthMult := ExportFieldIfChanged(e,
        ReadWeapDnamNativeValue(e, 'DNAM\Health Mod'),
        ReadWeapDnamNativeValue(master, 'DNAM\Health Mod'));
    end;
  end;
  if fromScratch then
    pluginSlots := gSnapBipedSlots
  else
    pluginSlots := ReadArmoBipedSlotIndices(e);
  ApplyRefListDiffIfItmGate(e, pluginSlots, masterSlots, gArmoPatchBipedSlotsToAdd, slotsRem);
  gArmoPatchBipedSlotsToRemove := slotsRem;
end;

//============================================================================
procedure GatherArmoPatchData(e: IInterface);
var
  keywords: string;
begin
  InitARMOPatchData;

  gArmoPatchFilterByArmors := PatchFilterFormIDRef(e);
  keywords := ReadKeywordRefsFromElement(e);
  ApplyKeywordDiffIfItmGate(e, keywords, gArmoPatchKeywordsToAdd, gArmoPatchKeywordsToRemove);

  gArmoPatchFullName := FullNameIfChanged(e);
  gArmoPatchWeight := DataFieldIfChanged(e, 'Weight');
  gArmoPatchDamageResist := DataFieldIfChanged(e, 'Armor Rating');
  if FO4Game then
    gArmoPatchValue := ''
  else
    gArmoPatchValue := DataFieldIfChanged(e, 'Value');

  if not FO4Game then
    gArmoPatchFilterByArmorTypes := ReadSkyrimArmorTypeFilter(e);

  if FO4Game then
    GatherArmoFO4PatchExtras(e, False);
end;

//============================================================================
function BuildARMOLine: string;
begin
  Result := '';
  Result := AppendPatchField(Result, 'filterByArmors', gArmoPatchFilterByArmors);
  Result := AppendAuthoringBatchField(Result, 'filterByArmorsExcluded', gArmoPatchFilterByArmorsExcluded);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywords', gArmoPatchFilterByKeywords);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsOr', gArmoPatchFilterByKeywordsOr);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gArmoPatchFilterByKeywordsExcluded);
  Result := AppendAuthoringBatchField(Result, 'filterByBipedSlots', gArmoPatchFilterByBipedSlots);
  Result := AppendAuthoringBatchField(Result, 'filterByBipedSlotsOr', gArmoPatchFilterByBipedSlotsOr);
  Result := AppendAuthoringBatchField(Result, 'filterByBipedSlotsExcluded', gArmoPatchFilterByBipedSlotsExcluded);
  if not FO4Game then
    Result := AppendPatchField(Result, 'filterByArmorTypes', gArmoPatchFilterByArmorTypes);

  Result := AppendField(Result, 'fullName', gArmoPatchFullName, False);
  Result := AppendNumericField(Result, 'damageResist', gArmoPatchDamageResist);
  Result := AppendNumericField(Result, 'weight', gArmoPatchWeight);
  if not FO4Game then
    Result := AppendNumericField(Result, 'value', gArmoPatchValue);

  if FO4Game then begin
    Result := AppendNumericField(Result, 'health', gArmoPatchHealth);
    Result := AppendField(Result, 'objectEffect', gArmoPatchObjectEffect, True);
    Result := AppendField(Result, 'changeDamageTypes', gArmoPatchChangeDamageTypes, True);
    Result := AppendNumericField(Result, 'weightMult', gArmoPatchWeightMult);
    Result := AppendNumericField(Result, 'healthMult', gArmoPatchHealthMult);
    Result := AppendField(Result, 'keywordsToAdd', gArmoPatchKeywordsToAdd, True);
    Result := AppendField(Result, 'keywordsToRemove', gArmoPatchKeywordsToRemove, True);
    Result := AppendField(Result, 'attachParentSlotKeywordsToAdd',
      gArmoPatchAttachParentSlotKeywordsToAdd, True);
    Result := AppendField(Result, 'attachParentSlotKeywordsToRemove',
      gArmoPatchAttachParentSlotKeywordsToRemove, True);
    Result := AppendField(Result, 'bipedSlotsToAdd', gArmoPatchBipedSlotsToAdd, True);
    Result := AppendField(Result, 'bipedSlotsToRemove', gArmoPatchBipedSlotsToRemove, True);
  end else begin
    Result := AppendField(Result, 'keywordsToAdd', gArmoPatchKeywordsToAdd, False);
    Result := AppendField(Result, 'keywordsToRemove', gArmoPatchKeywordsToRemove, True);
  end;
end;

//============================================================================
function ArmoFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  apprKeywords, masterAppr: string;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  if ReadFullName(e) <> ReadFullName(master) then
    Exit;
  if ReadDataField(e, 'Weight') <> ReadDataField(master, 'Weight') then
    Exit;
  if not FO4Game then begin
    if ReadDataField(e, 'Value') <> ReadDataField(master, 'Value') then
      Exit;
  end;
  if ReadDataField(e, 'Armor Rating') <> ReadDataField(master, 'Armor Rating') then
    Exit;
  if not KeywordRefsUnchangedVsMaster(e) then
    Exit;
  if FO4Game then begin
    if ReadDataField(e, 'Health') <> ReadDataField(master, 'Health') then
      Exit;
    if ReadArmoObjectEffect(e) <> ReadArmoObjectEffect(master) then
      Exit;
    apprKeywords := EffectiveApprKeywordRefs(e);
    masterAppr := EffectiveApprKeywordRefs(master);
    if not ListFieldUnchangedVsMaster(e, apprKeywords, masterAppr) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure ReadArmoPatchInputs(e: IInterface);
begin
  SnapReadMasterIfAny(e);
  SnapReadKeywordsToScratch(e);
  gSnapFullName := ReadFullName(e);
  gSnapMasterFullName := '';
  gSnapWeight := ReadDataField(e, 'Weight');
  gSnapMasterWeight := '';
  gSnapValue := '';
  gSnapMasterValue := '';
  if not FO4Game then begin
    gSnapValue := ReadDataField(e, 'Value');
    gSnapMasterValue := '';
  end;
  gSnapArmorRating := ReadDataField(e, 'Armor Rating');
  gSnapMasterArmorRating := '';
  gSnapHealth := '';
  gSnapMasterHealth := '';
  gSnapObjectEffect := 'null';
  gSnapMasterObjectEffect := 'null';
  gSnapApprKw := '';
  gSnapMasterApprKw := '';
  if FO4Game then begin
    gSnapHealth := ReadDataField(e, 'Health');
    gSnapObjectEffect := ReadArmoObjectEffect(e);
    gSnapDamageTypes := ReadRecordDamageTypePairs(e);
    gSnapBipedSlots := ReadArmoBipedSlotIndices(e);
    gSnapWeightMult := ReadWeapDnamNativeValue(e, 'DNAM\Weight Mod');
    gSnapHealthMult := ReadWeapDnamNativeValue(e, 'DNAM\Health Mod');
    SnapReadApprKwToScratch(e);
  end;
  if Assigned(gSnapMaster) then begin
    gSnapMasterFullName := ReadFullName(gSnapMaster);
    gSnapMasterWeight := ReadDataField(gSnapMaster, 'Weight');
    if not FO4Game then
      gSnapMasterValue := ReadDataField(gSnapMaster, 'Value');
    gSnapMasterArmorRating := ReadDataField(gSnapMaster, 'Armor Rating');
    if FO4Game then begin
      gSnapMasterHealth := ReadDataField(gSnapMaster, 'Health');
      gSnapMasterObjectEffect := ReadArmoObjectEffect(gSnapMaster);
      gSnapMasterDamageTypes := ReadRecordDamageTypePairs(gSnapMaster);
      gSnapMasterBipedSlots := ReadArmoBipedSlotIndices(gSnapMaster);
      gSnapMasterWeightMult := ReadWeapDnamNativeValue(gSnapMaster, 'DNAM\Weight Mod');
      gSnapMasterHealthMult := ReadWeapDnamNativeValue(gSnapMaster, 'DNAM\Health Mod');
    end;
  end;
end;

//============================================================================
function ArmoFieldsUnchangedFromScratch(e: IInterface): boolean;
begin
  Result := False;
  if not Assigned(gSnapMaster) then
    Exit;
  if gSnapFullName <> gSnapMasterFullName then
    Exit;
  if gSnapWeight <> gSnapMasterWeight then
    Exit;
  if not FO4Game then begin
    if gSnapValue <> gSnapMasterValue then
      Exit;
  end;
  if gSnapArmorRating <> gSnapMasterArmorRating then
    Exit;
  if not RefListDiffUnchangedVsMaster(gSnapKeywords, gSnapMasterKeywords) then
    Exit;
  if FO4Game then begin
    if gSnapHealth <> gSnapMasterHealth then
      Exit;
    if gSnapObjectEffect <> gSnapMasterObjectEffect then
      Exit;
    if not RefListDiffUnchangedVsMaster(gSnapApprKw, gSnapMasterApprKw) then
      Exit;
    if not ArmoFo4ExtrasUnchangedFromScratch then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure GatherArmoPatchDataFromScratch(e: IInterface);
begin
  InitARMOPatchData;
  gArmoPatchFilterByArmors := PatchFilterFormIDRef(e);
  ApplyKeywordDiffIfItmGate(e, gSnapKeywords,
    gArmoPatchKeywordsToAdd, gArmoPatchKeywordsToRemove);
  gArmoPatchFullName := ExportFieldIfChanged(e, gSnapFullName, gSnapMasterFullName);
  gArmoPatchWeight := ExportFieldIfChanged(e, gSnapWeight, gSnapMasterWeight);
  gArmoPatchDamageResist := ExportFieldIfChanged(e, gSnapArmorRating,
    gSnapMasterArmorRating);
  if FO4Game then
    gArmoPatchValue := ''
  else
    gArmoPatchValue := ExportFieldIfChanged(e, gSnapValue, gSnapMasterValue);
  if not FO4Game then
    gArmoPatchFilterByArmorTypes := ReadSkyrimArmorTypeFilter(e);
  if FO4Game then
    GatherArmoFO4PatchExtras(e, True);
end;

//============================================================================
procedure ExportARMO(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'ARMO' then
    Exit;

  gSnapRaceSubgraphMask := 0;

  ReadArmoPatchInputs(e);
  if SnapshotUseItmGate then begin
    if ArmoFieldsUnchangedFromScratch(e) then begin
      SnapRecordEarlyPregatherSkip('ExportARMO');
      Exit;
    end;
  end;

  GatherArmoPatchDataFromScratch(e);
  EmitSnapshotRecord(e, 'ARMO', shortComment, BuildARMOLine);
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
  Result := ReadFormLinkFirst(e, 'DNAM\Ammo', 'DNAM\Ammunition');
  if Result = '' then
    Result := ReadFormLinkRef(e, 'CNAM');
end;

//============================================================================
function ReadWeapAimModelRef(e: IInterface): string;
begin
  Result := ReadFormLinkPathOrRef(e, 'Aim Model', 'AIMP');
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
  Result := ReadFormLinkPathOrRef(e, 'DNAM\Projectile', 'PNAM');
end;

//============================================================================
function ReadWeapNpcAmmoList(e: IInterface): string;
begin
  Result := ReadFormLinkPathOrRef(e, 'DNAM\NPC Ammo List', 'VNAM');
end;

//============================================================================
function ReadRecordDamageTypePairs(e: IInterface): string;
var
  arr, entry, dtLink: IInterface;
  i: integer;
  pairEntry, dmgVal: string;
begin
  Result := '';
  if not FO4Game then
    Exit;
  if not ElementExists(e, 'DNAM\Damage Types') then
    Exit;
  arr := ElementByPath(e, 'DNAM\Damage Types');
  SnapEnsurePartsScratch;
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
    pairEntry := MasterFormIDRef(dtLink) + '=' + dmgVal;
    gSnapPartsScratch.Add(pairEntry);
  end;
  Result := JoinParts(gSnapPartsScratch);
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
  SnapEnsureCommaScratch;
  ParseCommaList(gSnapCommaScratch, pluginPairs);
  ParseCommaList(gSnapCommaScratch2, masterPairs);

  SnapEnsurePartsScratch;
  for i := 0 to Pred(gSnapCommaScratch.Count) do begin
    entry := Trim(gSnapCommaScratch[i]);
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
    for j := 0 to Pred(gSnapCommaScratch2.Count) do begin
      mEntry := Trim(gSnapCommaScratch2[j]);
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
        gSnapPartsScratch.Add(entry);
      Break;
    end;
    if not found then
      gSnapPartsScratch.Add(entry);
  end;
  changeOut := NoneIfEmpty(JoinParts(gSnapPartsScratch));

  SnapEnsurePartsScratch;
  for j := 0 to Pred(gSnapCommaScratch2.Count) do begin
    mEntry := Trim(gSnapCommaScratch2[j]);
    if mEntry = '' then
      Continue;
    eqPos := Pos('=', mEntry);
    if eqPos > 0 then
      mKey := Copy(mEntry, 1, eqPos - 1)
    else
      mKey := mEntry;
    found := False;
    for i := 0 to Pred(gSnapCommaScratch.Count) do begin
      entry := Trim(gSnapCommaScratch[i]);
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
      if gSnapPartsScratch.IndexOf(mKey) < 0 then
        gSnapPartsScratch.Add(mKey);
  end;
  removeOut := NoneIfEmpty(JoinParts(gSnapPartsScratch));
end;

//============================================================================
function ReadArmoBipedSlotIndices(e: IInterface): string;
var
  flags, i: integer;
begin
  Result := '';
  if not FO4Game then
    Exit;
  if not ElementExists(e, 'BOD2\Biped Slots') then
    Exit;
  flags := Round(GetElementNativeValues(e, 'BOD2\Biped Slots'));
  SnapEnsurePartsScratch;
  for i := 0 to 31 do begin
    if (flags and (1 shl i)) <> 0 then
      gSnapPartsScratch.Add(IntToStr(i));
  end;
  Result := JoinParts(gSnapPartsScratch);
end;

//============================================================================
function ArmoFo4ExtrasUnchanged(e, master: IInterface): boolean;
var
  pluginSlots, masterSlots, pluginAppr, masterAppr: string;
begin
  Result := True;
  if not FO4Game then
    Exit;
  if not Assigned(master) then
    Exit;
  if ReadArmoObjectEffect(e) <> ReadArmoObjectEffect(master) then begin
    Result := False;
    Exit;
  end;
  pluginAppr := EffectiveApprKeywordRefs(e);
  masterAppr := EffectiveApprKeywordRefs(master);
  if not RefListDiffUnchangedVsMaster(pluginAppr, masterAppr) then begin
    Result := False;
    Exit;
  end;
  if ReadRecordDamageTypePairs(e) <> ReadRecordDamageTypePairs(master) then begin
    Result := False;
    Exit;
  end;
  pluginSlots := ReadArmoBipedSlotIndices(e);
  masterSlots := ReadArmoBipedSlotIndices(master);
  if not RefListDiffUnchangedVsMaster(pluginSlots, masterSlots) then begin
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
function ArmoFo4ExtrasUnchangedFromScratch: boolean;
begin
  Result := True;
  if not FO4Game then
    Exit;
  if not Assigned(gSnapMaster) then
    Exit;
  if gSnapObjectEffect <> gSnapMasterObjectEffect then begin
    Result := False;
    Exit;
  end;
  if not RefListDiffUnchangedVsMaster(gSnapApprKw, gSnapMasterApprKw) then begin
    Result := False;
    Exit;
  end;
  if gSnapDamageTypes <> gSnapMasterDamageTypes then begin
    Result := False;
    Exit;
  end;
  if not RefListDiffUnchangedVsMaster(gSnapBipedSlots, gSnapMasterBipedSlots) then begin
    Result := False;
    Exit;
  end;
  if gSnapWeightMult <> gSnapMasterWeightMult then begin
    Result := False;
    Exit;
  end;
  if gSnapHealthMult <> gSnapMasterHealthMult then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
procedure ApplyApprKeywordDiffIfItmGate(e: IInterface; const pluginAppr, masterAppr: string;
  var toAdd, toRemove: string);
begin
  // Same diff semantics as keywordsToAdd/Remove per Armor/Weapon/OMOD patcher articles.
  ApplyRefListDiffIfItmGate(e, pluginAppr, masterAppr, toAdd, toRemove);
end;

//============================================================================
function ReadNpcSkinRef(e: IInterface): string;
begin
  Result := ReadFormLinkPathOrRef(e, 'DNAM\Skin', 'GNAM');
end;

//============================================================================
function ReadNpcPowerArmorStandRef(e: IInterface): string;
begin
  Result := ReadFormLinkPathOrRef(e, 'DNAM\Power Armor Stand', 'SNAM');
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
function NpcXpValueOffsetUnchanged(const pluginVal, masterVal: string): boolean;
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
function NpcXpValueOffsetExportVal(const pluginVal, masterVal: string): string;
begin
  if NpcXpValueOffsetUnchanged(pluginVal, masterVal) then
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
procedure InitWEAPPatchData;
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
function WeapDnamItmGateUnchanged(e, master: IInterface; const path: string;
  pluginValue, masterValue: string): boolean;
begin
  Result := True;
  if pluginValue = masterValue then
    Exit;
  if not SubElementConflictFreeByPath(e, master, path) then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
function ExportWeapDnamFieldIfItmGate(e, master: IInterface; const path: string;
  pluginValue, masterValue: string): string;
begin
  Result := '';
  if not Assigned(master) then begin
    Result := pluginValue;
    Exit;
  end;
  if not SnapshotUseItmGate then begin
    Result := pluginValue;
    Exit;
  end;
  if SubElementConflictFreeByPath(e, master, path) then
    Exit;
  Result := ExportFieldIfChanged(e, pluginValue, masterValue);
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
  if RecordHasExternalMaster(e) then begin
    master := CompareBaselineRecord(e);
    if fromScratch then begin
      masterBash := gSnapMasterBashDamage;
      masterAmmo := gSnapMasterAmmoRef;
      masterAim := gSnapMasterAimModel;
      masterAppr := gSnapMasterApprKw;
      masterDmgTypes := gSnapMasterDamageTypes;
    end else begin
      masterBash := ReadWeapBashDamage(master);
      masterAmmo := ReadWeapAmmoRef(master);
      masterAim := ReadWeapAimModelRef(master);
      masterAppr := EffectiveApprKeywordRefs(master);
      masterDmgTypes := ReadRecordDamageTypePairs(master);
    end;
  end;
  if fromScratch then
    gWeapPatchBashDamage := ExportFieldIfChanged(e, gSnapBashDamage, masterBash)
  else
    gWeapPatchBashDamage := ExportFieldIfChanged(e, ReadWeapBashDamage(e), masterBash);
  if fromScratch then
    ammoRef := gSnapAmmoRef
  else
    ammoRef := ReadWeapAmmoRef(e);
  gWeapPatchSetNewAmmo := ExportFieldIfChanged(e, NoneIfEmpty(ammoRef),
    NoneIfEmpty(masterAmmo));
  if fromScratch then
    aimModel := gSnapAimModel
  else
    aimModel := ReadWeapAimModelRef(e);
  gWeapPatchAimModel := ExportFieldIfChanged(e, NoneIfEmpty(aimModel),
    NoneIfEmpty(masterAim));
  if fromScratch then
    apprKeywords := gSnapApprKw
  else
    apprKeywords := EffectiveApprKeywordRefs(e);
  ApplyApprKeywordDiffIfItmGate(e, NoneIfEmpty(apprKeywords),
    NoneIfEmpty(masterAppr), gWeapPatchAttachParentSlotKeywordsToAdd,
    gWeapPatchAttachParentSlotKeywordsToRemove);
  if fromScratch then
    pluginDmgTypes := gSnapDamageTypes
  else
    pluginDmgTypes := ReadRecordDamageTypePairs(e);
  if Assigned(master) then
    DiffDamageTypeMap(pluginDmgTypes, masterDmgTypes,
      gWeapPatchDamageTypesToChange, gWeapPatchDamageTypesToRemove)
  else begin
    gWeapPatchDamageTypesToChange := NoneIfEmpty(pluginDmgTypes);
    gWeapPatchDamageTypesToRemove := 'none';
  end;
  if Assigned(master) then begin
    if fromScratch then begin
      gWeapPatchOutOfRangeDamageMult := ExportFieldIfChanged(e,
        gSnapOutOfRangeDamageMult, gSnapMasterOutOfRangeDamageMult);
      gWeapPatchConeIronSightsMultiplier := ExportFieldIfChanged(e,
        gSnapConeIronSightsMult, gSnapMasterConeIronSightsMult);
      gWeapPatchRecoilDiminishSpringForce := ExportFieldIfChanged(e,
        gSnapRecoilSpringForce, gSnapMasterRecoilSpringForce);
      gWeapPatchRecoilPerShotMin := ExportFieldIfChanged(e,
        gSnapRecoilPerShotMin, gSnapMasterRecoilPerShotMin);
      gWeapPatchRecoilPerShotMax := ExportFieldIfChanged(e,
        gSnapRecoilPerShotMax, gSnapMasterRecoilPerShotMax);
      gWeapPatchAttackActionPointCost := ExportWeapDnamFieldIfItmGate(e, master,
        'DNAM\Action Point Cost',
        gSnapAttackActionPointCost, gSnapMasterAttackActionPointCost);
      gWeapPatchSoundLevel := ExportWeapDnamFieldIfItmGate(e, master,
        'DNAM\Sound Level',
        gSnapSoundLevel, gSnapMasterSoundLevel);
      gWeapPatchWeaponHitType := ExportFieldIfChanged(e,
        gSnapWeaponHitType, gSnapMasterWeaponHitType);
      gWeapPatchOverrideProjectile := ExportFieldIfChanged(e,
        gSnapOverrideProjectile, gSnapMasterOverrideProjectile);
      gWeapPatchSetNewAmmoList := ExportFieldIfChanged(e,
        gSnapNpcAmmoList, gSnapMasterNpcAmmoList);
    end else begin
      gWeapPatchOutOfRangeDamageMult := ExportFieldIfChanged(e,
        ReadWeapDnamNativeValue(e, 'DNAM\Out of Range Damage Mult'),
        ReadWeapDnamNativeValue(master, 'DNAM\Out of Range Damage Mult'));
      gWeapPatchConeIronSightsMultiplier := ExportFieldIfChanged(e,
        ReadWeapAimModelScalar(e, 'DNAM\Cone Iron Sights Mult'),
        ReadWeapAimModelScalar(master, 'DNAM\Cone Iron Sights Mult'));
      gWeapPatchRecoilDiminishSpringForce := ExportFieldIfChanged(e,
        ReadWeapAimModelScalar(e, 'DNAM\Recoil Diminish Spring Force'),
        ReadWeapAimModelScalar(master, 'DNAM\Recoil Diminish Spring Force'));
      gWeapPatchRecoilPerShotMin := ExportFieldIfChanged(e,
        ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Min Degrees'),
        ReadWeapAimModelScalar(master, 'DNAM\Recoil Per Shot - Min Degrees'));
      gWeapPatchRecoilPerShotMax := ExportFieldIfChanged(e,
        ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Max Degrees'),
        ReadWeapAimModelScalar(master, 'DNAM\Recoil Per Shot - Max Degrees'));
      gWeapPatchAttackActionPointCost := ExportWeapDnamFieldIfItmGate(e, master,
        'DNAM\Action Point Cost',
        ReadWeapDnamNativeValue(e, 'DNAM\Action Point Cost'),
        ReadWeapDnamNativeValue(master, 'DNAM\Action Point Cost'));
      gWeapPatchSoundLevel := ExportWeapDnamFieldIfItmGate(e, master,
        'DNAM\Sound Level',
        ReadWeapDnamEditValue(e, 'DNAM\Sound Level'),
        ReadWeapDnamEditValue(master, 'DNAM\Sound Level'));
      gWeapPatchWeaponHitType := ExportFieldIfChanged(e,
        ReadWeapDnamEditValue(e, 'DNAM\Weapon Hit Type'),
        ReadWeapDnamEditValue(master, 'DNAM\Weapon Hit Type'));
      gWeapPatchOverrideProjectile := ExportFieldIfChanged(e,
        NoneIfEmpty(ReadWeapOverrideProjectile(e)),
        NoneIfEmpty(ReadWeapOverrideProjectile(master)));
      gWeapPatchSetNewAmmoList := ExportFieldIfChanged(e,
        NoneIfEmpty(ReadWeapNpcAmmoList(e)),
        NoneIfEmpty(ReadWeapNpcAmmoList(master)));
    end;
  end else begin
    gWeapPatchOutOfRangeDamageMult := ReadWeapDnamNativeValue(e, 'DNAM\Out of Range Damage Mult');
    gWeapPatchConeIronSightsMultiplier := ReadWeapAimModelScalar(e, 'DNAM\Cone Iron Sights Mult');
    gWeapPatchRecoilDiminishSpringForce := ReadWeapAimModelScalar(e, 'DNAM\Recoil Diminish Spring Force');
    gWeapPatchRecoilPerShotMin := ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Min Degrees');
    gWeapPatchRecoilPerShotMax := ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Max Degrees');
    if fromScratch then begin
      gWeapPatchAttackActionPointCost := gSnapAttackActionPointCost;
      gWeapPatchSoundLevel := gSnapSoundLevel;
    end else begin
      gWeapPatchAttackActionPointCost := ReadWeapDnamNativeValue(e, 'DNAM\Action Point Cost');
      gWeapPatchSoundLevel := ReadWeapDnamEditValue(e, 'DNAM\Sound Level');
    end;
    gWeapPatchWeaponHitType := ReadWeapDnamEditValue(e, 'DNAM\Weapon Hit Type');
    gWeapPatchOverrideProjectile := NoneIfEmpty(ReadWeapOverrideProjectile(e));
    gWeapPatchSetNewAmmoList := NoneIfEmpty(ReadWeapNpcAmmoList(e));
  end;
end;

//============================================================================
function WeapFo4ExtrasUnchanged(e, master: IInterface): boolean;
var
  pluginDmg, masterDmg, changeOut, removeOut, pluginAppr, masterAppr: string;
begin
  Result := True;
  if not FO4Game then
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
  pluginAppr := EffectiveApprKeywordRefs(e);
  masterAppr := EffectiveApprKeywordRefs(master);
  if not RefListDiffUnchangedVsMaster(pluginAppr, masterAppr) then begin
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
    if not SubElementConflictFreeByPath(e, master, 'DNAM\Action Point Cost') then begin
      Result := False;
      Exit;
    end;
  end;
  if ReadWeapDnamEditValue(e, 'DNAM\Sound Level') <>
    ReadWeapDnamEditValue(master, 'DNAM\Sound Level') then begin
    if not SubElementConflictFreeByPath(e, master, 'DNAM\Sound Level') then begin
      Result := False;
      Exit;
    end;
  end;
  if ReadWeapDnamEditValue(e, 'DNAM\Weapon Hit Type') <>
    ReadWeapDnamEditValue(master, 'DNAM\Weapon Hit Type') then begin
    Result := False;
    Exit;
  end;
  if NoneIfEmpty(ReadWeapOverrideProjectile(e)) <>
    NoneIfEmpty(ReadWeapOverrideProjectile(master)) then begin
    Result := False;
    Exit;
  end;
  if NoneIfEmpty(ReadWeapNpcAmmoList(e)) <>
    NoneIfEmpty(ReadWeapNpcAmmoList(master)) then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
function WeapFo4ExtrasUnchangedFromScratch(e: IInterface): boolean;
var
  changeOut, removeOut: string;
begin
  Result := True;
  if not FO4Game then
    Exit;
  if not Assigned(gSnapMaster) then
    Exit;
  if gSnapBashDamage <> gSnapMasterBashDamage then begin
    Result := False;
    Exit;
  end;
  if gSnapAmmoRef <> gSnapMasterAmmoRef then begin
    Result := False;
    Exit;
  end;
  if gSnapAimModel <> gSnapMasterAimModel then begin
    Result := False;
    Exit;
  end;
  if not RefListDiffUnchangedVsMaster(gSnapApprKw, gSnapMasterApprKw) then begin
    Result := False;
    Exit;
  end;
  DiffDamageTypeMap(gSnapDamageTypes, gSnapMasterDamageTypes, changeOut, removeOut);
  if (changeOut <> '') and (changeOut <> 'none') then begin
    Result := False;
    Exit;
  end;
  if (removeOut <> '') and (removeOut <> 'none') then begin
    Result := False;
    Exit;
  end;
  if gSnapOutOfRangeDamageMult <> gSnapMasterOutOfRangeDamageMult then begin
    Result := False;
    Exit;
  end;
  if gSnapConeIronSightsMult <> gSnapMasterConeIronSightsMult then begin
    Result := False;
    Exit;
  end;
  if gSnapRecoilSpringForce <> gSnapMasterRecoilSpringForce then begin
    Result := False;
    Exit;
  end;
  if gSnapRecoilPerShotMin <> gSnapMasterRecoilPerShotMin then begin
    Result := False;
    Exit;
  end;
  if gSnapRecoilPerShotMax <> gSnapMasterRecoilPerShotMax then begin
    Result := False;
    Exit;
  end;
  if not WeapDnamItmGateUnchanged(e, gSnapMaster, 'DNAM\Action Point Cost',
    gSnapAttackActionPointCost, gSnapMasterAttackActionPointCost) then begin
    Result := False;
    Exit;
  end;
  if not WeapDnamItmGateUnchanged(e, gSnapMaster, 'DNAM\Sound Level',
    gSnapSoundLevel, gSnapMasterSoundLevel) then begin
    Result := False;
    Exit;
  end;
  if gSnapWeaponHitType <> gSnapMasterWeaponHitType then begin
    Result := False;
    Exit;
  end;
  if gSnapOverrideProjectile <> gSnapMasterOverrideProjectile then begin
    Result := False;
    Exit;
  end;
  if gSnapNpcAmmoList <> gSnapMasterNpcAmmoList then begin
    Result := False;
    Exit;
  end;
end;

//============================================================================
procedure GatherWeapPatchData(e: IInterface);
var
  keywords: string;
begin
  InitWEAPPatchData;

  gWeapPatchFilterByWeapons := PatchFilterFormIDRef(e);
  keywords := ReadKeywordRefsFromElement(e);
  ApplyKeywordDiffIfItmGate(e, keywords, gWeapPatchKeywordsToAdd, gWeapPatchKeywordsToRemove);

  gWeapPatchFullName := FullNameIfChanged(e);
  gWeapPatchAttackDamage := DataFieldIfChanged(e, 'Damage');
  gWeapPatchWeight := DataFieldIfChanged(e, 'Weight');
  gWeapPatchValue := DataFieldIfChanged(e, 'Value');

  if FO4Game then
    GatherWeapFO4PatchExtras(e, False);
end;

//============================================================================
function BuildWEAPLine: string;
begin
  Result := '';
  Result := AppendPatchField(Result, 'filterByWeapons', gWeapPatchFilterByWeapons);
  Result := AppendAuthoringBatchField(Result, 'filterByAmmos', gWeapPatchFilterByAmmos);
  Result := AppendAuthoringBatchField(Result, 'filterByWeaponsExcluded', gWeapPatchFilterByWeaponsExcluded);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywords', gWeapPatchFilterByKeywords);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsOr', gWeapPatchFilterByKeywordsOr);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gWeapPatchFilterByKeywordsExcluded);
  Result := AppendAuthoringBatchField(Result, 'filterByHasAmmoFromWeaponList',
    gWeapPatchFilterByHasAmmoFromWeaponList);

  Result := AppendField(Result, 'fullName', gWeapPatchFullName, False);

  if FO4Game then begin
    Result := AppendNumericField(Result, 'attackDamage', gWeapPatchAttackDamage);
    Result := AppendNumericField(Result, 'bashDamage', gWeapPatchBashDamage);
    Result := AppendNumericField(Result, 'outOfRangeDamageMult', gWeapPatchOutOfRangeDamageMult);
    Result := AppendNumericField(Result, 'coneIronSightsMultiplier', gWeapPatchConeIronSightsMultiplier);
    Result := AppendNumericField(Result, 'recoilDiminishSpringForce', gWeapPatchRecoilDiminishSpringForce);
    Result := AppendNumericField(Result, 'recoilPerShotMin', gWeapPatchRecoilPerShotMin);
    Result := AppendNumericField(Result, 'recoilPerShotMax', gWeapPatchRecoilPerShotMax);
    Result := AppendNumericField(Result, 'attackActionPointCost', gWeapPatchAttackActionPointCost);
    Result := AppendField(Result, 'soundLevel', gWeapPatchSoundLevel, True);
    Result := AppendField(Result, 'weaponHitType', gWeapPatchWeaponHitType, True);
    Result := AppendField(Result, 'keywordsToAdd', gWeapPatchKeywordsToAdd, True);
    Result := AppendField(Result, 'keywordsToRemove', gWeapPatchKeywordsToRemove, True);
    Result := AppendField(Result, 'setNewAmmo', gWeapPatchSetNewAmmo, True);
    Result := AppendField(Result, 'setNewAmmoList', gWeapPatchSetNewAmmoList, True);
    Result := AppendField(Result, 'aimModel', gWeapPatchAimModel, True);
    Result := AppendField(Result, 'overrideProjectile', gWeapPatchOverrideProjectile, True);
    Result := AppendNumericField(Result, 'weight', gWeapPatchWeight);
    Result := AppendNumericField(Result, 'value', gWeapPatchValue);
    Result := AppendField(Result, 'damageTypesToChange', gWeapPatchDamageTypesToChange, True);
    Result := AppendField(Result, 'damageTypesToRemove', gWeapPatchDamageTypesToRemove, True);
    Result := AppendField(Result, 'attachParentSlotKeywordsToAdd',
      gWeapPatchAttachParentSlotKeywordsToAdd, True);
    Result := AppendField(Result, 'attachParentSlotKeywordsToRemove',
      gWeapPatchAttachParentSlotKeywordsToRemove, True);
  end else begin
    Result := AppendNumericField(Result, 'attackDamage', gWeapPatchAttackDamage);
    Result := AppendNumericField(Result, 'weight', gWeapPatchWeight);
    Result := AppendNumericField(Result, 'value', gWeapPatchValue);
    Result := AppendField(Result, 'keywordsToAdd', gWeapPatchKeywordsToAdd, False);
    Result := AppendField(Result, 'keywordsToRemove', gWeapPatchKeywordsToRemove, True);
  end;
end;

//============================================================================
function WeapFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  apprKeywords, masterAppr: string;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  if ReadFullName(e) <> ReadFullName(master) then
    Exit;
  if ReadDataField(e, 'Damage') <> ReadDataField(master, 'Damage') then
    Exit;
  if ReadDataField(e, 'Weight') <> ReadDataField(master, 'Weight') then
    Exit;
  if ReadDataField(e, 'Value') <> ReadDataField(master, 'Value') then
    Exit;
  if not KeywordRefsUnchangedVsMaster(e) then
    Exit;
  if FO4Game then begin
    if ReadWeapBashDamage(e) <> ReadWeapBashDamage(master) then
      Exit;
    if ReadWeapAmmoRef(e) <> ReadWeapAmmoRef(master) then
      Exit;
    if ReadWeapAimModelRef(e) <> ReadWeapAimModelRef(master) then
      Exit;
    apprKeywords := EffectiveApprKeywordRefs(e);
    masterAppr := EffectiveApprKeywordRefs(master);
    if not ListFieldUnchangedVsMaster(e, apprKeywords, masterAppr) then
      Exit;
    if not WeapFo4ExtrasUnchanged(e, master) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure ReadWeapPatchInputs(e: IInterface);
begin
  SnapReadMasterIfAny(e);
  SnapReadKeywordsToScratch(e);
  gSnapFullName := ReadFullName(e);
  gSnapMasterFullName := '';
  gSnapDamage := ReadDataField(e, 'Damage');
  gSnapMasterDamage := '';
  gSnapWeight := ReadDataField(e, 'Weight');
  gSnapMasterWeight := '';
  gSnapValue := ReadDataField(e, 'Value');
  gSnapMasterValue := '';
  gSnapBashDamage := '';
  gSnapMasterBashDamage := '';
  gSnapAmmoRef := '';
  gSnapMasterAmmoRef := '';
  gSnapAimModel := '';
  gSnapMasterAimModel := '';
  gSnapApprKw := '';
  gSnapMasterApprKw := '';
  gSnapAttackActionPointCost := '';
  gSnapMasterAttackActionPointCost := '';
  gSnapSoundLevel := '';
  gSnapMasterSoundLevel := '';
  if FO4Game then begin
    gSnapBashDamage := ReadWeapBashDamage(e);
    gSnapAmmoRef := ReadWeapAmmoRef(e);
    gSnapAimModel := ReadWeapAimModelRef(e);
    gSnapAttackActionPointCost := ReadWeapDnamNativeValue(e, 'DNAM\Action Point Cost');
    gSnapSoundLevel := ReadWeapDnamEditValue(e, 'DNAM\Sound Level');
    gSnapDamageTypes := ReadRecordDamageTypePairs(e);
    gSnapOutOfRangeDamageMult := ReadWeapDnamNativeValue(e, 'DNAM\Out of Range Damage Mult');
    gSnapConeIronSightsMult := ReadWeapAimModelScalar(e, 'DNAM\Cone Iron Sights Mult');
    gSnapRecoilSpringForce := ReadWeapAimModelScalar(e, 'DNAM\Recoil Diminish Spring Force');
    gSnapRecoilPerShotMin := ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Min Degrees');
    gSnapRecoilPerShotMax := ReadWeapAimModelScalar(e, 'DNAM\Recoil Per Shot - Max Degrees');
    gSnapWeaponHitType := ReadWeapDnamEditValue(e, 'DNAM\Weapon Hit Type');
    gSnapOverrideProjectile := NoneIfEmpty(ReadWeapOverrideProjectile(e));
    gSnapNpcAmmoList := NoneIfEmpty(ReadWeapNpcAmmoList(e));
    SnapReadApprKwToScratch(e);
  end;
  if Assigned(gSnapMaster) then begin
    gSnapMasterFullName := ReadFullName(gSnapMaster);
    gSnapMasterDamage := ReadDataField(gSnapMaster, 'Damage');
    gSnapMasterWeight := ReadDataField(gSnapMaster, 'Weight');
    gSnapMasterValue := ReadDataField(gSnapMaster, 'Value');
    if FO4Game then begin
      gSnapMasterBashDamage := ReadWeapBashDamage(gSnapMaster);
      gSnapMasterAmmoRef := ReadWeapAmmoRef(gSnapMaster);
      gSnapMasterAimModel := ReadWeapAimModelRef(gSnapMaster);
      gSnapMasterAttackActionPointCost := ReadWeapDnamNativeValue(gSnapMaster,
        'DNAM\Action Point Cost');
      gSnapMasterSoundLevel := ReadWeapDnamEditValue(gSnapMaster, 'DNAM\Sound Level');
      gSnapMasterDamageTypes := ReadRecordDamageTypePairs(gSnapMaster);
      gSnapMasterOutOfRangeDamageMult := ReadWeapDnamNativeValue(gSnapMaster,
        'DNAM\Out of Range Damage Mult');
      gSnapMasterConeIronSightsMult := ReadWeapAimModelScalar(gSnapMaster,
        'DNAM\Cone Iron Sights Mult');
      gSnapMasterRecoilSpringForce := ReadWeapAimModelScalar(gSnapMaster,
        'DNAM\Recoil Diminish Spring Force');
      gSnapMasterRecoilPerShotMin := ReadWeapAimModelScalar(gSnapMaster,
        'DNAM\Recoil Per Shot - Min Degrees');
      gSnapMasterRecoilPerShotMax := ReadWeapAimModelScalar(gSnapMaster,
        'DNAM\Recoil Per Shot - Max Degrees');
      gSnapMasterWeaponHitType := ReadWeapDnamEditValue(gSnapMaster, 'DNAM\Weapon Hit Type');
      gSnapMasterOverrideProjectile := NoneIfEmpty(ReadWeapOverrideProjectile(gSnapMaster));
      gSnapMasterNpcAmmoList := NoneIfEmpty(ReadWeapNpcAmmoList(gSnapMaster));
    end;
  end;
end;

//============================================================================
function WeapFieldsUnchangedFromScratch(e: IInterface): boolean;
begin
  Result := False;
  if not Assigned(gSnapMaster) then
    Exit;
  if gSnapFullName <> gSnapMasterFullName then
    Exit;
  if gSnapDamage <> gSnapMasterDamage then
    Exit;
  if gSnapWeight <> gSnapMasterWeight then
    Exit;
  if gSnapValue <> gSnapMasterValue then
    Exit;
  if not RefListDiffUnchangedVsMaster(gSnapKeywords, gSnapMasterKeywords) then
    Exit;
  if FO4Game then begin
    if gSnapBashDamage <> gSnapMasterBashDamage then
      Exit;
    if gSnapAmmoRef <> gSnapMasterAmmoRef then
      Exit;
    if gSnapAimModel <> gSnapMasterAimModel then
      Exit;
    if not RefListDiffUnchangedVsMaster(gSnapApprKw, gSnapMasterApprKw) then
      Exit;
    if not WeapDnamItmGateUnchanged(e, gSnapMaster, 'DNAM\Action Point Cost',
      gSnapAttackActionPointCost, gSnapMasterAttackActionPointCost) then
      Exit;
    if not WeapDnamItmGateUnchanged(e, gSnapMaster, 'DNAM\Sound Level',
      gSnapSoundLevel, gSnapMasterSoundLevel) then
      Exit;
    if not WeapFo4ExtrasUnchangedFromScratch(e) then
      Exit;
  end;
  Result := True;
end;

//============================================================================
procedure GatherWeapPatchDataFromScratch(e: IInterface);
begin
  InitWEAPPatchData;
  gWeapPatchFilterByWeapons := PatchFilterFormIDRef(e);
  ApplyKeywordDiffIfItmGate(e, gSnapKeywords,
    gWeapPatchKeywordsToAdd, gWeapPatchKeywordsToRemove);
  gWeapPatchFullName := ExportFieldIfChanged(e, gSnapFullName, gSnapMasterFullName);
  gWeapPatchAttackDamage := ExportFieldIfChanged(e, gSnapDamage, gSnapMasterDamage);
  gWeapPatchWeight := ExportFieldIfChanged(e, gSnapWeight, gSnapMasterWeight);
  gWeapPatchValue := ExportFieldIfChanged(e, gSnapValue, gSnapMasterValue);
  if FO4Game then
    GatherWeapFO4PatchExtras(e, True);
end;

//============================================================================
procedure ExportWEAP(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'WEAP' then
    Exit;

  ReadWeapPatchInputs(e);
  if SnapshotUseItmGate then begin
    if WeapFieldsUnchangedFromScratch(e) then begin
      SnapRecordEarlyPregatherSkip('ExportWEAP');
      Exit;
    end;
  end;

  GatherWeapPatchDataFromScratch(e);
  EmitSnapshotRecord(e, 'WEAP', shortComment, BuildWEAPLine);
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

  SnapEnsurePartsScratch;
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

      gSnapPartsScratch.Add(
        MasterFormIDRef(mgef) + '~' + IntToStr(magnitude) + '~' +
        IntToStr(duration) + '~' + IntToStr(area)
      );
    end;
  Result := JoinParts(gSnapPartsScratch);
end;

//============================================================================
function AlchMgefRefFromKey(const effectKey: string): string;
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
procedure AlchMgefBuildMultiset(const listText: string; ms: TStringList);
var
  i: integer;
  key: string;
begin
  ms.Clear;
  SnapEnsureCommaScratch;
  ParseCommaList(gSnapCommaScratch, listText);
  for i := 0 to Pred(gSnapCommaScratch.Count) do begin
    key := Trim(gSnapCommaScratch[i]);
    if key <> '' then
      MultisetInc(ms, key);
  end;
end;

//============================================================================
procedure AlchMgefPairAddRemove(addParts, remParts, changeParts: TStringList);
var
  i, j, k: integer;
  addKey, remKey, addRef, remRef: string;
begin
  i := 0;
  while i < addParts.Count do begin
    addKey := addParts[i];
    addRef := AlchMgefRefFromKey(addKey);
    j := -1;
    for k := 0 to Pred(remParts.Count) do begin
      remRef := AlchMgefRefFromKey(remParts[k]);
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
  gAlchDiffPluginMs: TStringList;
  gAlchDiffMasterMs: TStringList;
  gAlchDiffUnionKeys: TStringList;
  gAlchDiffAdd: TStringList;
  gAlchDiffChange: TStringList;
  gAlchDiffRem: TStringList;

//============================================================================
procedure EnsureAlchDiffScratch;
begin
  if not Assigned(gAlchDiffPluginMs) then begin
    gAlchDiffPluginMs := TStringList.Create;
    gAlchDiffMasterMs := TStringList.Create;
    gAlchDiffUnionKeys := TStringList.Create;
    gAlchDiffAdd := TStringList.Create;
    gAlchDiffChange := TStringList.Create;
    gAlchDiffRem := TStringList.Create;
  end;
  gAlchDiffPluginMs.Clear;
  gAlchDiffMasterMs.Clear;
  gAlchDiffUnionKeys.Clear;
  gAlchDiffAdd.Clear;
  gAlchDiffChange.Clear;
  gAlchDiffRem.Clear;
  gAlchDiffUnionKeys.Sorted := True;
  gAlchDiffUnionKeys.Duplicates := dupIgnore;
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
  if pluginMgefs = masterMgefs then
    Exit;

  EnsureAlchDiffScratch;
  AlchMgefBuildMultiset(pluginMgefs, gAlchDiffPluginMs);
  AlchMgefBuildMultiset(masterMgefs, gAlchDiffMasterMs);
  MultisetSort(gAlchDiffPluginMs);
  MultisetSort(gAlchDiffMasterMs);

  if MultisetEqual(gAlchDiffPluginMs, gAlchDiffMasterMs) then
    Exit;

  for i := 0 to Pred(gAlchDiffPluginMs.Count) do
    gAlchDiffUnionKeys.Add(gAlchDiffPluginMs[i]);
  for i := 0 to Pred(gAlchDiffMasterMs.Count) do
    gAlchDiffUnionKeys.Add(gAlchDiffMasterMs[i]);

  for i := 0 to Pred(gAlchDiffUnionKeys.Count) do begin
    key := gAlchDiffUnionKeys[i];
    pluginCount := MultisetCount(gAlchDiffPluginMs, key);
    masterCount := MultisetCount(gAlchDiffMasterMs, key);
    n := pluginCount - masterCount;
    if n > 0 then
      for j := 1 to n do
        gAlchDiffAdd.Add(key);
    n := masterCount - pluginCount;
    if n > 0 then
      for j := 1 to n do
        gAlchDiffRem.Add(key);
  end;

  AlchMgefPairAddRemove(gAlchDiffAdd, gAlchDiffRem, gAlchDiffChange);

  mgefsToAdd := NoneIfEmpty(JoinParts(gAlchDiffAdd));
  mgefsToChange := NoneIfEmpty(JoinParts(gAlchDiffChange));
  mgefsToRemove := NoneIfEmpty(JoinParts(gAlchDiffRem));
end;

//============================================================================
procedure SnapEnsureAlchMgefDiffFromScratch;
begin
  if gSnapAlchMgefDiffStashed then
    Exit;
  DiffAlchMgefs(gSnapMgefs, gSnapMasterMgefs,
    gSnapAlchMgefsToAdd, gSnapAlchMgefsToChange, gSnapAlchMgefsToRemove);
  gSnapAlchMgefDiffStashed := True;
end;

//============================================================================
procedure InitALCHPatchData;
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
  InitALCHPatchData;

  gAlchPatchFilterByAlchs := PatchFilterFormIDRef(e);
  keywords := ReadKeywordRefsFromElement(e);
  mgefs := ReadAlchMgefsToAdd(e);

  gAlchPatchFullName := FullNameIfChanged(e);
  gAlchPatchWeight := DataFieldIfChanged(e, 'Weight');
  gAlchPatchValue := DataFieldIfChanged(e, 'Value');

  ApplyKeywordDiffIfItmGate(e, keywords, gAlchPatchKeywordsToAdd, gAlchPatchKeywordsToRemove);

  if RecordHasExternalMaster(e) then begin
    if SnapshotUseItmGate then begin
      master := CompareBaselineRecord(e);
      masterMgefs := ReadAlchMgefsToAdd(master);
      DiffAlchMgefs(mgefs, masterMgefs, gAlchPatchMgefsToAdd, gAlchPatchMgefsToChange, gAlchPatchMgefsToRemove);
    end else
      gAlchPatchMgefsToAdd := NoneIfEmpty(mgefs);
  end else
    gAlchPatchMgefsToAdd := NoneIfEmpty(mgefs);
end;

//============================================================================
//============================================================================
function BuildALCHLine: string;
begin
  Result := '';
  Result := AppendPatchField(Result, 'filterByAlchs', gAlchPatchFilterByAlchs);
  Result := AppendAuthoringBatchField(Result, 'filterByAlchsExcluded', gAlchPatchFilterByAlchsExcluded);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywords', gAlchPatchFilterByKeywords);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsOr', gAlchPatchFilterByKeywordsOr);
  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gAlchPatchFilterByKeywordsExcluded);
  Result := AppendAuthoringBatchField(Result, 'filterByMgefs', gAlchPatchFilterByMgefs);
  Result := AppendAuthoringBatchField(Result, 'filterByMgefsOr', gAlchPatchFilterByMgefsOr);
  Result := AppendAuthoringBatchField(Result, 'filterByMgefsExcluded', gAlchPatchFilterByMgefsExcluded);

  Result := AppendField(Result, 'fullName', gAlchPatchFullName, False);
  Result := AppendField(Result, 'keywordsToAdd', gAlchPatchKeywordsToAdd, True);
  Result := AppendField(Result, 'keywordsToRemove', gAlchPatchKeywordsToRemove, True);
  Result := AppendField(Result, 'mgefsToAdd', gAlchPatchMgefsToAdd, True);
  Result := AppendField(Result, 'mgefsToChange', gAlchPatchMgefsToChange, True);
  Result := AppendField(Result, 'mgefsToRemove', gAlchPatchMgefsToRemove, True);
  Result := AppendNumericField(Result, 'weight', gAlchPatchWeight);
  Result := AppendNumericField(Result, 'value', gAlchPatchValue);
end;

//============================================================================
function AlchFieldsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  mgefs, masterMgefs: string;
  mgefsToAdd, mgefsToChange, mgefsToRemove: string;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  if ReadFullName(e) <> ReadFullName(master) then
    Exit;
  if ReadDataField(e, 'Weight') <> ReadDataField(master, 'Weight') then
    Exit;
  if ReadDataField(e, 'Value') <> ReadDataField(master, 'Value') then
    Exit;
  if not KeywordRefsUnchangedVsMaster(e) then
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
procedure ReadAlchPatchInputs(e: IInterface);
begin
  SnapReadMasterIfAny(e);
  SnapReadKeywordsToScratch(e);
  SnapReadAlchMgefsToScratch(e);
  gSnapFullName := ReadFullName(e);
  gSnapMasterFullName := '';
  gSnapWeight := ReadDataField(e, 'Weight');
  gSnapMasterWeight := '';
  gSnapValue := ReadDataField(e, 'Value');
  gSnapMasterValue := '';
  if Assigned(gSnapMaster) then begin
    gSnapMasterFullName := ReadFullName(gSnapMaster);
    gSnapMasterWeight := ReadDataField(gSnapMaster, 'Weight');
    gSnapMasterValue := ReadDataField(gSnapMaster, 'Value');
  end;
end;

//============================================================================
function AlchFieldsUnchangedFromScratch: boolean;
begin
  Result := False;
  if not Assigned(gSnapMaster) then
    Exit;
  if gSnapFullName <> gSnapMasterFullName then
    Exit;
  if gSnapWeight <> gSnapMasterWeight then
    Exit;
  if gSnapValue <> gSnapMasterValue then
    Exit;
  if not RefListDiffUnchangedVsMaster(gSnapKeywords, gSnapMasterKeywords) then
    Exit;
  SnapEnsureAlchMgefDiffFromScratch;
  if gSnapAlchMgefsToAdd <> 'none' then
    Exit;
  if gSnapAlchMgefsToChange <> 'none' then
    Exit;
  if gSnapAlchMgefsToRemove <> 'none' then
    Exit;
  Result := True;
end;

//============================================================================
procedure GatherAlchPatchDataFromScratch(e: IInterface);
begin
  InitALCHPatchData;
  gAlchPatchFilterByAlchs := PatchFilterFormIDRef(e);
  gAlchPatchFullName := ExportFieldIfChanged(e, gSnapFullName, gSnapMasterFullName);
  gAlchPatchWeight := ExportFieldIfChanged(e, gSnapWeight, gSnapMasterWeight);
  gAlchPatchValue := ExportFieldIfChanged(e, gSnapValue, gSnapMasterValue);
  ApplyKeywordDiffIfItmGate(e, gSnapKeywords,
    gAlchPatchKeywordsToAdd, gAlchPatchKeywordsToRemove);
  if Assigned(gSnapMaster) then begin
    if SnapshotUseItmGate then begin
      SnapEnsureAlchMgefDiffFromScratch;
      gAlchPatchMgefsToAdd := gSnapAlchMgefsToAdd;
      gAlchPatchMgefsToChange := gSnapAlchMgefsToChange;
      gAlchPatchMgefsToRemove := gSnapAlchMgefsToRemove;
    end else
      gAlchPatchMgefsToAdd := NoneIfEmpty(gSnapMgefs);
  end else
    gAlchPatchMgefsToAdd := NoneIfEmpty(gSnapMgefs);
end;

//============================================================================
procedure ExportALCH(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'ALCH' then
    Exit;

  gSnapRaceSubgraphMask := 0;

  if SnapshotUseItmGate then begin
    if SnapTryEarlyPregatherSkipAlch(e) then begin
      SnapRecordEarlyPregatherSkip('ExportALCH');
      Exit;
    end;
  end;

  ReadAlchPatchInputs(e);
  if SnapshotUseItmGate then begin
    if AlchFieldsUnchangedFromScratch then begin
      SnapRecordEarlyPregatherSkip('ExportALCH');
      Exit;
    end;
  end;

  GatherAlchPatchDataFromScratch(e);
  EmitSnapshotRecord(e, 'ALCH', shortComment, BuildALCHLine);
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

  gOmodScratchFloat, gOmodScratchVp, gOmodScratchForm: TStringList;
  gOmodScratchFn: TStringList;
  gOmodScratchMasterFloat, gOmodScratchMasterVp, gOmodScratchMasterForm: TStringList;

//============================================================================
procedure OmodEnsurePropListScratch;
begin
  if not Assigned(gOmodScratchFloat) then begin
    gOmodScratchFloat := TStringList.Create;
    gOmodScratchVp := TStringList.Create;
    gOmodScratchForm := TStringList.Create;
    gOmodScratchFn := TStringList.Create;
    gOmodScratchMasterFloat := TStringList.Create;
    gOmodScratchMasterVp := TStringList.Create;
    gOmodScratchMasterForm := TStringList.Create;
  end;
  gOmodScratchFloat.Clear;
  gOmodScratchVp.Clear;
  gOmodScratchForm.Clear;
  gOmodScratchFn.Clear;
  gOmodScratchMasterFloat.Clear;
  gOmodScratchMasterVp.Clear;
  gOmodScratchMasterForm.Clear;
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
  Result := ReadUnionFormLink(prop);
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

  rightRef := MasterFormIDRef(link);
  link2 := nil;
  if ElementExists(prop, 'Value\Object Union\Object v1\FormID') then
    link2 := LinksTo(ElementByPath(prop, 'Value\Object Union\Object v1\FormID'));

  if Assigned(link2) then begin
    leftRef := MasterFormIDRef(link2);
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
      if gOmodScratchFn.IndexOf(fnEntry) < 0 then
        gOmodScratchFn.Add(fnEntry);
    end;

    if OmodValueTypeIsVP(valueType) then begin
      link := OmodPropObjectLink(prop);
      floatVal := OmodPropFloatValue(prop);
      if Assigned(link) then begin
        if floatVal <> '' then begin
          vpEntry := MasterFormIDRef(link) + '=' + floatVal;
          vpParts.Add(vpEntry);
        end;
      end;
      Continue;
    end;

    if OmodValueTypeIsForm(valueType) or
       ((Pos('Form', valueType) > 0) and (Pos('Float', valueType) = 0) and
        (Pos('Bool', valueType) = 0)) then begin
      vpEntry := OmodPropFormPairEntry(prop);
      if vpEntry <> '' then
        formParts.Add(vpEntry);
      Continue;
    end;

    propKey := OmodPropertyKeyForExport(propName);
    floatVal := OmodPropFloatValue(prop);
    if floatVal = '' then
      floatVal := OmodPropIntValue(prop);
    if (propKey <> '') and (floatVal <> '') then begin
      floatEntry := propKey + '=' + floatVal;
      floatParts.Add(floatEntry);
    end;
  end;
end;

//============================================================================
function ReadOmodAttachPoint(e: IInterface): string;
begin
  Result := ReadFormLinkPathOrRef(e, 'DATA\Attach Point', 'BNAM');
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
procedure OmodPluginPatchKeysIntoSeen(const patchText: string);
var
  i, eqPos: integer;
  part, key: string;
begin
  if (patchText = '') or (patchText = 'none') then
    Exit;
  SnapEnsureCommaScratch;
  gSnapCommaScratch.StrictDelimiter := True;
  gSnapCommaScratch.Delimiter := ',';
  gSnapCommaScratch.DelimitedText := patchText;
  for i := 0 to Pred(gSnapCommaScratch.Count) do begin
    part := gSnapCommaScratch[i];
    if part = '' then
      Continue;
    eqPos := Pos('=', part);
    if eqPos > 0 then
      key := Copy(part, 1, eqPos - 1)
    else
      key := part;
    if gSnapRefSeenScratch.IndexOf(key) < 0 then
      gSnapRefSeenScratch.Add(key);
  end;
end;

//============================================================================
procedure OmodCollectMasterRemoveKeys(masterParts, outParts: TStringList);
var
  i, eqPos: integer;
  part, leftKey: string;
begin
  if not Assigned(masterParts) then
    Exit;
  if not Assigned(outParts) then
    Exit;
  for i := 0 to Pred(masterParts.Count) do begin
    part := masterParts[i];
    if part = '' then
      Continue;
    eqPos := Pos('=', part);
    if eqPos > 0 then
      leftKey := Copy(part, 1, eqPos - 1)
    else
      leftKey := part;
    if leftKey = '' then
      Continue;
    if gSnapRefSeenScratch.IndexOf(leftKey) >= 0 then
      Continue;
    if outParts.IndexOf(leftKey) < 0 then
      outParts.Add(leftKey);
  end;
end;

//============================================================================
procedure GatherOmodPropertyExtras(e, master: IInterface;
  const pluginFloatText, pluginVpText, pluginFormText: string);
var
  floatRem, vpRem, formRem: string;
begin
  gOmodPatchChangeOModFunctionType := 'none';
  gOmodPatchRemoveOModProperties := 'none';
  gOmodPatchRemoveOModPropertiesVP := 'none';
  gOmodPatchRemoveOModPropertiesForm := 'none';
  if not Assigned(master) then
    Exit;

  gOmodPatchChangeOModFunctionType := ExportFieldIfChanged(e,
    NoneIfEmpty(JoinParts(gOmodScratchFn)), 'none');

  SnapEnsureRefSeenScratch;
  OmodPluginPatchKeysIntoSeen(pluginFloatText);
  OmodPluginPatchKeysIntoSeen(pluginVpText);
  OmodPluginPatchKeysIntoSeen(pluginFormText);
  SnapEnsureCommaScratch;
  SnapEnsurePartsScratch;
  OmodCollectMasterRemoveKeys(gOmodScratchMasterFloat, gSnapCommaScratch);
  OmodCollectMasterRemoveKeys(gOmodScratchMasterVp, gSnapCommaScratch2);
  OmodCollectMasterRemoveKeys(gOmodScratchMasterForm, gSnapPartsScratch);
  floatRem := NoneIfEmpty(JoinParts(gSnapCommaScratch));
  vpRem := NoneIfEmpty(JoinParts(gSnapCommaScratch2));
  formRem := NoneIfEmpty(JoinParts(gSnapPartsScratch));
  gOmodPatchRemoveOModProperties := ExportFieldIfChanged(e, floatRem, 'none');
  gOmodPatchRemoveOModPropertiesVP := ExportFieldIfChanged(e, vpRem, 'none');
  gOmodPatchRemoveOModPropertiesForm := ExportFieldIfChanged(e, formRem, 'none');
end;

//============================================================================
function OmodHasProperties(e: IInterface): boolean;
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
procedure SnapStashOmodHeader(e, master: IInterface; const plainName, masterPlainName,
  attach, masterAttach, appr, masterAppr: string);
begin
  gSnapOmodHeaderStashed := True;
  gSnapOmodPlainName := plainName;
  gSnapMasterOmodPlainName := masterPlainName;
  gSnapOmodAttach := attach;
  gSnapMasterOmodAttach := masterAttach;
  gSnapOmodApprKw := appr;
  gSnapMasterOmodApprKw := masterAppr;
end;

//============================================================================
function OmodHeaderUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  attach, masterAttach, appr, masterAppr, plainName, masterPlainName: string;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  plainName := ReadPlainFullName(e);
  masterPlainName := ReadPlainFullName(master);
  if plainName <> masterPlainName then
    Exit;
  attach := ReadOmodAttachPoint(e);
  masterAttach := ReadOmodAttachPoint(master);
  if attach <> masterAttach then
    Exit;
  appr := EffectiveApprKeywordRefs(e);
  masterAppr := EffectiveApprKeywordRefs(master);
  if not ListFieldUnchangedVsMaster(e, appr, masterAppr) then
    Exit;
  SnapStashOmodHeader(e, master, plainName, masterPlainName, attach, masterAttach, appr, masterAppr);
  Result := True;
end;

//============================================================================
function OmodExportFieldsUnchangedVsMaster(e: IInterface): boolean;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  if not OmodHeaderUnchangedVsMaster(e) then
    Exit;
  if OmodHasProperties(e) then
    Exit;
  Result := True;
end;

//============================================================================
procedure ReadOmodPatchInputs(e: IInterface);
begin
  SnapReadMasterIfAny(e);
  if gSnapOmodHeaderStashed then
    Exit;
  gSnapOmodPlainName := ReadPlainFullName(e);
  gSnapOmodAttach := ReadOmodAttachPoint(e);
  gSnapMasterOmodPlainName := '';
  gSnapMasterOmodAttach := '';
  gSnapOmodApprKw := '';
  gSnapMasterOmodApprKw := '';
  if Assigned(gSnapMaster) then begin
    gSnapMasterOmodPlainName := ReadPlainFullName(gSnapMaster);
    gSnapMasterOmodAttach := ReadOmodAttachPoint(gSnapMaster);
    if SnapApprKwSubgraphConflictFree(e, gSnapMaster) then begin
      gSnapOmodApprKw := SnapCacheApprKw(gSnapMaster);
      gSnapMasterOmodApprKw := gSnapOmodApprKw;
    end else begin
      gSnapOmodApprKw := ReadApprKeywordRefs(e);
      gSnapMasterOmodApprKw := SnapCacheApprKw(gSnapMaster);
    end;
  end else
    gSnapOmodApprKw := ReadApprKeywordRefs(e);
end;

//============================================================================
function OmodFieldsUnchangedFromScratch(e: IInterface): boolean;
begin
  Result := False;
  if not Assigned(gSnapMaster) then
    Exit;
  if gSnapOmodPlainName <> gSnapMasterOmodPlainName then
    Exit;
  if gSnapOmodAttach <> gSnapMasterOmodAttach then
    Exit;
  if not RefListDiffUnchangedVsMaster(gSnapOmodApprKw, gSnapMasterOmodApprKw) then
    Exit;
  if OmodHasProperties(e) then
    Exit;
  Result := True;
end;

//============================================================================
procedure GatherOmodPatchDataFromScratch(e: IInterface);
var
  headerUnchanged, skipMasterProps: boolean;
begin
  InitOMODPatchData;

  gOmodPatchFilterByOMod := PatchFilterFormIDRef(e);
  gOmodPatchFullName := ExportFieldIfChanged(e, gSnapOmodPlainName, gSnapMasterOmodPlainName);
  gOmodPatchSetAttachPoint := ExportFieldIfChanged(e, gSnapOmodAttach, gSnapMasterOmodAttach);
  ApplyApprKeywordDiffIfItmGate(e, gSnapOmodApprKw, gSnapMasterOmodApprKw,
    gOmodPatchAttachParentSlotKeywordsToAdd, gOmodPatchAttachParentSlotKeywordsToRemove);

  headerUnchanged := False;
  if ItmGateExternalOverride(e) then
    headerUnchanged := OmodFieldsUnchangedFromScratch(e);
  if headerUnchanged then begin
    if not OmodHasProperties(e) then
      Exit;
  end;

  OmodEnsurePropListScratch;
  GatherOmodProperties(e, gOmodScratchFloat, gOmodScratchVp, gOmodScratchForm);
  skipMasterProps := False;
  if RecordHasExternalMaster(e) then begin
    if headerUnchanged then begin
      if gOmodScratchFloat.Count = 0 then begin
        if gOmodScratchVp.Count = 0 then begin
          if gOmodScratchForm.Count = 0 then
            skipMasterProps := True;
        end;
      end;
    end;
    if not skipMasterProps then
      GatherOmodProperties(gSnapMaster, gOmodScratchMasterFloat,
        gOmodScratchMasterVp, gOmodScratchMasterForm);
  end;
  gOmodPatchChangeOModPropertiesFloat := ExportListFieldIfChanged(e,
    JoinParts(gOmodScratchFloat), JoinParts(gOmodScratchMasterFloat));
  gOmodPatchChangeOModPropertiesVP := ExportListFieldIfChanged(e,
    JoinParts(gOmodScratchVp), JoinParts(gOmodScratchMasterVp));
  gOmodPatchChangeOModPropertiesForm := ExportListFieldIfChanged(e,
    JoinParts(gOmodScratchForm), JoinParts(gOmodScratchMasterForm));
  if RecordHasExternalMaster(e) then
    GatherOmodPropertyExtras(e, gSnapMaster,
      gOmodPatchChangeOModPropertiesFloat, gOmodPatchChangeOModPropertiesVP,
      gOmodPatchChangeOModPropertiesForm);
end;

//============================================================================
procedure InitOMODPatchData;
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
  InitOMODPatchData;

  gOmodPatchFilterByOMod := PatchFilterFormIDRef(e);
  gOmodPatchFullName := PlainFullNameIfChanged(e);
  masterAttach := '';
  masterAppr := '';
  if RecordHasExternalMaster(e) then begin
    masterAttach := ReadOmodAttachPoint(CompareBaselineRecord(e));
    masterAppr := EffectiveApprKeywordRefs(CompareBaselineRecord(e));
  end;
  gOmodPatchSetAttachPoint := ExportFieldIfChanged(e, ReadOmodAttachPoint(e), masterAttach);
  apprKeywords := EffectiveApprKeywordRefs(e);
  ApplyApprKeywordDiffIfItmGate(e, apprKeywords, masterAppr,
    gOmodPatchAttachParentSlotKeywordsToAdd, gOmodPatchAttachParentSlotKeywordsToRemove);

  headerUnchanged := False;
  if ItmGateExternalOverride(e) then
    headerUnchanged := OmodHeaderUnchangedVsMaster(e);
  if headerUnchanged then begin
    if not OmodHasProperties(e) then
      Exit;
  end;

  OmodEnsurePropListScratch;
  GatherOmodProperties(e, gOmodScratchFloat, gOmodScratchVp, gOmodScratchForm);
  skipMasterProps := False;
  if RecordHasExternalMaster(e) then begin
    if headerUnchanged then begin
      if gOmodScratchFloat.Count = 0 then begin
        if gOmodScratchVp.Count = 0 then begin
          if gOmodScratchForm.Count = 0 then
            skipMasterProps := True;
        end;
      end;
    end;
    if not skipMasterProps then
      GatherOmodProperties(CompareBaselineRecord(e), gOmodScratchMasterFloat,
        gOmodScratchMasterVp, gOmodScratchMasterForm);
  end;
  gOmodPatchChangeOModPropertiesFloat := ExportListFieldIfChanged(e,
    JoinParts(gOmodScratchFloat), JoinParts(gOmodScratchMasterFloat));
  gOmodPatchChangeOModPropertiesVP := ExportListFieldIfChanged(e,
    JoinParts(gOmodScratchVp), JoinParts(gOmodScratchMasterVp));
  gOmodPatchChangeOModPropertiesForm := ExportListFieldIfChanged(e,
    JoinParts(gOmodScratchForm), JoinParts(gOmodScratchMasterForm));
  if RecordHasExternalMaster(e) then
    GatherOmodPropertyExtras(e, CompareBaselineRecord(e),
      gOmodPatchChangeOModPropertiesFloat, gOmodPatchChangeOModPropertiesVP,
      gOmodPatchChangeOModPropertiesForm);
end;

//============================================================================
function BuildOMODLine: string;
begin
  Result := '';
  Result := AppendPatchField(Result, 'filterByOMod', gOmodPatchFilterByOMod);
  Result := AppendAuthoringBatchField(Result, 'connectionAnd', gOmodPatchConnectionAnd);
  Result := AppendAuthoringBatchField(Result, 'filterByOModExcluded', gOmodPatchFilterByOModExcluded);
  Result := AppendAuthoringBatchField(Result, 'filterByFormType', gOmodPatchFilterByFormType);
  Result := AppendAuthoringBatchField(Result, 'filterByNameContainsAnd', gOmodPatchFilterByNameContainsAnd);
  Result := AppendAuthoringBatchField(Result, 'filterByNameContainsOr', gOmodPatchFilterByNameContainsOr);
  Result := AppendAuthoringBatchField(Result, 'filterByNameContainsExclude',
    gOmodPatchFilterByNameContainsExclude);
  Result := AppendAuthoringBatchField(Result, 'filterByPropertiesAnd', gOmodPatchFilterByPropertiesAnd);
  Result := AppendAuthoringBatchField(Result, 'filterByPropertiesOr', gOmodPatchFilterByPropertiesOr);
  Result := AppendAuthoringBatchField(Result, 'filterByPropertiesExclude',
    gOmodPatchFilterByPropertiesExclude);
  Result := AppendAuthoringBatchField(Result, 'filterByAttachPoint', gOmodPatchFilterByAttachPoint);

  Result := AppendField(Result, 'fullName', gOmodPatchFullName, False);
  Result := AppendField(Result, 'setAttachPoint', gOmodPatchSetAttachPoint, False);
  Result := AppendField(Result, 'attachParentSlotKeywordsToAdd',
    gOmodPatchAttachParentSlotKeywordsToAdd, False);
  Result := AppendField(Result, 'attachParentSlotKeywordsToRemove',
    gOmodPatchAttachParentSlotKeywordsToRemove, True);
  Result := AppendField(Result, 'changeOModPropertiesFloat',
    gOmodPatchChangeOModPropertiesFloat, False);
  Result := AppendField(Result, 'changeOModPropertiesVP',
    gOmodPatchChangeOModPropertiesVP, False);
  Result := AppendField(Result, 'changeOModPropertiesForm',
    gOmodPatchChangeOModPropertiesForm, False);
  Result := AppendField(Result, 'changeOModFunctionType',
    gOmodPatchChangeOModFunctionType, True);
  Result := AppendField(Result, 'removeOModProperties',
    gOmodPatchRemoveOModProperties, True);
  Result := AppendField(Result, 'removeOModPropertiesVP',
    gOmodPatchRemoveOModPropertiesVP, True);
  Result := AppendField(Result, 'removeOModPropertiesForm',
    gOmodPatchRemoveOModPropertiesForm, True);
end;

//============================================================================
procedure ExportOMOD(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
var
  line: string;
begin
  if Signature(e) <> 'OMOD' then
    Exit;

  gSnapOmodHeaderStashed := False;

  if SnapshotUseItmGate then begin
    if SnapTryEarlyPregatherSkipOmod(e) then begin
      SnapRecordEarlyPregatherSkip('ExportOMOD');
      Exit;
    end;
  end;

  ReadOmodPatchInputs(e);
  if SnapshotUseItmGate then begin
    if OmodFieldsUnchangedFromScratch(e) then begin
      SnapRecordEarlyPregatherSkip('ExportOMOD');
      Exit;
    end;
  end;

  GatherOmodPatchDataFromScratch(e);
  line := BuildOMODLine;
  EmitSnapshotRecord(e, 'OMOD', shortComment, line);
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

function BoolFlag(flags, mask: integer): string;

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

      SnapRefPartsAddUnique(MasterFormIDRef(link));

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

  SnapEnsureRefPartsScratch;

  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin

    if ElementExists(e, 'SPLO') then

      for i := 0 to Pred(ElementCount(ElementBySignature(e, 'SPLO'))) do begin

        spell := LinksTo(ElementByIndex(ElementBySignature(e, 'SPLO'), i));

        if Assigned(spell) then begin

          refKey := MasterFormIDRef(spell);

          SnapRefPartsAddUnique(refKey);

        end;

      end;

  end else begin

    elem := ElementByName(e, 'Actor Effects');

    if Assigned(elem) then

      CollectSpellFormIDs(elem, gSnapRefPartsScratch);

    if ElementExists(e, 'SPLO') then

      for i := 0 to Pred(ElementCount(ElementBySignature(e, 'SPLO'))) do begin

        spell := LinksTo(ElementByIndex(ElementBySignature(e, 'SPLO'), i));

        if Assigned(spell) then begin

          refKey := MasterFormIDRef(spell);

          SnapRefPartsAddUnique(refKey);

        end;

      end;

  end;

  Result := JoinParts(gSnapRefPartsScratch);

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

  SnapEnsureRefPartsScratch;

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

    refKey := MasterFormIDRef(link);

    SnapRefPartsAddUnique(refKey);

  end;

  Result := JoinParts(gSnapRefPartsScratch);

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

  SnapEnsureRefPartsScratch;

  for i := 0 to Pred(ElementCount(ents)) do begin

    ent := ElementByIndex(ents, i);

    faction := LinksTo(ElementByName(ent, 'Faction'));

    if not Assigned(faction) then

      Continue;

    rank := Round(GetElementNativeValues(ent, 'Rank'));

    gSnapRefPartsScratch.Add(MasterFormIDRef(faction) + '=' + IntToStr(rank));

  end;

  Result := JoinParts(gSnapRefPartsScratch);

end;



//============================================================================

function NpcItemPath: string;
begin
  if gSnapCachedNpcItemPath <> '' then begin
    Result := gSnapCachedNpcItemPath;
    Exit;
  end;
  if wbGameMode = gmTES4 then
    gSnapCachedNpcItemPath := 'Item'
  else
    gSnapCachedNpcItemPath := 'CNTO\Item';
  Result := gSnapCachedNpcItemPath;
end;

//============================================================================
function NpcItemCountPath: string;
begin
  if gSnapCachedNpcItemCountPath <> '' then begin
    Result := gSnapCachedNpcItemCountPath;
    Exit;
  end;
  if wbGameMode = gmTES4 then
    gSnapCachedNpcItemCountPath := 'Count'
  else
    gSnapCachedNpcItemCountPath := 'CNTO\Count';
  Result := gSnapCachedNpcItemCountPath;
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

  SnapEnsureRefPartsScratch;

  for i := 0 to Pred(ElementCount(items)) do begin

    item := ElementByIndex(items, i);

    ref := LinksTo(ElementByPath(item, NpcItemPath));

    if not Assigned(ref) then

      Continue;

    count := Round(GetElementNativeValues(item, NpcItemCountPath));

    if count <= 0 then

      count := 1;

    gSnapRefPartsScratch.Add(MasterFormIDRef(ref) + '=' + IntToStr(count));

  end;

  Result := JoinParts(gSnapRefPartsScratch);

end;



//============================================================================

function ReadDeathItemRef(e: IInterface): string;

var

  link: IInterface;

begin

  Result := '';

  link := LinksTo(ElementBySignature(e, 'INAM'));

  if Assigned(link) then

    Result := MasterFormIDRef(link);

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

  gNpcPatchAutoCalcStats := BoolFlag(flags, ACBS_AutoCalcStats);

  gNpcPatchSetPcLevelMult := BoolFlag(flags, ACBS_PCLevelMult);

  gNpcPatchSetEssential := BoolFlag(flags, ACBS_Essential);



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

  autoCalc := BoolFlag(flags, ACBS_AutoCalcStats);

  pcLevelMult := BoolFlag(flags, ACBS_PCLevelMult);

  essential := BoolFlag(flags, ACBS_Essential);



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

procedure SnapReadAcbsToScratch(e: IInterface);

begin

  ReadACBSFieldStrings(e, gSnapAcbsAutoCalc, gSnapAcbsPcLevelMult, gSnapAcbsEssential,

    gSnapAcbsLevel, gSnapAcbsCalcMin, gSnapAcbsCalcMax);

  gSnapMasterAcbsAutoCalc := 'none';

  gSnapMasterAcbsPcLevelMult := 'none';

  gSnapMasterAcbsEssential := 'none';

  gSnapMasterAcbsLevel := '';

  gSnapMasterAcbsCalcMin := '';

  gSnapMasterAcbsCalcMax := '';

  if not Assigned(gSnapMaster) then
    Exit;
  if (gSnapRaceSubgraphMask and 16) <> 0 then begin
    gSnapMasterAcbsAutoCalc := gSnapAcbsAutoCalc;
    gSnapMasterAcbsPcLevelMult := gSnapAcbsPcLevelMult;
    gSnapMasterAcbsEssential := gSnapAcbsEssential;
    gSnapMasterAcbsLevel := gSnapAcbsLevel;
    gSnapMasterAcbsCalcMin := gSnapAcbsCalcMin;
    gSnapMasterAcbsCalcMax := gSnapAcbsCalcMax;
    Exit;
  end;
  if SubElementConflictFreeByName(e, gSnapMaster, 'ACBS') then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 16;
    gSnapMasterAcbsAutoCalc := gSnapAcbsAutoCalc;
    gSnapMasterAcbsPcLevelMult := gSnapAcbsPcLevelMult;
    gSnapMasterAcbsEssential := gSnapAcbsEssential;
    gSnapMasterAcbsLevel := gSnapAcbsLevel;
    gSnapMasterAcbsCalcMin := gSnapAcbsCalcMin;
    gSnapMasterAcbsCalcMax := gSnapAcbsCalcMax;
  end else
    ReadACBSFieldStrings(gSnapMaster, gSnapMasterAcbsAutoCalc, gSnapMasterAcbsPcLevelMult,
      gSnapMasterAcbsEssential, gSnapMasterAcbsLevel, gSnapMasterAcbsCalcMin,
      gSnapMasterAcbsCalcMax);

end;



//============================================================================

function AcbsFieldsUnchangedFromScratch: boolean;

begin

  Result := False;

  if not Assigned(gSnapMaster) then

    Exit;

  if not ScalarUnchangedVsMaster(gSnapAcbsAutoCalc, gSnapMasterAcbsAutoCalc) then

    Exit;

  if not ScalarUnchangedVsMaster(gSnapAcbsPcLevelMult, gSnapMasterAcbsPcLevelMult) then

    Exit;

  if not ScalarUnchangedVsMaster(gSnapAcbsEssential, gSnapMasterAcbsEssential) then

    Exit;

  if not ScalarUnchangedVsMaster(gSnapAcbsLevel, gSnapMasterAcbsLevel) then

    Exit;

  if not ScalarUnchangedVsMaster(gSnapAcbsCalcMin, gSnapMasterAcbsCalcMin) then

    Exit;

  if not ScalarUnchangedVsMaster(gSnapAcbsCalcMax, gSnapMasterAcbsCalcMax) then

    Exit;

  Result := True;

end;



//============================================================================

procedure ApplyAcbsPatchDiffFromScratch(e: IInterface);

begin

  if not SnapshotUseItmGate then

    Exit;

  if not Assigned(gSnapMaster) then

    Exit;

  gNpcPatchAutoCalcStats := ExportFieldIfChanged(e, gSnapAcbsAutoCalc, gSnapMasterAcbsAutoCalc);

  gNpcPatchSetPcLevelMult := ExportFieldIfChanged(e, gSnapAcbsPcLevelMult, gSnapMasterAcbsPcLevelMult);

  gNpcPatchSetEssential := ExportFieldIfChanged(e, gSnapAcbsEssential, gSnapMasterAcbsEssential);

  gNpcPatchLevel := ExportFieldIfChanged(e, gSnapAcbsLevel, gSnapMasterAcbsLevel);

  gNpcPatchCalcLevelMin := ExportFieldIfChanged(e, gSnapAcbsCalcMin, gSnapMasterAcbsCalcMin);

  gNpcPatchCalcLevelMax := ExportFieldIfChanged(e, gSnapAcbsCalcMax, gSnapMasterAcbsCalcMax);

end;



//============================================================================

function AcbsFieldsUnchangedVsMaster(e, master: IInterface): boolean;

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

  if not ScalarUnchangedVsMaster(pAutoCalc, mAutoCalc) then

    Exit;

  if not ScalarUnchangedVsMaster(pPcLevelMult, mPcLevelMult) then

    Exit;

  if not ScalarUnchangedVsMaster(pEssential, mEssential) then

    Exit;

  if not ScalarUnchangedVsMaster(pLevel, mLevel) then

    Exit;

  if not ScalarUnchangedVsMaster(pCalcMin, mCalcMin) then

    Exit;

  if not ScalarUnchangedVsMaster(pCalcMax, mCalcMax) then

    Exit;

  Result := True;

end;



//============================================================================

procedure ApplyAcbsPatchDiffIfItmGate(e, master: IInterface);

var

  pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax: string;

  mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax: string;

begin

  if not SnapshotUseItmGate then

    Exit;

  if not Assigned(master) then

    Exit;

  ReadACBSFieldStrings(e, pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax);

  ReadACBSFieldStrings(master, mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax);

  gNpcPatchAutoCalcStats := ExportFieldIfChanged(e, pAutoCalc, mAutoCalc);

  gNpcPatchSetPcLevelMult := ExportFieldIfChanged(e, pPcLevelMult, mPcLevelMult);

  gNpcPatchSetEssential := ExportFieldIfChanged(e, pEssential, mEssential);

  gNpcPatchLevel := ExportFieldIfChanged(e, pLevel, mLevel);

  gNpcPatchCalcLevelMin := ExportFieldIfChanged(e, pCalcMin, mCalcMin);

  gNpcPatchCalcLevelMax := ExportFieldIfChanged(e, pCalcMax, mCalcMax);

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



    parts.Add(MasterFormIDRef(link) + '=' + valStr);

  end;

end;



//============================================================================

function ReadSkyrimAVIFS(e: IInterface): string;

var
  health, magicka, stamina: integer;
begin
  Result := 'none';
  SnapEnsurePartsScratch;

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

      gSnapPartsScratch.Add('Skyrim.esm|3E8=' + IntToStr(health));

    if magicka > 0 then

      gSnapPartsScratch.Add('Skyrim.esm|3FC=' + IntToStr(magicka));

    if stamina > 0 then

      gSnapPartsScratch.Add('Skyrim.esm|3F2=' + IntToStr(stamina));



    if gSnapPartsScratch.Count = 0 then begin

      if not bLoggedSkyrimAVSkip then begin

        QueueExportLog('RobCo NPC: no mappable Skyrim actor values on ' + Name(e) + '; using changeAVIFS=none.');

        bLoggedSkyrimAVSkip := True;

      end;

      Exit;

    end;



    Result := JoinParts(gSnapPartsScratch);

end;



//============================================================================
procedure SnapEnsureRacePropertiesResolved(e: IInterface);
var
  formId: cardinal;
  topCount, actorCount: integer;
begin
  if not Assigned(e) then begin
    gSnapRacePropsFormId := 0;
    gSnapRacePropsTop := nil;
    gSnapRacePropsActor := nil;
    gSnapRacePropsCount := 0;
    Exit;
  end;
  formId := GetLoadOrderFormID(e);
  if gSnapRacePropsFormId = formId then
    Exit;
  gSnapRacePropsFormId := formId;
  gSnapRacePropsTop := ElementByPath(e, 'Properties');
  gSnapRacePropsActor := ElementByPath(e, 'Actor Data\Properties');
  topCount := 0;
  actorCount := 0;
  if Assigned(gSnapRacePropsTop) then
    topCount := ElementCount(gSnapRacePropsTop);
  if Assigned(gSnapRacePropsActor) then
    actorCount := ElementCount(gSnapRacePropsActor);
  gSnapRacePropsCount := topCount + actorCount;
end;

//============================================================================

function ReadFO4AVIFS(e: IInterface): string;
begin
  Result := 'none';
  SnapEnsureRacePropertiesResolved(e);
  if gSnapRacePropsCount = 0 then
    Exit;
  SnapEnsurePartsScratch;
  if Assigned(gSnapRacePropsTop) then
    AppendAVIFFromProperties(gSnapRacePropsTop, gSnapPartsScratch);
  if gSnapPartsScratch.Count = 0 then begin
    if Assigned(gSnapRacePropsActor) then
      AppendAVIFFromProperties(gSnapRacePropsActor, gSnapPartsScratch);
  end;
  if gSnapPartsScratch.Count = 0 then
    Exit;
  Result := JoinParts(gSnapPartsScratch);
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
  SnapEnsureCommaScratch;
  ParseCommaList(gSnapCommaScratch, listText);
  for i := 0 to Pred(gSnapCommaScratch.Count) do begin
    entry := Trim(gSnapCommaScratch[i]);
    if entry = '' then
      Continue;
    eqPos := Pos('=', entry);
    if eqPos > 0 then
      refKey := Copy(entry, 1, eqPos - 1)
    else
      refKey := entry;
    if gSnapCommaScratch2.IndexOf(refKey) < 0 then
      gSnapCommaScratch2.Add(refKey);
  end;
  Result := NoneIfEmpty(JoinParts(gSnapCommaScratch2));
end;



//============================================================================

procedure InitNPCPatchData;

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
procedure SnapInitRacePatchOutput;
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

  InitNPCPatchData;



  keywords := ReadKeywordRefsFromElement(e);

  perks := ReadPerkRefs(e);

  spells := ReadSpellRefs(e);



  master := nil;

  masterPerks := '';

  masterSpells := '';

  masterChangeAvif := 'none';

  if RecordHasExternalMaster(e) then begin

    master := CompareBaselineRecord(e);

    masterPerks := ReadPerkRefs(master);

    masterSpells := ReadSpellRefs(master);

    masterChangeAvif := ReadChangeAVIFS(master);

  end;



  changeAvif := ReadChangeAVIFS(e);

  gNpcPatchChangeAVIFS := ExportFieldIfChanged(e, changeAvif, masterChangeAvif);

  if Assigned(master) then
    ApplyRefListDiffIfItmGate(e, ReadRaceSpellAndPerkRefs(e),
      ReadRaceSpellAndPerkRefs(master), gNpcPatchSpellsToAdd, spellsRem)
  else
    ApplyRefListDiffIfItmGate(e, ReadRaceSpellAndPerkRefs(e), '',
      gNpcPatchSpellsToAdd, spellsRem);

  gNpcPatchFilterByRaces := PatchFilterFormIDRef(e);

  // Keywords on RACE lines are operations (keywordsToAdd/Remove), not filterByKeywords.
  gNpcPatchFilterByKeywords := 'none';

  ApplyKeywordDiffIfItmGate(e, keywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

end;



//============================================================================

function RaceFieldsUnchangedVsMaster(e: IInterface): boolean;

var

  master: IInterface;

  changeAvif, masterChangeAvif: string;

begin

  Result := False;

  if not RecordHasExternalMaster(e) then

    Exit;

  master := CompareBaselineRecord(e);

  if not KeywordRefsUnchangedVsMaster(e) then

    Exit;

  if not RefListDiffUnchangedVsMaster(ReadPerkRefs(e), ReadPerkRefs(master)) then

    Exit;

  if not RefListDiffUnchangedVsMaster(ReadSpellRefs(e), ReadSpellRefs(master)) then

    Exit;

  changeAvif := ReadChangeAVIFS(e);

  masterChangeAvif := ReadChangeAVIFS(master);

  if changeAvif <> masterChangeAvif then

    Exit;

  if not AcbsFieldsUnchangedVsMaster(e, master) then

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

  InitNPCPatchData;



  keywords := ReadKeywordRefsFromElement(e);

  perks := ReadPerkRefs(e);

  spells := ReadSpellRefs(e);

  factions := ReadFactionRefs(e);

  inventory := ReadInventoryRefs(e);

  fullNameVal := ReadFullName(e);

  deathItemVal := ReadDeathItemRef(e);

  raceRef := ReadFormLinkRef(e, 'RNAM');

  classRef := ReadFormLinkRef(e, 'CNAM');



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

  if RecordHasExternalMaster(e) then begin

    master := CompareBaselineRecord(e);

    masterFullName := ReadFullName(master);

    masterPerks := ReadPerkRefs(master);

    masterSpells := ReadSpellRefs(master);

    masterFactions := ReadFactionRefs(master);

    masterInventory := ReadInventoryRefs(master);

    masterChangeAvif := ReadChangeAVIFS(master);

    masterDeathItem := ReadDeathItemRef(master);

    masterRace := ReadFormLinkRef(master, 'RNAM');

    masterClass := ReadFormLinkRef(master, 'CNAM');

  end;



  changeAvif := ReadChangeAVIFS(e);

  gNpcPatchChangeAVIFS := ExportFieldIfChanged(e, changeAvif, masterChangeAvif);

  ApplyRefListDiffIfItmGate(e, perks, masterPerks, gNpcPatchPerksToAdd, perksRem);

  ApplyRefListDiffIfItmGate(e, spells, masterSpells, gNpcPatchSpellsToAdd, spellsRem);

  ApplyRefListDiffIfItmGate(e, factions, masterFactions, gNpcPatchFactionsToAdd, factionsRem);

  ApplyRefListDiffIfItmGate(e, inventory, masterInventory, gNpcPatchObjectsToAdd, objectsRem);

  gNpcPatchFactionsToRemove := NpcStripRankSuffixFromRefList(factionsRem);

  gNpcPatchObjectsToRemove := NpcStripRankSuffixFromRefList(objectsRem);



  gNpcPatchFilterByNpcs := PatchFilterFormIDRef(e);

  ApplyKeywordDiffIfItmGate(e, keywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

  gNpcPatchFullName := ExportFieldIfChanged(e, fullNameVal, masterFullName);

  if (deathItemVal = '') and (masterDeathItem <> '') then
    gNpcPatchDeathItem := 'null'
  else
    gNpcPatchDeathItem := ExportFieldIfChanged(e, deathItemVal, masterDeathItem);

  gNpcPatchRace := ExportFieldIfChanged(e, raceRef, masterRace);

  gNpcPatchClassOp := ExportFieldIfChanged(e, classRef, masterClass);

  if Assigned(master) then begin
    if SnapshotUseItmGate then
      ApplyAcbsPatchDiffIfItmGate(e, master)
    else
      ReadACBSFields(e);
  end else
    ReadACBSFields(e);

  if Assigned(master) then begin
    gNpcPatchSkin := ExportFieldIfChanged(e, NoneIfEmpty(ReadNpcSkinRef(e)),
      NoneIfEmpty(ReadNpcSkinRef(master)));
    gNpcPatchPowerArmorStand := ExportFieldIfChanged(e,
      NoneIfEmpty(ReadNpcPowerArmorStandRef(e)),
      NoneIfEmpty(ReadNpcPowerArmorStandRef(master)));
    gNpcPatchXpValueOffset := NpcXpValueOffsetExportVal(ReadNpcXpValueOffset(e),
      ReadNpcXpValueOffset(master));
  end;

end;



//============================================================================

function BuildNPCLine: string;

begin

  Result := '';

  Result := AppendPatchField(Result, 'filterByNpcs', gNpcPatchFilterByNpcs);

  Result := AppendAuthoringBatchField(Result, 'filterByNpcsExcluded', gNpcPatchFilterByNpcsExcluded);

  Result := AppendAuthoringBatchField(Result, 'filterByRaces', gNpcPatchFilterByRaces);

  Result := AppendAuthoringBatchField(Result, 'filterByRacesExcluded', gNpcPatchFilterByRacesExcluded);

  Result := AppendAuthoringBatchField(Result, 'filterByKeywords', gNpcPatchFilterByKeywords);

  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsOr', gNpcPatchFilterByKeywordsOr);

  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gNpcPatchFilterByKeywordsExcluded);

  Result := AppendAuthoringBatchField(Result, 'filterByFactions', gNpcPatchFilterByFactions);

  Result := AppendAuthoringBatchField(Result, 'filterByFactionsOr', gNpcPatchFilterByFactionsOr);

  Result := AppendAuthoringBatchField(Result, 'filterByFactionsExcluded', gNpcPatchFilterByFactionsExcluded);

  Result := AppendAuthoringBatchField(Result, 'filterByClass', gNpcPatchFilterByClass);

  Result := AppendAuthoringBatchField(Result, 'filterByGender', gNpcPatchFilterByGender);

  Result := AppendField(Result, 'changeAVIFS', gNpcPatchChangeAVIFS, True);

  Result := AppendField(Result, 'keywordsToAdd', gNpcPatchKeywordsToAdd, True);

  Result := AppendField(Result, 'keywordsToRemove', gNpcPatchKeywordsToRemove, True);

  Result := AppendField(Result, 'perksToAdd', gNpcPatchPerksToAdd, True);

  Result := AppendField(Result, 'spellsToAdd', gNpcPatchSpellsToAdd, True);

  Result := AppendField(Result, 'factionsToAdd', gNpcPatchFactionsToAdd, False);

  Result := AppendField(Result, 'factionsToRemove', gNpcPatchFactionsToRemove, False);

  Result := AppendField(Result, 'fullName', gNpcPatchFullName, False);

  Result := AppendNumericField(Result, 'autoCalcStats', gNpcPatchAutoCalcStats);

  Result := AppendNumericField(Result, 'setPcLevelMult', gNpcPatchSetPcLevelMult);

  Result := AppendNumericField(Result, 'setEssential', gNpcPatchSetEssential);

  Result := AppendNumericField(Result, 'level', gNpcPatchLevel);

  Result := AppendNumericField(Result, 'calcLevelMin', gNpcPatchCalcLevelMin);

  Result := AppendNumericField(Result, 'calcLevelMax', gNpcPatchCalcLevelMax);

  Result := AppendField(Result, 'deathItem', gNpcPatchDeathItem, False);

  Result := AppendField(Result, 'race', gNpcPatchRace, False);

  Result := AppendField(Result, 'class', gNpcPatchClassOp, False);

  Result := AppendField(Result, 'objectsToAdd', gNpcPatchObjectsToAdd, False);

  Result := AppendField(Result, 'objectsToRemove', gNpcPatchObjectsToRemove, False);

  Result := AppendField(Result, 'skin', gNpcPatchSkin, False);

  Result := AppendField(Result, 'powerArmorStand', gNpcPatchPowerArmorStand, False);

  if not SnapshotUseItmGate then
    Result := AppendNumericField(Result, 'xpValueOffset', gNpcPatchXpValueOffset)
  else if gNpcPatchXpValueOffset <> '' then
    Result := AppendNumericField(Result, 'xpValueOffset', gNpcPatchXpValueOffset);

end;



//============================================================================

function BuildRACELine: string;

begin

  Result := '';

  Result := AppendPatchField(Result, 'filterByRaces', gNpcPatchFilterByRaces);

  Result := AppendAuthoringBatchField(Result, 'filterByRacesExcluded', gNpcPatchFilterByRacesExcluded);

  Result := AppendAuthoringBatchField(Result, 'filterByKeywords', gNpcPatchFilterByKeywords);

  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsOr', gNpcPatchFilterByKeywordsOr);

  Result := AppendAuthoringBatchField(Result, 'filterByKeywordsExcluded', gNpcPatchFilterByKeywordsExcluded);

  Result := AppendField(Result, 'changeAVIFS', gNpcPatchChangeAVIFS, True);

  Result := AppendField(Result, 'keywordsToAdd', gNpcPatchKeywordsToAdd, True);

  Result := AppendField(Result, 'keywordsToRemove', gNpcPatchKeywordsToRemove, True);

  Result := AppendField(Result, 'spellsToAdd', gNpcPatchSpellsToAdd, True);

end;



//============================================================================
// Subgraph conflict gates, master cache, gated scratch reads
//============================================================================

function SnapKeywordsSubgraphConflictFree(e, master: IInterface): boolean;
var
  kwE, kwM: IInterface;
  key: string;
begin
  key := SnapConflictProbeCacheKey(e, master, 'kw');
  if SnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  kwE := GetKeywordsElement(e);
  kwM := GetKeywordsElement(master);
  Result := SubElementConflictFree(kwE, kwM);
  SnapConflictProbeCachePut(key, Result);
end;

//============================================================================
function SnapApprKwSubgraphConflictFree(e, master: IInterface): boolean;
var
  aE, aM: IInterface;
  key: string;
begin
  key := SnapConflictProbeCacheKey(e, master, 'apprkw');
  if SnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  aE := GetApprElement(e);
  aM := GetApprElement(master);
  Result := SubElementConflictFree(aE, aM);
  SnapConflictProbeCachePut(key, Result);
end;

//============================================================================
function SnapCobjCategoryKwSubgraphConflictFree(e, master: IInterface): boolean;
var
  a, b: IInterface;
begin
  a := GetCobjCategoryKeywordsElement(e);
  b := GetCobjCategoryKeywordsElement(master);
  Result := SubElementConflictFree(a, b);
end;

//============================================================================
function SnapSpellsSubgraphConflictFree(e, master: IInterface): boolean;
begin
  Result := False;
  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin
    Result := SubElementConflictFreeBySignature(e, master, 'SPLO');
    Exit;
  end;
  if not SubElementConflictFreeByName(e, master, 'Actor Effects') then
    Exit;
  Result := SubElementConflictFreeBySignature(e, master, 'SPLO');
end;

//============================================================================
function SnapAvifSubgraphConflictFree(e, master: IInterface): boolean;
begin
  Result := False;
  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin
    if not SubElementConflictFreeByPath(e, master, 'NPC Attributes') then
      Exit;
    if not SubElementConflictFreeByPath(e, master, 'Attributes') then
      Exit;
    Result := SubElementConflictFreeByPath(e, master, 'DATA');
    Exit;
  end;
  if SnapRacePropertiesCount(e) = 0 then begin
    if SnapRacePropertiesCount(master) = 0 then begin
      Result := True;
      Exit;
    end;
  end else if SnapRacePropertiesCount(e) <> SnapRacePropertiesCount(master) then
    Exit;
  if not SubElementConflictFreeByName(e, master, 'Properties') then
    Exit;
  Result := SubElementConflictFreeByPath(e, master, 'Actor Data\Properties');
end;

//============================================================================
function SnapCacheKeywords(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'keywords');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadKeywordRefsFromElement(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCachePerks(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'perks');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadPerkRefs(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheSpells(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'spells');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadSpellRefs(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheChangeAvif(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'avif');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadChangeAVIFS(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheFactions(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'factions');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadFactionRefs(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheInventory(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'inventory');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadInventoryRefs(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheApprKw(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'apprkw');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadApprKeywordRefs(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheCobjCategoryKw(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'cobjcatkw');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadCobjCategoryKeywordRefs(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheCobjWorkbench(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'cobjbench');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadWorkbenchKeywordRef(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheAlchMgefs(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'alchmgefs');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadAlchMgefsToAdd(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
procedure SnapReadKeywordsToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := '';
    Exit;
  end;
  if (gSnapRaceSubgraphMask and 1) <> 0 then begin
    gSnapKeywords := SnapCacheKeywords(gSnapMaster);
    gSnapMasterKeywords := gSnapKeywords;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and $100) <> 0 then begin
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := SnapCacheKeywords(gSnapMaster);
    Exit;
  end;
  if SnapKeywordsSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 1;
    gSnapKeywords := SnapCacheKeywords(gSnapMaster);
    gSnapMasterKeywords := gSnapKeywords;
  end else begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $100;
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := SnapCacheKeywords(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapReadPerksToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := '';
    Exit;
  end;
  if (gSnapRaceSubgraphMask and 2) <> 0 then begin
    gSnapPerks := SnapCachePerks(gSnapMaster);
    gSnapMasterPerks := gSnapPerks;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and $200) <> 0 then begin
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := SnapCachePerks(gSnapMaster);
    Exit;
  end;
  if SubElementConflictFreeByName(e, gSnapMaster, 'Perks') then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 2;
    gSnapPerks := SnapCachePerks(gSnapMaster);
    gSnapMasterPerks := gSnapPerks;
  end else begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $200;
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := SnapCachePerks(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapReadSpellsToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := '';
    Exit;
  end;
  if (gSnapRaceSubgraphMask and 4) <> 0 then begin
    gSnapSpells := SnapCacheSpells(gSnapMaster);
    gSnapMasterSpells := gSnapSpells;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and $400) <> 0 then begin
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := SnapCacheSpells(gSnapMaster);
    Exit;
  end;
  if SnapSpellsSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 4;
    gSnapSpells := SnapCacheSpells(gSnapMaster);
    gSnapMasterSpells := gSnapSpells;
  end else begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $400;
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := SnapCacheSpells(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapReadChangeAvifToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapChangeAvif := ReadChangeAVIFS(e);
    gSnapMasterChangeAvif := 'none';
    Exit;
  end;
  if (gSnapRaceSubgraphMask and 8) <> 0 then begin
    gSnapChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapMasterChangeAvif := gSnapChangeAvif;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and $800) <> 0 then begin
    gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
    gSnapMasterChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    Exit;
  end;
  if SnapAvifSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 8;
    gSnapChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapMasterChangeAvif := gSnapChangeAvif;
  end else begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $800;
    gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
    gSnapMasterChangeAvif := SnapCacheChangeAvif(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapStashRaceKeywords(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := '';
    gSnapRaceStashMask := gSnapRaceStashMask or 1;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and 1) <> 0 then begin
    gSnapKeywords := SnapCacheKeywords(gSnapMaster);
    gSnapMasterKeywords := gSnapKeywords;
    gSnapRaceStashMask := gSnapRaceStashMask or 1;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and $100) <> 0 then begin
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := SnapCacheKeywords(gSnapMaster);
    gSnapRaceStashMask := gSnapRaceStashMask or 1;
    Exit;
  end;
  if SnapRaceKeywordsFootprintDiffers(e, gSnapMaster) then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $100;
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := SnapCacheKeywords(gSnapMaster);
  end else if SnapKeywordsSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 1;
    gSnapKeywords := SnapCacheKeywords(gSnapMaster);
    gSnapMasterKeywords := gSnapKeywords;
  end else begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $100;
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := SnapCacheKeywords(gSnapMaster);
  end;
  gSnapRaceStashMask := gSnapRaceStashMask or 1;
end;

//============================================================================
procedure SnapStashRacePerks(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := '';
    gSnapRaceStashMask := gSnapRaceStashMask or 2;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and 2) <> 0 then begin
    gSnapPerks := SnapCachePerks(gSnapMaster);
    gSnapMasterPerks := gSnapPerks;
    gSnapRaceStashMask := gSnapRaceStashMask or 2;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and $200) <> 0 then begin
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := SnapCachePerks(gSnapMaster);
    gSnapRaceStashMask := gSnapRaceStashMask or 2;
    Exit;
  end;
  if (gSnapRaceStashMask and 2) <> 0 then begin
    if (gSnapRaceSubgraphMask and 2) = 0 then begin
      if (gSnapRaceSubgraphMask and $200) = 0 then begin
        if RefListDiffUnchangedVsMaster(
          JoinTwoCommaLists(gSnapPerks, gSnapSpells),
          JoinTwoCommaLists(gSnapMasterPerks, gSnapMasterSpells)) then begin
          gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 2;
          gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 4;
        end else begin
          gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $200;
          gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $400;
        end;
      end;
    end;
    if (gSnapRaceSubgraphMask and 2) <> 0 then begin
      gSnapPerks := SnapCachePerks(gSnapMaster);
      gSnapMasterPerks := gSnapPerks;
      gSnapSpells := SnapCacheSpells(gSnapMaster);
      gSnapMasterSpells := gSnapSpells;
    end;
    gSnapRaceStashMask := gSnapRaceStashMask or 2;
    gSnapRaceStashMask := gSnapRaceStashMask or 4;
    Exit;
  end;
  if (SnapRaceNamedListContainerCount(e, 'Perks') = 0) then begin
    if SnapRaceNamedListContainerCount(gSnapMaster, 'Perks') = 0 then begin
      gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 2;
      gSnapPerks := SnapCachePerks(gSnapMaster);
      gSnapMasterPerks := gSnapPerks;
    end else begin
      gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $200;
      gSnapPerks := ReadPerkRefs(e);
      gSnapMasterPerks := SnapCachePerks(gSnapMaster);
    end;
  end else if SubElementConflictFreeByName(e, gSnapMaster, 'Perks') then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 2;
    gSnapPerks := SnapCachePerks(gSnapMaster);
    gSnapMasterPerks := gSnapPerks;
  end else begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $200;
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := SnapCachePerks(gSnapMaster);
  end;
  gSnapRaceStashMask := gSnapRaceStashMask or 2;
end;

//============================================================================
procedure SnapStashRaceSpells(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := '';
    gSnapRaceStashMask := gSnapRaceStashMask or 4;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and 4) <> 0 then begin
    gSnapSpells := SnapCacheSpells(gSnapMaster);
    gSnapMasterSpells := gSnapSpells;
    gSnapRaceStashMask := gSnapRaceStashMask or 4;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and $400) <> 0 then begin
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := SnapCacheSpells(gSnapMaster);
    gSnapRaceStashMask := gSnapRaceStashMask or 4;
    Exit;
  end;
  if (SnapRaceSpellsFootprintCount(e) = 0) then begin
    if SnapRaceSpellsFootprintCount(gSnapMaster) = 0 then begin
      gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 4;
      gSnapSpells := SnapCacheSpells(gSnapMaster);
      gSnapMasterSpells := gSnapSpells;
    end else begin
      gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $400;
      gSnapSpells := ReadSpellRefs(e);
      gSnapMasterSpells := SnapCacheSpells(gSnapMaster);
    end;
  end else if SnapSpellsSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 4;
    gSnapSpells := SnapCacheSpells(gSnapMaster);
    gSnapMasterSpells := gSnapSpells;
  end else begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $400;
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := SnapCacheSpells(gSnapMaster);
  end;
  gSnapRaceStashMask := gSnapRaceStashMask or 4;
end;

//============================================================================
procedure SnapStashRaceAvif(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapChangeAvif := ReadChangeAVIFS(e);
    gSnapMasterChangeAvif := 'none';
    gSnapRaceStashMask := gSnapRaceStashMask or 8;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and 8) <> 0 then begin
    gSnapChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapMasterChangeAvif := gSnapChangeAvif;
    gSnapRaceStashMask := gSnapRaceStashMask or 8;
    Exit;
  end;
  if (gSnapRaceSubgraphMask and $800) <> 0 then begin
    gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
    gSnapMasterChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapRaceStashMask := gSnapRaceStashMask or 8;
    Exit;
  end;
  if (gSnapRaceStashMask and 8) <> 0 then begin
    if (gSnapRaceSubgraphMask and 8) = 0 then begin
      if (gSnapRaceSubgraphMask and $800) = 0 then begin
        if gSnapChangeAvif = gSnapMasterChangeAvif then
          gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 8
        else
          gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $800;
      end;
    end;
    if (gSnapRaceSubgraphMask and 8) <> 0 then begin
      gSnapChangeAvif := SnapCacheChangeAvif(gSnapMaster);
      gSnapMasterChangeAvif := gSnapChangeAvif;
    end;
    gSnapRaceStashMask := gSnapRaceStashMask or 8;
    Exit;
  end;
  if SnapRacePropertiesCount(e) <> SnapRacePropertiesCount(gSnapMaster) then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $800;
    gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
    gSnapMasterChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapRaceStashMask := gSnapRaceStashMask or 8;
    Exit;
  end;
  if SnapAvifSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or 8;
    gSnapChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapMasterChangeAvif := gSnapChangeAvif;
  end else begin
    gSnapRaceSubgraphMask := gSnapRaceSubgraphMask or $800;
    gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
    gSnapMasterChangeAvif := SnapCacheChangeAvif(gSnapMaster);
  end;
  gSnapRaceStashMask := gSnapRaceStashMask or 8;
end;

//============================================================================
procedure SnapReadFactionsToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapFactions := ReadFactionRefs(e);
    gSnapMasterFactions := '';
    Exit;
  end;
  if SubElementConflictFreeByName(e, gSnapMaster, 'Factions') then begin
    gSnapFactions := SnapCacheFactions(gSnapMaster);
    gSnapMasterFactions := gSnapFactions;
  end else begin
    gSnapFactions := ReadFactionRefs(e);
    gSnapMasterFactions := SnapCacheFactions(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapReadInventoryToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapInventory := ReadInventoryRefs(e);
    gSnapMasterInventory := '';
    Exit;
  end;
  if SubElementConflictFreeByName(e, gSnapMaster, 'Items') then begin
    gSnapInventory := SnapCacheInventory(gSnapMaster);
    gSnapMasterInventory := gSnapInventory;
  end else begin
    gSnapInventory := ReadInventoryRefs(e);
    gSnapMasterInventory := SnapCacheInventory(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapReadApprKwToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapApprKw := EffectiveApprKeywordRefs(e);
    gSnapMasterApprKw := '';
    Exit;
  end;
  if SnapApprKwSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapApprKw := EffectiveApprKeywordRefs(gSnapMaster);
    gSnapMasterApprKw := gSnapApprKw;
  end else begin
    gSnapApprKw := EffectiveApprKeywordRefs(e);
    gSnapMasterApprKw := EffectiveApprKeywordRefs(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapReadCobjCategoryKwToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapCategoryKw := ReadCobjCategoryKeywordRefs(e);
    gSnapMasterCategoryKw := '';
    Exit;
  end;
  if (gSnapCobjSubgraphMask and 1) <> 0 then begin
    gSnapCategoryKw := SnapCacheCobjCategoryKw(gSnapMaster);
    gSnapMasterCategoryKw := gSnapCategoryKw;
    Exit;
  end;
  if (gSnapCobjSubgraphMask and $100) <> 0 then begin
    gSnapCategoryKw := ReadCobjCategoryKeywordRefs(e);
    gSnapMasterCategoryKw := SnapCacheCobjCategoryKw(gSnapMaster);
    Exit;
  end;
  if SnapCobjCategoryKwSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapCobjSubgraphMask := gSnapCobjSubgraphMask or 1;
    gSnapCategoryKw := SnapCacheCobjCategoryKw(gSnapMaster);
    gSnapMasterCategoryKw := gSnapCategoryKw;
  end else begin
    gSnapCobjSubgraphMask := gSnapCobjSubgraphMask or $100;
    gSnapCategoryKw := ReadCobjCategoryKeywordRefs(e);
    gSnapMasterCategoryKw := SnapCacheCobjCategoryKw(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapReadAlchMgefsToScratch(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapMgefs := ReadAlchMgefsToAdd(e);
    gSnapMasterMgefs := '';
    Exit;
  end;
  if SubElementConflictFreeByName(e, gSnapMaster, 'Effects') then begin
    gSnapMgefs := SnapCacheAlchMgefs(gSnapMaster);
    gSnapMasterMgefs := gSnapMgefs;
  end else begin
    gSnapMgefs := ReadAlchMgefsToAdd(e);
    gSnapMasterMgefs := SnapCacheAlchMgefs(gSnapMaster);
  end;
end;

//============================================================================
procedure SnapNpcClearStash;
begin
  gSnapNpcStashMask := 0;
  gSnapNpcSubgraphMask := 0;
end;

//============================================================================
procedure SnapStashNpcKeywords(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := '';
    gSnapNpcStashMask := gSnapNpcStashMask or 1;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and 1) <> 0 then begin
    gSnapKeywords := SnapCacheKeywords(gSnapMaster);
    gSnapMasterKeywords := gSnapKeywords;
    gSnapNpcStashMask := gSnapNpcStashMask or 1;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and $100) <> 0 then begin
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := SnapCacheKeywords(gSnapMaster);
    gSnapNpcStashMask := gSnapNpcStashMask or 1;
    Exit;
  end;
  if SnapKeywordsSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or 1;
    gSnapKeywords := SnapCacheKeywords(gSnapMaster);
    gSnapMasterKeywords := gSnapKeywords;
  end else begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or $100;
    gSnapKeywords := ReadKeywordRefsFromElement(e);
    gSnapMasterKeywords := SnapCacheKeywords(gSnapMaster);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 1;
end;

//============================================================================
procedure SnapStashNpcPerks(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := '';
    gSnapNpcStashMask := gSnapNpcStashMask or 2;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and 2) <> 0 then begin
    gSnapPerks := SnapCachePerks(gSnapMaster);
    gSnapMasterPerks := gSnapPerks;
    gSnapNpcStashMask := gSnapNpcStashMask or 2;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and $200) <> 0 then begin
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := SnapCachePerks(gSnapMaster);
    gSnapNpcStashMask := gSnapNpcStashMask or 2;
    Exit;
  end;
  if SubElementConflictFreeByName(e, gSnapMaster, 'Perks') then begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or 2;
    gSnapPerks := SnapCachePerks(gSnapMaster);
    gSnapMasterPerks := gSnapPerks;
  end else begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or $200;
    gSnapPerks := ReadPerkRefs(e);
    gSnapMasterPerks := SnapCachePerks(gSnapMaster);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 2;
end;

//============================================================================
procedure SnapStashNpcSpells(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := '';
    gSnapNpcStashMask := gSnapNpcStashMask or 4;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and 4) <> 0 then begin
    gSnapSpells := SnapCacheSpells(gSnapMaster);
    gSnapMasterSpells := gSnapSpells;
    gSnapNpcStashMask := gSnapNpcStashMask or 4;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and $400) <> 0 then begin
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := SnapCacheSpells(gSnapMaster);
    gSnapNpcStashMask := gSnapNpcStashMask or 4;
    Exit;
  end;
  if SnapSpellsSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or 4;
    gSnapSpells := SnapCacheSpells(gSnapMaster);
    gSnapMasterSpells := gSnapSpells;
  end else begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or $400;
    gSnapSpells := ReadSpellRefs(e);
    gSnapMasterSpells := SnapCacheSpells(gSnapMaster);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 4;
end;

//============================================================================
procedure SnapStashNpcAcbs(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    ReadACBSFieldStrings(e, gSnapAcbsAutoCalc, gSnapAcbsPcLevelMult, gSnapAcbsEssential,
      gSnapAcbsLevel, gSnapAcbsCalcMin, gSnapAcbsCalcMax);
    gSnapMasterAcbsAutoCalc := '';
    gSnapMasterAcbsPcLevelMult := '';
    gSnapMasterAcbsEssential := '';
    gSnapMasterAcbsLevel := '';
    gSnapMasterAcbsCalcMin := '';
    gSnapMasterAcbsCalcMax := '';
    gSnapNpcStashMask := gSnapNpcStashMask or 8;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and 8) <> 0 then begin
    ReadACBSFieldStrings(e, gSnapAcbsAutoCalc, gSnapAcbsPcLevelMult, gSnapAcbsEssential,
      gSnapAcbsLevel, gSnapAcbsCalcMin, gSnapAcbsCalcMax);
    gSnapMasterAcbsAutoCalc := gSnapAcbsAutoCalc;
    gSnapMasterAcbsPcLevelMult := gSnapAcbsPcLevelMult;
    gSnapMasterAcbsEssential := gSnapAcbsEssential;
    gSnapMasterAcbsLevel := gSnapAcbsLevel;
    gSnapMasterAcbsCalcMin := gSnapAcbsCalcMin;
    gSnapMasterAcbsCalcMax := gSnapAcbsCalcMax;
    gSnapNpcStashMask := gSnapNpcStashMask or 8;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and $800) <> 0 then begin
    ReadACBSFieldStrings(e, gSnapAcbsAutoCalc, gSnapAcbsPcLevelMult, gSnapAcbsEssential,
      gSnapAcbsLevel, gSnapAcbsCalcMin, gSnapAcbsCalcMax);
    ReadACBSFieldStrings(gSnapMaster, gSnapMasterAcbsAutoCalc, gSnapMasterAcbsPcLevelMult,
      gSnapMasterAcbsEssential, gSnapMasterAcbsLevel, gSnapMasterAcbsCalcMin,
      gSnapMasterAcbsCalcMax);
    gSnapNpcStashMask := gSnapNpcStashMask or 8;
    Exit;
  end;
  ReadACBSFieldStrings(e, gSnapAcbsAutoCalc, gSnapAcbsPcLevelMult, gSnapAcbsEssential,
    gSnapAcbsLevel, gSnapAcbsCalcMin, gSnapAcbsCalcMax);
  gSnapMasterAcbsAutoCalc := '';
  gSnapMasterAcbsPcLevelMult := '';
  gSnapMasterAcbsEssential := '';
  gSnapMasterAcbsLevel := '';
  gSnapMasterAcbsCalcMin := '';
  gSnapMasterAcbsCalcMax := '';
  if SubElementConflictFreeByName(e, gSnapMaster, 'ACBS') then begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or 8;
    gSnapMasterAcbsAutoCalc := gSnapAcbsAutoCalc;
    gSnapMasterAcbsPcLevelMult := gSnapAcbsPcLevelMult;
    gSnapMasterAcbsEssential := gSnapAcbsEssential;
    gSnapMasterAcbsLevel := gSnapAcbsLevel;
    gSnapMasterAcbsCalcMin := gSnapAcbsCalcMin;
    gSnapMasterAcbsCalcMax := gSnapAcbsCalcMax;
  end else begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or $800;
    ReadACBSFieldStrings(gSnapMaster, gSnapMasterAcbsAutoCalc, gSnapMasterAcbsPcLevelMult,
      gSnapMasterAcbsEssential, gSnapMasterAcbsLevel, gSnapMasterAcbsCalcMin,
      gSnapMasterAcbsCalcMax);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 8;
end;

//============================================================================
procedure SnapStashNpcAvif(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapChangeAvif := ReadChangeAVIFS(e);
    gSnapMasterChangeAvif := 'none';
    gSnapNpcStashMask := gSnapNpcStashMask or 16;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and 16) <> 0 then begin
    gSnapChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapMasterChangeAvif := gSnapChangeAvif;
    gSnapNpcStashMask := gSnapNpcStashMask or 16;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and $1000) <> 0 then begin
    gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
    gSnapMasterChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapNpcStashMask := gSnapNpcStashMask or 16;
    Exit;
  end;
  if SnapAvifSubgraphConflictFree(e, gSnapMaster) then begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or 16;
    gSnapChangeAvif := SnapCacheChangeAvif(gSnapMaster);
    gSnapMasterChangeAvif := gSnapChangeAvif;
  end else begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or $1000;
    gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
    gSnapMasterChangeAvif := SnapCacheChangeAvif(gSnapMaster);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 16;
end;

//============================================================================
procedure SnapStashNpcFactions(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapFactions := ReadFactionRefs(e);
    gSnapMasterFactions := '';
    gSnapNpcStashMask := gSnapNpcStashMask or 32;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and 32) <> 0 then begin
    gSnapFactions := SnapCacheFactions(gSnapMaster);
    gSnapMasterFactions := gSnapFactions;
    gSnapNpcStashMask := gSnapNpcStashMask or 32;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and $2000) <> 0 then begin
    gSnapFactions := ReadFactionRefs(e);
    gSnapMasterFactions := SnapCacheFactions(gSnapMaster);
    gSnapNpcStashMask := gSnapNpcStashMask or 32;
    Exit;
  end;
  if SubElementConflictFreeByName(e, gSnapMaster, 'Factions') then begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or 32;
    gSnapFactions := SnapCacheFactions(gSnapMaster);
    gSnapMasterFactions := gSnapFactions;
  end else begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or $2000;
    gSnapFactions := ReadFactionRefs(e);
    gSnapMasterFactions := SnapCacheFactions(gSnapMaster);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 32;
end;

//============================================================================
procedure SnapStashNpcInventory(e: IInterface);
begin
  if not Assigned(gSnapMaster) then begin
    gSnapInventory := ReadInventoryRefs(e);
    gSnapMasterInventory := '';
    gSnapNpcStashMask := gSnapNpcStashMask or 64;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and 64) <> 0 then begin
    gSnapInventory := SnapCacheInventory(gSnapMaster);
    gSnapMasterInventory := gSnapInventory;
    gSnapNpcStashMask := gSnapNpcStashMask or 64;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and $4000) <> 0 then begin
    gSnapInventory := ReadInventoryRefs(e);
    gSnapMasterInventory := SnapCacheInventory(gSnapMaster);
    gSnapNpcStashMask := gSnapNpcStashMask or 64;
    Exit;
  end;
  if SubElementConflictFreeByName(e, gSnapMaster, 'Items') then begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or 64;
    gSnapInventory := SnapCacheInventory(gSnapMaster);
    gSnapMasterInventory := gSnapInventory;
  end else begin
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or $4000;
    gSnapInventory := ReadInventoryRefs(e);
    gSnapMasterInventory := SnapCacheInventory(gSnapMaster);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 64;
end;

//============================================================================
procedure SnapStashNpcScalars(e: IInterface);
begin
  gSnapFullName := ReadFullName(e);
  gSnapDeathItem := ReadDeathItemRef(e);
  gSnapRaceRef := ReadFormLinkRef(e, 'RNAM');
  gSnapClassRef := ReadFormLinkRef(e, 'CNAM');
  gSnapSkin := ReadNpcSkinRef(e);
  gSnapPowerArmorStand := ReadNpcPowerArmorStandRef(e);
  gSnapXpValueOffset := ReadNpcXpValueOffset(e);
  gSnapMasterFullName := '';
  gSnapMasterDeathItem := '';
  gSnapMasterRaceRef := '';
  gSnapMasterClassRef := '';
  gSnapMasterSkin := '';
  gSnapMasterPowerArmorStand := '';
  gSnapMasterXpValueOffset := '';
  if Assigned(gSnapMaster) then begin
    gSnapMasterFullName := SnapCacheNpcMasterFullName(gSnapMaster);
    gSnapMasterDeathItem := SnapCacheNpcMasterDeathItem(gSnapMaster);
    gSnapMasterRaceRef := SnapCacheFormLinkRef(gSnapMaster, 'RNAM');
    gSnapMasterClassRef := SnapCacheFormLinkRef(gSnapMaster, 'CNAM');
    gSnapMasterSkin := SnapCacheNpcMasterSkin(gSnapMaster);
    gSnapMasterPowerArmorStand := SnapCacheNpcMasterPowerArmorStand(gSnapMaster);
    gSnapMasterXpValueOffset := SnapCacheNpcMasterXpValueOffset(gSnapMaster);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 128;
end;

//============================================================================
procedure SnapReadNpcBilateralFieldsIfNeeded(e: IInterface);
begin
  if (gSnapNpcStashMask and 1) = 0 then
    SnapStashNpcKeywords(e);
  if (gSnapNpcStashMask and 2) = 0 then
    SnapStashNpcPerks(e);
  if (gSnapNpcStashMask and 4) = 0 then
    SnapStashNpcSpells(e);
  if (gSnapNpcStashMask and 8) = 0 then
    SnapStashNpcAcbs(e);
  if (gSnapNpcStashMask and 16) = 0 then
    SnapStashNpcAvif(e);
  if (gSnapNpcStashMask and 32) = 0 then
    SnapStashNpcFactions(e);
  if (gSnapNpcStashMask and 64) = 0 then
    SnapStashNpcInventory(e);
  if (gSnapNpcStashMask and 128) = 0 then
    SnapStashNpcScalars(e);
end;

//============================================================================
procedure SnapProbeNpcItmSubgraphBit(e, master: IInterface; conflictFreeBit, conflictBit: integer;
  conflictFree: boolean);
begin
  if (gSnapNpcSubgraphMask and conflictFreeBit) <> 0 then
    Exit;
  if (gSnapNpcSubgraphMask and conflictBit) <> 0 then
    Exit;
  if conflictFree then
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or conflictFreeBit
  else
    gSnapNpcSubgraphMask := gSnapNpcSubgraphMask or conflictBit;
end;

//============================================================================
procedure SnapProbeNpcItmSubgraphs(e, master: IInterface);
begin
  if (gSnapNpcSubgraphMask and 1) = 0 then begin
    if (gSnapNpcSubgraphMask and $100) = 0 then
      SnapProbeNpcItmSubgraphBit(e, master, 1, $100,
        SnapKeywordsSubgraphConflictFree(e, master));
  end;
  if (gSnapNpcSubgraphMask and 2) = 0 then begin
    if (gSnapNpcSubgraphMask and $200) = 0 then
      SnapProbeNpcItmSubgraphBit(e, master, 2, $200,
        SubElementConflictFreeByName(e, master, 'Perks'));
  end;
  if (gSnapNpcSubgraphMask and 4) = 0 then begin
    if (gSnapNpcSubgraphMask and $400) = 0 then
      SnapProbeNpcItmSubgraphBit(e, master, 4, $400,
        SnapSpellsSubgraphConflictFree(e, master));
  end;
  if (gSnapNpcSubgraphMask and 16) = 0 then begin
    if (gSnapNpcSubgraphMask and $1000) = 0 then
      SnapProbeNpcItmSubgraphBit(e, master, 16, $1000,
        SnapAvifSubgraphConflictFree(e, master));
  end;
  if (gSnapNpcSubgraphMask and 8) = 0 then begin
    if (gSnapNpcSubgraphMask and $800) = 0 then
      SnapProbeNpcItmSubgraphBit(e, master, 8, $800,
        SubElementConflictFreeByName(e, master, 'ACBS'));
  end;
  if (gSnapNpcSubgraphMask and 32) = 0 then begin
    if (gSnapNpcSubgraphMask and $2000) = 0 then
      SnapProbeNpcItmSubgraphBit(e, master, 32, $2000,
        SubElementConflictFreeByName(e, master, 'Factions'));
  end;
  if (gSnapNpcSubgraphMask and 64) = 0 then begin
    if (gSnapNpcSubgraphMask and $4000) = 0 then
      SnapProbeNpcItmSubgraphBit(e, master, 64, $4000,
        SubElementConflictFreeByName(e, master, 'Items'));
  end;
end;

//============================================================================
function SnapNpcCachedListItmUnchanged(conflictFreeBit, conflictBit: integer;
  const pluginList, masterList: string): boolean;
begin
  Result := False;
  if (gSnapNpcSubgraphMask and conflictFreeBit) <> 0 then begin
    Result := True;
    Exit;
  end;
  if (gSnapNpcSubgraphMask and conflictBit) <> 0 then begin
    Result := RefListDiffUnchangedVsMaster(pluginList, masterList);
    Exit;
  end;
end;

//============================================================================
function SnapCacheRecordFactions(e: IInterface): string;
var
  key: string;
begin
  key := SnapRecordCacheKey(e, 'factions');
  if SnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadFactionRefs(e);
  SnapRecordCachePut(key, Result);
end;

//============================================================================
function SnapCacheRecordInventory(e: IInterface): string;
var
  key: string;
begin
  key := SnapRecordCacheKey(e, 'inventory');
  if SnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadInventoryRefs(e);
  SnapRecordCachePut(key, Result);
end;

//============================================================================
function SnapRaceListFieldsUnchangedFromStash: boolean;
begin
  Result := False;
  if not Assigned(gSnapMaster) then
    Exit;
  if not RefListDiffUnchangedVsMaster(gSnapKeywords, gSnapMasterKeywords) then
    Exit;
  if not RefListDiffUnchangedVsMaster(
    JoinTwoCommaLists(gSnapPerks, gSnapSpells),
    JoinTwoCommaLists(gSnapMasterPerks, gSnapMasterSpells)) then
    Exit;
  Result := True;
end;

//============================================================================
procedure SnapReadRaceBilateralFieldsIfNeeded(e: IInterface);
begin
  if (gSnapRaceStashMask and 1) = 0 then
    SnapStashRaceKeywords(e);
  if (gSnapRaceStashMask and 2) = 0 then
    SnapStashRacePerks(e);
  if (gSnapRaceStashMask and 4) = 0 then
    SnapStashRaceSpells(e);
  if (gSnapRaceStashMask and 8) = 0 then begin
    if not Assigned(gSnapMaster) then
      SnapStashRaceAvif(e)
    else begin
      if SnapRaceListFieldsUnchangedFromStash then begin
        if not SnapRaceAvifItmUnchanged(e, gSnapMaster) then
          SnapStashRaceAvif(e);
      end else
        SnapStashRaceAvif(e);
    end;
  end;
end;

//============================================================================
function SnapCacheRecordKeywords(e: IInterface): string;
var
  key: string;
begin
  key := SnapRecordCacheKey(e, 'keywords');
  if SnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadKeywordRefsFromElement(e);
  SnapRecordCachePut(key, Result);
end;

//============================================================================
function SnapCacheRecordPerks(e: IInterface): string;
var
  key: string;
begin
  key := SnapRecordCacheKey(e, 'perks');
  if SnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadPerkRefs(e);
  SnapRecordCachePut(key, Result);
end;

//============================================================================
function SnapCacheRecordSpells(e: IInterface): string;
var
  key: string;
begin
  key := SnapRecordCacheKey(e, 'spells');
  if SnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadSpellRefs(e);
  SnapRecordCachePut(key, Result);
end;

//============================================================================
function SnapCacheRecordChangeAvif(e: IInterface): string;
var
  key: string;
begin
  key := SnapRecordCacheKey(e, 'avif');
  if SnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadChangeAVIFS(e);
  SnapRecordCachePut(key, Result);
end;

//============================================================================
function SnapRacePropertiesCount(e: IInterface): integer;
begin
  SnapEnsureRacePropertiesResolved(e);
  Result := gSnapRacePropsCount;
end;

//============================================================================
function SnapRaceNamedListContainerCount(e: IInterface; const name: string): integer;
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
function SnapRaceKeywordsFootprintCount(e: IInterface): integer;
var
  kwda: IInterface;
begin
  Result := 0;
  if not Assigned(e) then
    Exit;
  kwda := GetKeywordsElement(e);
  if Assigned(kwda) then
    Result := ElementCount(kwda);
end;

//============================================================================
function SnapRaceKeywordsFootprintDiffers(e, master: IInterface): boolean;
begin
  Result := SnapRaceKeywordsFootprintCount(e) <>
    SnapRaceKeywordsFootprintCount(master);
end;

//============================================================================
function SnapRaceSpellsFootprintCount(e: IInterface): integer;
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
function SnapCacheNpcMasterFullName(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'npc.fullname');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadFullName(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheNpcMasterDeathItem(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'npc.deathitem');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadDeathItemRef(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheNpcMasterSkin(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'npc.skin');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadNpcSkinRef(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheNpcMasterPowerArmorStand(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'npc.pastand');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadNpcPowerArmorStandRef(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
function SnapCacheNpcMasterXpValueOffset(master: IInterface): string;
var
  key: string;
  idx: integer;
begin
  key := SnapMasterCacheKey(master, 'npc.xpoffset');
  idx := SnapMasterCacheIndex(key);
  if idx >= 0 then begin
    Result := SnapMasterCacheValueAt(idx);
    Exit;
  end;
  Result := ReadNpcXpValueOffset(master);
  SnapMasterCachePut(key, Result);
end;

//============================================================================
procedure SnapReadRaceItmCompareFieldAvif(e: IInterface);
begin
  gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
  if Assigned(gSnapMaster) then
    gSnapMasterChangeAvif := SnapCacheChangeAvif(gSnapMaster)
  else
    gSnapMasterChangeAvif := '';
  gSnapRaceStashMask := gSnapRaceStashMask or 8;
end;

//============================================================================
procedure SnapReadRaceItmCompareFieldKeywords(e: IInterface);
begin
  gSnapKeywords := SnapCacheRecordKeywords(e);
  if Assigned(gSnapMaster) then
    gSnapMasterKeywords := SnapCacheKeywords(gSnapMaster)
  else
    gSnapMasterKeywords := '';
  gSnapRaceStashMask := gSnapRaceStashMask or 1;
end;

//============================================================================
procedure SnapReadRaceItmCompareFieldPerksSpells(e: IInterface);
begin
  gSnapPerks := SnapCacheRecordPerks(e);
  gSnapSpells := SnapCacheRecordSpells(e);
  if Assigned(gSnapMaster) then begin
    gSnapMasterPerks := SnapCachePerks(gSnapMaster);
    gSnapMasterSpells := SnapCacheSpells(gSnapMaster);
  end else begin
    gSnapMasterPerks := '';
    gSnapMasterSpells := '';
  end;
  gSnapRaceStashMask := gSnapRaceStashMask or 2;
  gSnapRaceStashMask := gSnapRaceStashMask or 4;
end;

//============================================================================
function SnapRaceAvifItmUnchanged(e, master: IInterface): boolean;
begin
  Result := False;
  if not Assigned(master) then
    Exit;
  if (gSnapRaceStashMask and 8) = 0 then begin
    if SnapAvifSubgraphConflictFree(e, master) then begin
      gSnapChangeAvif := SnapCacheChangeAvif(master);
      gSnapMasterChangeAvif := gSnapChangeAvif;
    end else begin
      gSnapChangeAvif := SnapCacheRecordChangeAvif(e);
      gSnapMasterChangeAvif := SnapCacheChangeAvif(master);
    end;
    gSnapRaceStashMask := gSnapRaceStashMask or 8;
  end;
  Result := gSnapChangeAvif = gSnapMasterChangeAvif;
end;

//============================================================================
function SnapTryReadRaceItmUnchanged(e: IInterface): boolean;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  SnapReadMasterIfAny(e);
  if not Assigned(gSnapMaster) then
    Exit;
  if SnapRacePropertiesCount(e) <> SnapRacePropertiesCount(gSnapMaster) then
    Exit;
  SnapReadRaceItmCompareFieldKeywords(e);
  if not RefListDiffUnchangedVsMaster(gSnapKeywords, gSnapMasterKeywords) then
    Exit;
  SnapReadRaceItmCompareFieldPerksSpells(e);
  if not RefListDiffUnchangedVsMaster(
    JoinTwoCommaLists(gSnapPerks, gSnapSpells),
    JoinTwoCommaLists(gSnapMasterPerks, gSnapMasterSpells)) then
    Exit;
  SnapReadRaceItmCompareFieldAvif(e);
  if gSnapChangeAvif <> gSnapMasterChangeAvif then
    Exit;
  Result := True;
end;

//============================================================================
function SnapTryEarlyPregatherSkipNpc(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  SnapReadMasterIfAny(e);
  master := gSnapMaster;
  if not Assigned(master) then
    Exit;
  gSnapFullName := ReadFullName(e);
  gSnapDeathItem := ReadDeathItemRef(e);
  gSnapRaceRef := SnapCacheFormLinkRef(e, 'RNAM');
  gSnapClassRef := SnapCacheFormLinkRef(e, 'CNAM');
  gSnapSkin := ReadNpcSkinRef(e);
  gSnapPowerArmorStand := ReadNpcPowerArmorStandRef(e);
  gSnapXpValueOffset := ReadNpcXpValueOffset(e);
  gSnapMasterFullName := '';
  gSnapMasterDeathItem := '';
  gSnapMasterRaceRef := '';
  gSnapMasterClassRef := '';
  gSnapMasterSkin := '';
  gSnapMasterPowerArmorStand := '';
  gSnapMasterXpValueOffset := '';
  if Assigned(gSnapMaster) then begin
    gSnapMasterFullName := SnapCacheNpcMasterFullName(master);
    gSnapMasterDeathItem := SnapCacheNpcMasterDeathItem(master);
    gSnapMasterRaceRef := SnapCacheFormLinkRef(master, 'RNAM');
    gSnapMasterClassRef := SnapCacheFormLinkRef(master, 'CNAM');
    gSnapMasterSkin := SnapCacheNpcMasterSkin(master);
    gSnapMasterPowerArmorStand := SnapCacheNpcMasterPowerArmorStand(master);
    gSnapMasterXpValueOffset := SnapCacheNpcMasterXpValueOffset(master);
  end;
  gSnapNpcStashMask := gSnapNpcStashMask or 128;
  if gSnapFullName <> gSnapMasterFullName then
    Exit;
  if gSnapDeathItem <> gSnapMasterDeathItem then
    Exit;
  if gSnapRaceRef <> gSnapMasterRaceRef then
    Exit;
  if gSnapClassRef <> gSnapMasterClassRef then
    Exit;
  if gSnapSkin <> gSnapMasterSkin then
    Exit;
  if gSnapPowerArmorStand <> gSnapMasterPowerArmorStand then
    Exit;
  if not NpcXpValueOffsetUnchanged(gSnapXpValueOffset, gSnapMasterXpValueOffset) then
    Exit;
  SnapProbeNpcItmSubgraphs(e, master);
  if not SnapNpcCachedListItmUnchanged(1, $100, SnapCacheRecordKeywords(e),
    SnapCacheKeywords(master)) then
    Exit;
  if not SnapNpcCachedListItmUnchanged(2, $200, SnapCacheRecordPerks(e),
    SnapCachePerks(master)) then
    Exit;
  if (gSnapNpcSubgraphMask and 8) = 0 then begin
    if (gSnapNpcSubgraphMask and $800) <> 0 then begin
      ReadACBSFieldStrings(e, gSnapAcbsAutoCalc, gSnapAcbsPcLevelMult, gSnapAcbsEssential,
        gSnapAcbsLevel, gSnapAcbsCalcMin, gSnapAcbsCalcMax);
      ReadACBSFieldStrings(master, gSnapMasterAcbsAutoCalc, gSnapMasterAcbsPcLevelMult,
        gSnapMasterAcbsEssential, gSnapMasterAcbsLevel, gSnapMasterAcbsCalcMin,
        gSnapMasterAcbsCalcMax);
      gSnapNpcStashMask := gSnapNpcStashMask or 8;
      if not AcbsFieldsUnchangedFromScratch then
        Exit;
    end else
      Exit;
  end;
  if (gSnapNpcSubgraphMask and 16) = 0 then begin
    if (gSnapNpcSubgraphMask and $1000) <> 0 then begin
      if SnapCacheRecordChangeAvif(e) <> SnapCacheChangeAvif(master) then
        Exit;
    end else
      Exit;
  end;
  if not SnapNpcCachedListItmUnchanged(32, $2000, SnapCacheRecordFactions(e),
    SnapCacheFactions(master)) then
    Exit;
  if (gSnapNpcSubgraphMask and $4000) <> 0 then
    gSnapNpcStashMask := gSnapNpcStashMask or 64;
  if not SnapNpcCachedListItmUnchanged(64, $4000, SnapCacheRecordInventory(e),
    SnapCacheInventory(master)) then
    Exit;
  if not SnapNpcCachedListItmUnchanged(4, $400, SnapCacheRecordSpells(e),
    SnapCacheSpells(master)) then
    Exit;
  gSnapNpcStashMask := gSnapNpcStashMask or 1;
  gSnapNpcStashMask := gSnapNpcStashMask or 2;
  gSnapNpcStashMask := gSnapNpcStashMask or 4;
  gSnapNpcStashMask := gSnapNpcStashMask or 8;
  gSnapNpcStashMask := gSnapNpcStashMask or 16;
  gSnapNpcStashMask := gSnapNpcStashMask or 32;
  gSnapNpcStashMask := gSnapNpcStashMask or 64;
  gSnapNpcStashMask := gSnapNpcStashMask or 128;
  Result := True;
end;

//============================================================================
function SnapTryEarlyPregatherSkipAmmo(e: IInterface): boolean;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  if not AmmoFieldsUnchangedVsMaster(e) then
    Exit;
  Result := True;
end;

//============================================================================
function SnapTryEarlyPregatherSkipCobj(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  if not Assigned(master) then
    Exit;
  if ReadWorkbenchKeywordRef(e) <> SnapCacheCobjWorkbench(master) then
    Exit;
  if (gSnapCobjSubgraphMask and 1) = 0 then begin
    if not SnapCobjCategoryKwSubgraphConflictFree(e, master) then
      Exit;
    gSnapCobjSubgraphMask := gSnapCobjSubgraphMask or 1;
  end;
  Result := True;
end;

//============================================================================
function SnapTryEarlyPregatherSkipArmo(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  if not Assigned(master) then
    Exit;
  if not ArmoFieldsUnchangedVsMaster(e) then
    Exit;
  if not ArmoFo4ExtrasUnchanged(e, master) then
    Exit;
  Result := True;
end;

//============================================================================
function SnapTryEarlyPregatherSkipWeap(e: IInterface): boolean;
var
  master: IInterface;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  if not Assigned(master) then
    Exit;
  if not WeapFieldsUnchangedVsMaster(e) then
    Exit;
  if not WeapFo4ExtrasUnchanged(e, master) then
    Exit;
  Result := True;
end;

//============================================================================
function SnapTryEarlyPregatherSkipAlch(e: IInterface): boolean;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  SnapReadMasterIfAny(e);
  if not Assigned(gSnapMaster) then
    Exit;
  if ReadFullName(e) <> ReadFullName(gSnapMaster) then
    Exit;
  if ReadDataField(e, 'Weight') <> ReadDataField(gSnapMaster, 'Weight') then
    Exit;
  if ReadDataField(e, 'Value') <> ReadDataField(gSnapMaster, 'Value') then
    Exit;
  if not SnapKeywordsSubgraphConflictFree(e, gSnapMaster) then
    Exit;
  if not SubElementConflictFreeByName(e, gSnapMaster, 'Effects') then
    Exit;
  SnapReadAlchMgefsToScratch(e);
  SnapEnsureAlchMgefDiffFromScratch;
  if gSnapAlchMgefsToAdd <> 'none' then
    Exit;
  if gSnapAlchMgefsToChange <> 'none' then
    Exit;
  if gSnapAlchMgefsToRemove <> 'none' then
    Exit;
  Result := True;
end;

//============================================================================
function SnapTryEarlyPregatherSkipOmod(e: IInterface): boolean;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  if not OmodHeaderUnchangedVsMaster(e) then
    Exit;
  if OmodHasProperties(e) then
    Exit;
  Result := True;
end;

//============================================================================
procedure SnapRecordEarlyPregatherSkip(const exportFn: string);
begin
  // DEBUG_INJECT_PERFMON_COUNTER count.snap.early.pregather.skip 1
end;

//============================================================================
procedure ReadRacePatchInputs(e: IInterface);
begin
  SnapReadMasterIfAny(e);
  SnapReadRaceBilateralFieldsIfNeeded(e);
end;

//============================================================================
procedure ReadNpcPatchInputs(e: IInterface);
begin
  SnapReadMasterIfAny(e);
  SnapReadNpcBilateralFieldsIfNeeded(e);
end;



//============================================================================

function RaceFieldsUnchangedFromScratch(e: IInterface): boolean;

begin

  Result := False;

  if not Assigned(gSnapMaster) then

    Exit;

  if not RefListDiffUnchangedVsMaster(gSnapKeywords, gSnapMasterKeywords) then

    Exit;

  if not RefListDiffUnchangedVsMaster(
    JoinTwoCommaLists(gSnapPerks, gSnapSpells),
    JoinTwoCommaLists(gSnapMasterPerks, gSnapMasterSpells)) then
    Exit;

  if gSnapChangeAvif <> gSnapMasterChangeAvif then

    Exit;

  Result := True;

end;



//============================================================================

function NpcFieldsUnchangedFromScratch(e: IInterface): boolean;

begin

  Result := False;

  if not Assigned(gSnapMaster) then
    Exit;

  if not RefListDiffUnchangedVsMaster(gSnapKeywords, gSnapMasterKeywords) then
    Exit;

  if not RefListDiffUnchangedVsMaster(gSnapPerks, gSnapMasterPerks) then
    Exit;

  if not RefListDiffUnchangedVsMaster(gSnapSpells, gSnapMasterSpells) then
    Exit;

  if gSnapChangeAvif <> gSnapMasterChangeAvif then
    Exit;

  if not AcbsFieldsUnchangedFromScratch then
    Exit;

  if not RefListDiffUnchangedVsMaster(gSnapFactions, gSnapMasterFactions) then
    Exit;

  if not RefListDiffUnchangedVsMaster(gSnapInventory, gSnapMasterInventory) then
    Exit;

  if gSnapFullName <> gSnapMasterFullName then
    Exit;

  if gSnapDeathItem <> gSnapMasterDeathItem then
    Exit;

  if gSnapRaceRef <> gSnapMasterRaceRef then
    Exit;

  if gSnapClassRef <> gSnapMasterClassRef then
    Exit;

  if gSnapSkin <> gSnapMasterSkin then
    Exit;

  if gSnapPowerArmorStand <> gSnapMasterPowerArmorStand then
    Exit;

  if not NpcXpValueOffsetUnchanged(gSnapXpValueOffset, gSnapMasterXpValueOffset) then
    Exit;

  Result := True;

end;



//============================================================================

procedure GatherRacePatchDataFromScratch(e: IInterface);

var

  perksRem, spellsRem: string;

begin

  SnapInitRacePatchOutput;

  gNpcPatchChangeAVIFS := ExportFieldIfChanged(e, gSnapChangeAvif, gSnapMasterChangeAvif);

  if Assigned(gSnapMaster) then begin
    ApplyRefListDiffIfItmGate(e,
      JoinTwoCommaLists(gSnapPerks, gSnapSpells),
      JoinTwoCommaLists(gSnapMasterPerks, gSnapMasterSpells),
      gNpcPatchSpellsToAdd, spellsRem);
  end else begin
    if (gSnapPerks <> '') and (gSnapSpells <> '') then
      gNpcPatchSpellsToAdd := NoneIfEmpty(
        JoinTwoCommaLists(gSnapPerks, gSnapSpells))
    else if gSnapPerks <> '' then
      gNpcPatchSpellsToAdd := NoneIfEmpty(gSnapPerks)
    else
      gNpcPatchSpellsToAdd := NoneIfEmpty(gSnapSpells);
  end;

  gNpcPatchFilterByRaces := PatchFilterFormIDRef(e);

  if gRestorationMode then
    ApplyKeywordDiffIfItmGate(e, gSnapKeywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove)
  else
    ApplyRefListDiffIfItmGate(e, gSnapKeywords, gSnapMasterKeywords,
      gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

end;



//============================================================================

procedure GatherNpcPatchDataFromScratch(e: IInterface);

var

  perksRem, spellsRem, factionsRem, objectsRem: string;

begin

  InitNPCPatchData;

  gNpcPatchChangeAVIFS := ExportFieldIfChanged(e, gSnapChangeAvif, gSnapMasterChangeAvif);

  ApplyRefListDiffIfItmGate(e, gSnapPerks, gSnapMasterPerks, gNpcPatchPerksToAdd, perksRem);

  ApplyRefListDiffIfItmGate(e, gSnapSpells, gSnapMasterSpells, gNpcPatchSpellsToAdd, spellsRem);

  ApplyRefListDiffIfItmGate(e, gSnapFactions, gSnapMasterFactions, gNpcPatchFactionsToAdd, factionsRem);

  ApplyRefListDiffIfItmGate(e, gSnapInventory, gSnapMasterInventory, gNpcPatchObjectsToAdd, objectsRem);

  gNpcPatchFactionsToRemove := NpcStripRankSuffixFromRefList(factionsRem);

  gNpcPatchObjectsToRemove := NpcStripRankSuffixFromRefList(objectsRem);

  gNpcPatchFilterByNpcs := PatchFilterFormIDRef(e);

  if gRestorationMode then
    ApplyKeywordDiffIfItmGate(e, gSnapKeywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove)
  else
    ApplyRefListDiffIfItmGate(e, gSnapKeywords, gSnapMasterKeywords,
      gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

  gNpcPatchFullName := ExportFieldIfChanged(e, gSnapFullName, gSnapMasterFullName);

  if (gSnapDeathItem = '') and (gSnapMasterDeathItem <> '') then
    gNpcPatchDeathItem := 'null'
  else
    gNpcPatchDeathItem := ExportFieldIfChanged(e, gSnapDeathItem, gSnapMasterDeathItem);

  gNpcPatchRace := ExportFieldIfChanged(e, gSnapRaceRef, gSnapMasterRaceRef);

  gNpcPatchClassOp := ExportFieldIfChanged(e, gSnapClassRef, gSnapMasterClassRef);

  gNpcPatchSkin := ExportFieldIfChanged(e, NoneIfEmpty(gSnapSkin),
    NoneIfEmpty(gSnapMasterSkin));
  gNpcPatchPowerArmorStand := ExportFieldIfChanged(e,
    NoneIfEmpty(gSnapPowerArmorStand),
    NoneIfEmpty(gSnapMasterPowerArmorStand));
  gNpcPatchXpValueOffset := NpcXpValueOffsetExportVal(gSnapXpValueOffset,
    gSnapMasterXpValueOffset);

  if Assigned(gSnapMaster) then begin

    if SnapshotUseItmGate then

      ApplyAcbsPatchDiffFromScratch(e)

    else

      ReadACBSFields(e);

  end else

    ReadACBSFields(e);

end;



//============================================================================

procedure ExportRACE(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'RACE' then
    Exit;

  SnapClearFieldScratch;
  SnapReadMasterIfAny(e);

  if SnapshotUseItmGate then begin
    if SnapTryReadRaceItmUnchanged(e) then begin
      SnapRecordEarlyPregatherSkip('ExportRACE');
      Exit;
    end;
    SnapReadRaceBilateralFieldsIfNeeded(e);
  end else
    ReadRacePatchInputs(e);

  GatherRacePatchDataFromScratch(e);
  EmitSnapshotRecord(e, 'RACE', shortComment, BuildRACELine);
end;



//============================================================================

procedure ExportNPC(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'NPC_' then
    Exit;

  SnapClearFieldScratch;

  ReadNpcPatchInputs(e);
  if SnapshotUseItmGate then begin
    if NpcFieldsUnchangedFromScratch(e) then begin
      SnapRecordEarlyPregatherSkip('ExportNPC');
      Exit;
    end;
  end;

  GatherNpcPatchDataFromScratch(e);
  EmitSnapshotRecord(e, 'NPC_', shortComment, BuildNPCLine);
end;



//============================================================================

procedure BeginNpcPluginExport;

begin

  bLoggedSkyrimAVSkip := False;

end;


end.
