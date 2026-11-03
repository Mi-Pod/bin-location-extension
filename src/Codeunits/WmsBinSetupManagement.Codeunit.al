codeunit 50222 "WMS Bin Setup Management"
{
    // Creates a missing bin and/or assigns an item to a bin for the binSetups command API (50224, #4).
    //
    // A new bin copies its settings from a template bin in the same location. An existing bin is
    // never modified. With an item, the Bin Content is created, or on an existing one the requested
    // Fixed/Default flags are added; flags are never cleared on it and quantities are never written.
    // Making the bin the item's Default fails while another bin is the Default, unless
    // replaceDefault moves it. Retries with the same external request key replay the stored
    // response (see 50216).

    var
        FieldRequiredErr: Label '%1 is required.', Comment = '%1 = API field name';
        FieldNeedsItemErr: Label '%1 can only be sent together with itemNo.', Comment = '%1 = API field name';
        LocationNotFoundErr: Label 'Location %1 does not exist.', Comment = '%1 = location code';
        LocationNotBinMandatoryErr: Label 'Location %1 is not set up with Bin Mandatory.', Comment = '%1 = location code';
        LocationDirectedErr: Label 'Location %1 uses Directed Put-away and Pick, which binSetups does not support.', Comment = '%1 = location code';
        TemplateRequiredErr: Label 'Bin %1 does not exist in location %2. templateBinCode is required to create it.', Comment = '%1 = bin code, %2 = location code';
        TemplateNotFoundErr: Label 'Template bin %1 does not exist in location %2.', Comment = '%1 = template bin code, %2 = location code';
        TemplateDedicatedErr: Label 'Template bin %1 in location %2 is Dedicated and cannot be used as a template.', Comment = '%1 = template bin code, %2 = location code';
        TemplateIsAdjustmentBinErr: Label 'Template bin %1 is the adjustment bin of location %2 and cannot be used as a template.', Comment = '%1 = template bin code, %2 = location code';
        DefaultInOtherBinErr: Label 'Bin %1 is already the Default bin for item %2 variant ''%3'' in location %4. Set replaceDefault to move the Default to bin %5.', Comment = '%1 = current default bin code, %2 = item no., %3 = variant code, %4 = location code, %5 = requested bin code';
        BinCreatedMsg: Label 'Bin %1 created in location %2 from template %3.', Comment = '%1 = bin code, %2 = location code, %3 = template bin code';
        BinExistsMsg: Label 'Bin %1 already exists in location %2.', Comment = '%1 = bin code, %2 = location code';
        ItemAssignedMsg: Label ' Item %1 variant ''%2'' (%3) in bin %4: Fixed %5, Default %6.', Comment = '%1 = item no., %2 = variant code, %3 = unit of measure code, %4 = bin code, %5 = fixed, %6 = default';
        DefaultMovedMsg: Label ' Default moved from bin %1.', Comment = '%1 = previous default bin code';
        LocationCodeTok: Label 'locationCode', Locked = true;
        BinCodeTok: Label 'binCode', Locked = true;
        VariantCodeTok: Label 'variantCode', Locked = true;
        UnitOfMeasureCodeTok: Label 'unitOfMeasureCode', Locked = true;
        DefaultTok: Label 'default', Locked = true;

    procedure SetupBin(var WmsBinSetupBuffer: Record "WMS Bin Setup Buffer")
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WmsDocumentRequest: Record "WMS Document Request";
        WmsBinRules: Codeunit "WMS Bin Rules";
        WmsRequestManagement: Codeunit "WMS Request Management";
        PayloadHash: Text[64];
        TargetId: Guid;
        ResultText: Text;
    begin
        ValidateInput(WmsBinSetupBuffer);

        PayloadHash := WmsRequestManagement.ComputePayloadHash(GetCanonicalPayload(WmsBinSetupBuffer));
        if WmsRequestManagement.FindExisting(WmsBinSetupBuffer."External Request Key", "WMS Workflow Type"::BinSetup, PayloadHash, WmsDocumentRequest) then begin
            ApplyResponse(WmsDocumentRequest.GetResponse(), WmsBinSetupBuffer);
            exit;
        end;

        EnsureBin(WmsBinSetupBuffer, Bin);
        WmsBinSetupBuffer."Bin Id" := Bin.SystemId;
        WmsBinSetupBuffer."Last Modified At" := Bin.SystemModifiedAt;
        TargetId := Bin.SystemId;
        if WmsBinSetupBuffer."Bin Created" then
            ResultText := StrSubstNo(BinCreatedMsg, Bin.Code, Bin."Location Code", WmsBinSetupBuffer."Template Bin Code")
        else
            ResultText := StrSubstNo(BinExistsMsg, Bin.Code, Bin."Location Code");

        if WmsBinSetupBuffer."Item No." <> '' then begin
            WmsBinRules.CheckBinUsable(WmsBinSetupBuffer."Location Code", WmsBinSetupBuffer."Bin Code");
            if WmsBinSetupBuffer.Fixed or WmsBinSetupBuffer.Default then
                WmsBinRules.CheckFixedAssignment(
                    WmsBinSetupBuffer."Location Code", WmsBinSetupBuffer."Bin Code", WmsBinSetupBuffer."Item No.",
                    WmsBinSetupBuffer."Variant Code", WmsBinSetupBuffer."Unit of Measure Code", WmsBinSetupBuffer."Allow Other Fixed Item");
            if WmsBinSetupBuffer.Default then
                ClearDefaultInOtherBins(WmsBinSetupBuffer);

            WriteBinContent(WmsBinSetupBuffer, BinContent);

            // From here Fixed/Default report the Bin Content's flags, not the request's.
            WmsBinSetupBuffer.Fixed := BinContent.Fixed;
            WmsBinSetupBuffer.Default := BinContent.Default;
            WmsBinSetupBuffer."Bin Content Id" := BinContent.SystemId;
            WmsBinSetupBuffer."Last Modified At" := BinContent.SystemModifiedAt;
            TargetId := BinContent.SystemId;
            ResultText += StrSubstNo(
                ItemAssignedMsg, BinContent."Item No.", BinContent."Variant Code", BinContent."Unit of Measure Code",
                BinContent."Bin Code", BinContent.Fixed, BinContent.Default);
            if WmsBinSetupBuffer."Default Moved From Bin Code" <> '' then
                ResultText += StrSubstNo(DefaultMovedMsg, WmsBinSetupBuffer."Default Moved From Bin Code");
        end else begin
            // No Bin Content was touched, so there are no flags to report.
            WmsBinSetupBuffer.Fixed := false;
            WmsBinSetupBuffer.Default := false;
        end;
        WmsBinSetupBuffer.Result := CopyStr(ResultText, 1, MaxStrLen(WmsBinSetupBuffer.Result));

        WmsDocumentRequest.Init();
        WmsDocumentRequest."External Request Key" := WmsBinSetupBuffer."External Request Key";
        WmsDocumentRequest."Workflow Type" := "WMS Workflow Type"::BinSetup;
        WmsDocumentRequest."Payload Hash" := PayloadHash;
        WmsDocumentRequest."Location Code" := WmsBinSetupBuffer."Location Code";
        WmsDocumentRequest."Created By" := WmsBinSetupBuffer."Created By";
        WmsDocumentRequest."Target Id" := TargetId;
        WmsDocumentRequest.SetResponse(BuildResponse(WmsBinSetupBuffer));
        WmsRequestManagement.Register(WmsDocumentRequest);
    end;

    local procedure ValidateInput(var WmsBinSetupBuffer: Record "WMS Bin Setup Buffer")
    var
        Location: Record Location;
        WmsBinRules: Codeunit "WMS Bin Rules";
    begin
        if WmsBinSetupBuffer."Location Code" = '' then
            Error(FieldRequiredErr, LocationCodeTok);
        if WmsBinSetupBuffer."Bin Code" = '' then
            Error(FieldRequiredErr, BinCodeTok);

        if not Location.Get(WmsBinSetupBuffer."Location Code") then
            Error(LocationNotFoundErr, WmsBinSetupBuffer."Location Code");
        if not Location."Bin Mandatory" then
            Error(LocationNotBinMandatoryErr, WmsBinSetupBuffer."Location Code");
        // Directed locations need zones and bin types on every bin, which this endpoint doesn't take.
        if Location."Directed Put-away and Pick" then
            Error(LocationDirectedErr, WmsBinSetupBuffer."Location Code");

        if WmsBinSetupBuffer."Item No." = '' then begin
            // Without an item only the bin is set up; refuse item fields rather than ignore them.
            if WmsBinSetupBuffer."Variant Code" <> '' then
                Error(FieldNeedsItemErr, VariantCodeTok);
            if WmsBinSetupBuffer."Unit of Measure Code" <> '' then
                Error(FieldNeedsItemErr, UnitOfMeasureCodeTok);
            if WmsBinSetupBuffer.Default then
                Error(FieldNeedsItemErr, DefaultTok);
            exit;
        end;

        WmsBinRules.CheckItemVariantUnitOfMeasure(
            WmsBinSetupBuffer."Item No.", WmsBinSetupBuffer."Variant Code", WmsBinSetupBuffer."Unit of Measure Code");
    end;

    local procedure GetCanonicalPayload(WmsBinSetupBuffer: Record "WMS Bin Setup Buffer"): Text
    begin
        // Fixed field order, validated values (UOM already defaulted). Created By is left out so a
        // retry from another actor still matches.
        exit(
            WmsBinSetupBuffer."Location Code" + '|' +
            WmsBinSetupBuffer."Bin Code" + '|' +
            WmsBinSetupBuffer."Template Bin Code" + '|' +
            WmsBinSetupBuffer.Description + '|' +
            WmsBinSetupBuffer."Item No." + '|' +
            WmsBinSetupBuffer."Variant Code" + '|' +
            WmsBinSetupBuffer."Unit of Measure Code" + '|' +
            Format(WmsBinSetupBuffer.Fixed, 0, 9) + '|' +
            Format(WmsBinSetupBuffer.Default, 0, 9) + '|' +
            Format(WmsBinSetupBuffer."Replace Default", 0, 9) + '|' +
            Format(WmsBinSetupBuffer."Allow Other Fixed Item", 0, 9));
    end;

    local procedure EnsureBin(var WmsBinSetupBuffer: Record "WMS Bin Setup Buffer"; var Bin: Record Bin)
    var
        Location: Record Location;
        ModelBin: Record Bin; // the template bin; a Temp prefix would trip AA0237
    begin
        // An existing bin is used as-is; templateBinCode is ignored for it.
        if Bin.Get(WmsBinSetupBuffer."Location Code", WmsBinSetupBuffer."Bin Code") then begin
            WmsBinSetupBuffer."Bin Created" := false;
            exit;
        end;

        if WmsBinSetupBuffer."Template Bin Code" = '' then
            Error(TemplateRequiredErr, WmsBinSetupBuffer."Bin Code", WmsBinSetupBuffer."Location Code");
        if not ModelBin.Get(WmsBinSetupBuffer."Location Code", WmsBinSetupBuffer."Template Bin Code") then
            Error(TemplateNotFoundErr, WmsBinSetupBuffer."Template Bin Code", WmsBinSetupBuffer."Location Code");
        if ModelBin.Dedicated then
            Error(TemplateDedicatedErr, ModelBin.Code, ModelBin."Location Code");
        Location.Get(WmsBinSetupBuffer."Location Code");
        if Location."Adjustment Bin Code" = ModelBin.Code then
            Error(TemplateIsAdjustmentBinErr, ModelBin.Code, ModelBin."Location Code");

        Bin.Init();
        Bin."Location Code" := WmsBinSetupBuffer."Location Code";
        Bin.Code := WmsBinSetupBuffer."Bin Code";
        Bin.Description := WmsBinSetupBuffer.Description;
        // Assigned rather than validated: on Zone Code, Bin Type Code, Warehouse Class Code and the
        // rest, OnValidate checks the bin is empty and pushes the value to its Bin Contents, which
        // is pointless on a bin that doesn't exist yet. Block Movement and Dedicated are not copied,
        // so the new bin starts unblocked and not dedicated. Bin Type Code is blank on non-directed
        // locations, which Bin OnInsert requires.
        Bin."Zone Code" := ModelBin."Zone Code";
        Bin."Bin Type Code" := ModelBin."Bin Type Code";
        Bin."Warehouse Class Code" := ModelBin."Warehouse Class Code";
        Bin."Bin Ranking" := ModelBin."Bin Ranking";
        Bin."Special Equipment Code" := ModelBin."Special Equipment Code";
        Bin."Maximum Cubage" := ModelBin."Maximum Cubage";
        Bin."Maximum Weight" := ModelBin."Maximum Weight";
        Bin."Cross-Dock Bin" := ModelBin."Cross-Dock Bin";
        Bin.Insert(true);
        WmsBinSetupBuffer."Bin Created" := true;

        // Re-read so SystemId and SystemModifiedAt reflect what was written.
        Bin.GetBySystemId(Bin.SystemId);
    end;

    local procedure ClearDefaultInOtherBins(var WmsBinSetupBuffer: Record "WMS Bin Setup Buffer")
    var
        OtherDefaultBinContent: Record "Bin Content";
    begin
        // Same filters as "WMS Management".CheckDefaultBin, which Bin Content uses to refuse a second
        // Default for the item/variant at the location (any unit of measure, other bins only).
        // The Default drives the bin BC proposes on purchase/sales lines and put-aways, so it only
        // moves when the caller asks for it.
        OtherDefaultBinContent.SetCurrentKey(Default);
        OtherDefaultBinContent.SetRange(Default, true);
        OtherDefaultBinContent.SetRange("Location Code", WmsBinSetupBuffer."Location Code");
        OtherDefaultBinContent.SetRange("Item No.", WmsBinSetupBuffer."Item No.");
        OtherDefaultBinContent.SetRange("Variant Code", WmsBinSetupBuffer."Variant Code");
        OtherDefaultBinContent.SetFilter("Bin Code", '<>%1', WmsBinSetupBuffer."Bin Code");
        if not OtherDefaultBinContent.FindFirst() then
            exit;

        if not WmsBinSetupBuffer."Replace Default" then
            Error(
                DefaultInOtherBinErr, OtherDefaultBinContent."Bin Code", WmsBinSetupBuffer."Item No.",
                WmsBinSetupBuffer."Variant Code", WmsBinSetupBuffer."Location Code", WmsBinSetupBuffer."Bin Code");

        WmsBinSetupBuffer."Default Moved From Bin Code" := OtherDefaultBinContent."Bin Code";
        // BC allows only one, but clear every match (e.g. one per unit of measure) so the new
        // Default can be set. Each cleared record drops out of the filter.
        repeat
            OtherDefaultBinContent.Validate(Default, false);
            OtherDefaultBinContent.Modify(true);
        until not OtherDefaultBinContent.FindFirst();
    end;

    local procedure WriteBinContent(var WmsBinSetupBuffer: Record "WMS Bin Setup Buffer"; var BinContent: Record "Bin Content")
    var
        Changed: Boolean;
    begin
        if BinContent.Get(
            WmsBinSetupBuffer."Location Code", WmsBinSetupBuffer."Bin Code", WmsBinSetupBuffer."Item No.",
            WmsBinSetupBuffer."Variant Code", WmsBinSetupBuffer."Unit of Measure Code")
        then begin
            // Only add the flags that were asked for; never clear Fixed or Default here.
            if WmsBinSetupBuffer.Fixed and not BinContent.Fixed then begin
                BinContent.Fixed := true;
                Changed := true;
            end;
            if WmsBinSetupBuffer.Default and not BinContent.Default then begin
                BinContent.Validate(Default, true);
                Changed := true;
            end;
            if Changed then
                BinContent.Modify(true);
            WmsBinSetupBuffer."Bin Content Created" := false;
        end else begin
            BinContent.Init();
            BinContent."Location Code" := WmsBinSetupBuffer."Location Code";
            BinContent."Bin Code" := WmsBinSetupBuffer."Bin Code";
            BinContent."Item No." := WmsBinSetupBuffer."Item No.";
            BinContent."Variant Code" := WmsBinSetupBuffer."Variant Code";
            // Validate sets "Qty. per Unit of Measure" from the item.
            BinContent.Validate("Unit of Measure Code", WmsBinSetupBuffer."Unit of Measure Code");
            // Copies zone, bin type, warehouse class, ranking, block movement, dedicated and
            // cross-dock from the Bin. "Bin Code" OnValidate only does this for a user change.
            BinContent.SetUpNewLine();
            BinContent.Fixed := WmsBinSetupBuffer.Fixed;
            if WmsBinSetupBuffer.Default then
                BinContent.Validate(Default, true);
            BinContent.Insert(true);
            WmsBinSetupBuffer."Bin Content Created" := true;
        end;

        // Re-read so SystemId and SystemModifiedAt reflect what was written.
        BinContent.GetBySystemId(BinContent.SystemId);
    end;

    local procedure BuildResponse(WmsBinSetupBuffer: Record "WMS Bin Setup Buffer") ResponseJson: Text
    var
        NullValue: JsonValue;
        ResponseObject: JsonObject;
    begin
        NullValue.SetValueToNull();
        ResponseObject.Add('binId', Format(WmsBinSetupBuffer."Bin Id", 0, 4));
        ResponseObject.Add('binCreated', WmsBinSetupBuffer."Bin Created");
        if IsNullGuid(WmsBinSetupBuffer."Bin Content Id") then
            ResponseObject.Add('binContentId', NullValue)
        else
            ResponseObject.Add('binContentId', Format(WmsBinSetupBuffer."Bin Content Id", 0, 4));
        ResponseObject.Add('binContentCreated', WmsBinSetupBuffer."Bin Content Created");
        ResponseObject.Add('defaultMovedFromBinCode', WmsBinSetupBuffer."Default Moved From Bin Code");
        ResponseObject.Add('locationCode', WmsBinSetupBuffer."Location Code");
        ResponseObject.Add('binCode', WmsBinSetupBuffer."Bin Code");
        ResponseObject.Add('itemNo', WmsBinSetupBuffer."Item No.");
        ResponseObject.Add('variantCode', WmsBinSetupBuffer."Variant Code");
        ResponseObject.Add('unitOfMeasureCode', WmsBinSetupBuffer."Unit of Measure Code");
        ResponseObject.Add('fixed', WmsBinSetupBuffer.Fixed);
        ResponseObject.Add('default', WmsBinSetupBuffer.Default);
        ResponseObject.Add('lastModifiedDateTime', WmsBinSetupBuffer."Last Modified At");
        ResponseObject.Add('result', WmsBinSetupBuffer.Result);
        ResponseObject.WriteTo(ResponseJson);
    end;

    local procedure ApplyResponse(ResponseJson: Text; var WmsBinSetupBuffer: Record "WMS Bin Setup Buffer")
    var
        ResponseObject: JsonObject;
        Token: JsonToken;
    begin
        // Replays a stored response onto the buffer; the request inputs are already identical.
        if not ResponseObject.ReadFrom(ResponseJson) then
            exit;
        if ResponseObject.Get('binId', Token) then
            Evaluate(WmsBinSetupBuffer."Bin Id", Token.AsValue().AsText());
        if ResponseObject.Get('binCreated', Token) then
            WmsBinSetupBuffer."Bin Created" := Token.AsValue().AsBoolean();
        if ResponseObject.Get('binContentId', Token) then
            if not Token.AsValue().IsNull() then
                Evaluate(WmsBinSetupBuffer."Bin Content Id", Token.AsValue().AsText());
        if ResponseObject.Get('binContentCreated', Token) then
            WmsBinSetupBuffer."Bin Content Created" := Token.AsValue().AsBoolean();
        if ResponseObject.Get('defaultMovedFromBinCode', Token) then
            WmsBinSetupBuffer."Default Moved From Bin Code" := CopyStr(Token.AsValue().AsCode(), 1, MaxStrLen(WmsBinSetupBuffer."Default Moved From Bin Code"));
        if ResponseObject.Get('unitOfMeasureCode', Token) then
            WmsBinSetupBuffer."Unit of Measure Code" := CopyStr(Token.AsValue().AsCode(), 1, MaxStrLen(WmsBinSetupBuffer."Unit of Measure Code"));
        if ResponseObject.Get('fixed', Token) then
            WmsBinSetupBuffer.Fixed := Token.AsValue().AsBoolean();
        if ResponseObject.Get('default', Token) then
            WmsBinSetupBuffer.Default := Token.AsValue().AsBoolean();
        if ResponseObject.Get('lastModifiedDateTime', Token) then
            WmsBinSetupBuffer."Last Modified At" := Token.AsValue().AsDateTime();
        if ResponseObject.Get('result', Token) then
            WmsBinSetupBuffer.Result := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(WmsBinSetupBuffer.Result));
    end;
}
