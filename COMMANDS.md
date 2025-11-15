# Comandi Vocali - Reference Card

**⚠️ NOTA**: I comandi vocali saranno disponibili in **Phase 2**. Questo documento serve come riferimento per l'implementazione futura.

## 🎤 Wake Word

Per attivare il riconoscimento vocale, pronuncia:

- **"Hey Commander"**
- **"Ehi Commander"**

Il bordo dello schermo pulserà **BLU** quando il microfono è attivo.

---

## 💚 Comandi Vita

### Guadagnare Vita

```
"Guadagno [X] vite"
"Guadagno [X] vita"
"[Nome] guadagna [X] vite"
"Aggiungi [X] vite a [Nome]"
```

**Esempi**:
- "Guadagno 5 vite"
- "Alice guadagna 10 vite"
- "Aggiungi 3 vite a Bob"

### Perdere Vita

```
"Perdo [X] vite"
"Perdo [X] vita"
"[Nome] perde [X] vite"
"Rimuovi [X] vite da [Nome]"
```

**Esempi**:
- "Perdo 8 vite"
- "Charlie perde 12 vite"
- "Rimuovi 5 vite da Diana"

---

## ⚔️ Danni da Comandante

### Ricevere Danni

```
"Subisco [X] da [NomeComandante]"
"Subisco [X] da comandante [Nome/Colore]"
"Prendo [X] da [NomeComandante]"
"[Nome] subisce [X] da [NomeComandante]"
"[Nome] prende [X] da comandante [Nome]"
```

**Esempi**:
- "Subisco 8 da Atraxa"
- "Prendo 5 da comandante rosso"
- "Alice subisce 12 da Krenko"
- "Bob prende 21 da comandante Charlie"

### Infliggere Danni

```
"Do [X] da comandante a [Nome]"
"Il mio comandante fa [X] a [Nome]"
"[X] danni da comandante a [Nome]"
```

**Esempi**:
- "Do 10 da comandante a Alice"
- "Il mio comandante fa 7 a Bob"
- "15 danni da comandante a Charlie"

---

## ☠️ Poison Counter

```
"Prendo [X] poison"
"Prendo [X] veleno"
"[Nome] prende [X] poison"
"[Nome] prende [X] veleno"
"Aggiungi [X] poison a [Nome]"
"Do [X] poison a [Nome]"
```

**Esempi**:
- "Prendo 3 poison"
- "Alice prende 2 veleno"
- "Do 5 poison a Bob"

---

## ⚡ Energy Counter

```
"Aggiungi [X] energy"
"Aggiungi [X] energy a [Nome]"
"[Nome] guadagna [X] energy"
"Rimuovi [X] energy"
"Rimuovi [X] energy da [Nome]"
```

**Esempi**:
- "Aggiungi 5 energy"
- "Alice guadagna 3 energy"
- "Rimuovi 2 energy da Bob"

---

## 🎓 Experience Counter

```
"Aggiungi [X] experience"
"Aggiungi [X] experience a [Nome]"
"[Nome] guadagna [X] experience"
"Rimuovi [X] experience"
```

**Esempi**:
- "Aggiungi 1 experience"
- "Charlie guadagna 2 experience"

---

## 👑 Monarch

```
"Divento il Monarch"
"Divento Monarch"
"Prendo il Monarch"
"[Nome] diventa il Monarch"
"[Nome] diventa Monarch"
"[Nome] prende il Monarch"
```

**Esempi**:
- "Divento il Monarch"
- "Alice diventa Monarch"
- "Bob prende il Monarch"

---

## 🎲 Initiative

```
"Prendo l'iniziativa"
"Divento l'iniziativa"
"[Nome] prende l'iniziativa"
"[Nome] ha l'iniziativa"
```

**Esempi**:
- "Prendo l'iniziativa"
- "Charlie prende l'iniziativa"
- "Diana ha l'iniziativa"

---

## 🔄 Utility

### Annulla

```
"Annulla"
"Annulla ultimo"
"Annulla ultima azione"
"Torna indietro"
```

### Ripeti

```
"Ripeti"
"Ripeti ultimo"
"Ripeti comando"
```

---

## 📝 Sinonimi Riconosciuti

Il sistema NLP riconosce automaticamente sinonimi e variazioni:

### Comandante
- "comandante", "commander", "general"
- Abbreviazioni: "cmd", "cmdr"

### Vita
- "vita", "vite", "life", "punti vita", "hp"

### Danni
- "danni", "danno", "damage"

### Poison
- "poison", "veleno", "poison counter", "infect"

### Energy
- "energy", "energia"

### Experience
- "experience", "esperienza", "exp"

---

## 🎯 Pattern Avanzati

### Riferimenti Multipli

```
"Alice e Bob perdono 5 vite"
→ Alice: -5, Bob: -5

"Tutti prendono 3 danni"
→ Tutti i giocatori: -3 vita
```

### Valori Relativi

```
"Alice ha la stessa vita di Bob"
→ Copia la vita di Bob su Alice

"Dimezza la mia vita"
→ Vita attuale / 2
```

---

## ⚠️ Casi Speciali

### Danni da Proprio Comandante

```
"Subisco 5 da Atraxa"
[Se Atraxa è il TUO comandante]
→ ❌ Errore: "Non puoi ricevere danni dal tuo stesso comandante"
```

### Doppi Negativi

```
"Perdo -5 vite"
→ ⚠️ Conferma: "Vuoi guadagnare 5 vite?"
```

### Valori Estremi

```
"Guadagno 1000 vite"
→ ⚠️ Warning ma permesso (per combo infinite)
```

---

## 🔊 Feedback Vocale (TTS)

Il sistema conferma le azioni con sintesi vocale:

### Successo
```
"Fatto! Alice ha perso 5 vite"
"8 danni da comandante Atraxa a Bob"
"Charlie ha 3 poison counter"
```

### Errore
```
"Non ho capito, puoi ripetere?"
"Comando non riconosciuto"
"Valore non valido"
```

### Conferma Ambigua
```
"Chi ha parlato?"
[Mostra bottoni con nomi giocatori]
```

---

## 🎤 Speaker Recognition

### Calibrazione

Durante il setup, ogni giocatore ripete il proprio **nome 3 volte**:

```
Giocatore: "Alice"
Sistema: 1/3 ✓

Giocatore: "Alice"
Sistema: 2/3 ✓

Giocatore: "Alice"
Sistema: 3/3 ✓ Calibrazione completa!
```

### Riconoscimento Automatico

Durante il gioco:

- **Confidence ≥85%**: Comando eseguito automaticamente
- **Confidence <85%**: Popup "Chi ha parlato?" con 4 bottoni

---

## 🚫 Limitazioni

### Non Supportato (Phase 2)

- ❌ Comandi concatenati ("Alice perde 5 e Bob guadagna 3")
- ❌ Condizioni ("Se Alice ha meno di 10 vite, guadagna 5")
- ❌ Matematica complessa ("Dimezza e arrotonda per eccesso")

### Verrà Implementato (Phase 3)

- ⏳ Comandi personalizzati definiti dall'utente
- ⏳ Macro (sequenze di comandi salvate)
- ⏳ Integrazione con Alexa/Siri Shortcuts

---

## 💡 Tips per Migliori Risultati

1. **Parla chiaramente** ma naturalmente
2. **Usa nomi brevi** per giocatori (evita "Alessandro", preferisci "Alex")
3. **Pronuncia wake word** con pausa dopo (1 secondo)
4. **Aspetta il "ding"** prima di dare il comando
5. **Ambiente silenzioso** migliora la precisione
6. **Riduci musica** in sottofondo durante voice commands

---

## 📊 Statistiche (Beta Testing)

| Metrica | Target | Attuale |
|---------|--------|---------|
| Wake Word Accuracy | >95% | TBD |
| Speaker Recognition | >85% | TBD |
| Command Understanding | >90% | TBD |
| False Positives | <5% | TBD |

---

## 🔧 Troubleshooting Voice

### Microfono non rileva

- Verifica permessi: Settings → Privacy → Microphone
- Riavvia app
- Check microfono hardware

### Wake word non funziona

- Prova variante: "Hey Commander" vs "Ehi Commander"
- Aumenta volume voce
- Disabilita/riabilita voice nelle impostazioni

### Comandi non riconosciuti

- Usa frasi dal reference (evita improvvisazioni)
- Parla più lentamente
- Ri-calibra voice profile

### Speaker recognition sbaglia

- Ri-calibra tutti i giocatori
- Usa popup manuale (disabilita auto-recognition)
- Assicurati che le voci siano distinguibili

---

**Voice commands powered by Speech Framework & AVFoundation** 🎤✨
