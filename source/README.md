# Mi-Pod Bin Locations Extension

The Mi-Pod Bin Locations extension intends to enhance productivity with Bin Contents within Business Central.

---

## Bin Content Schema

### Schema Definitions

| Field                  | Type                  | Required | Title                     | Description                                                                                            |
| ---------------------- | --------------------- | -------- | ------------------------- | ------------------------------------------------------------------------------------------------------ |
| `ItemInternalId`       | `guid` (string)       | ✅       | Item Internal Id          | Internal BC SystemId of the **Item record**. Useful for joins across APIs without relying on `itemNo`. |
| `id`                   | `guid` (string)       | ✅       | System Id                 | Unique identifier for this Bin Content record (`SystemId`). Stable primary key for API usage.          |
| `locationCode`         | `string`              | ✅       | Location Code             | Warehouse location identifier where the bin exists (e.g., `AZ-WHSE-01`).                               |
| `zoneCode`             | `string`              | ❌       | Zone Code                 | Logical grouping of bins within a location (e.g., PICK, BULK, RECEIVING). Empty if not used.           |
| `binCode`              | `string`              | ✅       | Bin Code                  | Physical bin identifier (e.g., aisle/shelf/bin like `AP-10-16`).                                       |
| `itemNo`               | `string`              | ✅       | Item Number               | Business-facing item identifier (SKU).                                                                 |
| `variantCode`          | `string`              | ❌       | Variant Code              | Variant of the item (size, color, etc.). Empty if not applicable.                                      |
| `unitOfMeasureCode`    | `string`              | ✅       | Unit of Measure Code      | Unit used for this bin content entry (e.g., `EA`, `BOX`).                                              |
| `quantityBase`         | `number` (decimal)    | ✅       | Quantity Base             | Quantity in **base unit of measure**. This is the most reliable quantity for calculations.             |
| `fixed`                | `boolean`             | ✅       | Fixed                     | Indicates this bin is a **fixed bin** for the item (preferred storage location).                       |
| `defaultBin`           | `boolean`             | ✅       | Default Bin               | Indicates this bin is the **default bin** for the item in this location.                               |
| `dedicated`            | `boolean`             | ✅       | Dedicated                 | Indicates this bin is **reserved exclusively** for this item.                                          |
| `binRanking`           | `integer`             | ❌       | Bin Ranking               | Priority ranking used by BC for put-away/pick logic. Lower = higher priority.                          |
| `blockMovement`        | `string (enum)`       | ❌       | Block Movement            | Controls whether inbound/outbound movement is blocked for this bin content.                            |
| `lastModifiedDateTime` | `datetime (ISO 8601)` | ✅       | Last Modified (timestamp) | Timestamp of last modification (`SystemModifiedAt`). Used for delta sync.                              |

### 🧾 Example (Cleaned + Production Ready)

```json
{
  "ItemInternalId": "989cffbc-9f11-f111-8405-6045bdd9e4dd",
  "id": "989cffbc-9f11-f111-8405-6045bdd9e4dd",
  "locationCode": "AZ-WHSE-01",
  "zoneCode": "",
  "binCode": "AP-10-16",
  "itemNo": "57229",
  "variantCode": "",
  "unitOfMeasureCode": "EA",
  "quantityBase": 15,
  "fixed": true,
  "defaultBin": true,
  "dedicated": false,
  "binRanking": 0,
  "blockMovement": "None",
  "lastModifiedDateTime": "2026-02-24T16:42:06.04Z"
}
```

---

## Bin Type Schema

### Schema Definitions

| Field                  | Type                  | Required | Title                     | Description                                                                 |
| ---------------------- | --------------------- | -------- | ------------------------- | --------------------------------------------------------------------------- |
| `id`                   | `guid` (string)       | ✅       | System Id                 | Unique identifier for this Bin Type record (`SystemId`).                    |
| `code`                 | `string`              | ✅       | Code                      | Unique bin type code used throughout warehouse setup.                       |
| `description`          | `string`              | ❌       | Description               | Human-readable name for the bin type.                                       |
| `receive`              | `boolean`             | ✅       | Receive                   | Indicates the bin type is used for receiving bins.                          |
| `ship`                 | `boolean`             | ✅       | Ship                      | Indicates the bin type is used for shipping bins.                           |
| `putAway`              | `boolean`             | ✅       | Put Away                  | Indicates the bin type is used for put-away activity.                       |
| `pick`                 | `boolean`             | ✅       | Pick                      | Indicates the bin type is used for picking activity.                        |
| `lastModifiedDateTime` | `datetime (ISO 8601)` | ✅       | Last Modified (timestamp) | Timestamp of last modification (`SystemModifiedAt`). Used for delta sync.   |

### Example

```json
{
  "id": "86a6b94d-6f09-f011-bae3-6045bd123456",
  "code": "PICK",
  "description": "Picking Bin",
  "receive": false,
  "ship": false,
  "putAway": false,
  "pick": true,
  "lastModifiedDateTime": "2026-03-30T20:25:41.15Z"
}
```

---

## Zone Schema

### Schema Definitions

| Field                  | Type                  | Required | Title                     | Description                                                                          |
| ---------------------- | --------------------- | -------- | ------------------------- | ------------------------------------------------------------------------------------ |
| `id`                   | `guid` (string)       | ✅       | System Id                 | Unique identifier for this Zone record (`SystemId`).                                 |
| `locationCode`         | `string`              | ✅       | Location Code             | Warehouse location that owns the zone.                                               |
| `code`                 | `string`              | ✅       | Code                      | Unique zone code within the location.                                                |
| `description`          | `string`              | ❌       | Description               | Human-readable name for the zone.                                                    |
| `binTypeCode`          | `string`              | ❌       | Bin Type Code             | Default bin type assigned to the zone.                                               |
| `warehouseClassCode`   | `string`              | ❌       | Warehouse Class Code      | Warehouse class restriction applied to the zone.                                     |
| `specialEquipmentCode` | `string`              | ❌       | Special Equipment Code    | Special equipment associated with work in this zone.                                 |
| `zoneRanking`          | `integer`             | ✅       | Zone Ranking              | Ranking copied to bins created within the zone and used in warehouse logic.          |
| `crossDockBinZone`     | `boolean`             | ✅       | Cross-Dock Bin Zone       | Indicates whether the zone is designated for cross-dock bins.                        |
| `lastModifiedDateTime` | `datetime (ISO 8601)` | ✅       | Last Modified (timestamp) | Timestamp of last modification (`SystemModifiedAt`). Used for delta sync.            |

### Example

```json
{
  "id": "d5b1c24a-7109-f011-bae3-6045bd123456",
  "locationCode": "AZ-WHSE-01",
  "code": "PICK",
  "description": "Primary Picking Zone",
  "binTypeCode": "PICK",
  "warehouseClassCode": "",
  "specialEquipmentCode": "",
  "zoneRanking": 100,
  "crossDockBinZone": false,
  "lastModifiedDateTime": "2026-03-30T20:58:12.04Z"
}
```

---

## Bin Content Behaviors

### 📍 Bin Behavior Flags

#### `fixed`

- Item _should_ live here
- Used by put-away logic

#### `defaultBin`

- Primary bin for item lookups
- Often used by:
  - sales picks
  - quick inventory checks

#### `dedicated`

- No other items should exist in this bin
- Violations = **exception condition**

---

### 🚫 `blockMovement` (Enum Recommendation)

BC uses a Code field here, but you should normalize it in your API.

#### Suggested enum mapping:

| Value         | Meaning                  |
| ------------- | ------------------------ |
| `"None"`      | No restriction           |
| `"Inbound"`   | Cannot receive inventory |
| `"Outbound"`  | Cannot pick inventory    |
| `"All"`       | Fully blocked            |
| `""` or `" "` | Treat as `"None"`        |

👉 Normalize this in your API layer for sanity.

---

### ⏱️ `lastModifiedDateTime`

- Format: ISO 8601 UTC
- Used for:
  - incremental sync
  - cache invalidation
  - change tracking

Example:

```json
"2026-02-24T16:42:06.04Z"
```

---

## Potential Fields

#### Computed Fields (API Only)

```json
    "availableQty": number
    "reservedQty": number
    "blockedQty": number
    "utilizationPercent": number
    "daysSinceMovement": number
```

---

#### Analytics Flags

```json
    "isStale": boolean
    "isOverCapacity": boolean
    "hasException": boolean
```

---
