table 50217 "WMS Bin Level Buffer"
{
    // Temporary table backing the binLevels command API page (50219).
    // Nothing persists here - the request is recorded in "WMS Document Request" (50216) instead.
    TableType = Temporary;
    Caption = 'WMS Bin Level Buffer';

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
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
        }
        field(5; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = CustomerContent;
        }
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(7; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(8; "Unit of Measure Code"; Code[10])
        {
            // Optional. Defaults to the item's base unit of measure.
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
        }
        field(9; "Min. Qty."; Decimal)
        {
            Caption = 'Min. Qty.';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }
        field(10; "Max. Qty."; Decimal)
        {
            Caption = 'Max. Qty.';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }
        field(11; "Fixed"; Boolean)
        {
            Caption = 'Fixed';
            InitValue = true;
            DataClassification = CustomerContent;
        }
        field(12; "Allow Other Fixed Item"; Boolean)
        {
            // Set to allow the bin to be Fixed to more than one item or variant.
            Caption = 'Allow Other Fixed Item';
            DataClassification = CustomerContent;
        }
        field(20; "Bin Content Id"; Guid)
        {
            Caption = 'Bin Content Id';
            DataClassification = SystemMetadata;
        }
        field(21; "Last Modified At"; DateTime)
        {
            Caption = 'Last Modified At';
            DataClassification = SystemMetadata;
        }
        field(22; Result; Text[250])
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
