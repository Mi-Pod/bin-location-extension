tableextension 50220 "WMS Whse. Activity Line" extends "Warehouse Activity Line"
{
    // Links inventory movement lines back to the internal movement line they were created from.
    // Stamped by "WMS Movement Events" (50221) when BC creates the movement. Field IDs and types
    // must stay identical to "WMS Reg. Invt. Movement Line" (50221) so the standard TransferFields
    // at registration carries them over.
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
            // Line No. of the internal movement line. Shared by the Take and its Place line.
            Caption = 'WMS Source Line No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

    // Finds the Place line that belongs to this Take line: the next Place line with the same
    // item/variant/UOM and the same "WMS Source Line No.". Movements created without the stamp
    // (e.g. manually in BC) fall back to the first matching Place line after the Take.
    procedure WmsFindPairedPlaceLine(var PlaceWarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    begin
        PlaceWarehouseActivityLine.Reset();
        PlaceWarehouseActivityLine.SetRange("Activity Type", Rec."Activity Type");
        PlaceWarehouseActivityLine.SetRange("No.", Rec."No.");
        PlaceWarehouseActivityLine.SetFilter("Line No.", '>%1', Rec."Line No.");
        PlaceWarehouseActivityLine.SetRange("Action Type", PlaceWarehouseActivityLine."Action Type"::Place);
        PlaceWarehouseActivityLine.SetRange("Item No.", Rec."Item No.");
        PlaceWarehouseActivityLine.SetRange("Variant Code", Rec."Variant Code");
        PlaceWarehouseActivityLine.SetRange("Unit of Measure Code", Rec."Unit of Measure Code");
        if Rec."WMS Source Line No." <> 0 then
            PlaceWarehouseActivityLine.SetRange("WMS Source Line No.", Rec."WMS Source Line No.");
        exit(PlaceWarehouseActivityLine.FindFirst());
    end;
}
