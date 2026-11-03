page 50226 "WMS Posted Invt. PA Line API"
{
    // Posted inventory put-away lines, used to reconcile put-aways after a manager posts them in BC.
    // sourceNo / sourceLineNo are the purchase order no. and line no. invtPutAwayNo (the original
    // inventory put-away no.), postedReceiptNo and postingDate come from the posted header; they
    // are looked up per record, so filter on sourceNo or no instead:
    //   GET .../postedInvtPutAwayLines?$filter=sourceNo eq '{purchase order no.}'
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'postedInvtPutAwayLine';
    EntitySetName = 'postedInvtPutAwayLines';
    SourceTable = "Posted Invt. Put-away Line";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Posted Invt. PA Line API';

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
                field(invtPutAwayNo; InvtPutAwayNo)
                {
                    Caption = 'Invt. Put-away No.';
                }
                field(postedReceiptNo; PostedReceiptNo)
                {
                    Caption = 'Posted Receipt No.';
                }
                field(postingDate; PostingDate)
                {
                    Caption = 'Posting Date';
                }
                field(sourceType; Rec."Source Type")
                {
                    Caption = 'Source Type';
                }
                field(sourceSubtype; Rec."Source Subtype")
                {
                    Caption = 'Source Subtype';
                }
                field(sourceNo; Rec."Source No.")
                {
                    Caption = 'Source No.';
                }
                field(sourceLineNo; Rec."Source Line No.")
                {
                    Caption = 'Source Line No.';
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
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }

    var
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        InvtPutAwayNo: Code[20];
        PostedReceiptNo: Code[20];
        PostingDate: Date;

    trigger OnAfterGetRecord()
    begin
        if PostedInvtPutAwayHeader."No." <> Rec."No." then
            if not PostedInvtPutAwayHeader.Get(Rec."No.") then
                Clear(PostedInvtPutAwayHeader);
        InvtPutAwayNo := PostedInvtPutAwayHeader."Invt. Put-away No.";
        // Source No. on the posted header is the posted purchase receipt created by the posting.
        PostedReceiptNo := PostedInvtPutAwayHeader."Source No.";
        PostingDate := PostedInvtPutAwayHeader."Posting Date";
    end;
}
