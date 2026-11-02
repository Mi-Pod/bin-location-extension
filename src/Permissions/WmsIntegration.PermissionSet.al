permissionset 50216 "WMS Integration"
{
    // Assign to the Pick-Ticket-Server integration user. Covers this extension's objects and
    // read access to the BC tables its APIs expose. Write access to BC tables is added as each
    // command endpoint lands (#4, #5, #6, #7).
    Assignable = true;
    Caption = 'WMS Integration';

    Permissions =
        tabledata "WMS Document Request" = RIM,
        table "WMS Document Request" = X,
        tabledata Bin = R,
        tabledata "Bin Content" = R,
        tabledata "Bin Type" = R,
        tabledata Zone = R,
        tabledata Location = R,
        tabledata Item = R,
        tabledata "Sales Line" = R,
        tabledata "Assembly Header" = R,
        tabledata "Assembly Line" = R,
        tabledata "Assemble-to-Order Link" = R,
        codeunit "WMS Request Management" = X,
        codeunit "Assembly Line Bin Reassign" = X,
        page "Bin Content API" = X,
        page "Bin Type API" = X,
        page "Zone API" = X,
        page "Sales Line API" = X,
        page "Assembly Link API" = X,
        page "Assembly Header API" = X,
        page "Assembly Line API" = X,
        page "Bin Reassignment API" = X,
        page "WMS Bin API" = X,
        page "WMS Location API" = X,
        page "WMS Document Request API" = X;
}
