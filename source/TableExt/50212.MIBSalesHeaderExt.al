namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Sales.Document;

tableextension 50212 "MIB Sales Header Ext" extends "Sales Header"
{
    fields
    {
        field(50201; "MIB Bin Assignment No."; Code[20])
        {
            Caption = 'MIB Bin Assignment No.';
            DataClassification = CustomerContent;
            TableRelation = "MIB Bin Assignment Header"."No.";
            Editable = false;
        }
        field(50202; "MIB Bin Assignment Status"; Enum "MIB Bin Assignment Status")
        {
            Caption = 'MIB Bin Assignment Status';
            DataClassification = CustomerContent;
        }
    }
}
