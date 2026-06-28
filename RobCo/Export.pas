{
  Export op indices and batch dispatch.
}
unit Export;

uses 'RobCo\Common', 'RobCo\ListExport', 'RobCo\Snapshot';

const
  idxLVLI = 0;
  idxCONT = 1;
  idxExportRACE = 2;
  idxExportNPC = 3;
  idxExportFLST = 4;
  idxExportCOBJ = 5;
  idxExportMISC = 6;
  idxExportALCH = 7;
  idxExportARMO = 8;
  idxExportWEAP = 9;
  idxExportAMMO = 10;
  idxExportOMOD = 11;

  OpCount = 12;
  CombinedIniFileName = 'RobCo Tools.ini';

//============================================================================
function OperationIsListType(opIndex: integer): boolean;
begin
  Result := False;
  if opIndex = idxLVLI then begin
    Result := True;
    Exit;
  end;
  if opIndex = idxCONT then begin
    Result := True;
    Exit;
  end;
  if opIndex = idxExportFLST then
    Result := True;
end;

//============================================================================
function OperationIsSnapshotType(opIndex: integer): boolean;
begin
  Result := False;
  if opIndex < 0 then
    Exit;
  if OperationIsListType(opIndex) then
    Exit;
  Result := True;
end;

//============================================================================
function OpLabelForOp(opIndex: integer): string;
begin
  case opIndex of
    idxLVLI:
      if FO4Game then
        Result := 'LVLI / CONT'
      else
        Result := 'LVLI';
    idxCONT: Result := 'CONT';
    idxExportFLST: Result := 'FLST';
    idxExportNPC: Result := 'NPC_';
    idxExportRACE: Result := 'RACE';
    idxExportALCH: Result := 'ALCH';
    idxExportAMMO: Result := 'AMMO';
    idxExportARMO: Result := 'ARMO';
    idxExportCOBJ: Result := 'COBJ';
    idxExportMISC: Result := 'MISC';
    idxExportOMOD: Result := 'OMOD';
    idxExportWEAP: Result := 'WEAP';
  else
    Result := '';
  end;
end;

//============================================================================
function OpIndexFromDisplayOrder(displayItem: integer): integer;
begin
  case displayItem of
    0: Result := idxLVLI;
    1: Result := idxCONT;
    2: Result := idxExportFLST;
    3: Result := idxExportNPC;
    4: Result := idxExportRACE;
    5: Result := idxExportALCH;
    6: Result := idxExportAMMO;
    7: Result := idxExportARMO;
    8: Result := idxExportCOBJ;
    9: Result := idxExportMISC;
    10: Result := idxExportOMOD;
    11: Result := idxExportWEAP;
  else
    Result := -1;
  end;
end;

//============================================================================
function OpIndexFromListItem(listItem: integer; opMap: TStringList): integer;
var
  item: integer;
begin
  item := listItem;
  if item < 0 then
    item := 0;
  Result := OpIndexFromDisplayOrder(item);
  if Assigned(opMap) then begin
    if item >= 0 then begin
      if item < opMap.Count then
        Result := StrToIntDef(opMap[item], Result);
    end;
  end;
end;

//============================================================================
procedure PopulateOperationCheckList(clb: TCheckListBox; opMap: TStringList);
var
  i, op: integer;
begin
  clb.Items.Clear;
  opMap.Clear;
  for i := 0 to Pred(OpCount) do begin
    op := OpIndexFromDisplayOrder(i);
    if op = idxExportOMOD then begin
      if not FO4Game then
        Continue;
    end;
    if op = idxCONT then begin
      if FO4Game then
        Continue;
    end;
    clb.Items.Add(OpLabelForOp(op));
    opMap.Add(IntToStr(op));
  end;
end;

//============================================================================
function DefaultOutputFileName(opIndex: integer): string;
begin
  Result := CombinedIniFileName;
end;

//============================================================================
function ExportRunSelectedOps(slSelected: TStringList; const exportBasePath: string;
  var totalFiles, combinedFiles: integer): boolean;
var
  i, op, numFiles: integer;
  exportRoot: string;
begin
  Result := True;
  totalFiles := 0;
  combinedFiles := 0;
  RefreshDeploymentModeCache;
  gSnapItmGateActive := not gExportForwardItms;
  exportRoot := EnsureTrailingBackslash(exportBasePath) + PatcherFrameworkRoot;
  gPatcherRootDirBare := exportRoot;
  // DEBUG_INJECT_PERFMON_HOOK purge_destination_run_selected_ops
  for i := 0 to Pred(gSelectedOps.Count) do begin
    op := StrToIntDef(gSelectedOps[i], -1);
    if op < 0 then
      Continue;
    if not EnsurePatcherOutputDir(exportBasePath, op) then begin
      Result := False;
      Exit;
    end;
    ProgressSetOp(i + 1, gSelectedOps.Count, '');
    IniWriterBeginOp(gPatcherOutputDir, gPerPlugin,
      DefaultOutputFileName(op));
    ExportPluginsForOp(slSelected, op);
    numFiles := IniWriterEndOp;
    if gPerPlugin then begin
      if numFiles > 0 then
        totalFiles := totalFiles + numFiles;
    end else if numFiles > 0 then
      combinedFiles := combinedFiles + numFiles;
  end;
end;

//============================================================================
function RecordSigForOp(op: integer): string;
begin
  Result := OpLabelForOp(op);
end;

//============================================================================
function FilterPrefixForOp(op: integer): string;
begin
  case op of
    idxExportCOBJ: Result := FilterCobjs;
    idxExportMISC: Result := FilterMiscs;
    idxExportALCH: Result := FilterAlchs;
    idxExportARMO: Result := FilterArmors;
    idxExportWEAP: Result := FilterWeapons;
    idxExportAMMO: Result := FilterAmmos;
    idxExportOMOD: Result := FilterOmod;
    idxExportRACE: Result := FilterRaces;
    idxExportNPC: Result := FilterNpcs;
  else
    Result := '';
  end;
end;

//============================================================================
procedure ExportRecordForOp(e: IInterface; op: integer;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  case op of
    idxExportCOBJ:
      ExportCOBJ(e, forwardItms, overridesOnly, shortComment);
    idxExportMISC:
      ExportMISC(e, forwardItms, overridesOnly, shortComment);
    idxExportALCH:
      ExportALCH(e, forwardItms, overridesOnly, shortComment);
    idxExportARMO:
      ExportARMO(e, forwardItms, overridesOnly, shortComment);
    idxExportWEAP:
      ExportWEAP(e, forwardItms, overridesOnly, shortComment);
    idxExportAMMO:
      ExportAMMO(e, forwardItms, overridesOnly, shortComment);
    idxExportOMOD:
      ExportOMOD(e, forwardItms, overridesOnly, shortComment);
    idxExportRACE:
      ExportRACE(e, forwardItms, overridesOnly, shortComment);
    idxExportNPC:
      ExportNPC(e, forwardItms, overridesOnly, shortComment);
  end;
  if op = idxExportRACE then
    SnapshotClearNpcPatchOutput
  else if op = idxExportNPC then
    SnapshotClearNpcPatchOutput;
  if not SnapConsumeDeferWrapperClear then
    SnapClearFieldScratch;
end;

//============================================================================
function SnapshotCobjGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotCobjExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportCOBJ, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function SnapshotMiscGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotMiscExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportMISC, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function SnapshotAlchGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotAlchExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportALCH, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function SnapshotArmoGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotArmoExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportARMO, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function SnapshotWeapGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotWeapExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportWEAP, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function SnapshotAmmoGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotAmmoExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportAMMO, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function SnapshotOmodGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotOmodExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportOMOD, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function SnapshotRaceGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotRaceExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportRACE, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function SnapshotNpcGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := ShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure SnapshotNpcExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  ExportRecordForOp(e, idxExportNPC, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure SnapshotGateAndExportRecord(e: IInterface; op: integer;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  case op of
    idxExportCOBJ: begin
      if not SnapshotCobjGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotCobjExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportMISC: begin
      if not SnapshotMiscGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotMiscExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportALCH: begin
      if not SnapshotAlchGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotAlchExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportARMO: begin
      if not SnapshotArmoGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotArmoExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportWEAP: begin
      if not SnapshotWeapGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotWeapExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportAMMO: begin
      if not SnapshotAmmoGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotAmmoExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportOMOD: begin
      if not SnapshotOmodGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotOmodExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportRACE: begin
      if not SnapshotRaceGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotRaceExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportNPC: begin
      if not SnapshotNpcGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      SnapshotNpcExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
  end;
end;

//============================================================================
procedure ExportPluginsSnapshot(slSelected: TStringList; op: integer;
  forwardItms, overridesOnly, shortComment: boolean);
var
  i, j: integer;
  f, grp, e: IInterface;
  sig, pluginName: string;
begin
  sig := RecordSigForOp(op);
  if sig = '' then
    Exit;
  SnapMasterCacheClear;
  SnapClearFieldScratch;
  SnapReleaseListScratch;
  SnapshotClearNpcPatchOutput;
  if op = idxExportNPC then begin
    BeginNpcPluginExport;
  end else if op = idxExportRACE then begin
    BeginNpcPluginExport;
  end;
  for i := 0 to Pred(slSelected.Count) do begin
    f := ObjectToElement(slSelected.Objects[i]);
    pluginName := GetFileName(f);
    grp := GroupBySignature(f, sig);
    if not Assigned(grp) then
      Continue;
    if overridesOnly then begin
      if not PluginGroupHasOverridesCachedGrp(f, sig, grp) then
        Continue;
    end;
    for j := 0 to Pred(ElementCount(grp)) do begin
      e := ElementByIndex(grp, j);
      if Signature(e) <> sig then
        Continue;
      SnapshotGateAndExportRecord(e, op, forwardItms, overridesOnly, shortComment);
    end;
    ProgressReportPlugin(pluginName, i);
    SnapClearFieldScratch;
    SnapReleaseListScratch;
    SnapshotClearNpcPatchOutput;
    ReleaseExportDiffScratch;
  end;
end;

//============================================================================
procedure ExportPluginsCobj(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportCOBJ,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsMisc(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportMISC,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsAlch(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportALCH,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsArmo(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportARMO,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsWeap(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportWEAP,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsAmmo(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportAMMO,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsOmod(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportOMOD,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsRace(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportRACE,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsNpc(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  ExportPluginsSnapshot(slSelected, idxExportNPC,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure ExportPluginsForOp(slSelected: TStringList; opIndex: integer);
var
  opLabel: string;
begin
  opLabel := OpLabelForOp(opIndex);
  if gProgressOpTotal > 0 then begin
    ProgressSetOp(gProgressOpNum, gProgressOpTotal, opLabel);
    ReportProgressOpBoundary('RobCo [' + IntToStr(gProgressOpNum) + '/' +
      IntToStr(gProgressOpTotal) + '] Started ' + opLabel);
  end;
  case opIndex of
    idxLVLI:
      if FO4Game then
        ExportPluginsLeveledListAndContainers(slSelected,
          gListExportAdd, gListExportRemove,
          gExportForwardItms, gOverridesOnly, gPerPlugin)
      else
        ExportPluginsLvli(slSelected,
          gListExportAdd, gListExportRemove,
          gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxCONT:
      ExportPluginsCont(slSelected,
        gListExportAdd, gListExportRemove,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportFLST:
      ExportPluginsFlst(slSelected,
        gListExportAdd, gListExportRemove,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportCOBJ:
      ExportPluginsCobj(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportMISC:
      ExportPluginsMisc(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportALCH:
      ExportPluginsAlch(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportARMO:
      ExportPluginsArmo(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportWEAP:
      ExportPluginsWeap(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportAMMO:
      ExportPluginsAmmo(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportOMOD:
      ExportPluginsOmod(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportRACE:
      ExportPluginsRace(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
    idxExportNPC:
      ExportPluginsNpc(slSelected,
        gExportForwardItms, gOverridesOnly, gPerPlugin);
  end;
  if gProgressOpTotal > 0 then
    ReportProgressOpBoundary('RobCo [' + IntToStr(gProgressOpNum) + '/' +
      IntToStr(gProgressOpTotal) + '] Stopped ' + opLabel);
end;

end.
