# Commander Scorekeeper - Setup Xcode

Questa guida ti aiuterà a creare il progetto Xcode e importare tutti i file sorgente.

## 🎯 Obiettivo

Creare un progetto Xcode funzionante partendo dai file Swift forniti.

## 📋 Prerequisiti

- **Xcode 15.0+** installato
- **macOS Sonoma 14.0+**
- Questo repository clonato localmente

## 🔧 Procedura Setup

### Step 1: Crea Nuovo Progetto Xcode

1. Apri **Xcode**
2. Seleziona **File → New → Project** (⌘⇧N)
3. Scegli template:
   - Platform: **iOS**
   - Template: **App**
   - Click **Next**

4. Configura il progetto:
   ```
   Product Name: CommanderScorekeeper
   Team: [Il tuo team]
   Organization Identifier: com.yourdomain
   Bundle Identifier: com.yourdomain.CommanderScorekeeper
   Interface: SwiftUI
   Language: Swift
   Storage: Core Data ✓ (IMPORTANTE!)
   ```

5. Salva in una location temporanea (puoi cancellare dopo)

### Step 2: Prepara il Progetto

1. **Chiudi Xcode** completamente
2. Vai alla cartella dove hai salvato il progetto
3. **Elimina** questi file generati automaticamente:
   ```
   CommanderScorekeeper/ContentView.swift
   CommanderScorekeeper/CommanderScorekeeperApp.swift
   CommanderScorekeeper/Item.swift (se presente)
   CommanderScorekeeper.xcdatamodeld/
   ```

### Step 3: Copia i File del Repository

1. Dalla cartella di questo repository, **copia** tutta la cartella `CommanderScorekeeper/` nella root del progetto Xcode

2. La struttura dovrebbe essere:
   ```
   ProjectRoot/
   ├── CommanderScorekeeper.xcodeproj/
   └── CommanderScorekeeper/
       ├── App/
       │   ├── CommanderScorekeeperApp.swift
       │   └── ContentView.swift
       ├── Models/
       ├── ViewModels/
       ├── Views/
       ├── Services/
       ├── Resources/
       └── Utilities/
   ```

### Step 4: Apri e Configura Xcode

1. **Apri** `CommanderScorekeeper.xcodeproj` in Xcode

2. Nel **Project Navigator** (pannello sinistro), seleziona il progetto (icona blu)

3. Verifica **General** settings:
   - Display Name: `Commander Scorekeeper`
   - Bundle Identifier: `com.yourdomain.CommanderScorekeeper`
   - Version: `1.0`
   - Build: `1`
   - Deployment Target: **iOS 17.0**

4. Vai a **Signing & Capabilities**:
   - Seleziona il tuo Team
   - Abilita "Automatically manage signing"

### Step 5: Aggiungi File al Target

1. Nel **Project Navigator**, espandi la cartella `CommanderScorekeeper`

2. Seleziona **TUTTI** i file e cartelle

3. Verifica che nel **File Inspector** (pannello destro) sotto "Target Membership" sia selezionato **CommanderScorekeeper**

4. Se alcuni file non sono nel target:
   - Selezionali
   - Spunta la checkbox **CommanderScorekeeper** nel Target Membership

### Step 6: Configura Core Data Model

1. Nel Project Navigator, trova `Resources/CommanderScorekeeper.xcdatamodeld/`

2. Click destro → **Show in Finder**

3. Verifica che dentro ci sia il file `CommanderScorekeeper.xcdatamodel/contents`

4. Se Xcode non lo riconosce:
   - Elimina il `.xcdatamodeld` dal progetto
   - Trascina di nuovo dal Finder
   - Assicurati sia nel target

5. Apri il file `.xcdatamodeld` in Xcode e verifica che ci siano 3 entità:
   - **GameSession**
   - **Player**
   - **GameAction**

### Step 7: Configura Resources

1. Verifica che `Commanders.json` sia presente in `Resources/`

2. Nel **File Inspector**, assicurati che:
   - Target Membership: **CommanderScorekeeper** ✓
   - Type: **Default - JSON**

3. Se `Assets.xcassets` non esiste, crealo:
   - File → New → File
   - Resource → Asset Catalog
   - Nome: `Assets`
   - Salvalo in `Resources/`

### Step 8: Build Settings

1. Seleziona il **target CommanderScorekeeper**

2. Vai a **Build Settings**

3. Cerca "Swift Language Version":
   - Imposta a **Swift 6** (o latest)

4. Cerca "iOS Deployment Target":
   - Imposta a **17.0**

5. Cerca "Enable Strict Concurrency Checking":
   - Imposta a **Yes**

### Step 9: Info.plist

1. Se `Info.plist` non è presente, crealo:
   - File → New → File
   - Resource → Property List
   - Nome: `Info.plist`

2. Copia il contenuto dal file `Info.plist` fornito

3. Nel **target settings → Info**, verifica:
   - Custom iOS Target Properties contiene tutte le chiavi

### Step 10: Build e Test

1. Seleziona un simulatore (iPhone 15 Pro recommended)

2. Click **Product → Build** (⌘B)

3. **Risolvi eventuali errori** (vedi sezione Troubleshooting sotto)

4. Click **Product → Run** (⌘R)

5. L'app dovrebbe:
   - Launchare senza crash
   - Mostrare la welcome screen
   - Permettere di creare una nuova partita

## 🐛 Troubleshooting

### Errore: "Cannot find type 'Player' in scope"

**Soluzione**: Verifica che tutti i file in `Models/` siano nel target.

### Errore: "No such module 'CoreData'"

**Soluzione**:
1. Target → General → Frameworks
2. Click `+`
3. Aggiungi `CoreData.framework`

### Errore: "Type 'GameSession' has no member 'playersArray'"

**Soluzione**: Assicurati che il file `GameSession.swift` sia compilato DOPO `Player.swift`. Vai a Build Phases → Compile Sources e riordina.

### Errore: "Failed to load model named 'CommanderScorekeeper'"

**Soluzione**:
1. Verifica che `.xcdatamodeld` sia nella root del target
2. Apri il file e assicurati che le entità siano definite
3. Clean Build Folder (⌘⇧K) e rebuild

### Warning: "immutable value X was never used"

**Soluzione**: Normale in fase di sviluppo, puoi ignorare o commentare il codice non usato.

### Simulatore crash all'avvio

**Soluzione**:
1. Product → Clean Build Folder (⌘⇧K)
2. Chiudi simulatore
3. Reset simulatore: Device → Erase All Content and Settings
4. Rebuild e Run

### UI non appare correttamente

**Soluzione**:
1. Verifica che `@main` sia presente in `CommanderScorekeeperApp.swift`
2. Assicurati che `ContentView` sia impostato come root view
3. Controlla che Preview non interferisca (commenta `#Preview`)

## ✅ Verifica Setup Completo

Dopo il setup, verifica che funzioni tutto:

- [ ] App si apre senza crash
- [ ] Welcome screen mostra "Commander Scorekeeper"
- [ ] Bottone "Nuova Partita" funziona
- [ ] Puoi inserire 4 giocatori
- [ ] Autocomplete comandanti funziona
- [ ] Puoi iniziare una partita
- [ ] Game screen mostra 4 quadranti
- [ ] Tap su quadrante apre controlli
- [ ] Modifiche vita funzionano
- [ ] Auto-save funziona (aspetta 30s)
- [ ] Partite salvate appare nella lista

## 📚 Prossimi Passi

1. **Testa tutte le funzionalità** seguendo il README
2. **Personalizza** colori, assets, bundle ID
3. **Aggiungi Assets**: icona app, launch screen
4. **Implementa Phase 2**: voice recognition
5. **Deploy** su TestFlight per beta testing

## 🆘 Aiuto

Se incontri problemi non risolti da questa guida:

1. Controlla la console di Xcode per errori specifici
2. Verifica che tutti i file siano nel target giusto
3. Prova a fare Clean Build (⌘⇧K) e rebuild
4. Apri un issue su GitHub con:
   - Versione Xcode
   - Messaggio di errore completo
   - Screenshot se pertinente

## 📝 Note Finali

- **Backup** del progetto prima di modifiche importanti
- Usa **Git** per version control (già configurato con `.gitignore`)
- Testa su **dispositivi reali** oltre al simulatore
- Performance ottimali su **iPhone 12** e successivi

---

**Setup completato!** 🎉

Ora sei pronto per giocare a Commander e tracciare i tuoi punteggi come un professionista!
