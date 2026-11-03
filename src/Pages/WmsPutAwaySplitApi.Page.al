page 50225 "WMS Put-away Split API"
{
    // Command endpoint: spreads one open Place line of an Inventory Put-away (from a purchase
    // order) over one or more destination bins.
    //
    // Usage:
    //   POST /api/mioneBrands/warehouse/v1.0/companies({id})/putAwaySplits
    //   {
    //     "externalRequestKey": "pa-2026-11-02-0001",
    //     "createdBy": "jdoe",
    //     "activityNo": "IPA000034",
    //     "lineNo": 10000,
    //     "allocationsJson": "[{\"binCode\":\"FP-14-25\",\"quantityBase\":12},{\"binCode\":\"BULK-01\",\"quantityBase\":36}]",
    //     "expectedLastModifiedDateTime": "2026-11-02T17:05:00Z"
    //   }
    //
    // The quantities must add up to the line's Qty. Outstanding (Base) and each must be a whole
    // number of the line's unit of measure. expectedLastModifiedDateTime is optional.
    // Managers create and post the inventory put-aways in BC; nothing is posted here.
    // The record is never persisted - the table is Temporary.

    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'putAwaySplit';
    EntitySetName = 'putAwaySplits';
    SourceTable = "WMS Put-away Split Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = "Request Id";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Put-away Split API';

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
                field(activityNo; Rec."Activity No.")
                {
                    Caption = 'Activity No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(allocationsJson; AllocationsJson)
                {
                    Caption = 'Allocations JSON';
                }
                field(expectedLastModifiedDateTime; Rec."Expected Last Modified At")
                {
                    Caption = 'Expected Last Modified Date Time';
                }
                field(sourceNo; Rec."Source No.")
                {
                    Caption = 'Source No.';
                }
                field(sourceLineNo; Rec."Source Line No.")
                {
                    Caption = 'Source Line No.';
                }
                field(responseJson; ResponseJson)
                {
                    Caption = 'Response JSON';
                }
                field(lastModifiedDateTime; Rec."Last Modified At")
                {
                    Caption = 'Last Modified Date Time';
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                }
            }
        }
    }

    var
        AllocationsJson: Text;
        ResponseJson: Text;

    trigger OnAfterGetRecord()
    begin
        AllocationsJson := Rec.GetAllocationsJson();
        ResponseJson := Rec.GetResponseJson();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        WmsPutAwayManagement: Codeunit "WMS Put-away Management";
    begin
        Rec."Request Id" := CreateGuid();
        Rec.SetAllocationsJson(AllocationsJson);
        WmsPutAwayManagement.SplitPutAwayLine(Rec);
        ResponseJson := Rec.GetResponseJson();
        exit(true);
    end;
}
