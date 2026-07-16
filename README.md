# Riimind

Riimind turns a natural-language message into a calendar event in a few taps. Paste or share a message, review the details Gemini extracts, make corrections, then open the device calendar to save it.

## Requirements

- Flutter SDK compatible with Dart `^3.12.2`
- Android device/emulator for Android sharing and calendar-insert testing
- A Gemini API key from Google AI Studio

## Setup

```bash
git clone <repository-url>
cd riimind
cp .env.example .env
```

Set the following value in `.env`:

```dotenv
GEMINI_API_KEY=your_gemini_api_key_here
```

Then install dependencies and run the app:

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```

## MVP flow

1. Paste or import text from the clipboard into Riimind.
2. Tap **Extract Event**.
3. Review and edit the title, date, time, location, and description.
4. Tap **Continue** to open the native calendar editor and save the event.

> Share-intent support has been temporarily removed from v1.0. Clipboard import remains the supported workflow for bringing text into the app.

See [HANDOFF.md](HANDOFF.md) for the architecture, package choices, limitations, and implementation decisions.
