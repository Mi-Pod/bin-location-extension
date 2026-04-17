namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Sales.Document;
using Microsoft.Inventory.Item;

page 50218 "Sales Line Bin API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';

    EntityName = 'salesLineBin';
    EntitySetName = 'salesLineBins';

    SourceTable = "Sales Line";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Caption = 'Sales Line Bin API';

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

                field(documentType; Rec."Document Type")
                {
                    Caption = 'Document Type';
                }

                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }

                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }

                field(itemNo; Rec."No.")
                {
                    Caption = 'Item No.';
                }

                field(itemInternalId; ItemInternalId)
                {
                    Caption = 'Item Internal Id';
                }

                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }

                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }

                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }

                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }

                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }

                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }

                field(quantityBase; Rec."Quantity (Base)")
                {
                    Caption = 'Quantity (Base)';
                }

                field(outstandingQuantity; Rec."Outstanding Quantity")
                {
                    Caption = 'Outstanding Quantity';
                }

                field(shipmentDate; Rec."Shipment Date")
                {
                    Caption = 'Shipment Date';
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
        if Rec."No." <> '' then
            if Item.Get(Rec."No.") then
                ItemInternalId := Item.SystemId;
    end;

    var
        ItemInternalId: Guid;
}
