codeunit 50208 "Assembly Line Bin Reassign"
{
    [ServiceEnabled]
    procedure ReassignAssemblyLineBin(AssemblyLineId: Guid; NewBinCode: Code[20]): Text
    var
        AssemblyLine: Record "Assembly Line";
        Bin: Record Bin;
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

        AssemblyLine.Validate("Bin Code", NormalizedBinCode);
        AssemblyLine.Modify(true);

        exit(
          StrSubstNo(
            'Assembly line %1 (line %2) bin updated to %3.',
            AssemblyLine."Document No.",
            AssemblyLine."Line No.",
            AssemblyLine."Bin Code"));
    end;
}
