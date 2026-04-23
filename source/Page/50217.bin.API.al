namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Warehouse.Structure;

page 50217 "Bin API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';

    EntityName = 'bin';
    EntitySetName = 'bins';

    SourceTable = Bin;
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Caption = 'Bin API';

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

                field(zoneCode; Rec."Zone Code")
                {
                    Caption = 'Zone Code';
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

                field(binRanking; Rec."Bin Ranking")
                {
                    Caption = 'Bin Ranking';
                }

                field(maximumCubage; Rec."Maximum Cubage")
                {
                    Caption = 'Maximum Cubage';
                }

                field(maximumWeight; Rec."Maximum Weight")
                {
                    Caption = 'Maximum Weight';
                }

                field(blockMovement; Rec."Block Movement")
                {
                    Caption = 'Block Movement';
                }

                field(crossDockBin; Rec."Cross-Dock Bin")
                {
                    Caption = 'Cross-Dock Bin';
                }

                field(empty; Rec.Empty)
                {
                    Caption = 'Empty';
                }

                field(dedicated; Rec.Dedicated)
                {
                    Caption = 'Dedicated';
                }

                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }
}
