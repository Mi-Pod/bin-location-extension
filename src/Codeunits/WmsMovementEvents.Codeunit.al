codeunit 50221 "WMS Movement Events"
{
    // Stamps the internal movement link on inventory movement lines as BC creates them.
    // The event fires before BC splits the line into Take and Place, so both get the stamp.
    // It runs for every movement created from an internal movement, not only the API's.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnCreateInvtMvntWithoutSourceOnAfterTransferFields', '', false, false)]
    local procedure StampInternalMovementLink(var WarehouseActivityLine: Record "Warehouse Activity Line"; InternalMovementLine: Record "Internal Movement Line")
    begin
        WarehouseActivityLine."WMS Internal Movement No." := InternalMovementLine."No.";
        WarehouseActivityLine."WMS Source Line No." := InternalMovementLine."Line No.";
    end;
}
