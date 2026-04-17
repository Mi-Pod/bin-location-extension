namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Warehouse.Structure;

pageextension 50230 "MIB Bin Contents Ext" extends "Bin Contents List"
{
    layout
    {
        addafter("Quantity (Base)")
        {
            field("MIB Assignment Qty"; Rec."MIB Assignment Qty")
            {
                ApplicationArea = Warehouse;
                Caption = 'MIB Assignment Qty';
                ToolTip = 'Specifies the quantity reserved via MIB bin assignments.';
            }
            field("MIB Bin Assignment Status"; Rec."MIB Bin Assignment Status")
            {
                ApplicationArea = Warehouse;
                Caption = 'MIB Assignment Status';
                ToolTip = 'Specifies the rolled-up MIB bin assignment status for this bin content row.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(ShowAssignments)
            {
                Caption = 'Show Assignments';
                ApplicationArea = Warehouse;
                Image = Bin;
                ToolTip = 'Show all open bin assignments for this location.';

                trigger OnAction()
                var
                    AssignHeader: Record "MIB Bin Assignment Header";
                    AssignList: Page "MIB Bin Assignment List";
                begin
                    AssignHeader.SetRange("Location Code", Rec."Location Code");
                    AssignList.SetTableView(AssignHeader);
                    AssignList.Run();
                end;
            }
        }
    }
}
