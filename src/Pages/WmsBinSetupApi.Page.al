page 50224 "WMS Bin Setup API"
{
    // Command endpoint that creates a missing bin and/or assigns an item to a bin (#4).
    //
    // Usage:
    //   POST /api/mioneBrands/warehouse/v1.0/companies({id})/binSetups
    //   { "externalRequestKey": "...", "locationCode": "MAIN", "binCode": "FP-14-26",
    //     "templateBinCode": "FP-14-25", "itemNo": "1000", "default": true }
    //
    // Optional: createdBy, templateBinCode (required only when the bin does not exist yet),
    // description (new bins only), itemNo (blank = only make sure the bin exists), variantCode,
    // unitOfMeasureCode (defaults to the item's base UOM), fixed (defaults to true), default
    // (defaults to false), replaceDefault (defaults to false), allowOtherFixedItem (defaults to false).
    //
    // The POST fires OnInsertRecord, which calls "WMS Bin Setup Management" (50222). The table is
    // Temporary; the request itself is recorded in wmsDocumentRequests.

    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'binSetup';
    EntitySetName = 'binSetups';
    SourceTable = "WMS Bin Setup Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = "Request Id";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Bin Setup API';

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
                field(templateBinCode; Rec."Template Bin Code")
                {
                    Caption = 'Template Bin Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
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
                field(fixed; Rec.Fixed)
                {
                    Caption = 'Fixed';
                }
                field(default; Rec.Default)
                {
                    Caption = 'Default';
                }
                field(replaceDefault; Rec."Replace Default")
                {
                    Caption = 'Replace Default';
                }
                field(allowOtherFixedItem; Rec."Allow Other Fixed Item")
                {
                    Caption = 'Allow Other Fixed Item';
                }
                field(binId; Rec."Bin Id")
                {
                    Caption = 'Bin Id';
                    Editable = false;
                }
                field(binCreated; Rec."Bin Created")
                {
                    Caption = 'Bin Created';
                    Editable = false;
                }
                field(binContentId; Rec."Bin Content Id")
                {
                    Caption = 'Bin Content Id';
                    Editable = false;
                }
                field(binContentCreated; Rec."Bin Content Created")
                {
                    Caption = 'Bin Content Created';
                    Editable = false;
                }
                field(defaultMovedFromBinCode; Rec."Default Moved From Bin Code")
                {
                    Caption = 'Default Moved From Bin Code';
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
        WmsBinSetupManagement: Codeunit "WMS Bin Setup Management";
    begin
        Rec."Request Id" := CreateGuid();
        WmsBinSetupManagement.SetupBin(Rec);

        // Return true so the framework returns the buffer with its result fields filled in.
        exit(true);
    end;
}
