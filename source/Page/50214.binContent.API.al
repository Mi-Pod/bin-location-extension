namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Item;

page 50214 "Bin Content API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';

    EntityName = 'binContent';
    EntitySetName = 'binContents';

    SourceTable = "Bin Content";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Caption = 'Bin Content API';

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

                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }

                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }

                field(itemInternalId; ItemInternalId)
                {
                    Caption = 'Item Internal Id';
                }

                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }

                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }

                field(quantityBase; Rec."Quantity (Base)")
                {
                    Caption = 'Quantity (Base)';
                }

                field(fixed; Rec.Fixed)
                {
                    Caption = 'Fixed';
                }

                field(defaultBin; Rec.Default)
                {
                    Caption = 'Default';
                }

                field(dedicated; Rec.Dedicated)
                {
                    Caption = 'Dedicated';
                }

                field(binRanking; Rec."Bin Ranking")
                {
                    Caption = 'Bin Ranking';
                }

                field(blockMovement; Rec."Block Movement")
                {
                    Caption = 'Block Movement';
                }

                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        Clear(ItemInternalId);
        if Item.Get(Rec."Item No.") then
            ItemInternalId := Item.SystemId;
    end;

    var
        ItemInternalId: Guid;
}
