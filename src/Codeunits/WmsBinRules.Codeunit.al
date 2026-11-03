codeunit 50218 "WMS Bin Rules"
{
    // Bin checks shared by the WMS command endpoints that assign items to bins (#4, #7), and the
    // whole-quantity rule shared by every WMS command endpoint (#10).
    // Errors name the offending location, bin, item or field so the app can show them as-is.

    var
        LocationNotFoundErr: Label 'Location %1 does not exist.', Comment = '%1 = location code';
        LocationNotBinMandatoryErr: Label 'Location %1 is not set up with Bin Mandatory.', Comment = '%1 = location code';
        BinNotFoundErr: Label 'Bin %1 does not exist in location %2.', Comment = '%1 = bin code, %2 = location code';
        BinBlockedErr: Label 'Bin %1 in location %2 has Block Movement set to %3.', Comment = '%1 = bin code, %2 = location code, %3 = block movement value';
        BinDedicatedErr: Label 'Bin %1 in location %2 is Dedicated and cannot be used.', Comment = '%1 = bin code, %2 = location code';
        BinIsAdjustmentBinErr: Label 'Bin %1 is the adjustment bin of location %2 and cannot be used.', Comment = '%1 = bin code, %2 = location code';
        BinFixedToOtherItemErr: Label 'Bin %1 in location %2 is already Fixed to item %3 variant ''%4''. Set allowOtherFixedItem to assign another item.', Comment = '%1 = bin code, %2 = location code, %3 = item no., %4 = variant code';
        ItemNotFoundErr: Label 'Item %1 does not exist.', Comment = '%1 = item no.';
        ItemNotInventoryErr: Label 'Item %1 must be of type Inventory.', Comment = '%1 = item no.';
        VariantNotFoundErr: Label 'Variant %1 does not exist for item %2.', Comment = '%1 = variant code, %2 = item no.';
        UnitOfMeasureNotFoundErr: Label 'Unit of measure %1 does not exist for item %2.', Comment = '%1 = unit of measure code, %2 = item no.';
        NotWholeQuantityErr: Label '%1 is %2, which is not a whole number of %3. Fractional quantities are not accepted.', Comment = '%1 = API field name, %2 = quantity, %3 = unit of measure code';
        NotWholeBaseQuantityErr: Label '%1 is %2 base units, which is not a whole number of %3 (%4 base units per %3). Fractional quantities are not accepted.', Comment = '%1 = API field name, %2 = base quantity, %3 = unit of measure code, %4 = qty. per unit of measure';

    procedure CheckBinUsable(LocationCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
    begin
        if not Location.Get(LocationCode) then
            Error(LocationNotFoundErr, LocationCode);
        if not Location."Bin Mandatory" then
            Error(LocationNotBinMandatoryErr, LocationCode);

        if not Bin.Get(LocationCode, BinCode) then
            Error(BinNotFoundErr, BinCode, LocationCode);
        if Bin."Block Movement" <> Bin."Block Movement"::" " then
            Error(BinBlockedErr, BinCode, LocationCode, Bin."Block Movement");
        if Bin.Dedicated then
            Error(BinDedicatedErr, BinCode, LocationCode);
        if (Location."Adjustment Bin Code" <> '') and (Location."Adjustment Bin Code" = BinCode) then
            Error(BinIsAdjustmentBinErr, BinCode, LocationCode);
    end;

    procedure CheckFixedAssignment(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; AllowOtherItem: Boolean)
    var
        BinContent: Record "Bin Content";
    begin
        // BC itself lets any number of items be Fixed in one bin. The WMS stops an item from
        // newly becoming Fixed in a bin another item already has, unless the caller opts out.
        if AllowOtherItem then
            exit;

        // Already Fixed here: the request doesn't change who owns the bin, so shared pick
        // faces (about 20% of Fixed bins in DEV) stay editable.
        if BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode) then
            if BinContent.Fixed then
                exit;
        Clear(BinContent);

        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange(Fixed, true);

        BinContent.SetFilter("Item No.", '<>%1', ItemNo);
        if BinContent.FindFirst() then
            Error(BinFixedToOtherItemErr, BinCode, LocationCode, BinContent."Item No.", BinContent."Variant Code");

        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetFilter("Variant Code", '<>%1', VariantCode);
        if BinContent.FindFirst() then
            Error(BinFixedToOtherItemErr, BinCode, LocationCode, BinContent."Item No.", BinContent."Variant Code");
    end;

    procedure CheckItemVariantUnitOfMeasure(ItemNo: Code[20]; VariantCode: Code[10]; var UnitOfMeasureCode: Code[10])
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
    begin
        // Checks the item can be put in a bin and defaults a blank unit of measure to the
        // item's base unit, so callers can hash and store the value actually used.
        if not Item.Get(ItemNo) then
            Error(ItemNotFoundErr, ItemNo);
        if Item.Type <> Item.Type::Inventory then
            Error(ItemNotInventoryErr, ItemNo);

        if VariantCode <> '' then
            if not ItemVariant.Get(ItemNo, VariantCode) then
                Error(VariantNotFoundErr, VariantCode, ItemNo);

        if UnitOfMeasureCode = '' then
            UnitOfMeasureCode := Item."Base Unit of Measure";
        if not ItemUnitOfMeasure.Get(ItemNo, UnitOfMeasureCode) then
            Error(UnitOfMeasureNotFoundErr, UnitOfMeasureCode, ItemNo);
    end;

    procedure CheckWholeQuantity(FieldName: Text; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    begin
        // The warehouse never deals in fractions, so this deliberately ignores the unit's
        // Qty. Rounding Precision (0 there means BC accepts 0.00001). Never rounds.
        if Quantity <> Round(Quantity, 1) then
            Error(NotWholeQuantityErr, FieldName, Quantity, UnitOfMeasureCode);
    end;

    procedure CheckWholeBaseQuantity(FieldName: Text; QuantityBase: Decimal; QtyPerUnitOfMeasure: Decimal; UnitOfMeasureCode: Code[10])
    var
        Quantity: Decimal;
    begin
        // A base quantity must come to whole units of the line's unit of measure.
        if QtyPerUnitOfMeasure in [0, 1] then begin
            CheckWholeQuantity(FieldName, QuantityBase, UnitOfMeasureCode);
            exit;
        end;
        Quantity := QuantityBase / QtyPerUnitOfMeasure;
        if Quantity <> Round(Quantity, 1) then
            Error(NotWholeBaseQuantityErr, FieldName, QuantityBase, UnitOfMeasureCode, QtyPerUnitOfMeasure);
    end;
}
