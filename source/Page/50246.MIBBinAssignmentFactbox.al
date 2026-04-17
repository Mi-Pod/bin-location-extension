namespace MiOneBrands.WarehouseBinAssignment;

page 50246 "MIB Bin Assignment Factbox"
{
    PageType = CardPart;
    SourceTable = "MIB Bin Assignment Header";
    Caption = 'Bin Assignment';

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Warehouse;
                Caption = 'Assignment No.';
                ToolTip = 'Specifies the bin assignment number for this sales order.';
            }
            field(Status; Rec.Status)
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the current assignment status.';
                StyleExpr = StatusStyleExpr;
            }
            field("No. of Assignment Lines"; Rec."No. of Assignment Lines")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the number of bin assignment lines.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AssignBins)
            {
                Caption = 'Assign Bins';
                ApplicationArea = Warehouse;
                Image = Bin;
                ToolTip = 'Open the bin assignment document.';
                RunObject = Page "MIB Bin Assignment";
                RunPageLink = "No." = field("No.");
            }
        }
    }

    var
        StatusStyleExpr: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Conflict:
                StatusStyleExpr := 'Unfavorable';
            Rec.Status::Confirmed:
                StatusStyleExpr := 'Favorable';
            Rec.Status::Assigned:
                StatusStyleExpr := 'Strong';
            Rec.Status::Partial:
                StatusStyleExpr := 'Ambiguous';
            else
                StatusStyleExpr := 'Standard';
        end;
    end;
}
