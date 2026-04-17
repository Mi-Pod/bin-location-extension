namespace MiOneBrands.WarehouseBinAssignment;

page 50243 "MIB Bin Assignment Setup"
{
    PageType = Card;
    SourceTable = "MIB Bin Assignment Setup";
    Caption = 'MIB Bin Assignment Setup';
    ApplicationArea = Warehouse;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Assignment Nos."; Rec."Assignment Nos.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series used to auto-number bin assignments.';
                }
                field("Default Location Code"; Rec."Default Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the default location used when filtering bin suggestions.';
                }
            }
            group(Automation)
            {
                Caption = 'Automation';
                field("Auto-Assign on Release"; Rec."Auto-Assign on Release")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'When enabled, bins are automatically suggested and assigned when a sales order is released.';
                }
                field("Require Full Assignment"; Rec."Require Full Assignment")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'When enabled, releasing a sales order is blocked if any line still has a bin conflict.';
                }
                field("Conflict Resolution Mode"; Rec."Conflict Resolution Mode")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how competing bin assignments are resolved: Manual, Priority (by rule), or FEFD (first-expired, first-delivered).';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
