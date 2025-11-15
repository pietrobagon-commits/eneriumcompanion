# Commander Scorekeeper ⚔️🎤

Un'app iOS professionale in Swift per tracciare i punteggi delle partite di **Magic: The Gathering Commander** con **riconoscimento vocale integrato**.

![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Phase](https://img.shields.io/badge/Phase-2%20Complete-success.svg)

## 📋 Caratteristiche

### ✅ Phase 1 (Core MVP) - **COMPLETATO**

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

### ✅ Phase 2 (Voice Recognition) - **COMPLETATO** 🎤

- ✅ **Wake Word Detection**
  - Rilevamento "Hey Commander" o "Ehi Commander"
  - Continuous listening in low-power mode
  - Indicatore visivo con animazione pulsante blu
  - Audio feedback con "ding" sound
  - Timeout automatico dopo 5 secondi

- ✅ **Speaker Recognition**
  - Calibrazione voce opzionale (3 campioni per giocatore)
  - Estrazione features acustiche (MFCC, pitch, energy, spectral centroid)
  - Matching con confidence score (threshold 85%)
  - Fallback manuale se confidence <85%
  - Voice profiles salvati in Core Data

- ✅ **Natural Language Processing**
  - Parser italiano completo per comandi di gioco
  - Pattern matching avanzato con regex
  - Sinonimi e variazioni supportati
  - Estrazione automatica player names e commanders
  - Supporto comandi:
    * Vita: "Guadagno 5 vite", "Perdo 10 vite"
    * Danni comandante: "Subisco 8 da Atraxa"
    * Poison: "Prendo 3 poison"
    * Energy: "Aggiungi 5 energy"
    * Experience: "Guadagno 2 experience"
    * Monarch: "Divento il Monarch"
    * Initiative: "Prendo l'iniziativa"

- ✅ **Text-to-Speech Feedback**
  - Conferma vocale azioni eseguite
  - Voice italiana naturale (it-IT)
  - Sistema di priorità (immediate/high/normal/low)
  - Queue management per comandi multipli
  - Velocità ottimizzata (1.1x)

- ✅ **Voice UI Components**
  - VoiceIndicator animato (stato microfono)
  - VoiceCalibrationView per setup
  - Popup selezione speaker se ambiguo
  - Toggle voice nel menu di gioco
  - Feedback visivo e haptic integrato

### 🎨 Phase 3 (Polish) - **DA IMPLEMENTARE**

- ⬜ Animazioni avanzate per eliminazioni
- ⬜ Effetti sonori custom
- ⬜ Tutorial interattivo first-launch
- ⬜ Statistiche avanzate (win rate, comandanti più usati)
- ⬜ Esportazione dati (CSV, JSON)
- ⬜ iCloud sync per partite salvate
- ⬜ Widget iOS per quick stats
- ⬜ Siri Shortcuts integration

## 🛠️ Setup Xcode - Guida Completa Passo-Passo

### Prerequisiti

- **Xcode 15.0+** (con Swift 6.0 support)
- **iOS 17.0+** come deployment target
- **macOS Sonoma 14.0+**
- **Apple Developer Account** (per testing su device reale)

### Installazione Dettagliata

#### Passo 1: Clona il Repository

```bash
git clone https://github.com/tuouser/eneriumcompanion.git
cd eneriumcompanion
```

#### Passo 2: Crea Progetto Xcode

1. **Apri Xcode**
2. Seleziona **File → New → Project** (⌘⇧N)
3. Scegli template:
   - Platform: **iOS**
   - Template: **App**
   - Click **Next**

4. Configura progetto:
   ```
   Product Name: CommanderScorekeeper
   Team: [Il tuo team Apple Developer]
   Organization Identifier: com.tuodominio
   Bundle Identifier: com.tuodominio.CommanderScorekeeper
   Interface: SwiftUI
   Language: Swift
   Storage: Core Data ✓ (IMPORTANTE!)
   Include Tests: ✓ (opzionale)
   ```

5. Scegli location e **Create**

#### Passo 3: Importa Files del Repository

1. **Chiudi Xcode** temporaneamente

2. Nel Finder, vai alla cartella del progetto appena creato

3. **Elimina** i file auto-generati:
   ```
   CommanderScorekeeper/ContentView.swift
   CommanderScorekeeper/CommanderScorekeeperApp.swift
   CommanderScorekeeper.xcdatamodeld/ (cartella completa)
   ```

4. **Copia** l'intera cartella `CommanderScorekeeper/` dal repository clonato nella root del progetto Xcode

5. La struttura finale dovrebbe essere:
   ```
   ProjectRoot/
   ├── CommanderScorekeeper.xcodeproj/
   └── CommanderScorekeeper/
       ├── App/
       ├── Models/
       ├── ViewModels/
       ├── Views/
       ├── Services/
       ├── Resources/
       └── Utilities/
   ```

#### Passo 4: Apri e Configura Xcode

1. **Riapri** `CommanderScorekeeper.xcodeproj` in Xcode

2. Nel **Project Navigator** (pannello sinistro), vedrai tutti i file importati

3. **Aggiungi File al Target**:
   - Seleziona la cartella `CommanderScorekeeper` nel Project Navigator
   - Trascina tutte le sottocartelle nel progetto se non già presenti
   - Quando richiesto, seleziona:
     - ✅ Copy items if needed
     - ✅ Create groups
     - ✅ Add to targets: CommanderScorekeeper

4. **Verifica File Inspector**:
   - Seleziona un file qualsiasi (es. `ContentView.swift`)
   - Nel pannello destro, sotto "Target Membership"
   - Assicurati che **CommanderScorekeeper** sia selezionato

#### Passo 5: Configura Core Data Model

1. Nel Project Navigator, trova:
   ```
   Resources/CommanderScorekeeper.xcdatamodeld/
   ```

2. Fai click destro → **Show in Finder**

3. Verifica che esista il file:
   ```
   CommanderScorekeeper.xcdatamodel/contents
   ```

4. Torna in Xcode e apri il file `.xcdatamodeld`

5. Verifica che ci siano **3 entità**:
   - **GameSession** (6 attributi + 2 relationships)
   - **Player** (15 attributi + 1 relationship)
   - **GameAction** (9 attributi + 1 relationship)

6. Se non visualizzato correttamente:
   - Elimina dal progetto (Delete → Remove Reference)
   - Trascina di nuovo dal Finder
   - Seleziona "Add to targets"

#### Passo 6: Aggiungi Resources

1. Verifica `Commanders.json`:
   - Deve essere in `Resources/Commanders.json`
   - File Inspector → Target Membership: ✅ CommanderScorekeeper
   - Type: Default - JSON

2. Se `Assets.xcassets` non esiste:
   - File → New → File
   - Resource → Asset Catalog
   - Nome: `Assets`
   - Salva in `Resources/`

#### Passo 7: Configura Build Settings

1. Seleziona il **target CommanderScorekeeper** (icona blu nel Project Navigator)

2. Tab **General**:
   ```
   Display Name: Commander Scorekeeper
   Bundle Identifier: com.tuodominio.CommanderScorekeeper
   Version: 1.0
   Build: 1
   Deployment Info:
     - iOS: 17.0
     - iPhone Orientation: Portrait, Landscape Left, Landscape Right
     - iPad Orientation: All
   ```

3. Tab **Signing & Capabilities**:
   - Team: [Seleziona il tuo team]
   - ✅ Automatically manage signing
   - Provisioning Profile: Automatic

4. Tab **Build Settings** (cerca con ⌘F):

   **Swift Language Version**:
   ```
   SWIFT_VERSION = 6.0 (o latest)
   ```

   **iOS Deployment Target**:
   ```
   IPHONEOS_DEPLOYMENT_TARGET = 17.0
   ```

   **Enable Strict Concurrency Checking**:
   ```
   SWIFT_STRICT_CONCURRENCY = Complete
   ```

#### Passo 8: Verifica Info.plist

1. Se `Info.plist` non è presente:
   - File → New → File
   - Resource → Property List
   - Nome: `Info.plist`
   - Salva nella root del target

2. **Aggiungi Privacy Descriptions** (OBBLIGATORI per Phase 2):

   Nel target → Info tab → Custom iOS Target Properties, aggiungi:

   ```xml
   Key: Privacy - Microphone Usage Description
   Type: String
   Value: Commander Scorekeeper utilizza il microfono per il riconoscimento vocale dei comandi durante la partita.

   Key: Privacy - Speech Recognition Usage Description
   Type: String
   Value: Commander Scorekeeper utilizza il riconoscimento vocale per permetterti di controllare la partita a mani libere.
   ```

   Oppure edita direttamente il file XML aggiungendo:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Commander Scorekeeper utilizza il microfono per il riconoscimento vocale dei comandi durante la partita.</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>Commander Scorekeeper utilizza il riconoscimento vocale per permetterti di controllare la partita a mani libere.</string>
   ```

#### Passo 9: Build del Progetto

1. Seleziona un **simulatore** dalla toolbar:
   - Recommended: **iPhone 15 Pro** (performance ottimali)
   - Alternative: iPhone 14 Pro, iPad Pro

2. **Clean Build Folder**:
   - Product → Clean Build Folder (⌘⇧K)

3. **Build** il progetto:
   - Product → Build (⌘B)

4. **Attendi la compilazione**:
   - Dovrebbe completare senza errori
   - Warnings ammessi (es. unused variables in preview)

5. Se ci sono **errori di compilazione**:
   - Vedi sezione "Troubleshooting" sotto

#### Passo 10: Run dell'App

1. **Run** sul simulatore:
   - Product → Run (⌘R)
   - Oppure click sul ▶️ play button

2. **L'app si avvia** e dovresti vedere:
   - Welcome screen con "Commander Scorekeeper"
   - Icona corona dorata
   - Bottone "Nuova Partita"
   - Bottone "Partite Salvate"

3. **Test rapido**:
   - Tap "Nuova Partita"
   - Inserisci 4 giocatori
   - Cerca comandanti (autocomplete funziona)
   - Seleziona colori
   - Tap "Rivedi e Inizia"
   - Tap "Inizia Partita!"
   - Game screen si apre con 4 quadranti

#### Passo 11: Testing Voice (Opzionale - Richiede Device Reale)

**NOTA**: Voice recognition **NON funziona** sul simulatore (manca microfono hardware).

Per testare Phase 2, **devi usare un device reale**:

1. **Collega iPhone/iPad** via USB

2. In Xcode, seleziona il **tuo device** dalla toolbar

3. Se richiesto:
   - Trust this computer sul device
   - Inserisci passcode
   - Autorizza developer certificate

4. **Run** sul device (⌘R)

5. **Al primo lancio**, l'app chiederà permessi:
   - "Consenti accesso al microfono?" → **Consenti**
   - "Consenti riconoscimento vocale?" → **Consenti**

6. **Test voice flow**:
   - Avvia partita
   - Menu → "Attiva Voce"
   - Dici: "Hey Commander"
   - Schermo pulsa blu
   - Dici: "Guadagno 5 vite"
   - TTS conferma azione

## 🎮 Utilizzo Completo

### Avvio Partita

1. **Tap "Nuova Partita"** dalla schermata principale
2. **Configura 4 giocatori**:
   - Inserisci nome giocatore
   - Cerca comandante (autocomplete attivo)
   - Seleziona identità colore
   - **[Opzionale]** Tap "Calibra Voce" e registra 3 campioni
3. **Tap "Rivedi e Inizia"** per vedere il riepilogo
4. **Tap "Inizia Partita!"** per entrare nel game screen

### Durante la Partita (Controlli Manuali)

#### Tracking Vita
- **Tap sul quadrante** di un giocatore
- Tab "Vita"
- Usa quick buttons (±1, ±5, ±10)
- O inserisci valore personalizzato
- Tap "Applica"

#### Danni Comandante
- **Tap sul quadrante** del difensore
- Tab "Cmd Dmg"
- Seleziona attaccante
- Tap bottone +X per aggiungere danno

#### Counter (Poison/Energy/Experience)
- **Tap sul quadrante**
- Tab "Counter"
- Usa bottoni +1, +3, +5 per aggiungere
- Bottone -1 per rimuovere

#### Stati Speciali
- **Tap sul quadrante**
- Tab "Stato"
- Tap "Monarch" o "Initiative" per attivare

### Durante la Partita (Voice Commands) 🎤

#### Attivazione Voice

1. **Tap icona menu** (⋯) in alto a destra
2. **Tap "Attiva Voce"**
3. Indicatore microfono diventa **GRIGIO** (standby)
4. Dici: **"Hey Commander"** (o "Ehi Commander")
5. Schermo pulsa **BLU** → microfono attivo
6. Hai 5 secondi per dire il comando

#### Comandi Vita

```
"Guadagno 5 vite"
"Perdo 10 vite"
"Alice guadagna 3 vite"
"Bob perde 8 vite"
```

#### Comandi Danni Comandante

```
"Subisco 12 da Atraxa"
"Prendo 8 da comandante rosso"
"Alice subisce 21 da Krenko"
"Do 15 da comandante a Bob"
```

#### Comandi Poison

```
"Prendo 3 poison"
"Alice prende 5 veleno"
"Do 2 poison a Bob"
```

#### Comandi Energy

```
"Aggiungi 10 energy"
"Alice guadagna 5 energy"
"Rimuovi 3 energy"
```

#### Comandi Experience

```
"Guadagno 2 experience"
"Aggiungi 1 experience"
```

#### Comandi Stati

```
"Divento il Monarch"
"Bob prende il Monarch"
"Prendo l'iniziativa"
"Alice ha l'iniziativa"
```

#### Feedback Voice

Dopo ogni comando:
- ✅ **Comando riconosciuto**: TTS conferma ("Fatto! Guadagno 5 vite")
- ❌ **Comando non capito**: TTS chiede ("Non ho capito, puoi ripetere?")
- ❓ **Speaker ambiguo**: Popup "Chi ha parlato?" → seleziona nome

### Controlli Generali

- **Pausa/Resume**: Ferma/riprendi timer (e voice se attivo)
- **Annulla**: Ripristina ultima azione (max 10 undo)
- **Log Completo**: Vedi tutte le azioni con timestamp
- **Salva Partita**: Salvataggio manuale (auto-save ogni 30s)
- **Termina Partita**: Segna partita come completata

### Caricamento Partita Salvata

1. Home → "Partite Salvate"
2. Sezione "In Corso" o "Terminate"
3. Tap su partita
4. Game screen si apre con stato esatto
5. Continua partita

## 🐛 Troubleshooting

### Errori di Build

#### "Cannot find type 'Player' in scope"

**Soluzione**:
1. Verifica che `Models/Player.swift` sia nel target
2. Project Navigator → Seleziona file
3. File Inspector → Target Membership: ✅ CommanderScorekeeper

#### "No such module 'CoreData'"

**Soluzione**:
1. Target → General → Frameworks, Libraries, and Embedded Content
2. Click `+`
3. Aggiungi `CoreData.framework`

#### "Failed to load model named 'CommanderScorekeeper'"

**Soluzione**:
1. Verifica percorso Core Data model: `Resources/CommanderScorekeeper.xcdatamodeld`
2. Apri file e verifica 3 entità presenti
3. Clean Build Folder (⌘⇧K)
4. Rebuild (⌘B)

#### Build succeed ma app crasha all'avvio

**Soluzione**:
1. Product → Clean Build Folder
2. Simulator → Device → Erase All Content and Settings
3. Rebuild e re-run

### Problemi Voice Recognition

#### "Microfono non disponibile"

**Causa**: Stai usando il simulatore

**Soluzione**: Usa un **device reale** (iPhone/iPad)

#### "Autorizzazione negata"

**Soluzione**:
1. iPhone Settings → Privacy & Security → Microphone
2. Trova "Commander Scorekeeper"
3. Abilita toggle

#### Wake word non rilevato

**Soluzioni**:
1. Parla più chiaramente e lentamente
2. Prova variante: "Hey Commander" vs "Ehi Commander"
3. Aumenta volume voce
4. Riduci rumore ambientale
5. Verifica microfono funzionante (prova Memo Vocali)

#### Comandi non riconosciuti

**Soluzioni**:
1. Usa frasi dal reference (vedi COMMANDS.md)
2. Parla naturalmente, non roboticamente
3. Aspetta "ding" prima di parlare
4. Pronuncia nomi giocatori/comandanti chiaramente
5. Evita abbreviazioni non standard

#### Speaker recognition sbagliata

**Soluzioni**:
1. Ri-calibra voice profiles (Setup → Calibra Voce)
2. Assicurati voci distinguibili (tono, volume diversi)
3. Usa popup manuale se confidence sempre <85%

#### TTS non parla

**Soluzioni**:
1. Verifica volume device non silenziato
2. Verifica TTS attivo (non disabilitato in settings)
3. Riavvia app
4. Settings → Accessibility → Spoken Content → check abilitato

### Performance Issues

#### App lenta/framerate basso

**Soluzioni**:
1. Testa su iPhone 12+ (raccomandato)
2. Chiudi app in background
3. Riavvia device
4. Verifica storage device non pieno

#### Voice latency alta

**Soluzioni**:
1. Connessione internet stabile (Speech API usa server Apple)
2. Disabilita altre app che usano microfono
3. Riduci carico CPU (chiudi app pesanti)

## 📊 Statistiche Progetto

```
Total Files: 29 Swift files + 4 docs
Total Lines: ~5,700+ lines of code
Architecture: MVVM + Combine
UI Framework: 100% SwiftUI
Storage: 100% Core Data
Voice: Speech Framework + AVFoundation
Test Coverage: 0% (to implement Phase 3)

Services: 5 files (~2,500 lines)
  - VoiceRecognitionService
  - SpeakerIdentificationService
  - NLPCommandParser
  - TextToSpeechService
  - PersistenceController

ViewModels: 3 files (~1,200 lines)
  - SetupViewModel
  - GameViewModel
  - VoiceRecognitionViewModel

Views: 13 files (~1,800 lines)
  - Setup flow (3 files)
  - Game screen (5 files)
  - Saved games (2 files)
  - Voice components (3 files)

Models: 4 files (~700 lines)
  - Core Data entities
  - Commander database
```

## 🗺️ Roadmap

### v1.0 (Phase 1) - ✅ COMPLETE
- ✅ Core gameplay tracking
- ✅ Manual controls
- ✅ Persistence
- ✅ Professional UI/UX

### v1.1 (Phase 2) - ✅ COMPLETE
- ✅ Voice recognition
- ✅ Speaker identification
- ✅ Natural language commands (Italian)
- ✅ Text-to-speech feedback

### v1.2 (Phase 3) - 🚧 PLANNED
- ⬜ Advanced animations
- ⬜ Sound effects
- ⬜ Statistics dashboard
- ⬜ Data export (CSV/JSON)
- ⬜ Tutorial first-launch

### v2.0 - 💭 FUTURE
- ⬜ iCloud sync
- ⬜ Custom commanders
- ⬜ Deck tracking
- ⬜ Tournament mode
- ⬜ Multiplayer scoring
- ⬜ Siri Shortcuts
- ⬜ iOS Widget

## 📄 Comandi Vocali Reference

Vedi **[COMMANDS.md](COMMANDS.md)** per la lista completa di tutti i comandi vocali supportati con esempi.

## 📱 Compatibilità

- **iPhone**: SE (3rd gen), 12, 13, 14, 15 series
- **iPad**: tutti i modelli con iOS 17+
- **Orientamento**: Portrait (setup), Portrait/Landscape (game)
- **Accessibilità**: VoiceOver ready, Dynamic Type ready
- **Voice**: Solo su device reali (microfono hardware richiesto)

## 📝 File Structure

Vedi **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** per la documentazione completa dell'architettura.

## 🤝 Contributing

1. Fork il repository
2. Crea branch (`git checkout -b feature/amazing-feature`)
3. Commit (`git commit -m 'feat: Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Apri Pull Request

### Code Style

- Segui [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Usa SwiftLint (config incluso)
- Documenta funzioni pubbliche
- Scrivi test per business logic

## 📄 License

Questo progetto è rilasciato sotto licenza MIT. Vedi `LICENSE` per dettagli.

## 🙏 Credits

- **Magic: The Gathering** è un trademark di Wizards of the Coast
- Commander database basato su EDHREC
- Icons da SF Symbols
- Voice powered by Apple Speech Framework

## 📧 Supporto

Per bug report, feature request o domande:
- Apri un issue su GitHub
- Consulta SETUP.md per problemi di configurazione
- Consulta COMMANDS.md per comandi vocali

---

**Fatto con ❤️ per la community Magic**

*"May your draws be gas, your opponents' be lands, and your voice commands be recognized."* 🎤⚔️

**Phase 2 COMPLETE** - Ready for voice-controlled Commander games! 🎉
