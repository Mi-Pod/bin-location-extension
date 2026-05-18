pageextension 50211 "Sales Order Reassign Bins" extends "Sales Order"
{
    actions
    {
        addlast(Processing)
        {
            action(ReassignBins)
            {
                ApplicationArea = All;
                Caption = 'Reassign Bins';
                Image = Replan;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    SendReassignBinsRequest(Rec."No.");
                end;
            }
        }
    }

    local procedure SendReassignBinsRequest(OrderNo: Code[20])
    var
        Client: HttpClient;
        Content: HttpContent;
        RequestUrl: Text;
        Response: HttpResponseMessage;
    begin
        if OrderNo = '' then
            Error('Order number is empty.');

        RequestUrl := StrSubstNo('%1?order_number=%2', GetTargetUrl(), OrderNo);

        Content.WriteFrom('');

        if not Client.Post(RequestUrl, Content, Response) then
            Error('Failed to send POST request to %1.', RequestUrl);

        if not Response.IsSuccessStatusCode() then
            Error('Request failed with status %1: %2', Response.HttpStatusCode(), Response.ReasonPhrase());

        ShowResponseModal(OrderNo, Response);
    end;

    local procedure ShowResponseModal(OrderNo: Code[20]; Response: HttpResponseMessage)
    var
        ResponseBody: Text;
    begin
        Response.Content.ReadAs(ResponseBody);
        Message(BuildResponseModalText(OrderNo, ResponseBody));
    end;

    local procedure BuildResponseModalText(OrderNo: Code[20]; ResponseBody: Text): Text
    var
        RootJson: JsonObject;
        ResultsJson: JsonObject;
        ResultsToken: JsonToken;
        IssuesToken: JsonToken;
        Issues: JsonArray;
        IssueToken: JsonToken;
        IssueJson: JsonObject;
        ReqId: Text;
        OrderIdentifier: Text;
        SeenCount: Text;
        UpdatedCount: Text;
        IssuesText: Text;
        i: Integer;
    begin
        if not RootJson.ReadFrom(ResponseBody) then
            exit(StrSubstNo('Reassign bins request sent for order %1.\Response was not JSON:\%2', OrderNo, ResponseBody));

        ReqId := GetJsonText(RootJson, 'req_id');
        OrderIdentifier := GetJsonText(RootJson, 'order_identifier');

        if RootJson.Get('results', ResultsToken) and ResultsToken.IsObject() then begin
            ResultsJson := ResultsToken.AsObject();
            SeenCount := GetJsonText(ResultsJson, 'seen');
            UpdatedCount := GetJsonText(ResultsJson, 'updated');

            if ResultsJson.Get('issues', IssuesToken) and IssuesToken.IsArray() then begin
                Issues := IssuesToken.AsArray();

                if Issues.Count() = 0 then
                    IssuesText := 'None'
                else
                    for i := 0 to Issues.Count() - 1 do begin
                        Issues.Get(i, IssueToken);
                        if IssueToken.IsObject() then begin
                            IssueJson := IssueToken.AsObject();
                            IssuesText += StrSubstNo('- %1',
                                GetJsonText(IssueJson, 'message'));
                        end;
                    end;
            end;
        end;

        if IssuesText = '' then
            IssuesText := 'None';

        exit(StrSubstNo(
            'Bin Reassignment Response\Request ID: %1\Order: %2\Seen: %3\Updated: %4\Issues:\%5',
            ReqId,
            SelectText(OrderIdentifier <> '', OrderIdentifier, Format(OrderNo)),
            SeenCount,
            UpdatedCount,
            IssuesText));
    end;

    local procedure GetJsonText(Json: JsonObject; PropertyName: Text): Text
    var
        ValueToken: JsonToken;
    begin
        if Json.Get(PropertyName, ValueToken) and ValueToken.IsValue() then
            exit(ValueToken.AsValue().AsText());

        exit('');
    end;

    local procedure SelectText(Condition: Boolean; TrueValue: Text; FalseValue: Text): Text
    begin
        if Condition then
            exit(TrueValue);

        exit(FalseValue);
    end;

    local procedure GetTargetUrl(): Text
    var
        TargetUrl: Text;
    begin
        TargetUrl := 'https://order-sync-b0f1f2769abe.herokuapp.com/api/orders/reassignBins';

        if TargetUrl = '' then
            Error('Target URL is not configured.');

        exit(TargetUrl);
    end;
}

