# Commander Scorekeeper ⚔️

Un'app iOS professionale in Swift per tracciare i punteggi delle partite di **Magic: The Gathering Commander**.

![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 📋 Caratteristiche

### ✅ Phase 1 (Core MVP) - **IMPLEMENTATO**

- ✅ **Setup Partita Intuitivo**
  - Configurazione 4 giocatori obbligatori
  - Autocomplete per oltre 50 comandanti popolari
  - Selezione identità colore WUBRG
  - Validazione completa prima di iniziare

- ✅ **Game Screen Professionale**
  - Layout a 4 quadranti (2x2) ottimizzato per landscape
  - Visualizzazione punti vita con font grande e chiaro (56pt)
  - Tracking danni comandante per ogni avversario
  - Evidenziazione danni letali (≥21)
  - Counter secondari: Poison ☠️, Energy ⚡, Experience 🎓
  - Stati speciali: Monarch 👑, Initiative 🎲
  - Overlay eliminazione automatica

- ✅ **Controlli Manuali Completi**
  - Tap su quadrante per aprire controlli dettagliati
  - Quick adjust buttons per modifiche rapide (±1, ±5, ±10)
  - Input personalizzato per valori specifici
  - Controlli separati per vita, danni comandante, counter, stati

- ✅ **Persistenza Dati**
  - Core Data per salvataggio robusto
  - Auto-save ogni 30 secondi
  - Salvataggio manuale disponibile
  - Lista partite salvate con preview
  - Caricamento partite in corso o terminate

- ✅ **Sistema Undo**
  - Stack delle ultime 10 azioni
  - Undo completo con ripristino stato
  - Feedback visivo e tattile

- ✅ **UI/UX Excellence**
  - Tema Magic: The Gathering professionale
  - Animazioni fluide con Spring physics
  - Haptic feedback contestuale
  - Flash effects per danni e cure
  - Glow effects per stati speciali
  - Dark mode nativo

- ✅ **Log Azioni**
  - Tracking completo di tutte le azioni
  - Overlay con ultime 5 azioni
  - Vista log completo espandibile
  - Timestamp e descrizioni dettagliate

### 🚧 Phase 2 (Voice Recognition) - **DA IMPLEMENTARE**

- ⬜ Wake word detection ("Hey Commander")
- ⬜ Speaker recognition con calibrazione vocale
- ⬜ Natural Language Processing per comandi in italiano
- ⬜ Text-to-Speech feedback
- ⬜ Continuous listening in low-power mode

### 🎨 Phase 3 (Polish) - **DA IMPLEMENTARE**

- ⬜ Animazioni avanzate per eliminazioni
- ⬜ Effetti sonori
- ⬜ Tutorial interattivo
- ⬜ Statistiche avanzate
- ⬜ Esportazione dati

## 🛠️ Setup Xcode

### Prerequisiti

- **Xcode 15.0+** (con Swift 6.0 support)
- **iOS 17.0+** come deployment target
- **macOS Sonoma 14.0+**

### Installazione

1. **Apri Xcode** e seleziona "Create a new Xcode project"

2. Scegli template:
   - **iOS** → **App**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **Core Data**

3. Configura il progetto:
   - **Product Name**: `CommanderScorekeeper`
   - **Organization Identifier**: `com.tuodominio`
   - **Bundle Identifier**: `com.tuodominio.CommanderScorekeeper`

4. Copia i file del repository nella cartella del progetto Xcode

5. Aggiungi i file al progetto:
   - Trascina la cartella `CommanderScorekeeper` nel Project Navigator
   - Seleziona "Create groups"
   - Assicurati che tutti i file `.swift` siano nel target

6. Configura Core Data:
   - Apri il file `.xcdatamodeld`
   - Verifica che le entità `GameSession`, `Player`, `GameAction` siano presenti
   - Se necessario, ricrea il modello seguendo la struttura in `Resources/CommanderScorekeeper.xcdatamodeld/`

7. Aggiungi `Commanders.json`:
   - Trascina il file JSON in `Resources/`
   - Assicurati che sia incluso nel target

8. Configura `Info.plist`:
   - Aggiungi le privacy descriptions per microfono (Phase 2)
   - Configura orientamenti supportati

9. Build Settings:
   - **Swift Language Version**: Swift 6.0
   - **iOS Deployment Target**: iOS 17.0
   - **Enable Strict Concurrency Checking**: Yes

10. **Build** il progetto (⌘B)

## 🚀 Utilizzo

### Avvio Partita

1. **Tap "Nuova Partita"** dalla schermata principale
2. **Configura 4 giocatori**:
   - Inserisci nome giocatore
   - Cerca e seleziona comandante (autocomplete)
   - Scegli identità colore (o usa auto-detect)
3. **Tap "Rivedi e Inizia"** per vedere il riepilogo
4. **Tap "Inizia Partita!"** per entrare nel game screen

### Durante la Partita

#### Tracking Vita
- **Tap sul quadrante** di un giocatore
- Usa i quick buttons (±1, ±5, ±10)
- O inserisci un valore personalizzato

#### Danni Comandante
- **Tap sul quadrante** del difensore
- Vai alla tab "Cmd Dmg"
- Seleziona l'attaccante e aggiungi il danno

#### Counter (Poison/Energy/Experience)
- **Tap sul quadrante** del giocatore
- Tab "Counter"
- Aggiungi/rimuovi counter usando i bottoni

#### Stati Speciali (Monarch/Initiative)
- **Tap sul quadrante** del giocatore
- Tab "Stato"
- Attiva lo stato desiderato

#### Controlli Generali
- **Pausa**: ferma il timer (voice recognition disabilitato in Phase 2)
- **Annulla**: ripristina l'ultima azione
- **Menu**: salva, vedi log completo, termina partita

### Eliminazione Automatica

Un giocatore viene eliminato automaticamente quando:
- Punti vita ≤ 0
- Poison counter ≥ 10
- Danni da comandante da una singola fonte ≥ 21

L'overlay "💀 ELIMINATO" appare sul quadrante con la motivazione.

### Salvataggio e Caricamento

- **Auto-save**: ogni 30 secondi
- **Salva Manuale**: Menu → "Salva Partita"
- **Carica Partita**: "Partite Salvate" dalla home → tap sulla partita

## 📐 Architettura

### Stack Tecnologico

```
┌─────────────────────────────────────┐
│           SwiftUI Views             │
├─────────────────────────────────────┤
│      ViewModels (MVVM + Combine)    │
├─────────────────────────────────────┤
│          Services Layer             │
│  - PersistenceController            │
│  - CommanderDatabase                │
│  - HapticManager                    │
├─────────────────────────────────────┤
│         Core Data Models            │
│  - GameSession                      │
│  - Player                           │
│  - GameAction                       │
└─────────────────────────────────────┘
```

### Dependency Injection

```swift
// Example: ViewModel initialization
let viewModel = GameViewModel(
    session: gameSession,
    persistenceController: .shared
)
```

### Data Flow

```
User Action → View → ViewModel → Model → Core Data
                ↓        ↓
            Haptic   Animation
```

## 🎨 Design System

### Colors

- **Background**: `#1A1A1A`, `#2D2D2D`, `#3A3A3A`
- **Magic Gold**: `#B8860B`
- **Mana Colors**: W (White), U (Blue), B (Black), R (Red), G (Green)
- **Status**: Success (Green), Warning (Orange), Error (Red)

### Typography

- **Life Total**: SF Pro Display, 56pt, Bold
- **Player Name**: SF Pro Display, 20pt, Bold
- **Commander Damage**: SF Pro Text, 18pt, Medium
- **Counters**: SF Pro Text, 16pt, Semibold

### Animations

- **Spring**: `response: 0.3, dampingFraction: 0.7`
- **Damage Flash**: `0.5s ease-out`
- **Elimination**: `0.8s` con fade + scale

## 🧪 Testing

### Unit Tests (da implementare)

```swift
// Example test structure
class GameViewModelTests: XCTestCase {
    func testLifeChange() {
        // Setup
        let viewModel = GameViewModel(session: mockSession)

        // Action
        viewModel.changeLife(for: player, amount: -5)

        // Assert
        XCTAssertEqual(player.currentLife, 35)
    }
}
```

### UI Tests (da implementare)

```swift
class CommanderScorekeeperUITests: XCTestCase {
    func testGameSetupFlow() {
        let app = XCUIApplication()
        app.launch()

        // Test setup flow
        app.buttons["Nuova Partita"].tap()
        // ...
    }
}
```

## 📱 Compatibilità

- **iPhone**: SE (3rd gen), 12, 13, 14, 15 series
- **iPad**: tutti i modelli con iOS 17+
- **Orientamento**: Portrait (setup), Portrait/Landscape (game)
- **Accessibilità**: VoiceOver support, Dynamic Type ready

## 🐛 Known Issues

- [ ] Landscape mode su iPhone SE mostra quadranti compressi
- [ ] Autocomplete commanders può essere lento con 500+ entries
- [ ] Undo non funziona per stati Monarch/Initiative

## 🗺️ Roadmap

### v1.0 (Phase 1) - **CURRENT**
- ✅ Core gameplay tracking
- ✅ Manual controls
- ✅ Persistence

### v1.1 (Phase 2)
- ⬜ Voice recognition
- ⬜ Speaker identification
- ⬜ Natural language commands

### v1.2 (Phase 3)
- ⬜ Advanced animations
- ⬜ Sound effects
- ⬜ Statistics dashboard
- ⬜ Data export

### v2.0
- ⬜ Multiplayer sync (iCloud)
- ⬜ Custom commanders
- ⬜ Deck tracking
- ⬜ Tournament mode

## 📄 Comandi Vocali (Phase 2)

### Riferimento Comandi

**Vita:**
- "Guadagno 5 vite"
- "Perdo 3 vite"
- "[Nome] guadagna 10 vite"

**Danni Comandante:**
- "Subisco 8 da [NomeComandante]"
- "Do 5 da comandante a [Nome]"
- "[Nome] prende 12 da comandante da [Nome]"

**Poison:**
- "Prendo 3 poison"
- "[Nome] prende 2 veleno"

**Counter:**
- "Aggiungi 5 energy"
- "Rimuovi 2 experience"

**Stati:**
- "Divento il Monarch"
- "[Nome] prende l'iniziativa"

**Utility:**
- "Annulla"
- "Ripeti"

## 🤝 Contributing

Questo è un progetto tier-1 production-ready. Se vuoi contribuire:

1. Fork il repository
2. Crea un branch (`git checkout -b feature/amazing-feature`)
3. Commit con messaggi descrittivi
4. Push al branch
5. Apri una Pull Request

### Code Style

- Segui le [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Usa SwiftLint (config incluso)
- Documenta funzioni pubbliche
- Scrivi test per business logic

## 📝 License

Questo progetto è rilasciato sotto licenza MIT. Vedi `LICENSE` per dettagli.

## 🙏 Credits

- **Magic: The Gathering** è un trademark di Wizards of the Coast
- Commander database basato su EDHREC
- Icons da SF Symbols

## 📧 Contatti

Per bug report, feature request o domande:
- Apri un issue su GitHub
- Email: [tuo-email@example.com]

---

**Fatto con ❤️ per la community Magic**

*"May your draws be gas and your opponents' be lands."*
