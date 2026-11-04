# Bin Location Extension

**Publisher:** Mi-One Brands  
**Version:** 1.3.0.0  
**Platform:** Business Central 27.0 or later (runtime 16.0)

A Business Central AL extension that exposes warehouse data through OData APIs for the Mi-One WMS (Pick-Ticket-Server). It provides:
- Read APIs for bins, locations, bin contents and warehouse documents.
- Retry-safe command APIs to set up bins, maintain Min/Max levels, create movements and split put-aways.
- Bin assignment for sales orders and assembly orders, with special handling for Assemble-to-Order (ATO).

---

## Features

- **Warehouse master data APIs:** read access to bins (including empty ones), locations and their warehouse settings, bin contents, bin types and zones.
- **Bin setup:** create a missing bin from a template bin, and make an item Fixed or Default in a bin.
- **Replenishment rules:** read and write Bin Content Min. Qty. and Max. Qty.
- **Internal movements:** create an Internal Movement and its Inventory Movement in one call, and set Qty. to Handle. Managers register the movements in BC.
- **Inventory put-away splits:** spread an open put-away line over several destination bins. Managers post the put-aways in BC.
- **Retry-safe commands:** every WMS command is recorded under its external request key. A retry replays the first response instead of doing the work twice.
- **Sales line and assembly line bin assignment:** update bin codes through the API. ATO links are kept in sync.
- **UI additions:** a "Reassign Bins" action on the Sales Order page, Total Available Bins on the item card and list, and Item Description on the Bin Contents page.

---

## API Endpoints

All endpoints are under:

```
/api/mioneBrands/warehouse/v1.0/companies({id})/
```

### Read endpoints

| Endpoint | Source table | Description |
|---|---|---|
| `bins` | Bin | Bin master records, including empty bins that have no Bin Content: zone, bin type, warehouse class, Block Movement, Dedicated, Default, Cross-Dock, adjustment bin flag, Empty, ranking, capacity. A bin missing from `binContents` still exists in BC; check here. |
| `locations` | Location | Warehouse settings the app needs to pick a document flow: Bin Mandatory, Directed Put-away and Pick, Require Receive/Put-away/Shipment/Pick, bin policies, and the special bin codes (receipt, shipment, adjustment, assembly, cross-dock). |
| `binContents` | Bin Content | Bin contents by location, zone, item and variant, including quantities, `minQty` and `maxQty`. |
| `binTypes` | Bin Type | Bin type master (receive, ship, put-away and pick flags). |
| `zones` | Zone | Warehouse zones. |
| `warehouseActivityLines` | Warehouse Activity Line | Open activity lines (Take/Place pairs) with Qty. to Handle, outstanding and handled quantities, the source document fields (`sourceType`, `sourceSubtype`, `sourceNo`, `sourceLineNo`, `sourceDocument`, `dueDate`) and the WMS internal movement link fields. |
| `registeredInvtMovementLines` | Registered Invt. Movement Line | Registered inventory movement lines with the original inventory movement no., registering date and the WMS link fields. |
| `postedInvtPutAwayLines` | Posted Invt. Put-away Line | Posted inventory put-away lines with the purchase order (`sourceNo` / `sourceLineNo`), bin, quantities, and, from the header, the original inventory put-away no., posted receipt no. and posting date. |
| `binShipments` | Warehouse Entry (query) | Units shipped out of each bin per day: net base quantity of sales order shipments and assembly consumption, one row per location, bin, item, variant and registering date (negative = out of the bin). Filter on `locationCode` and `registeringDate`. Used for level suggestions. |
| `wmsDocumentRequests` | WMS Document Request | Every processed WMS command with its key, workflow type, document links and stored response (see [Request tracking](#request-tracking-and-retries)). |
| `assemblyLinks` | Assemble-to-Order Link | ATO links between assembly headers and sales lines. |
| `assemblyHeaders` | Assembly Header | Assembly order headers, including bin code, quantities and dates. |

BC's own enums come back encoded, e.g. `activityType` = `Invt_x002E__x0020_Movement`. Filter on `actionType`, `activityNo` or `sourceNo` instead.

### Editable endpoints

| Endpoint | Source table | Editable fields |
|---|---|---|
| `salesLine_wBins` | Sales Line | `binCode`; a change triggers the ATO sync |
| `assemblyLines` | Assembly Line | `binCode`; a change triggers the ATO sync |

### Command endpoints

Each command is a `POST` to a temporary buffer table; nothing is stored in the buffer.

| Endpoint | Page | Description |
|---|---|---|
| `binReassignments` | 50210 Bin Reassignment API | Assign a bin to a sales line or an assembly line. |
| `binLevels` | 50219 WMS Bin Level API | Set Min. Qty. and Max. Qty. on a Bin Content, creating a Fixed Bin Content if none exists. |
| `binSetups` | 50224 WMS Bin Setup API | Create a missing bin from a template bin, and/or make an item Fixed or Default in a bin. |
| `movements` | 50220 WMS Movement API | Create an Internal Movement and turn it into an Inventory Movement. |
| `qtyToHandles` | 50221 WMS Qty. to Handle API | Set Qty. to Handle on an inventory movement Take line and its Place line, or on an inventory put-away Place line. |
| `putAwaySplits` | 50225 WMS Put-away Split API | Spread one open Place line of an inventory put-away over several destination bins. |

---

## Rules shared by the WMS commands

These apply to `binLevels`, `binSetups`, `movements`, `qtyToHandles` and `putAwaySplits`.

### Request tracking and retries

- **`externalRequestKey` is required.** The first successful request is recorded in `WMS Document Request` (table 50216) with a hash of its payload and its response.
- **Retries replay:** the same key with the same payload returns the stored response without doing the work again. The same key with a different payload, or for a different command, is refused.
- **Timeouts:** after a timeout, look the request up with `GET .../wmsDocumentRequests?$filter=externalRequestKey eq '{key}'`.
- **All or nothing:** nothing is committed unless the whole request succeeds.
- **`createdBy`** is stored for reference only and is not part of the payload hash.

`wmsDocumentRequests.workflowType` returns one of the following (`MissingBinFill` is reserved):

| Workflow type | Command | `documentNo` | `activityNo` | `targetId` |
|---|---|---|---|---|
| `BinLevels` | `binLevels` | n/a | n/a | Bin Content SystemId |
| `BinSetup` | `binSetups` | n/a | n/a | Bin Content SystemId, or the Bin's when no item was sent |
| `Replenishment` | `movements` | internal movement no. | inventory movement no. | inventory movement SystemId |
| `QtyToHandle` | `qtyToHandles` | internal movement no. | inventory movement no. | Take line SystemId |
| `PutAway` | `putAwaySplits` | purchase order no. | inventory put-away no. | the line's SystemId before the split |

### No fractional quantities

Every quantity sent to a WMS command must be a whole number of the line's unit of measure, whatever the unit's Qty. Rounding Precision says. That covers `quantityBase` on `movements` and `putAwaySplits`, `qtyToHandleBase`, and `minQty`/`maxQty`. Anything else is refused with an error naming the field and value; nothing is rounded. Quantities ending in `Base` are in the item's base unit.

### Bin checks

In `binLevels`, `binSetups` (with an item) and `putAwaySplits`, the target bin must exist, must not have Block Movement set, must not be Dedicated and must not be the location's adjustment bin. `movements` only checks that both bins exist.

---

## Commands

### `POST binReassignments`

Assign a bin to a sales line or an assembly line by SystemId.

```json
{ "targetType": "AssemblyLine", "assemblyLineId": "{assembly-line-system-id}", "newBinCode": "FP-14-25" }
```
```json
{ "targetType": "SalesLine", "salesLineId": "{sales-line-system-id}", "newBinCode": "FP-14-25" }
```

The response has a `result` field with a confirmation message. This command is not tracked in `wmsDocumentRequests`.

### `POST binLevels`

Set the replenishment Min/Max for an item in a bin.

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

- **Required:** `externalRequestKey`, `locationCode`, `binCode`, `itemNo`, `minQty` and `maxQty`.
- **Defaults:** `unitOfMeasureCode` is the item's base unit, `fixed` is `true`, `allowOtherFixedItem` is `false`.
- **Clearing a rule:** send `minQty` 0 and `maxQty` 0. The Bin Content is kept.
- **Quantities:** `minQty` and `maxQty` are in the Bin Content's unit of measure. Stock quantities in the bin are never changed.
- **Refused when:**
  - the bin fails the [bin checks](#bin-checks)
  - `minQty` is greater than `maxQty`
  - either value is negative or not a whole number
- **Shared Fixed bins:** if the item isn't already Fixed in the bin and another item or variant is, the request fails unless `allowOtherFixedItem` is `true`. In a bin already shared by several Fixed items, each item's levels can always be set.

The response echoes the stored values plus `binContentId`, `lastModifiedDateTime` and `result`.

### `POST binSetups`

Create a bin that doesn't exist yet, and/or assign an item to a bin.

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

Only `externalRequestKey`, `locationCode` and `binCode` are always required. Defaults:
- `unitOfMeasureCode` is the item's base unit.
- `fixed` is `true`.
- `default`, `replaceDefault` and `allowOtherFixedItem` are `false`.

The response carries the request fields plus:
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

**Location:** must be Bin Mandatory and must not use Directed Put-away and Pick.

**New bin:** if `binCode` doesn't exist, `templateBinCode` is required. The template must be a bin in the same location that isn't Dedicated and isn't the adjustment bin.
- The new bin copies Zone Code, Bin Type Code, Warehouse Class Code, Bin Ranking, Special Equipment Code, Maximum Cubage, Maximum Weight and Cross-Dock Bin from the template.
- It gets `description` (blank if not sent). It is never blocked or Dedicated.

**Existing bin:** never changed. `templateBinCode` and `description` are ignored, and `binCreated` is `false`.

**No `itemNo`:** only the bin is set up. `binContentId` is `null`, and `fixed` and `default` are `false`. Sending `variantCode`, `unitOfMeasureCode` or `default: true` without `itemNo` fails.

**With `itemNo`:**
- The item must be of type Inventory, and the variant and unit of measure must exist.
- The bin must pass the [bin checks](#bin-checks).
- If `fixed` or `default` is requested and another item or variant is already Fixed in the bin, the request fails unless `allowOtherFixedItem` is `true`.

**Bin Content:** created if missing, with the requested flags. On an existing Bin Content the requested flags are only added: Fixed and Default are never cleared, and quantities never change. `fixed` and `default` in the response are the Bin Content's flags after the request.

**Default:** BC proposes an item's Default bin on purchase lines, sales lines and put-aways, and allows only one per item and variant per location.
- If another bin is already the Default, the request fails and names that bin.
- With `replaceDefault` `true`, that bin loses its Default, and `defaultMovedFromBinCode` names it.

### `POST movements`

Create an Internal Movement and turn it into an Inventory Movement, in one transaction.

```json
{
  "externalRequestKey": "repl-2026-11-02-0001",
  "createdBy": "jdoe",
  "locationCode": "MAIN",
  "linesJson": "[{\"itemNo\":\"1000\",\"variantCode\":\"\",\"fromBinCode\":\"BULK-01\",\"toBinCode\":\"FP-14-25\",\"quantityBase\":24}]"
}
```

- Each line's `quantityBase` is in whole base units.
- `fromBinCode` and `toBinCode` must be different bins that both exist.
- **Stock:** availability is checked before the movement is created, counting other lines that take from the same bin content. The created Take quantities are checked afterwards. Any shortfall fails the whole request, and nothing is created.
- **Tracking:** items with warehouse lot, serial or package tracking are refused.
- **Internal movement:** BC deletes it once the inventory movement covers it fully, so the returned `internalMovementNo` is a reference only.

The response returns `internalMovementNo`, `activityNo` and `responseJson`. `responseJson` lists `sourceLineNo`, `itemNo`, `takeLineNo`, `placeLineNo` and `quantityBase` for each created Take line.

Every inventory movement line created from an internal movement is stamped with `wmsInternalMovementNo` and `wmsSourceLineNo`, including movements made by hand in BC. The stamp carries over to the registered lines. Managers register the movements in BC.

### `POST qtyToHandles`

Set Qty. to Handle on an inventory movement Take line and its paired Place line. It never registers anything.

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

- `qtyToHandleBase` must be 0 or more, a whole number of the lines' unit of measure, and no more than the outstanding quantity.
- `expectedLastModifiedDateTime` is optional. When it is sent, the request fails if either line changed in BC after that time.

The response returns `placeLineNo`, `qtyToHandleBase`, `qtyOutstandingBase`, `qtyHandledBase` and `lastModifiedDateTime`.

**Inventory put-aways.** When `activityNo` / `takeLineNo` is not an inventory movement Take line, the API looks for an **inventory put-away** line instead. It must be a Place line (put-aways from purchase orders have no Take lines); only that line is set. The same rules apply: whole units of the line's unit of measure, no more than outstanding, `expectedLastModifiedDateTime` checked against the line, retries replay. The response's `takeLineNo` and `placeLineNo` are both that line. It never posts the put-away.

### `POST putAwaySplits`

Spread one open Place line of an inventory put-away (from a purchase order) over one or more destination bins. It never posts anything.

Managers create the inventory put-aways from purchase orders in BC and post them there; posting also posts the purchase receipt. The app reads the open lines (`warehouseActivityLines` with `sourceNo eq '{purchase order no.}'`) and redistributes a Place line across bins. Once a put-away is posted, move the stock on with `POST movements`.

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

- **Quantities:** the `quantityBase` values must add up exactly to the line's Qty. Outstanding (Base). Each must be a whole number of the line's unit of measure, which is the purchase unit.
- **Bins:** each bin may appear only once and must pass the [bin checks](#bin-checks).
- **Line order:** the first allocation stays on the original line. BC's Split Line creates a line for each further allocation right after it, in request order. BC may renumber the put-away's lines to make room, so use the line nos. in the response.
- **Qty. to Handle:** the line's pattern is kept. If it was 0, every resulting line gets 0. If it was the full outstanding quantity, each line gets its own full quantity.
- **Refused lines:** lines with a partly set Qty. to Handle, and lines carrying a lot, serial or package no.
- **Source:** only lines from purchase orders are supported.
- `expectedLastModifiedDateTime` is optional. When it is sent, the request fails if the line changed in BC after that time.

The response returns `sourceNo` (the purchase order no.), `sourceLineNo`, `lastModifiedDateTime` and `responseJson`:
```json
{"activityNo":"IPA000034","sourceNo":"PO-1042","sourceLineNo":10000,"lines":[{"lineNo":10000,"binCode":"FP-14-25","quantityBase":12,"qtyToHandleBase":0},{"lineNo":15000,"binCode":"BULK-01","quantityBase":36,"qtyToHandleBase":0}],"lastModifiedDateTime":"2026-11-02T17:06:12.123Z"}
```

---

## Setup

- **Location:** Bin Mandatory on, Directed Put-away and Pick off. For put-away splits, Require Put-away is on and Require Receive is off, so inventory put-aways are used.
- **Inventory Setup:** each of the following must point to a number series with Default Nos. on:
  - Internal Movement Nos.
  - Inventory Movement Nos.
  - Registered Invt. Movement Nos.
  - Inventory Put-away Nos.
  - Posted Invt. Put-away Nos.
- **Warehouse Employee:** the BC user that *makes the call* must be a Warehouse Employee at the location. Otherwise `POST movements` fails with `You cannot use Location Code ...`.
  - For service-to-service calls this is the app registration's own BC user (see Microsoft Entra Applications).
  - For delegated calls it is the signed-in user.
- **Permissions:** assign the **WMS Integration** permission set (50216) to that user. It covers the WMS APIs and the warehouse tables they read and write.

---

## Business Logic

### Bin reassignment (codeunit 50208, Assembly Line Bin Reassign)

Every bin reassignment:
1. Finds the target record by `SystemId`.
2. Normalizes the bin code.
3. Checks that the bin exists in the location on the source document.

**ATO detection:** when an assembly line's bin is reassigned, the codeunit checks the Assemble-to-Order Link table. If the assembly order is linked to a sales line:
- It updates the assembly line bin directly, without validation. This avoids "Request Data Invalid" errors from BC's internal ATO coupling.
- It re-syncs the bin on the parent sales line.

Assembly lines without an ATO link, and all sales lines, go through the standard `Validate()` path with full bin availability checks.

### WMS command logic

| Codeunit | Responsibility |
|---|---|
| 50216 WMS Request Management | Payload hashing, replay lookup and request registration |
| 50217 WMS Bin Level Management | `binLevels` |
| 50218 WMS Bin Rules | Shared bin checks, the Fixed-bin guard, item/variant/UOM checks and the whole-quantity rule |
| 50220 WMS Movement Management | `movements` and `qtyToHandles` |
| 50221 WMS Movement Events | Stamps the internal movement link on new inventory movement lines |
| 50222 WMS Bin Setup Management | `binSetups` |
| 50223 WMS Put-away Management | `putAwaySplits` |

None of them call `Commit`.

---

## UI Integration

- **Sales Order → Reassign Bins** (Processing group). Posts the order to the external order sync service:
  ```
  POST https://order-sync-b0f1f2769abe.herokuapp.com/api/orders/reassignBins?orderNo={orderNo}
  ```
  The response appears in a dialog with the request ID, the order, summary counts (seen, updated) and any issues. Each issue shows the item no., bin code, responsibility center and message.
- **Item Card / Item List → Total Available Bins:** the number of Bin Content records for the item.
- **Bin Contents → Item Description:** the item's description, shown next to Item No.

---

## Build and Deploy

- **Build:** with the VS Code AL extension, or headless with its `alc.exe`, using the Business Central symbols in `.alpackages`.
- **Development sandbox:** publish with Ctrl+F5. The app is installed in developer scope there, so no version bump is needed. A sandbox BC upgrade removes developer-scope apps, so republish after one.
- **Production:** bump `version` in `app.json`, then upload the `.app` as a per-tenant extension (Extension Management → Upload). Release builds are attached to the GitHub releases.

---

## Object Index

ID range: 50201–50249 (BigCommerce uses 50250 and up).

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
| 50212 | Page Extension | Bin Contents Item Description |
| 50213 | Table Extension | Item Total Bins Ext |
| 50214 | Page Extension | Item List Total Bins Ext |
| 50215 | Page Extension | Item Card Total Bins Ext |
| 50216 | Table | WMS Document Request |
| 50216 | Codeunit | WMS Request Management |
| 50216 | Enum | WMS Workflow Type |
| 50216 | Page (API) | WMS Bin API |
| 50216 | Permission Set | WMS Integration |
| 50217 | Table | WMS Bin Level Buffer |
| 50217 | Codeunit | WMS Bin Level Management |
| 50217 | Page (API) | WMS Location API |
| 50218 | Codeunit | WMS Bin Rules |
| 50218 | Page (API) | WMS Document Request API |
| 50219 | Page (API) | WMS Bin Level API |
| 50220 | Table | WMS Movement Buffer |
| 50220 | Codeunit | WMS Movement Management |
| 50220 | Page (API) | WMS Movement API |
| 50220 | Table Extension | WMS Whse. Activity Line |
| 50221 | Table | WMS Qty. to Handle Buffer |
| 50221 | Codeunit | WMS Movement Events |
| 50221 | Page (API) | WMS Qty. to Handle API |
| 50221 | Table Extension | WMS Reg. Invt. Movement Line |
| 50222 | Table | WMS Bin Setup Buffer |
| 50222 | Codeunit | WMS Bin Setup Management |
| 50222 | Page (API) | WMS Activity Line API |
| 50222 | Table Extension | WMS Internal Movement Line |
| 50223 | Table | WMS Put-away Split Buffer |
| 50223 | Codeunit | WMS Put-away Management |
| 50223 | Page (API) | WMS Reg. Invt. Mvmt. Line API |
| 50224 | Page (API) | WMS Bin Setup API |
| 50225 | Page (API) | WMS Put-away Split API |
| 50226 | Page (API) | WMS Posted Invt. PA Line API |
| 50227 | Query (API) | WMS Bin Shipment API |
