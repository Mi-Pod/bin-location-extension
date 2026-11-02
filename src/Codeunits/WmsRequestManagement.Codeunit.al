codeunit 50216 "WMS Request Management"
{
    // Retry handling shared by every WMS command endpoint (#4, #5, #6, #7).
    //
    // Usage from a command:
    //   1. Build a canonical text of the validated input fields and hash it with ComputePayloadHash.
    //   2. Call FindExisting. If it returns true, replay WmsDocumentRequest.GetResponse() and stop.
    //   3. Do the work, then fill a "WMS Document Request" record and call Register
    //      in the same transaction.
    //
    // A command that errors rolls back its request row too, so a failed request can simply be
    // retried. Two identical requests racing each other collide on the unique key; the loser
    // errors and its retry replays the winner's result.

    var
        RequestKeyRequiredErr: Label 'An external request key is required.';
        KeyUsedForOtherWorkflowErr: Label 'External request key %1 was already used for a %2 request.', Comment = '%1 = external request key, %2 = workflow type';
        PayloadMismatchErr: Label 'External request key %1 was already used with a different payload.', Comment = '%1 = external request key';

    procedure ComputePayloadHash(CanonicalPayload: Text): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        exit(CopyStr(CryptographyManagement.GenerateHash(CanonicalPayload, HashAlgorithmType::SHA256), 1, 64));
    end;

    procedure FindExisting(ExternalRequestKey: Text[100]; WorkflowType: Enum "WMS Workflow Type"; PayloadHash: Text[64]; var WmsDocumentRequest: Record "WMS Document Request"): Boolean
    begin
        CheckRequestKey(ExternalRequestKey);

        WmsDocumentRequest.Reset();
        WmsDocumentRequest.SetRange("External Request Key", ExternalRequestKey);
        if not WmsDocumentRequest.FindFirst() then
            exit(false);

        if WmsDocumentRequest."Workflow Type" <> WorkflowType then
            Error(KeyUsedForOtherWorkflowErr, ExternalRequestKey, WmsDocumentRequest."Workflow Type");
        if WmsDocumentRequest."Payload Hash" <> PayloadHash then
            Error(PayloadMismatchErr, ExternalRequestKey);

        exit(true);
    end;

    procedure Register(var WmsDocumentRequest: Record "WMS Document Request")
    begin
        CheckRequestKey(WmsDocumentRequest."External Request Key");
        WmsDocumentRequest.TestField("Payload Hash");
        WmsDocumentRequest.Insert(true);
    end;

    local procedure CheckRequestKey(ExternalRequestKey: Text)
    begin
        if DelChr(ExternalRequestKey, '<>', ' ') = '' then
            Error(RequestKeyRequiredErr);
    end;
}
