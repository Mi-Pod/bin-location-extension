page 50222 "WMS Activity Line API"
{
    // Open warehouse activity lines (Take/Place pairs), used to reconcile movements.
    // Lines created by the movements API carry wmsInternalMovementNo and wmsSourceLineNo:
    //   GET .../warehouseActivityLines?$filter=activityType eq 'Invt. Movement' and activityNo eq '{no}'
    // Inventory put-away lines carry the purchase order in sourceNo / sourceLineNo:
    //   GET .../warehouseActivityLines?$filter=activityType eq 'Invt. Put-away' and sourceNo eq '{purchase order no.}'
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'warehouseActivityLine';
    EntitySetName = 'warehouseActivityLines';
    SourceTable = "Warehouse Activity Line";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Activity Line API';

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
                field(activityType; Rec."Activity Type")
                {
                    Caption = 'Activity Type';
                }
                field(activityNo; Rec."No.")
                {
                    Caption = 'Activity No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(actionType; Rec."Action Type")
                {
                    Caption = 'Action Type';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
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
                field(quantityBase; Rec."Qty. (Base)")
                {
                    Caption = 'Quantity (Base)';
                }
                field(qtyToHandle; Rec."Qty. to Handle")
                {
                    Caption = 'Qty. to Handle';
                }
                field(qtyToHandleBase; Rec."Qty. to Handle (Base)")
                {
                    Caption = 'Qty. to Handle (Base)';
                }
                field(qtyOutstanding; Rec."Qty. Outstanding")
                {
                    Caption = 'Qty. Outstanding';
                }
                field(qtyOutstandingBase; Rec."Qty. Outstanding (Base)")
                {
                    Caption = 'Qty. Outstanding (Base)';
                }
                field(qtyHandled; Rec."Qty. Handled")
                {
                    Caption = 'Qty. Handled';
                }
                field(qtyHandledBase; Rec."Qty. Handled (Base)")
                {
                    Caption = 'Qty. Handled (Base)';
                }
                field(sourceType; Rec."Source Type")
                {
                    Caption = 'Source Type';
                }
                field(sourceSubtype; Rec."Source Subtype")
                {
                    Caption = 'Source Subtype';
                }
                field(sourceNo; Rec."Source No.")
                {
                    Caption = 'Source No.';
                }
                field(sourceLineNo; Rec."Source Line No.")
                {
                    Caption = 'Source Line No.';
                }
                field(sourceDocument; Rec."Source Document")
                {
                    Caption = 'Source Document';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due Date';
                }
                field(wmsInternalMovementNo; Rec."WMS Internal Movement No.")
                {
                    Caption = 'WMS Internal Movement No.';
                }
                field(wmsSourceLineNo; Rec."WMS Source Line No.")
                {
                    Caption = 'WMS Source Line No.';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }
}
