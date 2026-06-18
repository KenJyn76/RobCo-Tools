{
  Export op indices and batch dispatch.
}
unit RobCoExport;

uses 'RobCo\RobCoCommon', 'RobCo\RobCoListExport', 'RobCo\RobCoSnapshot';

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

  RobCoOpCount = 12;
  RobCoCombinedIniFileName = 'RobCo Tools.ini';

//============================================================================
function RobCoOperationIsListType(opIndex: integer): boolean;
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
function RobCoOperationIsSnapshotType(opIndex: integer): boolean;
begin
  Result := False;
  if opIndex < 0 then
    Exit;
  if RobCoOperationIsListType(opIndex) then
    Exit;
  Result := True;
end;

//============================================================================
function RobCoOpLabelForOp(opIndex: integer): string;
begin
  case opIndex of
    idxLVLI:
      if RobCoFO4Game then
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
function RobCoOpIndexFromDisplayOrder(displayItem: integer): integer;
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
function RobCoOpIndexFromListItem(listItem: integer; opMap: TStringList): integer;
var
  item: integer;
begin
  item := listItem;
  if item < 0 then
    item := 0;
  Result := RobCoOpIndexFromDisplayOrder(item);
  if Assigned(opMap) then begin
    if item >= 0 then begin
      if item < opMap.Count then
        Result := StrToIntDef(opMap[item], Result);
    end;
  end;
end;

//============================================================================
procedure RobCoPopulateOperationCheckList(clb: TCheckListBox; opMap: TStringList);
var
  i, op: integer;
begin
  clb.Items.Clear;
  opMap.Clear;
  for i := 0 to Pred(RobCoOpCount) do begin
    op := RobCoOpIndexFromDisplayOrder(i);
    if op = idxExportOMOD then begin
      if not RobCoFO4Game then
        Continue;
    end;
    if op = idxCONT then begin
      if RobCoFO4Game then
        Continue;
    end;
    clb.Items.Add(RobCoOpLabelForOp(op));
    opMap.Add(IntToStr(op));
  end;
end;

//============================================================================
function DefaultOutputFileName(opIndex: integer): string;
begin
  Result := RobCoCombinedIniFileName;
end;

//============================================================================
function RobCoExportRunSelectedOps(slSelected: TStringList; const exportBasePath: string;
  var totalFiles, combinedFiles: integer): boolean;
var
  i, op, numFiles: integer;
  exportRoot: string;
begin
  Result := True;
  totalFiles := 0;
  combinedFiles := 0;
  gRobCoSnapItmGateActive := not gRobCoExportForwardItms;
  exportRoot := RobCoEnsureTrailingBackslash(exportBasePath) + RobCoPatcherFrameworkRoot;
  gRobCoPatcherRootDirBare := exportRoot;
  // DEBUG_INJECT_PERFMON_HOOK purge_destination_run_selected_ops
  for i := 0 to Pred(gRobCoSelectedOps.Count) do begin
    op := StrToIntDef(gRobCoSelectedOps[i], -1);
    if op < 0 then
      Continue;
    if not RobCoEnsurePatcherOutputDir(exportBasePath, op) then begin
      Result := False;
      Exit;
    end;
    RobCoProgressSetOp(i + 1, gRobCoSelectedOps.Count, '');
    RobCoIniWriterBeginOp(gRobCoPatcherOutputDir, gRobCoPerPlugin,
      DefaultOutputFileName(op));
    RobCoExportPluginsForOp(slSelected, op);
    numFiles := RobCoIniWriterEndOp;
    if gRobCoPerPlugin then begin
      if numFiles > 0 then
        totalFiles := totalFiles + numFiles;
    end else if numFiles > 0 then
      combinedFiles := combinedFiles + numFiles;
  end;
end;

//============================================================================
function RobCoRecordSigForOp(op: integer): string;
begin
  Result := RobCoOpLabelForOp(op);
end;

//============================================================================
function RobCoFilterPrefixForOp(op: integer): string;
begin
  case op of
    idxExportCOBJ: Result := RobCoFilterCobjs;
    idxExportMISC: Result := RobCoFilterMiscs;
    idxExportALCH: Result := RobCoFilterAlchs;
    idxExportARMO: Result := RobCoFilterArmors;
    idxExportWEAP: Result := RobCoFilterWeapons;
    idxExportAMMO: Result := RobCoFilterAmmos;
    idxExportOMOD: Result := RobCoFilterOmod;
    idxExportRACE: Result := RobCoFilterRaces;
    idxExportNPC: Result := RobCoFilterNpcs;
  else
    Result := '';
  end;
end;

//============================================================================
procedure RobCoExportRecordForOp(e: IInterface; op: integer;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  case op of
    idxExportCOBJ:
      ExportCOBJToRobCo(e, forwardItms, overridesOnly, shortComment);
    idxExportMISC:
      ExportMISCToRobCo(e, forwardItms, overridesOnly, shortComment);
    idxExportALCH:
      ExportALCHToRobCo(e, forwardItms, overridesOnly, shortComment);
    idxExportARMO:
      ExportARMOToRobCo(e, forwardItms, overridesOnly, shortComment);
    idxExportWEAP:
      ExportWEAPToRobCo(e, forwardItms, overridesOnly, shortComment);
    idxExportAMMO:
      ExportAMMOToRobCo(e, forwardItms, overridesOnly, shortComment);
    idxExportOMOD:
      ExportOMODToRobCo(e, forwardItms, overridesOnly, shortComment);
    idxExportRACE:
      ExportRACEToRobCo(e, forwardItms, overridesOnly, shortComment);
    idxExportNPC:
      ExportNPCToRobCo(e, forwardItms, overridesOnly, shortComment);
  end;
  if op = idxExportRACE then
    RobCoSnapshotClearNpcPatchOutput
  else if op = idxExportNPC then
    RobCoSnapshotClearNpcPatchOutput;
  RobCoSnapClearFieldScratch;
end;

//============================================================================
function RobCoSnapshotCobjGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotCobjExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportCOBJ, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoSnapshotMiscGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotMiscExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportMISC, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoSnapshotAlchGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotAlchExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportALCH, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoSnapshotArmoGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotArmoExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportARMO, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoSnapshotWeapGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotWeapExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportWEAP, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoSnapshotAmmoGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotAmmoExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportAMMO, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoSnapshotOmodGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotOmodExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportOMOD, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoSnapshotRaceGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotRaceExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportRACE, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
function RobCoSnapshotNpcGateOverride(e: IInterface; forwardItms, overridesOnly: boolean): boolean;
begin
  Result := RobCoShouldProcessOverride(e, forwardItms, overridesOnly);
end;

//============================================================================
procedure RobCoSnapshotNpcExportRecord(e: IInterface; forwardItms, overridesOnly,
  shortComment: boolean);
begin
  RobCoExportRecordForOp(e, idxExportNPC, forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoSnapshotGateAndExportRecord(e: IInterface; op: integer;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  case op of
    idxExportCOBJ: begin
      if not RobCoSnapshotCobjGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotCobjExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportMISC: begin
      if not RobCoSnapshotMiscGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotMiscExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportALCH: begin
      if not RobCoSnapshotAlchGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotAlchExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportARMO: begin
      if not RobCoSnapshotArmoGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotArmoExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportWEAP: begin
      if not RobCoSnapshotWeapGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotWeapExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportAMMO: begin
      if not RobCoSnapshotAmmoGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotAmmoExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportOMOD: begin
      if not RobCoSnapshotOmodGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotOmodExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportRACE: begin
      if not RobCoSnapshotRaceGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotRaceExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
    idxExportNPC: begin
      if not RobCoSnapshotNpcGateOverride(e, forwardItms, overridesOnly) then begin
        // DEBUG_INJECT_PERFMON_COUNTER count.snapshot.gate.skip 1
        Exit;
      end;
      RobCoSnapshotNpcExportRecord(e, forwardItms, overridesOnly, shortComment);
    end;
  end;
end;

//============================================================================
procedure RobCoExportPluginsSnapshot(slSelected: TStringList; op: integer;
  forwardItms, overridesOnly, shortComment: boolean);
var
  i, j: integer;
  f, grp, e: IInterface;
  sig, pluginName: string;
begin
  sig := RobCoRecordSigForOp(op);
  if sig = '' then
    Exit;
  RobCoSnapMasterCacheClear;
  RobCoSnapClearFieldScratch;
  RobCoSnapReleaseListScratch;
  RobCoSnapshotClearNpcPatchOutput;
  if op = idxExportNPC then begin
    RobCoBeginNpcPluginExport;
  end else if op = idxExportRACE then begin
    RobCoBeginNpcPluginExport;
  end;
  for i := 0 to Pred(slSelected.Count) do begin
    f := ObjectToElement(slSelected.Objects[i]);
    pluginName := GetFileName(f);
    grp := GroupBySignature(f, sig);
    if not Assigned(grp) then
      Continue;
    if overridesOnly then begin
      if not RobCoPluginGroupHasOverridesCachedGrp(f, sig, grp) then
        Continue;
    end;
    for j := 0 to Pred(ElementCount(grp)) do begin
      e := ElementByIndex(grp, j);
      if Signature(e) <> sig then
        Continue;
      RobCoSnapshotGateAndExportRecord(e, op, forwardItms, overridesOnly, shortComment);
    end;
    RobCoProgressReportPlugin(pluginName, i);
    RobCoSnapClearFieldScratch;
    RobCoSnapReleaseListScratch;
    RobCoSnapshotClearNpcPatchOutput;
    RobCoReleaseExportDiffScratch;
  end;
end;

//============================================================================
procedure RobCoExportPluginsCobj(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportCOBJ,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsMisc(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportMISC,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsAlch(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportALCH,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsArmo(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportARMO,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsWeap(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportWEAP,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsAmmo(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportAMMO,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsOmod(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportOMOD,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsRace(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportRACE,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsNpc(slSelected: TStringList;
  forwardItms, overridesOnly, shortComment: boolean);
begin
  RobCoExportPluginsSnapshot(slSelected, idxExportNPC,
    forwardItms, overridesOnly, shortComment);
end;

//============================================================================
procedure RobCoExportPluginsForOp(slSelected: TStringList; opIndex: integer);
var
  opLabel: string;
begin
  opLabel := RobCoOpLabelForOp(opIndex);
  if gRobCoProgressOpTotal > 0 then begin
    RobCoProgressSetOp(gRobCoProgressOpNum, gRobCoProgressOpTotal, opLabel);
    RobCoReportProgressOpBoundary('RobCo [' + IntToStr(gRobCoProgressOpNum) + '/' +
      IntToStr(gRobCoProgressOpTotal) + '] Started ' + opLabel);
  end;
  case opIndex of
    idxLVLI:
      if RobCoFO4Game then
        RobCoExportPluginsLeveledListAndContainers(slSelected,
          gRobCoListExportAdd, gRobCoListExportRemove,
          gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin)
      else
        RobCoExportPluginsLvli(slSelected,
          gRobCoListExportAdd, gRobCoListExportRemove,
          gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxCONT:
      RobCoExportPluginsCont(slSelected,
        gRobCoListExportAdd, gRobCoListExportRemove,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportFLST:
      RobCoExportPluginsFlst(slSelected,
        gRobCoListExportAdd, gRobCoListExportRemove,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportCOBJ:
      RobCoExportPluginsCobj(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportMISC:
      RobCoExportPluginsMisc(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportALCH:
      RobCoExportPluginsAlch(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportARMO:
      RobCoExportPluginsArmo(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportWEAP:
      RobCoExportPluginsWeap(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportAMMO:
      RobCoExportPluginsAmmo(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportOMOD:
      RobCoExportPluginsOmod(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportRACE:
      RobCoExportPluginsRace(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportNPC:
      RobCoExportPluginsNpc(slSelected,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
  end;
  if gRobCoProgressOpTotal > 0 then
    RobCoReportProgressOpBoundary('RobCo [' + IntToStr(gRobCoProgressOpNum) + '/' +
      IntToStr(gRobCoProgressOpTotal) + '] Stopped ' + opLabel);
end;

end.
