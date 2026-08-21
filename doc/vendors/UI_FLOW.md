# Vendors & Accounts Payable — UI Flow

> **Module Blueprint**: [`VENDORS.md`](file:///Users/daviditc/Documents/personal_projects/smart-hisab/doc/vendors/VENDORS.md)

---

## Screen Map

```
VendorsScreen (Supplier Directory)
  ├── [Search by name / category]
  ├── [Swipe Left]   ─► Quick Settle Payment (RecordVendorPaymentBottomSheet)
  ├── [Swipe Right]  ─► Edit Vendor (AddVendorBottomSheet in edit mode)
  ├── [Tap Card]     ─► VendorDetailScreen
  └── [FAB / Header] ─► AddVendorBottomSheet

VendorDetailScreen
  ├── [CTA: Record Payment]   ─► RecordVendorPaymentBottomSheet
  ├── [CTA: Add Supply Baki]  ─► AddVendorBakiBottomSheet
  └── [Swipe on Entry Row]    ─► VoidTransactionBottomSheet
```

---

## Screen Flows & State Transitions

### 1. `VendorsScreen`

| State | UI |
| :--- | :--- |
| Loading | Shimmer vendor card list (4 rows) |
| Loaded | Vendor cards with name, category badge, outstanding balance chip |
| Searching | Debounced (300ms) local filter on name / category / phone |
| Empty | Empty state card with "Add First Supplier" CTA centered — **header button hidden** |

**Balance Chip**:
- `> 0` → red chip: "Owed: ৳2,500" (canteen owes vendor)
- `= 0` → green chip: "Settled"

**Pull-to-Refresh**: Calls `vendorsNotifierProvider.refresh()`.

---

### 2. `AddVendorBottomSheet`

> **Modal**: Rounded top `32px`. No close button.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Vendor Name | TextInput | 2–60 chars, required |
| Phone | TextInput | Optional; numeric |
| Address | TextInput | Optional |
| Category | Dropdown | Default: `general`; options: `general`, `grocery`, `dairy`, `meat`, `gas`, `other` |
| Opening Balance | NumericInput | `>= 0`; represents existing debt owed to vendor |

| Mode | CTA | Action |
| :--- | :--- | :--- |
| Add | "Add Supplier" | `.from('vendors').insert(...)` → trigger auto-creates `vendor_wallets` → prepend to list |
| Edit | "Save Changes" | `.from('vendors').update(...).eq('id', id)` → mutate local item |

---

### 3. `VendorDetailScreen`

| Section | Content |
| :--- | :--- |
| Header Card | Vendor name, category, phone, outstanding balance badge |
| Summary Row | Total Debit (Baki), Total Credit (Paid), Net Due |
| Statement Feed | Chronological ledger — debit rows (red) and credit rows (green) |
| Date Filter | Expandable date range picker — triggers `get_vendor_statement` re-fetch |

| State | UI |
| :--- | :--- |
| Loading | Shimmer on header + 5 skeleton statement rows |
| Loaded | Full detail view |
| Empty statement | "No transactions yet" message |

**Pull-to-Refresh**: Refreshes statement via `vendorDetailNotifierProvider.refresh()`.

---

### 4. `RecordVendorPaymentBottomSheet`

> **Modal**: Rounded top `32px`. No close button. Opens from both detail screen CTA and swipe quick-action.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Amount | NumericInput | `> 0`; warn if exceeds outstanding balance |
| Payment Account | Dropdown | Required — from `canteen_accounts` |
| Notes | TextInput | Optional |

**RPC**: `record_vendor_payment_v2(p_tenant_id, p_vendor_id, p_canteen_account_id, p_amount, p_business_day_id, p_notes)`

**Cache Mutations**:
1. Decrement `vendor_wallets.current_balance -= amount` in list + detail
2. Prepend credit entry row in `vendorDetailNotifierProvider`
3. Append expense row in `cashbookNotifierProvider`

---

### 5. `AddVendorBakiBottomSheet`

> **Modal**: Rounded top `32px`. No close button. Logs a credit purchase.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Amount | NumericInput | `> 0` |
| Category | Dropdown | Default: `supplies`; options: `supplies`, `adjustment` |
| Notes | TextInput | Optional (e.g., "Rice & Lentils batch") |

**API**: `.from('vendor_wallet_entries').insert({entry_type: 'debit', category: 'supplies', ...})`

**Cache Mutations**:
1. Increment `vendor_wallets.current_balance += amount`
2. Prepend debit row in `vendorDetailNotifierProvider`

---

### 6. `VoidTransactionBottomSheet`

> **Modal**: Rounded top `32px`. No close button. Triggered by swipe on entry row.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Void Reason | TextInput | Required; 5–200 chars |

**RPC**: `void_wallet_entry(p_entry_id, p_reason)`

**Cache Mutation**:
1. Set `is_voided = true` on row
2. Re-compute `vendor_wallets.current_balance` delta locally

---

## Entry Row Design

| Column | Content |
| :--- | :--- |
| Left icon | 🔴 (debit/baki) or 🟢 (credit/payment) |
| Label | Category name + notes snippet |
| Amount | Red for debit, green for credit |
| Date | Relative ("3d ago") or absolute |
| Account | Small badge for which canteen wallet was used |
| Voided | Strikethrough + "VOIDED" label |

---

## Validation Rules

| Field | Rule |
| :--- | :--- |
| Vendor Name | 2–60 characters, required |
| Opening Balance | `>= 0` |
| Payment Amount | `> 0`; warn if exceeds outstanding balance |
| Supply Baki Amount | `> 0` |
| Void Reason | Required; 5–200 characters |
