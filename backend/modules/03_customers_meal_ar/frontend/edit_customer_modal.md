# Modal: Edit Customer

## 1. Description
Modal bottom sheet to edit existing customer details (name, phone, email, address, or active status).

* **Dart File**: [edit_customer_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/edit_customer_bottom_sheet.dart)
* **Riverpod Providers**: `customersNotifierProvider`, `customerDetailNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Update Customer** | Tap "Save Changes" button | Updates customer record in database and updates local state. |

---

## 3. APIs Used

### Mutation API: Update Customer
* **Method**: Supabase update
* **Query**:
```dart
await supabase
    .from('customers')
    .update({
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    })
    .eq('id', customerId);
```
* **Target Local Cache Mutation**:
  * Locates customer by `id` in `customersNotifierProvider` and replaces item.
  * Updates `customerDetailNotifierProvider` state.
