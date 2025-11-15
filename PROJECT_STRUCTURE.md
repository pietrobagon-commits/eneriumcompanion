# Commander Scorekeeper - Project Structure

## 📁 File System Structure

```
eneriumcompanion/
├── .git/                                    # Git repository
├── .gitignore                               # Git ignore rules
├── LICENSE                                  # MIT License
├── README.md                                # Main documentation
├── SETUP.md                                 # Xcode setup instructions
├── COMMANDS.md                              # Voice commands reference (Phase 2)
├── PROJECT_STRUCTURE.md                     # This file
│
└── CommanderScorekeeper/                    # Main app directory
    │
    ├── App/                                 # Application entry point
    │   ├── CommanderScorekeeperApp.swift   # @main entry, app configuration
    │   └── ContentView.swift                # Welcome/home screen
    │
    ├── Models/                              # Core Data models & business logic
    │   ├── Player.swift                     # Player entity + computed properties
    │   ├── GameAction.swift                 # Action logging + undo support
    │   ├── GameSession.swift                # Game session management
    │   └── CommanderDatabase.swift          # Commander lookup & autocomplete
    │
    ├── ViewModels/                          # MVVM ViewModels with Combine
    │   ├── SetupViewModel.swift             # Game setup logic
    │   └── GameViewModel.swift              # Active game state management
    │
    ├── Views/                               # SwiftUI Views
    │   │
    │   ├── Setup/                           # Game setup flow
    │   │   ├── SetupView.swift             # Main setup screen
    │   │   └── PlayerSetupCard.swift        # Player configuration card
    │   │
    │   ├── Game/                            # Active game views
    │   │   ├── GameView.swift              # 4-quadrant game screen
    │   │   ├── PlayerQuadrant.swift         # Single player quadrant
    │   │   ├── PlayerDetailSheet.swift      # Player controls sheet
    │   │   └── ActionLogView.swift          # Action history log
    │   │
    │   └── SavedGames/                      # Saved games management
    │       ├── SavedGamesListView.swift     # List of saved sessions
    │       └── GameSessionRow.swift         # Single session row
    │
    ├── Services/                            # Service layer
    │   └── PersistenceController.swift      # Core Data stack management
    │
    ├── Resources/                           # Assets & data files
    │   ├── Commanders.json                  # Commander database (50+ cards)
    │   ├── Assets.xcassets/                 # Images & colors (to be added)
    │   ├── Sounds/                          # Sound effects (Phase 3)
    │   └── CommanderScorekeeper.xcdatamodeld/  # Core Data model definition
    │       └── CommanderScorekeeper.xcdatamodel/
    │           └── contents                 # XML model definition
    │
    ├── Utilities/                           # Utility classes & helpers
    │   ├── Constants.swift                  # App-wide constants & colors
    │   ├── HapticManager.swift              # Haptic feedback controller
    │   └── Extensions/
    │       └── View+Extensions.swift        # SwiftUI View extensions
    │
    └── Info.plist                           # App configuration & permissions
```

---

## 🏗️ Architecture Overview

### MVVM + Combine Pattern

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Views                     │
│  (Setup, Game, SavedGames, Components)              │
└──────────────────┬──────────────────────────────────┘
                   │ @StateObject / @ObservedObject
                   ▼
┌─────────────────────────────────────────────────────┐
│                   ViewModels                         │
│  (SetupViewModel, GameViewModel)                    │
│  - Published properties (@Published)                 │
│  - Business logic                                    │
│  - Combine publishers                                │
└──────────────────┬──────────────────────────────────┘
                   │ Method calls
                   ▼
┌─────────────────────────────────────────────────────┐
│                   Services                           │
│  (PersistenceController, CommanderDatabase)         │
│  - Data operations                                   │
│  - External dependencies                             │
└──────────────────┬──────────────────────────────────┘
                   │ CRUD operations
                   ▼
┌─────────────────────────────────────────────────────┐
│                 Core Data Models                     │
│  (GameSession, Player, GameAction)                  │
│  - Entities                                          │
│  - Relationships                                     │
│  - Computed properties                               │
└─────────────────────────────────────────────────────┘
```

---

## 📊 Core Data Schema

```
GameSession (1) ──┐
                  ├──> (many) Player
                  │           └─ position (0-3)
                  │           └─ currentLife
                  │           └─ commanderDamage [UUID: Int]
                  │           └─ counters (poison, energy, experience)
                  │           └─ states (monarch, initiative, eliminated)
                  │
                  └──> (many) GameAction
                              └─ type (enum)
                              └─ timestamp
                              └─ actorID / targetID
                              └─ value
                              └─ previousStateData (for undo)
```

---

## 🔄 Data Flow Examples

### 1. Life Change Flow

```
User taps +5 button
    ↓
PlayerDetailSheet
    ↓
GameViewModel.changeLife(for: player, amount: 5)
    ↓
├─ player.currentLife += 5
├─ GameAction.createLifeChange(...)
├─ addToUndoStack(action)
├─ checkForElimination(player)
├─ flashDamage(for: player)
├─ HapticManager.shared.lifeChange(amount: 5)
└─ PersistenceController.save()
    ↓
View updates automatically (@Published)
```

### 2. Setup to Game Flow

```
User fills player info
    ↓
SetupViewModel validates
    ↓
User taps "Inizia Partita"
    ↓
SetupViewModel.startGame()
    ↓
PersistenceController.createGameSession(playerConfigs)
    ↓
├─ GameSession created
├─ 4 Players created with relationships
├─ GameAction.gameStart created
└─ Context saved
    ↓
NavigationStack pushes GameView(session)
    ↓
GameViewModel initialized with session
    ↓
Game screen displays
```

---

## 🎨 View Hierarchy

```
ContentView (NavigationStack)
├─ Background gradient
├─ Header section
├─ Main actions
│  ├─ "Nuova Partita" → SetupView
│  └─ "Partite Salvate" → SavedGamesListView
├─ Active sessions section
└─ Statistics section

SetupView (NavigationStack)
├─ Player tabs (P1, P2, P3, P4)
├─ TabView → PlayerSetupCard
│  ├─ Player name field
│  ├─ Commander search + autocomplete
│  └─ Color identity picker
├─ Bottom action bar
│  ├─ Validation errors
│  └─ "Rivedi e Inizia" → ReviewView
└─ ReviewView sheet
   ├─ Player review cards
   └─ "Inizia Partita!" → GameView

GameView (GeometryReader)
├─ 4-quadrant layout
│  ├─ PlayerQuadrant (0) [rotation: 180°]
│  ├─ PlayerQuadrant (1) [rotation: 180°]
│  ├─ PlayerQuadrant (2) [rotation: 0°]
│  └─ PlayerQuadrant (3) [rotation: 0°]
├─ Top bar (timer, menu)
├─ Recent actions overlay
├─ Bottom controls (undo, pause)
└─ PlayerDetailSheet (modal)
   ├─ Tab selector
   │  ├─ Life controls
   │  ├─ Commander damage controls
   │  ├─ Counter controls
   │  └─ Status controls
   └─ Quick adjust buttons

SavedGamesListView
├─ Empty state OR
├─ List
   ├─ Section "In Corso"
   │  └─ GameSessionRow (each active)
   └─ Section "Terminate"
      └─ GameSessionRow (each completed)
```

---

## 🧩 Component Reusability

### Reusable Components

```swift
// Buttons & Controls
QuickAdjustButton       // ±1, ±5, ±10 buttons
ColorButton             // WUBRG color selectors
CounterBadge            // Poison/Energy/Experience badges

// Cards & Rows
PlayerSetupCard         // Setup phase player card
PlayerReviewCard        // Review phase summary
PlayerPreviewCard       // Saved games preview
PlayerQuadrant          // Game screen quadrant
GameSessionRow          // Saved game row
ActionRow               // Action log entry

// Utilities
StatCard                // Statistics display
CommanderSuggestionRow  // Autocomplete result
StatusToggleRow         // Monarch/Initiative toggle
```

---

## 📦 Dependencies

### Built-in Frameworks
- **SwiftUI**: UI framework
- **Combine**: Reactive programming
- **CoreData**: Persistence
- **Foundation**: Base functionality

### Phase 2 (Voice)
- **Speech**: Voice recognition
- **AVFoundation**: Speaker identification, TTS

### Phase 3 (Future)
- **CloudKit**: iCloud sync
- **StoreKit**: In-app purchases (premium features)

---

## 🔧 Configuration Files

```
Info.plist
├─ Bundle ID
├─ Version info
├─ Supported orientations
├─ Privacy descriptions
│  ├─ Microphone usage
│  └─ Speech recognition
└─ Localizations

.gitignore
├─ Xcode user data
├─ Build artifacts
├─ DerivedData
└─ macOS files

Constants.swift
├─ Colors
├─ Layout dimensions
├─ Game rules
├─ Animation timings
└─ Symbols
```

---

## 📈 Performance Considerations

### Optimizations Implemented

1. **Core Data**
   - Batch fetching with limits
   - Relationship pre-fetching
   - Background contexts for heavy operations

2. **UI Performance**
   - LazyVGrid for player lists
   - Conditional rendering (@ViewBuilder)
   - Animation caching
   - Haptic generator pre-warming

3. **Memory Management**
   - Weak references in closures
   - Cancellable cleanup (Combine)
   - Image asset optimization

4. **State Management**
   - Minimal @Published properties
   - Computed properties for derived state
   - Debounced validation (300ms)

---

## 🧪 Testing Structure (To Implement)

```
CommanderScorekeeperTests/
├── Models/
│   ├── PlayerTests.swift
│   ├── GameSessionTests.swift
│   └── GameActionTests.swift
├── ViewModels/
│   ├── SetupViewModelTests.swift
│   └── GameViewModelTests.swift
├── Services/
│   └── PersistenceControllerTests.swift
└── Utilities/
    └── CommanderDatabaseTests.swift

CommanderScorekeeperUITests/
├── SetupFlowTests.swift
├── GameplayTests.swift
└── SavedGamesTests.swift
```

---

## 🔐 Security & Privacy

- ✅ No network calls (offline-first)
- ✅ Local data only (Core Data)
- ✅ No analytics/tracking
- ✅ Privacy descriptions in Info.plist
- 🔜 Phase 2: Voice data not stored, processed on-device only

---

## 📊 Code Statistics

```
Total Files: ~25 Swift files
Total Lines: ~3500+ lines of code
Architecture: MVVM
UI Framework: 100% SwiftUI
Storage: 100% Core Data
Test Coverage: 0% (to implement)
```

---

## 🗺️ File Dependencies Graph

```
CommanderScorekeeperApp.swift
├─> ContentView.swift
│   ├─> SetupView.swift
│   │   ├─> SetupViewModel.swift
│   │   │   ├─> CommanderDatabase.swift
│   │   │   └─> PersistenceController.swift
│   │   └─> PlayerSetupCard.swift
│   │
│   ├─> GameView.swift
│   │   ├─> GameViewModel.swift
│   │   │   ├─> PersistenceController.swift
│   │   │   └─> HapticManager.swift
│   │   ├─> PlayerQuadrant.swift
│   │   ├─> PlayerDetailSheet.swift
│   │   └─> ActionLogView.swift
│   │
│   └─> SavedGamesListView.swift
│       ├─> GameSessionRow.swift
│       └─> PersistenceController.swift
│
├─> Constants.swift (imported everywhere)
└─> View+Extensions.swift (imported in all views)
```

---

**Mantieni questa struttura per garantire scalabilità e manutenibilità! 🏗️**
