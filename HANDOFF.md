# Riimind handoff

## Current status

Features 1–3 are complete and verified. The app accepts natural-language text, extracts an event with Gemini, presents a review screen, and opens the native calendar editor for user confirmation. Feature 4 has not been started.

## Architecture overview

Riimind uses a feature-first Flutter structure. Presentation widgets live beside Riverpod providers, while parser domain data and Gemini integration are separated into `models` and `services`. `go_router` owns navigation, and `app.dart` is the composition root for theme and router configuration.

## Folder structure

```text
lib/
  core/                 # Theme and router
  features/
    home/               # Home screen composition
    input/              # Text input, clipboard actions, input state
    parser/             # Parsed event model, Gemini service, preview UI
    settings/           # Settings screen placeholder
  app.dart              # MaterialApp configuration
  main.dart             # Environment loading and ProviderScope
test/features/          # Parser and input/provider/widget tests
```

## Packages

- `flutter_riverpod`: shared input state and injectable parser service.
- `go_router`: declarative shell and preview navigation.
- `flutter_dotenv`: loads the Gemini key from `.env`.
- `google_generative_ai`: Gemini natural-language event extraction.
- `add_2_calendar`: opens the platform calendar editor before an event is saved.
- `cupertino_icons`: standard iOS-style icon set.

## Environment setup

Copy `.env.example` to `.env` and set:

```dotenv
GEMINI_API_KEY=your_gemini_api_key_here
```

`.env` is intentionally ignored by Git and is listed as a Flutter asset because it is loaded before the app starts.

## Completed features

1. App shell, Material 3 theme, Home/Settings navigation.
2. Multiline event input, clipboard detection/import, paste, clear, and shared input state.
3. Gemini extraction, JSON-to-`ParsedEvent` mapping, loading/error states, event preview, and native calendar-editor handoff.

## Known limitations

- The Gemini key is packaged in the client app; production use should proxy model calls through a secure backend.
- Parsed fields are read-only; correcting an individual field requires editing the original message and extracting again.
- Calendar events use a one-hour default duration for timed events and a one-day duration for all-day events.
- No persistence, event history, or offline extraction is implemented.

## Remaining roadmap

Feature 4 is not yet defined or implemented. Likely follow-up work includes editable preview fields, secure server-side AI access, validation/duration controls, and persistence/history.

## How to run

```bash
flutter pub get
flutter run
```

For verification:

```bash
flutter analyze
flutter test
```

## Important implementation decisions

- `inputTextProvider` mirrors the shared `TextEditingController`, so typing and programmatic clipboard updates keep every dependent widget in sync.
- Each extraction invalidates its keyed `FutureProvider` first, ensuring retries make a fresh Gemini request instead of reusing a cached result or error.
- Gemini is instructed to return JSON only; the service still defensively handles fenced or prose-wrapped JSON responses.
- The preview route is presented on the root navigator above the bottom-navigation shell.
- Riimind delegates final saving to the native calendar editor; it does not write events silently.
