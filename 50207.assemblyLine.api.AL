page 50207 "Assembly Line API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';

    EntityName = 'assemblyLine';
    EntitySetName = 'assemblyLines';

    SourceTable = "Assembly Line";
    ODataKeyFields = SystemId;
    DelayedInsert = true;


    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    Caption = 'Assembly Line API';

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

                field(type; Rec.Type)
                {
                    Caption = 'Type';

                }

                field(no; Rec."No.")
                {
                    Caption = 'No.';

                }

                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';

                }

                field(description; Rec.Description)
                {
                    Caption = 'Description';

                }

                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';

                }

                field(leadTimeOffset; Rec."Lead-Time Offset")
                {
                    Caption = 'Lead-Time Offset';

                }

                field(resourceUsageType; Rec."Resource Usage Type")
                {
                    Caption = 'Resource Usage Type';

                }

                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';

                }

                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';

                }

                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';

                }

                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }

                field(position; Rec.Position)
                {
                    Caption = 'Position';

                }

                field(position2; Rec."Position 2")
                {
                    Caption = 'Position 2';

                }

                field(position3; Rec."Position 3")
                {
                    Caption = 'Position 3';

                }

                field(applToItemEntry; Rec."Appl.-to Item Entry")
                {
                    Caption = 'Appl.-to Item Entry';

                }

                field(applFromItemEntry; Rec."Appl.-from Item Entry")
                {
                    Caption = 'Appl.-from Item Entry';

                }

                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';

                }

                field(quantityBase; Rec."Quantity (Base)")
                {
                    Caption = 'Quantity (Base)';

                }

                field(remainingQuantity; Rec."Remaining Quantity")
                {
                    Caption = 'Remaining Quantity';

                }

                field(remainingQuantityBase; Rec."Remaining Quantity (Base)")
                {
                    Caption = 'Remaining Quantity (Base)';

                }

                field(consumedQuantity; Rec."Consumed Quantity")
                {
                    Caption = 'Consumed Quantity';

                }

                field(consumedQuantityBase; Rec."Consumed Quantity (Base)")
                {
                    Caption = 'Consumed Quantity (Base)';

                }

                field(quantityToConsume; Rec."Quantity to Consume")
                {
                    Caption = 'Quantity to Consume';

                }

                field(quantityToConsumeBase; Rec."Quantity to Consume (Base)")
                {
                    Caption = 'Quantity to Consume (Base)';

                }

                field(availWarning; Rec."Avail. Warning")
                {
                    Caption = 'Avail. Warning';

                }

                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due Date';

                }

                field(reserve; Rec.Reserve)
                {
                    Caption = 'Reserve';

                }

                field(quantityPer; Rec."Quantity per")
                {
                    Caption = 'Quantity per';

                }

                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure")
                {
                    Caption = 'Qty. per Unit of Measure';

                }

                field(inventoryPostingGroup; Rec."Inventory Posting Group")
                {
                    Caption = 'Inventory Posting Group';

                }

                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group")
                {
                    Caption = 'Gen. Prod. Posting Group';

                }

                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group")
                {
                    Caption = 'Gen. Bus. Posting Group';

                }

                field(unitCost; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost';

                }

                field(costAmount; Rec."Cost Amount")
                {
                    Caption = 'Cost Amount';

                }

                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';

                }

                field(qtyRoundingPrecision; Rec."Qty. Rounding Precision")
                {
                    Caption = 'Qty. Rounding Precision';

                }

                field(qtyRoundingPrecisionBase; Rec."Qty. Rounding Precision (Base)")
                {
                    Caption = 'Qty. Rounding Precision (Base)';

                }

                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    Caption = 'Dimension Set ID';

                }

                field(qtyPicked; Rec."Qty. Picked")
                {
                    Caption = 'Qty. Picked';

                }

                field(qtyPickedBase; Rec."Qty. Picked (Base)")
                {
                    Caption = 'Qty. Picked (Base)';

                }

                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';

                }
            }
        }
    }

}
