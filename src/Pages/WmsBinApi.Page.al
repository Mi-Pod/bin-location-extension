page 50216 "WMS Bin API"
{
    // Bin master records, including empty bins that have no Bin Content.
    // A bin missing from binContents is not missing from BC; check this endpoint instead.
    PageType = API;
    APIPublisher = 'mioneBrands';
    APIGroup = 'warehouse';
    APIVersion = 'v1.0';
    EntityName = 'bin';
    EntitySetName = 'bins';
    SourceTable = Bin;
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'WMS Bin API';

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
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(binCode; Rec.Code)
                {
                    Caption = 'Bin Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(zoneCode; Rec."Zone Code")
                {
                    Caption = 'Zone Code';
                }
                field(binTypeCode; Rec."Bin Type Code")
                {
                    Caption = 'Bin Type Code';
                }
                field(warehouseClassCode; Rec."Warehouse Class Code")
                {
                    Caption = 'Warehouse Class Code';
                }
                field(specialEquipmentCode; Rec."Special Equipment Code")
                {
                    Caption = 'Special Equipment Code';
                }
                field(blockMovement; Rec."Block Movement")
                {
                    Caption = 'Block Movement';
                }
                field(dedicated; Rec.Dedicated)
                {
                    Caption = 'Dedicated';
                }
                field(defaultBin; Rec.Default)
                {
                    Caption = 'Default';
                }
                field(crossDockBin; Rec."Cross-Dock Bin")
                {
                    Caption = 'Cross-Dock Bin';
                }
                field(adjustmentBin; Rec."Adjustment Bin")
                {
                    Caption = 'Adjustment Bin';
                }
                field(empty; Rec.Empty)
                {
                    Caption = 'Empty';
                }
                field(binRanking; Rec."Bin Ranking")
                {
                    Caption = 'Bin Ranking';
                }
                field(maximumCubage; Rec."Maximum Cubage")
                {
                    Caption = 'Maximum Cubage';
                }
                field(maximumWeight; Rec."Maximum Weight")
                {
                    Caption = 'Maximum Weight';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }
}
