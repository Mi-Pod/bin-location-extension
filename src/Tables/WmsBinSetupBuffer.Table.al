table 50222 "WMS Bin Setup Buffer"
{
    // Temporary table backing the binSetups command API page (50224).
    // Nothing persists here - the request is recorded in "WMS Document Request" (50216) instead.
    TableType = Temporary;
    Caption = 'WMS Bin Setup Buffer';

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
        field(6; "Template Bin Code"; Code[20])
        {
            // Required only when the bin does not exist yet. The new bin copies its settings from it.
            Caption = 'Template Bin Code';
            DataClassification = CustomerContent;
        }
        field(7; Description; Text[100])
        {
            // Optional. Used only when the bin is created.
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(8; "Item No."; Code[20])
        {
            // Optional. Blank = only make sure the bin exists.
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(9; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            // Optional. Defaults to the item's base unit of measure.
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
        }
        field(11; "Fixed"; Boolean)
        {
            Caption = 'Fixed';
            InitValue = true;
            DataClassification = CustomerContent;
        }
        field(12; Default; Boolean)
        {
            Caption = 'Default';
            DataClassification = CustomerContent;
        }
        field(13; "Replace Default"; Boolean)
        {
            // Set to move the item's Default from another bin to this one instead of failing.
            Caption = 'Replace Default';
            DataClassification = CustomerContent;
        }
        field(14; "Allow Other Fixed Item"; Boolean)
        {
            // Set to allow the bin to be Fixed to more than one item or variant.
            Caption = 'Allow Other Fixed Item';
            DataClassification = CustomerContent;
        }
        field(20; "Bin Id"; Guid)
        {
            Caption = 'Bin Id';
            DataClassification = SystemMetadata;
        }
        field(21; "Bin Created"; Boolean)
        {
            Caption = 'Bin Created';
            DataClassification = SystemMetadata;
        }
        field(22; "Bin Content Id"; Guid)
        {
            Caption = 'Bin Content Id';
            DataClassification = SystemMetadata;
        }
        field(23; "Bin Content Created"; Boolean)
        {
            Caption = 'Bin Content Created';
            DataClassification = SystemMetadata;
        }
        field(24; "Default Moved From Bin Code"; Code[20])
        {
            Caption = 'Default Moved From Bin Code';
            DataClassification = CustomerContent;
        }
        field(25; "Last Modified At"; DateTime)
        {
            Caption = 'Last Modified At';
            DataClassification = SystemMetadata;
        }
        field(26; Result; Text[250])
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
