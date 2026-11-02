page 50221 "WMS Qty. to Handle API"
{
    // Command endpoint: sets Qty. to Handle on an inventory movement Take line and its Place line.
    //
    // Usage:
    //   POST /api/mioneBrands/warehouse/v1.0/companies({id})/qtyToHandles
    //   {
    //     "externalRequestKey": "qth-2026-11-02-0001",
    //     "createdBy": "jdoe",
    //     "activityNo": "IM000012",
    //     "takeLineNo": 10000,
    //     "qtyToHandleBase": 12,
    //     "expectedLastModifiedDateTime": "2026-11-02T17:05:00Z"
    //   }
    //
    // expectedLastModifiedDateTime is optional; when sent, the request fails if either line was
    // changed in BC after it. The movement is never registered here.
    // The record is never persisted - the table is Temporary.

    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'qtyToHandle';
    EntitySetName = 'qtyToHandles';
    SourceTable = "WMS Qty. to Handle Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = "Request Id";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Qty. to Handle API';

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
                field(takeLineNo; Rec."Take Line No.")
                {
                    Caption = 'Take Line No.';
                }
                field(qtyToHandleBase; Rec."Qty. to Handle (Base)")
                {
                    Caption = 'Qty. to Handle (Base)';
                }
                field(expectedLastModifiedDateTime; Rec."Expected Last Modified At")
                {
                    Caption = 'Expected Last Modified Date Time';
                }
                field(placeLineNo; Rec."Place Line No.")
                {
                    Caption = 'Place Line No.';
                }
                field(qtyOutstandingBase; Rec."Qty. Outstanding (Base)")
                {
                    Caption = 'Qty. Outstanding (Base)';
                }
                field(qtyHandledBase; Rec."Qty. Handled (Base)")
                {
                    Caption = 'Qty. Handled (Base)';
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        WmsMovementManagement: Codeunit "WMS Movement Management";
    begin
        Rec."Request Id" := CreateGuid();
        WmsMovementManagement.SetQtyToHandle(Rec);
        exit(true);
    end;
}
