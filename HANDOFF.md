# Riimind handoff

## Project overview

Riimind is an Android-first Flutter app that converts a natural-language message into a calendar event. Users paste or share text, Gemini extracts event details, the user edits the result, and the app opens the native calendar editor for final review and saving.

## Current status

The MVP (Features 1–8) is complete. There is no new feature work outstanding from the current specification.

## Architecture

The project uses a feature-first structure. Widgets and Riverpod providers live in each feature's presentation layer; parser data and Gemini integration are isolated in `models` and `services`. `app.dart` composes Material 3 theme and GoRouter, while `main.dart` loads environment values and creates the root `ProviderScope`.

## Folder structure

```text
lib/
  core/                         # App theme and GoRouter configuration
  features/
    home/presentation/          # Existing home screen and share intake lifecycle
    input/
      presentation/             # Input widgets and Riverpod input state
      services/                 # Android share-intent adapter
    parser/
      models/                   # ParsedEvent
      services/                 # Gemini extraction and error classification
      presentation/             # Editable review form and parser providers
    settings/presentation/      # Settings placeholder
  app.dart
  main.dart
test/features/                  # Input, parser, and preview tests
```

## Packages used

- `flutter_riverpod`: shared input state and injectable parser service.
- `go_router`: bottom-navigation shell and full-screen preview navigation.
- `flutter_dotenv`: loads the Gemini API key before app startup.
- `google_generative_ai`: structured natural-language event extraction.
- `add_2_calendar`: native Android/iOS calendar insert/editor flow.
- `receive_sharing_intent`: receives Android plain-text share intents.
- `cupertino_icons`: iOS icon support.

## Environment

Copy `.env.example` to `.env` and configure:

```dotenv
GEMINI_API_KEY=your_gemini_api_key_here
```

`.env` is ignored by Git and is included as a Flutter asset for startup loading.

## Completed features

1. Material 3 application shell, theme, bottom navigation, and Settings screen.
2. Multiline input with clipboard detection, import, paste, clear, and Riverpod state synchronization.
3. Gemini extraction, JSON parsing, loading/error handling, and event preview navigation.
4. Calendar handoff through `add_2_calendar`, including title, description, location, all-day events, a one-hour timed default, platform permission handling, and success/failure feedback.
5. Editable preview form with text inputs plus native date and time pickers. Continue always reads the edited state.
6. Android `ACTION_SEND` text sharing directly into the existing Home input.
7. Material 3 polish: consistent cards, picker affordances, disabled states, loading indicators, and focused dialogs.
8. Stronger Gemini instructions for relative dates, weekday expressions, common time expressions, all-day events, and non-hallucination.

## Important implementation decisions

- Input changes use one shared `TextEditingController`; `inputTextProvider` mirrors it so typing, clipboard actions, and sharing stay synchronized.
- Android shares are adapted to text in `ShareIntentService`, then fed into the existing input state—there is no second app entry point or Home screen.
- Calendar integration delegates saving to the platform editor. Android opens `ACTION_INSERT` without app calendar permission; iOS requests calendar access only when the editor needs it.
- An absent time creates an all-day event. A timed event defaults to one hour because the parser does not capture an end time.
- Gemini errors are classified internally and rendered as friendly messages; raw errors and stack traces are not shown to users.

## Known limitations

- The Gemini key is in the client app. A production release should call Gemini through a secure backend.
- Recurring language such as “every Monday” is preserved for review in the description; recurrence rules are not yet created in the device calendar.
- Calendar completion is controlled by the native editor, so Riimind can confirm that it opened the editor but cannot verify that the user tapped Save on Android.
- No event persistence/history, login, sync, or offline parsing is included (all are outside the MVP scope).

## Remaining roadmap

- Secure backend proxy for Gemini requests.
- Recurrence rule editing and end-time/duration controls.
- Saved event history and optional cloud sync.
- iOS share extension, if iOS sharing is required later.

## Run the project

```bash
flutter pub get
flutter run
```

Verify before handoff:

```bash
flutter analyze
flutter test
```
