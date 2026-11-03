codeunit 50217 "WMS Bin Level Management"
{
    // Sets Min. Qty./Max. Qty. on a Bin Content for the binLevels command API (50219, #7).
    //
    // The Bin Content is created (Fixed by default) when it does not exist yet. Quantities are
    // never written. Clearing a rule means sending min 0 and max 0; the Bin Content is kept.
    // Retries with the same external request key replay the stored response (see 50216).

    var
        FieldRequiredErr: Label '%1 is required.', Comment = '%1 = API field name';
        ItemNotFoundErr: Label 'Item %1 does not exist.', Comment = '%1 = item no.';
        ItemNotInventoryErr: Label 'Item %1 must be of type Inventory.', Comment = '%1 = item no.';
        VariantNotFoundErr: Label 'Variant %1 does not exist for item %2.', Comment = '%1 = variant code, %2 = item no.';
        UnitOfMeasureNotFoundErr: Label 'Unit of measure %1 does not exist for item %2.', Comment = '%1 = unit of measure code, %2 = item no.';
        NegativeQtyErr: Label '%1 must not be negative (got %2).', Comment = '%1 = API field name, %2 = value';
        MinAboveMaxErr: Label 'minQty (%1) must not be greater than maxQty (%2).', Comment = '%1 = min qty, %2 = max qty';
        BinLevelsSetMsg: Label 'Bin levels for item %1 in bin %2 set to min %3, max %4.', Comment = '%1 = item no., %2 = bin code, %3 = min qty, %4 = max qty';
        LocationCodeTok: Label 'locationCode', Locked = true;
        BinCodeTok: Label 'binCode', Locked = true;
        ItemNoTok: Label 'itemNo', Locked = true;
        MinQtyTok: Label 'minQty', Locked = true;
        MaxQtyTok: Label 'maxQty', Locked = true;

    procedure SetBinLevels(var WmsBinLevelBuffer: Record "WMS Bin Level Buffer")
    var
        BinContent: Record "Bin Content";
        WmsDocumentRequest: Record "WMS Document Request";
        WmsBinRules: Codeunit "WMS Bin Rules";
        WmsRequestManagement: Codeunit "WMS Request Management";
        PayloadHash: Text[64];
    begin
        ValidateInput(WmsBinLevelBuffer);

        PayloadHash := WmsRequestManagement.ComputePayloadHash(GetCanonicalPayload(WmsBinLevelBuffer));
        if WmsRequestManagement.FindExisting(WmsBinLevelBuffer."External Request Key", "WMS Workflow Type"::BinLevels, PayloadHash, WmsDocumentRequest) then begin
            ApplyResponse(WmsDocumentRequest.GetResponse(), WmsBinLevelBuffer);
            exit;
        end;

        WmsBinRules.CheckBinUsable(WmsBinLevelBuffer."Location Code", WmsBinLevelBuffer."Bin Code");
        WmsBinRules.CheckFixedAssignment(
            WmsBinLevelBuffer."Location Code", WmsBinLevelBuffer."Bin Code", WmsBinLevelBuffer."Item No.",
            WmsBinLevelBuffer."Variant Code", WmsBinLevelBuffer."Unit of Measure Code", WmsBinLevelBuffer."Allow Other Fixed Item");

        WriteBinContent(WmsBinLevelBuffer, BinContent);

        WmsBinLevelBuffer."Unit of Measure Code" := BinContent."Unit of Measure Code";
        WmsBinLevelBuffer."Min. Qty." := BinContent."Min. Qty.";
        WmsBinLevelBuffer."Max. Qty." := BinContent."Max. Qty.";
        WmsBinLevelBuffer.Fixed := BinContent.Fixed;
        WmsBinLevelBuffer."Bin Content Id" := BinContent.SystemId;
        WmsBinLevelBuffer."Last Modified At" := BinContent.SystemModifiedAt;
        WmsBinLevelBuffer.Result := CopyStr(
            StrSubstNo(BinLevelsSetMsg, BinContent."Item No.", BinContent."Bin Code", BinContent."Min. Qty.", BinContent."Max. Qty."),
            1, MaxStrLen(WmsBinLevelBuffer.Result));

        WmsDocumentRequest.Init();
        WmsDocumentRequest."External Request Key" := WmsBinLevelBuffer."External Request Key";
        WmsDocumentRequest."Workflow Type" := "WMS Workflow Type"::BinLevels;
        WmsDocumentRequest."Payload Hash" := PayloadHash;
        WmsDocumentRequest."Location Code" := WmsBinLevelBuffer."Location Code";
        WmsDocumentRequest."Created By" := WmsBinLevelBuffer."Created By";
        WmsDocumentRequest."Target Id" := BinContent.SystemId;
        WmsDocumentRequest.SetResponse(BuildResponse(WmsBinLevelBuffer));
        WmsRequestManagement.Register(WmsDocumentRequest);
    end;

    local procedure ValidateInput(var WmsBinLevelBuffer: Record "WMS Bin Level Buffer")
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
    begin
        if WmsBinLevelBuffer."Location Code" = '' then
            Error(FieldRequiredErr, LocationCodeTok);
        if WmsBinLevelBuffer."Bin Code" = '' then
            Error(FieldRequiredErr, BinCodeTok);
        if WmsBinLevelBuffer."Item No." = '' then
            Error(FieldRequiredErr, ItemNoTok);

        if not Item.Get(WmsBinLevelBuffer."Item No.") then
            Error(ItemNotFoundErr, WmsBinLevelBuffer."Item No.");
        if Item.Type <> Item.Type::Inventory then
            Error(ItemNotInventoryErr, WmsBinLevelBuffer."Item No.");

        if WmsBinLevelBuffer."Variant Code" <> '' then
            if not ItemVariant.Get(WmsBinLevelBuffer."Item No.", WmsBinLevelBuffer."Variant Code") then
                Error(VariantNotFoundErr, WmsBinLevelBuffer."Variant Code", WmsBinLevelBuffer."Item No.");

        if WmsBinLevelBuffer."Unit of Measure Code" = '' then
            WmsBinLevelBuffer."Unit of Measure Code" := Item."Base Unit of Measure";
        if not ItemUnitOfMeasure.Get(WmsBinLevelBuffer."Item No.", WmsBinLevelBuffer."Unit of Measure Code") then
            Error(UnitOfMeasureNotFoundErr, WmsBinLevelBuffer."Unit of Measure Code", WmsBinLevelBuffer."Item No.");

        // BC checks min <= max only when the Bin Content is inserted or modified; check up front
        // so the app gets an error that names the API fields.
        if WmsBinLevelBuffer."Min. Qty." < 0 then
            Error(NegativeQtyErr, MinQtyTok, WmsBinLevelBuffer."Min. Qty.");
        if WmsBinLevelBuffer."Max. Qty." < 0 then
            Error(NegativeQtyErr, MaxQtyTok, WmsBinLevelBuffer."Max. Qty.");
        if WmsBinLevelBuffer."Min. Qty." > WmsBinLevelBuffer."Max. Qty." then
            Error(MinAboveMaxErr, WmsBinLevelBuffer."Min. Qty.", WmsBinLevelBuffer."Max. Qty.");
    end;

    local procedure GetCanonicalPayload(WmsBinLevelBuffer: Record "WMS Bin Level Buffer"): Text
    begin
        // Fixed field order, validated values (UOM already defaulted). Created By is left out so a
        // retry from another actor still matches.
        exit(
            WmsBinLevelBuffer."Location Code" + '|' +
            WmsBinLevelBuffer."Bin Code" + '|' +
            WmsBinLevelBuffer."Item No." + '|' +
            WmsBinLevelBuffer."Variant Code" + '|' +
            WmsBinLevelBuffer."Unit of Measure Code" + '|' +
            Format(WmsBinLevelBuffer."Min. Qty.", 0, 9) + '|' +
            Format(WmsBinLevelBuffer."Max. Qty.", 0, 9) + '|' +
            Format(WmsBinLevelBuffer.Fixed, 0, 9) + '|' +
            Format(WmsBinLevelBuffer."Allow Other Fixed Item", 0, 9));
    end;

    local procedure WriteBinContent(WmsBinLevelBuffer: Record "WMS Bin Level Buffer"; var BinContent: Record "Bin Content")
    begin
        if BinContent.Get(
            WmsBinLevelBuffer."Location Code", WmsBinLevelBuffer."Bin Code", WmsBinLevelBuffer."Item No.",
            WmsBinLevelBuffer."Variant Code", WmsBinLevelBuffer."Unit of Measure Code")
        then begin
            SetLevels(WmsBinLevelBuffer, BinContent);
            BinContent.Modify(true);
        end else begin
            BinContent.Init();
            BinContent."Location Code" := WmsBinLevelBuffer."Location Code";
            BinContent."Bin Code" := WmsBinLevelBuffer."Bin Code";
            BinContent."Item No." := WmsBinLevelBuffer."Item No.";
            BinContent."Variant Code" := WmsBinLevelBuffer."Variant Code";
            // Validate sets "Qty. per Unit of Measure" from the item.
            BinContent.Validate("Unit of Measure Code", WmsBinLevelBuffer."Unit of Measure Code");
            // Copies zone, bin type, warehouse class, ranking, block movement, dedicated and
            // cross-dock from the Bin. "Bin Code" OnValidate only does this for a user change.
            BinContent.SetUpNewLine();
            SetLevels(WmsBinLevelBuffer, BinContent);
            BinContent.Insert(true);
        end;

        // Re-read so SystemId and SystemModifiedAt reflect what was written.
        BinContent.GetBySystemId(BinContent.SystemId);
    end;

    local procedure SetLevels(WmsBinLevelBuffer: Record "WMS Bin Level Buffer"; var BinContent: Record "Bin Content")
    begin
        BinContent.Validate("Min. Qty.", WmsBinLevelBuffer."Min. Qty.");
        // Assigned rather than validated: "Max. Qty." OnValidate runs CheckBinMaxCubageAndWeight,
        // which can raise a Confirm dialog that a headless API call cannot answer.
        BinContent."Max. Qty." := WmsBinLevelBuffer."Max. Qty.";
        BinContent.Fixed := WmsBinLevelBuffer.Fixed;
    end;

    local procedure BuildResponse(WmsBinLevelBuffer: Record "WMS Bin Level Buffer") ResponseJson: Text
    var
        ResponseObject: JsonObject;
    begin
        ResponseObject.Add('binContentId', Format(WmsBinLevelBuffer."Bin Content Id", 0, 4));
        ResponseObject.Add('locationCode', WmsBinLevelBuffer."Location Code");
        ResponseObject.Add('binCode', WmsBinLevelBuffer."Bin Code");
        ResponseObject.Add('itemNo', WmsBinLevelBuffer."Item No.");
        ResponseObject.Add('variantCode', WmsBinLevelBuffer."Variant Code");
        ResponseObject.Add('unitOfMeasureCode', WmsBinLevelBuffer."Unit of Measure Code");
        ResponseObject.Add('minQty', WmsBinLevelBuffer."Min. Qty.");
        ResponseObject.Add('maxQty', WmsBinLevelBuffer."Max. Qty.");
        ResponseObject.Add('fixed', WmsBinLevelBuffer.Fixed);
        ResponseObject.Add('lastModifiedDateTime', WmsBinLevelBuffer."Last Modified At");
        ResponseObject.Add('result', WmsBinLevelBuffer.Result);
        ResponseObject.WriteTo(ResponseJson);
    end;

    local procedure ApplyResponse(ResponseJson: Text; var WmsBinLevelBuffer: Record "WMS Bin Level Buffer")
    var
        ResponseObject: JsonObject;
        Token: JsonToken;
    begin
        // Replays a stored response onto the buffer; the request inputs are already identical.
        if not ResponseObject.ReadFrom(ResponseJson) then
            exit;
        if ResponseObject.Get('binContentId', Token) then
            Evaluate(WmsBinLevelBuffer."Bin Content Id", Token.AsValue().AsText());
        if ResponseObject.Get('unitOfMeasureCode', Token) then
            WmsBinLevelBuffer."Unit of Measure Code" := CopyStr(Token.AsValue().AsCode(), 1, MaxStrLen(WmsBinLevelBuffer."Unit of Measure Code"));
        if ResponseObject.Get('minQty', Token) then
            WmsBinLevelBuffer."Min. Qty." := Token.AsValue().AsDecimal();
        if ResponseObject.Get('maxQty', Token) then
            WmsBinLevelBuffer."Max. Qty." := Token.AsValue().AsDecimal();
        if ResponseObject.Get('fixed', Token) then
            WmsBinLevelBuffer.Fixed := Token.AsValue().AsBoolean();
        if ResponseObject.Get('lastModifiedDateTime', Token) then
            WmsBinLevelBuffer."Last Modified At" := Token.AsValue().AsDateTime();
        if ResponseObject.Get('result', Token) then
            WmsBinLevelBuffer.Result := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(WmsBinLevelBuffer.Result));
    end;
}
