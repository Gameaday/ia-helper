# Palette's Journal

## 2024-05-15 - Add confirmation dialog to destructive actions
**Learning:** Destructive actions like clearing caches or deleting data without a confirmation step can lead to accidental data loss and a frustrating user experience.
**Action:** Always wrap destructive actions, such as clearing the identifier cache, in an `AlertDialog` confirmation prompt to ensure intentionality.

## 2024-05-16 - Add tooltip to search bar clear button
**Learning:** Icon-only buttons without tooltips lack proper accessibility labels for screen readers in Flutter and provide poor context for hover interactions.
**Action:** Always add `tooltip` properties to `IconButton` widgets that only display an icon, particularly common functional buttons like "clear text" or "close".

## 2025-04-01 - Add tooltips to functional icon buttons
**Learning:** Missing `tooltip` properties on `IconButton` widgets that lack a label reduces accessibility for screen readers and deprives users of hover context for functional buttons.
**Action:** Always include a `tooltip` parameter when using `IconButton`, particularly for common functional actions like clearing a search or adding an item.

## 2026-04-02 - Dynamic Tooltips for State-Toggling IconButtons
**Learning:** Icon buttons that toggle state (like expand/collapse arrows) need dynamic tooltips that reflect the *action* they will perform when clicked, rather than a static description of the icon itself.
**Action:** Always use conditional logic (e.g., `tooltip: isExpanded ? 'Collapse details' : 'Expand details'`) for `IconButton` widgets that change state to provide accurate screen reader announcements and hover context.
## 2024-05-20 - Missing Tooltips on IconButtons
**Learning:** Many standard `IconButton` components in Flutter apps can lack the `tooltip` property, limiting accessibility for screen readers and usability for hover states. Tooltips are essential context.
**Action:** Always verify `IconButton` widgets include a descriptive `tooltip` attribute during routine UI component audits or modifications.
## 2026-04-04 - Add tooltips to clear search text IconButtons
**Learning:** Icon buttons that clear input fields need tooltips to be accessible and provide immediate context for their function.
**Action:** Always add a tooltip parameter when using IconButton, particularly for clearing searches or forms.

## 2026-04-05 - Add Tooltips and Semantics to Interactive GestureDetectors
**Learning:** When using `GestureDetector` as a custom interactive button (e.g. tapping on text to show a dialog), it inherently lacks accessibility labels and hover tooltips unlike `IconButton` or `TextButton`.
**Action:** Always wrap interactive `GestureDetector` widgets in `Tooltip` and `Semantics(button: true)` to ensure desktop mouse users get hover feedback and screen readers correctly announce the element.
## 2024-05-14 - Semantics and Tooltip on Compact Custom Chips
**Learning:** Icon-only custom widgets (like compact priority chips made with InkWell) are often missed during accessibility audits compared to standard IconButtons. Adding Semantics and Tooltips to these custom elements is crucial for screen readers and desktop users.
**Action:** Always verify if custom interactive elements built with `InkWell` or `GestureDetector` that display only icons have appropriate Semantics and Tooltip wrappers.

## 2024-05-18 - InkWell Interactive Elements Accessibility
**Learning:** Adding Semantics(button: true) and a Tooltip to custom text/icon interactive elements (like an InkWell acting as an expand/collapse toggle) improves the screen reader experience by properly identifying it as a button, and provides hover feedback for desktop users.
**Action:** When creating custom buttons using InkWell, ensure they are wrapped in Tooltip and Semantics(button: true).
## 2024-05-24 - Semantics Wrappers for List Cards
**Learning:** In Flutter, using interactive `Card` components that house `InkWell` elements will visually react to touches, but without a `Semantics` wrapper with `button: true` and an appropriate `label`, screen readers may struggle to clearly interpret the action.
**Action:** When creating grid or list cards that function as buttons using `InkWell`, always wrap the `Card` in a `Semantics` widget to explicitly define its accessible role and announce key contextual details (e.g., the title).

## 2026-05-10 - Semantics wrappers for Card buttons
**Learning:** When making a Flutter `Card` widget actionable via an internal `InkWell`, placing the `Semantics` wrapper *inside* the card can lead to confusing screen reader announcements. Placing it outside the `Card` ensures the entire element is treated as a single cohesive button.
**Action:** When wrapping a `Card` containing an `InkWell` for accessibility, apply the `Semantics(button: true)` wrapper to the parent `Card` widget, not the child.
## 2026-05-12 - Adding Semantics to Interactive Cards and Chips
**Learning:** When using custom `InkWell` widgets for tap targets (like badges or chips) that are not natively recognized as buttons by Flutter, they lack proper screen reader support. Wrapping the `InkWell` in a `Semantics(button: true, label: '...')` makes them discoverable and usable for visually impaired users. It is also important to use `.displayName` instead of raw `.name` enum values for the semantic label so the screen reader announces a human-readable text.
**Action:** Always wrap interactive `InkWell` or `GestureDetector` widgets in a `Semantics` widget with appropriate button roles and labels, using user-friendly text, especially for custom UI elements.
## 2026-05-15 - Semantics Wrapper Placement
**Learning:** When making a Flutter Card widget actionable via an internal InkWell, the Semantics wrapper must be placed *outside* the Card. If placed inside, screen readers may not correctly identify the entire card bounds as the interactive element.
**Action:** Always wrap the outermost Container/Card with Semantics instead of the internal InkWell.

## 2025-01-23 - Added tooltips to Card InkWells
**Learning:** When a Flutter Card uses an internal InkWell, adding Tooltip outside the Card works but inside the Card on the InkWell is also possible. The memory instruction says to put the Semantics outside the Card, and Tooltip inside Semantics.
**Action:** Wrapped Card with Tooltip to provide hover labels for interactive Cards.

## 2024-05-19 - Adding Semantics to Interactive List Items
**Learning:** `InkWell` or `GestureDetector` widgets used for interactive items within lists (such as search history entries) are not implicitly recognized as buttons by screen readers. This makes navigation confusing for users relying on accessibility tools.
**Action:** Always wrap interactive list items (`InkWell`, `GestureDetector`) with a `Semantics` widget, setting `button: true` and providing a descriptive `label` (e.g., `'Search history: ${entry.title}'`) to ensure they are properly identified as actionable controls.
## 2026-05-18 - Add Semantics to Saved Search Card\n**Learning:** In Flutter, using  directly inside a  for list items leaves the entire card interactive, but without an explicit semantic boundary, screen readers might not announce the overall purpose of the tap target effectively. Wrapping the entire actionable  with a  node () ensures the screen reader provides unified, descriptive context rather than reading inner layout elements sequentially.\n**Action:** Always wrap  widgets that function as list buttons (e.g., using an internal ) in a top-level  node to provide a cohesive label and interaction hint.
## 2024-05-24 - Add Semantics to Saved Search Card
**Learning:** In Flutter, using `InkWell` directly inside a `Card` for list items leaves the entire card interactive, but without an explicit semantic boundary, screen readers might not announce the overall purpose of the tap target effectively. Wrapping the entire actionable `Card` with a `Semantics` node (`button: true`) ensures the screen reader provides unified, descriptive context rather than reading inner layout elements sequentially.
**Action:** Always wrap `Card` widgets that function as list buttons (e.g., using an internal `InkWell`) in a top-level `Semantics` node to provide a cohesive label and interaction hint.
## 2026-05-20 - Added Tooltip to Card Widgets
**Learning:** When using internal InkWell or GestureDetector inside a Card widget, wrapping the inner widget with Tooltip doesn't properly provide hover context or accessibility support to the boundaries of the Card. Applying the Tooltip wrapper outside the Card (but inside Semantics) ensures that the hover bounding box and screen reader behavior properly applies to the entire visual Card surface area.
**Action:** Always wrap Card widgets in Tooltip when they contain interactive elements like InkWell to provide a smooth desktop hover and screen reader experience.

## 2026-05-26 - Semantics Wrapper in Grid Card
**Learning:** In Flutter, when wrapping a `Card` containing an `InkWell` for accessibility, apply the `Semantics` wrapper to the parent `Card` widget, not the child, to prevent confusing screen reader announcements.
**Action:** When wrapping a `Card` containing an `InkWell` for accessibility, apply the `Semantics(button: true)` wrapper to the parent `Card` widget.
## 2025-05-19 - Added missing Tooltip to Priority Selector Full Chip
**Learning:** Even when custom widgets (like the priority chip using `InkWell`) have proper `Semantics` wrappers, they often lack `Tooltip` wrappers. This creates an inconsistent experience where screen reader users get proper context, but desktop/web users using a mouse get no hover tooltip indicating the element is interactive and what it does.
**Action:** When adding accessibility to custom interactive components, always ensure that both `Semantics` (for screen readers) and `Tooltip` (for visual hover context) are implemented, and remember to use `excludeFromSemantics: true` on the `Tooltip` to prevent duplicate announcements.

## 2024-05-18 - Semantics wrappers for custom InkWell radio buttons
**Learning:** When using `InkWell` to build custom form controls like radio button groups (e.g., ThemeMode, BandwidthPreset selection), using visual cues alone is insufficient for screen readers. They won't announce the options as selectable buttons or read their selected state.
**Action:** Always wrap `InkWell` custom radio options in a `Semantics` widget with `button: true`, `inMutuallyExclusiveGroup: true`, `selected: isSelected`, and a descriptive `label` that clearly indicates what the option represents (e.g., 'Theme: System Default').
## 2024-05-19 - Avoid redundant Semantics and Tooltip in Flutter
**Learning:** In Flutter, combining explicit `Semantics` and `Tooltip` on the same interactive element can cause redundant screen reader readouts since both provide accessibility text to the OS.
**Action:** Use `excludeFromSemantics: true` on the `Tooltip` to prevent duplication, ensuring the tooltip provides hover context without confusing screen reader users.

## 2024-05-18 - Nested Interactive Element Accessibility
**Learning:** In Flutter, when wrapping interactive elements like `Card` and its internal `InkWell` for accessibility, applying both `Semantics` and `Tooltip` wrappers directly over the `Card` effectively communicates the interaction to screen readers and mouse users. However, `Tooltip` widgets read their `message` out loud to screen readers by default. When wrapping `Semantics` and `Tooltip` together on the same element, you must add `excludeFromSemantics: true` to the `Tooltip` to prevent redundant audio announcements.
**Action:** When creating toggleable sections or actionable cards containing `InkWell`, always place the `Semantics(button: true)` and `Tooltip(excludeFromSemantics: true)` outside the bounding parent (e.g. `Card`) and update their labels dynamically based on the toggle state (e.g., 'Expand' vs 'Collapse').

## 2026-05-30 - Tooltip and Semantics placement for actionable lists
**Learning:** When making `Card` elements actionable in grid or list views via internal `InkWell` components (e.g., in `FavoritesScreen` or `LibraryScreen`), they must be wrapped in `Semantics(button: true)` and `Tooltip(excludeFromSemantics: true)` to ensure screen readers announce them properly as interactive elements without duplicate announcements, and desktop users see a helpful hover state context.
**Action:** Always verify that grid items and list tiles that wrap `Card` + `InkWell` use both `Semantics` and `Tooltip`.
## 2026-06-05 - Avoid polluting repository with scratchpad scripts\n**Learning:** Including ad-hoc Python scripts created during codebase exploration and problem solving in the final commit pollutes the repository and degrades maintainability. They should be deleted before submitting.\n**Action:** Remember to delete local scratchpad scripts used for  alternative operations before finishing tasks and completing pre-commit steps.
## 2026-06-05 - Avoid polluting repository with scratchpad scripts
**Learning:** Including ad-hoc scripts (like python parsers) created during codebase exploration and problem solving in the final commit pollutes the repository and degrades maintainability. They should be deleted before submitting.
**Action:** Remember to delete local scratchpad scripts used for text operations before finishing tasks and completing pre-commit steps.

## 2024-05-18 - Missing Accessibility on Helper Rows
**Learning:** List items like credit rows or external links built using a base `InkWell` often miss out on standard button semantics, making them opaque to screen readers despite being interactive.
**Action:** Always wrap custom interactive text rows (`InkWell`/`GestureDetector`) in `Semantics(button: true)` and `Tooltip(excludeFromSemantics: true)` if they behave as buttons or links.
