namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Warehouse.Structure;

codeunit 50221 "MIB Bin Availability Engine"
{
    procedure CalcAvailableQty(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]): Decimal
    var
        BinContent: Record "Bin Content";
    begin
        if not BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UOMCode) then
            exit(0);
        BinContent.CalcFields("MIB Assignment Qty");
        exit(BinContent."Quantity (Base)" - BinContent."MIB Assignment Qty");
    end;

    procedure GetBinSuggestion(ItemNo: Code[20]; LocationCode: Code[10]; QtyNeeded: Decimal; var TempBinContent: Record "Bin Content" temporary)
    var
        BinContent: Record "Bin Content";
        BinRec: Record Bin;
        AvailQty: Decimal;
    begin
        TempBinContent.Reset();
        TempBinContent.DeleteAll();

        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        if BinContent.FindSet() then
            repeat
                BinContent.CalcFields("MIB Assignment Qty");
                AvailQty := BinContent."Quantity (Base)" - BinContent."MIB Assignment Qty";
                if AvailQty >= QtyNeeded then begin
                    TempBinContent := BinContent;
                    if BinRec.Get(LocationCode, BinContent."Bin Code") then
                        TempBinContent."Bin Ranking" := BinRec."MIB Allocation Priority";
                    if TempBinContent.Insert() then;
                end;
            until BinContent.Next() = 0;
    end;

    procedure CheckConflicts(AssignmentNo: Code[20]): Boolean
    var
        AssignLine: Record "MIB Bin Assignment Line";
    begin
        AssignLine.SetRange("Assignment No.", AssignmentNo);
        AssignLine.SetRange(Status, "MIB Bin Assignment Status"::Conflict);
        exit(not AssignLine.IsEmpty());
    end;

    procedure CalcReservedQty(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]): Decimal
    var
        AssignLine: Record "MIB Bin Assignment Line";
    begin
        AssignLine.SetRange("Location Code", LocationCode);
        AssignLine.SetRange("Bin Code", BinCode);
        AssignLine.SetRange("Item No.", ItemNo);
        AssignLine.SetFilter(Status, '%1|%2',
            "MIB Bin Assignment Status"::Assigned,
            "MIB Bin Assignment Status"::Confirmed);
        AssignLine.CalcSums(Quantity);
        exit(AssignLine.Quantity);
    end;
}
