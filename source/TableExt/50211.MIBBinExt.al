namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Warehouse.Structure;

tableextension 50211 "MIB Bin Ext" extends Bin
{
    fields
    {
        field(50201; "MIB Allocation Priority"; Integer)
        {
            Caption = 'MIB Allocation Priority';
            DataClassification = CustomerContent;
            InitValue = 0;
        }
    }
}
