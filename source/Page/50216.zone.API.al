namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Warehouse.Structure;

page 50216 "Zone API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';

    EntityName = 'zone';
    EntitySetName = 'zones';

    SourceTable = Zone;
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Caption = 'Zone API';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }

                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }

                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }

                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }

                field(binTypeCode; Rec."Bin Type Code")
                {
                    Caption = 'Bin Type Code';
                }

                field(warehouseClassCode; Rec."Warehouse Class Code")
                {
                    Caption = 'Warehouse Class Code';
                }

                field(specialEquipmentCode; Rec."Special Equipment Code")
                {
                    Caption = 'Special Equipment Code';
                }

                field(zoneRanking; Rec."Zone Ranking")
                {
                    Caption = 'Zone Ranking';
                }

                field(crossDockBinZone; Rec."Cross-Dock Bin Zone")
                {
                    Caption = 'Cross-Dock Bin Zone';
                }

                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }
}
