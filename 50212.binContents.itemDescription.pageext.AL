pageextension 50212 "Bin Contents Item Description" extends "Bin Contents"
{
    layout
    {
        addafter("Item No.")
        {
            field(ItemDescriptionExt; ItemDescriptionTxt)
            {
                ApplicationArea = All;
                Caption = 'Item Description';
                Editable = false;
                ToolTip = 'Specifies the description from the related item card.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ItemDescriptionTxt := GetItemDescription();
    end;

    local procedure GetItemDescription(): Text[100]
    begin
        if (Rec."Item No." = '') or (not Item.Get(Rec."Item No.")) then
            exit('');

        exit(Item.Description);
    end;

    var
        Item: Record Item;
        ItemDescriptionTxt: Text[100];
}