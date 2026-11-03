codeunit 50208 "Assembly Line Bin Reassign"
{
    // Internal codeunit - procedures are called by API page OnModifyRecord triggers
    // and by the binReassignments command API page (50209).
    // goes through the OData/API v2 surface exposed by pages 50207, 50204, 50209.

    procedure ReassignAssemblyLineBin(AssemblyLineId: Guid; NewBinCode: Code[20])
    var
        AssemblyLine: Record "Assembly Line";
        Bin: Record Bin;
        ATOLink: Record "Assemble-to-Order Link";
        SalesLine: Record "Sales Line";
        NormalizedBinCode: Code[20];
    begin
        if IsNullGuid(AssemblyLineId) then
            Error('AssemblyLineId is required.');

        NormalizedBinCode := CopyStr(DelChr(NewBinCode, '<>', ' '), 1, MaxStrLen(NormalizedBinCode));
        if NormalizedBinCode = '' then
            Error('NewBinCode is required.');

        AssemblyLine.SetRange(SystemId, AssemblyLineId);
        if not AssemblyLine.FindFirst() then
            Error('Assembly line with SystemId %1 was not found.', AssemblyLineId);

        AssemblyLine.TestField("Location Code");

        if not Bin.Get(AssemblyLine."Location Code", NormalizedBinCode) then
            Error(
                'Bin %1 does not exist in location %2 for assembly line %3.',
                NormalizedBinCode,
                AssemblyLine."Location Code",
                AssemblyLine."Document No.");

        // Detect ATO linkage. The link record key is:
        //   Assembly Document Type = Order, Assembly Document No. = header No.
        // The link is 1:1 between a sales line and an assembly header - there is
        // no line-level granularity on the link itself.
        if ATOLink.Get(ATOLink."Assembly Document Type"::Order, AssemblyLine."Document No.") then begin
            // ATO path: writing Bin Code directly bypasses the OnModify ATO guard
            // that causes "Request Data Invalid" when going through Validate + Modify(true).
            AssemblyLine."Bin Code" := NormalizedBinCode;
            AssemblyLine.Modify(false);

            // Re-sync the parent sales line so the ATO coupling is not left
            // inconsistent (sales line bin != assembly line bin).
            if SalesLine.Get(ATOLink."Document Type", ATOLink."Document No.", ATOLink."Document Line No.") then begin
                SalesLine."Bin Code" := NormalizedBinCode;
                SalesLine.Modify(false);
            end;
        end else begin
            // Non-ATO path: run full validation so bin availability checks
            // and any other OnModify logic fires normally.
            AssemblyLine.Validate("Bin Code", NormalizedBinCode);
            AssemblyLine.Modify(true);
        end;
    end;

    procedure ReassignSalesLineBin(SalesLineId: Guid; NewBinCode: Code[20])
    var
        SalesLine: Record "Sales Line";
        Bin: Record Bin;
        NormalizedBinCode: Code[20];
    begin
        if IsNullGuid(SalesLineId) then
            Error('SalesLineId is required.');

        NormalizedBinCode := CopyStr(DelChr(NewBinCode, '<>', ' '), 1, MaxStrLen(NormalizedBinCode));
        if NormalizedBinCode = '' then
            Error('NewBinCode is required.');

        SalesLine.SetRange(SystemId, SalesLineId);
        if not SalesLine.FindFirst() then
            Error('Sales line with SystemId %1 was not found.', SalesLineId);

        SalesLine.TestField("Location Code");

        if not Bin.Get(SalesLine."Location Code", NormalizedBinCode) then
            Error(
                'Bin %1 does not exist in location %2 for sales line %3 / %4.',
                NormalizedBinCode,
                SalesLine."Location Code",
                SalesLine."Document No.",
                SalesLine."Line No.");

        SalesLine.Validate("Bin Code", NormalizedBinCode);
        SalesLine.Modify(true);
    end;
}
