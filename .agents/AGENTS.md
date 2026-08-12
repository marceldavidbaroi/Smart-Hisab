# Project Rules & Customization Constraints

This file outlines the core rules and constraints that the AI agent must adhere to when working on this project.

## Mobile App Architecture (Flutter / Dart)

### 1. File Size & Modularity
* **Strict Constraint**: Files should not exceed 400 lines of code.
* Continuously modularize code into smaller, reusable UI widgets and Riverpod notifier providers.

### 2. Loading States & Animations
* Always use Skeleton / Shimmer loaders (`shimmer` package) for loading states instead of generic circular progress indicators.
* Incorporate smooth micro-animations to ensure the UI feels dynamic and responsive.

### 3. Dialogs & Modals
* For any dialogs, prioritize using Modal Bottom Sheets (`showModalBottomSheet`) instead of center-screen popups.
* **Strict Constraint**: Modal bottom sheets must have rounded top corners (`BorderRadius.vertical(top: Radius.circular(32))`) and must **never contain a top-right 'X' or close button**. Dismiss via backdrop tap, drag handle bar, or action buttons.

### 4. Data Refresh & Interactivity
* Ensure there is always a pull-to-refresh mechanism (`RefreshIndicator`) implemented on every scrollable view or list.

### 5. Layouts & Safe Area
* Always wrap views with `SafeArea` widget. Ensure UI elements do not overlap with status bars or navigation gestures.

### 6. Empty States & Primary Actions
* When a list or page is empty, hide top header creation/action buttons and place the primary action button directly inside the empty state card/container.

### 7. Canteen/POS Typography & Touch Ergonomics
* **Strict Constraint**: Main item/staff titles must be at least `fontSize: 16` bold. Secondary metadata badges must be at least `fontSize: 12` to `14` for high visibility at arm's length in high-speed canteen environments.

### 8. Swipeable Row Actions
* Prefer Dismissible / Swipeable rows for item/entity list management (Edit & Delete actions) to keep list card surfaces clean.

### 9. Target Platform: Android Only
* **Strict Constraint**: The target environment for this application is Android only (Android mobile devices & emulators). Prioritize Android design patterns, touch targets, and Android system behavior.

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

## Documentation & IDE Preferences

### 1. Markdown File Viewing Mode
* **Strict Constraint**: Always open, view, and present `.md` (Markdown) files in Preview Mode so markdown formatting, alerts, tables, and Mermaid diagrams are rendered visually for the user.

