namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Inventory.Item;

pageextension 50233 "MIB Item Card Ext" extends "Item Card"
{
    layout
    {
        addlast(Warehouse)
        {
            field("MIB Allocation Rule"; MIBAllocationRuleCode)
            {
                ApplicationArea = Warehouse;
                Caption = 'MIB Allocation Rule';
                TableRelation = "MIB Bin Allocation Rule".Code;
                ToolTip = 'Specifies the bin allocation rule applied when auto-suggesting bins for this item.';

                trigger OnValidate()
                begin
                    UpdateItemAllocationRule(Rec."No.", MIBAllocationRuleCode);
                end;
            }
        }
    }

    var
        MIBAllocationRuleCode: Code[20];

    trigger OnAfterGetRecord()
    begin
        MIBAllocationRuleCode := GetItemAllocationRule(Rec."No.");
    end;

    local procedure GetItemAllocationRule(ItemNo: Code[20]): Code[20]
    var
        AllocationRule: Record "MIB Bin Allocation Rule";
    begin
        AllocationRule.SetRange("Item Category Filter", Rec."Item Category Code");
        AllocationRule.SetRange(Enabled, true);
        AllocationRule.SetCurrentKey(Priority);
        if AllocationRule.FindFirst() then
            exit(AllocationRule.Code);
        exit('');
    end;

    local procedure UpdateItemAllocationRule(ItemNo: Code[20]; RuleCode: Code[20])
    begin
        // Placeholder: item-level rule association can be stored via
        // a dedicated item table extension field if required in a future iteration.
    end;
}
