page 50223 "WMS Reg. Invt. Mvmt. Line API"
{
    // Registered inventory movement lines, used to reconcile movements after registration in BC.
    // invtMovementNo (the original inventory movement no.) and registeringDate come from the
    // registered header; they are looked up per record, so filter on wmsInternalMovementNo or no instead:
    //   GET .../registeredInvtMovementLines?$filter=wmsInternalMovementNo eq '{no}'
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'registeredInvtMovementLine';
    EntitySetName = 'registeredInvtMovementLines';
    SourceTable = "Registered Invt. Movement Line";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Reg. Invt. Mvmt. Line API';

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
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(invtMovementNo; InvtMovementNo)
                {
                    Caption = 'Invt. Movement No.';
                }
                field(registeringDate; RegisteringDate)
                {
                    Caption = 'Registering Date';
                }
                field(actionType; Rec."Action Type")
                {
                    Caption = 'Action Type';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin Code';
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
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(quantityBase; Rec."Qty. (Base)")
                {
                    Caption = 'Quantity (Base)';
                }
                field(wmsInternalMovementNo; Rec."WMS Internal Movement No.")
                {
                    Caption = 'WMS Internal Movement No.';
                }
                field(wmsSourceLineNo; Rec."WMS Source Line No.")
                {
                    Caption = 'WMS Source Line No.';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }

    var
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        InvtMovementNo: Code[20];
        RegisteringDate: Date;

    trigger OnAfterGetRecord()
    begin
        if RegisteredInvtMovementHdr."No." <> Rec."No." then
            if not RegisteredInvtMovementHdr.Get(Rec."No.") then
                Clear(RegisteredInvtMovementHdr);
        InvtMovementNo := RegisteredInvtMovementHdr."Invt. Movement No.";
        RegisteringDate := RegisteredInvtMovementHdr."Registering Date";
    end;
}
