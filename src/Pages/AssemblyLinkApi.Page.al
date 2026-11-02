page 50205 "Assembly Link API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'assemblyLink';
    EntitySetName = 'assemblyLinks';
    SourceTable = "Assemble-to-Order Link";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'Assembly Link API';

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
                field(assemblyDocumentType; Rec."Assembly Document Type")
                {
                    Caption = 'Assembly Document Type';
                }
                // assemblyDocumentNo is the Assembly Header "No." -
                // use this to filter assemblyLines by documentNo to get all
                // component lines belonging to this ATO order.
                field(assemblyDocumentNo; Rec."Assembly Document No.")
                {
                    Caption = 'Assembly Document No.';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                // documentNo + documentLineNo identify the parent sales line.
                field(documentType; Rec."Document Type")
                {
                    Caption = 'Document Type';
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(documentLineNo; Rec."Document Line No.")
                {
                    Caption = 'Document Line No.';
                }
                field(assembledQuantity; Rec."Assembled Quantity")
                {
                    Caption = 'Assembled Quantity';
                }
                field(createdDateTime; Rec.SystemCreatedAt)
                {
                    Caption = 'Created Date Time';
                }
                field(createdBy; Rec.SystemCreatedBy)
                {
                    Caption = 'Created By';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
                field(lastModifiedBy; Rec.SystemModifiedBy)
                {
                    Caption = 'Last Modified By';
                }
            }
        }
    }
}
