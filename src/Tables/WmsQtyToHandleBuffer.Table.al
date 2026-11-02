table 50221 "WMS Qty. to Handle Buffer"
{
    // Temporary table backing the qtyToHandles command API page (50221).
    // Nothing persists - records exist only for the duration of a single POST request.
    TableType = Temporary;
    Caption = 'WMS Qty. to Handle Buffer';

    fields
    {
        field(1; "Request Id"; Guid)
        {
            Caption = 'Request Id';
            DataClassification = SystemMetadata;
        }
        field(2; "External Request Key"; Text[100])
        {
            Caption = 'External Request Key';
            DataClassification = SystemMetadata;
        }
        field(3; "Created By"; Text[100])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Activity No."; Code[20])
        {
            // Inventory Movement no.
            Caption = 'Activity No.';
            DataClassification = CustomerContent;
        }
        field(5; "Take Line No."; Integer)
        {
            Caption = 'Take Line No.';
            DataClassification = CustomerContent;
        }
        field(6; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }
        field(7; "Expected Last Modified At"; DateTime)
        {
            // Optional. When set, the request fails if either line was changed in BC after this time.
            Caption = 'Expected Last Modified At';
            DataClassification = SystemMetadata;
        }
        field(10; "Place Line No."; Integer)
        {
            Caption = 'Place Line No.';
            DataClassification = CustomerContent;
        }
        field(11; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }
        field(12; "Qty. Handled (Base)"; Decimal)
        {
            Caption = 'Qty. Handled (Base)';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }
        field(13; "Last Modified At"; DateTime)
        {
            // Newest SystemModifiedAt of the Take and Place lines.
            Caption = 'Last Modified At';
            DataClassification = SystemMetadata;
        }
        field(14; Result; Text[250])
        {
            Caption = 'Result';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Request Id")
        {
            Clustered = true;
        }
    }
}
