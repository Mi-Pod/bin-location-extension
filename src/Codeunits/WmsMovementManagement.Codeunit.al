codeunit 50220 "WMS Movement Management"
{
    // Command logic behind the movements (50220) and qtyToHandles (50221) APIs.
    //
    // CreateMovement: Internal Movement -> Inventory Movement, all in one transaction.
    //   BC quietly creates less than asked when stock is short, so availability is checked
    //   up front and the created Take quantities are checked afterwards. Any shortfall errors
    //   and rolls everything back, including the internal movement.
    //   BC deletes the internal movement once it is fully covered by the inventory movement,
    //   so the stored internal movement no. is a reference only.
    //
    // SetQtyToHandle: sets Qty. to Handle on a Take line and its Place line. Never registers.
    //
    // Both follow the WMS Request Management (50216) retry pattern and never Commit.

    var
        LocationRequiredErr: Label 'locationCode is required.';
        LocationNotFoundErr: Label 'Location %1 does not exist.', Comment = '%1 = location code';
        LinesJsonInvalidErr: Label 'linesJson must be a JSON array of lines.';
        NoLinesErr: Label 'linesJson must contain at least one line.';
        LineNotObjectErr: Label 'Line %1 in linesJson is not a JSON object.', Comment = '%1 = line index (1-based)';
        ValueTooLongErr: Label 'Line %1: %2 must not be longer than %3 characters.', Comment = '%1 = line index, %2 = JSON property name, %3 = max length';
        ValueRequiredErr: Label 'Line %1: %2 is required.', Comment = '%1 = line index, %2 = JSON property name';
        ItemNotFoundErr: Label 'Line %1: item %2 does not exist.', Comment = '%1 = line index, %2 = item no.';
        VariantNotFoundErr: Label 'Line %1: variant %2 does not exist for item %3.', Comment = '%1 = line index, %2 = variant code, %3 = item no.';
        WhseTrackedItemErr: Label 'Line %1: item %2 uses item tracking code %3 with warehouse lot, serial or package tracking. Movements for warehouse-tracked items are not supported by this API.', Comment = '%1 = line index, %2 = item no., %3 = item tracking code';
        QuantityNotPositiveErr: Label 'Line %1: quantityBase must be greater than 0.', Comment = '%1 = line index';
        SameBinErr: Label 'Line %1: fromBinCode and toBinCode must be different (both are %2).', Comment = '%1 = line index, %2 = bin code';
        BinNotFoundErr: Label 'Line %1: bin %2 does not exist at location %3.', Comment = '%1 = line index, %2 = bin code, %3 = location code';
        InsufficientStockErr: Label 'Line %1: bin %2 has only %3 of item %4 (variant ''%5'') available to take, but %6 was requested. Nothing was created.', Comment = '%1 = line index, %2 = bin code, %3 = available base qty, %4 = item no., %5 = variant code, %6 = requested base qty';
        NoActivityCreatedErr: Label 'BC did not create an inventory movement from internal movement %1. Nothing was created.', Comment = '%1 = internal movement no.';
        PartialMovementErr: Label 'Line %1: BC created a movement for only %2 of the %3 requested for item %4 from bin %5. Nothing was created.', Comment = '%1 = line index, %2 = created base qty, %3 = requested base qty, %4 = item no., %5 = bin code';
        MovementCreatedMsg: Label 'Inventory movement %1 created from internal movement %2.', Comment = '%1 = inventory movement no., %2 = internal movement no.';
        ActivityNoRequiredErr: Label 'activityNo is required.';
        TakeLineNoRequiredErr: Label 'takeLineNo is required.';
        QtyToHandleNegativeErr: Label 'qtyToHandleBase must not be negative.';
        TakeLineNotFoundErr: Label 'Inventory movement %1 has no line %2.', Comment = '%1 = inventory movement no., %2 = line no.';
        NotTakeLineErr: Label 'Line %2 of inventory movement %1 is a %3 line. takeLineNo must be a Take line.', Comment = '%1 = inventory movement no., %2 = line no., %3 = action type';
        PlaceLineNotFoundErr: Label 'No Place line was found for Take line %2 of inventory movement %1.', Comment = '%1 = inventory movement no., %2 = take line no.';
        LineChangedErr: Label 'Inventory movement %1 line %2 or its Place line was changed in BC after %3. Refresh and try again.', Comment = '%1 = inventory movement no., %2 = take line no., %3 = expected last modified date time';
        QtyToHandleSetMsg: Label 'Qty. to handle on inventory movement %1 lines %2 and %3 set to %4.', Comment = '%1 = inventory movement no., %2 = take line no., %3 = place line no., %4 = base qty';

    procedure CreateMovement(var WmsMovementBuffer: Record "WMS Movement Buffer")
    var
        TempRequestInternalMovementLine: Record "Internal Movement Line" temporary;
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WmsDocumentRequest: Record "WMS Document Request";
        WmsRequestManagement: Codeunit "WMS Request Management";
        InternalMovementNo: Code[20];
        PayloadHash: Text[64];
        ResponseJson: Text;
    begin
        ReadMovementRequest(WmsMovementBuffer, TempRequestInternalMovementLine);

        PayloadHash := WmsRequestManagement.ComputePayloadHash(BuildMovementPayload(WmsMovementBuffer."Location Code", TempRequestInternalMovementLine));
        if WmsRequestManagement.FindExisting(WmsMovementBuffer."External Request Key", "WMS Workflow Type"::Replenishment, PayloadHash, WmsDocumentRequest) then begin
            FillMovementBuffer(WmsMovementBuffer, WmsDocumentRequest.GetResponse());
            exit;
        end;

        CreateInternalMovement(WmsMovementBuffer."Location Code", TempRequestInternalMovementLine, InternalMovementHeader);
        // Keep the number: BC deletes the header once the inventory movement covers it.
        InternalMovementNo := InternalMovementHeader."No.";
        CreateInventoryMovement(InternalMovementHeader, WarehouseActivityHeader);
        CheckMovementCreated(InternalMovementNo, WarehouseActivityHeader."No.", TempRequestInternalMovementLine);
        ResponseJson := BuildMovementResponse(InternalMovementNo, WarehouseActivityHeader."No.", TempRequestInternalMovementLine);

        WmsDocumentRequest.Init();
        WmsDocumentRequest."External Request Key" := WmsMovementBuffer."External Request Key";
        WmsDocumentRequest."Workflow Type" := "WMS Workflow Type"::Replenishment;
        WmsDocumentRequest."Payload Hash" := PayloadHash;
        WmsDocumentRequest."Location Code" := WmsMovementBuffer."Location Code";
        WmsDocumentRequest."Created By" := WmsMovementBuffer."Created By";
        WmsDocumentRequest."Document No." := InternalMovementNo;
        WmsDocumentRequest."Activity No." := WarehouseActivityHeader."No.";
        WmsDocumentRequest."Target Id" := WarehouseActivityHeader.SystemId;
        WmsDocumentRequest.SetResponse(ResponseJson);
        WmsRequestManagement.Register(WmsDocumentRequest);

        FillMovementBuffer(WmsMovementBuffer, ResponseJson);
    end;

    procedure SetQtyToHandle(var WmsQtyToHandleBuffer: Record "WMS Qty. to Handle Buffer")
    var
        TakeWarehouseActivityLine: Record "Warehouse Activity Line";
        PlaceWarehouseActivityLine: Record "Warehouse Activity Line";
        WmsDocumentRequest: Record "WMS Document Request";
        WmsRequestManagement: Codeunit "WMS Request Management";
        LastModifiedAt: DateTime;
        PayloadHash: Text[64];
        ResponseJson: Text;
    begin
        if WmsQtyToHandleBuffer."Activity No." = '' then
            Error(ActivityNoRequiredErr);
        if WmsQtyToHandleBuffer."Take Line No." = 0 then
            Error(TakeLineNoRequiredErr);
        if WmsQtyToHandleBuffer."Qty. to Handle (Base)" < 0 then
            Error(QtyToHandleNegativeErr);

        // expectedLastModifiedDateTime is a precondition, not part of the command, so it stays out of the hash.
        PayloadHash := WmsRequestManagement.ComputePayloadHash(
            WmsQtyToHandleBuffer."Activity No." + '|' +
            Format(WmsQtyToHandleBuffer."Take Line No.", 0, 9) + '|' +
            Format(WmsQtyToHandleBuffer."Qty. to Handle (Base)", 0, 9));
        if WmsRequestManagement.FindExisting(WmsQtyToHandleBuffer."External Request Key", "WMS Workflow Type"::QtyToHandle, PayloadHash, WmsDocumentRequest) then begin
            FillQtyToHandleBuffer(WmsQtyToHandleBuffer, WmsDocumentRequest.GetResponse());
            exit;
        end;

        if not TakeWarehouseActivityLine.Get(TakeWarehouseActivityLine."Activity Type"::"Invt. Movement", WmsQtyToHandleBuffer."Activity No.", WmsQtyToHandleBuffer."Take Line No.") then
            Error(TakeLineNotFoundErr, WmsQtyToHandleBuffer."Activity No.", WmsQtyToHandleBuffer."Take Line No.");
        if TakeWarehouseActivityLine."Action Type" <> TakeWarehouseActivityLine."Action Type"::Take then
            Error(NotTakeLineErr, WmsQtyToHandleBuffer."Activity No.", WmsQtyToHandleBuffer."Take Line No.", TakeWarehouseActivityLine."Action Type");
        if not TakeWarehouseActivityLine.WmsFindPairedPlaceLine(PlaceWarehouseActivityLine) then
            Error(PlaceLineNotFoundErr, WmsQtyToHandleBuffer."Activity No.", WmsQtyToHandleBuffer."Take Line No.");

        if WmsQtyToHandleBuffer."Expected Last Modified At" <> 0DT then
            if (TakeWarehouseActivityLine.SystemModifiedAt > WmsQtyToHandleBuffer."Expected Last Modified At") or
               (PlaceWarehouseActivityLine.SystemModifiedAt > WmsQtyToHandleBuffer."Expected Last Modified At")
            then
                Error(LineChangedErr, WmsQtyToHandleBuffer."Activity No.", WmsQtyToHandleBuffer."Take Line No.", WmsQtyToHandleBuffer."Expected Last Modified At");

        // BC does not carry Qty. to Handle from a Take to its Place on inventory movements, so set both.
        SetLineQtyToHandle(TakeWarehouseActivityLine, WmsQtyToHandleBuffer."Qty. to Handle (Base)");
        SetLineQtyToHandle(PlaceWarehouseActivityLine, WmsQtyToHandleBuffer."Qty. to Handle (Base)");

        // Re-read to pick up the new SystemModifiedAt values.
        TakeWarehouseActivityLine.Get(TakeWarehouseActivityLine."Activity Type", TakeWarehouseActivityLine."No.", TakeWarehouseActivityLine."Line No.");
        PlaceWarehouseActivityLine.Get(PlaceWarehouseActivityLine."Activity Type", PlaceWarehouseActivityLine."No.", PlaceWarehouseActivityLine."Line No.");
        LastModifiedAt := TakeWarehouseActivityLine.SystemModifiedAt;
        if PlaceWarehouseActivityLine.SystemModifiedAt > LastModifiedAt then
            LastModifiedAt := PlaceWarehouseActivityLine.SystemModifiedAt;

        ResponseJson := BuildQtyToHandleResponse(TakeWarehouseActivityLine, PlaceWarehouseActivityLine, LastModifiedAt);

        WmsDocumentRequest.Init();
        WmsDocumentRequest."External Request Key" := WmsQtyToHandleBuffer."External Request Key";
        WmsDocumentRequest."Workflow Type" := "WMS Workflow Type"::QtyToHandle;
        WmsDocumentRequest."Payload Hash" := PayloadHash;
        WmsDocumentRequest."Location Code" := TakeWarehouseActivityLine."Location Code";
        WmsDocumentRequest."Created By" := WmsQtyToHandleBuffer."Created By";
        WmsDocumentRequest."Document No." := TakeWarehouseActivityLine."WMS Internal Movement No.";
        WmsDocumentRequest."Activity No." := TakeWarehouseActivityLine."No.";
        WmsDocumentRequest."Target Id" := TakeWarehouseActivityLine.SystemId;
        WmsDocumentRequest.SetResponse(ResponseJson);
        WmsRequestManagement.Register(WmsDocumentRequest);

        FillQtyToHandleBuffer(WmsQtyToHandleBuffer, ResponseJson);
    end;

    // --- CreateMovement steps ---

    local procedure ReadMovementRequest(var WmsMovementBuffer: Record "WMS Movement Buffer"; var TempRequestInternalMovementLine: Record "Internal Movement Line" temporary)
    var
        Location: Record Location;
        LinesJsonArray: JsonArray;
        LineJsonToken: JsonToken;
        LineJsonObject: JsonObject;
        LineIndex: Integer;
    begin
        if WmsMovementBuffer."Location Code" = '' then
            Error(LocationRequiredErr);
        if not Location.Get(WmsMovementBuffer."Location Code") then
            Error(LocationNotFoundErr, WmsMovementBuffer."Location Code");

        if not LinesJsonArray.ReadFrom(WmsMovementBuffer.GetLinesJson()) then
            Error(LinesJsonInvalidErr);
        if LinesJsonArray.Count() = 0 then
            Error(NoLinesErr);

        // The temporary Internal Movement Line only holds the parsed request; Line No. = index * 10000
        // is also the line no. used on the real internal movement.
        foreach LineJsonToken in LinesJsonArray do begin
            LineIndex += 1;
            if not LineJsonToken.IsObject() then
                Error(LineNotObjectErr, LineIndex);
            LineJsonObject := LineJsonToken.AsObject();

            TempRequestInternalMovementLine.Init();
            TempRequestInternalMovementLine."Line No." := LineIndex * 10000;
            TempRequestInternalMovementLine."Location Code" := Location.Code;
            TempRequestInternalMovementLine."Item No." := CopyStr(GetLineCode(LineJsonObject, 'itemNo', MaxStrLen(TempRequestInternalMovementLine."Item No."), LineIndex), 1, MaxStrLen(TempRequestInternalMovementLine."Item No."));
            TempRequestInternalMovementLine."Variant Code" := CopyStr(GetLineCode(LineJsonObject, 'variantCode', MaxStrLen(TempRequestInternalMovementLine."Variant Code"), LineIndex), 1, MaxStrLen(TempRequestInternalMovementLine."Variant Code"));
            TempRequestInternalMovementLine."From Bin Code" := CopyStr(GetLineCode(LineJsonObject, 'fromBinCode', MaxStrLen(TempRequestInternalMovementLine."From Bin Code"), LineIndex), 1, MaxStrLen(TempRequestInternalMovementLine."From Bin Code"));
            TempRequestInternalMovementLine."To Bin Code" := CopyStr(GetLineCode(LineJsonObject, 'toBinCode', MaxStrLen(TempRequestInternalMovementLine."To Bin Code"), LineIndex), 1, MaxStrLen(TempRequestInternalMovementLine."To Bin Code"));
            TempRequestInternalMovementLine."Qty. (Base)" := GetLineDecimal(LineJsonObject, 'quantityBase', LineIndex);
            CheckRequestLine(TempRequestInternalMovementLine, LineIndex);
            TempRequestInternalMovementLine.Insert();
        end;
    end;

    local procedure CheckRequestLine(RequestInternalMovementLine: Record "Internal Movement Line"; LineIndex: Integer)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Bin: Record Bin;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if RequestInternalMovementLine."Item No." = '' then
            Error(ValueRequiredErr, LineIndex, 'itemNo');
        if not Item.Get(RequestInternalMovementLine."Item No.") then
            Error(ItemNotFoundErr, LineIndex, RequestInternalMovementLine."Item No.");
        if RequestInternalMovementLine."Variant Code" <> '' then
            if not ItemVariant.Get(RequestInternalMovementLine."Item No.", RequestInternalMovementLine."Variant Code") then
                Error(VariantNotFoundErr, LineIndex, RequestInternalMovementLine."Variant Code", RequestInternalMovementLine."Item No.");

        // Warehouse-tracked items would need Whse. Item Tracking Lines on the internal movement.
        if ItemTrackingManagement.GetWhseItemTrkgSetup(Item."No.") then
            Error(WhseTrackedItemErr, LineIndex, Item."No.", Item."Item Tracking Code");

        if RequestInternalMovementLine."Qty. (Base)" <= 0 then
            Error(QuantityNotPositiveErr, LineIndex);

        if RequestInternalMovementLine."From Bin Code" = '' then
            Error(ValueRequiredErr, LineIndex, 'fromBinCode');
        if RequestInternalMovementLine."To Bin Code" = '' then
            Error(ValueRequiredErr, LineIndex, 'toBinCode');
        if RequestInternalMovementLine."From Bin Code" = RequestInternalMovementLine."To Bin Code" then
            Error(SameBinErr, LineIndex, RequestInternalMovementLine."From Bin Code");
        // Internal Movement Line.CheckBin silently skips bins that do not exist, so check here.
        if not Bin.Get(RequestInternalMovementLine."Location Code", RequestInternalMovementLine."From Bin Code") then
            Error(BinNotFoundErr, LineIndex, RequestInternalMovementLine."From Bin Code", RequestInternalMovementLine."Location Code");
        if not Bin.Get(RequestInternalMovementLine."Location Code", RequestInternalMovementLine."To Bin Code") then
            Error(BinNotFoundErr, LineIndex, RequestInternalMovementLine."To Bin Code", RequestInternalMovementLine."Location Code");
    end;

    local procedure BuildMovementPayload(LocationCode: Code[10]; var TempRequestInternalMovementLine: Record "Internal Movement Line" temporary): Text
    var
        Payload: TextBuilder;
    begin
        Payload.Append(LocationCode);
        TempRequestInternalMovementLine.Reset();
        if TempRequestInternalMovementLine.FindSet() then
            repeat
                Payload.Append('|' + TempRequestInternalMovementLine."Item No.");
                Payload.Append('|' + TempRequestInternalMovementLine."Variant Code");
                Payload.Append('|' + TempRequestInternalMovementLine."From Bin Code");
                Payload.Append('|' + TempRequestInternalMovementLine."To Bin Code");
                Payload.Append('|' + Format(TempRequestInternalMovementLine."Qty. (Base)", 0, 9));
            until TempRequestInternalMovementLine.Next() = 0;
        exit(Payload.ToText());
    end;

    local procedure CreateInternalMovement(LocationCode: Code[10]; var TempRequestInternalMovementLine: Record "Internal Movement Line" temporary; var InternalMovementHeader: Record "Internal Movement Header")
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        // Location validation checks the user is a warehouse employee there, the location is
        // Bin Mandatory and it does not use Directed Put-away and Pick.
        // The header To Bin Code is left blank (it shows a Message once lines exist); each line gets its own.
        InternalMovementHeader.Init();
        InternalMovementHeader.Insert(true);
        InternalMovementHeader.Validate("Location Code", LocationCode);
        InternalMovementHeader.Modify(true);

        TempRequestInternalMovementLine.Reset();
        TempRequestInternalMovementLine.FindSet();
        repeat
            InternalMovementLine.Init();
            InternalMovementLine."No." := InternalMovementHeader."No.";
            InternalMovementLine."Line No." := TempRequestInternalMovementLine."Line No.";
            InternalMovementLine.Validate("Location Code", InternalMovementHeader."Location Code");
            // Item No. sets the base UOM. From Bin Code resets Quantity, so it goes before Quantity.
            InternalMovementLine.Validate("Item No.", TempRequestInternalMovementLine."Item No.");
            if TempRequestInternalMovementLine."Variant Code" <> '' then
                InternalMovementLine.Validate("Variant Code", TempRequestInternalMovementLine."Variant Code");
            InternalMovementLine.Validate("From Bin Code", TempRequestInternalMovementLine."From Bin Code");
            InternalMovementLine.Validate("To Bin Code", TempRequestInternalMovementLine."To Bin Code");
            // The line uses the base UOM, so Quantity = base quantity.
            InternalMovementLine.Validate(Quantity, TempRequestInternalMovementLine."Qty. (Base)");
            InternalMovementLine.Insert(true);
        until TempRequestInternalMovementLine.Next() = 0;

        // Checked once every line exists, so lines drawing on the same bin content count against each other.
        InternalMovementLine.Reset();
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.FindSet();
        repeat
            CheckBinAvailability(InternalMovementLine);
            InternalMovementLine.WmsCheckBinContentQty();
        until InternalMovementLine.Next() = 0;
    end;

    // Same calculation as BC's CheckBinContentQty, with an error that names the line, item, bin and quantities.
    local procedure CheckBinAvailability(InternalMovementLine: Record "Internal Movement Line")
    var
        BinContent: Record "Bin Content";
        OpenInternalMovementLine: Record "Internal Movement Line";
        AvailQtyBase: Decimal;
    begin
        BinContent.Init();
        BinContent."Location Code" := InternalMovementLine."Location Code";
        BinContent."Bin Code" := InternalMovementLine."From Bin Code";
        BinContent."Item No." := InternalMovementLine."Item No.";
        BinContent."Variant Code" := InternalMovementLine."Variant Code";
        BinContent."Unit of Measure Code" := InternalMovementLine."Unit of Measure Code";
        AvailQtyBase := BinContent.CalcQtyAvailToTake(0);

        // Every open internal movement line (this one included) taking the same bin content.
        OpenInternalMovementLine.SetCurrentKey("Item No.", "From Bin Code", "Location Code", "Unit of Measure Code", "Variant Code");
        OpenInternalMovementLine.SetRange("Item No.", InternalMovementLine."Item No.");
        OpenInternalMovementLine.SetRange("From Bin Code", InternalMovementLine."From Bin Code");
        OpenInternalMovementLine.SetRange("Location Code", InternalMovementLine."Location Code");
        OpenInternalMovementLine.SetRange("Unit of Measure Code", InternalMovementLine."Unit of Measure Code");
        OpenInternalMovementLine.SetRange("Variant Code", InternalMovementLine."Variant Code");
        OpenInternalMovementLine.CalcSums("Qty. (Base)");
        AvailQtyBase -= OpenInternalMovementLine."Qty. (Base)" - InternalMovementLine."Qty. (Base)";

        if AvailQtyBase < InternalMovementLine."Qty. (Base)" then begin
            if AvailQtyBase < 0 then
                AvailQtyBase := 0;
            Error(
                InsufficientStockErr, InternalMovementLine."Line No." div 10000, InternalMovementLine."From Bin Code", AvailQtyBase,
                InternalMovementLine."Item No.", InternalMovementLine."Variant Code", InternalMovementLine."Qty. (Base)");
        end;
    end;

    local procedure CreateInventoryMovement(var InternalMovementHeader: Record "Internal Movement Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
        InternalMovementNo: Code[20];
    begin
        InternalMovementNo := InternalMovementHeader."No.";
        // HideDialog suppresses the Confirm before and the Message after creation.
        CreateInventoryPickMovement.SetHideDialog(true);
        CreateInventoryPickMovement.SetSuppressCommit(true);
        CreateInventoryPickMovement.CreateInvtMvntWithoutSource(InternalMovementHeader);
        CreateInventoryPickMovement.GetWhseActivHeader(WarehouseActivityHeader);
        if WarehouseActivityHeader."No." = '' then
            Error(NoActivityCreatedErr, InternalMovementNo);
    end;

    // BC reduces the movement quietly when stock runs short between the check and the creation.
    local procedure CheckMovementCreated(InternalMovementNo: Code[20]; ActivityNo: Code[20]; var TempRequestInternalMovementLine: Record "Internal Movement Line" temporary)
    var
        TakeWarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        TempRequestInternalMovementLine.Reset();
        TempRequestInternalMovementLine.FindSet();
        repeat
            FilterTakeLines(TakeWarehouseActivityLine, InternalMovementNo, ActivityNo, TempRequestInternalMovementLine."Line No.");
            TakeWarehouseActivityLine.CalcSums("Qty. (Base)");
            if TakeWarehouseActivityLine."Qty. (Base)" <> TempRequestInternalMovementLine."Qty. (Base)" then
                Error(
                    PartialMovementErr, TempRequestInternalMovementLine."Line No." div 10000, TakeWarehouseActivityLine."Qty. (Base)",
                    TempRequestInternalMovementLine."Qty. (Base)", TempRequestInternalMovementLine."Item No.", TempRequestInternalMovementLine."From Bin Code");
        until TempRequestInternalMovementLine.Next() = 0;
    end;

    local procedure FilterTakeLines(var TakeWarehouseActivityLine: Record "Warehouse Activity Line"; InternalMovementNo: Code[20]; ActivityNo: Code[20]; SourceLineNo: Integer)
    begin
        TakeWarehouseActivityLine.Reset();
        TakeWarehouseActivityLine.SetRange("Activity Type", TakeWarehouseActivityLine."Activity Type"::"Invt. Movement");
        TakeWarehouseActivityLine.SetRange("No.", ActivityNo);
        TakeWarehouseActivityLine.SetRange("Action Type", TakeWarehouseActivityLine."Action Type"::Take);
        TakeWarehouseActivityLine.SetRange("WMS Internal Movement No.", InternalMovementNo);
        TakeWarehouseActivityLine.SetRange("WMS Source Line No.", SourceLineNo);
    end;

    local procedure BuildMovementResponse(InternalMovementNo: Code[20]; ActivityNo: Code[20]; var TempRequestInternalMovementLine: Record "Internal Movement Line" temporary) ResponseJson: Text
    var
        TakeWarehouseActivityLine: Record "Warehouse Activity Line";
        PlaceWarehouseActivityLine: Record "Warehouse Activity Line";
        ResponseJsonObject: JsonObject;
        LinesJsonArray: JsonArray;
        LineJsonObject: JsonObject;
        PlaceLineNo: Integer;
    begin
        // One entry per Take line. BC normally creates one Take/Place pair per request line.
        TempRequestInternalMovementLine.Reset();
        TempRequestInternalMovementLine.FindSet();
        repeat
            FilterTakeLines(TakeWarehouseActivityLine, InternalMovementNo, ActivityNo, TempRequestInternalMovementLine."Line No.");
            if TakeWarehouseActivityLine.FindSet() then
                repeat
                    PlaceLineNo := 0;
                    if TakeWarehouseActivityLine.WmsFindPairedPlaceLine(PlaceWarehouseActivityLine) then
                        PlaceLineNo := PlaceWarehouseActivityLine."Line No.";
                    Clear(LineJsonObject);
                    LineJsonObject.Add('sourceLineNo', TempRequestInternalMovementLine."Line No.");
                    LineJsonObject.Add('itemNo', TakeWarehouseActivityLine."Item No.");
                    LineJsonObject.Add('takeLineNo', TakeWarehouseActivityLine."Line No.");
                    LineJsonObject.Add('placeLineNo', PlaceLineNo);
                    LineJsonObject.Add('quantityBase', TakeWarehouseActivityLine."Qty. (Base)");
                    LinesJsonArray.Add(LineJsonObject);
                until TakeWarehouseActivityLine.Next() = 0;
        until TempRequestInternalMovementLine.Next() = 0;

        ResponseJsonObject.Add('internalMovementNo', InternalMovementNo);
        ResponseJsonObject.Add('activityNo', ActivityNo);
        ResponseJsonObject.Add('lines', LinesJsonArray);
        ResponseJsonObject.WriteTo(ResponseJson);
    end;

    local procedure FillMovementBuffer(var WmsMovementBuffer: Record "WMS Movement Buffer"; ResponseJson: Text)
    var
        ResponseJsonObject: JsonObject;
    begin
        ResponseJsonObject.ReadFrom(ResponseJson);
        WmsMovementBuffer."Internal Movement No." := CopyStr(GetResponseText(ResponseJsonObject, 'internalMovementNo'), 1, MaxStrLen(WmsMovementBuffer."Internal Movement No."));
        WmsMovementBuffer."Activity No." := CopyStr(GetResponseText(ResponseJsonObject, 'activityNo'), 1, MaxStrLen(WmsMovementBuffer."Activity No."));
        WmsMovementBuffer.SetResponseJson(ResponseJson);
        WmsMovementBuffer.Result := CopyStr(StrSubstNo(MovementCreatedMsg, WmsMovementBuffer."Activity No.", WmsMovementBuffer."Internal Movement No."), 1, MaxStrLen(WmsMovementBuffer.Result));
    end;

    // --- SetQtyToHandle steps ---

    local procedure SetLineQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandleBase: Decimal)
    begin
        // Standard validation enforces Qty. to Handle <= Qty. Outstanding.
        if WarehouseActivityLine."Qty. per Unit of Measure" = 1 then
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandleBase)
        else
            WarehouseActivityLine.Validate("Qty. to Handle (Base)", QtyToHandleBase);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure BuildQtyToHandleResponse(TakeWarehouseActivityLine: Record "Warehouse Activity Line"; PlaceWarehouseActivityLine: Record "Warehouse Activity Line"; LastModifiedAt: DateTime) ResponseJson: Text
    var
        ResponseJsonObject: JsonObject;
    begin
        ResponseJsonObject.Add('activityNo', TakeWarehouseActivityLine."No.");
        ResponseJsonObject.Add('takeLineNo', TakeWarehouseActivityLine."Line No.");
        ResponseJsonObject.Add('placeLineNo', PlaceWarehouseActivityLine."Line No.");
        ResponseJsonObject.Add('qtyToHandleBase', TakeWarehouseActivityLine."Qty. to Handle (Base)");
        ResponseJsonObject.Add('qtyOutstandingBase', TakeWarehouseActivityLine."Qty. Outstanding (Base)");
        ResponseJsonObject.Add('qtyHandledBase', TakeWarehouseActivityLine."Qty. Handled (Base)");
        ResponseJsonObject.Add('lastModifiedDateTime', LastModifiedAt);
        ResponseJsonObject.WriteTo(ResponseJson);
    end;

    local procedure FillQtyToHandleBuffer(var WmsQtyToHandleBuffer: Record "WMS Qty. to Handle Buffer"; ResponseJson: Text)
    var
        ResponseJsonObject: JsonObject;
        JsonValueToken: JsonToken;
    begin
        ResponseJsonObject.ReadFrom(ResponseJson);
        WmsQtyToHandleBuffer."Place Line No." := GetResponseInteger(ResponseJsonObject, 'placeLineNo');
        WmsQtyToHandleBuffer."Qty. to Handle (Base)" := GetResponseDecimal(ResponseJsonObject, 'qtyToHandleBase');
        WmsQtyToHandleBuffer."Qty. Outstanding (Base)" := GetResponseDecimal(ResponseJsonObject, 'qtyOutstandingBase');
        WmsQtyToHandleBuffer."Qty. Handled (Base)" := GetResponseDecimal(ResponseJsonObject, 'qtyHandledBase');
        if ResponseJsonObject.Get('lastModifiedDateTime', JsonValueToken) then
            WmsQtyToHandleBuffer."Last Modified At" := JsonValueToken.AsValue().AsDateTime();
        WmsQtyToHandleBuffer.Result := CopyStr(
            StrSubstNo(QtyToHandleSetMsg, WmsQtyToHandleBuffer."Activity No.", WmsQtyToHandleBuffer."Take Line No.", WmsQtyToHandleBuffer."Place Line No.", WmsQtyToHandleBuffer."Qty. to Handle (Base)"),
            1, MaxStrLen(WmsQtyToHandleBuffer.Result));
    end;

    // --- JSON helpers ---

    local procedure GetLineCode(LineJsonObject: JsonObject; PropertyName: Text; MaxLength: Integer; LineIndex: Integer) Value: Text
    var
        JsonValueToken: JsonToken;
    begin
        if not LineJsonObject.Get(PropertyName, JsonValueToken) then
            exit('');
        if not JsonValueToken.IsValue() then
            exit('');
        if JsonValueToken.AsValue().IsNull() then
            exit('');
        Value := UpperCase(DelChr(JsonValueToken.AsValue().AsText(), '<>', ' '));
        if StrLen(Value) > MaxLength then
            Error(ValueTooLongErr, LineIndex, PropertyName, MaxLength);
    end;

    local procedure GetLineDecimal(LineJsonObject: JsonObject; PropertyName: Text; LineIndex: Integer): Decimal
    var
        JsonValueToken: JsonToken;
    begin
        if not LineJsonObject.Get(PropertyName, JsonValueToken) then
            Error(ValueRequiredErr, LineIndex, PropertyName);
        if not JsonValueToken.IsValue() then
            Error(ValueRequiredErr, LineIndex, PropertyName);
        if JsonValueToken.AsValue().IsNull() then
            Error(ValueRequiredErr, LineIndex, PropertyName);
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

    local procedure GetResponseInteger(ResponseJsonObject: JsonObject; PropertyName: Text): Integer
    var
        JsonValueToken: JsonToken;
    begin
        if ResponseJsonObject.Get(PropertyName, JsonValueToken) then
            exit(JsonValueToken.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetResponseDecimal(ResponseJsonObject: JsonObject; PropertyName: Text): Decimal
    var
        JsonValueToken: JsonToken;
    begin
        if ResponseJsonObject.Get(PropertyName, JsonValueToken) then
            exit(JsonValueToken.AsValue().AsDecimal());
        exit(0);
    end;
}
