# Collection Navigation - UI Mockup Guide

**Feature:** Enhanced Collection Navigation & Discovery  
**Version:** 1.0  
**Date:** October 8, 2025

---

## 🎨 Visual Design Mockups

### 1. Archive Detail Screen - Collection Chips

#### Before (Current)
```
┌─────────────────────────────────────────┐
│ ← Archive Title                     ⋮   │
├─────────────────────────────────────────┤
│ [Thumbnail]                              │
│                                          │
│ Title: Example Archive                  │
│ Creator: John Doe                       │
│                                          │
│ Description: Lorem ipsum...             │
│                                          │
│ [File List]                             │
│ • file1.mp3                             │
│ • file2.mp3                             │
│ • file3.mp3                             │
└─────────────────────────────────────────┘
```

#### After (Enhanced)
```
┌─────────────────────────────────────────┐
│ ← Archive Title              ⭐ 📥 ⋮    │
├─────────────────────────────────────────┤
│ [Thumbnail]                              │
│                                          │
│ Title: Example Archive                  │
│ Creator: John Doe • 2020                │
│                                          │
│ ┌─────────────────────────────────────┐ │
│ │ 📁 Collections (3)                  │ │
│ │                                     │ │
│ │ ┌──────────────┐ ┌──────────────┐ │ │
│ │ │ 🎵 Music     │ │ 🎸 Rock 70s  │ │ │
│ │ │ 1.2K items   │ │ 450 items    │ │ │
│ │ └──────────────┘ └──────────────┘ │ │
│ │                                     │ │
│ │ ┌────────────────┐                 │ │
│ │ │ 📻 Classics    │  + View all    │ │
│ │ │ 2.4K items     │                 │ │
│ │ └────────────────┘                 │ │
│ └─────────────────────────────────────┘ │
│                                          │
│ ▼ Description                           │
│ Lorem ipsum dolor sit amet...           │
│                                          │
│ ▼ Files (234) 🔍                        │
│ [File list with filters]                │
│                                          │
│ ▼ Metadata                              │
│ [Collapsible metadata section]          │
│                                          │
│ ▼ Similar Items                         │
│ [Horizontal scroll of thumbnails]       │
└─────────────────────────────────────────┘
```

**MD3 Components Used:**
- `Card` with `surfaceVariant` for collection section
- `Chip` with `FilterChip` style for collections
- `Icon` with color = `primary` for collection type
- `Text` with `labelSmall` for item count
- `ExpansionTile` for collapsible sections

---

### 2. Collection View Screen - Full Layout

```
┌─────────────────────────────────────────┐
│ ← Rock Albums Collection        🔍 ⋮   │ App Bar
├─────────────────────────────────────────┤
│ ╔═══════════════════════════════════╗  │
│ ║                                   ║  │
│ ║   [Collection Cover Image]       ║  │ Hero Image
│ ║                                   ║  │ (16:9 ratio)
│ ╚═══════════════════════════════════╝  │
│                                          │
│ Rock Albums Collection                  │ Title (headline)
│ Curated by Music Enthusiasts            │ Subtitle
│ 1,234 albums • Created Jan 2020         │ Stats
│                                          │
│ A comprehensive collection of classic   │ Description
│ rock albums from the 1960s-1990s.       │ (max 3 lines,
│ Featuring legendary bands and...        │ expand button)
│                                          │
│ ┌───────────────────────────────────┐  │
│ │  🔖  BOOKMARK COLLECTION          │  │ Primary Action
│ └───────────────────────────────────┘  │ (FilledButton)
├─────────────────────────────────────────┤
│ ⚙️ Sort: Date ↓   📁 Filter   🔍 Search│ Toolbar
├─────────────────────────────────────────┤
│                                          │
│ ┏━━━━━━┓ ┏━━━━━━┓ ┏━━━━━━┓ ┏━━━━━━┓│
│ ┃ 🎵   ┃ ┃ 🎵   ┃ ┃ 🎵   ┃ ┃ 🎵   ┃│
│ ┃[Img] ┃ ┃[Img] ┃ ┃[Img] ┃ ┃[Img] ┃│ 2-column
│ ┃      ┃ ┃      ┃ ┃      ┃ ┃      ┃│ grid on
│ ┃Title ┃ ┃Title ┃ ┃Title ┃ ┃Title ┃│ phone
│ ┃Year  ┃ ┃Year  ┃ ┃Year  ┃ ┃Year  ┃│
│ ┗━━━━━━┛ ┗━━━━━━┛ ┗━━━━━━┛ ┗━━━━━━┛│
│                                          │
│ ┏━━━━━━┓ ┏━━━━━━┓ ┏━━━━━━┓ ┏━━━━━━┓│
│ ┃ 🎵   ┃ ┃ 🎵   ┃ ┃ 🎵   ┃ ┃ 🎵   ┃│
│ ┃[Img] ┃ ┃[Img] ┃ ┃[Img] ┃ ┃[Img] ┃│
│ ┗━━━━━━┛ ┗━━━━━━┛ ┗━━━━━━┛ ┗━━━━━━┛│
│                                          │
│        [Load More / Infinite Scroll]     │
└─────────────────────────────────────────┘
```

**Tablet Layout (3-column):**
```
┌───────────────────────────────────────────────────────┐
│ ← Rock Albums Collection                    🔍 ⋮     │
├───────────────────────────────────────────────────────┤
│ ╔═════════════════╗                                   │
│ ║                 ║  Rock Albums Collection           │
│ ║  [Cover Image]  ║  by Music Enthusiasts             │
│ ║                 ║  1,234 albums • Jan 2020          │
│ ╚═════════════════╝                                   │
│                     Description text here...          │
│                     [🔖 BOOKMARK]                     │
├───────────────────────────────────────────────────────┤
│ Sort: Date ↓  Filter  Search                          │
├───────────────────────────────────────────────────────┤
│ ┏━━━━┓ ┏━━━━┓ ┏━━━━┓ ┏━━━━┓ ┏━━━━┓ ┏━━━━┓│
│ ┃🎵  ┃ ┃🎵  ┃ ┃🎵  ┃ ┃🎵  ┃ ┃🎵  ┃ ┃🎵  ┃│
│ ┃[Img┃ ┃[Img┃ ┃[Img┃ ┃[Img┃ ┃[Img┃ ┃[Img┃│ 3-column
│ ┃    ┃ ┃    ┃ ┃    ┃ ┃    ┃ ┃    ┃ ┃    ┃│ grid
│ ┗━━━━┛ ┗━━━━┛ ┗━━━━┛ ┗━━━━┛ ┗━━━━┛ ┗━━━━┛│
└───────────────────────────────────────────────────────┘
```

---

### 3. In-Collection Navigation

#### Option A: Navigation Bar (Recommended)
```
┌─────────────────────────────────────────┐
│ ← Rock Albums                       ⋮   │ App Bar with
├─────────────────────────────────────────┤ collection name
│ ╔═══════════════════════════════════╗  │
│ ║  ◄ Previous    12/234    Next ►   ║  │ Navigation Bar
│ ║  [Prev Thumb] Archive# [Next Thmb]║  │ (sticky at top)
│ ╚═══════════════════════════════════╝  │
├─────────────────────────────────────────┤
│                                          │
│ [Archive Content]                       │ Main content
│                                          │
└─────────────────────────────────────────┘
```

#### Option B: Floating Navigation (Alternative)
```
┌─────────────────────────────────────────┐
│ ← Back to Collection                ⋮   │
├─────────────────────────────────────────┤
│                                          │
│ [Archive Content]                       │
│                                          │
│                                          │
│  ╔═══╗                        ╔═══╗    │ Floating
│  ║ ◄ ║                        ║ ► ║    │ buttons
│  ╚═══╝                        ╚═══╝    │ (semi-
│                                          │ transparent)
│                                          │
│                                          │
│         12/234 in Rock Albums           │ Position
│         ━━━━━━━━━━                     │ indicator
└─────────────────────────────────────────┘
```

#### Swipe Gesture Indicator
```
┌─────────────────────────────────────────┐
│                                          │
│        [Swipe left for next] →          │ Hint overlay
│                                          │ (shows on
│ [Archive Content]                       │ first view)
│                                          │
└─────────────────────────────────────────┘
```

---

### 4. Sort & Filter Bottom Sheet

```
┌─────────────────────────────────────────┐
│               Sort & Filter              │ Sheet Header
│                     ╳                    │
├─────────────────────────────────────────┤
│                                          │
│ SORT BY                                 │
│ ○ Date Added (Newest First)             │
│ ● Date Added (Oldest First)             │ Radio buttons
│ ○ Title (A-Z)                           │
│ ○ Title (Z-A)                           │
│ ○ Most Downloaded                       │
│ ○ Most Viewed                           │
│                                          │
├─────────────────────────────────────────┤
│                                          │
│ FILTER BY MEDIA TYPE                    │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐   │
│ │ 🎵   │ │ 🎬   │ │ 📄   │ │ 🖼️   │   │ Filter chips
│ │Audio │ │Video │ │Text  │ │Image │   │ (multi-select)
│ └──────┘ └──────┘ └──────┘ └──────┘   │
│                                          │
│ DATE RANGE                              │
│ ├────────●══════●─────────┤            │ Range slider
│ 1960              2020    2025          │
│                                          │
│ FILE SIZE                               │
│ ├─●═══════════════════─────┤           │ Range slider
│ 0MB                      1GB            │
│                                          │
├─────────────────────────────────────────┤
│ [Clear All]           [Apply Filters]   │ Action buttons
└─────────────────────────────────────────┘
```

---

### 5. Collection Chip States

#### Default State
```
┌──────────────┐
│ 🎵 Music     │  ← Icon + Label
│ 1.2K items   │  ← Item count (optional)
└──────────────┘
```

#### Hover/Focus State (Desktop)
```
┌──────────────┐
│ 🎵 Music     │  ← Slightly elevated
│ 1.2K items   │  ← Primary color background
└──────────────┘
   └─ Tooltip: "View Music collection"
```

#### Pressed State
```
┌──────────────┐
│ 🎵 Music     │  ← Ripple effect
│ 1.2K items   │  ← Slightly darker
└──────────────┘
```

#### Loading State
```
┌──────────────┐
│ ⌛ Loading   │  ← Spinner icon
│ ...          │  ← Skeleton text
└──────────────┘
```

---

### 6. Bookmarked Collection Indicator

#### In Collections List
```
┌─────────────────────────────────────────┐
│ MY COLLECTIONS                          │
├─────────────────────────────────────────┤
│                                          │
│ ┏━━━━━━━┓                               │
│ ┃ 📁    ┃  My Saved Items               │ User collection
│ ┃ [Img] ┃  12 items • Local             │ (local)
│ ┗━━━━━━━┛                               │
│                                          │
│ ┏━━━━━━━┓                               │
│ ┃ 🔖 IA ┃  Rock Albums ⭐               │ Bookmarked IA
│ ┃ [Img] ┃  1.2K items • Internet Archive│ (IA + star)
│ ┗━━━━━━━┛                               │
│                                          │
│ ┏━━━━━━━┓                               │
│ ┃ 📁    ┃  Favorites                    │ User collection
│ ┃ [Img] ┃  45 items • Local             │ (local)
│ ┗━━━━━━━┛                               │
└─────────────────────────────────────────┘
```

#### Bookmark Button States
```
Before Bookmark:        After Bookmark:
┌─────────────────┐    ┌─────────────────┐
│ 🔖 BOOKMARK     │    │ ✓ BOOKMARKED    │
│ COLLECTION      │    │                 │
└─────────────────┘    └─────────────────┘
 OutlinedButton          FilledButton
                         + Success color
```

---

### 7. Empty States

#### Empty Collection
```
┌─────────────────────────────────────────┐
│                                          │
│              📭                         │
│                                          │
│         No Items Found                  │
│                                          │
│    This collection is empty or          │
│    couldn't be loaded.                  │
│                                          │
│    ┌──────────────────┐                │
│    │ Refresh          │                │
│    └──────────────────┘                │
│                                          │
└─────────────────────────────────────────┘
```

#### No Bookmarked Collections
```
┌─────────────────────────────────────────┐
│                                          │
│              🔖                         │
│                                          │
│      No Bookmarked Collections          │
│                                          │
│    Browse archives and bookmark         │
│    collections you want to explore.     │
│                                          │
│    ┌──────────────────┐                │
│    │ Explore Archives │                │
│    └──────────────────┘                │
│                                          │
└─────────────────────────────────────────┘
```

#### No Collections for Archive
```
┌─────────────────────────────────────────┐
│ 📁 Collections                          │
│                                          │
│ This archive isn't part of any          │
│ collections yet.                        │
└─────────────────────────────────────────┘
```

---

### 8. Loading States

#### Collection View Loading
```
┌─────────────────────────────────────────┐
│ ← Collection Name               🔍 ⋮   │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐│
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ││ Shimmer
│ │                                     ││ skeleton
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                 ││ loader
│ │ ▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓                ││
│ └─────────────────────────────────────┘│
│                                          │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐           │
│ │▓▓▓▓│ │▓▓▓▓│ │▓▓▓▓│ │▓▓▓▓│           │ Grid
│ │▓▓▓▓│ │▓▓▓▓│ │▓▓▓▓│ │▓▓▓▓│           │ skeletons
│ └────┘ └────┘ └────┘ └────┘           │
└─────────────────────────────────────────┘
```

#### Collection Chips Loading
```
┌─────────────────────────────────────────┐
│ 📁 Collections                          │
│                                          │
│ ┌──────┐ ┌──────┐ ┌──────┐             │
│ │ ⌛▓▓ │ │ ⌛▓▓ │ │ ⌛▓▓ │             │ Shimmer
│ │ ▓▓▓▓ │ │ ▓▓▓▓ │ │ ▓▓▓▓ │             │ chips
│ └──────┘ └──────┘ └──────┘             │
└─────────────────────────────────────────┘
```

---

## 🎨 MD3 Component Mapping

### Collection Chips
- **Component**: `FilterChip` or `ActionChip`
- **Elevation**: 1dp
- **Shape**: Fully rounded (stadium shape)
- **Color**: 
  - Default: `surfaceVariant`
  - Selected: `secondaryContainer`
- **Text**: `labelLarge` (14sp)
- **Icon**: 16dp, `onSurfaceVariant`

### Collection Card (in list)
- **Component**: `Card` with `elevated` variant
- **Elevation**: 1dp → 3dp on hover
- **Shape**: `medium` (12dp corners)
- **Padding**: 16dp
- **Image**: 16:9 ratio, rounded top corners

### Navigation Bar (in-collection)
- **Component**: Custom `Container` with `Card` elevation
- **Background**: `surface` with 95% opacity
- **Elevation**: 2dp
- **Buttons**: `IconButton` with circular background
- **Text**: `labelMedium` for position counter

### Bookmark Button
- **Component**: `FilledButton` when bookmarked, `OutlinedButton` when not
- **Icon**: `bookmark` (outlined) or `bookmark` (filled)
- **Text**: `labelLarge`
- **Min Width**: 200dp on tablet, full-width on phone

---

## 📐 Spacing & Sizing

### Collection Chips
- Height: 40dp
- Horizontal padding: 16dp
- Icon size: 18dp
- Gap between chips: 8dp
- Gap between rows: 8dp

### Collection View Grid
- Phone: 2 columns, 8dp gap
- Tablet: 3-4 columns, 12dp gap
- Large tablet: 4-6 columns, 16dp gap
- Card aspect ratio: 3:4 (portrait) or 16:9 (landscape)

### Navigation Bar
- Height: 64dp
- Horizontal padding: 16dp
- Button size: 48dp
- Icon size: 24dp

---

## 🔄 Animations

### Collection Chip Tap
```dart
// MD3 Emphasized curve
TweenSequence([
  TweenSequenceItem(scale: 0.95, duration: 50ms),
  TweenSequenceItem(scale: 1.05, duration: 100ms),
  TweenSequenceItem(scale: 1.0, duration: 50ms),
])
```

### Collection View Enter
```dart
// Fade + Slide
SlideTransition(
  position: Tween(begin: Offset(0.0, 0.1), end: Offset.zero),
  child: FadeTransition(opacity: animation),
)
Duration: 300ms (MD3 emphasized curve)
```

### Grid Item Appearance
```dart
// Staggered fade-in
for (int i = 0; i < items.length; i++) {
  delay: i * 50ms
  duration: 200ms
  animation: FadeIn + ScaleIn(0.8 → 1.0)
}
```

### Bookmark Button
```dart
// Success animation
ScaleTransition(1.0 → 1.2 → 1.0)
ColorTransition(outline → filled → success)
Icon change: bookmark_outline → bookmark
Duration: 400ms
```

---

## ✅ Checklist for Implementation

- [ ] Create collection chip widget with proper MD3 styling
- [ ] Implement collection view screen with hero image
- [ ] Add sort/filter bottom sheet
- [ ] Create grid layout with responsive columns
- [ ] Implement pagination/infinite scroll
- [ ] Add bookmark button with animations
- [ ] Create navigation bar for in-collection browsing
- [ ] Implement swipe gestures
- [ ] Add all loading states (skeletons)
- [ ] Add all empty states with illustrations
- [ ] Implement breadcrumb navigation
- [ ] Add proper transitions between screens
- [ ] Test on multiple screen sizes
- [ ] Verify MD3 compliance
- [ ] Ensure WCAG AA+ accessibility
- [ ] Test dark mode appearance

---

**Mockup Version:** 1.0  
**Figma Link:** [To be created]  
**Design System:** Material Design 3  
**Target Platforms:** Android (primary), iOS (secondary)
