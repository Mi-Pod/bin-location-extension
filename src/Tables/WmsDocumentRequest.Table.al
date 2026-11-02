table 50216 "WMS Document Request"
{
    // One row per processed WMS command request, keyed by the app's external request key.
    // Used by "WMS Request Management" (50216) to make every command endpoint retry-safe,
    // and exposed read-only through the wmsDocumentRequests API (50218) for reconciliation.
    Caption = 'WMS Document Request';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "External Request Key"; Text[100])
        {
            Caption = 'External Request Key';
            DataClassification = SystemMetadata;
        }
        field(3; "Workflow Type"; Enum "WMS Workflow Type")
        {
            Caption = 'Workflow Type';
            DataClassification = SystemMetadata;
        }
        field(4; "Payload Hash"; Text[64])
        {
            Caption = 'Payload Hash';
            DataClassification = SystemMetadata;
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            DataClassification = CustomerContent;
        }
        field(6; "Created By"; Text[100])
        {
            // Actor name sent by the app. The app has no authentication yet (Pick-Ticket-Server#9).
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Document No."; Code[20])
        {
            // Source document created by the request, e.g. the Internal Movement no.
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(8; "Activity No."; Code[20])
        {
            // Warehouse activity created by the request, e.g. the Inventory Movement no.
            Caption = 'Activity No.';
            DataClassification = CustomerContent;
        }
        field(9; "Target Id"; Guid)
        {
            // SystemId of the record a request created or changed, e.g. a Bin or Bin Content.
            Caption = 'Target Id';
            DataClassification = SystemMetadata;
        }
        field(10; "Response JSON"; Blob)
        {
            // Result returned to the app, replayed as-is when the same request is retried.
            Caption = 'Response JSON';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ExternalRequestKey; "External Request Key")
        {
            Unique = true;
        }
    }

    procedure SetResponse(ResponseJson: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Response JSON");
        "Response JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseJson);
    end;

    procedure GetResponse() ResponseJson: Text
    var
        InStr: InStream;
    begin
        CalcFields("Response JSON");
        if not "Response JSON".HasValue() then
            exit('');
        "Response JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(ResponseJson);
    end;
}
