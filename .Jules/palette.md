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
