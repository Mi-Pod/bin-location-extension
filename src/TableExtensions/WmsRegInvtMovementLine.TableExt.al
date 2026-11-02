tableextension 50221 "WMS Reg. Invt. Movement Line" extends "Registered Invt. Movement Line"
{
    // Same field IDs and types as "WMS Whse. Activity Line" (50220). BC registers inventory
    // movements with TransferFields from the activity line, so the values copy over with no code.
    fields
    {
        field(50220; "WMS Internal Movement No."; Code[20])
        {
            Caption = 'WMS Internal Movement No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(50221; "WMS Source Line No."; Integer)
        {
            Caption = 'WMS Source Line No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}
