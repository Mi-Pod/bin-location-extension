page 50220 "WMS Movement API"
{
    // Command endpoint: creates an Internal Movement and turns it into an Inventory Movement.
    //
    // Usage:
    //   POST /api/mioneBrands/warehouse/v1.0/companies({id})/movements
    //   {
    //     "externalRequestKey": "repl-2026-11-02-0001",
    //     "createdBy": "jdoe",
    //     "locationCode": "MAIN",
    //     "linesJson": "[{\"itemNo\":\"1000\",\"variantCode\":\"\",\"fromBinCode\":\"BULK-01\",\"toBinCode\":\"FP-14-25\",\"quantityBase\":24}]"
    //   }
    //
    // Quantities are in base units. The whole request fails if any source bin is short.
    // The response carries internalMovementNo, activityNo and responseJson, which lists the
    // created Take/Place line nos. per request line. Retrying with the same key replays it.
    // The record is never persisted - the table is Temporary.

    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'movement';
    EntitySetName = 'movements';
    SourceTable = "WMS Movement Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = "Request Id";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Movement API';

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
                field(linesJson; LinesJson)
                {
                    Caption = 'Lines JSON';
                }
                field(internalMovementNo; Rec."Internal Movement No.")
                {
                    Caption = 'Internal Movement No.';
                }
                field(activityNo; Rec."Activity No.")
                {
                    Caption = 'Activity No.';
                }
                field(responseJson; ResponseJson)
                {
                    Caption = 'Response JSON';
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                }
            }
        }
    }

    var
        LinesJson: Text;
        ResponseJson: Text;

    trigger OnAfterGetRecord()
    begin
        LinesJson := Rec.GetLinesJson();
        ResponseJson := Rec.GetResponseJson();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        WmsMovementManagement: Codeunit "WMS Movement Management";
    begin
        Rec."Request Id" := CreateGuid();
        Rec.SetLinesJson(LinesJson);
        WmsMovementManagement.CreateMovement(Rec);
        ResponseJson := Rec.GetResponseJson();
        exit(true);
    end;
}
