namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Inventory.Location;
using Microsoft.Foundation.NoSeries;

table 50205 "MIB Bin Assignment Setup"
{
    Caption = 'MIB Bin Assignment Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(2; "Assignment Nos."; Code[20])
        {
            Caption = 'Assignment Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series".Code;
        }
        field(3; "Auto-Assign on Release"; Boolean)
        {
            Caption = 'Auto-Assign on Release';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(4; "Conflict Resolution Mode"; Option)
        {
            Caption = 'Conflict Resolution Mode';
            DataClassification = CustomerContent;
            OptionMembers = Manual,"Priority",FEFD;
            OptionCaption = 'Manual,Priority,FEFD';
        }
        field(5; "Require Full Assignment"; Boolean)
        {
            Caption = 'Require Full Assignment';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(6; "Default Location Code"; Code[10])
        {
            Caption = 'Default Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
