codeunit 50223 "WMS Put-away Management"
{
    // Command logic behind the putAwaySplits API (50225).
    //
    // SplitPutAwayLine: spreads one open Place line of an Inventory Put-away (from a purchase
    //   order) over one or more destination bins, using BC's own Split Line. Managers create and
    //   post the inventory put-aways in BC; this never creates, posts or registers anything.
    //   The line's Qty. to Handle pattern (all 0, or all = outstanding) is kept on every resulting
    //   line, so the manager still decides what to post.
    //
    // Follows the WMS Request Management (50216) retry pattern and never Commits.

    var
        ActivityNoRequiredErr: Label 'activityNo is required.';
        LineNoRequiredErr: Label 'lineNo is required.';
        AllocationsJsonInvalidErr: Label 'allocationsJson must be a JSON array of allocations.';
        NoAllocationsErr: Label 'allocationsJson must contain at least one allocation.';
        AllocationNotObjectErr: Label 'Allocation %1 in allocationsJson is not a JSON object.', Comment = '%1 = allocation index (1-based)';
        ValueTooLongErr: Label 'Allocation %1: %2 must not be longer than %3 characters.', Comment = '%1 = allocation index, %2 = JSON property name, %3 = max length';
        ValueRequiredErr: Label 'Allocation %1: %2 is required.', Comment = '%1 = allocation index, %2 = JSON property name';
        QuantityNotPositiveErr: Label 'Allocation %1: quantityBase must be greater than 0.', Comment = '%1 = allocation index';
        DuplicateBinErr: Label 'Allocation %1: binCode %2 is already used by allocation %3. Each bin may appear only once.', Comment = '%1 = allocation index, %2 = bin code, %3 = earlier allocation index';
        LineNotFoundErr: Label 'Inventory put-away %1 has no line %2.', Comment = '%1 = inventory put-away no., %2 = line no.';
        NotPlaceLineErr: Label 'Line %2 of inventory put-away %1 is a %3 line. lineNo must be a Place line.', Comment = '%1 = inventory put-away no., %2 = line no., %3 = action type';
        NothingOutstandingErr: Label 'Line %2 of inventory put-away %1 has nothing outstanding.', Comment = '%1 = inventory put-away no., %2 = line no.';
        NotPurchaseOrderErr: Label 'Line %2 of inventory put-away %1 comes from a %3, not a Purchase Order. Only purchase order put-aways are supported.', Comment = '%1 = inventory put-away no., %2 = line no., %3 = source document';
        TrackedLineErr: Label 'Line %2 of inventory put-away %1 carries a lot, serial or package no. Put-aways for tracked items are not supported by this API.', Comment = '%1 = inventory put-away no., %2 = line no.';
        PartialQtyToHandleErr: Label 'Line %2 of inventory put-away %1 has Qty. to Handle %3 of %4 outstanding. Set it to 0 or to the full outstanding quantity in BC before splitting.', Comment = '%1 = inventory put-away no., %2 = line no., %3 = qty. to handle, %4 = qty. outstanding';
        LineChangedErr: Label 'Inventory put-away %1 line %2 was changed in BC after %3. Refresh and try again.', Comment = '%1 = inventory put-away no., %2 = line no., %3 = expected last modified date time';
        NotWholeUnitErr: Label 'Allocation %1: quantityBase %2 is not a whole number of unit of measure %3 (Qty. per Unit of Measure %4, rounding precision %5) on line %6.', Comment = '%1 = allocation index, %2 = base qty, %3 = unit of measure code, %4 = qty. per unit of measure, %5 = rounding precision, %6 = line no.';
        SumMismatchErr: Label 'The allocations add up to %1, but line %2 of inventory put-away %3 has %4 outstanding (base). They must match exactly.', Comment = '%1 = sum of quantityBase, %2 = line no., %3 = inventory put-away no., %4 = qty. outstanding (base)';
        SplitResultMismatchErr: Label 'BC did not split line %2 of inventory put-away %1 as requested (allocation %3). Nothing was changed.', Comment = '%1 = inventory put-away no., %2 = line no., %3 = allocation index';
        PutAwaySplitMsg: Label 'Inventory put-away %1 line %2 spread over %3 bin(s) for purchase order %4.', Comment = '%1 = inventory put-away no., %2 = line no., %3 = number of bins, %4 = purchase order no.';

    procedure SplitPutAwayLine(var WmsPutAwaySplitBuffer: Record "WMS Put-away Split Buffer")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WmsDocumentRequest: Record "WMS Document Request";
        WmsRequestManagement: Codeunit "WMS Request Management";
        BinCodes: List of [Code[20]];
        QuantitiesBase: List of [Decimal];
        ResultLineNos: List of [Integer];
        OriginalLineId: Guid;
        PayloadHash: Text[64];
        ResponseJson: Text;
    begin
        ReadSplitRequest(WmsPutAwaySplitBuffer, BinCodes, QuantitiesBase);

        // expectedLastModifiedDateTime is a precondition, not part of the command, so it stays out of the hash.
        // The replay check runs before the line checks: after a successful split the line no longer
        // matches the request, so a retry must replay rather than fail.
        PayloadHash := WmsRequestManagement.ComputePayloadHash(BuildSplitPayload(WmsPutAwaySplitBuffer, BinCodes, QuantitiesBase));
        if WmsRequestManagement.FindExisting(WmsPutAwaySplitBuffer."External Request Key", "WMS Workflow Type"::PutAway, PayloadHash, WmsDocumentRequest) then begin
            FillSplitBuffer(WmsPutAwaySplitBuffer, WmsDocumentRequest.GetResponse());
            exit;
        end;

        if not WarehouseActivityLine.Get(WarehouseActivityLine."Activity Type"::"Invt. Put-away", WmsPutAwaySplitBuffer."Activity No.", WmsPutAwaySplitBuffer."Line No.") then
            Error(LineNotFoundErr, WmsPutAwaySplitBuffer."Activity No.", WmsPutAwaySplitBuffer."Line No.");

        if WmsPutAwaySplitBuffer."Expected Last Modified At" <> 0DT then
            if WarehouseActivityLine.SystemModifiedAt > WmsPutAwaySplitBuffer."Expected Last Modified At" then
                Error(LineChangedErr, WmsPutAwaySplitBuffer."Activity No.", WmsPutAwaySplitBuffer."Line No.", WmsPutAwaySplitBuffer."Expected Last Modified At");

        CheckPutAwayLine(WarehouseActivityLine);
        CheckAllocations(WarehouseActivityLine, BinCodes, QuantitiesBase);

        // Target Id is the line as it was before the split. BC renumbers (and so re-inserts) the
        // lines of the put-away when there is no gap for a new line, so this is a reference only.
        OriginalLineId := WarehouseActivityLine.SystemId;
        ApplySplit(WarehouseActivityLine, BinCodes, QuantitiesBase, ResultLineNos);
        ResponseJson := BuildSplitResponse(WarehouseActivityLine, ResultLineNos);

        WmsDocumentRequest.Init();
        WmsDocumentRequest."External Request Key" := WmsPutAwaySplitBuffer."External Request Key";
        WmsDocumentRequest."Workflow Type" := "WMS Workflow Type"::PutAway;
        WmsDocumentRequest."Payload Hash" := PayloadHash;
        WmsDocumentRequest."Location Code" := WarehouseActivityLine."Location Code";
        WmsDocumentRequest."Created By" := WmsPutAwaySplitBuffer."Created By";
        WmsDocumentRequest."Document No." := WarehouseActivityLine."Source No.";
        WmsDocumentRequest."Activity No." := WarehouseActivityLine."No.";
        WmsDocumentRequest."Target Id" := OriginalLineId;
        WmsDocumentRequest.SetResponse(ResponseJson);
        WmsRequestManagement.Register(WmsDocumentRequest);

        FillSplitBuffer(WmsPutAwaySplitBuffer, ResponseJson);
    end;

    // --- Request checks ---

    local procedure ReadSplitRequest(var WmsPutAwaySplitBuffer: Record "WMS Put-away Split Buffer"; var BinCodes: List of [Code[20]]; var QuantitiesBase: List of [Decimal])
    var
        AllocationsJsonArray: JsonArray;
        AllocationJsonToken: JsonToken;
        AllocationJsonObject: JsonObject;
        BinCode: Code[20];
        QuantityBase: Decimal;
        AllocationIndex: Integer;
    begin
        if WmsPutAwaySplitBuffer."Activity No." = '' then
            Error(ActivityNoRequiredErr);
        if WmsPutAwaySplitBuffer."Line No." = 0 then
            Error(LineNoRequiredErr);

        if not AllocationsJsonArray.ReadFrom(WmsPutAwaySplitBuffer.GetAllocationsJson()) then
            Error(AllocationsJsonInvalidErr);
        if AllocationsJsonArray.Count() = 0 then
            Error(NoAllocationsErr);

        foreach AllocationJsonToken in AllocationsJsonArray do begin
            AllocationIndex += 1;
            if not AllocationJsonToken.IsObject() then
                Error(AllocationNotObjectErr, AllocationIndex);
            AllocationJsonObject := AllocationJsonToken.AsObject();

            BinCode := CopyStr(GetAllocationCode(AllocationJsonObject, 'binCode', MaxStrLen(BinCode), AllocationIndex), 1, MaxStrLen(BinCode));
            if BinCode = '' then
                Error(ValueRequiredErr, AllocationIndex, 'binCode');
            if BinCodes.Contains(BinCode) then
                Error(DuplicateBinErr, AllocationIndex, BinCode, BinCodes.IndexOf(BinCode));

            QuantityBase := GetAllocationDecimal(AllocationJsonObject, 'quantityBase', AllocationIndex);
            if QuantityBase <= 0 then
                Error(QuantityNotPositiveErr, AllocationIndex);

            BinCodes.Add(BinCode);
            QuantitiesBase.Add(QuantityBase);
        end;
    end;

    local procedure BuildSplitPayload(WmsPutAwaySplitBuffer: Record "WMS Put-away Split Buffer"; BinCodes: List of [Code[20]]; QuantitiesBase: List of [Decimal]): Text
    var
        Payload: TextBuilder;
        AllocationIndex: Integer;
    begin
        Payload.Append(WmsPutAwaySplitBuffer."Activity No.");
        Payload.Append('|' + Format(WmsPutAwaySplitBuffer."Line No.", 0, 9));
        for AllocationIndex := 1 to BinCodes.Count() do begin
            Payload.Append('|' + BinCodes.Get(AllocationIndex));
            Payload.Append('|' + Format(QuantitiesBase.Get(AllocationIndex), 0, 9));
        end;
        exit(Payload.ToText());
    end;

    local procedure CheckPutAwayLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        if WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Place then
            Error(NotPlaceLineErr, WarehouseActivityLine."No.", WarehouseActivityLine."Line No.", WarehouseActivityLine."Action Type");
        if WarehouseActivityLine."Qty. Outstanding (Base)" <= 0 then
            Error(NothingOutstandingErr, WarehouseActivityLine."No.", WarehouseActivityLine."Line No.");
        if WarehouseActivityLine."Source Document" <> WarehouseActivityLine."Source Document"::"Purchase Order" then
            Error(NotPurchaseOrderErr, WarehouseActivityLine."No.", WarehouseActivityLine."Line No.", WarehouseActivityLine."Source Document");
        // Splitting tracked lines would need the Whse. Item Tracking split as well.
        if (WarehouseActivityLine."Lot No." <> '') or (WarehouseActivityLine."Serial No." <> '') or (WarehouseActivityLine."Package No." <> '') then
            Error(TrackedLineErr, WarehouseActivityLine."No.", WarehouseActivityLine."Line No.");
        // A partial Qty. to Handle has no meaning once the line is spread over several bins.
        if (WarehouseActivityLine."Qty. to Handle" <> 0) and (WarehouseActivityLine."Qty. to Handle" <> WarehouseActivityLine."Qty. Outstanding") then
            Error(
                PartialQtyToHandleErr, WarehouseActivityLine."No.", WarehouseActivityLine."Line No.",
                WarehouseActivityLine."Qty. to Handle", WarehouseActivityLine."Qty. Outstanding");
    end;

    local procedure CheckAllocations(WarehouseActivityLine: Record "Warehouse Activity Line"; BinCodes: List of [Code[20]]; QuantitiesBase: List of [Decimal])
    var
        WmsBinRules: Codeunit "WMS Bin Rules";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        Qty: Decimal;
        TotalQtyBase: Decimal;
        AllocationIndex: Integer;
    begin
        // Bin Code validation on the line only checks that the bin exists; Block Movement and
        // Dedicated would only fail at posting, so check them here.
        for AllocationIndex := 1 to BinCodes.Count() do begin
            WmsBinRules.CheckBinUsable(WarehouseActivityLine."Location Code", BinCodes.Get(AllocationIndex));

            // Lines are in the purchase unit of measure, so each share must be whole units of it.
            Qty := QuantitiesBase.Get(AllocationIndex) / WarehouseActivityLine."Qty. per Unit of Measure";
            if UnitOfMeasureManagement.RoundQty(Qty, WarehouseActivityLine."Qty. Rounding Precision") <> Qty then
                Error(
                    NotWholeUnitErr, AllocationIndex, QuantitiesBase.Get(AllocationIndex), WarehouseActivityLine."Unit of Measure Code",
                    WarehouseActivityLine."Qty. per Unit of Measure", WarehouseActivityLine."Qty. Rounding Precision", WarehouseActivityLine."Line No.");

            TotalQtyBase += QuantitiesBase.Get(AllocationIndex);
        end;

        if TotalQtyBase <> WarehouseActivityLine."Qty. Outstanding (Base)" then
            Error(SumMismatchErr, TotalQtyBase, WarehouseActivityLine."Line No.", WarehouseActivityLine."No.", WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    // --- Split ---

    local procedure ApplySplit(var WarehouseActivityLine: Record "Warehouse Activity Line"; BinCodes: List of [Code[20]]; QuantitiesBase: List of [Decimal]; var ResultLineNos: List of [Integer])
    var
        SplitWarehouseActivityLine: Record "Warehouse Activity Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        ResultWarehouseActivityLine: Record "Warehouse Activity Line";
        KeepQtyToHandle: Boolean;
        RemainingQty: Decimal;
        AllocationIndex: Integer;
    begin
        KeepQtyToHandle := WarehouseActivityLine."Qty. to Handle" <> 0;
        RemainingQty := WarehouseActivityLine."Qty. Outstanding";

        // SplitLine moves Qty. Outstanding - Qty. to Handle into a new line right after the original.
        // Splitting off the last allocation first leaves the lines in request order:
        // original = allocation 1, then allocations 2..n.
        for AllocationIndex := BinCodes.Count() downto 2 do begin
            RemainingQty -= QuantitiesBase.Get(AllocationIndex) / WarehouseActivityLine."Qty. per Unit of Measure";
            WarehouseActivityLine.Validate("Qty. to Handle", RemainingQty);
            // Saved first: if BC has to renumber the lines it re-reads the original from the database.
            WarehouseActivityLine.Modify(true);
            // Same call pattern as the standard Split Line action on the Inventory Put-away subform.
            SplitWarehouseActivityLine.Copy(WarehouseActivityLine);
            WarehouseActivityLine.SplitLine(SplitWarehouseActivityLine, NewWarehouseActivityLine);
            WarehouseActivityLine.Copy(SplitWarehouseActivityLine);
            SetLineBin(NewWarehouseActivityLine, BinCodes.Get(AllocationIndex));
            NewWarehouseActivityLine.Modify(true);
        end;
        SetLineBin(WarehouseActivityLine, BinCodes.Get(1));
        WarehouseActivityLine.Modify(true);

        // Collect the resulting lines (the original and the n - 1 lines right after it), check them
        // against the request and put back the original Qty. to Handle pattern.
        ResultWarehouseActivityLine := WarehouseActivityLine;
        ResultWarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        ResultWarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        for AllocationIndex := 1 to BinCodes.Count() do begin
            if AllocationIndex > 1 then
                if ResultWarehouseActivityLine.Next() = 0 then
                    Error(SplitResultMismatchErr, WarehouseActivityLine."No.", WarehouseActivityLine."Line No.", AllocationIndex);
            if (ResultWarehouseActivityLine."Source No." <> WarehouseActivityLine."Source No.") or
               (ResultWarehouseActivityLine."Source Line No." <> WarehouseActivityLine."Source Line No.") or
               (ResultWarehouseActivityLine."Bin Code" <> BinCodes.Get(AllocationIndex)) or
               (ResultWarehouseActivityLine."Qty. Outstanding (Base)" <> QuantitiesBase.Get(AllocationIndex))
            then
                Error(SplitResultMismatchErr, WarehouseActivityLine."No.", WarehouseActivityLine."Line No.", AllocationIndex);

            if KeepQtyToHandle then
                ResultWarehouseActivityLine.Validate("Qty. to Handle", ResultWarehouseActivityLine."Qty. Outstanding")
            else
                ResultWarehouseActivityLine.Validate("Qty. to Handle", 0);
            ResultWarehouseActivityLine.Modify(true);
            ResultLineNos.Add(ResultWarehouseActivityLine."Line No.");
        end;

        WarehouseActivityLine.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", WarehouseActivityLine."Line No.");
    end;

    local procedure SetLineBin(var WarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        // The Bin Code table relation is filtered on the line's Zone Code, so take the new bin's
        // zone first; Bin Code validation then copies Zone Code, Dedicated and Bin Ranking from the bin.
        Bin.Get(WarehouseActivityLine."Location Code", BinCode);
        WarehouseActivityLine."Zone Code" := Bin."Zone Code";
        WarehouseActivityLine.Validate("Bin Code", BinCode);
    end;

    local procedure BuildSplitResponse(WarehouseActivityLine: Record "Warehouse Activity Line"; ResultLineNos: List of [Integer]) ResponseJson: Text
    var
        ResultWarehouseActivityLine: Record "Warehouse Activity Line";
        ResponseJsonObject: JsonObject;
        LinesJsonArray: JsonArray;
        LineJsonObject: JsonObject;
        LastModifiedAt: DateTime;
        LineNo: Integer;
    begin
        LastModifiedAt := 0DT;
        foreach LineNo in ResultLineNos do begin
            ResultWarehouseActivityLine.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", LineNo);
            Clear(LineJsonObject);
            LineJsonObject.Add('lineNo', ResultWarehouseActivityLine."Line No.");
            LineJsonObject.Add('binCode', ResultWarehouseActivityLine."Bin Code");
            LineJsonObject.Add('quantityBase', ResultWarehouseActivityLine."Qty. Outstanding (Base)");
            LineJsonObject.Add('qtyToHandleBase', ResultWarehouseActivityLine."Qty. to Handle (Base)");
            LinesJsonArray.Add(LineJsonObject);
            if ResultWarehouseActivityLine.SystemModifiedAt > LastModifiedAt then
                LastModifiedAt := ResultWarehouseActivityLine.SystemModifiedAt;
        end;

        ResponseJsonObject.Add('activityNo', WarehouseActivityLine."No.");
        ResponseJsonObject.Add('sourceNo', WarehouseActivityLine."Source No.");
        ResponseJsonObject.Add('sourceLineNo', WarehouseActivityLine."Source Line No.");
        ResponseJsonObject.Add('lines', LinesJsonArray);
        ResponseJsonObject.Add('lastModifiedDateTime', LastModifiedAt);
        ResponseJsonObject.WriteTo(ResponseJson);
    end;

    local procedure FillSplitBuffer(var WmsPutAwaySplitBuffer: Record "WMS Put-away Split Buffer"; ResponseJson: Text)
    var
        ResponseJsonObject: JsonObject;
        JsonValueToken: JsonToken;
        LineCount: Integer;
    begin
        ResponseJsonObject.ReadFrom(ResponseJson);
        WmsPutAwaySplitBuffer."Source No." := CopyStr(GetResponseText(ResponseJsonObject, 'sourceNo'), 1, MaxStrLen(WmsPutAwaySplitBuffer."Source No."));
        if ResponseJsonObject.Get('sourceLineNo', JsonValueToken) then
            WmsPutAwaySplitBuffer."Source Line No." := JsonValueToken.AsValue().AsInteger();
        if ResponseJsonObject.Get('lastModifiedDateTime', JsonValueToken) then
            WmsPutAwaySplitBuffer."Last Modified At" := JsonValueToken.AsValue().AsDateTime();
        if ResponseJsonObject.Get('lines', JsonValueToken) then
            LineCount := JsonValueToken.AsArray().Count();
        WmsPutAwaySplitBuffer.SetResponseJson(ResponseJson);
        WmsPutAwaySplitBuffer.Result := CopyStr(
            StrSubstNo(PutAwaySplitMsg, WmsPutAwaySplitBuffer."Activity No.", WmsPutAwaySplitBuffer."Line No.", LineCount, WmsPutAwaySplitBuffer."Source No."),
            1, MaxStrLen(WmsPutAwaySplitBuffer.Result));
    end;

    // --- JSON helpers ---

    local procedure GetAllocationCode(AllocationJsonObject: JsonObject; PropertyName: Text; MaxLength: Integer; AllocationIndex: Integer) Value: Text
    var
        JsonValueToken: JsonToken;
    begin
        if not AllocationJsonObject.Get(PropertyName, JsonValueToken) then
            exit('');
        if not JsonValueToken.IsValue() then
            exit('');
        if JsonValueToken.AsValue().IsNull() then
            exit('');
        Value := UpperCase(DelChr(JsonValueToken.AsValue().AsText(), '<>', ' '));
        if StrLen(Value) > MaxLength then
            Error(ValueTooLongErr, AllocationIndex, PropertyName, MaxLength);
    end;

    local procedure GetAllocationDecimal(AllocationJsonObject: JsonObject; PropertyName: Text; AllocationIndex: Integer): Decimal
    var
        JsonValueToken: JsonToken;
    begin
        if not AllocationJsonObject.Get(PropertyName, JsonValueToken) then
            Error(ValueRequiredErr, AllocationIndex, PropertyName);
        if not JsonValueToken.IsValue() then
            Error(ValueRequiredErr, AllocationIndex, PropertyName);
        if JsonValueToken.AsValue().IsNull() then
            Error(ValueRequiredErr, AllocationIndex, PropertyName);
        exit(JsonValueToken.AsValue().AsDecimal());
    end;

    local procedure GetResponseText(ResponseJsonObject: JsonObject; PropertyName: Text): Text
    var
        JsonValueToken: JsonToken;
    begin
        if ResponseJsonObject.Get(PropertyName, JsonValueToken) then
            exit(JsonValueToken.AsValue().AsText());
        exit('');
    end;
}
