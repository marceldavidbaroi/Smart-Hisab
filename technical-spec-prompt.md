I am updating/creating a new [feature / module / plan] called: [Insert Feature Name/Brief Description Here].

Please act as a Principal Software Engineer and Solutions Architect. Write a comprehensive Technical Specification Document (RFC) for this update. Ensure you cover every single detail across the following technical requirements:

1. PRODUCT & SECURITY
- User Story: Clear user persona, action, and business value.
- Permission Control: Access control matrix for different user roles.
- Authentication & Authorization: Identity verification and route/database-level authorization enforcement.

2. BACKEND & DATA
- Data Modeling: Database schema design, fields, relationships, and indexing.
- Database Integration: Migrations, ORM updates, and handling of existing data.
- Api Surface & Design: Specific endpoint paths, HTTP methods, and exact JSON request/response structures.
- Api Flow: Sequential flow of data from client to DB and back, including middleware.
- Error Handling (Backend): Specific status codes and failure responses for validation, limits, and server issues.

3. FRONTEND ARCHITECTURE
- State Management: Local vs. global state strategy, caching, and data distribution.
- Routing: URL structures, nested routes, and route guards.
- Lazy Loading: Code-splitting strategy and performance optimization boundaries.

4. UI & ACCESSIBILITY
- Component Specification: Breakdown of components needed and their respective properties (props).
- UI Components Responsive Design: Layout behavior and breakpoints (Mobile, Tablet, Desktop).
- Style: Themes, visual states (hover, active, loading, disabled), and utility tokens.
- Accessibility (a11y): ARIA attributes, semantic HTML, and keyboard navigation.
- Data Fetching & Error Handling (Frontend): UI handling for empty states, network drops, form validations, and error boundaries.

Finally, after providing the document, break down the implementation phase into small, chronological, and highly actionable checklists (Phase 1: Backend/Data, Phase 2: UI/Frontend Infra, Phase 3: Assembly/Integration, Phase 4: Optimization/Polish) so the feature can be built incrementally.