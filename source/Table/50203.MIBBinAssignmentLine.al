namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 50203 "MIB Bin Assignment Line"
{
    Caption = 'MIB Bin Assignment Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Assignment No."; Code[20])
        {
            Caption = 'Assignment No.';
            DataClassification = CustomerContent;
            TableRelation = "MIB Bin Assignment Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; "Sales Line No."; Integer)
        {
            Caption = 'Sales Line No.';
            DataClassification = CustomerContent;
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }
        field(5; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(7; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            DataClassification = CustomerContent;
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(8; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = CustomerContent;
            TableRelation = "Bin Content"."Bin Code" where(
                "Location Code" = field("Location Code"),
                "Item No." = field("Item No."),
                "Variant Code" = field("Variant Code"));
        }
        field(9; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(11; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(12; Status; Enum "MIB Bin Assignment Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(13; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Assignment No.", "Line No.") { Clustered = true; }
        key(LocationBinItem; "Location Code", "Bin Code", "Item No.", "Variant Code") { SumIndexFields = Quantity; }
        key(SalesLineLookup; "Sales Order No.", "Sales Line No.", Status) { SumIndexFields = Quantity; }
    }
}
