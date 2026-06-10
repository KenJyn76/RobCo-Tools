{
  Snapshot exports: MISC, AMMO, COBJ, ARMO, WEAP, ALCH, OMOD (FO4), NPC_, RACE.
}
unit RobCoSnapshot;

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

  Result := RobCoAppendField(Result, 'value', gMiscPatchValue, False);
  Result := RobCoAppendField(Result, 'weight', gMiscPatchWeight, False);
  Result := RobCoAppendField(Result, 'weightMultiply', gMiscPatchWeightMultiply, False);
end;

//============================================================================
procedure ExportMISCToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'MISC' then
    Exit;

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherMiscPatchData(e);
  RobCoEmitSnapshotRecord(e, 'MISC', forwardItms, overridesOnly, shortComment, BuildRobCoMISCLine);
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
  Result := RobCoAppendField(Result, 'weight', gAmmoPatchWeight, False);
  Result := RobCoAppendField(Result, 'keywordsToAdd', gAmmoPatchKeywordsToAdd, True);

  if RobCoFO4Game then begin
    Result := RobCoAppendField(Result, 'attackDamage', gAmmoPatchAttackDamage, False);
    Result := RobCoAppendField(Result, 'ammoCategory', gAmmoPatchAmmoCategory, True);
    Result := RobCoAppendField(Result, 'setNewProjectile', gAmmoPatchSetNewProjectile, True);
  end;
end;

//============================================================================
procedure ExportAMMOToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'AMMO' then
    Exit;

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherAmmoPatchData(e);
  RobCoEmitSnapshotRecord(e, 'AMMO', forwardItms, overridesOnly, shortComment, BuildRobCoAMMOLine);
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
  parts: TStringList;
  i: integer;
begin
  Result := '';
  kwda := GetCobjCategoryKeywordsElement(e);
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
  gCobjPatchCategoryKeywordsToAdd := RobCoExportListFieldIfChanged(e,
    RobCoNoneIfEmpty(categoryKeywords), RobCoNoneIfEmpty(masterCategory));
  if gCobjPatchCategoryKeywordsToAdd = '' then
    gCobjPatchCategoryKeywordsToAdd := 'none';
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
  Result := RobCoAppendPatchField(Result, 'filterByCobjs', gCobjPatchFilterByCobjs);
  Result := RobCoAppendPatchField(Result, 'filterByWorkbenchKeywordsOr', gCobjPatchFilterByWorkbenchKeywordsOr);
  Result := RobCoAppendPatchField(Result, 'filterByCategoryKeywordsOr', gCobjPatchFilterByCategoryKeywordsOr);

  Result := RobCoAppendField(Result, 'categoryKeywordsToAdd', gCobjPatchCategoryKeywordsToAdd, True);
  Result := RobCoAppendField(Result, 'categoryKeywordsToRemove', gCobjPatchCategoryKeywordsToRemove, True);
  Result := RobCoAppendField(Result, 'workbenchKeyword', gCobjPatchWorkbenchKeyword, True);
end;

//============================================================================
procedure ExportCOBJToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'COBJ' then
    Exit;

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherCobjPatchData(e);
  RobCoEmitSnapshotRecord(e, 'COBJ', forwardItms, overridesOnly, shortComment, BuildRobCoCOBJLine);
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
  Result := RobCoAppendField(Result, 'damageResist', gArmoPatchDamageResist, False);
  Result := RobCoAppendField(Result, 'weight', gArmoPatchWeight, False);
  Result := RobCoAppendField(Result, 'value', gArmoPatchValue, False);

  if RobCoFO4Game then begin
    Result := RobCoAppendField(Result, 'health', gArmoPatchHealth, False);
    Result := RobCoAppendField(Result, 'objectEffect', gArmoPatchObjectEffect, True);
    Result := RobCoAppendField(Result, 'changeDamageTypes', gArmoPatchChangeDamageTypes, True);
    Result := RobCoAppendField(Result, 'weightMult', gArmoPatchWeightMult, True);
    Result := RobCoAppendField(Result, 'healthMult', gArmoPatchHealthMult, True);
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
procedure ExportARMOToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'ARMO' then
    Exit;

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherArmoPatchData(e);
  RobCoEmitSnapshotRecord(e, 'ARMO', forwardItms, overridesOnly, shortComment, BuildRobCoARMOLine);
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
    Result := RobCoAppendField(Result, 'attackDamage', gWeapPatchAttackDamage, True);
    Result := RobCoAppendField(Result, 'bashDamage', gWeapPatchBashDamage, True);
    Result := RobCoAppendField(Result, 'outOfRangeDamageMult', gWeapPatchOutOfRangeDamageMult, True);
    Result := RobCoAppendField(Result, 'keywordsToAdd', gWeapPatchKeywordsToAdd, True);
    Result := RobCoAppendField(Result, 'keywordsToRemove', gWeapPatchKeywordsToRemove, True);
    Result := RobCoAppendField(Result, 'setNewAmmo', gWeapPatchSetNewAmmo, True);
    Result := RobCoAppendField(Result, 'aimModel', gWeapPatchAimModel, True);
    Result := RobCoAppendField(Result, 'weight', gWeapPatchWeight, False);
    Result := RobCoAppendField(Result, 'value', gWeapPatchValue, False);
    Result := RobCoAppendField(Result, 'damageTypesToChange', gWeapPatchDamageTypesToChange, True);
    Result := RobCoAppendField(Result, 'damageTypesToRemove', gWeapPatchDamageTypesToRemove, True);
    Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToAdd',
      gWeapPatchAttachParentSlotKeywordsToAdd, True);
    Result := RobCoAppendField(Result, 'attachParentSlotKeywordsToRemove',
      gWeapPatchAttachParentSlotKeywordsToRemove, True);
  end else begin
    Result := RobCoAppendField(Result, 'attackDamage', gWeapPatchAttackDamage, False);
    Result := RobCoAppendField(Result, 'weight', gWeapPatchWeight, False);
    Result := RobCoAppendField(Result, 'value', gWeapPatchValue, False);
    Result := RobCoAppendField(Result, 'keywordsToAdd', gWeapPatchKeywordsToAdd, False);
    Result := RobCoAppendField(Result, 'keywordsToRemove', gWeapPatchKeywordsToRemove, True);
  end;
end;

//============================================================================
procedure ExportWEAPToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'WEAP' then
    Exit;

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherWeapPatchData(e);
  RobCoEmitSnapshotRecord(e, 'WEAP', forwardItms, overridesOnly, shortComment, BuildRobCoWEAPLine);
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
  parts: TStringList;
  i, magnitude, duration, area: integer;
begin
  Result := '';
  effects := ElementByName(e, 'Effects');
  if not Assigned(effects) then
    Exit;

  parts := TStringList.Create;
  try
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

      parts.Add(
        RobCoMasterFormIDRef(mgef) + '~' + IntToStr(magnitude) + '~' +
        IntToStr(duration) + '~' + IntToStr(area)
      );
    end;
    Result := RobCoJoinParts(parts);
  finally
    parts.Free;
  end;
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
  sl: TStringList;
  i: integer;
  key: string;
begin
  ms.Clear;
  sl := TStringList.Create;
  try
    RobCoParseCommaList(sl, listText);
    for i := 0 to Pred(sl.Count) do begin
      key := Trim(sl[i]);
      if key <> '' then
        RobCoMultisetInc(ms, key);
    end;
  finally
    sl.Free;
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
procedure DiffAlchMgefs(const pluginMgefs, masterMgefs: string;
  var mgefsToAdd, mgefsToChange, mgefsToRemove: string);
var
  pluginMs, masterMs, unionKeys, addParts, changeParts, remParts: TStringList;
  i, j, pluginCount, masterCount, n: integer;
  key: string;
begin
  mgefsToAdd := 'none';
  mgefsToChange := 'none';
  mgefsToRemove := 'none';

  pluginMs := TStringList.Create;
  masterMs := TStringList.Create;
  unionKeys := TStringList.Create;
  addParts := TStringList.Create;
  changeParts := TStringList.Create;
  remParts := TStringList.Create;
  try
    RobCoAlchMgefBuildMultiset(pluginMgefs, pluginMs);
    RobCoAlchMgefBuildMultiset(masterMgefs, masterMs);
    RobCoMultisetSort(pluginMs);
    RobCoMultisetSort(masterMs);

    if RobCoMultisetEqual(pluginMs, masterMs) then
      Exit;

    unionKeys.Sorted := True;
    unionKeys.Duplicates := dupIgnore;
    for i := 0 to Pred(pluginMs.Count) do
      unionKeys.Add(pluginMs[i]);
    for i := 0 to Pred(masterMs.Count) do
      unionKeys.Add(masterMs[i]);

    for i := 0 to Pred(unionKeys.Count) do begin
      key := unionKeys[i];
      pluginCount := RobCoMultisetCount(pluginMs, key);
      masterCount := RobCoMultisetCount(masterMs, key);
      n := pluginCount - masterCount;
      if n > 0 then
        for j := 1 to n do
          addParts.Add(key);
      n := masterCount - pluginCount;
      if n > 0 then
        for j := 1 to n do
          remParts.Add(key);
    end;

    RobCoAlchMgefPairAddRemove(addParts, remParts, changeParts);

    mgefsToAdd := RobCoNoneIfEmpty(RobCoJoinParts(addParts));
    mgefsToChange := RobCoNoneIfEmpty(RobCoJoinParts(changeParts));
    mgefsToRemove := RobCoNoneIfEmpty(RobCoJoinParts(remParts));
  finally
    remParts.Free;
    changeParts.Free;
    addParts.Free;
    unionKeys.Free;
    masterMs.Free;
    pluginMs.Free;
  end;
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
    if RobCoSnapshotOmitUnchangedFields then begin
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
  Result := RobCoAppendField(Result, 'weight', gAlchPatchWeight, False);
  Result := RobCoAppendField(Result, 'value', gAlchPatchValue, False);
end;

//============================================================================
procedure ExportALCHToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'ALCH' then
    Exit;

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherAlchPatchData(e);
  RobCoEmitSnapshotRecord(e, 'ALCH', forwardItms, overridesOnly, shortComment, BuildRobCoALCHLine);
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
  seenFloat, seenVp, seenForm: TStringList;
begin
  if not Assigned(floatParts) or not Assigned(vpParts) or not Assigned(formParts) then
    Exit;

  props := ElementByName(e, 'Properties');
  if not Assigned(props) then
    Exit;

  seenFloat := TStringList.Create;
  seenVp := TStringList.Create;
  seenForm := TStringList.Create;
  try
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
          if RobCoTryAddUniqueKey(seenVp, vpEntry) then
            vpParts.Add(vpEntry);
        end;
      end;
      Continue;
    end;

    if OmodValueTypeIsForm(valueType) or
       ((Pos('Form', valueType) > 0) and (Pos('Float', valueType) = 0) and
        (Pos('Bool', valueType) = 0)) then begin
      vpEntry := OmodPropFormPairEntry(prop);
      if (vpEntry <> '') and RobCoTryAddUniqueKey(seenForm, vpEntry) then
        formParts.Add(vpEntry);
      Continue;
    end;

    propKey := OmodPropertyKeyForExport(propName);
    floatVal := OmodPropFloatValue(prop);
    if floatVal = '' then
      floatVal := OmodPropIntValue(prop);
    if (propKey <> '') and (floatVal <> '') then begin
      floatEntry := propKey + '=' + floatVal;
      if RobCoTryAddUniqueKey(seenFloat, floatEntry) then
        floatParts.Add(floatEntry);
    end;
  end;
  finally
    seenForm.Free;
    seenVp.Free;
    seenFloat.Free;
  end;
end;

//============================================================================
function ReadOmodAttachPoint(e: IInterface): string;
begin
  Result := RobCoReadFormLinkPathOrRef(e, 'DATA\Attach Point', 'BNAM');
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
  floatParts, vpParts, formParts: TStringList;
  masterFloat, masterVp, masterForm: TStringList;
  apprKeywords, masterAppr: string;
  masterAttach: string;
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

  floatParts := TStringList.Create;
  vpParts := TStringList.Create;
  formParts := TStringList.Create;
  masterFloat := TStringList.Create;
  masterVp := TStringList.Create;
  masterForm := TStringList.Create;
  try
    GatherOmodProperties(e, floatParts, vpParts, formParts);
    if RobCoRecordHasExternalMaster(e) then
      GatherOmodProperties(MasterOrSelf(e), masterFloat, masterVp, masterForm);
    gOmodPatchChangeOModPropertiesFloat := RobCoExportListFieldIfChanged(e,
      RobCoJoinParts(floatParts), RobCoJoinParts(masterFloat));
    gOmodPatchChangeOModPropertiesVP := RobCoExportListFieldIfChanged(e,
      RobCoJoinParts(vpParts), RobCoJoinParts(masterVp));
    gOmodPatchChangeOModPropertiesForm := RobCoExportListFieldIfChanged(e,
      RobCoJoinParts(formParts), RobCoJoinParts(masterForm));
  finally
    masterForm.Free;
    masterVp.Free;
    masterFloat.Free;
    formParts.Free;
    vpParts.Free;
    floatParts.Free;
  end;
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

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherOmodPatchData(e);
  line := BuildRobCoOMODLine;
  RobCoEmitSnapshotRecord(e, 'OMOD', forwardItms, overridesOnly, shortComment, line);
end;


//============================================================================
// NPC / RACE
//============================================================================




const

  robCoExportNpc = 0;

  robCoExportRace = 1;



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

      if parts.IndexOf(RobCoMasterFormIDRef(link)) = -1 then

        parts.Add(RobCoMasterFormIDRef(link));

  end;



  for i := 0 to Pred(ElementCount(elem)) do

    CollectSpellFormIDs(ElementByIndex(elem, i), parts);

end;



//============================================================================

function ReadSpellRefs(e: IInterface): string;

var

  parts: TStringList;

  i: integer;

  elem, spell: IInterface;

begin

  Result := '';

  parts := TStringList.Create;

  try

    if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin

      if ElementExists(e, 'SPLO') then

        for i := 0 to Pred(ElementCount(ElementBySignature(e, 'SPLO'))) do begin

          spell := LinksTo(ElementByIndex(ElementBySignature(e, 'SPLO'), i));

          if Assigned(spell) then

            if parts.IndexOf(RobCoMasterFormIDRef(spell)) = -1 then

              parts.Add(RobCoMasterFormIDRef(spell));

        end;

    end else begin

      elem := ElementByName(e, 'Actor Effects');

      if Assigned(elem) then

        CollectSpellFormIDs(elem, parts);



      if ElementExists(e, 'SPLO') then

        for i := 0 to Pred(ElementCount(ElementBySignature(e, 'SPLO'))) do begin

          spell := LinksTo(ElementByIndex(ElementBySignature(e, 'SPLO'), i));

          if Assigned(spell) then

            if parts.IndexOf(RobCoMasterFormIDRef(spell)) = -1 then

              parts.Add(RobCoMasterFormIDRef(spell));

        end;

    end;



    Result := RobCoJoinParts(parts);

  finally

    parts.Free;

  end;

end;



//============================================================================

function ReadPerkRefs(e: IInterface): string;

var

  parts: TStringList;

  perks, i: integer;

  perk, link: IInterface;

begin

  Result := '';

  if not ElementExists(e, 'Perks') then

    Exit;



  parts := TStringList.Create;

  try

    perks := ElementCount(ElementByName(e, 'Perks'));

    for i := 0 to Pred(perks) do begin

      perk := ElementByIndex(ElementByName(e, 'Perks'), i);

      link := LinksTo(ElementByPath(perk, 'PKPR - Perk'));

      if not Assigned(link) then

        link := LinksTo(perk);

      if not Assigned(link) then

        Continue;

      if Signature(link) <> 'PERK' then

        Continue;

      if parts.IndexOf(RobCoMasterFormIDRef(link)) = -1 then

        parts.Add(RobCoMasterFormIDRef(link));

    end;

    Result := RobCoJoinParts(parts);

  finally

    parts.Free;

  end;

end;



//============================================================================

function ReadFactionRefs(e: IInterface): string;

var

  parts: TStringList;

  ents, ent, faction: IInterface;

  i, rank: integer;

begin

  Result := '';

  ents := ElementByName(e, 'Factions');

  if not Assigned(ents) then

    Exit;



  parts := TStringList.Create;

  try

    for i := 0 to Pred(ElementCount(ents)) do begin

      ent := ElementByIndex(ents, i);

      faction := LinksTo(ElementByName(ent, 'Faction'));

      if not Assigned(faction) then

        Continue;



      rank := Round(GetElementNativeValues(ent, 'Rank'));

      parts.Add(RobCoMasterFormIDRef(faction) + '=' + IntToStr(rank));

    end;

    Result := RobCoJoinParts(parts);

  finally

    parts.Free;

  end;

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

  parts: TStringList;

  items, item, ref: IInterface;

  i, count: integer;

begin

  Result := '';

  items := ElementByName(e, 'Items');

  if not Assigned(items) then

    Exit;



  parts := TStringList.Create;

  try

    for i := 0 to Pred(ElementCount(items)) do begin

      item := ElementByIndex(items, i);

      ref := LinksTo(ElementByPath(item, NpcItemPath));

      if not Assigned(ref) then

        Continue;

      count := Round(GetElementNativeValues(item, NpcItemCountPath));

      if count <= 0 then

        count := 1;

      parts.Add(RobCoMasterFormIDRef(ref) + '=' + IntToStr(count));

    end;

    Result := RobCoJoinParts(parts);

  finally

    parts.Free;

  end;

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



    if not Assigned(link) or (Signature(link) <> 'AVIF') then

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

  parts: TStringList;

  health, magicka, stamina: integer;

begin

  Result := 'none';

  parts := TStringList.Create;

  try

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



    if (health = 0) and (magicka = 0) and (stamina = 0) and ElementExists(e, 'DATA') then begin

      health := Round(GetElementNativeValues(e, 'DATA\Health'));

      magicka := Round(GetElementNativeValues(e, 'DATA\Magicka'));

      stamina := Round(GetElementNativeValues(e, 'DATA\Stamina'));

    end;



    if health > 0 then

      parts.Add('Skyrim.esm|3E8=' + IntToStr(health));

    if magicka > 0 then

      parts.Add('Skyrim.esm|3FC=' + IntToStr(magicka));

    if stamina > 0 then

      parts.Add('Skyrim.esm|3F2=' + IntToStr(stamina));



    if parts.Count = 0 then begin

      if not bLoggedSkyrimAVSkip then begin

        AddMessage('RobCo NPC: no mappable Skyrim actor values on ' + Name(e) + '; using changeAVIFS=none.');

        bLoggedSkyrimAVSkip := True;

      end;

      Exit;

    end;



    Result := RobCoJoinParts(parts);

  finally

    parts.Free;

  end;

end;



//============================================================================

function ReadFO4AVIFS(e: IInterface): string;

var

  parts: TStringList;

  props: IInterface;

begin

  Result := 'none';

  parts := TStringList.Create;

  try

    props := ElementByName(e, 'Properties');

    if Assigned(props) then

      AppendAVIFFromProperties(props, parts);



    if parts.Count = 0 then begin

      props := ElementByPath(e, 'Actor Data\Properties');

      if Assigned(props) then

        AppendAVIFFromProperties(props, parts);

    end;



    if parts.Count = 0 then

      Exit;



    Result := RobCoJoinParts(parts);

  finally

    parts.Free;

  end;

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

  parsed, outParts: TStringList;

  i, eqPos: integer;

  entry, refKey: string;

begin

  Result := listText;

  if (listText = '') or (listText = 'none') then

    Exit;



  parsed := TStringList.Create;

  outParts := TStringList.Create;

  try

    RobCoParseCommaList(parsed, listText);

    for i := 0 to Pred(parsed.Count) do begin

      entry := Trim(parsed[i]);

      if entry = '' then

        Continue;

      eqPos := Pos('=', entry);

      if eqPos > 0 then

        refKey := Copy(entry, 1, eqPos - 1)

      else

        refKey := entry;

      if outParts.IndexOf(refKey) < 0 then

        outParts.Add(refKey);

    end;

    Result := RobCoNoneIfEmpty(RobCoJoinParts(outParts));

  finally

    outParts.Free;

    parsed.Free;

  end;

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

procedure GatherNpcPatchData(e: IInterface; exportKind: integer);

var

  keywords, perks, spells, factions, inventory, fullNameVal, deathItemVal: string;

  raceRef, classRef: string;

  master: IInterface;

  masterPerks, masterSpells, masterFactions, masterInventory, masterChangeAvif: string;

  masterDeathItem, masterRace, masterClass, masterFullName: string;

  pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax: string;

  mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax: string;

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



  gNpcPatchChangeAVIFS := RobCoExportFieldIfChanged(e, ReadChangeAVIFS(e), masterChangeAvif);

  RobCoApplyRefListDiffIfCompact(e, perks, masterPerks, gNpcPatchPerksToAdd, perksRem);

  RobCoApplyRefListDiffIfCompact(e, spells, masterSpells, gNpcPatchSpellsToAdd, spellsRem);

  RobCoApplyRefListDiffIfCompact(e, factions, masterFactions, gNpcPatchFactionsToAdd, factionsRem);

  RobCoApplyRefListDiffIfCompact(e, inventory, masterInventory, gNpcPatchObjectsToAdd, objectsRem);

  gNpcPatchFactionsToRemove := NpcStripRankSuffixFromRefList(factionsRem);

  gNpcPatchObjectsToRemove := NpcStripRankSuffixFromRefList(objectsRem);



  if exportKind = robCoExportNpc then begin

    gNpcPatchFilterByNpcs := RobCoPatchFilterFormIDRef(e);

    RobCoApplyKeywordDiffIfCompact(e, keywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

    gNpcPatchFullName := RobCoExportFieldIfChanged(e, fullNameVal, masterFullName);

    gNpcPatchDeathItem := RobCoExportFieldIfChanged(e, deathItemVal, masterDeathItem);

    gNpcPatchRace := RobCoExportFieldIfChanged(e, raceRef, masterRace);

    gNpcPatchClassOp := RobCoExportFieldIfChanged(e, classRef, masterClass);

    ReadACBSFields(e);

    if Assigned(master) then begin

      if RobCoSnapshotOmitUnchangedFields then begin

        ReadACBSFieldStrings(e, pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax);

        ReadACBSFieldStrings(master, mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax);

        gNpcPatchAutoCalcStats := RobCoExportFieldIfChanged(e, pAutoCalc, mAutoCalc);

        gNpcPatchSetPcLevelMult := RobCoExportFieldIfChanged(e, pPcLevelMult, mPcLevelMult);

        gNpcPatchSetEssential := RobCoExportFieldIfChanged(e, pEssential, mEssential);

        gNpcPatchLevel := RobCoExportFieldIfChanged(e, pLevel, mLevel);

        gNpcPatchCalcLevelMin := RobCoExportFieldIfChanged(e, pCalcMin, mCalcMin);

        gNpcPatchCalcLevelMax := RobCoExportFieldIfChanged(e, pCalcMax, mCalcMax);

      end;

    end;

  end else begin

    gNpcPatchFilterByRaces := RobCoPatchFilterFormIDRef(e);

    // Keywords on RACE lines are operations (keywordsToAdd/Remove), not filterByKeywords.
    gNpcPatchFilterByKeywords := 'none';

    RobCoApplyKeywordDiffIfCompact(e, keywords, gNpcPatchKeywordsToAdd, gNpcPatchKeywordsToRemove);

    ReadACBSFields(e);

    if Assigned(master) then begin

      if RobCoSnapshotOmitUnchangedFields then begin

        ReadACBSFieldStrings(e, pAutoCalc, pPcLevelMult, pEssential, pLevel, pCalcMin, pCalcMax);

        ReadACBSFieldStrings(master, mAutoCalc, mPcLevelMult, mEssential, mLevel, mCalcMin, mCalcMax);

        gNpcPatchAutoCalcStats := RobCoExportFieldIfChanged(e, pAutoCalc, mAutoCalc);

        gNpcPatchSetPcLevelMult := RobCoExportFieldIfChanged(e, pPcLevelMult, mPcLevelMult);

        gNpcPatchSetEssential := RobCoExportFieldIfChanged(e, pEssential, mEssential);

        gNpcPatchLevel := RobCoExportFieldIfChanged(e, pLevel, mLevel);

        gNpcPatchCalcLevelMin := RobCoExportFieldIfChanged(e, pCalcMin, mCalcMin);

        gNpcPatchCalcLevelMax := RobCoExportFieldIfChanged(e, pCalcMax, mCalcMax);

      end;

    end;

  end;

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

  Result := RobCoAppendField(Result, 'autoCalcStats', gNpcPatchAutoCalcStats, False);

  Result := RobCoAppendField(Result, 'setPcLevelMult', gNpcPatchSetPcLevelMult, False);

  Result := RobCoAppendField(Result, 'setEssential', gNpcPatchSetEssential, False);

  Result := RobCoAppendField(Result, 'level', gNpcPatchLevel, False);

  Result := RobCoAppendField(Result, 'calcLevelMin', gNpcPatchCalcLevelMin, False);

  Result := RobCoAppendField(Result, 'calcLevelMax', gNpcPatchCalcLevelMax, False);

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

  Result := RobCoAppendField(Result, 'autoCalcStats', gNpcPatchAutoCalcStats, False);

  Result := RobCoAppendField(Result, 'setPcLevelMult', gNpcPatchSetPcLevelMult, False);

  Result := RobCoAppendField(Result, 'setEssential', gNpcPatchSetEssential, False);

  Result := RobCoAppendField(Result, 'level', gNpcPatchLevel, False);

  Result := RobCoAppendField(Result, 'calcLevelMin', gNpcPatchCalcLevelMin, False);

  Result := RobCoAppendField(Result, 'calcLevelMax', gNpcPatchCalcLevelMax, False);

end;



//============================================================================

procedure ExportRACEToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'RACE' then
    Exit;

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherNpcPatchData(e, robCoExportRace);
  RobCoEmitSnapshotRecord(e, 'RACE', forwardItms, overridesOnly, shortComment, BuildRobCoRACELine);
end;



//============================================================================

procedure ExportNPCToRobCo(e: IInterface; forwardItms, overridesOnly, shortComment: boolean);
begin
  if Signature(e) <> 'NPC_' then
    Exit;

  if not RobCoShouldProcessOverride(e, forwardItms, overridesOnly) then
    Exit;

  GatherNpcPatchData(e, robCoExportNpc);
  RobCoEmitSnapshotRecord(e, 'NPC_', forwardItms, overridesOnly, shortComment, BuildRobCoNPCLine);
end;



//============================================================================

procedure RobCoBeginNpcPluginExport;

begin

  bLoggedSkyrimAVSkip := False;

end;

end.
