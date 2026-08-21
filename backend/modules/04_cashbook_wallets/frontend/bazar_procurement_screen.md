# Screen: Bazar (Daily Market Procurement)

## 1. Description
Dedicated view for logging daily canteen market shopping (vegetables, meat, spices, groceries) and reviewing historical procurement costs.

* **Dart Files**: [bazar_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/bazar/bazar_screen.dart), [bazar_note_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/bazar_note_detail_screen.dart)

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Log Bazar Expense** | Tap "Add Bazar Cost" | Opens `AddExpenseBottomSheet` prefilled with category `bazar`. |
| **Inspect Itemized List** | Tap Bazar Card | Opens `BazarNoteDetailScreen` with breakdown of grocery items and costs. |

---

## 3. APIs Used

### Read: Fetch Bazar Expenses
* **Method**: Supabase query
* **Query**:
```dart
final records = await supabase
    .from('day_entries')
    .select('*, canteen_accounts(*)')
    .eq('category', 'bazar')
    .eq('tenant_id', tenantId)
    .order('created_at', ascending: false);
```
