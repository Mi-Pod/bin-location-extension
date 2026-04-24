page 50210 "Bin Reassignment API"
{
    // Command endpoint for bin reassignment via the v2 API framework.
    //
    // Usage:
    //   POST /api/mioneBrands/warehouse/v1.0/companies({id})/binReassignments
    //   { "targetType": "AssemblyLine", "assemblyLineId": "{guid}", "newBinCode": "FP-14-25" }
    //   { "targetType": "SalesLine",    "salesLineId":    "{guid}", "newBinCode": "FP-14-25" }
    //
    // The POST fires OnInsertRecord which calls the appropriate codeunit procedure.
    // The record is never persisted - the table is Temporary. The response body
    // includes the "result" field confirming the update.
    //
    // GET is supported to confirm the endpoint is reachable; it returns an empty set.

    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'binReassignment';
    EntitySetName = 'binReassignments';
    SourceTable = "Bin Reassignment Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = "Request Id";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'Bin Reassignment API';

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
                field(targetType; Rec."Target Type")
                {
                    Caption = 'Target Type';
                }
                field(assemblyLineId; Rec."Assembly Line Id")
                {
                    Caption = 'Assembly Line Id';
                }
                field(salesLineId; Rec."Sales Line Id")
                {
                    Caption = 'Sales Line Id';
                }
                field(newBinCode; Rec."New Bin Code")
                {
                    Caption = 'New Bin Code';
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
        BinReassign: Codeunit "Assembly Line Bin Reassign";
    begin
        Rec."Request Id" := CreateGuid();

        case Rec."Target Type" of
            Rec."Target Type"::AssemblyLine:
                begin
                    if IsNullGuid(Rec."Assembly Line Id") then
                        Error('assemblyLineId is required when targetType is AssemblyLine.');
                    BinReassign.ReassignAssemblyLineBin(Rec."Assembly Line Id", Rec."New Bin Code");
                    Rec.Result := StrSubstNo('Assembly line %1 bin updated to %2.', Rec."Assembly Line Id", Rec."New Bin Code");
                end;
            Rec."Target Type"::SalesLine:
                begin
                    if IsNullGuid(Rec."Sales Line Id") then
                        Error('salesLineId is required when targetType is SalesLine.');
                    BinReassign.ReassignSalesLineBin(Rec."Sales Line Id", Rec."New Bin Code");
                    Rec.Result := StrSubstNo('Sales line %1 bin updated to %2.', Rec."Sales Line Id", Rec."New Bin Code");
                end;
            else
                Error('targetType must be AssemblyLine or SalesLine.');
        end;

        // Return true to let the framework return the record (with result populated).
        // The temp table means nothing is written to the database.
        exit(true);
    end;
}
