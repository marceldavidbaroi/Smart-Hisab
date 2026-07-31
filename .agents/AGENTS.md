# Project Rules & Customization Constraints

This file outlines the core rules and constraints that the AI agent must adhere to when working on this project.

## Mobile App Architecture (React Native / Expo)

### 1. File Size & Modularity
* **Strict Constraint**: Files should not exceed 400 lines of code.
* Continuously modularize code into smaller, reusable UI components and custom hooks. This ensures easier maintenance and reduced token usage during context building.

### 2. Loading States & Animations
* Always use Skeleton loaders for loading states instead of plain generic spinners (e.g., `ActivityIndicator`), to maintain a premium feel.
* Incorporate lightweight micro-animations to ensure the UI feels dynamic and responsive.

### 3. Dialogs & Modals
* For any dialogs, prioritize using Bottom Slide Sheets/Dialogs instead of traditional center-screen popups. This is more ergonomic for mobile touch interfaces.
* **Strict Constraint**: Bottom slide sheets must have soft rounded top corners (`rounded-t-[32px]` or `rounded-t-3xl`) and must **never contain a top-right 'X' or close button**. Users dismiss bottom slide sheets exclusively via backdrop tap, top drag handle bar, or primary action/cancel buttons.
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

## Data Management & API Optimization (Mobile & Backend)

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
