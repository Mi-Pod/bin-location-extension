page 50219 "WMS Bin Level API"
{
    // Command endpoint that sets Min. Qty./Max. Qty. on a Bin Content (#7).
    //
    // Usage:
    //   POST /api/mioneBrands/warehouse/v1.0/companies({id})/binLevels
    //   { "externalRequestKey": "...", "locationCode": "MAIN", "binCode": "FP-14-25",
    //     "itemNo": "1000", "minQty": 5, "maxQty": 20 }
    //
    // Optional: createdBy, variantCode, unitOfMeasureCode (defaults to the item's base UOM),
    // fixed (defaults to true), allowOtherFixedItem (defaults to false).
    // minQty and maxQty are whole numbers of the unit of measure; fractions are refused (#10).
    // Send minQty 0 and maxQty 0 to clear the rule. Read the result back through binContents.
    //
    // The POST fires OnInsertRecord, which calls "WMS Bin Level Management" (50217). The table is
    // Temporary; the request itself is recorded in wmsDocumentRequests.

    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'binLevel';
    EntitySetName = 'binLevels';
    SourceTable = "WMS Bin Level Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = "Request Id";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Bin Level API';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec."Request Id")
                {
                    Caption = 'Id';
                }
                field(externalRequestKey; Rec."External Request Key")
                {
                    Caption = 'External Request Key';
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
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
                field(minQty; Rec."Min. Qty.")
                {
                    Caption = 'Min. Qty.';
                }
                field(maxQty; Rec."Max. Qty.")
                {
                    Caption = 'Max. Qty.';
                }
                field(fixed; Rec.Fixed)
                {
                    Caption = 'Fixed';
                }
                field(allowOtherFixedItem; Rec."Allow Other Fixed Item")
                {
                    Caption = 'Allow Other Fixed Item';
                }
                field(binContentId; Rec."Bin Content Id")
                {
                    Caption = 'Bin Content Id';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec."Last Modified At")
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        WmsBinLevelManagement: Codeunit "WMS Bin Level Management";
    begin
        Rec."Request Id" := CreateGuid();
        WmsBinLevelManagement.SetBinLevels(Rec);

        // Return true so the framework returns the buffer with its result fields filled in.
        exit(true);
    end;
}
