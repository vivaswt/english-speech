# English Speech Article Processor

A Flutter application that automates the process of fetching web articles from a Notion database, summarizing them using the Gemini API, and preparing them for Text-to-Speech (TTS) processing.

The primary goal is to convert online articles into simplified English content suitable for language learners.

## Workflow

The application performs the following steps when the "Run" button is pressed:

1.  **Fetch Articles**: Retrieves a list of unprocessed articles from a specified Notion database. An article is considered "unprocessed" if its "Processed" checkbox is unchecked.
2.  **Enrich Titles**: For each article, it fetches the source web page to get the accurate `<title>`, ensuring the article's name is correct.
3.  **Process Each Article**: Iterates through the list of articles and performs the following for each one:
    a. **Fetch Content**: Retrieves the full block content of the article from Notion.
    b. **Summarize with AI**: Sends the content to the Gemini API with a specific prompt to rewrite it in simpler English (CEFR A2-B1 level), with a maximum word count of 800.
    c. **Register for TTS**: Sends the simplified content, title, and URL to another Notion database for TTS processing.
    d. **Mark as Processed**: Updates the original article in Notion by checking the "Processed" checkbox to prevent it from being processed again.

## Features

- **Automated Content Pipeline**: Fully automates the workflow from fetching to processing and final registration.
- **Notion Integration**: Uses the Notion API to read articles from one database and write processed data to another.
- **AI-Powered Summarization**: Leverages the Google Gemini API to intelligently simplify English text for language learners.
- **Real-time UI Updates**: The UI displays the list of articles to be processed and updates the status of each one in real-time (`waiting`, `processing`, `done`, `failed`).
- **Content Viewing**: Allows users to tap on an article to view its raw block content before processing.
- **Cancellable Process**: The processing loop can be cancelled mid-operation.
- Tappable list items navigate to a detail screen showing the full block content of the article.
- **Secure API Key Storage**: A dedicated settings screen to configure API keys, which are stored securely on the device.

## Configuration

This application requires API keys for Notion and Gemini to function correctly.

1.  Launch the application.
2.  Tap the **settings icon** in the top-right corner of the main screen.
3.  Enter your **Notion API Key** and **Gemini API Key** into the respective fields.
4.  Save the keys.

The keys are persisted on the device using `shared_preferences`.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- Ensure you have the Flutter SDK installed.

### Installation

1.  Ensure you have the Flutter SDK installed.
2.  Clone the repository and navigate to the project directory.
    ```sh
    git clone <your-repository-url>
    cd english_speech
    ```
3.  Install dependencies:
    ```sh
    flutter pub get
    ```
4.  Run the application:
    ```sh
    flutter run
    ```
