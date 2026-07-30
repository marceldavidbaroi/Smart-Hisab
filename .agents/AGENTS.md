# Project Rules & Customization Constraints

This file outlines the core rules and constraints that the AI agent must adhere to when working on this project.

## UI/UX & Frontend Architecture (Quasar Framework v2 / Vue 3)

### 1. Component Density & Elevation
* Avoid flat, stark white designs and heavy, default shadows. Use `flat` or `unelevated` classes on components paired with clean border classes (e.g. `bordered`) for modern, subtle definition.
* Always utilize the `dense` prop on enterprise elements (data tables, forms, selection boxes, lists, buttons) to maximize visibility and density without sacrificing clarity.

### 2. Color Theory & Design Tokens
* **Strict Constraint**: Do not hardcode HEX or RGB values in Vue component templates.
* Use Quasar dynamic design utility classes (e.g., `text-primary`, `bg-grey-1`, `text-subtitle2`, `text-weight-medium`).
* Maintain high color contrast under both Light and Dark modes. Utilize standard backgrounds like `bg-grey-2` or dynamic grey backgrounds to provide rich contrast against white/dark container cards.

### 3. Spacing Integrity & Layout safety
* Use Quasar spacing multipliers exclusively (`q-pa-xs`, `q-pa-sm`, `q-pa-md`, `q-col-gutter-md`) to maintain layout rhythm.
* **Strict Constraint**: Never combine margins/paddings directly on structural layout nodes (such as `QLayout`, `QPageContainer`, `QDrawer`). Keep these structural nodes free of style adjustments to prevent responsive breaking.

### 4. Interactive Decoration & Touch Hitboxes
* Add interactive feedback states (hover/focus/active) on click targets, and always add the `cursor-pointer` class to indicate clickability.
* Prefer clean, modern container shapes; use `square` controls on toolbars or headers where clean minimal layouts benefit from them.

### 5. Modern & Minimal Aesthetics
* Focus on clean lines, subtle separators (`q-separator`), and premium typography (e.g., Inter, Outfit, or Roboto).
* Use micro-animations and smooth transition helpers where appropriate to make the interface feel responsive and alive.
* Avoid visual clutter; keep panels clean and focus user attention using structural alignment.

### 6. Mobile-First & Responsive Strategy (Web & Android)
* All templates must be responsive. Use Quasar's 12-column grid system (`row`, `col-12`, `col-sm-6`, `col-md-4`).
* Design mobile-first by default, specifying base layout columns (`col-12` or `col-xs-12`) and adjusting for desktop using responsive breakpoints (`col-md-6`, `col-lg-4`).
* Leverage visibility classes:
  - `gt-xs` / `gt-sm` to show desktop-optimized components (e.g., full data tables, side menus).
  - `lt-sm` / `lt-md` to display mobile-friendly alternatives (e.g., list cards, bottom bars).
* For mobile/Android viewports, target touch safety:
  - Interactive hitboxes must have a minimum height/width of `48px`.
  - Prevent horizontal scrollbars on the page wrapper; ensure overflowing elements (like tables or long lists) are gracefully scroll-contained or replaced by mobile cards.

### 7. Central Feedback (errors & toasts)
* **Strict Constraint**: Use `web/src/composables/useFeedback.ts` for all user-facing API errors and success/info/warning toasts. Do not add per-feature `$q.notify`, custom snackbars, or ad-hoc error dialogs.
* API failures → `showApiError` / `showError` (centered Dialog, OK only). Soft feedback → `showSuccess` / `showInfo` / `showWarning` (top toast).
* Confirm/destructive Yes-Cancel dialogs and inline field validation remain exceptions.

## Mobile App Architecture (React Native / Expo)

### 1. File Size & Modularity
* **Strict Constraint**: Files should not exceed 400 lines of code.
* Continuously modularize code into smaller, reusable UI components and custom hooks. This ensures easier maintenance and reduced token usage during context building.

### 2. Loading States & Animations
* Always use Skeleton loaders for loading states instead of plain generic spinners (e.g., `ActivityIndicator`), to maintain a premium feel.
* Incorporate lightweight micro-animations to ensure the UI feels dynamic and responsive.

### 3. Dialogs & Modals
* For any dialogs, prioritize using Bottom Slide Sheets/Dialogs instead of traditional center-screen popups. This is more ergonomic for mobile touch interfaces.
* Use a Blur effect for the background of overlays, sheets, and modals (e.g., using `expo-blur`) instead of applying a solid dark tint or dimming.

### 4. Data Refresh & Interactivity
* Ensure there is always a pull-to-refresh mechanism (`RefreshControl`) implemented on every scrollable page or list.

### 5. Layouts & Safe Area
* Always use the proper Safe Area boundaries (via `react-native-safe-area-context`). Ensure UI elements do not overlap with device notches, status bars, and bottom navigation bars.

### 6. Empty States & Primary Actions
* When a list or page is empty (`length === 0`), hide top header creation/action buttons and place the primary action button directly inside the empty state card/container. Show top header action buttons only when items exist in the list.

### 7. Canteen/POS Typography & Touch Ergonomics
* **Strict Constraint**: Do not use micro-fonts (`text-[9px]`, `text-[10px]`) on canteen/POS screens.
* Main item/staff titles must be at least `text-base` (16px) font bold. Secondary metadata badges/labels must be at least `text-xs` (12px) to `text-sm` (14px) for high visibility at arm's length in high-speed canteen environments.

### 8. Swipeable Row Actions & Peek Affordance
* Prefer Swipeable rows (`SwipeableRow`) for item/entity list management (Edit & Delete actions) to keep list card surfaces clean and uncluttered.
* Always incorporate an initial **Peek Nudge Animation** on the first list item upon screen load to visually signal swipeability to users.

## Data Management & API Optimization (Web & Mobile)

### 1. Prevent Redundant Calls
* **Strict Constraint**: Never make unnecessary API calls. Always verify if the data is already available in the local state/cache or if the request can be optimized before hitting the network.

### 2. Targeted Cache Mutation
* **Strict Constraint**: On edit or delete actions, do not trigger a full list refetch. Instead, directly mutate/update the local cache for that specific item to save bandwidth and improve perceived performance.

### 3. Optimistic Updates
* For fast-paced environments (like POS systems), implement optimistic updates where the UI updates immediately on interaction before waiting for the API to confirm the change.

### 4. Debounce/Throttle Inputs
* Always debounce API calls triggered by text inputs (like search bars) to prevent spamming the backend with requests on every keystroke.

### 5. Pagination & Infinite Scroll
* Never fetch entire large database tables at once. Always use pagination or infinite scrolling for lists (like transaction history or large inventories) to minimize payload sizes.

### 6. Stale-While-Revalidate
* Rely on robust caching strategies (like React Query or SWR) to show cached data instantly while silently fetching the latest updates in the background.
