enum 50216 "WMS Workflow Type"
{
    // Workflow types from the shared planning-to-BC contract (Pick-Ticket-Server#162).
    // Every WMS command endpoint records its requests under one of these.
    Extensible = false;
    Caption = 'WMS Workflow Type';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Bin Setup")
    {
        Caption = 'Bin Setup';
    }
    value(2; Replenishment)
    {
        Caption = 'Replenishment';
    }
    value(3; "Missing Bin Fill")
    {
        Caption = 'Missing Bin Fill';
    }
    value(4; "Put-away")
    {
        Caption = 'Put-away';
    }
    value(5; "Qty. to Handle")
    {
        Caption = 'Qty. to Handle';
    }
    value(6; "Bin Levels")
    {
        Caption = 'Bin Levels';
    }
}
