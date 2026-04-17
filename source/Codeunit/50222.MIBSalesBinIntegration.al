namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;

codeunit 50222 "MIB Sales Bin Integration"
{
    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeReleaseSalesDocument', '', false, false)]
    local procedure OnBeforeReleaseSalesDocument(var SalesHeader: Record "Sales Header")
    var
        Setup: Record "MIB Bin Assignment Setup";
        AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
        BinAvailEngine: Codeunit "MIB Bin Availability Engine";
        AssignmentNo: Code[20];
    begin
        if not Setup.Get() then
            exit;
        if not Setup."Auto-Assign on Release" then
            exit;
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit;

        AssignmentNo := AssignMgt.GetOrCreateAssignment(SalesHeader);

        if Setup."Require Full Assignment" and BinAvailEngine.CheckConflicts(AssignmentNo) then
            Error('Cannot release sales order %1: bin assignment has unresolved conflicts. Resolve conflicts on the Bin Assignment page before releasing.', SalesHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReleaseSalesDocument', '', false, false)]
    local procedure OnAfterReleaseSalesDocument(var SalesHeader: Record "Sales Header")
    var
        AssignHeader: Record "MIB Bin Assignment Header";
    begin
        if SalesHeader."MIB Bin Assignment No." = '' then
            exit;
        if not AssignHeader.Get(SalesHeader."MIB Bin Assignment No.") then
            exit;
        SalesHeader."MIB Bin Assignment Status" := AssignHeader.Status;
        SalesHeader.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CommitIsSuppressed: Boolean; EInvoiceErr: Boolean)
    var
        AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
    begin
        if SalesHeader."MIB Bin Assignment No." = '' then
            exit;
        AssignMgt.CancelAssignment(SalesHeader."MIB Bin Assignment No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    var
        AssignLine: Record "MIB Bin Assignment Line";
        AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
        AssignmentNos: List of [Code[20]];
        AssignmentNo: Code[20];
    begin
        AssignLine.SetRange("Sales Order No.", Rec."Document No.");
        AssignLine.SetRange("Sales Line No.", Rec."Line No.");
        if AssignLine.FindSet() then
            repeat
                if not AssignmentNos.Contains(AssignLine."Assignment No.") then
                    AssignmentNos.Add(AssignLine."Assignment No.");
            until AssignLine.Next() = 0;

        AssignLine.SetRange("Sales Order No.", Rec."Document No.");
        AssignLine.SetRange("Sales Line No.", Rec."Line No.");
        AssignLine.DeleteAll(true);

        foreach AssignmentNo in AssignmentNos do
            AssignMgt.UpdateStatus(AssignmentNo);
    end;
}
