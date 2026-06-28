{
  Hub dialog: record-type checklist, export options, layout.
}
unit HubDialog;

uses 'RobCo\Export';

const
  RecordSelAll = 0;
  RecordSelNone = 1;
  RecordSelInvert = 2;

var
  opMap: TStringList;
  gDlgLayoutReady: boolean;
  gDlgCachedHasList: boolean;
  gDlgCachedHasSnapshot: boolean;
  gDlgCachedMidChainRestore: boolean;
  gDlgCachedHintOp: integer;
  gDlgRefreshDepth: integer;
  gDlgRefreshQueue: integer;
  gDlgClbOperation: TCheckListBox;
  gDlgGbRecordTypes: TGroupBox;
  gDlgGbExportOptions: TGroupBox;
  gDlgGbRecordOperation: TGroupBox;
  gDlgGbOutput: TGroupBox;
  gDlgPnlOutputLayout: TPanel;
  gDlgPnlOutputBaseline: TPanel;
  gDlgChkOverridesOnly: TCheckBox;
  gDlgChkForwardItms: TCheckBox;
  gDlgChkWriteAllFields: TCheckBox;
  gDlgChkListAdd: TCheckBox;
  gDlgChkListRemove: TCheckBox;
  gDlgRbOutputPerPlugin: TRadioButton;
  gDlgRbOutputCombined: TRadioButton;
  gDlgRbMidChainRestore: TRadioButton;
  gDlgRbEspReplacement: TRadioButton;
  gDlgBtnOk: TButton;
  gDlgBtnCancel: TButton;
  gDlgBtnSelectAll: TButton;
  gDlgBtnSelectNone: TButton;
  gDlgBtnInvert: TButton;
  gDlgSlChecked: TStringList;

//============================================================================
procedure CollectSelectedOps(clb: TCheckListBox; opMap: TStringList; slOut: TStringList);
var
  i: integer;
begin
  slOut.Clear;
  for i := 0 to Pred(clb.Items.Count) do begin
    if clb.Checked[i] then
      slOut.Add(opMap[i]);
  end;
end;

//============================================================================
function SelectionHasListType(slOps: TStringList): boolean;
var
  i, op: integer;
begin
  Result := False;
  for i := 0 to Pred(slOps.Count) do begin
    op := StrToIntDef(slOps[i], -1);
    if OperationIsListType(op) then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
function SelectionHasSnapshotType(slOps: TStringList): boolean;
var
  i, op: integer;
begin
  Result := False;
  for i := 0 to Pred(slOps.Count) do begin
    op := StrToIntDef(slOps[i], -1);
    if OperationIsSnapshotType(op) then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
function SingleSelectedOp(slOps: TStringList): integer;
begin
  if slOps.Count = 1 then
    Result := StrToIntDef(slOps[0], -1)
  else
    Result := -1;
end;

//============================================================================
procedure SetGroupBoxItemStack(gb: TGroupBox; itemCount: integer);
const
  InnerTop = 22;
  InnerBottom = 10;
  ItemHeight = 17;
  ItemGap = 6;
var
  blockH: integer;
begin
  if itemCount < 1 then
    itemCount := 1;
  blockH := itemCount * ItemHeight + (itemCount - 1) * ItemGap;
  gb.Height := InnerTop + blockH + InnerBottom;
end;

//============================================================================
function GroupBoxStartTop(gb: TGroupBox; itemCount: integer): integer;
const
  InnerTop = 22;
  InnerBottom = 10;
  ItemHeight = 17;
  ItemGap = 6;
var
  blockH, innerH: integer;
begin
  if itemCount < 1 then
    itemCount := 1;
  blockH := itemCount * ItemHeight + (itemCount - 1) * ItemGap;
  innerH := gb.Height - InnerTop - InnerBottom;
  Result := InnerTop + (innerH - blockH) div 2;
end;

//============================================================================
function GroupBoxInnerWidth(gb: TGroupBox): integer;
begin
  Result := gb.Width - 24;
end;

//============================================================================
procedure ResetDialogLayoutCache;
begin
  gDlgLayoutReady := False;
  gDlgCachedHasList := False;
  gDlgCachedHasSnapshot := False;
  gDlgCachedMidChainRestore := False;
  gDlgCachedHintOp := -2;
  gDlgRefreshDepth := 0;
  gDlgRefreshQueue := 0;
end;

//============================================================================
procedure ClearDialogControls;
begin
  gDlgClbOperation := nil;
  gDlgGbRecordTypes := nil;
  gDlgGbExportOptions := nil;
  gDlgGbRecordOperation := nil;
  gDlgGbOutput := nil;
  gDlgPnlOutputLayout := nil;
  gDlgPnlOutputBaseline := nil;
  gDlgChkOverridesOnly := nil;
  gDlgChkForwardItms := nil;
  gDlgChkWriteAllFields := nil;
  gDlgChkListAdd := nil;
  gDlgChkListRemove := nil;
  gDlgRbOutputPerPlugin := nil;
  gDlgRbOutputCombined := nil;
  gDlgRbMidChainRestore := nil;
  gDlgRbEspReplacement := nil;
  gDlgBtnOk := nil;
  gDlgBtnCancel := nil;
  gDlgBtnSelectAll := nil;
  gDlgBtnSelectNone := nil;
  gDlgBtnInvert := nil;
end;

//============================================================================
procedure BindDialogControls(frm: TForm);
begin
  gDlgClbOperation := TCheckListBox(frm.FindComponent('clbOperation'));
  gDlgGbRecordTypes := TGroupBox(frm.FindComponent('gbRecordTypes'));
  gDlgGbExportOptions := TGroupBox(frm.FindComponent('gbExportOptions'));
  gDlgGbRecordOperation := TGroupBox(frm.FindComponent('gbRecordOperation'));
  gDlgGbOutput := TGroupBox(frm.FindComponent('gbOutput'));
  gDlgPnlOutputLayout := TPanel(frm.FindComponent('pnlOutputLayout'));
  gDlgPnlOutputBaseline := TPanel(frm.FindComponent('pnlOutputBaseline'));
  gDlgChkOverridesOnly := TCheckBox(frm.FindComponent('chkOverridesOnly'));
  gDlgChkForwardItms := TCheckBox(frm.FindComponent('chkForwardItms'));
  gDlgChkWriteAllFields := TCheckBox(frm.FindComponent('chkWriteAllFields'));
  gDlgChkListAdd := TCheckBox(frm.FindComponent('chkListAdd'));
  gDlgChkListRemove := TCheckBox(frm.FindComponent('chkListRemove'));
  gDlgRbOutputPerPlugin := TRadioButton(frm.FindComponent('rbOutputPerPlugin'));
  gDlgRbOutputCombined := TRadioButton(frm.FindComponent('rbOutputCombined'));
  gDlgRbMidChainRestore := TRadioButton(frm.FindComponent('rbMidChainRestore'));
  gDlgRbEspReplacement := TRadioButton(frm.FindComponent('rbEspReplacement'));
  gDlgBtnOk := TButton(frm.FindComponent('btnOk'));
  gDlgBtnCancel := TButton(frm.FindComponent('btnCancel'));
  gDlgBtnSelectAll := TButton(frm.FindComponent('btnSelectAll'));
  gDlgBtnSelectNone := TButton(frm.FindComponent('btnSelectNone'));
  gDlgBtnInvert := TButton(frm.FindComponent('btnInvert'));
  if not Assigned(gDlgSlChecked) then
    gDlgSlChecked := TStringList.Create;
end;

//============================================================================
procedure LayoutRecordTypeButtons;
var
  innerW, btnGap, btnW, btnTop: integer;
begin
  if not Assigned(gDlgGbRecordTypes) then
    Exit;
  if not Assigned(gDlgClbOperation) then
    Exit;
  innerW := gDlgGbRecordTypes.Width - 16;
  btnGap := 4;
  btnW := (innerW - 2 * btnGap) div 3;
  btnTop := gDlgClbOperation.Top + gDlgClbOperation.Height + 4;
  if Assigned(gDlgBtnSelectAll) then begin
    gDlgBtnSelectAll.Caption := 'All';
    gDlgBtnSelectAll.Left := 8;
    gDlgBtnSelectAll.Top := btnTop;
    gDlgBtnSelectAll.Width := btnW;
    gDlgBtnSelectAll.Height := 25;
  end;
  if Assigned(gDlgBtnSelectNone) then begin
    gDlgBtnSelectNone.Caption := 'None';
    gDlgBtnSelectNone.Left := 8 + btnW + btnGap;
    gDlgBtnSelectNone.Top := btnTop;
    gDlgBtnSelectNone.Width := btnW;
    gDlgBtnSelectNone.Height := 25;
  end;
  if Assigned(gDlgBtnInvert) then begin
    gDlgBtnInvert.Caption := 'Invert';
    gDlgBtnInvert.Left := 8 + 2 * (btnW + btnGap);
    gDlgBtnInvert.Top := btnTop;
    gDlgBtnInvert.Width := btnW;
    gDlgBtnInvert.Height := 25;
  end;
  gDlgGbRecordTypes.Height := btnTop + 25 + 10;
end;

//============================================================================
procedure ComputeDialogSelection(frm: TForm;
  var hasListType, hasSnapshotType: boolean; var hintOp: integer);
begin
  hasListType := False;
  hasSnapshotType := False;
  hintOp := -1;
  if not Assigned(gDlgClbOperation) then
    Exit;
  if not Assigned(gDlgSlChecked) then
    Exit;
  gDlgSlChecked.Clear;
  CollectSelectedOps(gDlgClbOperation, opMap, gDlgSlChecked);
  hasListType := SelectionHasListType(gDlgSlChecked);
  hasSnapshotType := SelectionHasSnapshotType(gDlgSlChecked);
  hintOp := SingleSelectedOp(gDlgSlChecked);
end;

//============================================================================
procedure ApplyDeploymentOutputLayoutDefaults(frm: TForm);
begin
  if not Assigned(gDlgRbOutputPerPlugin) then
    Exit;
  if not Assigned(gDlgRbOutputCombined) then
    Exit;
  if Assigned(gDlgRbMidChainRestore) then begin
    if gDlgRbMidChainRestore.Checked then begin
      gDlgRbOutputCombined.Checked := True;
      gPerPlugin := False;
      Exit;
    end;
  end;
  gDlgRbOutputPerPlugin.Checked := True;
  gPerPlugin := True;
end;

//============================================================================
procedure HubSyncGlobalsFromDialog(frm: TForm);
var
  hasSnapshotType: boolean;
begin
  if not Assigned(gDlgClbOperation) then
    Exit;
  if not Assigned(opMap) then
    Exit;
  if not Assigned(gSelectedOps) then
    Exit;

  CollectSelectedOps(gDlgClbOperation, opMap, gSelectedOps);

  if Assigned(gDlgChkListAdd) then
    gListExportAdd := gDlgChkListAdd.Checked;
  if Assigned(gDlgChkListRemove) then
    gListExportRemove := gDlgChkListRemove.Checked;

  if Assigned(gDlgRbEspReplacement) then begin
    if gDlgRbEspReplacement.Checked then begin
      gExportDeployment := DeploymentEspReplace;
      gCompareDeclaredMasters := True;
    end else begin
      gExportDeployment := DeploymentRestoration;
      gCompareDeclaredMasters := False;
    end;
  end;
  RefreshDeploymentModeCache;

  if Assigned(gDlgRbOutputPerPlugin) then
    gPerPlugin := gDlgRbOutputPerPlugin.Checked
  else
    gPerPlugin := True;

  if IsRestorationMode then begin
    gOverridesOnly := True;
    gExportForwardItms := False;
    if Assigned(gDlgChkOverridesOnly) then
      gDlgChkOverridesOnly.Checked := True;
    if Assigned(gDlgChkForwardItms) then
      gDlgChkForwardItms.Checked := False;
  end else begin
    if Assigned(gDlgChkOverridesOnly) then
      gOverridesOnly := gDlgChkOverridesOnly.Checked
    else
      gOverridesOnly := True;
    if gPerPlugin then begin
      if Assigned(gDlgChkForwardItms) then
        gExportForwardItms := gDlgChkForwardItms.Checked
      else
        gExportForwardItms := False;
    end else
      gExportForwardItms := False;
  end;

  if Assigned(gDlgChkWriteAllFields) then
    gExportWriteAllFields := gDlgChkWriteAllFields.Checked
  else
    gExportWriteAllFields := False;
  hasSnapshotType := SelectionHasSnapshotType(gSelectedOps);
  if not hasSnapshotType then
    gExportWriteAllFields := False;
end;

//============================================================================
procedure HubInitDialogGlobals;
begin
  gListExportAdd := True;
  gListExportRemove := True;
  gExportForwardItms := False;
  gPerPlugin := False;
  gOverridesOnly := True;
  gExportWriteAllFields := False;
  gExportDeployment := DeploymentRestoration;
  gCompareDeclaredMasters := False;
  RefreshDeploymentModeCache;
end;

//============================================================================
procedure HubApplyGlobalsToControls(frm: TForm);
begin
  if Assigned(gDlgRbOutputPerPlugin) then begin
    if gPerPlugin then
      gDlgRbOutputPerPlugin.Checked := True
    else if Assigned(gDlgRbOutputCombined) then
      gDlgRbOutputCombined.Checked := True;
  end;
  if IsRestorationMode then
    Exit;
  if Assigned(gDlgChkOverridesOnly) then begin
    gDlgChkOverridesOnly.Enabled := True;
    gDlgChkOverridesOnly.Checked := gOverridesOnly;
    gDlgChkOverridesOnly.Hint :=
      'When on, export only records with an external master (overrides).';
  end;
  if not Assigned(gDlgChkForwardItms) then
    Exit;
  if not gPerPlugin then begin
    gDlgChkForwardItms.Enabled := False;
    gDlgChkForwardItms.Hint :=
      'Forward ITMs is not available with Combined output (use Per plugin).';
    Exit;
  end;
  gDlgChkForwardItms.Enabled := True;
  gDlgChkForwardItms.Checked := gExportForwardItms;
  gDlgChkForwardItms.Hint :=
    'When off, skip unchanged (ITM) records vs master. When on, emit master-matched content.';
end;

//============================================================================
procedure UpdateOutputHints(frm: TForm; hintOp: integer);
var
  outputHintSuffix: string;
begin
  if not Assigned(gDlgRbOutputPerPlugin) then
    Exit;
  if not Assigned(gDlgRbOutputCombined) then
    Exit;
  if hintOp >= 0 then begin
    outputHintSuffix := PatcherCategoryForOperation(hintOp) + '\';
    gDlgRbOutputPerPlugin.Hint := 'Example: MyMod\' + PatcherFrameworkRoot +
      outputHintSuffix + 'MyMod.esp.ini';
    gDlgRbOutputCombined.Hint := 'Example: MyMod\' + PatcherFrameworkRoot +
      outputHintSuffix + DefaultOutputFileName(hintOp);
  end else begin
    gDlgRbOutputPerPlugin.Hint := 'Example: MyMod\' + PatcherFrameworkRoot +
      '<category>\MyMod.esp.ini (one file per type under each category folder)';
    gDlgRbOutputCombined.Hint := 'Example: MyMod\' + PatcherFrameworkRoot +
      '<category>\RobCo Tools.ini (one file per selected type)';
  end;
end;

//============================================================================
function CombinedOutputAllowed(hasSnapshotType: boolean): boolean;
begin
  Result := False;
  if gExportForwardItms then
    Exit;
  Result := True;
end;

//============================================================================
procedure RefreshCombinedOutputAvailability(frm: TForm;
  hasSnapshotType, hintOp: integer);
var
  disabledHint: string;
begin
  if not Assigned(gDlgRbOutputCombined) then
    Exit;
  if CombinedOutputAllowed(hasSnapshotType) then begin
    gDlgRbOutputCombined.Enabled := True;
    UpdateOutputHints(frm, hintOp);
    Exit;
  end;
  disabledHint := 'Combined output requires Forward ITMs off.';
  gDlgRbOutputCombined.Hint := disabledHint;
  gDlgRbOutputCombined.Enabled := False;
  if not gPerPlugin then begin
    gPerPlugin := True;
    if Assigned(gDlgRbOutputPerPlugin) then
      gDlgRbOutputPerPlugin.Checked := True;
  end;
end;

//============================================================================
function DialogOwnerForm: TForm;
begin
  Result := nil;
  if Assigned(gDlgGbRecordTypes) then
    Result := TForm(gDlgGbRecordTypes.Parent);
end;

//============================================================================
procedure ExportOptionsChanged(Sender: TObject);
var
  frm: TForm;
begin
  frm := DialogOwnerForm;
  if not Assigned(frm) then
    Exit;
  RefreshToolsDialog(frm);
end;

//============================================================================
procedure DeploymentModeChanged(Sender: TObject);
var
  frm: TForm;
begin
  frm := DialogOwnerForm;
  if not Assigned(frm) then
    Exit;
  ApplyDeploymentOutputLayoutDefaults(frm);
  RefreshToolsDialog(frm);
end;

//============================================================================
procedure OutputFormatChanged(Sender: TObject);
var
  frm: TForm;
begin
  frm := DialogOwnerForm;
  if not Assigned(frm) then
    Exit;
  RefreshToolsDialog(frm);
end;

//============================================================================
procedure LayoutToolsDialog(frm: TForm;
  hasListType, hasSnapshotType: boolean; hintOp: integer);
var
  topOffset, startTop, innerWidth, exportOptionCount, exportRow: integer;
  midChainRestore, showOverridesForward: boolean;
begin
  if not Assigned(gDlgGbRecordTypes) then
    Exit;
  topOffset := gDlgGbRecordTypes.Top + gDlgGbRecordTypes.Height + 8;
  midChainRestore := IsRestorationMode;
  showOverridesForward := not midChainRestore;
  gDlgChkOverridesOnly.Visible := showOverridesForward;
  gDlgChkForwardItms.Visible := showOverridesForward;
  exportOptionCount := 0;
  if showOverridesForward then
    exportOptionCount := exportOptionCount + 2;
  if hasSnapshotType then
    exportOptionCount := exportOptionCount + 1;
  if exportOptionCount > 0 then begin
    gDlgGbExportOptions.Visible := True;
    gDlgGbExportOptions.Top := topOffset;
    gDlgGbExportOptions.Left := gDlgGbRecordTypes.Left;
    gDlgGbExportOptions.Width := gDlgGbRecordTypes.Width;
    SetGroupBoxItemStack(gDlgGbExportOptions, exportOptionCount);
    startTop := GroupBoxStartTop(gDlgGbExportOptions, exportOptionCount);
    innerWidth := GroupBoxInnerWidth(gDlgGbExportOptions);
    exportRow := 0;
    if showOverridesForward then begin
      gDlgChkOverridesOnly.Left := 12;
      gDlgChkOverridesOnly.Top := startTop + exportRow * 23;
      gDlgChkOverridesOnly.Width := innerWidth;
      exportRow := exportRow + 1;
      gDlgChkForwardItms.Left := 12;
      gDlgChkForwardItms.Top := startTop + exportRow * 23;
      gDlgChkForwardItms.Width := innerWidth;
      exportRow := exportRow + 1;
    end;
    gDlgChkWriteAllFields.Visible := hasSnapshotType;
    if hasSnapshotType then begin
      gDlgChkWriteAllFields.Left := 12;
      gDlgChkWriteAllFields.Top := startTop + exportRow * 23;
      gDlgChkWriteAllFields.Width := innerWidth;
    end;
    topOffset := gDlgGbExportOptions.Top + gDlgGbExportOptions.Height + 8;
  end else begin
    gDlgGbExportOptions.Visible := False;
    gDlgChkWriteAllFields.Visible := False;
  end;
  gDlgGbRecordOperation.Visible := hasListType;
  if hasListType then begin
    gDlgGbRecordOperation.Top := topOffset;
    gDlgGbRecordOperation.Left := gDlgGbRecordTypes.Left;
    gDlgGbRecordOperation.Width := gDlgGbRecordTypes.Width;
    SetGroupBoxItemStack(gDlgGbRecordOperation, 2);
    startTop := GroupBoxStartTop(gDlgGbRecordOperation, 2);
    innerWidth := GroupBoxInnerWidth(gDlgGbRecordOperation);
    gDlgChkListAdd.Left := 12;
    gDlgChkListAdd.Top := startTop;
    gDlgChkListAdd.Width := innerWidth;
    gDlgChkListRemove.Left := 12;
    gDlgChkListRemove.Top := startTop + 23;
    gDlgChkListRemove.Width := innerWidth;
    topOffset := gDlgGbRecordOperation.Top + gDlgGbRecordOperation.Height + 8;
  end;
  gDlgGbOutput.Top := topOffset;
  gDlgGbOutput.Left := gDlgGbRecordTypes.Left;
  gDlgGbOutput.Width := gDlgGbRecordTypes.Width;
  SetGroupBoxItemStack(gDlgGbOutput, 2);
  startTop := GroupBoxStartTop(gDlgGbOutput, 2);
  innerWidth := GroupBoxInnerWidth(gDlgGbOutput);
  if Assigned(gDlgPnlOutputLayout) then begin
    gDlgPnlOutputLayout.Left := 12;
    gDlgPnlOutputLayout.Top := startTop;
    gDlgPnlOutputLayout.Width := (innerWidth - 8) div 2;
    gDlgPnlOutputLayout.Height := 40;
  end;
  if Assigned(gDlgPnlOutputBaseline) then begin
    gDlgPnlOutputBaseline.Left := 12 + gDlgPnlOutputLayout.Width + 8;
    gDlgPnlOutputBaseline.Top := startTop;
    gDlgPnlOutputBaseline.Width := (innerWidth - 8) div 2;
    gDlgPnlOutputBaseline.Height := 40;
  end;
  gDlgRbOutputCombined.Left := 0;
  gDlgRbOutputCombined.Top := 0;
  gDlgRbOutputCombined.Width := gDlgPnlOutputLayout.Width;
  gDlgRbOutputCombined.ShowHint := True;
  gDlgRbOutputPerPlugin.Left := 0;
  gDlgRbOutputPerPlugin.Top := 23;
  gDlgRbOutputPerPlugin.Width := gDlgPnlOutputLayout.Width;
  gDlgRbOutputPerPlugin.ShowHint := True;
  gDlgRbMidChainRestore.Left := 0;
  gDlgRbMidChainRestore.Top := 0;
  gDlgRbMidChainRestore.Width := gDlgPnlOutputBaseline.Width;
  gDlgRbMidChainRestore.ShowHint := True;
  gDlgRbEspReplacement.Left := 0;
  gDlgRbEspReplacement.Top := 23;
  gDlgRbEspReplacement.Width := gDlgPnlOutputBaseline.Width;
  gDlgRbEspReplacement.ShowHint := True;
  topOffset := gDlgGbOutput.Top + gDlgGbOutput.Height + 8;
  gDlgBtnOk.Top := topOffset + 8;
  gDlgBtnCancel.Top := topOffset + 8;
  frm.Height := gDlgBtnOk.Top + gDlgBtnOk.Height + 48;
end;

//============================================================================
procedure ExecuteToolsDialogRefresh(frm: TForm);
var
  hasListType, hasSnapshotType: boolean;
  hintOp: integer;
  midChainRestore: boolean;
  needFullLayout: boolean;
begin
  HubSyncGlobalsFromDialog(frm);
  ComputeDialogSelection(frm, hasListType, hasSnapshotType, hintOp);
  midChainRestore := IsRestorationMode;
  needFullLayout := not gDlgLayoutReady;
  if not needFullLayout then begin
    if hasListType <> gDlgCachedHasList then
      needFullLayout := True
    else if hasSnapshotType <> gDlgCachedHasSnapshot then
      needFullLayout := True
    else if midChainRestore <> gDlgCachedMidChainRestore then
      needFullLayout := True;
  end;
  if needFullLayout then
    LayoutToolsDialog(frm, hasListType, hasSnapshotType, hintOp)
  else if hintOp <> gDlgCachedHintOp then
    UpdateOutputHints(frm, hintOp);
  HubApplyGlobalsToControls(frm);
  RefreshCombinedOutputAvailability(frm, hasSnapshotType, hintOp);
  HubSyncGlobalsFromDialog(frm);
  gDlgCachedHasList := hasListType;
  gDlgCachedHasSnapshot := hasSnapshotType;
  gDlgCachedMidChainRestore := midChainRestore;
  gDlgCachedHintOp := hintOp;
  gDlgLayoutReady := True;
end;

//============================================================================
procedure DrainToolsDialogRefreshQueue(frm: TForm);
begin
  while gDlgRefreshQueue > 0 do begin
    gDlgRefreshQueue := 0;
    gDlgRefreshDepth := 1;
    ExecuteToolsDialogRefresh(frm);
    gDlgRefreshDepth := 0;
  end;
end;

//============================================================================
procedure RefreshToolsDialog(frm: TForm);
begin
  gDlgRefreshQueue := gDlgRefreshQueue + 1;
  if gDlgRefreshDepth > 0 then
    Exit;
  DrainToolsDialogRefreshQueue(frm);
end;

//============================================================================
procedure OperationChanged(Sender: TObject);
begin
  RefreshToolsDialog(TForm(TCheckListBox(Sender).Parent.Parent));
end;

//============================================================================
procedure ApplyRecordTypeSelection(frm: TForm; mode: integer);
var
  i: integer;
begin
  if not Assigned(gDlgClbOperation) then
    Exit;
  for i := 0 to Pred(gDlgClbOperation.Items.Count) do begin
    if mode = RecordSelAll then
      gDlgClbOperation.Checked[i] := True
    else if mode = RecordSelNone then
      gDlgClbOperation.Checked[i] := False
    else if mode = RecordSelInvert then
      gDlgClbOperation.Checked[i] := not gDlgClbOperation.Checked[i];
  end;
  RefreshToolsDialog(frm);
end;

//============================================================================
procedure SelectAllRecordTypesClick(Sender: TObject);
begin
  ApplyRecordTypeSelection(TForm(TButton(Sender).Parent.Parent), RecordSelAll);
end;

//============================================================================
procedure SelectNoneRecordTypesClick(Sender: TObject);
begin
  ApplyRecordTypeSelection(TForm(TButton(Sender).Parent.Parent), RecordSelNone);
end;

//============================================================================
procedure InvertRecordTypesClick(Sender: TObject);
begin
  ApplyRecordTypeSelection(TForm(TButton(Sender).Parent.Parent), RecordSelInvert);
end;

//============================================================================
procedure ToolsOkClick(Sender: TObject);
var
  frm: TForm;
begin
  frm := TForm(TButton(Sender).Parent);
  HubSyncGlobalsFromDialog(frm);
  if gSelectedOps.Count = 0 then begin
    MessageDlg('Select at least one record type.', mtWarning, [mbOk], 0);
    Exit;
  end;
  if SelectionHasListType(gSelectedOps) then begin
    if not gListExportAdd then begin
      if not gListExportRemove then begin
        MessageDlg('Select at least one of Add entries or Remove dropped entries.',
          mtWarning, [mbOk], 0);
        Exit;
      end;
    end;
  end;
  if not gPerPlugin then begin
    if not CombinedOutputAllowed(SelectionHasSnapshotType(gSelectedOps)) then begin
      MessageDlg('Combined output requires Forward ITMs off.',
        mtWarning, [mbOk], 0);
      Exit;
    end;
  end;
  frm.ModalResult := mrOk;
end;

//============================================================================
function ShowToolsDialog: boolean;
var
  frm: TForm;
  clbOperation: TCheckListBox;
  gbRecordTypes, gbExportOptions, gbRecordOperation, gbOutput: TGroupBox;
  pnlOutputLayout, pnlOutputBaseline: TPanel;
  chkListAdd, chkListRemove, chkForwardItms, chkOverridesOnly,
  chkWriteAllFields: TCheckBox;
  rbOutputPerPlugin, rbOutputCombined: TRadioButton;
  rbMidChainRestore, rbEspReplacement: TRadioButton;
  btnOk, btnCancel, btnSelectAll, btnSelectNone, btnInvert: TButton;
begin
  Result := False;
  opMap := TStringList.Create;
  frm := TForm.Create(nil);
  frm.Caption := 'RobCo Tools';
    frm.Width := 360;
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;

    gbRecordTypes := TGroupBox.Create(frm);
    gbRecordTypes.Parent := frm;
    gbRecordTypes.Name := 'gbRecordTypes';
    gbRecordTypes.Left := 16;
    gbRecordTypes.Top := 12;
    gbRecordTypes.Width := frm.Width - 48;
    gbRecordTypes.Caption := 'Record type';

    clbOperation := TCheckListBox.Create(frm);
    clbOperation.Parent := gbRecordTypes;
    clbOperation.Name := 'clbOperation';
    clbOperation.Left := 8;
    clbOperation.Top := 20;
    clbOperation.Width := gbRecordTypes.Width - 16;
    PopulateOperationCheckList(clbOperation, opMap);
    clbOperation.Height := opMap.Count * 18 + 4;
    clbOperation.OnClickCheck := OperationChanged;

    btnSelectAll := TButton.Create(frm);
    btnSelectAll.Parent := gbRecordTypes;
    btnSelectAll.Name := 'btnSelectAll';
    btnSelectAll.OnClick := SelectAllRecordTypesClick;

    btnSelectNone := TButton.Create(frm);
    btnSelectNone.Parent := gbRecordTypes;
    btnSelectNone.Name := 'btnSelectNone';
    btnSelectNone.OnClick := SelectNoneRecordTypesClick;

    btnInvert := TButton.Create(frm);
    btnInvert.Parent := gbRecordTypes;
    btnInvert.Name := 'btnInvert';
    btnInvert.OnClick := InvertRecordTypesClick;

    gbExportOptions := TGroupBox.Create(frm);
    gbExportOptions.Parent := frm;
    gbExportOptions.Name := 'gbExportOptions';
    gbExportOptions.Caption := 'Export options';
    gbExportOptions.Width := gbRecordTypes.Width;

    gbRecordOperation := TGroupBox.Create(frm);
    gbRecordOperation.Parent := frm;
    gbRecordOperation.Name := 'gbRecordOperation';
    gbRecordOperation.Caption := 'Record operation';
    gbRecordOperation.Width := gbRecordTypes.Width;

    chkOverridesOnly := TCheckBox.Create(frm);
    chkOverridesOnly.Parent := gbExportOptions;
    chkOverridesOnly.Name := 'chkOverridesOnly';
    chkOverridesOnly.Height := 17;
    chkOverridesOnly.Caption := 'Overrides only';
    chkOverridesOnly.Checked := True;
    chkOverridesOnly.ShowHint := True;
    chkOverridesOnly.Hint :=
      'Export only override records (not IsMaster), not new plugin-local masters.';
    chkOverridesOnly.OnClick := ExportOptionsChanged;

    chkForwardItms := TCheckBox.Create(frm);
    chkForwardItms.Parent := gbExportOptions;
    chkForwardItms.Name := 'chkForwardItms';
    chkForwardItms.Height := 17;
    chkForwardItms.Caption := 'Forward ITMs';
    chkForwardItms.Checked := False;
    chkForwardItms.ShowHint := True;
    chkForwardItms.Hint :=
      'Emit ITM and master-matched content instead of skipping it.';
    chkForwardItms.OnClick := ExportOptionsChanged;

    chkWriteAllFields := TCheckBox.Create(frm);
    chkWriteAllFields.Parent := gbExportOptions;
    chkWriteAllFields.Name := 'chkWriteAllFields';
    chkWriteAllFields.Height := 17;
    chkWriteAllFields.Caption := 'Write all fields';
    chkWriteAllFields.Checked := False;
    chkWriteAllFields.ShowHint := True;
    chkWriteAllFields.Hint :=
      'Snapshot exports only. On: append every article filter slot and operation field ' +
      'unchanged slots as =none so you can trim when authoring a batch patch. Does not ' +
      'change override selection or ITM skip logic. Off (default): sparse mirror lines only.';
    chkWriteAllFields.OnClick := ExportOptionsChanged;

    chkListAdd := TCheckBox.Create(frm);
    chkListAdd.Parent := gbRecordOperation;
    chkListAdd.Name := 'chkListAdd';
    chkListAdd.Height := 17;
    chkListAdd.Caption := 'Add entries';
    chkListAdd.Checked := True;
    chkListAdd.ShowHint := True;
    chkListAdd.Hint :=
      'Write addTo* lines for list entries in the selected plugin.';

    chkListRemove := TCheckBox.Create(frm);
    chkListRemove.Parent := gbRecordOperation;
    chkListRemove.Name := 'chkListRemove';
    chkListRemove.Height := 17;
    chkListRemove.Caption := 'Remove dropped entries';
    chkListRemove.Checked := True;
    chkListRemove.ShowHint := True;
    chkListRemove.Hint :=
      'Write removeFrom* lines for master list rows dropped by the override.';

    gbOutput := TGroupBox.Create(frm);
    gbOutput.Parent := frm;
    gbOutput.Name := 'gbOutput';
    gbOutput.Caption := 'Output mode';
    gbOutput.Width := gbRecordTypes.Width;

    pnlOutputLayout := TPanel.Create(frm);
    pnlOutputLayout.Parent := gbOutput;
    pnlOutputLayout.Name := 'pnlOutputLayout';
    pnlOutputLayout.BevelOuter := bvNone;
    pnlOutputLayout.Caption := '';

    pnlOutputBaseline := TPanel.Create(frm);
    pnlOutputBaseline.Parent := gbOutput;
    pnlOutputBaseline.Name := 'pnlOutputBaseline';
    pnlOutputBaseline.BevelOuter := bvNone;
    pnlOutputBaseline.Caption := '';

    rbOutputCombined := TRadioButton.Create(frm);
    rbOutputCombined.Parent := pnlOutputLayout;
    rbOutputCombined.Name := 'rbOutputCombined';
    rbOutputCombined.Height := 17;
    rbOutputCombined.Caption := 'Combined';
    rbOutputCombined.Checked := True;
    rbOutputCombined.OnClick := OutputFormatChanged;

    rbOutputPerPlugin := TRadioButton.Create(frm);
    rbOutputPerPlugin.Parent := pnlOutputLayout;
    rbOutputPerPlugin.Name := 'rbOutputPerPlugin';
    rbOutputPerPlugin.Height := 17;
    rbOutputPerPlugin.Caption := 'Per plugin';
    rbOutputPerPlugin.OnClick := OutputFormatChanged;

    rbMidChainRestore := TRadioButton.Create(frm);
    rbMidChainRestore.Parent := pnlOutputBaseline;
    rbMidChainRestore.Name := 'rbMidChainRestore';
    rbMidChainRestore.Height := 17;
    rbMidChainRestore.Caption := 'Mid-chain restore';
    rbMidChainRestore.Checked := True;
    rbMidChainRestore.ShowHint := True;
    rbMidChainRestore.Hint :=
      'All ESPs stay loaded. Patcher restores changes earlier overrides made that the ' +
      'winning override does not carry. Does not export winning overrides.';
    rbMidChainRestore.OnClick := DeploymentModeChanged;

    rbEspReplacement := TRadioButton.Create(frm);
    rbEspReplacement.Parent := pnlOutputBaseline;
    rbEspReplacement.Name := 'rbEspReplacement';
    rbEspReplacement.Height := 17;
    rbEspReplacement.Caption := 'ESP replacement';
    rbEspReplacement.ShowHint := True;
    rbEspReplacement.Hint :=
      'Diff vs declared plugin masters. Export patches so you can remove source ESPs ' +
      'from load order.';
    rbEspReplacement.OnClick := DeploymentModeChanged;

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Name := 'btnOk';
    btnOk.Caption := 'OK';
    btnOk.Left := frm.Width - 184;
    btnOk.Width := 75;
    btnOk.OnClick := ToolsOkClick;

    btnCancel := TButton.Create(frm);
    btnCancel.Parent := frm;
    btnCancel.Name := 'btnCancel';
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := btnOk.Left + btnOk.Width + 8;
    btnCancel.Width := 75;

    BindDialogControls(frm);
    HubInitDialogGlobals;
    LayoutRecordTypeButtons;
    ResetDialogLayoutCache;
    RefreshToolsDialog(frm);

    if frm.ShowModal = mrOk then
      Result := True;

  ClearDialogControls;
  opMap.Free;
  opMap := nil;
  frm.Free;
end;

end.
