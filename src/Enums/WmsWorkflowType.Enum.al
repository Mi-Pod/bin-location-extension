enum 50216 "WMS Workflow Type"
{
    // Workflow types from the shared planning-to-BC contract (Pick-Ticket-Server#162).
    // Every WMS command endpoint records its requests under one of these.
    // Value names are what the wmsDocumentRequests API returns, so they have no spaces or
    // punctuation (BC would encode them, e.g. Qty_x002E__x0020_to_x0020_Handle).
    Extensible = false;
    Caption = 'WMS Workflow Type';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; BinSetup)
    {
        Caption = 'Bin Setup';
    }
    value(2; Replenishment)
    {
        Caption = 'Replenishment';
    }
    value(3; MissingBinFill)
    {
        Caption = 'Missing Bin Fill';
    }
    value(4; PutAway)
    {
        Caption = 'Put-away';
    }
    value(5; QtyToHandle)
    {
        Caption = 'Qty. to Handle';
    }
    value(6; BinLevels)
    {
        Caption = 'Bin Levels';
    }
}
