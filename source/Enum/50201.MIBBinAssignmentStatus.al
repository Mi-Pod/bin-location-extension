namespace MiOneBrands.WarehouseBinAssignment;

enum 50201 "MIB Bin Assignment Status"
{
    Extensible = true;

    value(0; Open) { Caption = 'Open'; }
    value(1; Assigned) { Caption = 'Assigned'; }
    value(2; Partial) { Caption = 'Partial'; }
    value(3; Conflict) { Caption = 'Conflict'; }
    value(4; Confirmed) { Caption = 'Confirmed'; }
}
