namespace MiOneBrands.WarehouseBinAssignment;

page 50240 "MIB Bin Assignment"
{
    PageType = Document;
    SourceTable = "MIB Bin Assignment Header";
    Caption = 'MIB Bin Assignment';
    SourceTableView = where(Status = filter(<> Confirmed));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin assignment number.';
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
                    ToolTip = 'Specifies the overall assignment status.';
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
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies an optional note for this assignment.';
                }
            }
            part(Lines; "MIB Bin Assignment Lines")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Assignment No." = field("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Release)
            {
                Caption = 'Release';
                ApplicationArea = Warehouse;
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Confirm and release the bin assignment.';

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
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Cancel and delete the bin assignment.';

                trigger OnAction()
                var
                    AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
                begin
                    if Confirm('Cancel assignment %1? This will delete all assignment lines.', false, Rec."No.") then begin
                        AssignMgt.CancelAssignment(Rec."No.");
                        CurrPage.Close();
                    end;
                end;
            }
            action(UpdateStatus)
            {
                Caption = 'Refresh Status';
                ApplicationArea = Warehouse;
                Image = Refresh;
                ToolTip = 'Recalculate the assignment status from its lines.';

                trigger OnAction()
                var
                    AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
                begin
                    AssignMgt.UpdateStatus(Rec."No.");
                    CurrPage.Update(false);
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
