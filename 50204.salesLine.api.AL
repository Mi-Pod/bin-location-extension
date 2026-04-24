page 50204 "Sales Line API"
{
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'salesLine_wBin';
    EntitySetName = 'salesLine_wBins';
    SourceTable = "Sales Line";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Caption = 'Sales Line w/ Bin API';

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
                field(documentType; Rec."Document Type")
                {
                    Caption = 'Document Type';
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(qtyToShip; Rec."Qty. to Ship")
                {
                    Caption = 'Qty. to Ship';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Line Amount';
                }
                field(outstandingQuantity; Rec."Outstanding Quantity")
                {
                    Caption = 'Outstanding Quantity';
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        BinReassign: Codeunit "Assembly Line Bin Reassign";
    begin
        if Rec."Bin Code" <> xRec."Bin Code" then begin
            BinReassign.ReassignSalesLineBin(Rec.SystemId, Rec."Bin Code");
            exit(false);
        end;
        exit(true);
    end;
}
