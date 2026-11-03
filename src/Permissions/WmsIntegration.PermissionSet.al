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
        tabledata "Bin Content" = RIM,
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
        page "WMS Document Request API" = X,
        // #7 bin levels
        tabledata "Item Variant" = R,
        tabledata "Item Unit of Measure" = R,
        table "WMS Bin Level Buffer" = X,
        codeunit "WMS Bin Level Management" = X,
        codeunit "WMS Bin Rules" = X,
        page "WMS Bin Level API" = X,
        // #5 movements
        tabledata "No. Series" = R,
        tabledata "No. Series Line" = RIM,
        tabledata "Internal Movement Header" = RIMD,
        tabledata "Internal Movement Line" = RIMD,
        tabledata "Warehouse Activity Header" = RIMD,
        tabledata "Warehouse Activity Line" = RIMD,
        tabledata "Registered Invt. Movement Hdr." = R,
        tabledata "Registered Invt. Movement Line" = R,
        tabledata "Inventory Setup" = R,
        tabledata "Warehouse Employee" = R,
        tabledata "Item Tracking Code" = R,
        tabledata "Whse. Item Tracking Line" = R,
        table "WMS Movement Buffer" = X,
        table "WMS Qty. to Handle Buffer" = X,
        codeunit "WMS Movement Management" = X,
        codeunit "WMS Movement Events" = X,
        page "WMS Movement API" = X,
        page "WMS Qty. to Handle API" = X,
        page "WMS Activity Line API" = X,
        page "WMS Reg. Invt. Mvmt. Line API" = X,
        // #6 put-away
        tabledata "Posted Invt. Put-away Header" = R,
        tabledata "Posted Invt. Put-away Line" = R,
        table "WMS Put-away Split Buffer" = X,
        codeunit "WMS Put-away Management" = X,
        page "WMS Put-away Split API" = X,
        page "WMS Posted Invt. PA Line API" = X;
}
