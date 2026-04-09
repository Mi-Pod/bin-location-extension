page 50202 "Bin Type API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';

    EntityName = 'binType';
    EntitySetName = 'binTypes';

    SourceTable = "Bin Type";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Caption = 'Bin Type API';

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

                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }

                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }

                field(receive; Rec.Receive)
                {
                    Caption = 'Receive';
                }

                field(ship; Rec.Ship)
                {
                    Caption = 'Ship';
                }

                field(putAway; Rec."Put Away")
                {
                    Caption = 'Put Away';
                }

                field(pick; Rec.Pick)
                {
                    Caption = 'Pick';
                }

                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }
}
