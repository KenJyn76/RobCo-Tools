{
  Hub dialog: record-type checklist, export options, layout.
}
unit RobCoHubDialog;

uses 'RobCo\RobCoExport';

const
  RobCoRecordSelAll = 0;
  RobCoRecordSelNone = 1;
  RobCoRecordSelInvert = 2;

var
  robCoOpMap: TStringList;
  gRobCoDlgLayoutReady: boolean;
  gRobCoDlgCachedHasList: boolean;
  gRobCoDlgCachedHasSnapshot: boolean;
  gRobCoDlgCachedHintOp: integer;
  gRobCoDlgRefreshDepth: integer;
  gRobCoDlgRefreshPending: boolean;
  gRobCoDlgClbOperation: TCheckListBox;
  gRobCoDlgGbRecordTypes: TGroupBox;
  gRobCoDlgGbExportOptions: TGroupBox;
  gRobCoDlgGbRecordOperation: TGroupBox;
  gRobCoDlgGbOutput: TGroupBox;
  gRobCoDlgChkOverridesOnly: TCheckBox;
  gRobCoDlgChkForwardItms: TCheckBox;
  gRobCoDlgChkWriteAllFields: TCheckBox;
  gRobCoDlgChkListAdd: TCheckBox;
  gRobCoDlgChkListRemove: TCheckBox;
  gRobCoDlgRbOutputPerPlugin: TRadioButton;
  gRobCoDlgRbOutputCombined: TRadioButton;
  gRobCoDlgBtnOk: TButton;
  gRobCoDlgBtnCancel: TButton;
  gRobCoDlgBtnSelectAll: TButton;
  gRobCoDlgBtnSelectNone: TButton;
  gRobCoDlgBtnInvert: TButton;
  gRobCoDlgSlChecked: TStringList;

//============================================================================
procedure RobCoCollectSelectedOps(clb: TCheckListBox; opMap: TStringList; slOut: TStringList);
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
function RobCoSelectionHasListType(slOps: TStringList): boolean;
var
  i, op: integer;
begin
  Result := False;
  for i := 0 to Pred(slOps.Count) do begin
    op := StrToIntDef(slOps[i], -1);
    if RobCoOperationIsListType(op) then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
function RobCoSelectionHasSnapshotType(slOps: TStringList): boolean;
var
  i, op: integer;
begin
  Result := False;
  for i := 0 to Pred(slOps.Count) do begin
    op := StrToIntDef(slOps[i], -1);
    if RobCoOperationIsSnapshotType(op) then begin
      Result := True;
      Exit;
    end;
  end;
end;

//============================================================================
function RobCoSingleSelectedOp(slOps: TStringList): integer;
begin
  if slOps.Count = 1 then
    Result := StrToIntDef(slOps[0], -1)
  else
    Result := -1;
end;

//============================================================================
procedure RobCoSetGroupBoxItemStack(gb: TGroupBox; itemCount: integer);
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
function RobCoGroupBoxStartTop(gb: TGroupBox; itemCount: integer): integer;
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
function RobCoGroupBoxInnerWidth(gb: TGroupBox): integer;
begin
  Result := gb.Width - 24;
end;

//============================================================================
procedure RobCoResetDialogLayoutCache;
begin
  gRobCoDlgLayoutReady := False;
  gRobCoDlgCachedHasList := False;
  gRobCoDlgCachedHasSnapshot := False;
  gRobCoDlgCachedHintOp := -2;
  gRobCoDlgRefreshDepth := 0;
  gRobCoDlgRefreshPending := False;
end;

//============================================================================
procedure RobCoClearDialogControls;
begin
  gRobCoDlgClbOperation := nil;
  gRobCoDlgGbRecordTypes := nil;
  gRobCoDlgGbExportOptions := nil;
  gRobCoDlgGbRecordOperation := nil;
  gRobCoDlgGbOutput := nil;
  gRobCoDlgChkOverridesOnly := nil;
  gRobCoDlgChkForwardItms := nil;
  gRobCoDlgChkWriteAllFields := nil;
  gRobCoDlgChkListAdd := nil;
  gRobCoDlgChkListRemove := nil;
  gRobCoDlgRbOutputPerPlugin := nil;
  gRobCoDlgRbOutputCombined := nil;
  gRobCoDlgBtnOk := nil;
  gRobCoDlgBtnCancel := nil;
  gRobCoDlgBtnSelectAll := nil;
  gRobCoDlgBtnSelectNone := nil;
  gRobCoDlgBtnInvert := nil;
end;

//============================================================================
procedure RobCoBindDialogControls(frm: TForm);
begin
  gRobCoDlgClbOperation := TCheckListBox(frm.FindComponent('clbOperation'));
  gRobCoDlgGbRecordTypes := TGroupBox(frm.FindComponent('gbRecordTypes'));
  gRobCoDlgGbExportOptions := TGroupBox(frm.FindComponent('gbExportOptions'));
  gRobCoDlgGbRecordOperation := TGroupBox(frm.FindComponent('gbRecordOperation'));
  gRobCoDlgGbOutput := TGroupBox(frm.FindComponent('gbOutput'));
  gRobCoDlgChkOverridesOnly := TCheckBox(frm.FindComponent('chkOverridesOnly'));
  gRobCoDlgChkForwardItms := TCheckBox(frm.FindComponent('chkForwardItms'));
  gRobCoDlgChkWriteAllFields := TCheckBox(frm.FindComponent('chkWriteAllFields'));
  gRobCoDlgChkListAdd := TCheckBox(frm.FindComponent('chkListAdd'));
  gRobCoDlgChkListRemove := TCheckBox(frm.FindComponent('chkListRemove'));
  gRobCoDlgRbOutputPerPlugin := TRadioButton(frm.FindComponent('rbOutputPerPlugin'));
  gRobCoDlgRbOutputCombined := TRadioButton(frm.FindComponent('rbOutputCombined'));
  gRobCoDlgBtnOk := TButton(frm.FindComponent('btnOk'));
  gRobCoDlgBtnCancel := TButton(frm.FindComponent('btnCancel'));
  gRobCoDlgBtnSelectAll := TButton(frm.FindComponent('btnSelectAll'));
  gRobCoDlgBtnSelectNone := TButton(frm.FindComponent('btnSelectNone'));
  gRobCoDlgBtnInvert := TButton(frm.FindComponent('btnInvert'));
  if not Assigned(gRobCoDlgSlChecked) then
    gRobCoDlgSlChecked := TStringList.Create;
end;

//============================================================================
procedure RobCoLayoutRecordTypeButtons;
var
  innerW, btnGap, btnW, btnTop: integer;
begin
  if not Assigned(gRobCoDlgGbRecordTypes) then
    Exit;
  if not Assigned(gRobCoDlgClbOperation) then
    Exit;
  innerW := gRobCoDlgGbRecordTypes.Width - 16;
  btnGap := 4;
  btnW := (innerW - 2 * btnGap) div 3;
  btnTop := gRobCoDlgClbOperation.Top + gRobCoDlgClbOperation.Height + 4;
  if Assigned(gRobCoDlgBtnSelectAll) then begin
    gRobCoDlgBtnSelectAll.Caption := 'All';
    gRobCoDlgBtnSelectAll.Left := 8;
    gRobCoDlgBtnSelectAll.Top := btnTop;
    gRobCoDlgBtnSelectAll.Width := btnW;
    gRobCoDlgBtnSelectAll.Height := 25;
  end;
  if Assigned(gRobCoDlgBtnSelectNone) then begin
    gRobCoDlgBtnSelectNone.Caption := 'None';
    gRobCoDlgBtnSelectNone.Left := 8 + btnW + btnGap;
    gRobCoDlgBtnSelectNone.Top := btnTop;
    gRobCoDlgBtnSelectNone.Width := btnW;
    gRobCoDlgBtnSelectNone.Height := 25;
  end;
  if Assigned(gRobCoDlgBtnInvert) then begin
    gRobCoDlgBtnInvert.Caption := 'Invert';
    gRobCoDlgBtnInvert.Left := 8 + 2 * (btnW + btnGap);
    gRobCoDlgBtnInvert.Top := btnTop;
    gRobCoDlgBtnInvert.Width := btnW;
    gRobCoDlgBtnInvert.Height := 25;
  end;
  gRobCoDlgGbRecordTypes.Height := btnTop + 25 + 10;
end;

//============================================================================
procedure RobCoComputeDialogSelection(frm: TForm;
  var hasListType, hasSnapshotType: boolean; var hintOp: integer);
begin
  hasListType := False;
  hasSnapshotType := False;
  hintOp := -1;
  if not Assigned(gRobCoDlgClbOperation) then
    Exit;
  if not Assigned(gRobCoDlgSlChecked) then
    Exit;
  gRobCoDlgSlChecked.Clear;
  RobCoCollectSelectedOps(gRobCoDlgClbOperation, robCoOpMap, gRobCoDlgSlChecked);
  hasListType := RobCoSelectionHasListType(gRobCoDlgSlChecked);
  hasSnapshotType := RobCoSelectionHasSnapshotType(gRobCoDlgSlChecked);
  hintOp := RobCoSingleSelectedOp(gRobCoDlgSlChecked);
end;

//============================================================================
procedure RobCoUpdateOutputHints(frm: TForm; hintOp: integer);
var
  outputHintSuffix: string;
begin
  if not Assigned(gRobCoDlgRbOutputPerPlugin) then
    Exit;
  if not Assigned(gRobCoDlgRbOutputCombined) then
    Exit;
  if hintOp >= 0 then begin
    outputHintSuffix := RobCoPatcherCategoryForOperation(hintOp) + '\';
    gRobCoDlgRbOutputPerPlugin.Hint := 'Example: MyMod\' + RobCoPatcherFrameworkRoot +
      outputHintSuffix + 'MyMod.esp.ini';
    gRobCoDlgRbOutputCombined.Hint := 'Example: MyMod\' + RobCoPatcherFrameworkRoot +
      outputHintSuffix + DefaultOutputFileName(hintOp);
  end else begin
    gRobCoDlgRbOutputPerPlugin.Hint := 'Example: MyMod\' + RobCoPatcherFrameworkRoot +
      '<category>\MyMod.esp.ini (one file per type under each category folder)';
    gRobCoDlgRbOutputCombined.Hint := 'Example: MyMod\' + RobCoPatcherFrameworkRoot +
      '<category>\RobCo Tools.ini (one file per selected type)';
  end;
end;

//============================================================================
function RobCoCombinedOutputAllowed(hasSnapshotType: boolean): boolean;
begin
  Result := False;
  if not Assigned(gRobCoDlgChkForwardItms) then
    Exit;
  if gRobCoDlgChkForwardItms.Checked then
    Exit;
  Result := True;
end;

//============================================================================
procedure RobCoRefreshCombinedOutputAvailability(frm: TForm;
  hasSnapshotType, hintOp: integer);
var
  disabledHint: string;
begin
  if not Assigned(gRobCoDlgRbOutputCombined) then
    Exit;
  if RobCoCombinedOutputAllowed(hasSnapshotType) then begin
    gRobCoDlgRbOutputCombined.Enabled := True;
    RobCoUpdateOutputHints(frm, hintOp);
    Exit;
  end;
  disabledHint := 'Combined output requires Forward ITMs off.';
  gRobCoDlgRbOutputCombined.Hint := disabledHint;
  gRobCoDlgRbOutputCombined.Enabled := False;
  if gRobCoDlgRbOutputCombined.Checked then begin
    if Assigned(gRobCoDlgRbOutputPerPlugin) then
      gRobCoDlgRbOutputPerPlugin.Checked := True;
  end;
end;

//============================================================================
procedure RobCoRefreshForwardItmsAvailability(frm: TForm);
begin
  if not Assigned(gRobCoDlgChkForwardItms) then
    Exit;
  if Assigned(gRobCoDlgRbOutputCombined) then begin
    if gRobCoDlgRbOutputCombined.Checked then begin
      gRobCoDlgChkForwardItms.Checked := False;
      gRobCoDlgChkForwardItms.Enabled := False;
      gRobCoDlgChkForwardItms.Hint :=
        'Forward ITMs is not available with Combined output (use Per plugin). ' +
        'ITM carry-forward increases combined dedupe load.';
      Exit;
    end;
  end;
  gRobCoDlgChkForwardItms.Enabled := True;
  gRobCoDlgChkForwardItms.Hint :=
    'When off, skip unchanged (ITM) records vs master. When on, emit master-matched content.';
end;

//============================================================================
procedure RobCoExportOptionsChanged(Sender: TObject);
var
  frm: TForm;
  hasListType, hasSnapshotType: boolean;
  hintOp: integer;
begin
  frm := TForm(TCheckBox(Sender).Parent.Parent);
  RobCoComputeDialogSelection(frm, hasListType, hasSnapshotType, hintOp);
  RobCoRefreshCombinedOutputAvailability(frm, hasSnapshotType, hintOp);
  RobCoRefreshForwardItmsAvailability(frm);
end;

//============================================================================
procedure RobCoOutputFormatChanged(Sender: TObject);
var
  frm: TForm;
  hasListType, hasSnapshotType: boolean;
  hintOp: integer;
begin
  frm := TForm(TRadioButton(Sender).Parent.Parent);
  RobCoComputeDialogSelection(frm, hasListType, hasSnapshotType, hintOp);
  RobCoRefreshCombinedOutputAvailability(frm, hasSnapshotType, hintOp);
  RobCoRefreshForwardItmsAvailability(frm);
end;

//============================================================================
procedure RobCoLayoutToolsDialog(frm: TForm;
  hasListType, hasSnapshotType: boolean; hintOp: integer);
var
  topOffset, startTop, innerWidth, exportOptionCount: integer;
begin
  if not Assigned(gRobCoDlgGbRecordTypes) then
    Exit;
  topOffset := gRobCoDlgGbRecordTypes.Top + gRobCoDlgGbRecordTypes.Height + 8;
  gRobCoDlgGbExportOptions.Top := topOffset;
  gRobCoDlgGbExportOptions.Left := gRobCoDlgGbRecordTypes.Left;
  gRobCoDlgGbExportOptions.Width := gRobCoDlgGbRecordTypes.Width;
  if hasSnapshotType then
    exportOptionCount := 3
  else
    exportOptionCount := 2;
  RobCoSetGroupBoxItemStack(gRobCoDlgGbExportOptions, exportOptionCount);
  startTop := RobCoGroupBoxStartTop(gRobCoDlgGbExportOptions, exportOptionCount);
  innerWidth := RobCoGroupBoxInnerWidth(gRobCoDlgGbExportOptions);
  gRobCoDlgChkOverridesOnly.Left := 12;
  gRobCoDlgChkOverridesOnly.Top := startTop;
  gRobCoDlgChkOverridesOnly.Width := innerWidth;
  gRobCoDlgChkForwardItms.Left := 12;
  gRobCoDlgChkForwardItms.Top := startTop + 23;
  gRobCoDlgChkForwardItms.Width := innerWidth;
  gRobCoDlgChkWriteAllFields.Visible := hasSnapshotType;
  if hasSnapshotType then begin
    gRobCoDlgChkWriteAllFields.Left := 12;
    gRobCoDlgChkWriteAllFields.Top := startTop + 46;
    gRobCoDlgChkWriteAllFields.Width := innerWidth;
  end;
  topOffset := gRobCoDlgGbExportOptions.Top + gRobCoDlgGbExportOptions.Height + 8;
  gRobCoDlgGbRecordOperation.Visible := hasListType;
  if hasListType then begin
    gRobCoDlgGbRecordOperation.Top := topOffset;
    gRobCoDlgGbRecordOperation.Left := gRobCoDlgGbRecordTypes.Left;
    gRobCoDlgGbRecordOperation.Width := gRobCoDlgGbRecordTypes.Width;
    RobCoSetGroupBoxItemStack(gRobCoDlgGbRecordOperation, 2);
    startTop := RobCoGroupBoxStartTop(gRobCoDlgGbRecordOperation, 2);
    innerWidth := RobCoGroupBoxInnerWidth(gRobCoDlgGbRecordOperation);
    gRobCoDlgChkListAdd.Left := 12;
    gRobCoDlgChkListAdd.Top := startTop;
    gRobCoDlgChkListAdd.Width := innerWidth;
    gRobCoDlgChkListRemove.Left := 12;
    gRobCoDlgChkListRemove.Top := startTop + 23;
    gRobCoDlgChkListRemove.Width := innerWidth;
    topOffset := gRobCoDlgGbRecordOperation.Top + gRobCoDlgGbRecordOperation.Height + 8;
  end;
  gRobCoDlgGbOutput.Top := topOffset;
  gRobCoDlgGbOutput.Left := gRobCoDlgGbRecordTypes.Left;
  gRobCoDlgGbOutput.Width := gRobCoDlgGbRecordTypes.Width;
  RobCoSetGroupBoxItemStack(gRobCoDlgGbOutput, 2);
  startTop := RobCoGroupBoxStartTop(gRobCoDlgGbOutput, 2);
  innerWidth := RobCoGroupBoxInnerWidth(gRobCoDlgGbOutput);
  gRobCoDlgRbOutputPerPlugin.Left := 12;
  gRobCoDlgRbOutputPerPlugin.Top := startTop;
  gRobCoDlgRbOutputPerPlugin.Width := innerWidth;
  gRobCoDlgRbOutputPerPlugin.ShowHint := True;
  gRobCoDlgRbOutputCombined.Left := 12;
  gRobCoDlgRbOutputCombined.Top := startTop + 23;
  gRobCoDlgRbOutputCombined.Width := innerWidth;
  gRobCoDlgRbOutputCombined.ShowHint := True;
  RobCoRefreshCombinedOutputAvailability(frm, hasSnapshotType, hintOp);
  RobCoRefreshForwardItmsAvailability(frm);
  topOffset := gRobCoDlgGbOutput.Top + gRobCoDlgGbOutput.Height + 8;
  gRobCoDlgBtnOk.Top := topOffset + 8;
  gRobCoDlgBtnCancel.Top := topOffset + 8;
  frm.Height := gRobCoDlgBtnOk.Top + gRobCoDlgBtnOk.Height + 48;
end;

//============================================================================
procedure RobCoRefreshToolsDialog(frm: TForm);
var
  hasListType, hasSnapshotType: boolean;
  hintOp: integer;
  needFullLayout: boolean;
begin
  if gRobCoDlgRefreshDepth > 0 then begin
    gRobCoDlgRefreshPending := True;
    Exit;
  end;
  while True do begin
    gRobCoDlgRefreshPending := False;
    gRobCoDlgRefreshDepth := 1;
    try
      RobCoComputeDialogSelection(frm, hasListType, hasSnapshotType, hintOp);
      needFullLayout := not gRobCoDlgLayoutReady;
      if not needFullLayout then begin
        if hasListType <> gRobCoDlgCachedHasList then
          needFullLayout := True
        else if hasSnapshotType <> gRobCoDlgCachedHasSnapshot then
          needFullLayout := True;
      end;
      if needFullLayout then
        RobCoLayoutToolsDialog(frm, hasListType, hasSnapshotType, hintOp)
      else if hintOp <> gRobCoDlgCachedHintOp then
        RobCoUpdateOutputHints(frm, hintOp);
      RobCoComputeDialogSelection(frm, hasListType, hasSnapshotType, hintOp);
      RobCoRefreshCombinedOutputAvailability(frm, hasSnapshotType, hintOp);
      RobCoRefreshForwardItmsAvailability(frm);
      gRobCoDlgCachedHasList := hasListType;
      gRobCoDlgCachedHasSnapshot := hasSnapshotType;
      gRobCoDlgCachedHintOp := hintOp;
      gRobCoDlgLayoutReady := True;
    finally
      gRobCoDlgRefreshDepth := 0;
    end;
    if not gRobCoDlgRefreshPending then
      Break;
  end;
end;

//============================================================================
procedure RobCoOperationChanged(Sender: TObject);
begin
  RobCoRefreshToolsDialog(TForm(TCheckListBox(Sender).Parent.Parent));
end;

//============================================================================
procedure RobCoApplyRecordTypeSelection(frm: TForm; mode: integer);
var
  i: integer;
begin
  if not Assigned(gRobCoDlgClbOperation) then
    Exit;
  for i := 0 to Pred(gRobCoDlgClbOperation.Items.Count) do begin
    if mode = RobCoRecordSelAll then
      gRobCoDlgClbOperation.Checked[i] := True
    else if mode = RobCoRecordSelNone then
      gRobCoDlgClbOperation.Checked[i] := False
    else if mode = RobCoRecordSelInvert then
      gRobCoDlgClbOperation.Checked[i] := not gRobCoDlgClbOperation.Checked[i];
  end;
  RobCoRefreshToolsDialog(frm);
end;

//============================================================================
procedure RobCoSelectAllRecordTypesClick(Sender: TObject);
begin
  RobCoApplyRecordTypeSelection(TForm(TButton(Sender).Parent.Parent), RobCoRecordSelAll);
end;

//============================================================================
procedure RobCoSelectNoneRecordTypesClick(Sender: TObject);
begin
  RobCoApplyRecordTypeSelection(TForm(TButton(Sender).Parent.Parent), RobCoRecordSelNone);
end;

//============================================================================
procedure RobCoInvertRecordTypesClick(Sender: TObject);
begin
  RobCoApplyRecordTypeSelection(TForm(TButton(Sender).Parent.Parent), RobCoRecordSelInvert);
end;

//============================================================================
procedure RobCoToolsOkClick(Sender: TObject);
begin
  RobCoCollectSelectedOps(gRobCoDlgClbOperation, robCoOpMap, gRobCoSelectedOps);
  if gRobCoSelectedOps.Count = 0 then begin
    MessageDlg('Select at least one record type.', mtWarning, [mbOk], 0);
    Exit;
  end;
  if RobCoSelectionHasListType(gRobCoSelectedOps) then begin
    if not gRobCoDlgChkListAdd.Checked then begin
      if not gRobCoDlgChkListRemove.Checked then begin
        MessageDlg('Select at least one of Add entries or Remove dropped entries.',
          mtWarning, [mbOk], 0);
        Exit;
      end;
    end;
  end;
  if Assigned(gRobCoDlgRbOutputCombined) then begin
    if gRobCoDlgRbOutputCombined.Checked then begin
      if not RobCoCombinedOutputAllowed(RobCoSelectionHasSnapshotType(gRobCoSelectedOps)) then begin
        MessageDlg('Combined output requires Forward ITMs off.',
          mtWarning, [mbOk], 0);
        Exit;
      end;
    end;
  end;
  TForm(TButton(Sender).Parent).ModalResult := mrOk;
end;

//============================================================================
function ShowRobCoToolsDialog: boolean;
var
  frm: TForm;
  clbOperation: TCheckListBox;
  gbRecordTypes, gbExportOptions, gbRecordOperation, gbOutput: TGroupBox;
  chkListAdd, chkListRemove, chkForwardItms, chkOverridesOnly, chkWriteAllFields: TCheckBox;
  rbOutputPerPlugin, rbOutputCombined: TRadioButton;
  btnOk, btnCancel, btnSelectAll, btnSelectNone, btnInvert: TButton;
begin
  Result := False;
  robCoOpMap := TStringList.Create;
  frm := TForm.Create(nil);
  try
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
    RobCoPopulateOperationCheckList(clbOperation, robCoOpMap);
    clbOperation.Height := robCoOpMap.Count * 18 + 4;
    clbOperation.OnClickCheck := RobCoOperationChanged;

    btnSelectAll := TButton.Create(frm);
    btnSelectAll.Parent := gbRecordTypes;
    btnSelectAll.Name := 'btnSelectAll';
    btnSelectAll.OnClick := RobCoSelectAllRecordTypesClick;

    btnSelectNone := TButton.Create(frm);
    btnSelectNone.Parent := gbRecordTypes;
    btnSelectNone.Name := 'btnSelectNone';
    btnSelectNone.OnClick := RobCoSelectNoneRecordTypesClick;

    btnInvert := TButton.Create(frm);
    btnInvert.Parent := gbRecordTypes;
    btnInvert.Name := 'btnInvert';
    btnInvert.OnClick := RobCoInvertRecordTypesClick;

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

    chkForwardItms := TCheckBox.Create(frm);
    chkForwardItms.Parent := gbExportOptions;
    chkForwardItms.Name := 'chkForwardItms';
    chkForwardItms.Height := 17;
    chkForwardItms.Caption := 'Forward ITMs';
    chkForwardItms.Checked := False;
    chkForwardItms.ShowHint := True;
    chkForwardItms.Hint :=
      'Emit ITM and master-matched content instead of skipping it.';
    chkForwardItms.OnClick := RobCoExportOptionsChanged;

    chkWriteAllFields := TCheckBox.Create(frm);
    chkWriteAllFields.Parent := gbExportOptions;
    chkWriteAllFields.Name := 'chkWriteAllFields';
    chkWriteAllFields.Height := 17;
    chkWriteAllFields.Caption := 'Write all fields';
    chkWriteAllFields.Checked := False;
    chkWriteAllFields.ShowHint := True;
    chkWriteAllFields.Hint :=
      'Snapshot exports only. On: print every filter and operation field (including ' +
      'unchanged and none) so you can delete what you do not need when authoring a ' +
      'custom patch. Off (default): only changed operation fields when Forward ITMs is also off.';
    chkWriteAllFields.OnClick := RobCoExportOptionsChanged;

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
    gbOutput.Caption := 'Output format';
    gbOutput.Width := gbRecordTypes.Width;

    rbOutputPerPlugin := TRadioButton.Create(frm);
    rbOutputPerPlugin.Parent := gbOutput;
    rbOutputPerPlugin.Name := 'rbOutputPerPlugin';
    rbOutputPerPlugin.Height := 17;
    rbOutputPerPlugin.Caption := 'Per plugin';
    rbOutputPerPlugin.Checked := True;
    rbOutputPerPlugin.OnClick := RobCoOutputFormatChanged;

    rbOutputCombined := TRadioButton.Create(frm);
    rbOutputCombined.Parent := gbOutput;
    rbOutputCombined.Name := 'rbOutputCombined';
    rbOutputCombined.Height := 17;
    rbOutputCombined.Caption := 'Combined';
    rbOutputCombined.OnClick := RobCoOutputFormatChanged;

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Name := 'btnOk';
    btnOk.Caption := 'OK';
    btnOk.Left := frm.Width - 184;
    btnOk.Width := 75;
    btnOk.OnClick := RobCoToolsOkClick;

    btnCancel := TButton.Create(frm);
    btnCancel.Parent := frm;
    btnCancel.Name := 'btnCancel';
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := btnOk.Left + btnOk.Width + 8;
    btnCancel.Width := 75;

    RobCoBindDialogControls(frm);
    RobCoLayoutRecordTypeButtons;
    RobCoResetDialogLayoutCache;
    RobCoRefreshToolsDialog(frm);

    if frm.ShowModal = mrOk then begin
      gRobCoListExportAdd := chkListAdd.Checked;
      gRobCoListExportRemove := chkListRemove.Checked;
      gRobCoPerPlugin := rbOutputPerPlugin.Checked;
      gRobCoOverridesOnly := chkOverridesOnly.Checked;
      gRobCoExportWriteAllFields := chkWriteAllFields.Checked;
      if not RobCoSelectionHasSnapshotType(gRobCoSelectedOps) then
        gRobCoExportWriteAllFields := False;
      if gRobCoPerPlugin then
        gRobCoExportForwardItms := chkForwardItms.Checked
      else begin
        gRobCoExportForwardItms := False;
      end;
      Result := True;
    end;
  finally
    RobCoClearDialogControls;
    robCoOpMap.Free;
    robCoOpMap := nil;
    frm.Free;
  end;
end;

end.
