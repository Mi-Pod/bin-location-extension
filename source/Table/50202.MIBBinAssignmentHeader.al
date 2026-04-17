namespace MiOneBrands.WarehouseBinAssignment;

using Microsoft.Sales.Document;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.NoSeries;

table 50202 "MIB Bin Assignment Header"
{
    Caption = 'MIB Bin Assignment Header';
    DataClassification = CustomerContent;
    LookupPageId = "MIB Bin Assignment List";
    DrillDownPageId = "MIB Bin Assignment List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(2; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(4; Status; Enum "MIB Bin Assignment Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(5; "Assigned By"; Code[50])
        {
            Caption = 'Assigned By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Assigned Date"; Date)
        {
            Caption = 'Assigned Date';
            DataClassification = CustomerContent;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(8; "No. of Assignment Lines"; Integer)
        {
            Caption = 'No. of Assignment Lines';
            FieldClass = FlowField;
            CalcFormula = count("MIB Bin Assignment Line" where("Assignment No." = field("No.")));
            Editable = false;
        }
        field(9; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series".Code;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(SalesOrder; "Sales Order No.") { }
    }

    trigger OnInsert()
    var
        MIBBinAssignmentSetup: Record "MIB Bin Assignment Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if Rec."No." = '' then begin
            MIBBinAssignmentSetup.Get();
            Rec."No." := NoSeries.GetNextNo(MIBBinAssignmentSetup."Assignment Nos.", Today());
        end;
        Rec."Assigned By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Assigned By"));
        Rec."Assigned Date" := Today();
    end;
}
