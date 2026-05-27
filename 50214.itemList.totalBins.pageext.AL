pageextension 50214 "Item List Total Bins Ext" extends "Item List"
{
    layout
    {
        addafter(Description)
        {
            field("Total Available Bins"; Rec."Total Available Bins")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies how many bin content records currently exist for this item. Drill down to open Bin Contents filtered by item number.';

                trigger OnDrillDown()
                var
                    BinContent: Record "Bin Content";
                begin
                    BinContent.SetRange("Item No.", Rec."No.");
                    Page.Run(Page::"Bin Contents", BinContent);
                end;
            }
        }
    }
}