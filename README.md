# English Speech Article Processor

A Flutter application that automates two main workflows:

1.  **Article Processing**: Fetches web articles from a Notion database, summarizes them using the Gemini API, and prepares them for Text-to-Speech (TTS) processing.
2.  **TTS Generation**: Creates audio files from the processed summaries using either Google Cloud TTS or Gemini TTS APIs.

The primary goal is to convert online articles into simplified English audio content suitable for language learners.

## Workflows

The application is divided into two main batch processes.

### 1. Summarize Web Articles

This workflow automates the process of converting web articles into simplified text content.

1.  **Fetch Articles**: Retrieves a list of unprocessed articles from a specified Notion database.
2.  **Enrich Titles**: For each article, it fetches the source web page to get the accurate `<title>`.
3.  **Process Each Article**: Iterates through the list and for each one:
    1.  **Fetch Content**: Retrieves the full block content of the article from Notion.
    2.  **Summarize with AI**: Sends the content to the Gemini API to rewrite it in simpler English (CEFR A2-B1 level).
    3.  **Register for TTS**: Saves the simplified content to another Notion database, ready for audio generation.
    4.  **Mark as Processed**: Updates the original article in Notion to prevent it from being processed again.

### 2. Create Audio from Summaries

This workflow converts the simplified text summaries into audio files.

1.  **Fetch Summaries**: Retrieves a list of summaries from the TTS database that have not yet been converted to audio.
2.  **Select TTS API**: The user can choose between the **Gemini** or **Google Cloud TTS** API directly on the screen.
3.  **Generate Audio**: For each summary, the application:
    1.  Calls the selected TTS API to synthesize the audio in chunks.
    2.  Joins the audio chunks into a single `.wav` file.
    3.  Saves the file to a user-configurable folder.
    4.  Marks the summary as complete in Notion.

## Features

- **Automated Content Pipeline**: Fully automates the workflow from fetching to processing and final registration.
- **Notion Integration**: Uses the Notion API to read articles from one database and write processed data to another.
- **AI-Powered Summarization**: Leverages the Google Gemini API to intelligently simplify English text for language learners.
- **Real-time UI Updates**: The UI displays the list of articles to be processed and updates the status of each one in real-time (`waiting`, `processing`, `done`, `failed`).
- **Flexible TTS Generation**: Supports both Google Cloud TTS and Gemini for audio synthesis, selectable at runtime.
- **Content Viewing**: Allows users to tap on an article to view its raw block content before processing.
- **Cancellable Process**: The processing loop can be cancelled mid-operation.
- **Configurable Save Location**: Users can specify a custom folder for saving the generated `.wav` files.
- **Secure API Key Storage**: A dedicated settings screen to configure API keys and other preferences, stored securely on the device.

## Configuration

This application requires API keys and other settings to function correctly.

1.  Launch the application.
2.  Tap the **settings icon** in the top-right corner of the main screen.
3.  Enter your **Notion API Key** and **Gemini API Key** into the respective fields.
4.  If you plan to use Google Cloud TTS, enter your **Google TTS API Key**.
5.  Optionally, set a **Save Folder Path** for your audio files. If left blank, a temporary directory will be used.
6.  Adjust the **Speaking Rate** slider to control the speed of the generated speech.

All settings are saved automatically and persisted on the device using `shared_preferences`.

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
