page 50217 "WMS Location API"
{
    // Location Card warehouse settings the app needs to pick a supported document flow
    // (Pick-Ticket-Server#162). Read these instead of inferring configuration from bin codes.
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'location';
    EntitySetName = 'locations';
    SourceTable = Location;
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Location API';

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
                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(useAsInTransit; Rec."Use As In-Transit")
                {
                    Caption = 'Use As In-Transit';
                }
                field(binMandatory; Rec."Bin Mandatory")
                {
                    Caption = 'Bin Mandatory';
                }
                field(directedPutAwayAndPick; Rec."Directed Put-away and Pick")
                {
                    Caption = 'Directed Put-away and Pick';
                }
                field(requireReceive; Rec."Require Receive")
                {
                    Caption = 'Require Receive';
                }
                field(requirePutAway; Rec."Require Put-away")
                {
                    Caption = 'Require Put-away';
                }
                field(requireShipment; Rec."Require Shipment")
                {
                    Caption = 'Require Shipment';
                }
                field(requirePick; Rec."Require Pick")
                {
                    Caption = 'Require Pick';
                }
                field(usePutAwayWorksheet; Rec."Use Put-away Worksheet")
                {
                    Caption = 'Use Put-away Worksheet';
                }
                field(alwaysCreatePutAwayLine; Rec."Always Create Put-away Line")
                {
                    Caption = 'Always Create Put-away Line';
                }
                field(alwaysCreatePickLine; Rec."Always Create Pick Line")
                {
                    Caption = 'Always Create Pick Line';
                }
                field(useCrossDocking; Rec."Use Cross-Docking")
                {
                    Caption = 'Use Cross-Docking';
                }
                field(binCapacityPolicy; Rec."Bin Capacity Policy")
                {
                    Caption = 'Bin Capacity Policy';
                }
                field(defaultBinSelection; Rec."Default Bin Selection")
                {
                    Caption = 'Default Bin Selection';
                }
                field(receiptBinCode; Rec."Receipt Bin Code")
                {
                    Caption = 'Receipt Bin Code';
                }
                field(shipmentBinCode; Rec."Shipment Bin Code")
                {
                    Caption = 'Shipment Bin Code';
                }
                field(crossDockBinCode; Rec."Cross-Dock Bin Code")
                {
                    Caption = 'Cross-Dock Bin Code';
                }
                field(adjustmentBinCode; Rec."Adjustment Bin Code")
                {
                    Caption = 'Adjustment Bin Code';
                }
                field(toAssemblyBinCode; Rec."To-Assembly Bin Code")
                {
                    Caption = 'To-Assembly Bin Code';
                }
                field(fromAssemblyBinCode; Rec."From-Assembly Bin Code")
                {
                    Caption = 'From-Assembly Bin Code';
                }
                field(asmToOrderShptBinCode; Rec."Asm.-to-Order Shpt. Bin Code")
                {
                    Caption = 'Asm.-to-Order Shpt. Bin Code';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }
}
