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

## 2026-04-06 - Add Tooltips and Semantics to Tree-View Interactive Elements
**Learning:** In file explorers or tree views, custom interactive nodes (like directories built with `InkWell`) often lack screen reader context about whether they are expanded or collapsed, and desktop users don't get hover tooltips explaining the action.
**Action:** Always wrap stateful, tree-view interactive elements in `Semantics(button: true)` with dynamic labels (e.g. 'Expand folder' / 'Collapse folder') and a `Tooltip` to ensure both accessibility and usability.
