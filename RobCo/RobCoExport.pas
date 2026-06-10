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
  case opIndex of
    idxLVLI:
      if RobCoFO4Game then
        Result := 'Leveled List Export.ini'
      else
        Result := 'LVLI Export.ini';
    idxCONT: Result := 'CONT Export.ini';
    idxExportRACE: Result := 'RACE Export.ini';
    idxExportNPC: Result := 'NPC Export.ini';
    idxExportFLST: Result := 'FLST Export.ini';
    idxExportCOBJ: Result := 'COBJ Export.ini';
    idxExportMISC: Result := 'MISC Export.ini';
    idxExportALCH: Result := 'ALCH Export.ini';
    idxExportARMO: Result := 'ARMO Export.ini';
    idxExportWEAP: Result := 'WEAP Export.ini';
    idxExportAMMO: Result := 'AMMO Export.ini';
    idxExportOMOD: Result := 'OMOD Export.ini';
  else
    Result := 'RobCo Export.ini';
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
end;

//============================================================================
procedure RobCoExportPluginsSnapshot(slSelected: TStringList; op: integer;
  forwardItms, overridesOnly, shortComment: boolean);
var
  i, j: integer;
  f, grp, e: IInterface;
  sig: string;
begin
  sig := RobCoRecordSigForOp(op);
  if sig = '' then
    Exit;
  if op = idxExportNPC then begin
    RobCoBeginNpcPluginExport;
  end else if op = idxExportRACE then begin
    RobCoBeginNpcPluginExport;
  end;
  for i := 0 to Pred(slSelected.Count) do begin
    f := ObjectToElement(slSelected.Objects[i]);
    grp := GroupBySignature(f, sig);
    if not Assigned(grp) then
      Continue;
    for j := 0 to Pred(ElementCount(grp)) do begin
      e := ElementByIndex(grp, j);
      RobCoExportRecordForOp(e, op, forwardItms, overridesOnly, shortComment);
    end;
  end;
end;

//============================================================================
procedure RobCoExportPluginsForOp(slSelected: TStringList; opIndex: integer);
begin
  case opIndex of
    idxLVLI:
      if RobCoFO4Game then
        RobCoExportPluginsLeveledListAndContainers(slSelected,
          gRobCoListExportAdd, gRobCoListExportRemove,
          gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin)
      else
        RobCoExportPluginsList(slSelected, RobCoListKindLVLI,
          gRobCoListExportAdd, gRobCoListExportRemove,
          gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxCONT:
      RobCoExportPluginsList(slSelected, RobCoListKindCONT,
        gRobCoListExportAdd, gRobCoListExportRemove,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportFLST:
      RobCoExportPluginsList(slSelected, RobCoListKindFLST,
        gRobCoListExportAdd, gRobCoListExportRemove,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
    idxExportCOBJ, idxExportMISC, idxExportALCH, idxExportARMO, idxExportWEAP,
    idxExportAMMO, idxExportOMOD, idxExportRACE, idxExportNPC:
      RobCoExportPluginsSnapshot(slSelected, opIndex,
        gRobCoExportForwardItms, gRobCoOverridesOnly, gRobCoPerPlugin);
  end;
end;

end.
