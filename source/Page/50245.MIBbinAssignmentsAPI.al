namespace MiOneBrands.WarehouseBinAssignment;

page 50245 "MIB binAssignments API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v2.0';

    EntityName = 'binAssignment';
    EntitySetName = 'binAssignments';

    SourceTable = "MIB Bin Assignment Header";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Caption = 'MIB Bin Assignments API';

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
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(salesOrderNo; Rec."Sales Order No.")
                {
                    Caption = 'Sales Order No.';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(assignedBy; Rec."Assigned By")
                {
                    Caption = 'Assigned By';
                }
                field(assignedDate; Rec."Assigned Date")
                {
                    Caption = 'Assigned Date';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(noOfAssignmentLines; Rec."No. of Assignment Lines")
                {
                    Caption = 'No. of Assignment Lines';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }
}
