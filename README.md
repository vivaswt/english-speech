# english_speech

A Flutter application designed to fetch and display articles from a Notion database. It enriches the articles with titles from their web URLs and provides detailed content views.

## Features

- Fetches a list of articles from a specified Notion database.
- Enriches article data by fetching the title from the source URL.
- Displays articles in a clean, scrollable list.
- Shows the processing status (`processing`, `success`, `error`) for each article during enrichment.
- Tappable list items navigate to a detail screen showing the full block content of the article.
- A settings screen to configure Notion and Gemini API keys.

## Configuration

This application requires API keys for Notion and Gemini to function correctly.

1.  Launch the application.
2.  Tap the settings icon in the top-right corner of the main screen.
3.  Enter your **Notion API Key** and **Gemini API Key** into the respective fields.

The keys are stored securely on the device using `shared_preferences`.

## Getting Started

1.  Ensure you have the Flutter SDK installed.
2.  Clone the repository and navigate to the project directory.
3.  Run `flutter pub get` to install dependencies.
4.  Run `flutter run` to launch the application on a connected device or emulator.
