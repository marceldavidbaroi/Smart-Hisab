# Screen: Home Dashboard (POS & Operations Hub)

## 1. Description
The main operational command center of the canteen. Shows dynamic celestial background animation based on current time/shift, active business day status, live shift stats, onboarding checklist, yesterday recap, and quick triggers for fast POS meal punching.

* **Dart File**: [home_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/home_screen.dart)

---

## 2. Initial Load & Riverpod State

### A. Initial Fetch APIs
1. **Fetch Active Business Day**:
   * **RPC**: `get_active_business_day(p_tenant_id: "uuid")`
   * **Response**:
```json
{
  "active": true,
  "id": "8f3b6a9c-0000-0000-0000-000000000001",
  "opening_balance": 1500.00,
  "opened_at": "2026-08-21T06:00:00Z",
  "status": "open",
  "notes": "Morning float"
}
```
2. **Fetch Current Active Shift**:
   * **RPC**: `get_current_shift(p_tenant_id: "uuid")`
   * **Response**:
```json
{
  "found": true,
  "id": "33a1b2c3-0000-0000-0000-000000000001",
  "name": "Lunch",
  "start_time": "11:00:00",
  "end_time": "16:00:00"
}
```

### B. Riverpod State
* **Provider Name**: `businessDayNotifierProvider`
* **Type**: `AsyncNotifier<BusinessDayState>` (Stores `isOpen`, `businessDayId`, `openingBalance`, `currentShift`)
* **Local Cache**: Hive Box `business_day_cache_<tenant_id>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Start Business Day** | Tap "Start Day" CTA | `startDay(openingFloat, notes)` | `start_business_day` | Sets `isOpen = true`, `businessDayId = id`, `openingBalance = float` immediately. |
| **Close Business Day** | Tap "Close Day" button | `closeDay(actualCash, notes)` | `end_business_day` | Sets `isOpen = false`, `businessDayId = null`. |
| **Quick Meal Punch** | Tap "Record Meal" / shift badge | `recordMealPunch(...)` | `record_meal_attendance` | Increments shift meal counter; updates customer debt balance. |
| **Verify Staff PIN** | Supervisor PIN Dialog | `verifyPin(pin)` | `verify_staff_pin` | Authorizes override / cashier switch. |
| **Pull to Refresh** | Pull down list | `refreshDayState()` | `get_active_business_day` | Silently updates state from backend. |

---

## 4. Complete API & RPC Specifications

### 1. `start_business_day`
* **Method**: `supabase.rpc('start_business_day', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_opening_balance": 1500.00,
  "p_notes": "Morning float"
}
```
* **Response**:
```json
{
  "success": true,
  "business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "opening_balance": 1500.00,
  "opened_at": "2026-08-21T06:00:00Z"
}
```

### 2. `record_meal_attendance`
* **Method**: `supabase.rpc('record_meal_attendance', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "p_shift_id": "33a1b2c3-0000-0000-0000-000000000001",
  "p_rate": 60.00,
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001"
}
```
* **Response**:
```json
{
  "success": true,
  "attendance_id": "77a8b9c0-0000-0000-0000-000000000001",
  "customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "rate": 60.00,
  "meal_date": "2026-08-21"
}
```
