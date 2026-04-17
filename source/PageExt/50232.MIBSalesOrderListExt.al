namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Sales.Document;

pageextension 50232 "MIB Sales Order List Ext" extends "Sales Order List"
{
    layout
    {
        addafter(Status)
        {
            field("MIB Bin Assignment Status"; Rec."MIB Bin Assignment Status")
            {
                ApplicationArea = Warehouse;
                Caption = 'Bin Assignment Status';
                ToolTip = 'Specifies the bin assignment status for this sales order.';
                StyleExpr = BinAssignStatusStyleExpr;
            }
        }
    }

    var
        BinAssignStatusStyleExpr: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."MIB Bin Assignment Status" of
            Rec."MIB Bin Assignment Status"::Conflict:
                BinAssignStatusStyleExpr := 'Unfavorable';
            Rec."MIB Bin Assignment Status"::Confirmed:
                BinAssignStatusStyleExpr := 'Favorable';
            Rec."MIB Bin Assignment Status"::Assigned:
                BinAssignStatusStyleExpr := 'Strong';
            else
                BinAssignStatusStyleExpr := 'Standard';
        end;
    end;
}
