query 50227 "WMS Bin Shipment API"
{
    // Units shipped out of each bin per day, from posted Warehouse Entries, for the level
    // suggestions in Pick-Ticket-Server (Replenishment -> Levels -> Suggest levels). Read-only.
    //   GET .../binShipments?$filter=locationCode eq 'AZ-WHSE-01' and registeringDate ge 2026-09-01
    //
    // One row per location + bin + item + variant + registering date. quantityBase is the net
    // base quantity of sales order shipments and assembly consumption: negative = out of the
    // bin, and an undone shipment nets back. Movements, put-aways, receipts and journal
    // adjustments are not included.
    QueryType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'binShipment';
    EntitySetName = 'binShipments';
    Caption = 'WMS Bin Shipment API';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(WarehouseEntry; "Warehouse Entry")
        {
            DataItemTableFilter = "Source Document" = filter("S. Order" | "Assembly Consumption"), "Bin Code" = filter(<> '');

            column(locationCode; "Location Code")
            {
            }
            column(binCode; "Bin Code")
            {
            }
            column(itemNo; "Item No.")
            {
            }
            column(variantCode; "Variant Code")
            {
            }
            column(registeringDate; "Registering Date")
            {
            }
            column(quantityBase; "Qty. (Base)")
            {
                Method = Sum;
            }
        }
    }
}
