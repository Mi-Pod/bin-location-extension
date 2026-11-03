# Bin Location Extension

**Publisher:** Mi-One Brands  
**Version:** 1.0.0.6  
**Platform:** Business Central 27.0 (Runtime 16.0)

A Business Central AL extension that exposes warehouse bin data through OData APIs and provides bin assignment capabilities for sales orders and assembly operations, with special handling for Assemble-to-Order (ATO) workflows.

---

## Features

- **Warehouse master data APIs** — Read-only access to bin contents, bin types, and warehouse zones
- **Sales line bin assignment** — Update bin codes on sales order lines via REST API
- **Assembly line bin assignment** — Update bin codes on assembly order component lines via REST API
- **ATO-aware synchronization** — Automatically detects Assemble-to-Order relationships and keeps parent sales line bins in sync when assembly line bins change
- **Command-based bulk reassignment** — Dedicated POST endpoint for programmatic bin reassignments
- **Sales Order UI action** — "Reassign Bins" button on the Sales Order page that calls an external service and displays results

---

## API Endpoints

All endpoints are under the base path:

```
/api/mioneBrands/warehouse/v1.0/
```

### Read-Only Endpoints

| Endpoint | Source Table | Description |
|---|---|---|
| `binContents` | Bin Content | Bin inventory levels by location, zone, item, and variant, including `minQty` / `maxQty` |
| `binTypes` | Bin Type | Bin type master (receive, ship, put-away, pick flags) |
| `zones` | Zone | Warehouse zone master data |
| `assemblyLinks` | Assemble-to-Order Link | ATO linkage between assembly headers and sales lines |
| `assemblyHeaders` | Assembly Header | Full assembly order header data including bin code, quantities, and dates |
| `warehouseActivityLines` | Warehouse Activity Line | Open activity lines (Take/Place pairs) with qty. to handle/outstanding/handled, the source document fields (`sourceType`, `sourceSubtype`, `sourceNo`, `sourceLineNo`, `sourceDocument`, `dueDate`) and the WMS internal movement link fields |
| `registeredInvtMovementLines` | Registered Invt. Movement Line | Registered inventory movement lines with the original inventory movement no., registering date and the WMS link fields |
| `postedInvtPutAwayLines` | Posted Invt. Put-away Line | Posted inventory put-away lines with the purchase order (`sourceNo` / `sourceLineNo`), bin, quantities, and the original inventory put-away no., posted receipt no. and posting date from the header |

### Editable Endpoints

| Endpoint | Source Table | Editable Fields |
|---|---|---|
| `salesLine_wBins` | Sales Line | `binCode` — triggers ATO sync on change |
| `assemblyLines` | Assembly Line | `binCode` — triggers ATO sync on change |

### Command Endpoints

| Endpoint | Buffer Table | Description |
|---|---|---|
| `binReassignments` | Bin Reassignment Buffer | Assign a bin to a sales line or assembly line (below) |
| `binLevels` | WMS Bin Level Buffer | Set Min. Qty. / Max. Qty. on a Bin Content, creating a Fixed Bin Content if none exists (#7) |
| `binSetups` | WMS Bin Setup Buffer | Create a missing bin from a template bin and/or make an item Fixed / Default in a bin (#4) |


**`POST /api/mioneBrands/warehouse/v1.0/companies({id})/binReassignments`**

Assign a bin to a sales line or assembly line by GUID.

**Reassign an assembly line bin:**
```json
{
  "targetType": "AssemblyLine",
  "assemblyLineId": "{assembly-line-system-id}",
  "newBinCode": "FP-14-25"
}
```

**Reassign a sales line bin:**
```json
{
  "targetType": "SalesLine",
  "salesLineId": "{sales-line-system-id}",
  "newBinCode": "FP-14-25"
}
```

The response includes a `result` field with a confirmation message. Requests are not persisted to the database.

**`POST /api/mioneBrands/warehouse/v1.0/companies({id})/binLevels`**

Set the replenishment min/max for an item in a bin. Retry-safe: the same `externalRequestKey` with the same payload replays the first response; with a different payload it errors.

```json
{
  "externalRequestKey": "{unique-key}",
  "createdBy": "jdoe",
  "locationCode": "MAIN",
  "binCode": "FP-14-25",
  "itemNo": "1000",
  "variantCode": "",
  "unitOfMeasureCode": "",
  "minQty": 5,
  "maxQty": 20,
  "fixed": true,
  "allowOtherFixedItem": false
}
```

Only `externalRequestKey`, `locationCode`, `binCode`, `itemNo`, `minQty` and `maxQty` are needed. `unitOfMeasureCode` defaults to the item's base unit, `fixed` to `true`, `allowOtherFixedItem` to `false`. Send `minQty` 0 and `maxQty` 0 to clear the rule; the Bin Content is kept. Quantities in the bin are never changed.

The response echoes the stored values plus `binContentId`, `lastModifiedDateTime` and `result`. Requests fail if the bin is blocked, dedicated, the location's adjustment bin, if `minQty` > `maxQty`, or if either is not a whole number. If the item isn't already Fixed in the bin and another item/variant is, the request also fails unless `allowOtherFixedItem` is `true`. Bins shared by several Fixed items can always have each item's levels set.

**`POST /api/mioneBrands/warehouse/v1.0/companies({id})/binSetups`**

Create a bin that doesn't exist yet and/or assign an item to a bin. Retry-safe like `binLevels`.

```json
{
  "externalRequestKey": "{unique-key}",
  "createdBy": "jdoe",
  "locationCode": "MAIN",
  "binCode": "FP-14-26",
  "templateBinCode": "FP-14-25",
  "description": "Pick face 14-26",
  "itemNo": "1000",
  "variantCode": "",
  "unitOfMeasureCode": "",
  "fixed": true,
  "default": true,
  "replaceDefault": false,
  "allowOtherFixedItem": false
}
```

Only `externalRequestKey`, `locationCode` and `binCode` are always needed. Defaults: `unitOfMeasureCode` the item's base unit, `fixed` `true`, `default`, `replaceDefault` and `allowOtherFixedItem` `false`.

Response (besides the request fields):
```json
{
  "binId": "{bin-system-id}",
  "binCreated": true,
  "binContentId": "{bin-content-system-id}",
  "binContentCreated": true,
  "defaultMovedFromBinCode": "",
  "fixed": true,
  "default": true,
  "lastModifiedDateTime": "2026-11-02T17:05:00Z",
  "result": "Bin FP-14-26 created in location MAIN from template FP-14-25. Item 1000 variant '' (PCS) in bin FP-14-26: Fixed Yes, Default Yes."
}
```

Rules:
- **Location:** must be Bin Mandatory and not use Directed Put-away and Pick.
- **New bin:** if `binCode` doesn't exist, `templateBinCode` is required and must be a bin in the same location that is not Dedicated and not the adjustment bin. The new bin copies Zone Code, Bin Type Code, Warehouse Class Code, Bin Ranking, Special Equipment Code, Maximum Cubage, Maximum Weight and Cross-Dock Bin from it. It gets `description` (else blank), and is never blocked or Dedicated.
- **Existing bin:** never changed; `templateBinCode` and `description` are ignored and `binCreated` is `false`.
- **No `itemNo`:** only the bin is set up. `binContentId` is `null` and `fixed`/`default` are `false`. Sending `variantCode`, `unitOfMeasureCode` or `default: true` without `itemNo` fails.
- **With `itemNo`:** the item must be of type Inventory and the variant and unit of measure must exist. The bin must not be blocked, Dedicated or the adjustment bin. If `fixed` or `default` is requested and another item/variant is already Fixed in the bin, the request fails unless `allowOtherFixedItem` is `true` (same rule as `binLevels`).
- **Bin Content:** created if missing with the requested flags. On an existing one, the requested flags are only *added*: Fixed and Default are never cleared and quantities never change. `fixed` and `default` in the response are the Bin Content's flags after the request.
- **Default:** BC proposes an item's Default bin on purchase/sales lines and put-aways, and allows one per item/variant per location. If another bin is already the Default, the request fails naming that bin, unless `replaceDefault` is `true`; then that bin loses its Default and `defaultMovedFromBinCode` names it.

### WMS Movement Commands

All three commands are retry-safe: the same `externalRequestKey` with the same payload replays the first response (see `wmsDocumentRequests`). Quantities are in base units. Nothing is committed unless the whole request succeeds.

**No fractions:** every quantity sent to a WMS command (`movements`, `qtyToHandles`, `putAwaySplits`, `binLevels`) must be a whole number of the line's unit of measure, whatever the unit's Qty. Rounding Precision says. Anything else is refused with an error naming the field and value; nothing is rounded.

| Endpoint | Page | Description |
|---|---|---|
| `POST movements` | 50220 WMS Movement API | Creates an Internal Movement and turns it into an Inventory Movement. Fails as a whole if any source bin is short or an item uses warehouse lot/serial/package tracking. |
| `POST qtyToHandles` | 50221 WMS Qty. to Handle API | Sets Qty. to Handle on an inventory movement Take line and its Place line. Never registers. |
| `POST putAwaySplits` | 50225 WMS Put-away Split API | Spreads one open Place line of an inventory put-away (from a purchase order) over one or more destination bins. Never posts. |

**Create a movement:**
```json
{
  "externalRequestKey": "repl-2026-11-02-0001",
  "createdBy": "jdoe",
  "locationCode": "MAIN",
  "linesJson": "[{\"itemNo\":\"1000\",\"variantCode\":\"\",\"fromBinCode\":\"BULK-01\",\"toBinCode\":\"FP-14-25\",\"quantityBase\":24}]"
}
```
The response returns `internalMovementNo`, `activityNo` and `responseJson`, which lists `sourceLineNo`, `itemNo`, `takeLineNo`, `placeLineNo` and `quantityBase` per created Take line.

**Set Qty. to Handle:**
```json
{
  "externalRequestKey": "qth-2026-11-02-0001",
  "createdBy": "jdoe",
  "activityNo": "IM000012",
  "takeLineNo": 10000,
  "qtyToHandleBase": 12,
  "expectedLastModifiedDateTime": "2026-11-02T17:05:00Z"
}
```
`expectedLastModifiedDateTime` is optional. When sent, the request fails if either line changed in BC after that time.

**Split an inventory put-away line over destination bins:**

Managers create the inventory put-aways from purchase orders in BC and post them there (posting also posts the purchase receipt). The app only reads the open put-away lines (`warehouseActivityLines` with `activityType eq 'Invt. Put-away'`) and redistributes a Place line across bins. Once a put-away is posted, move stock on with `POST movements` instead.

```json
{
  "externalRequestKey": "pa-2026-11-02-0001",
  "createdBy": "jdoe",
  "activityNo": "IPA000034",
  "lineNo": 10000,
  "allocationsJson": "[{\"binCode\":\"FP-14-25\",\"quantityBase\":12},{\"binCode\":\"BULK-01\",\"quantityBase\":36}]",
  "expectedLastModifiedDateTime": "2026-11-02T17:05:00Z"
}
```
- The `quantityBase` values must add up exactly to the line's Qty. Outstanding (Base), and each must be a whole number of the line's unit of measure (the purchase unit). Each bin may appear once and must not be blocked, dedicated or the adjustment bin.
- The first allocation stays on the original line; BC's Split Line creates a line for each further allocation, right after it, in request order.
- Qty. to Handle keeps the line's pattern: if it was 0 it stays 0 on every resulting line, if it was the full outstanding quantity each line gets its own full quantity. A partially set Qty. to Handle is rejected. Lines with lot, serial or package nos. are rejected.
- `expectedLastModifiedDateTime` is optional. When sent, the request fails if the line changed in BC after that time.

The response returns `sourceNo` (purchase order no.), `sourceLineNo`, `lastModifiedDateTime` and `responseJson`:
```json
{"activityNo":"IPA000034","sourceNo":"PO-1042","sourceLineNo":10000,"lines":[{"lineNo":10000,"binCode":"FP-14-25","quantityBase":12,"qtyToHandleBase":0},{"lineNo":15000,"binCode":"BULK-01","quantityBase":36,"qtyToHandleBase":0}],"lastModifiedDateTime":"2026-11-02T17:06:12.123Z"}
```

### Setup for the WMS commands

- **Inventory Setup:** Internal Movement Nos., Inventory Movement Nos. and Registered Invt. Movement Nos. must each point to a series with Default Nos. on.
- **Location:** Bin Mandatory on and Directed Put-away and Pick off.
- **Warehouse Employee:** the BC user that *makes the call* must be a Warehouse Employee at the location, or `POST movements` fails with `You cannot use Location Code ...`. For service-to-service calls that is the app registration's own BC user (see Microsoft Entra Applications); for delegated calls it is the signed-in user.
- **Permissions:** assign the **WMS Integration** permission set to that user.

`wmsDocumentRequests.workflowType` returns `Replenishment`, `QtyToHandle`, `BinLevels`, `BinSetup` or `PutAway` (later also `MissingBinFill`). For `BinSetup`, `targetId` is the Bin Content's SystemId, or the Bin's when no item was sent. For `PutAway`, `documentNo` is the purchase order no. and `activityNo` the inventory put-away no.

---

## Business Logic

### Bin Reassignment (`Codeunit 50208 — Assembly Line Bin Reassign`)

All bin reassignment operations:

1. Validate the target record exists by `SystemId`
2. Normalize the bin code input
3. Confirm the bin exists in the location defined on the source document

**ATO detection:** When reassigning an assembly line bin, the codeunit checks the Assemble-to-Order Link table. If the assembly order is ATO-linked:
- Updates the assembly line bin directly (bypasses AL validation to avoid "Request Data Invalid" errors from BC's internal ATO coupling)
- Re-syncs the parent sales line bin to maintain coupling consistency

Non-ATO assembly lines and all sales lines run the standard `Validate()` path for full bin availability checks.

---

## UI Integration

The extension adds a **"Reassign Bins"** action to the Sales Order page (Processing group, promoted as a Process action).

When triggered, it sends a POST request to the external order sync service:

```
POST https://order-sync-b0f1f2769abe.herokuapp.com/api/orders/reassignBins?orderNo={orderNo}
```

The response is displayed in a modal showing:
- Request ID and order identifier
- Summary counts (seen, updated)
- Any issues, each including item number, bin code, responsibility center, and message

---

## Object Index

| ID | Type | Name |
|---|---|---|
| 50201 | Page (API) | Bin Content API |
| 50202 | Page (API) | Bin Type API |
| 50203 | Page (API) | Zone API |
| 50204 | Page (API) | Sales Line API |
| 50205 | Page (API) | Assembly Link API |
| 50206 | Page (API) | Assembly Header API |
| 50207 | Page (API) | Assembly Line API |
| 50208 | Codeunit | Assembly Line Bin Reassign |
| 50209 | Table | Bin Reassignment Buffer |
| 50209 | Enum | Bin Reassignment Target Type |
| 50210 | Page (API) | Bin Reassignment API |
| 50211 | Page Extension | Sales Order Reassign Bins |
| 50217 | Table | WMS Bin Level Buffer |
| 50217 | Codeunit | WMS Bin Level Management |
| 50218 | Codeunit | WMS Bin Rules |
| 50219 | Page (API) | WMS Bin Level API |
| 50220 | Table | WMS Movement Buffer |
| 50221 | Table | WMS Qty. to Handle Buffer |
| 50220 | Codeunit | WMS Movement Management |
| 50221 | Codeunit | WMS Movement Events |
| 50220 | Table Extension | WMS Whse. Activity Line |
| 50221 | Table Extension | WMS Reg. Invt. Movement Line |
| 50222 | Table Extension | WMS Internal Movement Line |
| 50220 | Page (API) | WMS Movement API |
| 50221 | Page (API) | WMS Qty. to Handle API |
| 50222 | Page (API) | WMS Activity Line API |
| 50223 | Page (API) | WMS Reg. Invt. Mvmt. Line API |
| 50222 | Table | WMS Bin Setup Buffer |
| 50222 | Codeunit | WMS Bin Setup Management |
| 50224 | Page (API) | WMS Bin Setup API |
| 50223 | Table | WMS Put-away Split Buffer |
| 50223 | Codeunit | WMS Put-away Management |
| 50225 | Page (API) | WMS Put-away Split API |
| 50226 | Page (API) | WMS Posted Invt. PA Line API |
