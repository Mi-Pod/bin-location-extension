namespace MiOneBrands.WarehouseBinAssignment;

page 50244 "MIB Bin Allocation Rules"
{
    PageType = List;
    SourceTable = "MIB Bin Allocation Rule";
    Caption = 'MIB Bin Allocation Rules';
    ApplicationArea = Warehouse;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(List)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unique rule code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the rule.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the rule priority. Lower number = higher priority in auto-suggest.';
                }
                field("Location Filter"; Rec."Location Filter")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies which location this rule applies to. Leave blank to apply to all locations.';
                }
                field("Item Category Filter"; Rec."Item Category Filter")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies which item category this rule applies to. Leave blank to apply to all item categories.';
                }
                field("Bin Type Filter"; Rec."Bin Type Filter")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies which bin type this rule applies to. Leave blank to apply to all bin types.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether this rule is active.';
                }
            }
        }
    }
}
