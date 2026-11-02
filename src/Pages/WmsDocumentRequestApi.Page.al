page 50218 "WMS Document Request API"
{
    // Read-only view of processed WMS command requests (table 50216).
    // After a timeout the app can look up its request to see whether it was processed:
    //   GET .../wmsDocumentRequests?$filter=externalRequestKey eq '{key}'
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'wmsDocumentRequest';
    EntitySetName = 'wmsDocumentRequests';
    SourceTable = "WMS Document Request";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Document Request API';

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
                field(externalRequestKey; Rec."External Request Key")
                {
                    Caption = 'External Request Key';
                }
                field(workflowType; Rec."Workflow Type")
                {
                    Caption = 'Workflow Type';
                }
                field(payloadHash; Rec."Payload Hash")
                {
                    Caption = 'Payload Hash';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(activityNo; Rec."Activity No.")
                {
                    Caption = 'Activity No.';
                }
                field(targetId; Rec."Target Id")
                {
                    Caption = 'Target Id';
                }
                field(responseJson; ResponseJson)
                {
                    Caption = 'Response JSON';
                }
                field(createdDateTime; Rec.SystemCreatedAt)
                {
                    Caption = 'Created Date Time';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }

    var
        ResponseJson: Text;

    trigger OnAfterGetRecord()
    begin
        ResponseJson := Rec.GetResponse();
    end;
}
