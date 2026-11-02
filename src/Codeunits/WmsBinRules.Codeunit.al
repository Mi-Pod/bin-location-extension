codeunit 50218 "WMS Bin Rules"
{
    // Bin checks shared by the WMS command endpoints that assign items to bins (#4, #7).
    // Errors name the offending location, bin or item so the app can show them as-is.

    var
        LocationNotFoundErr: Label 'Location %1 does not exist.', Comment = '%1 = location code';
        LocationNotBinMandatoryErr: Label 'Location %1 is not set up with Bin Mandatory.', Comment = '%1 = location code';
        BinNotFoundErr: Label 'Bin %1 does not exist in location %2.', Comment = '%1 = bin code, %2 = location code';
        BinBlockedErr: Label 'Bin %1 in location %2 has Block Movement set to %3.', Comment = '%1 = bin code, %2 = location code, %3 = block movement value';
        BinDedicatedErr: Label 'Bin %1 in location %2 is Dedicated and cannot be used.', Comment = '%1 = bin code, %2 = location code';
        BinIsAdjustmentBinErr: Label 'Bin %1 is the adjustment bin of location %2 and cannot be used.', Comment = '%1 = bin code, %2 = location code';
        BinFixedToOtherItemErr: Label 'Bin %1 in location %2 is already Fixed to item %3 variant ''%4''. Set allowOtherFixedItem to assign another item.', Comment = '%1 = bin code, %2 = location code, %3 = item no., %4 = variant code';

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

    procedure CheckFixedAssignment(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; AllowOtherItem: Boolean)
    var
        BinContent: Record "Bin Content";
    begin
        // BC itself lets any number of items be Fixed in one bin; the WMS allows only one
        // item/variant per bin unless the caller explicitly opts out.
        if AllowOtherItem then
            exit;

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
}
