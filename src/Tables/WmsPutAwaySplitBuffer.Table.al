table 50223 "WMS Put-away Split Buffer"
{
    // Temporary table backing the putAwaySplits command API page (50225).
    // Nothing persists - records exist only for the duration of a single POST request.
    TableType = Temporary;
    Caption = 'WMS Put-away Split Buffer';

    fields
    {
        field(1; "Request Id"; Guid)
        {
            Caption = 'Request Id';
            DataClassification = SystemMetadata;
        }
        field(2; "External Request Key"; Text[100])
        {
            Caption = 'External Request Key';
            DataClassification = SystemMetadata;
        }
        field(3; "Created By"; Text[100])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Activity No."; Code[20])
        {
            // Inventory Put-away no.
            Caption = 'Activity No.';
            DataClassification = CustomerContent;
        }
        field(5; "Line No."; Integer)
        {
            // The open Place line to split.
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(6; "Allocations JSON"; Blob)
        {
            // JSON array of destination bins: [{binCode, quantityBase}]
            Caption = 'Allocations JSON';
            DataClassification = CustomerContent;
        }
        field(7; "Expected Last Modified At"; DateTime)
        {
            // Optional. When set, the request fails if the line was changed in BC after this time.
            Caption = 'Expected Last Modified At';
            DataClassification = SystemMetadata;
        }
        field(10; "Source No."; Code[20])
        {
            // Purchase order no.
            Caption = 'Source No.';
            DataClassification = CustomerContent;
        }
        field(11; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            DataClassification = CustomerContent;
        }
        field(12; "Response JSON"; Blob)
        {
            // Full response, including the resulting line nos., bins and quantities.
            Caption = 'Response JSON';
            DataClassification = CustomerContent;
        }
        field(13; "Last Modified At"; DateTime)
        {
            // Newest SystemModifiedAt of the resulting lines.
            Caption = 'Last Modified At';
            DataClassification = SystemMetadata;
        }
        field(14; Result; Text[250])
        {
            Caption = 'Result';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Request Id")
        {
            Clustered = true;
        }
    }

    procedure SetAllocationsJson(AllocationsJson: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Allocations JSON");
        "Allocations JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(AllocationsJson);
    end;

    procedure GetAllocationsJson() AllocationsJson: Text
    var
        InStr: InStream;
    begin
        if not "Allocations JSON".HasValue() then
            exit('');
        "Allocations JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(AllocationsJson);
    end;

    procedure SetResponseJson(ResponseJson: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Response JSON");
        "Response JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseJson);
    end;

    procedure GetResponseJson() ResponseJson: Text
    var
        InStr: InStream;
    begin
        if not "Response JSON".HasValue() then
            exit('');
        "Response JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(ResponseJson);
    end;
}
