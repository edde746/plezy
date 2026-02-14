# Piano di Porting: Plezy → webOS (LG TV)

## Analisi dello stato attuale

**Plezy** è un client Plex Flutter multi-piattaforma (Android, iOS, macOS, Windows, Linux) con:
- Navigazione D-pad/TV già implementata (`lib/focus/` - FocusableWrapper, DpadNavigator, InputModeTracker)
- UI adattiva TV con side-navigation, focusable widgets, e controller support
- Video player basato su **MPV** (nativo, non disponibile su web)
- Database locale **Drift/SQLite** per cache API e download
- Dipendenze pesanti su `dart:io` (`Platform.isAndroid`, ecc.)
- Numerosi plugin nativi (window_manager, os_media_controls, gamepad, PiP, ecc.)

## Strategia: Flutter Web → webOS Web App (IPK)

webOS è basato su un runtime web (Chromium). La strategia più efficace è compilare Plezy come **Flutter Web app** e pacchettizzarla come **webOS Hosted Web App** (.ipk). Questo massimizza il riuso del codice esistente.

---

## Fasi di lavoro

### Fase 1: Infrastruttura Web e Astrazione Piattaforma

**1.1 - Abilitare Flutter Web**
- Aggiungere la directory `web/` con `index.html` e web manifest
- Configurare `CanvasKit` renderer (migliore resa grafica per TV)
- Aggiungere profilo di build per webOS

**1.2 - Eliminare dipendenze dirette da `dart:io`**
- `main.dart` usa `Platform.isAndroid`, `Platform.isMacOS`, ecc. → sostituire con conditional imports
- Creare `lib/utils/platform_stub.dart` (web) e `lib/utils/platform_native.dart` (nativo) con pattern di conditional import (`platform_detector_web.dart` / `platform_detector_native.dart`)
- Aggiornare `PlatformDetector` per riconoscere webOS come piattaforma TV

**1.3 - Creare layer di astrazione per plugin nativi**
- Definire interfacce astratte per servizi dipendenti dalla piattaforma
- Implementare stub/no-op per web per: `window_manager`, `os_media_controls`, `wakelock_plus`, `universal_gamepad`, `pip_service`, `saf_stream/saf_util`, `mobile_scanner`, `android_intent_plus`, `background_downloader`, `workmanager`, `dart_discord_presence`
- Usare conditional imports per switchare tra implementazione nativa e web

### Fase 2: Video Player per webOS

**2.1 - Creare `WebVideoPlayer` basato su HTML5 `<video>`**
- Implementare un wrapper Flutter che usa `HtmlElementView` per embedare un elemento `<video>` HTML5
- Esporre la stessa interfaccia del player MPV attuale (play, pause, seek, volume, tracks)
- Gestire stream/eventi di stato (posizione, durata, buffering, errore)

**2.2 - Integrazione con webOS Media API**
- Usare `webOSSystem` JS interop per accedere alle API native TV
- Configurare il media pipeline webOS per playback ottimale (Direct Play dove possibile)
- Gestire codec supportati dal TV (H.264, H.265/HEVC, VP9, AV1 sui modelli recenti)
- Implementare gestione HDR se il TV lo supporta

**2.3 - Subtitle rendering**
- Utilizzare il renderer sottotitoli nativo del `<video>` (WebVTT)
- Per formati ASS/SSA: conversione lato client o fallback a testo semplice
- Rispettare le impostazioni di stile sottotitoli esistenti (`subtitle_font_size`, colore, ecc.)

**2.4 - Adattare `VideoPlayerScreen`**
- Conditional import per selezionare `MpvPlayer` (nativo) vs `WebVideoPlayer` (web/webOS)
- Riusare completamente i controlli video esistenti (`video_controls/`)
- Adattare la gestione dei tasti del telecomando webOS (play/pause/stop/ff/rw)

### Fase 3: Storage e Database per Web

**3.1 - Drift Web (IndexedDB)**
- Drift supporta nativamente il web tramite `drift/web.dart` con `WasmDatabase` o `WebDatabase`
- Aggiungere dipendenza `drift/web` e conditional import nel `AppDatabase`
- Le tabelle esistenti (ApiCache, DownloadQueue, ecc.) funzionano invariate

**3.2 - Shared Preferences Web**
- `shared_preferences` supporta già il web (usa `localStorage`) → nessuna modifica necessaria

**3.3 - Storage Service**
- Adattare `StorageService` per web (niente accesso filesystem)
- `path_provider` non funziona su web → usare localStorage/IndexedDB per token e configurazione

### Fase 4: Feature Gating per webOS

**4.1 - Funzionalità da disabilitare su webOS**
- **Download/Offline**: niente filesystem, disabilitare completamente Download e OfflineMode
- **Picture-in-Picture**: non disponibile, nascondere opzione
- **Player esterno**: non applicabile su TV
- **Discord Rich Presence**: non disponibile su web
- **Scanner QR**: non disponibile (usare flow alternativo per pairing)
- **Gamepad fisico**: usare il telecomando webOS (che mappa su tasti standard)
- **Shader/upscaling**: gestiti dal TV hardware, rimuovere opzione
- **File picker / SAF**: non disponibile
- **In-App Review**: non applicabile

**4.2 - Funzionalità da adattare**
- **Autenticazione**: flow OAuth via browser integrato webOS (o PIN-based auth)
- **Wakelock**: usare webOS `keepAlive` API
- **Orientamento**: fisso landscape, nessuna rotazione necessaria
- **Window management**: fullscreen always, nessuna gestione finestra

### Fase 5: UI e UX per webOS TV

**5.1 - Layout TV ottimizzato (10-foot UI)**
- L'app ha già side-navigation e focusable widgets → riusare
- Verificare dimensioni font e padding per leggibilità a distanza (min 24sp)
- Verificare contrasto e safe-area TV (overscan margin 5%)
- Assicurare che tutti gli elementi interattivi abbiano indicatore di focus visibile

**5.2 - Telecomando webOS (Magic Remote)**
- Il Magic Remote genera eventi pointer (cursore) E tasti D-pad
- Il sistema focus Flutter esistente gestisce già i tasti arrow → funziona out-of-the-box
- Mappare tasti speciali webOS: Back (461), Color buttons (403-406), Channel Up/Down
- I tasti media del telecomando (Play/Pause/Stop/FF/RW) → video player controls

**5.3 - Navigazione e flow**
- Tab iniziale: Home/Discover → primo contenuto immediatamente visibile
- Animazioni: ridurre/semplificare per hardware TV (performance)
- Scroll: assicurare scroll fluido in liste lunghe (virtualizzazione)

### Fase 6: Configurazione e Packaging webOS

**6.1 - Struttura webOS app**
```
webos/
├── appinfo.json          # Manifest app webOS (id, title, type, version)
├── icon.png              # Icona app 80x80
├── largeIcon.png         # Icona grande 130x130
├── splash.png            # Splash screen
└── index.html            # Entry point (redirect a Flutter web build)
```

**6.2 - appinfo.json**
```json
{
  "id": "com.plezy.app",
  "version": "1.16.1",
  "vendor": "Plezy",
  "type": "web",
  "main": "index.html",
  "title": "Plezy",
  "icon": "icon.png",
  "largeIcon": "largeIcon.png",
  "resolution": "1920x1080",
  "disableBackHistoryAPI": true,
  "handlesRelaunch": true
}
```

**6.3 - Tooling webOS**
- Installare `@anthropic/webos-cli` (ares-cli) per build/deploy/debug
- Script di build: `flutter build web --web-renderer canvaskit` → copia in cartella webOS → `ares-package`
- Deploy su TV: `ares-install --device <tv>` per testing
- Debug: `ares-inspect` per Chrome DevTools remoto

**6.4 - Script di build automatizzato**
- Creare `scripts/build_webos.sh` che:
  1. Esegue `flutter build web --release --web-renderer canvaskit`
  2. Copia il build in `webos/`
  3. Aggiunge `appinfo.json` e icone
  4. Pacchettizza con `ares-package`

### Fase 7: Ottimizzazione Performance

**7.1 - CanvasKit ottimizzazioni**
- Ridurre dimensione bundle (tree-shaking, defer loading)
- Pre-caricare CanvasKit WASM
- Lazy loading delle schermate non iniziali

**7.2 - Performance TV**
- I TV LG hanno CPU/GPU limitati rispetto a desktop/mobile
- Ridurre animazioni complesse (blur, shadow, scale)
- Ottimizzare image cache per memoria limitata
- Limitare numero di immagini caricate simultaneamente nelle grid
- Testare su hardware TV reale (WebOS 4.x+, 5.x, 6.x)

**7.3 - Startup time**
- Implementare splash screen nativo webOS
- Caricare dati critici in parallelo
- Ridurre dimensione asset (comprimere font da 14.7MB)

### Fase 8: Testing e Distribuzione

**8.1 - Testing**
- Test su emulatore webOS (VirtualBox image da LG developer portal)
- Test su TV fisico (Developer Mode app)
- Verificare tutti i flow: auth → browse → play → back
- Test con telecomando fisico (D-pad + pointer)
- Test codec video (H.264, HEVC, sottotitoli)
- Test performance su TV entry-level

**8.2 - Distribuzione**
- **Sideload**: file .ipk installabile via Developer Mode (per beta)
- **LG Content Store**: submission ufficiale (richiede account developer LG, review process)
- **Homebrew**: distribuzione su community webOS (Homebrew Channel)

---

## Ordine di priorità e dipendenze

```
Fase 1 (Infrastruttura) ──→ Fase 2 (Video Player)
         │                          │
         ├──→ Fase 3 (Storage)      │
         │                          │
         └──→ Fase 4 (Feature Gate) │
                                    │
              Fase 5 (UI/UX) ───────┘
                    │
              Fase 6 (Packaging) ──→ Fase 7 (Performance) ──→ Fase 8 (Testing)
```

**Fase 1** è prerequisito per tutto. **Fasi 2, 3, 4** possono procedere in parallelo dopo la Fase 1. **Fase 5** richiede il video player funzionante. **Fasi 6-8** sono sequenziali alla fine.

## Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---------|---------|-------------|
| Performance Flutter Web su TV | Alto | CanvasKit + ottimizzazioni aggressive, test precoce su hardware |
| Codec video non supportati | Alto | Configurare transcoding Plex server, rilevare codec TV |
| `dart:io` pervasivo nel codice | Medio | Conditional imports sistematici, refactor graduale |
| Memoria limitata TV | Medio | Ridurre image cache, lazy loading, profiling |
| Auth flow su TV (no keyboard) | Basso | PIN-based auth (Plex lo supporta già) |
| webOS versioni diverse (4.x-6.x) | Medio | Target minimo webOS 4.0+, test su multiple versioni |
