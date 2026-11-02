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
| `binContents` | Bin Content | Bin inventory levels by location, zone, item, and variant |
| `binTypes` | Bin Type | Bin type master (receive, ship, put-away, pick flags) |
| `zones` | Zone | Warehouse zone master data |
| `assemblyLinks` | Assemble-to-Order Link | ATO linkage between assembly headers and sales lines |
| `assemblyHeaders` | Assembly Header | Full assembly order header data including bin code, quantities, and dates |
| `warehouseActivityLines` | Warehouse Activity Line | Open activity lines (Take/Place pairs) with qty. to handle/outstanding/handled and the WMS internal movement link fields |
| `registeredInvtMovementLines` | Registered Invt. Movement Line | Registered inventory movement lines with the original inventory movement no., registering date and the WMS link fields |

### Editable Endpoints

| Endpoint | Source Table | Editable Fields |
|---|---|---|
| `salesLine_wBins` | Sales Line | `binCode` — triggers ATO sync on change |
| `assemblyLines` | Assembly Line | `binCode` — triggers ATO sync on change |

### Command Endpoint

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

### WMS Movement Commands

Both commands are retry-safe: the same `externalRequestKey` with the same payload replays the first response (see `wmsDocumentRequests`). Quantities are in base units. Nothing is committed unless the whole request succeeds.

| Endpoint | Page | Description |
|---|---|---|
| `POST movements` | 50220 WMS Movement API | Creates an Internal Movement and turns it into an Inventory Movement. Fails as a whole if any source bin is short or an item uses warehouse lot/serial/package tracking. |
| `POST qtyToHandles` | 50221 WMS Qty. to Handle API | Sets Qty. to Handle on an inventory movement Take line and its Place line. Never registers. |

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
