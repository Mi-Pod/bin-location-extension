namespace MiOneBrands.WarehouseBinAssignment;

page 50242 "MIB Bin Assignment List"
{
    PageType = List;
    SourceTable = "MIB Bin Assignment Header";
    Caption = 'MIB Bin Assignment List';
    CardPageId = "MIB Bin Assignment";
    ApplicationArea = Warehouse;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(List)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the assignment number.';
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the sales order this assignment covers.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse location.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the assignment status.';
                    StyleExpr = StatusStyleExpr;
                }
                field("Assigned By"; Rec."Assigned By")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the user who created the assignment.';
                }
                field("Assigned Date"; Rec."Assigned Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date the assignment was created.';
                }
                field("No. of Assignment Lines"; Rec."No. of Assignment Lines")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of bin assignment lines.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Notes; Notes) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(processing)
        {
            action(NewAssignment)
            {
                Caption = 'New';
                ApplicationArea = Warehouse;
                Image = NewDocument;
                RunObject = Page "MIB Bin Assignment";
                RunPageMode = Create;
                ToolTip = 'Create a new bin assignment.';
            }
            action(Release)
            {
                Caption = 'Release';
                ApplicationArea = Warehouse;
                Image = ReleaseDoc;
                ToolTip = 'Confirm and release the selected bin assignment.';

                trigger OnAction()
                var
                    AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
                begin
                    AssignMgt.ReleaseAssignment(Rec."No.");
                    CurrPage.Update(false);
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel';
                ApplicationArea = Warehouse;
                Image = Cancel;
                ToolTip = 'Cancel and delete the selected bin assignment.';

                trigger OnAction()
                var
                    AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
                begin
                    if Confirm('Cancel assignment %1?', false, Rec."No.") then begin
                        AssignMgt.CancelAssignment(Rec."No.");
                        CurrPage.Update(false);
                    end;
                end;
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
