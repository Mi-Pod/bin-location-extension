namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Warehouse.Structure;

tableextension 50210 "MIB Bin Content Ext" extends "Bin Content"
{
    fields
    {
        field(50201; "MIB Assignment Qty"; Decimal)
        {
            Caption = 'MIB Assignment Qty';
            FieldClass = FlowField;
            CalcFormula = sum("MIB Bin Assignment Line".Quantity
                where("Location Code" = field("Location Code"),
                      "Bin Code" = field("Bin Code"),
                      "Item No." = field("Item No."),
                      "Variant Code" = field("Variant Code"),
                      Status = filter(Assigned | Confirmed)));
            Editable = false;
        }
        field(50202; "MIB Bin Assignment Status"; Enum "MIB Bin Assignment Status")
        {
            Caption = 'MIB Bin Assignment Status';
            DataClassification = CustomerContent;
        }
    }
}
