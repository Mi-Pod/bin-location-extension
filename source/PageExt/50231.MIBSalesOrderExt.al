namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Sales.Document;

pageextension 50231 "MIB Sales Order Ext" extends "Sales Order"
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
            field("MIB Bin Assignment No."; Rec."MIB Bin Assignment No.")
            {
                ApplicationArea = Warehouse;
                Caption = 'Bin Assignment No.';
                ToolTip = 'Specifies the bin assignment number linked to this sales order.';
            }
        }
        addfirst(factboxes)
        {
            part(BinAssignmentFactbox; "MIB Bin Assignment Factbox")
            {
                ApplicationArea = Warehouse;
                Caption = 'Bin Assignment';
                SubPageLink = "Sales Order No." = field("No.");
            }
        }
    }

    actions
    {
        addlast("F&unctions")
        {
            action(AssignBins)
            {
                Caption = 'Assign Bins';
                ApplicationArea = Warehouse;
                Image = Bin;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open or create the bin assignment for this sales order.';

                trigger OnAction()
                var
                    AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
                    AssignmentNo: Code[20];
                    AssignPage: Page "MIB Bin Assignment";
                    AssignHeader: Record "MIB Bin Assignment Header";
                begin
                    AssignmentNo := AssignMgt.GetOrCreateAssignment(Rec);
                    AssignHeader.Get(AssignmentNo);
                    AssignPage.SetRecord(AssignHeader);
                    AssignPage.Run();
                end;
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
