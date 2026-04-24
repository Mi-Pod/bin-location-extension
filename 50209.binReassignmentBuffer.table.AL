table 50209 "Bin Reassignment Buffer"
{
    // Temporary table backing the binReassignments command API page (50210).
    // Nothing persists - records exist only for the duration of a single POST request.
    TableType = Temporary;
    Caption = 'Bin Reassignment Buffer';

    fields
    {
        field(1; "Request Id"; Guid)
        {
            Caption = 'Request Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Target Type"; Enum "Bin Reassignment Target Type")
        {
            Caption = 'Target Type';
            DataClassification = CustomerContent;
        }
        field(3; "Assembly Line Id"; Guid)
        {
            Caption = 'Assembly Line Id';
            DataClassification = CustomerContent;
        }
        field(4; "Sales Line Id"; Guid)
        {
            Caption = 'Sales Line Id';
            DataClassification = CustomerContent;
        }
        field(5; "New Bin Code"; Code[20])
        {
            Caption = 'New Bin Code';
            DataClassification = CustomerContent;
        }
        field(6; Result; Text[250])
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
