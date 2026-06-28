{
  Shared export I/O, globals, and record gates.
}
unit Common;

var
  slExportLog: TStringList;
  gExportWriteAllFields: boolean;
  gExportForwardItms: boolean;
  gSnapItmGateActive: boolean;
  gListExportAdd: boolean;
  gListExportRemove: boolean;
  gPerPlugin: boolean;
  gOverridesOnly: boolean;
  gCompareDeclaredMasters: boolean;
  gExportDeployment: integer;
  gRestorationMode: boolean;
  gMidChainPreparedFormId: cardinal;
  gMidChainParent: IInterface;
  gMidChainWinner: IInterface;
  gMidChainRecord: IInterface;
  gSelectedOps: TStringList;
  gPatcherOutputDir: string;
  gPatcherDirBare: string;
  gPatcherRootDirBare: string;
  gIniWriterActive: boolean;
  gIniOutputDir: string;
  gIniPerPlugin: boolean;
  gIniCombinedFileName: string;
  gIniCurrentPlugin: string;
  gIniFilesCreated: integer;
  gIniFileActive: boolean;
  gIniActivePath: string;
  gIniLineBuffer: TStringList;
  gIniCombinedFileStarted: boolean;
  gIniNeedCombinedPluginHeader: boolean;
  gIniPluginsStarted: TStringList;
  gIniOverwriteOnFlush: boolean;

  gKeywordPartsScratch: TStringList;
  gDiffScratchPlugin: TStringList;
  gDiffScratchMaster: TStringList;
  gDiffScratchAdd: TStringList;
  gDiffScratchRem: TStringList;
  gRestoreSetOpSeenScratch: TStringList;
  gMidChainPartsScratch: TStringList;
  gMidChainRefSeenScratch: TStringList;
  gIniMergeScratch: TStringList;
  gIniDeferredAggregate: TStringList;
  gPluginNameByLoadOrder: TStringList;

  gSnapMasterCacheKeys: TStringList;
  gSnapMasterCacheVals: TStringList;
  gSnapRecordCacheKeys: TStringList;
  gSnapRecordCacheVals: TStringList;
  gSnapConflictProbeKeys: TStringList;

  gProgressLastReportMs: integer;
  gProgressPluginTotal: integer;
  gProgressOpNum: integer;
  gProgressOpTotal: integer;
  gProgressOpLabel: string;

{ DEBUG_INJECT_SYNC_GLOBALS: debug injection site — sync-profile splices stat globals (profile_markers.json) }
// DEBUG_INJECT_SYNC_GLOBALS

  gPluginGroupCache: TStringList;
  gIniCachedPerPluginName: string;
  gIniCachedPerPluginPath: string;
  gIniCachedCombinedPath: string;
  gExportRunId: string;
  gReliedPluginsByFile: TStringList;
  gGameMasterFileName: string;

const
  ProgressMinIntervalMs = 30000;
  FilterLLs = 'filterByLLs=';
  FilterCONT = 'filterByContainers=';
  FilterNpcs = 'filterByNpcs=';
  FilterRaces = 'filterByRaces=';
  FilterFormLists = 'filterByFormLists=';
  FilterCobjs = 'filterByCobjs=';
  FilterMiscs = 'filterByMiscs=';
  FilterAlchs = 'filterByAlchs=';
  FilterArmors = 'filterByArmors=';
  FilterWeapons = 'filterByWeapons=';
  FilterAmmos = 'filterByAmmos=';
  FilterOmod = 'filterByOMod=';

  FO4VanillaPlugins =
    ',fallout4.esm,dlccoast.esm,dlcnukaworld.esm,dlcrobot.esm,' +
    'dlcworkshop01.esm,dlcworkshop02.esm,dlcworkshop03.esm,';
  SkyrimVanillaPlugins =
    ',skyrim.esm,update.esm,dawnguard.esm,hearthfires.esm,dragonborn.esm,';
  OblivionVanillaPlugins =
    ',oblivion.esm,knights.esp,shiveringisles.esp,';
  FO3VanillaPlugins =
    ',fallout3.esm,anchorage.esm,thepitt.esm,brokensteel.esm,pointlookout.esm,zeta.esm,';
  FNVVanillaPlugins =
    ',falloutnv.esm,deadmoney.esm,honesthearts.esm,oldworldblues.esm,lonesomeroad.esm,' +
    'gunrunnersarsenal.esm,classicpack.esm,mercenarypack.esm,tribalpack.esm,';

  IniDeferredPathMarker = '//@@ROBCO_DEFERRED_PATH:';
  { Peak line buffer before chunk flush — same ceiling as load-order catalog exporter (~327680 lines).
    Catalog OOM at FlushLineCount=0 held ~1.55M Fallout4.esm lines; combined INI must not grow unbounded. }
  IniFlushLineCount = 327680;
  IniDeferAggregateFlushLineCount = 327680;
  IniDeferDiskFlush = True;

  DeploymentRestoration = 0;
  DeploymentEspReplace = 1;

//============================================================================
procedure RefreshDeploymentModeCache;
begin
  gRestorationMode := gExportDeployment = DeploymentRestoration;
end;

//============================================================================
function IsRestorationMode: boolean;
begin
  Result := gRestorationMode;
end;

//============================================================================
function IsEspReplaceMode: boolean;
begin
  Result := not gRestorationMode;
end;

//============================================================================
function ExportDeploymentString: string;
begin
  if gExportDeployment = DeploymentEspReplace then
    Result := 'esp_replace'
  else
    Result := 'restoration';
end;

//============================================================================
procedure MidChainClearRecordContext;
begin
  gMidChainParent := nil;
  gMidChainWinner := nil;
  gMidChainRecord := nil;
  gMidChainPreparedFormId := 0;
end;

//============================================================================
procedure MidChainPrepareRecord(e: IInterface);
var
  formId: cardinal;
begin
  if not Assigned(e) then begin
    MidChainClearRecordContext;
    Exit;
  end;
  formId := GetLoadOrderFormID(e);
  if (formId <> 0) then begin
    if formId = gMidChainPreparedFormId then
      if Assigned(gMidChainParent) then
        Exit;
  end;
  gMidChainRecord := e;
  gMidChainPreparedFormId := formId;
  gMidChainParent := CompareBaselineRecord(e);
  gMidChainWinner := WinningOverride(e);
end;

//============================================================================
function MidChainScalarRestorable(const pluginVal, parentVal, winnerVal: string): boolean;
begin
  Result := False;
  if pluginVal = parentVal then
    Exit;
  if winnerVal <> parentVal then
    Exit;
  Result := True;
end;

//============================================================================
function MidChainPathRestorable(e, parent, winner: IInterface; const path: string): boolean;
var
  midChanged, winnerUnchanged: boolean;
begin
  Result := False;
  if not Assigned(e) then
    Exit;
  if not Assigned(parent) then
    Exit;
  if not Assigned(winner) then
    Exit;
  midChanged := not SubElementConflictFreeByPath(e, parent, path);
  if not midChanged then
    Exit;
  winnerUnchanged := SubElementConflictFreeByPath(winner, parent, path);
  if not winnerUnchanged then
    Exit;
  Result := True;
end;

//============================================================================
procedure MidChainFilterAddsNotInWinner(var refsToAdd: string; const winnerList: string);
var
  addSl, winnerSl, kept: TStringList;
  i, loopLast: integer;
  ref, built: string;
begin
  if refsToAdd = '' then
    Exit;
  if refsToAdd = 'none' then
    Exit;
  addSl := TStringList.Create;
  winnerSl := TStringList.Create;
  kept := TStringList.Create;
  ParseCommaList(addSl, refsToAdd);
  ParseCommaList(winnerSl, winnerList);
  loopLast := LoopLastIndex(addSl.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    ref := StringListItemAt(addSl, i);
    if ref = '' then
      Continue;
    if winnerSl.IndexOf(ref) >= 0 then
      Continue;
    if kept.IndexOf(ref) >= 0 then
      Continue;
    kept.Add(ref);
  end;
  built := '';
  loopLast := LoopLastIndex(kept.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    ref := StringListItemAt(kept, i);
    if built <> '' then
      built := built + ',';
    built := built + ref;
  end;
  if built = '' then
    refsToAdd := ''
  else
    refsToAdd := built;
  addSl.Free;
  winnerSl.Free;
  kept.Free;
end;

//============================================================================
procedure MidChainFilterRefListAdds(const pluginList, parentList, winnerList: string;
  var refsToAdd: string);
var
  pluginSl, parentSl, winnerSl, kept: TStringList;
  i, loopLast: integer;
  ref: string;
  built: string;
begin
  if refsToAdd = '' then
    Exit;
  if refsToAdd = 'none' then
    Exit;
  pluginSl := TStringList.Create;
  parentSl := TStringList.Create;
  winnerSl := TStringList.Create;
  kept := TStringList.Create;
  ParseCommaList(pluginSl, pluginList);
  ParseCommaList(parentSl, parentList);
  ParseCommaList(winnerSl, winnerList);
  loopLast := LoopLastIndex(pluginSl.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    ref := StringListItemAt(pluginSl, i);
    if ref = '' then
      Continue;
    if parentSl.IndexOf(ref) >= 0 then
      Continue;
    if winnerSl.IndexOf(ref) >= 0 then
      Continue;
    if kept.IndexOf(ref) >= 0 then
      Continue;
    kept.Add(ref);
  end;
  built := '';
  loopLast := LoopLastIndex(kept.Count);
  if loopLast >= 0 then
  for i := 0 to loopLast do begin
    ref := StringListItemAt(kept, i);
    if built <> '' then
      built := built + ',';
    built := built + ref;
  end;
  if built = '' then
    refsToAdd := ''
  else
    refsToAdd := built;
  pluginSl.Free;
  parentSl.Free;
  winnerSl.Free;
  kept.Free;
end;

//============================================================================
procedure MidChainPartsScratchEnsure;
begin
  if not Assigned(gMidChainPartsScratch) then
    gMidChainPartsScratch := TStringList.Create;
  gMidChainPartsScratch.Clear;
  if not Assigned(gMidChainRefSeenScratch) then
    gMidChainRefSeenScratch := TStringList.Create;
  gMidChainRefSeenScratch.Clear;
end;

//============================================================================
procedure MidChainRefPartsAddUnique(const refKey: string);
begin
  if refKey = '' then
    Exit;
  if gMidChainRefSeenScratch.IndexOf(refKey) >= 0 then
    Exit;
  gMidChainRefSeenScratch.Add(refKey);
  gMidChainPartsScratch.Add(refKey);
end;

//============================================================================
function MidChainReadMiscValue(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  if ElementExists(e, 'DATA\Value') then
    Result := IntToStr(Round(GetElementNativeValues(e, 'DATA\Value')));
end;

//============================================================================
function MidChainReadMiscWeight(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  if ElementExists(e, 'DATA\Weight') then
    Result := GetElementEditValues(e, 'DATA\Weight');
end;

//============================================================================
function MidChainReadAmmoAttackDamage(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  if ElementExists(e, 'DNAM\Damage') then
    Result := GetElementEditValues(e, 'DNAM\Damage')
  else if ElementExists(e, 'DATA\Damage') then
    Result := GetElementEditValues(e, 'DATA\Damage');
end;

//============================================================================
function MidChainReadAmmoProjectileRef(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkRef(e, 'PNAM');
  if Result = '' then
    Result := ReadFormLinkPathOrRef(e, 'Projectile', 'INAM');
end;

//============================================================================
function MidChainGetCobjCategoryKeywordsElement(e: IInterface): IInterface;
begin
  Result := nil;
  if not Assigned(e) then
    Exit;
  Result := ElementBySignature(e, 'FNAM');
  if not Assigned(Result) then
    Result := ElementByPath(e, 'Keywords\KWDA');
end;

//============================================================================
function MidChainReadCobjCategoryKeywordRefs(e: IInterface): string;
var
  kwda, kw: IInterface;
  i: integer;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  kwda := MidChainGetCobjCategoryKeywordsElement(e);
  if not Assigned(kwda) then
    Exit;
  MidChainPartsScratchEnsure;
  for i := 0 to Pred(ElementCount(kwda)) do begin
    kw := LinksTo(ElementByIndex(kwda, i));
    if not Assigned(kw) then
      Continue;
    if Signature(kw) <> 'KYWD' then
      Continue;
    MidChainRefPartsAddUnique(MasterFormIDRef(kw));
  end;
  Result := JoinParts(gMidChainPartsScratch);
end;

//============================================================================
function MidChainReadWorkbenchKeywordRef(e: IInterface): string;
var
  link: IInterface;
begin
  Result := 'null';
  if not Assigned(e) then
    Exit;
  if not ElementExists(e, 'BNAM') then
    Exit;
  link := LinksTo(ElementBySignature(e, 'BNAM'));
  if Assigned(link) then
    Result := MasterFormIDRef(link)
  else
    Result := 'null';
end;

//============================================================================
function MidChainReadArmoObjectEffect(e: IInterface): string;
begin
  Result := 'null';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkPathOrRef(e, 'Object Effect', 'EITM');
  if Result = '' then
    Result := 'null';
end;

//============================================================================
function MidChainReadWeapBashDamage(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  if ElementExists(e, 'DNAM\Secondary Damage') then
    Result := GetElementEditValues(e, 'DNAM\Secondary Damage')
  else if ElementExists(e, 'DNAM\Bash Damage') then
    Result := GetElementEditValues(e, 'DNAM\Bash Damage');
end;

//============================================================================
function MidChainReadWeapAmmoRef(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkFirst(e, 'DNAM\Ammo', 'DNAM\Ammunition');
  if Result = '' then
    Result := ReadFormLinkRef(e, 'CNAM');
end;

//============================================================================
function MidChainReadWeapAimModelRef(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkPathOrRef(e, 'Aim Model', 'AIMP');
end;

//============================================================================
function MidChainReadWeapDnamEditValue(e: IInterface; const path: string): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  if ElementExists(e, path) then
    Result := GetElementEditValues(e, path);
end;

//============================================================================
function MidChainReadWeapDnamNativeValue(e: IInterface; const path: string): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  if ElementExists(e, path) then
    Result := FloatToStr(GetElementNativeValues(e, path));
end;

//============================================================================
function MidChainReadWeapAimModelElement(e: IInterface): IInterface;
begin
  Result := nil;
  if not Assigned(e) then
    Exit;
  Result := LinksTo(ElementByPath(e, 'DNAM\Aim Model'));
  if not Assigned(Result) then
    Result := LinksTo(ElementBySignature(e, 'AIMP'));
end;

//============================================================================
function MidChainReadWeapAimModelScalar(e: IInterface; const path: string): string;
var
  aim: IInterface;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  aim := MidChainReadWeapAimModelElement(e);
  if not Assigned(aim) then
    Exit;
  if ElementExists(aim, path) then
    Result := GetElementEditValues(aim, path);
end;

//============================================================================
function MidChainReadWeapOverrideProjectile(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkPathOrRef(e, 'DNAM\Projectile', 'PNAM');
end;

//============================================================================
function MidChainReadWeapNpcAmmoList(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkPathOrRef(e, 'DNAM\NPC Ammo List', 'VNAM');
end;

//============================================================================
function MidChainReadRecordDamageTypePairs(e: IInterface): string;
var
  arr, entry, dtLink: IInterface;
  i: integer;
  pairEntry, dmgVal: string;
begin
  Result := '';
  if not FO4Game then
    Exit;
  if not Assigned(e) then
    Exit;
  if not ElementExists(e, 'DNAM\Damage Types') then
    Exit;
  arr := ElementByPath(e, 'DNAM\Damage Types');
  MidChainPartsScratchEnsure;
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
    gMidChainPartsScratch.Add(pairEntry);
  end;
  Result := JoinParts(gMidChainPartsScratch);
end;

//============================================================================
function MidChainReadArmoBipedSlotIndices(e: IInterface): string;
var
  flags, i: integer;
begin
  Result := '';
  if not FO4Game then
    Exit;
  if not Assigned(e) then
    Exit;
  if not ElementExists(e, 'BOD2\Biped Slots') then
    Exit;
  flags := Round(GetElementNativeValues(e, 'BOD2\Biped Slots'));
  MidChainPartsScratchEnsure;
  for i := 0 to 31 do begin
    if (flags and (1 shl i)) <> 0 then
      gMidChainPartsScratch.Add(IntToStr(i));
  end;
  Result := JoinParts(gMidChainPartsScratch);
end;

//============================================================================
function MidChainReadAlchMgefsToAdd(e: IInterface): string;
var
  effects, effect, mgef: IInterface;
  i, magnitude, duration, area: integer;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  effects := ElementByName(e, 'Effects');
  if not Assigned(effects) then
    Exit;
  MidChainPartsScratchEnsure;
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
    gMidChainPartsScratch.Add(
      MasterFormIDRef(mgef) + '~' + IntToStr(magnitude) + '~' +
      IntToStr(duration) + '~' + IntToStr(area)
    );
  end;
  Result := JoinParts(gMidChainPartsScratch);
end;

//============================================================================
function MidChainReadOmodAttachPoint(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkPathOrRef(e, 'DATA\Attach Point', 'BNAM');
end;

//============================================================================
procedure MidChainCollectSpellFormIDs(elem: IInterface; parts: TStringList);
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
      MidChainRefPartsAddUnique(MasterFormIDRef(link));
  end;
  for i := 0 to Pred(ElementCount(elem)) do
    MidChainCollectSpellFormIDs(ElementByIndex(elem, i), parts);
end;

//============================================================================
function MidChainReadSpellRefs(e: IInterface): string;
var
  i: integer;
  elem, spell: IInterface;
  refKey: string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  MidChainPartsScratchEnsure;
  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) then begin
    if ElementExists(e, 'SPLO') then begin
      for i := 0 to Pred(ElementCount(ElementBySignature(e, 'SPLO'))) do begin
        spell := LinksTo(ElementByIndex(ElementBySignature(e, 'SPLO'), i));
        if not Assigned(spell) then
          Continue;
        refKey := MasterFormIDRef(spell);
        MidChainRefPartsAddUnique(refKey);
      end;
    end;
  end else begin
    elem := ElementByName(e, 'Actor Effects');
    if Assigned(elem) then
      MidChainCollectSpellFormIDs(elem, gMidChainPartsScratch);
    if ElementExists(e, 'SPLO') then begin
      for i := 0 to Pred(ElementCount(ElementBySignature(e, 'SPLO'))) do begin
        spell := LinksTo(ElementByIndex(ElementBySignature(e, 'SPLO'), i));
        if not Assigned(spell) then
          Continue;
        refKey := MasterFormIDRef(spell);
        MidChainRefPartsAddUnique(refKey);
      end;
    end;
  end;
  Result := JoinParts(gMidChainPartsScratch);
end;

//============================================================================
function MidChainReadPerkRefs(e: IInterface): string;
var
  perks, i: integer;
  perk, link, perksElem: IInterface;
  refKey: string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  if not ElementExists(e, 'Perks') then
    Exit;
  perksElem := ElementByName(e, 'Perks');
  MidChainPartsScratchEnsure;
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
    MidChainRefPartsAddUnique(refKey);
  end;
  Result := JoinParts(gMidChainPartsScratch);
end;

//============================================================================
function MidChainReadFactionRefs(e: IInterface): string;
var
  ents, ent, faction: IInterface;
  i, rank: integer;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  ents := ElementByName(e, 'Factions');
  if not Assigned(ents) then
    Exit;
  MidChainPartsScratchEnsure;
  for i := 0 to Pred(ElementCount(ents)) do begin
    ent := ElementByIndex(ents, i);
    faction := LinksTo(ElementByName(ent, 'Faction'));
    if not Assigned(faction) then
      Continue;
    rank := Round(GetElementNativeValues(ent, 'Rank'));
    gMidChainPartsScratch.Add(MasterFormIDRef(faction) + '=' + IntToStr(rank));
  end;
  Result := JoinParts(gMidChainPartsScratch);
end;

//============================================================================
function MidChainNpcItemPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Item'
  else
    Result := 'CNTO\Item';
end;

//============================================================================
function MidChainNpcItemCountPath: string;
begin
  if wbGameMode = gmTES4 then
    Result := 'Count'
  else
    Result := 'CNTO\Count';
end;

//============================================================================
function MidChainReadInventoryRefs(e: IInterface): string;
var
  items, item, ref: IInterface;
  i, count: integer;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  items := ElementByName(e, 'Items');
  if not Assigned(items) then
    Exit;
  MidChainPartsScratchEnsure;
  for i := 0 to Pred(ElementCount(items)) do begin
    item := ElementByIndex(items, i);
    ref := LinksTo(ElementByPath(item, MidChainNpcItemPath));
    if not Assigned(ref) then
      Continue;
    count := Round(GetElementNativeValues(item, MidChainNpcItemCountPath));
    if count <= 0 then
      count := 1;
    gMidChainPartsScratch.Add(MasterFormIDRef(ref) + '=' + IntToStr(count));
  end;
  Result := JoinParts(gMidChainPartsScratch);
end;

//============================================================================
function MidChainReadDeathItemRef(e: IInterface): string;
var
  link: IInterface;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  link := LinksTo(ElementBySignature(e, 'INAM'));
  if Assigned(link) then
    Result := MasterFormIDRef(link);
end;

//============================================================================
function MidChainReadNpcSkinRef(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkPathOrRef(e, 'DNAM\Skin', 'GNAM');
end;

//============================================================================
function MidChainReadNpcPowerArmorStandRef(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := ReadFormLinkPathOrRef(e, 'DNAM\Power Armor Stand', 'SNAM');
end;

//============================================================================
function MidChainReadNpcXpValueOffset(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  if ElementExists(e, 'EAMX') then
    Result := IntToStr(Round(GetElementNativeValues(e, 'EAMX')))
  else if ElementExists(e, 'ACBS\XP Value Offset') then
    Result := IntToStr(Round(GetElementNativeValues(e, 'ACBS\XP Value Offset')));
end;

//============================================================================
function MidChainReadAcbsUInt(e: IInterface; const path: string): integer;
begin
  Result := 0;
  if not Assigned(e) then
    Exit;
  if not ElementExists(e, 'ACBS') then
    Exit;
  Result := Round(GetElementNativeValues(e, path));
end;

//============================================================================
function MidChainBoolFlag(flags, mask: integer): string;
begin
  if (flags and mask) <> 0 then
    Result := 'yes'
  else
    Result := 'no';
end;

//============================================================================
procedure MidChainReadAcbsFieldStrings(e: IInterface; var autoCalc, pcLevelMult,
  essential, level, calcMin, calcMax: string);
var
  flags, levelVal: integer;
begin
  autoCalc := 'none';
  pcLevelMult := 'none';
  essential := 'none';
  level := '';
  calcMin := '';
  calcMax := '';
  if not Assigned(e) then
    Exit;
  if not ElementExists(e, 'ACBS') then
    Exit;
  flags := Round(GetElementNativeValues(e, 'ACBS\Flags'));
  autoCalc := MidChainBoolFlag(flags, $10);
  pcLevelMult := MidChainBoolFlag(flags, $80);
  essential := MidChainBoolFlag(flags, 2);
  levelVal := MidChainReadAcbsUInt(e, 'ACBS\Level');
  if (flags and $80) <> 0 then begin
    if levelVal <> 0 then
      level := IntToStr(levelVal div 1000);
  end else if levelVal <> 0 then
    level := IntToStr(levelVal);
  levelVal := MidChainReadAcbsUInt(e, 'ACBS\Calc min level');
  if levelVal = 0 then
    levelVal := MidChainReadAcbsUInt(e, 'ACBS\Calc Min');
  if levelVal <> 0 then
    calcMin := IntToStr(levelVal);
  levelVal := MidChainReadAcbsUInt(e, 'ACBS\Calc max level');
  if levelVal = 0 then
    levelVal := MidChainReadAcbsUInt(e, 'ACBS\Calc Max');
  if levelVal <> 0 then
    calcMax := IntToStr(levelVal);
end;

//============================================================================
function MidChainOpIsMapMerge(const key: string): boolean;
begin
  Result := False;
  if key = '' then
    Exit;
  if Pos('ToChange', key) > 0 then begin
    Result := True;
    Exit;
  end;
  if key = 'changeAVIFS' then begin
    Result := True;
    Exit;
  end;
  if key = 'changeDamageTypes' then begin
    Result := True;
    Exit;
  end;
  if key = 'damageTypesToChange' then begin
    Result := True;
    Exit;
  end;
  if Pos('changeOMod', key) = 1 then begin
    Result := True;
    Exit;
  end;
end;

//============================================================================
function MidChainOpIsListRemove(const key: string): boolean;
begin
  Result := False;
  if key = '' then
    Exit;
  if Pos('ToRemove', key) > 0 then begin
    Result := True;
    Exit;
  end;
  if Pos('removeOModProperties', key) = 1 then begin
    Result := True;
    Exit;
  end;
end;

//============================================================================
function MidChainReadListForOp(el: IInterface; const key: string): string;
begin
  Result := '';
  if not Assigned(el) then
    Exit;
  if key = 'keywordsToAdd' then begin
    Result := ReadKeywordRefsFromElement(el);
    Exit;
  end;
  if key = 'categoryKeywordsToAdd' then begin
    Result := MidChainReadCobjCategoryKeywordRefs(el);
    Exit;
  end;
  if key = 'attachParentSlotKeywordsToAdd' then begin
    Result := EffectiveApprKeywordRefs(el);
    Exit;
  end;
  if key = 'bipedSlotsToAdd' then begin
    Result := MidChainReadArmoBipedSlotIndices(el);
    Exit;
  end;
  if key = 'mgefsToAdd' then begin
    Result := MidChainReadAlchMgefsToAdd(el);
    Exit;
  end;
  if key = 'perksToAdd' then begin
    Result := MidChainReadPerkRefs(el);
    Exit;
  end;
  if key = 'spellsToAdd' then begin
    Result := MidChainReadSpellRefs(el);
    Exit;
  end;
  if key = 'factionsToAdd' then begin
    Result := MidChainReadFactionRefs(el);
    Exit;
  end;
  if key = 'objectsToAdd' then begin
    Result := MidChainReadInventoryRefs(el);
    Exit;
  end;
end;

//============================================================================
function MidChainTryReadScalarForOp(el: IInterface; const key: string;
  var fieldVal: string): boolean;
var
  sig: string;
  autoCalc, pcLevelMult, essential, level, calcMin, calcMax: string;
begin
  Result := False;
  fieldVal := '';
  if not Assigned(el) then
    Exit;
  sig := Signature(el);
  if key = 'fullName' then begin
    fieldVal := ReadFullName(el);
    Result := True;
    Exit;
  end;
  if key = 'weight' then begin
    if sig = 'MISC' then
      fieldVal := MidChainReadMiscWeight(el)
    else
      fieldVal := ReadDataField(el, 'Weight');
    Result := True;
    Exit;
  end;
  if key = 'value' then begin
    if sig = 'MISC' then
      fieldVal := MidChainReadMiscValue(el)
    else
      fieldVal := ReadDataField(el, 'Value');
    Result := True;
    Exit;
  end;
  if key = 'attackDamage' then begin
    if sig = 'AMMO' then
      fieldVal := MidChainReadAmmoAttackDamage(el)
    else
      fieldVal := ReadDataField(el, 'Damage');
    Result := True;
    Exit;
  end;
  if key = 'damageResist' then begin
    fieldVal := ReadDataField(el, 'Armor Rating');
    Result := True;
    Exit;
  end;
  if key = 'health' then begin
    fieldVal := ReadDataField(el, 'Health');
    Result := True;
    Exit;
  end;
  if key = 'bashDamage' then begin
    fieldVal := MidChainReadWeapBashDamage(el);
    Result := True;
    Exit;
  end;
  if key = 'outOfRangeDamageMult' then begin
    fieldVal := MidChainReadWeapDnamNativeValue(el, 'DNAM\Out of Range Damage Mult');
    Result := True;
    Exit;
  end;
  if key = 'coneIronSightsMultiplier' then begin
    fieldVal := MidChainReadWeapAimModelScalar(el, 'DNAM\Cone Iron Sights Mult');
    Result := True;
    Exit;
  end;
  if key = 'recoilDiminishSpringForce' then begin
    fieldVal := MidChainReadWeapAimModelScalar(el, 'DNAM\Recoil Diminish Spring Force');
    Result := True;
    Exit;
  end;
  if key = 'recoilPerShotMin' then begin
    fieldVal := MidChainReadWeapAimModelScalar(el, 'DNAM\Recoil Per Shot - Min Degrees');
    Result := True;
    Exit;
  end;
  if key = 'recoilPerShotMax' then begin
    fieldVal := MidChainReadWeapAimModelScalar(el, 'DNAM\Recoil Per Shot - Max Degrees');
    Result := True;
    Exit;
  end;
  if key = 'attackActionPointCost' then begin
    fieldVal := MidChainReadWeapDnamNativeValue(el, 'DNAM\Action Point Cost');
    Result := True;
    Exit;
  end;
  if key = 'soundLevel' then begin
    fieldVal := MidChainReadWeapDnamEditValue(el, 'DNAM\Sound Level');
    Result := True;
    Exit;
  end;
  if key = 'weaponHitType' then begin
    fieldVal := MidChainReadWeapDnamEditValue(el, 'DNAM\Weapon Hit Type');
    Result := True;
    Exit;
  end;
  if key = 'setNewAmmo' then begin
    fieldVal := NoneIfEmpty(MidChainReadWeapAmmoRef(el));
    Result := True;
    Exit;
  end;
  if key = 'setNewAmmoList' then begin
    fieldVal := NoneIfEmpty(MidChainReadWeapNpcAmmoList(el));
    Result := True;
    Exit;
  end;
  if key = 'aimModel' then begin
    fieldVal := NoneIfEmpty(MidChainReadWeapAimModelRef(el));
    Result := True;
    Exit;
  end;
  if key = 'overrideProjectile' then begin
    fieldVal := NoneIfEmpty(MidChainReadWeapOverrideProjectile(el));
    Result := True;
    Exit;
  end;
  if key = 'setNewProjectile' then begin
    fieldVal := NoneIfEmpty(MidChainReadAmmoProjectileRef(el));
    Result := True;
    Exit;
  end;
  if key = 'objectEffect' then begin
    fieldVal := MidChainReadArmoObjectEffect(el);
    Result := True;
    Exit;
  end;
  if key = 'weightMult' then begin
    fieldVal := MidChainReadWeapDnamNativeValue(el, 'DNAM\Weight Mod');
    Result := True;
    Exit;
  end;
  if key = 'healthMult' then begin
    fieldVal := MidChainReadWeapDnamNativeValue(el, 'DNAM\Health Mod');
    Result := True;
    Exit;
  end;
  if key = 'workbenchKeyword' then begin
    fieldVal := MidChainReadWorkbenchKeywordRef(el);
    Result := True;
    Exit;
  end;
  if key = 'setAttachPoint' then begin
    fieldVal := MidChainReadOmodAttachPoint(el);
    Result := True;
    Exit;
  end;
  if key = 'deathItem' then begin
    fieldVal := MidChainReadDeathItemRef(el);
    Result := True;
    Exit;
  end;
  if key = 'race' then begin
    fieldVal := ReadFormLinkRef(el, 'RNAM');
    Result := True;
    Exit;
  end;
  if key = 'class' then begin
    fieldVal := ReadFormLinkRef(el, 'CNAM');
    Result := True;
    Exit;
  end;
  if key = 'skin' then begin
    fieldVal := NoneIfEmpty(MidChainReadNpcSkinRef(el));
    Result := True;
    Exit;
  end;
  if key = 'powerArmorStand' then begin
    fieldVal := NoneIfEmpty(MidChainReadNpcPowerArmorStandRef(el));
    Result := True;
    Exit;
  end;
  if key = 'xpValueOffset' then begin
    fieldVal := MidChainReadNpcXpValueOffset(el);
    Result := True;
    Exit;
  end;
  if key = 'autoCalcStats' then begin
    MidChainReadAcbsFieldStrings(el, autoCalc, pcLevelMult, essential, level, calcMin, calcMax);
    fieldVal := autoCalc;
    Result := True;
    Exit;
  end;
  if key = 'setPcLevelMult' then begin
    MidChainReadAcbsFieldStrings(el, autoCalc, pcLevelMult, essential, level, calcMin, calcMax);
    fieldVal := pcLevelMult;
    Result := True;
    Exit;
  end;
  if key = 'setEssential' then begin
    MidChainReadAcbsFieldStrings(el, autoCalc, pcLevelMult, essential, level, calcMin, calcMax);
    fieldVal := essential;
    Result := True;
    Exit;
  end;
  if key = 'level' then begin
    MidChainReadAcbsFieldStrings(el, autoCalc, pcLevelMult, essential, level, calcMin, calcMax);
    fieldVal := level;
    Result := True;
    Exit;
  end;
  if key = 'calcLevelMin' then begin
    MidChainReadAcbsFieldStrings(el, autoCalc, pcLevelMult, essential, level, calcMin, calcMax);
    fieldVal := calcMin;
    Result := True;
    Exit;
  end;
  if key = 'calcLevelMax' then begin
    MidChainReadAcbsFieldStrings(el, autoCalc, pcLevelMult, essential, level, calcMin, calcMax);
    fieldVal := calcMax;
    Result := True;
    Exit;
  end;
end;

//============================================================================
function MidChainFilterSnapshotLine(e: IInterface; const line: string): string;
var
  rest, segment, key, value, parentVal, winnerVal: string;
  colonPos, eqPos: integer;
  parent, winner: IInterface;
  kept: TStringList;
  i, loopLast: integer;
  built: string;
begin
  Result := line;
  if not gRestorationMode then
    Exit;
  if line = '' then
    Exit;
  MidChainPrepareRecord(e);
  parent := gMidChainParent;
  winner := gMidChainWinner;
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
    if MidChainOpIsListRemove(key) then begin
      kept.Add(segment);
      Continue;
    end;
    if MidChainOpIsMapMerge(key) then begin
      kept.Add(segment);
      Continue;
    end;
    if Pos('ToAdd', key) > 0 then begin
      winnerVal := MidChainReadListForOp(winner, key);
      MidChainFilterAddsNotInWinner(value, winnerVal);
      if value <> '' then
        kept.Add(key + '=' + value);
      Continue;
    end;
    if MidChainTryReadScalarForOp(parent, key, parentVal) then begin
      if MidChainTryReadScalarForOp(winner, key, winnerVal) then begin
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
procedure RestoreSetOpSeenEnsure;
begin
  if not Assigned(gRestoreSetOpSeenScratch) then begin
    gRestoreSetOpSeenScratch := TStringList.Create;
    gRestoreSetOpSeenScratch.Sorted := True;
    gRestoreSetOpSeenScratch.Duplicates := dupIgnore;
  end;
  gRestoreSetOpSeenScratch.Clear;
end;

//============================================================================
function MidChainOpNeedsSetReplaceDedupe(const key: string): boolean;
begin
  Result := False;
  if key = '' then
    Exit;
  if Pos('filterBy', key) = 1 then
    Exit;
  if Pos('ToAdd', key) > 0 then
    Exit;
  if key = 'addToLLs' then
    Exit;
  if key = 'addToContainers' then
    Exit;
  if key = 'formsToAdd' then
    Exit;
  if Pos('ToRemove', key) > 0 then
    Exit;
  if key = 'removeFromLLs' then
    Exit;
  if key = 'removeFromContainers' then
    Exit;
  if key = 'formsToRemove' then
    Exit;
  if MidChainOpIsMapMerge(key) then
    Exit;
  if key = 'calcForLevel' then
    Exit;
  if key = 'calcEachItem' then
    Exit;
  if key = 'calcForLevelAndEachItem' then
    Exit;
  if key = 'calcUseAll' then
    Exit;
  Result := True;
end;

//============================================================================
function PatchLinePrimaryFilterTarget(const line: string): string;
var
  rest, segment, key, value: string;
  colonPos, eqPos: integer;
begin
  Result := '';
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
    if eqPos <= 0 then
      Continue;
    key := Copy(segment, 1, eqPos - 1);
    value := Copy(segment, eqPos + 1, MaxInt);
    if Pos('filterBy', key) <> 1 then
      Continue;
    if value = '' then
      Continue;
    if LowerCase(value) = 'none' then
      Continue;
    Result := LowerCase(value);
    Exit;
  end;
end;

//============================================================================
function MidChainDedupeSetReplaceOps(const line: string): string;
var
  rest, segment, key, value, filterTarget, seenKey: string;
  colonPos, eqPos: integer;
  kept: TStringList;
  i, loopLast: integer;
  built: string;
begin
  Result := line;
  if not gRestorationMode then
    Exit;
  if line = '' then
    Exit;
  filterTarget := PatchLinePrimaryFilterTarget(line);
  if filterTarget = '' then
    Exit;
  RestoreSetOpSeenEnsure;
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
    if not MidChainOpNeedsSetReplaceDedupe(key) then begin
      kept.Add(segment);
      Continue;
    end;
    seenKey := filterTarget + '|' + LowerCase(key);
    if gRestoreSetOpSeenScratch.IndexOf(seenKey) >= 0 then
      Continue;
    gRestoreSetOpSeenScratch.Add(seenKey);
    kept.Add(segment);
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
function NowMs: integer;
begin
  Result := Trunc(Now * 86400000);
end;


//============================================================================
procedure ProgressReset;
begin
  gProgressLastReportMs := 0;
  gProgressPluginTotal := 0;
  gProgressOpNum := 0;
  gProgressOpTotal := 0;
  gProgressOpLabel := '';
end;


//============================================================================
procedure ProgressSetPluginTotal(totalPlugins: integer);
begin
  gProgressPluginTotal := totalPlugins;
end;


//============================================================================
procedure ProgressSetOp(opNum, opTotal: integer; const opLabel: string);
begin
  gProgressOpNum := opNum;
  gProgressOpTotal := opTotal;
  gProgressOpLabel := opLabel;
end;


//============================================================================
procedure ReportProgress(const msg: string);
var
  nowMs: integer;
begin
  nowMs := NowMs;
  if gProgressLastReportMs > 0 then begin
    if (nowMs - gProgressLastReportMs) < ProgressMinIntervalMs then
      Exit;
  end;
  gProgressLastReportMs := nowMs;
  AddMessage(msg);
end;

//============================================================================
// Always prints; updates last-write time (Started/Stopped record-type lines only).
procedure ReportProgressOpBoundary(const msg: string);
begin
  gProgressLastReportMs := NowMs;
  AddMessage(msg);
end;


//============================================================================
procedure ProgressReportPlugin(const pluginName: string; pluginIndex: integer);
var
  msg: string;
begin
  if gProgressOpLabel = '' then
    Exit;
  msg := 'RobCo [' + IntToStr(gProgressOpNum) + '/' +
    IntToStr(gProgressOpTotal) + '] ' + gProgressOpLabel +
    ': plugin ' + IntToStr(pluginIndex + 1) + '/' +
    IntToStr(gProgressPluginTotal) + ' ' + pluginName;
  ReportProgress(msg);
end;

{ DEBUG_INJECT_SYNC_PROCS: debug injection site — sync-profile splices debug/perfmon procedures until function JsonEscape }
// DEBUG_INJECT_SYNC_PROCS
//============================================================================
function JsonEscape(const s: string): string;
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
function JsonBool(flag: boolean): string;
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
function RecordEditorId(e: IInterface): string;
begin
  Result := GetElementEditValues(e, 'EDID');
end;

//============================================================================
procedure EnsurePluginNameCache;
begin
  if not Assigned(gPluginNameByLoadOrder) then
    gPluginNameByLoadOrder := TStringList.Create;
end;

//============================================================================
procedure BuildPluginNameCache;
var
  i, lo, maxLo: integer;
  f: IInterface;
begin
  EnsurePluginNameCache;
  gPluginNameByLoadOrder.Clear;
  maxLo := 0;
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if not Assigned(f) then
      Continue;
    lo := GetLoadOrder(f);
    if lo > maxLo then
      maxLo := lo;
  end;
  while gPluginNameByLoadOrder.Count <= maxLo do
    gPluginNameByLoadOrder.Add('');
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);
    if not Assigned(f) then
      Continue;
    lo := GetLoadOrder(f);
    gPluginNameByLoadOrder[lo] := GetFileName(f);
  end;
end;

//============================================================================
function PluginNameForFile(af: IInterface): string;
var
  lo: integer;
begin
  Result := '';
  if not Assigned(af) then
    Exit;
  lo := GetLoadOrder(af);
  if Assigned(gPluginNameByLoadOrder) then begin
    if lo >= 0 then begin
      if lo < gPluginNameByLoadOrder.Count then begin
        Result := gPluginNameByLoadOrder[lo];
        if Result <> '' then
          Exit;
      end;
    end;
  end;
  Result := GetFileName(af);
end;

//============================================================================
function PluginNameForRecord(e: IInterface): string;
begin
  Result := '';
  if not Assigned(e) then
    Exit;
  Result := PluginNameForFile(GetFile(e));
end;

//============================================================================
function FormIDRef(rec: IInterface): string;
begin
  Result := PluginNameForRecord(rec) + '|' + FormatFormID(rec);
end;

//============================================================================
// Linked-record refs for diff/export fields: master-file plugin|id so override vs
// master reads match (e.g. Fallout4.esm|150733 not patch.esp|150733).
function MasterFormIDRef(ref: IInterface): string;
begin
  Result := '';
  if not Assigned(ref) then
    Exit;

  Result := FormIDRef(MasterOrSelf(ref));
end;

//============================================================================
// Primary filterBy* on snapshot exports: winning master identity (plugin-local
// masters stay on their plugin; overrides use the master plugin|id).
function PatchFilterFormIDRef(e: IInterface): string;
begin
  Result := MasterFormIDRef(e);
end;

//============================================================================
function RecordUnchangedVsMaster(e: IInterface): boolean;
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
  master := CompareBaselineRecord(e);
  if not Assigned(master) then begin
    Result := False;
    Exit;
  end;
  Result := ConflictAllForElements(e, master, False, False) <= caNoConflict;
end;

//============================================================================
function SubElementConflictFree(a, b: IInterface): boolean;
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
// Using PatchFilterFormIDRef(e) = FormIDRef(MasterOrSelf(e)) collapses all
// overrides of the same master to the same key, causing stale conflictFree=True
// hits that silently suppress keyword/subgraph changes in later override plugins.
function SnapConflictProbeCacheKey(e, master: IInterface; const tag: string): string;
begin
  Result := FormIDRef(e) + #1 + PatchFilterFormIDRef(master) + #1 + tag;
end;

//============================================================================
procedure SnapEnsureConflictProbeCache;
begin
  if not Assigned(gSnapConflictProbeKeys) then begin
    gSnapConflictProbeKeys := TStringList.Create;
    gSnapConflictProbeKeys.Sorted := True;
    gSnapConflictProbeKeys.Duplicates := dupIgnore;
  end;
end;

//============================================================================
function SnapConflictProbeCacheTryGet(const key: string; var conflictFree: boolean): boolean;
var
  idx: integer;
begin
  Result := False;
  if not Assigned(gSnapConflictProbeKeys) then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.conflict.probe.cache.miss 1
    Exit;
  end;
  idx := gSnapConflictProbeKeys.IndexOf(key);
  if idx < 0 then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.conflict.probe.cache.miss 1
    Exit;
  end;
  conflictFree := Integer(gSnapConflictProbeKeys.Objects[idx]) <> 0;
  // DEBUG_INJECT_PERFMON_COUNTER count.conflict.probe.cache.hit 1
  Result := True;
end;

//============================================================================
procedure SnapConflictProbeCachePut(const key: string; conflictFree: boolean);
var
  idx: integer;
  flag: integer;
begin
  SnapEnsureConflictProbeCache;
  if conflictFree then
    flag := 1
  else
    flag := 0;
  idx := gSnapConflictProbeKeys.IndexOf(key);
  if idx >= 0 then
    gSnapConflictProbeKeys.Objects[idx] := TObject(flag)
  else
    gSnapConflictProbeKeys.AddObject(key, TObject(flag));
end;

//============================================================================
function SubElementConflictFreeByPath(e, master: IInterface; const path: string): boolean;
var
  a, b: IInterface;
  key: string;
begin
  key := SnapConflictProbeCacheKey(e, master, 'p:' + path);
  if SnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  if not ElementExists(e, path) then begin
    if not ElementExists(master, path) then
      Result := True
    else
      Result := False;
    SnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  if not ElementExists(master, path) then begin
    Result := False;
    SnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  a := ElementByPath(e, path);
  b := ElementByPath(master, path);
  Result := SubElementConflictFree(a, b);
  SnapConflictProbeCachePut(key, Result);
end;

//============================================================================
function SubElementConflictFreeByName(e, master: IInterface; const name: string): boolean;
var
  a, b: IInterface;
  key: string;
begin
  key := SnapConflictProbeCacheKey(e, master, 'n:' + name);
  if SnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  if not ElementExists(e, name) then begin
    if not ElementExists(master, name) then
      Result := True
    else
      Result := False;
    SnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  if not ElementExists(master, name) then begin
    Result := False;
    SnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  a := ElementByName(e, name);
  b := ElementByName(master, name);
  Result := SubElementConflictFree(a, b);
  SnapConflictProbeCachePut(key, Result);
end;

//============================================================================
function SubElementConflictFreeBySignature(e, master: IInterface; const sig: string): boolean;
var
  a, b: IInterface;
  key: string;
begin
  key := SnapConflictProbeCacheKey(e, master, 's:' + sig);
  if SnapConflictProbeCacheTryGet(key, Result) then
    Exit;
  a := ElementBySignature(e, sig);
  b := ElementBySignature(master, sig);
  if not Assigned(a) then begin
    if not Assigned(b) then
      Result := True
    else
      Result := False;
    SnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  if not Assigned(b) then begin
    Result := False;
    SnapConflictProbeCachePut(key, Result);
    Exit;
  end;
  Result := SubElementConflictFree(a, b);
  SnapConflictProbeCachePut(key, Result);
end;

//============================================================================
function EditScalarConflictFree(e, master: IInterface; const path: string): boolean;
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
function RecordHasExternalMaster(e: IInterface): boolean;
begin
  Result := False;
  if not Assigned(e) then
    Exit;
  Result := not IsMaster(e);
end;

//============================================================================
function FileByPluginName(const pluginName: string): IInterface;
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
function ReliedPluginSetHas(relied: TStringList; const pluginNameLower: string): boolean;
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
procedure ReliedPluginSetAdd(relied: TStringList; const pluginNameLower: string);
begin
  if not Assigned(relied) then
    Exit;
  if pluginNameLower = '' then
    Exit;
  if ReliedPluginSetHas(relied, pluginNameLower) then
    Exit;
  relied.Add(pluginNameLower);
end;

//============================================================================
procedure ReliedPluginsAppendDirectMasters(af: IInterface; relied, queue: TStringList);
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
    ReliedPluginSetAdd(relied, mastLower);
    if not ReliedPluginSetHas(queue, mastLower) then
      queue.Add(mastLower);
  end;
end;

//============================================================================
function ReliedPluginsForFile(af: IInterface): TStringList;
var
  cacheKey, gameLower, queueName: string;
  cacheIdx, i: integer;
  relied, queue: TStringList;
  nextFile: IInterface;
begin
  Result := nil;
  if not Assigned(af) then
    Exit;
  if not Assigned(gReliedPluginsByFile) then
    gReliedPluginsByFile := TStringList.Create;
  cacheKey := LowerCase(GetFileName(af));
  cacheIdx := gReliedPluginsByFile.IndexOf(cacheKey);
  if cacheIdx >= 0 then begin
    Result := TStringList(gReliedPluginsByFile.Objects[cacheIdx]);
    Exit;
  end;

  relied := TStringList.Create;
  queue := TStringList.Create;
  gameLower := LowerCase(gGameMasterFileName);
  if gameLower <> '' then
    ReliedPluginSetAdd(relied, gameLower);
  ReliedPluginsAppendDirectMasters(af, relied, queue);

  i := 0;
  while i < queue.Count do begin
    queueName := queue[i];
    nextFile := FileByPluginName(queueName);
    if Assigned(nextFile) then begin
      if gGameMasterFileName = '' then
        ReliedPluginsAppendDirectMasters(nextFile, relied, queue)
      else if not SameText(GetFileName(nextFile), gGameMasterFileName) then
        ReliedPluginsAppendDirectMasters(nextFile, relied, queue);
    end;
    i := i + 1;
  end;

  queue.Free;
  gReliedPluginsByFile.AddObject(cacheKey, relied);
  Result := relied;
end;

//============================================================================
procedure ReliedPluginsCacheReset;
var
  i: integer;
begin
  if Assigned(gReliedPluginsByFile) then begin
    for i := 0 to Pred(gReliedPluginsByFile.Count) do begin
      if Assigned(gReliedPluginsByFile.Objects[i]) then
        TStringList(gReliedPluginsByFile.Objects[i]).Free;
    end;
    gReliedPluginsByFile.Clear;
  end;
  gGameMasterFileName := '';
  if FileCount > 0 then begin
    if Assigned(FileByIndex(0)) then
      gGameMasterFileName := GetFileName(FileByIndex(0));
  end;
end;

//============================================================================
function CompareBaselineRecord(e: IInterface): IInterface;
var
  ownerFile, walk: IInterface;
  relied: TStringList;
  ownerNameLower: string;
begin
  Result := nil;
  if not Assigned(e) then
    Exit;
  if not gCompareDeclaredMasters then begin
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
  relied := ReliedPluginsForFile(ownerFile);
  walk := Master(e);
  while Assigned(walk) do begin
    ownerNameLower := LowerCase(GetFileName(GetFile(walk)));
    if ReliedPluginSetHas(relied, ownerNameLower) then begin
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
function ShouldExportRecord(e: IInterface; overridesOnly: boolean): boolean;
begin
  if not overridesOnly then
    Result := True
  else
    Result := RecordHasExternalMaster(e);
end;

//============================================================================
// Record gate only: overridesOnly + Forward ITMs (ITM skip). Write all fields
// must never be read here — it affects line verbosity only (AppendField /
// AppendNumericField for scalar ops).
function ShouldProcessOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := False;
  if not Assigned(e) then
    Exit;
  if not ShouldExportRecord(e, overridesOnly) then
    Exit;
  if gRestorationMode then begin
    if IsWinningOverride(e) then
      Exit;
    Result := True;
    Exit;
  end;
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
  if RecordUnchangedVsMaster(e) then
    Exit;
  Result := True;
end;

//============================================================================
function ItmGateExternalOverride(e: IInterface): boolean;
begin
  Result := False;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  Result := True;
end;

//============================================================================
function ScalarUnchangedVsMaster(const pluginVal, masterVal: string): boolean;
begin
  Result := pluginVal = masterVal;
end;

//============================================================================
function CommaListRefCount(const listText: string): integer;
begin
  Result := 0;
  if listText = '' then
    Exit;
  EnsureDiffScratch;
  ParseCommaList(gDiffScratchPlugin, listText);
  Result := gDiffScratchPlugin.Count;
end;

//============================================================================
function RefListDiffUnchangedVsMaster(const pluginList, masterList: string): boolean;
var
  refsToAdd, refsToRemove: string;
begin
  DiffCommaSeparatedRefs(pluginList, masterList, refsToAdd, refsToRemove);
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
function RefListDiffUnchangedFromLists(slPlugin, slMaster: TStringList): boolean;
var
  i: integer;
  ref: string;
begin
  Result := True;
  if not Assigned(slPlugin) then
    Exit;
  if not Assigned(slMaster) then
    Exit;
  EnsureDiffScratch;
  gDiffScratchMaster.Clear;
  for i := 0 to Pred(slMaster.Count) do
    gDiffScratchMaster.Add(slMaster[i]);
  gDiffScratchMaster.Sorted := True;

  for i := 0 to Pred(slPlugin.Count) do begin
    ref := Trim(slPlugin[i]);
    if ref = '' then
      Continue;
    if gDiffScratchMaster.IndexOf(ref) < 0 then begin
      Result := False;
      Exit;
    end;
  end;

  gDiffScratchPlugin.Clear;
  for i := 0 to Pred(slPlugin.Count) do
    gDiffScratchPlugin.Add(slPlugin[i]);
  gDiffScratchPlugin.Sorted := True;
  for i := 0 to Pred(slMaster.Count) do begin
    ref := Trim(slMaster[i]);
    if ref = '' then
      Continue;
    if gDiffScratchPlugin.IndexOf(ref) < 0 then begin
      Result := False;
      Exit;
    end;
  end;
  gDiffScratchPlugin.Sorted := False;
  gDiffScratchMaster.Sorted := False;
end;

//============================================================================
function KeywordRefsUnchangedVsMaster(e: IInterface): boolean;
var
  master: IInterface;
  pluginKw, masterKw: string;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  master := CompareBaselineRecord(e);
  pluginKw := ReadKeywordRefsFromElement(e);
  masterKw := ReadKeywordRefsFromElement(master);
  Result := RefListDiffUnchangedVsMaster(pluginKw, masterKw);
end;

//============================================================================
function ListFieldUnchangedVsMaster(e: IInterface; const pluginList, masterList: string): boolean;
begin
  Result := False;
  if not RecordHasExternalMaster(e) then
    Exit;
  Result := RefListDiffUnchangedVsMaster(pluginList, masterList);
end;

//============================================================================
procedure BeginExport;
begin
  ProgressReset;
  // DEBUG_INJECT_PERFMON_HOOK stat_reset_begin_export
  ReliedPluginsCacheReset;
  PluginGroupCacheReset;
  if Assigned(slExportLog) then
    slExportLog.Free;
  slExportLog := nil;
  gExportRunId := IntToStr(NowMs);
  gPatcherRootDirBare := '';
  gExportDeployment := DeploymentRestoration;
  gCompareDeclaredMasters := False;
  RefreshDeploymentModeCache;
  MidChainClearRecordContext;
  RestoreSetOpSeenEnsure;
  BuildPluginNameCache;
  IniWriterInit;
end;

//============================================================================
procedure QueueExportLog(const msg: string);
begin
  if not Assigned(slExportLog) then
    slExportLog := TStringList.Create;
  slExportLog.Add(msg);
end;

//============================================================================
function PluginGroupHasOverrides(grp: IInterface): boolean;
var
  j: integer;
  e: IInterface;
begin
  Result := False;
  if not Assigned(grp) then
    Exit;
  for j := 0 to Pred(ElementCount(grp)) do begin
    e := ElementByIndex(grp, j);
    if RecordHasExternalMaster(e) then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
procedure PluginGroupCacheReset;
begin
  if Assigned(gPluginGroupCache) then begin
    gPluginGroupCache.Free;
    gPluginGroupCache := nil;
  end;
end;

//============================================================================
procedure PluginGroupCacheEnsure;
begin
  if not Assigned(gPluginGroupCache) then begin
    gPluginGroupCache := TStringList.Create;
    gPluginGroupCache.Sorted := True;
    gPluginGroupCache.Duplicates := dupIgnore;
  end;
end;

//============================================================================
function PluginGroupHasOverridesCachedGrp(f: IInterface; const sig: string;
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
  PluginGroupCacheEnsure;
  pluginName := GetFileName(f);
  cacheKey := pluginName + #1 + sig;
  idx := gPluginGroupCache.IndexOf(cacheKey);
  if idx >= 0 then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.cache.plugin.group.hit 1
    Result := Integer(gPluginGroupCache.Objects[idx]) <> 0;
    Exit;
  end;
  // DEBUG_INJECT_PERFMON_COUNTER count.cache.plugin.group.miss 1
  Result := PluginGroupHasOverrides(grp);
  gPluginGroupCache.AddObject(cacheKey, TObject(Integer(Result)));
end;

//============================================================================
function PluginGroupHasOverridesCached(f: IInterface; const sig: string): boolean;
var
  grp: IInterface;
begin
  Result := False;
  if not Assigned(f) then
    Exit;
  if sig = '' then
    Exit;
  grp := GroupBySignature(f, sig);
  Result := PluginGroupHasOverridesCachedGrp(f, sig, grp);
end;

//============================================================================
procedure FlushExportLog;
var
  i: integer;
begin
  // DEBUG_INJECT_PERFMON_HOOK stat_summary_flush_export_log
  if Assigned(slExportLog) then begin
    for i := 0 to Pred(slExportLog.Count) do
      AddMessage(slExportLog[i]);
    slExportLog.Free;
    slExportLog := nil;
  end;

  // DEBUG_INJECT_PERFMON_HOOK manifest_write_flush_export_log
  IniWriterShutdown;
end;
//============================================================================
// Caller must run ShouldProcessOverride before gather/build.
procedure EmitSnapshotRecord(e: IInterface; const sig: string;
  shortComment: boolean; const line: string);
var
  pluginName, editorID, emitLine: string;
begin
  emitLine := line;
  if gRestorationMode then
    emitLine := MidChainFilterSnapshotLine(e, line);
  if not SnapshotLineHasOperations(emitLine) then
    Exit;

  if not gIniWriterActive then
    Exit;

  pluginName := PluginNameForRecord(e);
  editorID := RecordEditorId(e);

  IniWriterWriteRecordBlock(pluginName,
    RecordComment(editorID, pluginName, sig, e, shortComment), emitLine);
  // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.emitted 1
end;

//============================================================================
function StringListHasFilter(aList: TStringList; const filterPrefix: string): boolean;
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
    StringListHasFilter(aList, FilterNpcs) or
    StringListHasFilter(aList, FilterRaces);
end;

//============================================================================
function StringListHasAnyData(aList: TStringList): boolean;
begin
  Result :=
    StringListHasFilter(aList, FilterLLs) or
    StringListHasFilter(aList, FilterCONT) or
    StringListHasFilter(aList, FilterNpcs) or
    StringListHasFilter(aList, FilterRaces) or
    StringListHasFilter(aList, FilterFormLists) or
    StringListHasFilter(aList, FilterCobjs) or
    StringListHasFilter(aList, FilterMiscs) or
    StringListHasFilter(aList, FilterAlchs) or
    StringListHasFilter(aList, FilterArmors) or
    StringListHasFilter(aList, FilterWeapons) or
    StringListHasFilter(aList, FilterAmmos) or
    StringListHasFilter(aList, FilterOmod);
end;

//============================================================================
function FO4Game: boolean;
begin
  Result := (wbGameMode = gmFO4) or (wbGameMode = gmFO4VR);
end;

//============================================================================
function SkyrimGame: boolean;
begin
  Result := (wbGameMode = gmTES5) or (wbGameMode = gmSSE);
end;

//============================================================================
function FrameworkSupported: boolean;
begin
  Result := FO4Game or SkyrimGame;
end;

//============================================================================
procedure MultisetClear(sl: TStringList);
begin
  if not Assigned(sl) then
    Exit;
  sl.Clear;
  sl.Sorted := False;
end;

//============================================================================
function StringListItemAt(sl: TStringList; index: integer): string;
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
function StringListObjectIntAt(sl: TStringList; index: integer): integer;
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
function LoopLastIndex(count: integer): integer;
begin
  Result := -1;
  if count <= 0 then
    Exit;
  Result := Pred(count);
end;

//============================================================================
function MultisetFindIdxLinear(sl: TStringList; const key: string): integer;
var
  i, loopLast: integer;
begin
  Result := -1;
  if not Assigned(sl) then
    Exit;
  if key = '' then
    Exit;
  loopLast := LoopLastIndex(sl.Count);
  if loopLast < 0 then
    Exit;
  for i := 0 to loopLast do begin
    if CompareStr(StringListItemAt(sl, i), key) = 0 then begin
      Result := i;
      Exit;
    end;
  end;
end;

//============================================================================
function MultisetFindIdx(sl: TStringList; const key: string): integer;
begin
  Result := MultisetFindIdxLinear(sl, key);
end;

//============================================================================
procedure MultisetAddCount(sl: TStringList; const key: string; count: integer);
var
  idx, n: integer;
begin
  if key = '' then
    Exit;
  if count <= 0 then
    Exit;

  idx := MultisetFindIdxLinear(sl, key);
  if idx < 0 then
    sl.AddObject(key, TObject(count))
  else begin
    n := Integer(sl.Objects[idx]);
    sl.Objects[idx] := TObject(n + count);
  end;
end;

//============================================================================
procedure MultisetInc(sl: TStringList; const key: string);
begin
  MultisetAddCount(sl, key, 1);
end;

//============================================================================
procedure MultisetSort(sl: TStringList);
begin
  // Unsorted lists only: TStringList.Sorted breaks Object pairing in JvInterpreter;
  // sorting thousands of FLST keys here was O(n^2) and stalled exports.
end;

//============================================================================
procedure MultisetAssign(dst, src: TStringList);
var
  i, n: integer;
begin
  MultisetClear(dst);
  if not Assigned(src) then
    Exit;
  // Multiset keys are unique; copy directly instead of MultisetAddCount (O(n^2)).
  for i := 0 to Pred(src.Count) do begin
    n := Integer(src.Objects[i]);
    if n <= 0 then
      Continue;
    dst.AddObject(src[i], TObject(n));
  end;
end;

//============================================================================
function MultisetTryConsume(sl: TStringList; const key: string): boolean;
var
  idx, n: integer;
begin
  Result := False;
  if key = '' then
    Exit;

  idx := MultisetFindIdxLinear(sl, key);
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
function MultisetCount(sl: TStringList; const key: string): integer;
var
  idx: integer;
begin
  idx := MultisetFindIdxLinear(sl, key);
  if idx < 0 then
    Result := 0
  else
    Result := Integer(sl.Objects[idx]);
end;

//============================================================================
function MultisetEqual(a, b: TStringList): boolean;
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
function TryAddUniqueKey(seen: TStringList; const key: string): boolean;
begin
  Result := seen.IndexOf(key) = -1;
  if Result then
    seen.Add(key);
end;

//============================================================================
function NoneIfEmpty(const s: string): string;
begin
  if s = '' then
    Result := 'none'
  else
    Result := s;
end;

//============================================================================
function JoinParts(parts: TStringList): string;
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
procedure ParseCommaList(sl: TStringList; const listText: string);
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
// Write all fields (verbose vs sparse lines) is separate: AppendField and
// AppendAuthoringBatchField pad =none for patch-author templates without
// changing ITM skip or which records are exported.
function SnapshotUseItmGate: boolean;
begin
  Result := gSnapItmGateActive;
end;

//============================================================================
function SnapshotOmitUnchangedFields: boolean;
begin
  Result := SnapshotUseItmGate;
end;

//============================================================================
function ExportFieldIfChanged(e: IInterface; const pluginValue, masterValue: string): string;
begin
  Result := pluginValue;
  if not SnapshotUseItmGate then
    Exit;
  if Assigned(gSnapMaster) then begin
    if pluginValue = masterValue then
      Result := '';
    Exit;
  end;
  if not RecordHasExternalMaster(e) then
    Exit;
  if pluginValue = masterValue then
    Result := '';
end;

//============================================================================
function ExportFieldIfRestorable(e: IInterface; const pluginValue, parentValue,
  winnerValue: string): string;
begin
  Result := ExportFieldIfChanged(e, pluginValue, parentValue);
  if Result = '' then
    Exit;
  if not gRestorationMode then
    Exit;
  if not MidChainScalarRestorable(Result, parentValue, winnerValue) then
    Result := '';
end;

//============================================================================
function DataFieldIfChanged(e: IInterface; const fieldName: string): string;
var
  master: IInterface;
  pluginVal, masterVal: string;
begin
  pluginVal := ReadDataField(e, fieldName);
  if not SnapshotUseItmGate then begin
    Result := pluginVal;
    Exit;
  end;
  if not RecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := CompareBaselineRecord(e);
  masterVal := ReadDataField(master, fieldName);
  if pluginVal = masterVal then
    Result := ''
  else
    Result := pluginVal;
end;

//============================================================================
function FullNameIfChanged(e: IInterface): string;
var
  master: IInterface;
  pluginVal, masterVal: string;
begin
  pluginVal := ReadFullName(e);
  if not SnapshotUseItmGate then begin
    Result := pluginVal;
    Exit;
  end;
  if not RecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := CompareBaselineRecord(e);
  masterVal := ReadFullName(master);
  if pluginVal = masterVal then
    Result := ''
  else
    Result := pluginVal;
end;

//============================================================================
function PlainFullNameIfChanged(e: IInterface): string;
var
  master: IInterface;
  pluginVal, masterVal: string;
begin
  pluginVal := ReadPlainFullName(e);
  if not SnapshotUseItmGate then begin
    Result := pluginVal;
    Exit;
  end;
  if not RecordHasExternalMaster(e) then begin
    Result := pluginVal;
    Exit;
  end;
  master := CompareBaselineRecord(e);
  masterVal := ReadPlainFullName(master);
  if pluginVal = masterVal then
    Result := ''
  else
    Result := pluginVal;
end;

//============================================================================
function ExportListFieldIfChanged(e: IInterface; const pluginList, masterList: string): string;
begin
  Result := pluginList;
  if not SnapshotUseItmGate then
    Exit;
  if not RecordHasExternalMaster(e) then
    Exit;
  if pluginList = masterList then
    Result := '';
end;

//============================================================================
procedure ApplyRefListDiffIfItmGate(e: IInterface; const pluginList, masterList: string;
  var refsToAdd, refsToRemove: string);
begin
  if not RecordHasExternalMaster(e) then begin
    refsToAdd := NoneIfEmpty(pluginList);
    refsToRemove := 'none';
    Exit;
  end;
  if SnapshotUseItmGate then
    DiffCommaSeparatedRefs(pluginList, masterList, refsToAdd, refsToRemove)
  else begin
    refsToAdd := NoneIfEmpty(pluginList);
    refsToRemove := 'none';
  end;
end;

//============================================================================
procedure ApplyKeywordDiffIfItmGate(e: IInterface; const pluginKeywords: string;
  var keywordsToAdd, keywordsToRemove: string);
var
  master: IInterface;
  masterKeywords, winnerKeywords: string;
begin
  masterKeywords := '';
  winnerKeywords := '';
  if RecordHasExternalMaster(e) then begin
    master := CompareBaselineRecord(e);
    masterKeywords := ReadKeywordRefsFromElement(master);
    if gRestorationMode then begin
      MidChainPrepareRecord(e);
      if Assigned(gMidChainWinner) then
        winnerKeywords := ReadKeywordRefsFromElement(gMidChainWinner);
    end;
  end;
  ApplyRefListDiffIfItmGate(e, pluginKeywords, masterKeywords,
    keywordsToAdd, keywordsToRemove);
  if gRestorationMode then
    MidChainFilterAddsNotInWinner(keywordsToAdd, winnerKeywords);
end;

//============================================================================
function SnapshotLineHasOperations(const line: string): boolean;
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
function AppendField(const line, key, value: string; forceInclude: boolean): string;
begin
  if (value = '') or (value = 'none') then begin
    if not gExportWriteAllFields then begin
      Result := line;
      Exit;
    end;
  end;

  if line <> '' then
    Result := line + ':'
  else
    Result := '';

  Result := Result + key + '=' + NoneIfEmpty(value);
end;

//============================================================================
function AppendNumericField(const line, key, value: string): string;
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
function AppendPatchField(const line, key, value: string): string;
begin
  Result := AppendField(line, key, value, True);
end;

//============================================================================
function AppendAuthoringBatchField(const line, key, value: string): string;
begin
  // Batch-only article filters: omitted on sparse mirror lines (=none), included
  // when Write all fields is on so patch authors get a full template.
  if gExportWriteAllFields then
    Result := AppendPatchField(line, key, value)
  else
    Result := line;
end;

//============================================================================
function GetKeywordsElement(e: IInterface): IInterface;
begin
  Result := ElementByPath(e, 'Keywords\KWDA');
  if not Assigned(Result) then
    Result := ElementBySignature(e, 'KWDA');
end;

//============================================================================
procedure EnsureKeywordPartsScratch;
begin
  if not Assigned(gKeywordPartsScratch) then
    gKeywordPartsScratch := TStringList.Create;
  gKeywordPartsScratch.Clear;
end;

//============================================================================
procedure EnsureDiffScratch;
begin
  if not Assigned(gDiffScratchPlugin) then begin
    gDiffScratchPlugin := TStringList.Create;
    gDiffScratchMaster := TStringList.Create;
    gDiffScratchAdd := TStringList.Create;
    gDiffScratchRem := TStringList.Create;
  end;
  gDiffScratchPlugin.Clear;
  gDiffScratchMaster.Clear;
  gDiffScratchAdd.Clear;
  gDiffScratchRem.Clear;
end;

//============================================================================
function ReadKeywordRefs(kwda: IInterface): string;
var
  i: integer;
  kw: IInterface;
begin
  Result := '';
  if not Assigned(kwda) then
    Exit;

  EnsureKeywordPartsScratch;
  for i := 0 to Pred(ElementCount(kwda)) do begin
    kw := LinksTo(ElementByIndex(kwda, i));
    if not Assigned(kw) then
      Continue;
    if Signature(kw) <> 'KYWD' then
      Continue;
    gKeywordPartsScratch.Add(MasterFormIDRef(kw));
  end;
  Result := JoinParts(gKeywordPartsScratch);
end;

//============================================================================
function JoinTwoCommaLists(const leftList, rightList: string): string;
begin
  if leftList = '' then begin
    Result := rightList;
    Exit;
  end;
  if rightList = '' then begin
    Result := leftList;
    Exit;
  end;
  EnsureDiffScratch;
  gDiffScratchPlugin.Clear;
  ParseCommaList(gDiffScratchPlugin, leftList);
  ParseCommaList(gDiffScratchPlugin, rightList);
  Result := JoinParts(gDiffScratchPlugin);
end;

//============================================================================
// Clears per-record field cache while keeping master + session conflict-probe
// caches warm across records and snapshot ops.
procedure SnapRecordCacheClear;
begin
  if Assigned(gSnapRecordCacheKeys) then begin
    gSnapRecordCacheKeys.Free;
    gSnapRecordCacheKeys := nil;
  end;
  if Assigned(gSnapRecordCacheVals) then begin
    gSnapRecordCacheVals.Free;
    gSnapRecordCacheVals := nil;
  end;
end;

//============================================================================
procedure SnapConflictProbeCacheClear;
begin
  if Assigned(gSnapConflictProbeKeys) then begin
    gSnapConflictProbeKeys.Free;
    gSnapConflictProbeKeys := nil;
  end;
end;

//============================================================================
procedure SnapRecordAndProbeCacheClear;
begin
  SnapRecordCacheClear;
  SnapConflictProbeCacheClear;
end;

//============================================================================
// Diff TStringList pools only — safe inside plugin loops while INI writer
// is active (must not free gIniDeferredAggregate or session caches).
procedure ReleaseExportDiffScratch;
begin
  if Assigned(gKeywordPartsScratch) then begin
    gKeywordPartsScratch.Free;
    gKeywordPartsScratch := nil;
  end;
  if Assigned(gDiffScratchPlugin) then begin
    gDiffScratchPlugin.Free;
    gDiffScratchPlugin := nil;
  end;
  if Assigned(gDiffScratchMaster) then begin
    gDiffScratchMaster.Free;
    gDiffScratchMaster := nil;
  end;
  if Assigned(gDiffScratchAdd) then begin
    gDiffScratchAdd.Free;
    gDiffScratchAdd := nil;
  end;
  if Assigned(gDiffScratchRem) then begin
    gDiffScratchRem.Free;
    gDiffScratchRem := nil;
  end;
  if Assigned(gRestoreSetOpSeenScratch) then begin
    gRestoreSetOpSeenScratch.Free;
    gRestoreSetOpSeenScratch := nil;
  end;
  if Assigned(gMidChainPartsScratch) then begin
    gMidChainPartsScratch.Free;
    gMidChainPartsScratch := nil;
  end;
  if Assigned(gMidChainRefSeenScratch) then begin
    gMidChainRefSeenScratch.Free;
    gMidChainRefSeenScratch := nil;
  end;
  if Assigned(gIniMergeScratch) then begin
    gIniMergeScratch.Free;
    gIniMergeScratch := nil;
  end;
end;

//============================================================================
procedure ReleaseHeavyExportScratch;
begin
  ReleaseExportDiffScratch;
  if Assigned(gPluginNameByLoadOrder) then begin
    gPluginNameByLoadOrder.Free;
    gPluginNameByLoadOrder := nil;
  end;
  PluginGroupCacheReset;
  SnapRecordAndProbeCacheClear;
end;

//============================================================================
procedure IniWriterEnsureLineBuffer;
begin
  if not Assigned(gIniLineBuffer) then
    gIniLineBuffer := TStringList.Create;
end;

//============================================================================
procedure IniWriterReleaseLineBuffer;
begin
  if Assigned(gIniLineBuffer) then begin
    gIniLineBuffer.Free;
    gIniLineBuffer := nil;
  end;
end;

//============================================================================
function ReadKeywordRefsFromElement(e: IInterface): string;
begin
  Result := ReadKeywordRefs(GetKeywordsElement(e));
end;

//============================================================================
procedure DiffCommaSeparatedRefs(const pluginRefs, masterRefs: string;
  var refsToAdd, refsToRemove: string);
var
  i: integer;
  ref: string;
begin
  refsToAdd := 'none';
  refsToRemove := 'none';

  EnsureDiffScratch;
  ParseCommaList(gDiffScratchPlugin, pluginRefs);
  ParseCommaList(gDiffScratchMaster, masterRefs);
  gDiffScratchMaster.Sorted := True;

  for i := 0 to Pred(gDiffScratchPlugin.Count) do begin
    ref := Trim(gDiffScratchPlugin[i]);
    if ref = '' then
      Continue;
    if gDiffScratchMaster.IndexOf(ref) < 0 then
      gDiffScratchAdd.Add(ref);
  end;

  gDiffScratchPlugin.Sorted := True;
  for i := 0 to Pred(gDiffScratchMaster.Count) do begin
    ref := Trim(gDiffScratchMaster[i]);
    if ref = '' then
      Continue;
    if gDiffScratchPlugin.IndexOf(ref) < 0 then
      gDiffScratchRem.Add(ref);
  end;
  gDiffScratchPlugin.Sorted := False;
  gDiffScratchMaster.Sorted := False;

  gDiffScratchAdd.Sorted := True;
  gDiffScratchRem.Sorted := True;
  refsToAdd := NoneIfEmpty(JoinParts(gDiffScratchAdd));
  refsToRemove := NoneIfEmpty(JoinParts(gDiffScratchRem));
end;

//============================================================================
function StripTrailingBackslash(const s: string): string;
begin
  Result := s;
  if Result = '' then
    Exit;
  if Result[Length(Result)] = '\' then
    SetLength(Result, Length(Result) - 1);
end;

//============================================================================
function EnsureTrailingBackslash(const s: string): string;
begin
  Result := s;
  if Result = '' then
    Exit;
  if Result[Length(Result)] = '\' then
    Exit;
  Result := Result + '\';
end;

//============================================================================
function PatcherFrameworkRoot: string;
begin
  if FO4Game then
    Result := 'F4SE\Plugins\RobCo_Patcher\'
  else
    Result := 'SKSE\Plugins\SkyPatcher\';
end;

//============================================================================
function PatcherCategoryForOperation(opIndex: integer): string;
begin
  // opIndex values match RobCo Tools.pas idx* constants.
  case opIndex of
    0: Result := 'leveledList';
    1:
      if FO4Game then
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
procedure BuildPatcherCategoryDir(const basePath: string; opIndex: integer);
var
  cat, root, base, built: string;
begin
  gPatcherOutputDir := '';
  gPatcherDirBare := '';
  cat := PatcherCategoryForOperation(opIndex);
  if cat = '' then
    Exit;
  base := EnsureTrailingBackslash(basePath);
  root := PatcherFrameworkRoot;
  built := base;
  built := built + root;
  built := built + cat;
  // JvInterpreter: assign globals from local built only (not global-to-global).
  gPatcherDirBare := built;
  gPatcherOutputDir := built + '\';
end;

//============================================================================
function EnsurePatcherOutputDir(const basePath: string; opIndex: integer): boolean;
begin
  Result := False;
  if PatcherCategoryForOperation(opIndex) = '' then begin
    AddMessage('Export cancelled: unknown record type for patcher folder (opIndex=' +
      IntToStr(opIndex) + ').');
    Exit;
  end;
  BuildPatcherCategoryDir(basePath, opIndex);
  if Length(gPatcherDirBare) = 0 then begin
    AddMessage('Export cancelled: could not resolve patcher output folder (opIndex=' +
      IntToStr(opIndex) + ').');
    Exit;
  end;
  if DirectoryExists(gPatcherDirBare) then begin
    Result := True;
    Exit;
  end;
  if ForceDirectories(gPatcherDirBare) then
    Result := True
  else
    AddMessage('Export cancelled: could not create output folder: ' + gPatcherDirBare);
end;

//============================================================================
function PatcherDeployFolderHint: string;
var
  dataPath, gameRoot: string;
begin
  dataPath := StripTrailingBackslash(DataPath);
  gameRoot := EnsureTrailingBackslash(ExtractFilePath(dataPath));
  if FO4Game then
    Result := gameRoot + 'F4SE\Plugins\RobCo_Patcher\'
  else
    Result := gameRoot + 'SKSE\Plugins\SkyPatcher\';
end;

//============================================================================
function PatcherDeployHint(const outputPath: string): string;
begin
  Result :=
    'Copy the exported ' + PatcherFrameworkRoot + ' subtree into your game install:' + #13#10 +
    PatcherDeployFolderHint + #13#10 +
    'Exported to: ' + outputPath;
end;

//============================================================================
function GetApprElement(e: IInterface): IInterface;
begin
  Result := ElementBySignature(e, 'APPR');
  if not Assigned(Result) then
    Result := ElementByPath(e, 'Keywords\APPR');
end;

//============================================================================
function ReadApprKeywordRefs(e: IInterface): string;
begin
  Result := ReadKeywordRefs(GetApprElement(e));
end;

//============================================================================
// Empty APPR on an override inherits the master list (no attachParent* emission).
function EffectiveApprKeywordRefs(e: IInterface): string;
var
  appr: string;
  master: IInterface;
begin
  appr := ReadApprKeywordRefs(e);
  if appr <> '' then begin
    Result := appr;
    Exit;
  end;
  if RecordHasExternalMaster(e) then begin
    master := CompareBaselineRecord(e);
    Result := ReadApprKeywordRefs(master);
    Exit;
  end;
  Result := '';
end;

//============================================================================
function ReadFullName(e: IInterface): string;
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
function ReadPlainFullName(e: IInterface): string;
begin
  // RobCo Patcher articles require ~...~ for fullName on all record types including OMOD.
  Result := ReadFullName(e);
end;

//============================================================================
function ReadFormLinkFirst(e: IInterface; const path1, path2: string): string;
begin
  Result := ReadFormLinkPath(e, path1);
  if Result = '' then
    Result := ReadFormLinkPath(e, path2);
end;

//============================================================================
function ReadFormLinkFirst3(e: IInterface; const path1, path2, path3: string): string;
begin
  Result := ReadFormLinkFirst(e, path1, path2);
  if Result = '' then
    Result := ReadFormLinkPath(e, path3);
end;

//============================================================================
function ReadFormLinkPathOrRef(e: IInterface; const path, sigName: string): string;
begin
  Result := ReadFormLinkPath(e, path);
  if Result = '' then
    Result := ReadFormLinkRef(e, sigName);
end;

//============================================================================
function SnapCacheFormLinkRef(e: IInterface; const sigName: string): string;
var
  key: string;
begin
  key := SnapRecordCacheKey(e, 'flref:' + sigName);
  if SnapRecordCacheLookup(key, Result) then
    Exit;
  Result := ReadFormLinkRef(e, sigName);
  SnapRecordCachePut(key, Result);
end;

//============================================================================
function ReadUnionFormLink(elem: IInterface): IInterface;
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
function ReadFormLinkRef(e: IInterface; const sigName: string): string;
var
  link: IInterface;
begin
  Result := '';
  link := LinksTo(ElementBySignature(e, sigName));
  if Assigned(link) then
    Result := MasterFormIDRef(link);
end;

//============================================================================
function ReadFormLinkPath(e: IInterface; const path: string): string;
var
  link: IInterface;
begin
  Result := '';
  if not ElementExists(e, path) then
    Exit;
  link := LinksTo(ElementByPath(e, path));
  if Assigned(link) then
    Result := MasterFormIDRef(link);
end;

//============================================================================
function ReadDataField(e: IInterface; const fieldName: string): string;
begin
  Result := '';
  if ElementExists(e, 'DATA\' + fieldName) then
    Result := GetElementEditValues(e, 'DATA\' + fieldName);
end;

//============================================================================
function RecordComment(const editorID, pluginName, sig: string; rec: IInterface;
  shortComment: boolean): string;
begin
  if shortComment then
    Result := '//' + editorID + ' [' + sig + ':' + FormatFormID(rec) + ']'
  else
    Result := '//' + editorID + ' [' + pluginName + '|' + sig + ':' + FormatFormID(rec) + ']';
end;

//============================================================================
function IsVanillaOrCCPlugin(f: IInterface): boolean;
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
      vanillaList := FO4VanillaPlugins;
    gmTES5, gmSSE:
      vanillaList := SkyrimVanillaPlugins;
    gmTES4:
      vanillaList := OblivionVanillaPlugins;
    gmFO3:
      vanillaList := FO3VanillaPlugins;
    gmFNV:
      vanillaList := FNVVanillaPlugins;
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
    clb.Checked[clb.Items.Count - 1] := not IsVanillaOrCCPlugin(f);
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
function SelectOutputDirectory(const prompt: string): string;
begin
  Result := SelectDirectory(prompt, '', DataPath, nil);
  if Result <> '' then begin
    if DirectoryExists(Result) then
      Result := EnsureTrailingBackslash(Result)
    else
      Result := '';
  end;
end;

//============================================================================
function SelectOutputFile(const defaultName: string): string;
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
procedure IniWriterEnsureDeferredAggregate;
begin
  if not Assigned(gIniDeferredAggregate) then
    gIniDeferredAggregate := TStringList.Create;
end;

//============================================================================
procedure IniWriterClearDeferredAggregate;
begin
  if Assigned(gIniDeferredAggregate) then
    gIniDeferredAggregate.Clear;
end;

//============================================================================
procedure IniWriterAppendBufferToDeferred;
var
  i: integer;
begin
  if gIniLineBuffer.Count = 0 then
    Exit;
  if gIniActivePath = '' then
    Exit;
  IniWriterEnsureDeferredAggregate;
  gIniDeferredAggregate.Add(IniDeferredPathMarker + gIniActivePath);
  for i := 0 to Pred(gIniLineBuffer.Count) do
    gIniDeferredAggregate.Add(gIniLineBuffer[i]);
  gIniLineBuffer.Clear;
  IniWriterMaybeFlushDeferredAggregate;
end;

//============================================================================
procedure IniWriterMaybeFlushOnLineCount;
begin
  if IniFlushLineCount <= 0 then
    Exit;
  if gIniLineBuffer.Count < IniFlushLineCount then
    Exit;
  IniWriterFlushBuffer;
end;

//============================================================================
procedure IniWriterMaybeFlushDeferredAggregate;
begin
  if IniDeferAggregateFlushLineCount <= 0 then
    Exit;
  if not IniDeferDiskFlush then
    Exit;
  if not Assigned(gIniDeferredAggregate) then
    Exit;
  if gIniDeferredAggregate.Count < IniDeferAggregateFlushLineCount then
    Exit;
  IniWriterFlushDeferredAggregateToDisk;
end;

//============================================================================
procedure IniWriterSaveBufferToPath(const path: string; overwriteOnFlush: boolean);
var
  savedPath: string;
  savedOverwrite: boolean;
begin
  if gIniLineBuffer.Count = 0 then
    Exit;
  if path = '' then
    Exit;
  savedPath := gIniActivePath;
  savedOverwrite := gIniOverwriteOnFlush;
  gIniActivePath := path;
  gIniOverwriteOnFlush := overwriteOnFlush;
  // DEBUG_INJECT_PERFMON_COUNTER count.ini.flush 1
  if (not gIniOverwriteOnFlush) and FileExists(path) then begin
    if not Assigned(gIniMergeScratch) then
      gIniMergeScratch := TStringList.Create;
    gIniMergeScratch.Clear;
    gIniMergeScratch.LoadFromFile(path);
    gIniMergeScratch.AddStrings(gIniLineBuffer);
    gIniMergeScratch.SaveToFile(path);
  end else
    gIniLineBuffer.SaveToFile(path);
  gIniActivePath := savedPath;
  gIniOverwriteOnFlush := savedOverwrite;
  gIniLineBuffer.Clear;
end;

//============================================================================
procedure IniWriterFlushDeferredAggregateToDisk;
var
  i: integer;
  line, path, built: string;
begin
  if not Assigned(gIniDeferredAggregate) then
    Exit;
  if gIniDeferredAggregate.Count = 0 then
    Exit;
  IniWriterEnsureLineBuffer;
  path := '';
  gIniLineBuffer.Clear;
  for i := 0 to Pred(gIniDeferredAggregate.Count) do begin
    line := gIniDeferredAggregate[i];
    if Pos(IniDeferredPathMarker, line) = 1 then begin
      if path <> '' then
        IniWriterSaveBufferToPath(path, True);
      built := Copy(line, Length(IniDeferredPathMarker) + 1, MaxInt);
      path := built;
      gIniLineBuffer.Clear;
      Continue;
    end;
    gIniLineBuffer.Add(line);
  end;
  if path <> '' then
    IniWriterSaveBufferToPath(path, True);
  gIniDeferredAggregate.Clear;
end;

//============================================================================
procedure IniWriterFlushBuffer;
begin
  IniWriterEnsureLineBuffer;
  if gIniLineBuffer.Count = 0 then
    Exit;
  if gIniActivePath = '' then
    Exit;
  if IniDeferDiskFlush then begin
    IniWriterAppendBufferToDeferred;
    Exit;
  end;
  IniWriterSaveBufferToPath(gIniActivePath, gIniOverwriteOnFlush);
  gIniOverwriteOnFlush := False;
end;

//============================================================================
procedure IniWriterCloseActiveFile;
begin
  IniWriterFlushBuffer;
  gIniFileActive := False;
  gIniActivePath := '';
end;

//============================================================================
procedure IniWriterActivatePath(const path: string; countAsNewFile: boolean);
begin
  if gIniActivePath = path then
    Exit;
  IniWriterFlushBuffer;
  gIniActivePath := path;
  gIniFileActive := True;
  gIniOverwriteOnFlush := countAsNewFile;
  if countAsNewFile then begin
    Inc(gIniFilesCreated);
    QueueExportLog('Created INI: ' + path);
  end;
end;

//============================================================================
procedure IniWriterQueueLine(const line: string);
begin
  IniWriterEnsureLineBuffer;
  gIniLineBuffer.Add(line);
  IniWriterMaybeFlushOnLineCount;
end;

//============================================================================
procedure IniWriterShutdown;
begin
  IniWriterCloseActiveFile;
  if IniDeferDiskFlush then
    IniWriterFlushDeferredAggregateToDisk;
  IniWriterClearDeferredAggregate;
  if Assigned(gIniDeferredAggregate) then begin
    gIniDeferredAggregate.Free;
    gIniDeferredAggregate := nil;
  end;
  gIniWriterActive := False;
  IniWriterReleaseLineBuffer;
end;

//============================================================================
procedure IniWriterInit;
begin
  IniWriterShutdown;
  gIniWriterActive := True;
  if not Assigned(gIniPluginsStarted) then begin
    gIniPluginsStarted := TStringList.Create;
    gIniPluginsStarted.Sorted := True;
    gIniPluginsStarted.Duplicates := dupIgnore;
  end;
  IniWriterEnsureLineBuffer;
  gIniLineBuffer.Clear;
end;

//============================================================================
procedure IniWriterResetPathCache;
begin
  gIniCachedPerPluginName := '';
  gIniCachedPerPluginPath := '';
  gIniCachedCombinedPath := '';
end;

//============================================================================
function IniWriterPerPluginPath(const pluginName: string): string;
begin
  if gIniCachedPerPluginName = pluginName then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.cache.ini.path.hit 1
    Result := gIniCachedPerPluginPath;
    Exit;
  end;
  // DEBUG_INJECT_PERFMON_COUNTER count.cache.ini.path.miss 1
  Result := gIniOutputDir + pluginName + '.ini';
  gIniCachedPerPluginName := pluginName;
  gIniCachedPerPluginPath := Result;
end;

//============================================================================
function IniWriterCombinedPath: string;
begin
  if gIniCachedCombinedPath <> '' then begin
    // DEBUG_INJECT_PERFMON_COUNTER count.cache.ini.path.hit 1
    Result := gIniCachedCombinedPath;
    Exit;
  end;
  // DEBUG_INJECT_PERFMON_COUNTER count.cache.ini.path.miss 1
  Result := gIniOutputDir + gIniCombinedFileName;
  gIniCachedCombinedPath := Result;
end;

//============================================================================
procedure IniWriterBeginOp(const outputDir: string; perPlugin: boolean;
  const combinedFileName: string);
begin
  IniWriterCloseActiveFile;
  ReleaseHeavyExportScratch;
  IniWriterEnsureLineBuffer;
  gIniOutputDir := outputDir;
  gIniPerPlugin := perPlugin;
  gIniCombinedFileName := combinedFileName;
  gIniCurrentPlugin := '';
  gIniFilesCreated := 0;
  gIniCombinedFileStarted := False;
  gIniNeedCombinedPluginHeader := False;
  IniWriterResetPathCache;
  PluginGroupCacheReset;
  if Assigned(gIniPluginsStarted) then
    gIniPluginsStarted.Clear;
  IniWriterClearDeferredAggregate;
end;

//============================================================================
procedure IniWriterEnsurePlugin(const pluginName: string);
var
  path: string;
  newFile: boolean;
begin
  if gIniPerPlugin then begin
    path := IniWriterPerPluginPath(pluginName);
    if gIniCurrentPlugin <> pluginName then begin
      IniWriterFlushBuffer;
      gIniCurrentPlugin := pluginName;
      gIniActivePath := '';
    end;
    newFile := gIniPluginsStarted.IndexOf(pluginName) < 0;
    if newFile then
      gIniPluginsStarted.Add(pluginName);
    IniWriterActivatePath(path, newFile);
  end else begin
    if gIniCurrentPlugin <> pluginName then begin
      gIniCurrentPlugin := pluginName;
      gIniNeedCombinedPluginHeader := True;
    end;
    path := IniWriterCombinedPath;
    newFile := not gIniCombinedFileStarted;
    if newFile then
      gIniCombinedFileStarted := True;
    IniWriterActivatePath(path, newFile);
  end;
end;

//============================================================================
procedure IniWriterWriteLine(const line: string);
begin
  if not gIniWriterActive then
    Exit;
  if (not gIniPerPlugin) and gIniNeedCombinedPluginHeader then begin
    IniWriterQueueLine('//===== ' + gIniCurrentPlugin + ' =====');
    IniWriterQueueLine('');
    gIniNeedCombinedPluginHeader := False;
  end;
  IniWriterQueueLine(line);
end;

//============================================================================
procedure IniWriterWriteRecordBlock(const pluginName, commentLine, dataLine: string);
var
  emitLine: string;
begin
  IniWriterEnsurePlugin(pluginName);
  emitLine := dataLine;
  if gRestorationMode then
    emitLine := MidChainDedupeSetReplaceOps(emitLine);
  if not SnapshotLineHasOperations(emitLine) then
    Exit;
  IniWriterWriteLine(commentLine);
  IniWriterWriteLine(emitLine);
  IniWriterWriteLine('');
end;

//============================================================================
procedure IniWriterWriteRecordLines(const pluginName, commentLine: string;
  lines: TStringList);
var
  i: integer;
  emitLine: string;
begin
  IniWriterEnsurePlugin(pluginName);
  if gRestorationMode then begin
    if not Assigned(gIniMergeScratch) then
      gIniMergeScratch := TStringList.Create;
    gIniMergeScratch.Clear;
    if Assigned(lines) then begin
      for i := 0 to Pred(lines.Count) do begin
        emitLine := MidChainDedupeSetReplaceOps(lines[i]);
        if SnapshotLineHasOperations(emitLine) then
          gIniMergeScratch.Add(emitLine);
      end;
    end;
    if gIniMergeScratch.Count = 0 then
      Exit;
    IniWriterWriteLine(commentLine);
    for i := 0 to Pred(gIniMergeScratch.Count) do
      IniWriterWriteLine(gIniMergeScratch[i]);
    IniWriterWriteLine('');
    Exit;
  end;
  IniWriterWriteLine(commentLine);
  if Assigned(lines) then begin
    for i := 0 to Pred(lines.Count) do
      IniWriterWriteLine(lines[i]);
  end;
  IniWriterWriteLine('');
end;

//============================================================================
function IniWriterEndOp: integer;
begin
  IniWriterCloseActiveFile;
  if IniDeferDiskFlush then
    IniWriterFlushDeferredAggregateToDisk;
  ReleaseHeavyExportScratch;
  if Assigned(gIniLineBuffer) then
    gIniLineBuffer.Clear;
  Result := gIniFilesCreated;
end;

//============================================================================
procedure SnapEnsureMasterCache;
begin
  if not Assigned(gSnapMasterCacheKeys) then
    gSnapMasterCacheKeys := TStringList.Create;
  if not Assigned(gSnapMasterCacheVals) then begin
    gSnapMasterCacheVals := TStringList.Create;
  end;
end;

//============================================================================
procedure SnapMasterCacheClear;
begin
  if Assigned(gSnapMasterCacheKeys) then begin
    gSnapMasterCacheKeys.Free;
    gSnapMasterCacheKeys := nil;
  end;
  if Assigned(gSnapMasterCacheVals) then begin
    gSnapMasterCacheVals.Free;
    gSnapMasterCacheVals := nil;
  end;
  SnapRecordCacheClear;
end;

//============================================================================
procedure SnapEnsureRecordCache;
begin
  if not Assigned(gSnapRecordCacheKeys) then
    gSnapRecordCacheKeys := TStringList.Create;
  if not Assigned(gSnapRecordCacheVals) then
    gSnapRecordCacheVals := TStringList.Create;
end;

//============================================================================
function SnapRecordCacheKey(e: IInterface; const fieldTag: string): string;
begin
  // Override identity (FormIDRef), not filter/master identity — multiple plugins
  // overriding the same master must not share keywords/perks/spells cache rows.
  Result := FormIDRef(e) + '|' + fieldTag;
end;

//============================================================================
function SnapRecordCacheLookup(const key: string; var cached: string): boolean;
var
  idx: integer;
begin
  Result := False;
  cached := '';
  SnapEnsureRecordCache;
  idx := gSnapRecordCacheKeys.IndexOf(key);
  if idx < 0 then
    Exit;
  if idx >= gSnapRecordCacheVals.Count then
    Exit;
  cached := gSnapRecordCacheVals[idx];
  Result := True;
end;

//============================================================================
procedure SnapRecordCachePut(const key, val: string);
var
  idx: integer;
begin
  SnapEnsureRecordCache;
  idx := gSnapRecordCacheKeys.IndexOf(key);
  if idx >= 0 then
    gSnapRecordCacheVals[idx] := val
  else begin
    gSnapRecordCacheKeys.Add(key);
    gSnapRecordCacheVals.Add(val);
  end;
end;

//============================================================================
function SnapMasterCacheKey(master: IInterface; const fieldTag: string): string;
begin
  Result := MasterFormIDRef(master) + '|' + fieldTag;
end;

//============================================================================
function SnapMasterCacheIndex(const key: string): integer;
begin
  SnapEnsureMasterCache;
  Result := gSnapMasterCacheKeys.IndexOf(key);
end;

//============================================================================
procedure SnapMasterCachePut(const key, val: string);
var
  idx: integer;
begin
  SnapEnsureMasterCache;
  idx := gSnapMasterCacheKeys.IndexOf(key);
  if idx >= 0 then
    gSnapMasterCacheVals[idx] := val
  else begin
    gSnapMasterCacheKeys.Add(key);
    gSnapMasterCacheVals.Add(val);
  end;
end;

//============================================================================
function SnapMasterCacheValueAt(idx: integer): string;
begin
  Result := '';
  if idx < 0 then
    Exit;
  SnapEnsureMasterCache;
  Result := StringListItemAt(gSnapMasterCacheVals, idx);
end;

end.
'