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
