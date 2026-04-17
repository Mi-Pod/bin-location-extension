namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Warehouse.Structure;

page 50241 "MIB Bin Assignment Lines"
{
    PageType = ListPart;
    SourceTable = "MIB Bin Assignment Line";
    Caption = 'MIB Bin Assignment Lines';
    AutoSplitKey = true;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field("Sales Line No."; Rec."Sales Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the sales line this assignment covers.';
                    Editable = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item number.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the location code.';
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin code. Lookup filters by location and item.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BinContent: Record "Bin Content";
                        BinContentList: Page "Bin Contents List";
                    begin
                        BinContent.SetRange("Location Code", Rec."Location Code");
                        BinContent.SetRange("Item No.", Rec."Item No.");
                        BinContentList.SetTableView(BinContent);
                        BinContentList.LookupMode(true);
                        if BinContentList.RunModal() = Action::LookupOK then begin
                            BinContentList.GetRecord(BinContent);
                            Rec."Bin Code" := BinContent."Bin Code";
                            Text := BinContent."Bin Code";
                            exit(true);
                        end;
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity assigned to this bin for this sales line.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the availability status for this line.';
                    StyleExpr = StatusStyleExpr;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ValidateAvailability)
            {
                Caption = 'Validate Availability';
                ApplicationArea = Warehouse;
                Image = CheckRemainingQuantity;
                ToolTip = 'Check bin availability and update the status for the selected line.';

                trigger OnAction()
                var
                    AssignMgt: Codeunit "MIB Bin Assignment Mgt.";
                begin
                    AssignMgt.ValidateAvailability(Rec);
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
            else
                StatusStyleExpr := 'Standard';
        end;
    end;
}
