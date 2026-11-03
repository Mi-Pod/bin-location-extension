table 50220 "WMS Movement Buffer"
{
    // Temporary table backing the movements command API page (50220).
    // Nothing persists - records exist only for the duration of a single POST request.
    TableType = Temporary;
    Caption = 'WMS Movement Buffer';

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
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
        }
        field(5; "Lines JSON"; Blob)
        {
            // JSON array of request lines: [{itemNo, variantCode, fromBinCode, toBinCode, quantityBase}]
            Caption = 'Lines JSON';
            DataClassification = CustomerContent;
        }
        field(10; "Internal Movement No."; Code[20])
        {
            Caption = 'Internal Movement No.';
            DataClassification = CustomerContent;
        }
        field(11; "Activity No."; Code[20])
        {
            Caption = 'Activity No.';
            DataClassification = CustomerContent;
        }
        field(12; "Response JSON"; Blob)
        {
            // Full response, including the created Take/Place line nos.
            Caption = 'Response JSON';
            DataClassification = CustomerContent;
        }
        field(13; Result; Text[250])
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

    procedure SetLinesJson(LinesJson: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Lines JSON");
        "Lines JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(LinesJson);
    end;

    procedure GetLinesJson() LinesJson: Text
    var
        InStr: InStream;
    begin
        if not "Lines JSON".HasValue() then
            exit('');
        "Lines JSON".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(LinesJson);
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
