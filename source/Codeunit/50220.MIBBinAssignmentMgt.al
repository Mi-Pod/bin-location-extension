namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Sales.Document;

codeunit 50220 "MIB Bin Assignment Mgt."
{
    procedure CreateAssignment(SalesHeader: Record "Sales Header"): Code[20]
    var
        AssignHeader: Record "MIB Bin Assignment Header";
        SalesLine: Record "Sales Line";
        AssignLine: Record "MIB Bin Assignment Line";
        LineNo: Integer;
    begin
        AssignHeader.Init();
        AssignHeader."Sales Order No." := SalesHeader."No.";
        AssignHeader."Location Code" := SalesHeader."Location Code";
        AssignHeader.Status := "MIB Bin Assignment Status"::Open;
        AssignHeader.Insert(true);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                LineNo += 10000;
                AssignLine.Init();
                AssignLine."Assignment No." := AssignHeader."No.";
                AssignLine."Line No." := LineNo;
                AssignLine."Sales Order No." := SalesHeader."No.";
                AssignLine."Sales Line No." := SalesLine."Line No.";
                AssignLine."Item No." := SalesLine."No.";
                AssignLine."Variant Code" := SalesLine."Variant Code";
                AssignLine."Location Code" := SalesLine."Location Code";
                AssignLine."Unit of Measure Code" := SalesLine."Unit of Measure Code";
                AssignLine.Quantity := SalesLine."Outstanding Quantity";
                AssignLine.Status := "MIB Bin Assignment Status"::Open;
                AssignLine.Insert(true);
            until SalesLine.Next() = 0;

        UpdateStatus(AssignHeader."No.");
        exit(AssignHeader."No.");
    end;

    procedure ValidateAvailability(var AssignLine: Record "MIB Bin Assignment Line"): Boolean
    var
        BinAvailEngine: Codeunit "MIB Bin Availability Engine";
        AvailQty: Decimal;
    begin
        AvailQty := BinAvailEngine.CalcAvailableQty(
            AssignLine."Location Code",
            AssignLine."Bin Code",
            AssignLine."Item No.",
            AssignLine."Variant Code",
            AssignLine."Unit of Measure Code");

        if AvailQty < AssignLine.Quantity then begin
            AssignLine.Status := "MIB Bin Assignment Status"::Conflict;
            AssignLine.Modify(true);
            exit(false);
        end;

        AssignLine.Status := "MIB Bin Assignment Status"::Assigned;
        AssignLine.Modify(true);
        exit(true);
    end;

    procedure ReleaseAssignment(AssignmentNo: Code[20])
    var
        AssignHeader: Record "MIB Bin Assignment Header";
        AssignLine: Record "MIB Bin Assignment Line";
        SalesHeader: Record "Sales Header";
    begin
        AssignHeader.Get(AssignmentNo);
        AssignHeader.Status := "MIB Bin Assignment Status"::Confirmed;
        AssignHeader.Modify(true);

        AssignLine.SetRange("Assignment No.", AssignmentNo);
        if AssignLine.FindSet() then
            repeat
                if AssignLine.Status = "MIB Bin Assignment Status"::Assigned then begin
                    AssignLine.Status := "MIB Bin Assignment Status"::Confirmed;
                    AssignLine.Modify(true);
                end;
            until AssignLine.Next() = 0;

        if SalesHeader.Get(SalesHeader."Document Type"::Order, AssignHeader."Sales Order No.") then begin
            SalesHeader."MIB Bin Assignment No." := AssignmentNo;
            SalesHeader."MIB Bin Assignment Status" := "MIB Bin Assignment Status"::Confirmed;
            SalesHeader.Modify(true);
        end;
    end;

    procedure CancelAssignment(AssignmentNo: Code[20])
    var
        AssignHeader: Record "MIB Bin Assignment Header";
        AssignLine: Record "MIB Bin Assignment Line";
        SalesHeader: Record "Sales Header";
    begin
        AssignHeader.Get(AssignmentNo);

        AssignLine.SetRange("Assignment No.", AssignmentNo);
        AssignLine.DeleteAll(true);

        if SalesHeader.Get(SalesHeader."Document Type"::Order, AssignHeader."Sales Order No.") then begin
            SalesHeader."MIB Bin Assignment No." := '';
            SalesHeader."MIB Bin Assignment Status" := "MIB Bin Assignment Status"::Open;
            SalesHeader.Modify(true);
        end;

        AssignHeader.Delete(true);
    end;

    procedure UpdateStatus(AssignmentNo: Code[20])
    var
        AssignHeader: Record "MIB Bin Assignment Header";
        AssignLine: Record "MIB Bin Assignment Line";
        HasConflict: Boolean;
        HasOpen: Boolean;
        HasAssigned: Boolean;
    begin
        AssignHeader.Get(AssignmentNo);

        AssignLine.SetRange("Assignment No.", AssignmentNo);
        if AssignLine.FindSet() then
            repeat
                case AssignLine.Status of
                    "MIB Bin Assignment Status"::Conflict:
                        HasConflict := true;
                    "MIB Bin Assignment Status"::Assigned,
                    "MIB Bin Assignment Status"::Confirmed:
                        HasAssigned := true;
                    "MIB Bin Assignment Status"::Open:
                        HasOpen := true;
                end;
            until AssignLine.Next() = 0;

        if HasConflict then
            AssignHeader.Status := "MIB Bin Assignment Status"::Conflict
        else if HasOpen and HasAssigned then
            AssignHeader.Status := "MIB Bin Assignment Status"::Partial
        else if HasAssigned and not HasOpen then
            AssignHeader.Status := "MIB Bin Assignment Status"::Assigned
        else
            AssignHeader.Status := "MIB Bin Assignment Status"::Open;

        AssignHeader.Modify(true);
    end;

    procedure GetOrCreateAssignment(SalesHeader: Record "Sales Header"): Code[20]
    var
        AssignHeader: Record "MIB Bin Assignment Header";
    begin
        AssignHeader.SetRange("Sales Order No.", SalesHeader."No.");
        AssignHeader.SetFilter(Status, '<>%1', "MIB Bin Assignment Status"::Confirmed);
        if AssignHeader.FindFirst() then
            exit(AssignHeader."No.");

        exit(CreateAssignment(SalesHeader));
    end;
}
