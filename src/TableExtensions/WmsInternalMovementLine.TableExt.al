tableextension 50222 "WMS Internal Movement Line" extends "Internal Movement Line"
{
    // BC only checks bin availability when a user types the Quantity (CurrFieldNo = Quantity).
    // This exposes the protected check so code-created lines get the same validation.
    procedure WmsCheckBinContentQty()
    begin
        CheckBinContentQty();
    end;
}
