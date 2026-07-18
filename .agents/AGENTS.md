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
