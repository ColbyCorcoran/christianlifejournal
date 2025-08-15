# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Run
- **Build**: Use Xcode IDE - no external package managers required
- **Run**: Product → Run in Xcode or `Cmd+R`
- **Test**: Product → Test in Xcode or `Cmd+U`
- **Clean Build**: Product → Clean Build Folder or `Cmd+Shift+K`

This is a native iOS app using SwiftUI and SwiftData with no external dependencies.

## Architecture Overview

### Core Technology Stack
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's persistence framework (replacement for Core Data)
- **iOS Target**: Native iOS application
- **Navigation**: NavigationStack with custom `DashboardNav` enum for type-safe routing

### Application Structure
The app is a multi-feature Christian journaling application with:
- **Dashboard-centric design**: Central hub showing all journal sections
- **Multiple journal types**: Personal Time, Sermon Notes, Prayer Journal, Scripture Memorization, Group Notes
- **Advanced scripture memorization system**: 3-phase spaced repetition system
- **Tag and Speaker management**: Reusable reference data across entries

### Data Architecture
- **Primary Models**: `JournalEntry` and `ScriptureMemoryEntry` as main @Model classes
- **Reference Data**: `Tag` and `Speaker` models managed by dedicated stores
- **Flexible Schema**: JournalEntry uses optional fields to accommodate different entry types
- **UUID-based relationships**: TagIDs and SpeakerIDs stored as UUID arrays for relationships

## Key Systems

### Scripture Memorization System
The app includes a sophisticated 3-phase memorization system:
- **Phase 1**: 5 intensive days with decreasing repetitions (25→20→15→10→5)
- **Phase 2**: 45 daily reviews (1 repetition each)
- **Phase 3**: Ongoing monthly reviews
- **Core Logic**: `MemorizationEngine` handles scheduling and completion tracking
- **Progress Tracking**: Complex state management with phase-specific progress data

### State Management Patterns
- **@EnvironmentObject**: Used for `TagStore` and `SpeakerStore` (shared across views)
- **@Query**: SwiftData queries directly in views for data fetching
- **@StateObject**: For settings and other view-specific observable objects
- **Custom Navigation**: `DashboardNav` enum with associated values for type-safe navigation

### Data Stores
- **TagStore**: Manages CRUD operations for tags, provides default tags
- **SpeakerStore**: Manages speakers for sermon notes
- **Both inject modelContext**: Initialized with SwiftData context in ContentView

## File Organization

### Models/
- `JournalModels.swift`: Main journal data models
- `ScriptureMemoryEntry.swift`: Complex model for memorization system
- `MemorizationModels.swift`: Supporting structs and enums for memorization
- `MemorizationEngine.swift`: Business logic for memorization scheduling
- `Tag.swift`, `Speaker.swift`: Reference data models
- `TagStore.swift`, `SpeakerStore.swift`: Data management classes
- `JournalSection.swift`: Enum defining journal categories
- `BibleBooks.swift`: Complete bible book data with chapter/verse counts

### Views/
- `DashboardView.swift`: Main navigation hub and app entry point
- `AddEntryView.swift`, `AddPersonalTimeView.swift`, `AddSermonNotesView.swift`, `AddScriptureMemoryView.swift`: Entry creation/editing views
- `ScriptureFlashcardView.swift`: Memorization practice interface
- Specific list views: `PersonalTimeListView.swift`, `SermonNotesListView.swift`, `ScriptureMemorizationListView.swift`, `GroupNotesListView.swift`, `PrayerJournalListView.swift`, `OtherListView.swift`
- `ScriptureListComponents.swift`: Reusable components for scripture list views
- `*ManagementView.swift`: CRUD interfaces for tags and speakers
- `*PickerSheet.swift`: Sheet-based selection components for tags, speakers, prayer categories, and scripture

### Supporting/
- `Color+AppColors.swift`: Custom green color palette with hex initializer
- `DateUtils.swift`: Date formatting and manipulation utilities
- `Utilities.swift`: General utility functions

## Development Patterns

### SwiftData Usage
- Use `@Query` directly in views for data fetching
- Sort queries by date in reverse order for recent-first display
- Model relationships through UUID arrays rather than SwiftData relationships
- Initialize stores with `modelContext` from environment

### Navigation Patterns
```swift
enum DashboardNav: Hashable {
    case section(JournalSection)
    case entry(UUID)
    case scriptureEntry(UUID)
}
```

### View Initialization
- Pass required data through initializers
- Use `@EnvironmentObject` for shared stores
- Initialize `@State` properties in init() when editing existing entries

### Color Usage
The app uses a custom green palette defined in `Color+AppColors.swift`:
- Use `Color.appGreen*` variants for consistent theming
- Hex-based color initialization available via `Color(hex: "#...")` extension

### Entry Type Handling
The `JournalSection` enum determines:
- Which fields are relevant for each entry type
- Whether to use the memorization system
- UI icons and display names
- Navigation behavior

When adding new journal section types, update the `JournalSection` enum and corresponding view logic.

### Memorization System Integration
- Check `section.usesMemorizationSystem` to determine if entry should use `ScriptureMemoryEntry`
- Use `MemorizationEngine` for all scheduling calculations
- Progress tracking requires updating multiple phase-specific properties
- System can be enabled/disabled via `MemorizationSettings`