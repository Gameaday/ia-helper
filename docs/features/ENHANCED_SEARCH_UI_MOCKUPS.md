# Enhanced Search Bar - UI Mockups

## State 1: Empty / Initial State

```
┌─────────────────────────────────────────────────────────┐
│  🔍  Search Internet Archive                            │
└─────────────────────────────────────────────────────────┘

[No buttons shown]
[No suggestions]
```

---

## State 2: User Typing (Within 400ms debounce)

```
┌─────────────────────────────────────────────────────────┐
│  ⏳  Checking archive...                    mari      ✕ │
└─────────────────────────────────────────────────────────┘

[No buttons yet - waiting for debounce]
```

---

## State 3: Archive Verified (Exact match)

```
┌─────────────────────────────────────────────────────────┐
│  📦  Press Enter to open "mario"            mario     ✕ │
└─────────────────────────────────────────────────────────┘

┌────────────────────────┬────────────────────────────────┐
│  [📦 Open Archive]     │  [🔍 Search]                   │
│   (Primary/Filled)     │   (Secondary/Outlined)         │
└────────────────────────┴────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ ✓  Super Mario Bros                                   → │
│    Software                                             │
└─────────────────────────────────────────────────────────┘
```

---

## State 4: Archive Verified (Case corrected)

```
┌─────────────────────────────────────────────────────────┐
│  📦  Press Enter to open "mario"            Mario     ✕ │
└─────────────────────────────────────────────────────────┘

┌────────────────────────┬────────────────────────────────┐
│  [📦 Open "mario"]     │  [🔍 Search]                   │
│   (Shows correct case) │   (Keyword search)             │
└────────────────────────┴────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ ✓  Super Mario Bros                                   → │
│    Software • Case corrected                            │
└─────────────────────────────────────────────────────────┘
```

---

## State 5: No Archive Found (Identifier pattern)

```
┌─────────────────────────────────────────────────────────┐
│  🔍  Press Enter to search         nonexistent123    ✕ │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│        [🔍 Search]                                      │
│        (Full width)                                     │
└─────────────────────────────────────────────────────────┘

[No preview card - archive doesn't exist]
[Shows recent searches if available]
```

---

## State 6: Keyword Search (with spaces)

```
┌─────────────────────────────────────────────────────────┐
│  🔍  Search Internet Archive     mario games         ✕ │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│        [🔍 Search]                                      │
│        (Full width primary button)                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Recent Searches                                         │
│ ───────────────────────────────────────────────────────│
│ 🕐 mario games                                      ↖   │
│ 🕐 super mario bros                                 ↖   │
│ 🕐 mario kart 64                                    ↖   │
└─────────────────────────────────────────────────────────┘
```

---

## Color Reference (MD3)

### Icons & States
- 📦 **Archive icon** (verified): Primary color (#6750A4 light / #D0BCFF dark)
- 🔍 **Search icon** (default): OnSurfaceVariant (#49454F light / #CAC4D0 dark)
- ⏳ **Loading spinner**: Primary color
- ✓ **Check mark**: Primary color
- 🕐 **History icon**: OnSurfaceVariant

### Buttons
- **Filled Button**: Primary container with primary color
- **Outlined Button**: Border with primary color, transparent fill
- **Text on buttons**: OnPrimary for filled, Primary for outlined

### Cards
- **Preview card**: Surface container with elevation 1
- **Recent searches**: Surface container with elevation 1
- **Border**: None (elevation provides depth)

### Text
- **Archive title**: BodyMedium, FontWeight.w600
- **Subtitle**: BodySmall, OnSurfaceVariant
- **Hint text**: BodyLarge, OnSurfaceVariant
- **Section headers**: LabelSmall, OnSurfaceVariant, FontWeight.w600

---

## Interaction Flows

### Flow 1: Quick Archive Access
```
1. User types "mario"
2. [400ms pause]
3. Archive verified → Preview appears
4. User presses Enter (or taps "Open Archive")
5. → Navigate to archive detail screen
```

### Flow 2: Explicit Choice
```
1. User types "mario"
2. [400ms pause]
3. Archive verified → Preview appears
4. User wants keyword search instead
5. User taps "Search" button
6. → Navigate to search results screen
```

### Flow 3: Case Auto-Correction
```
1. User types "Mario" (autocorrect capitalized it)
2. [400ms pause]
3. System checks: "Mario", "mario", "MARIO"
4. Finds: "mario" (lowercase)
5. Preview shows: "Open 'mario'" with notice
6. User taps "Open 'mario'"
7. → Navigate to lowercase "mario" archive
```

### Flow 4: Fallback to Search
```
1. User types "mario_2024_xyz"
2. [400ms pause]
3. Archive not found (404)
4. Only "Search" button shown
5. User presses Enter
6. → Navigate to search results for "mario_2024_xyz"
```

---

## Spacing & Layout (MD3 8dp Grid)

### Search Field
- Height: 56dp (standard MD3 text field height)
- Padding horizontal: 16dp
- Padding vertical: 16dp
- Border radius: 28dp (pill shape)
- Elevation: 2dp

### Buttons
- Height: 40dp (standard button height)
- Padding horizontal: 16dp
- Padding vertical: 12dp
- Border radius: 20dp (medium shape)
- Gap between: 8dp

### Preview Card
- Padding: 16dp
- List tile: Standard Material ListTile
- Icon size: 24dp
- Trailing icon: 16dp
- Gap from buttons: 12dp

### Recent Searches
- Section header padding: 16dp horizontal, 12dp top, 8dp bottom
- List tile: Dense variant
- Icon size: 20dp
- Gap from search: 8dp

---

## Accessibility

### Semantics
- Search field: "Search Internet Archive, edit text"
- Open Archive button: "Open mario archive"
- Search button: "Search for mario"
- Preview card: "Super Mario Bros, Software archive, Tap to open"
- Recent search: "Recent search: mario games, Tap to use"

### Touch Targets
- Minimum: 48x48dp (MD3 standard)
- Buttons: 40dp height + 8dp padding = meets minimum
- List tiles: 48dp height minimum
- Clear button: 48x48dp

### Contrast Ratios
- All text: WCAG AA minimum (4.5:1)
- Icon to background: WCAG AA (3:1)
- Buttons: Sufficient contrast in both light/dark modes

---

## Animation Timing

### Search Field
- Focus animation: 200ms emphasized curve
- Border color change: 200ms standard curve

### Buttons
- Appearance: Fade in 100ms
- Disappearance: Fade out 100ms
- Ripple: Default Material (200ms)

### Cards
- Slide in: 200ms decelerate
- Fade in: 100ms linear
- Slide out: 150ms accelerate

### Loading Spinner
- Continuous rotation: 1000ms linear, infinite

---

## Error States

### Network Timeout
```
┌─────────────────────────────────────────────────────────┐
│  ⚠️  Could not verify archive              mario      ✕ │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│        [🔍 Search]                                      │
│        (Fallback to search)                             │
└─────────────────────────────────────────────────────────┘

[ℹ️ Network error - try searching instead]
```

### API Rate Limit
```
┌─────────────────────────────────────────────────────────┐
│  ⚠️  Too many requests - using cache      mario      ✕ │
└─────────────────────────────────────────────────────────┘

[Shows cached result if available, or search fallback]
```

---

## Platform Adaptations

### iOS
- Use Cupertino-style search field border
- Add iOS-style clear button (ⓧ in circle)
- Haptic feedback on verification complete

### Android
- Standard Material search field
- Ripple effects on all interactive elements
- No haptic feedback (user preference)

### Web
- Hover states for buttons and list items
- Keyboard shortcuts (Alt+S to focus search)
- Tab navigation through suggestions

---

## Dark Mode

### Color Adjustments
- Surface: Darker elevation tint
- Primary: Lighter variant (D0BCFF)
- OnSurface: Lighter text (E6E1E5)
- Shadows: Deeper, higher contrast

### Contrast
- All elements maintain WCAG AA in dark mode
- Icons use lighter variants
- Card elevation more prominent

---

## Performance Targets

### Timing
- Debounce delay: 400ms (feels instant after typing)
- API timeout: 3 seconds
- Cache lookup: <10ms
- UI update: <16ms (60fps)

### Responsiveness
- Button press: Immediate visual feedback
- Suggestion tap: Instant navigation
- Clear button: Immediate text clear

---

## Comparison: Before vs After

### Before (Old Search Bar)
```
┌─────────────────────────────────────────────────────────┐
│  🔍  Enter Internet Archive identifier     mario      ✕ │
└─────────────────────────────────────────────────────────┘

[User presses Enter]
→ Tries to load archive
→ May fail if capitalization wrong
→ No indication of what will happen
→ No alternative action

Problems:
❌ No preview
❌ No case correction
❌ No keyword search option
❌ Unclear what Enter does
❌ Potential API call every keystroke
```

### After (Enhanced Search Bar)
```
┌─────────────────────────────────────────────────────────┐
│  📦  Press Enter to open "mario"            mario     ✕ │
└─────────────────────────────────────────────────────────┘

┌────────────────────────┬────────────────────────────────┐
│  [📦 Open Archive]     │  [🔍 Search]                   │
└────────────────────────┴────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ ✓  Super Mario Bros                                   → │
│    Software                                             │
└─────────────────────────────────────────────────────────┘

Benefits:
✅ Shows preview with title
✅ Case auto-correction
✅ Both archive & search options
✅ Clear hint text
✅ Debounced API calls (400ms)
✅ 1-hour cache
✅ Recent searches
```

---

## Mobile Layout (375px width)

```
┌─────────────────────────────┐
│                             │
│  🔍  Search Internet Archive│
│      mario               ✕  │
│                             │
├─────────────────────────────┤
│                             │
│  [📦 Open Archive]          │
│  [🔍 Search]                │
│                             │
├─────────────────────────────┤
│                             │
│ ✓ Super Mario Bros        → │
│   Software                  │
│                             │
└─────────────────────────────┘
```

### Responsive Breakpoints
- **< 600px**: Buttons stack vertically (full width each)
- **≥ 600px**: Buttons side-by-side (60-40 split when dual)
- **≥ 840px**: Wider search field, more breathing room

---

## Summary

The enhanced search bar provides:

1. **Clear Intent Separation**: Archive vs Search buttons
2. **Visual Feedback**: Icons, colors, preview cards
3. **Smart Case Handling**: Automatic correction with notice
4. **API Optimization**: Debouncing + caching = 50-80% fewer calls
5. **Graceful Degradation**: Falls back to search if archive not found
6. **MD3 Compliance**: Proper elevation, colors, spacing, animations

All while maintaining excellent accessibility and performance! 🎉
