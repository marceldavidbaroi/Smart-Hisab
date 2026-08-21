# Modal: Manage Meal Subscriptions

## 1. Description
Modal bottom sheet to configure which meal shifts (Breakfast, Lunch, Dinner) a customer is actively subscribed to.

* **Dart File**: [manage_meal_subscription_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/manage_meal_subscription_bottom_sheet.dart)
* **Riverpod Providers**: `customersNotifierProvider`, `customerDetailNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Toggle Shift Subscription** | Tap Shift Checkbox | Modifies `subscribed_shifts` UUID array. |
| **Save Subscriptions** | Tap "Save Subscriptions" | Updates customer record in Supabase and updates local cache. |

---

## 3. APIs Used

### Mutation API: Update Subscribed Shifts
* **Method**: Supabase update
* **Query**:
```dart
await supabase
    .from('customers')
    .update({'subscribed_shifts': selectedShiftIds})
    .eq('id', customerId);
```
* **Target Local Cache Mutation**:
  * Updates `customer.subscribedShifts` list in `customersNotifierProvider`.
