tableextension 50213 "Item Total Bins Ext" extends Item
{
    fields
    {
        field(50213; "Total Available Bins"; Integer)
        {
            Caption = 'Total Available Bins';
            FieldClass = FlowField;
            CalcFormula = Count("Bin Content" where("Item No." = field("No.")));
            Editable = false;
        }
    }
}