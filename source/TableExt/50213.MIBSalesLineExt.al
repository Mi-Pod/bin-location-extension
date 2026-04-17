namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Sales.Document;

tableextension 50213 "MIB Sales Line Ext" extends "Sales Line"
{
    fields
    {
        field(50201; "MIB Bin Assignment Status"; Enum "MIB Bin Assignment Status")
        {
            Caption = 'MIB Bin Assignment Status';
            DataClassification = CustomerContent;
        }
        field(50202; "MIB Qty Bin Assigned"; Decimal)
        {
            Caption = 'MIB Qty Bin Assigned';
            FieldClass = FlowField;
            CalcFormula = sum("MIB Bin Assignment Line".Quantity
                where("Sales Order No." = field("Document No."),
                      "Sales Line No." = field("Line No."),
                      Status = filter(Assigned | Confirmed)));
            Editable = false;
        }
    }
}
