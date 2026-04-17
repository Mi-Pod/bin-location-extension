namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Structure;

table 50204 "MIB Bin Allocation Rule"
{
    Caption = 'MIB Bin Allocation Rule';
    DataClassification = CustomerContent;
    LookupPageId = "MIB Bin Allocation Rules";
    DrillDownPageId = "MIB Bin Allocation Rules";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = CustomerContent;
        }
        field(4; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(5; "Item Category Filter"; Code[20])
        {
            Caption = 'Item Category Filter';
            DataClassification = CustomerContent;
            TableRelation = "Item Category".Code;
        }
        field(6; "Bin Type Filter"; Code[10])
        {
            Caption = 'Bin Type Filter';
            DataClassification = CustomerContent;
            TableRelation = "Bin Type".Code;
        }
        field(7; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(Priority; Priority) { }
    }
}
