# English Speech Article Processor

A Flutter application that automates the conversion of English content (from web articles and YouTube videos) into simplified audio files for language learners.

It has three main workflows:

1.  **Article Summarization**: Fetches web articles from a Notion database, summarizes them using the Gemini API, and registers them in Notion for audio generation.
2.  **YouTube Video Summarization**: Fetches videos from a user-selected YouTube playlist, summarizes their content using Gemini, registers them in Notion for audio generation, and removes them from the playlist.
3.  **TTS Generation**: Creates audio files from the processed summaries using either Google Cloud TTS or Gemini TTS APIs.

## Workflows

The application is divided into three main batch processes.

### 1. Summarize Web Articles

This workflow automates the process of converting web articles into simplified text content.

1.  **Fetch Articles**: Retrieves a list of unprocessed articles from a specified Notion database.
2.  **Process Each Article**: Iterates through the list and for each one:
    1.  **Fetch Content**: Retrieves the full block content of the article from Notion.
    2.  **Summarize with AI**: Sends the content to the Gemini API to rewrite it in simpler English (target CEFR A2-B1 level).
    3.  **Register for TTS**: Saves the simplified content to another Notion database, ready for audio generation.
    4.  **Mark as Processed**: Updates the original article in Notion to prevent it from being processed again.

### 2. Summarize YouTube Videos

This workflow automates the process of converting YouTube videos into simplified text content.

1.  **Authenticate**: The user signs in with their Google Account to grant access to their YouTube data.
2.  **Select Playlist**: The app fetches the user's YouTube playlists, and the user selects one from a dropdown menu.
3.  **Fetch Videos**: Retrieves all video items from the selected playlist.
4.  **Process Each Video**: Iterates through the list and for each one:
    1.  **Summarize with AI**: Sends the video URL to the Gemini API to generate a simplified summary.
    2.  **Register for TTS**: Saves the summary to the Notion database, ready for audio generation.
    3.  **Clean Up**: Deletes the video from the YouTube playlist to prevent reprocessing.

### 3. Create Audio from Summaries

This workflow converts the simplified text summaries (from either web articles or YouTube videos) into audio files.

1.  **Fetch Summaries**: Retrieves a list of summaries from the TTS database that have not yet been converted to audio.
2.  **Select TTS API**: The user can choose between the **Gemini** or **Google Cloud TTS** API directly on the screen.
3.  **Generate Audio**: For each summary, the application:
    1.  Calls the selected TTS API to synthesize the audio.
    2.  Saves the output as a `.wav` file.
    3.  Saves the file to a user-configurable folder.
    4.  Marks the summary as complete in Notion.

## Features

- **Automated Content Pipelines**: Fully automates workflows for both web articles and YouTube videos.
- **Notion Integration**: Uses the Notion API to read articles from one database and write processed data to another.
- **YouTube Integration**: Fetches playlists and videos from the user's YouTube account.
- **AI-Powered Summarization**: Leverages the Google Gemini API to intelligently simplify English text for language learners.
- **Real-time UI Updates**: The UI displays the list of items to be processed and updates the status of each one in real-time (`waiting`, `processing`, `done`, `failed`), including detailed error messages.
- **Flexible TTS Generation**: Supports both Google Cloud TTS and Gemini for audio synthesis, selectable at runtime.
- **Cancellable Process**: The processing loop can be cancelled mid-operation.
- **Configurable Save Location**: Users can specify a custom folder for saving the generated `.wav` files.
- **Google Account Sign-In**: Securely authenticates with Google to access YouTube data.
- **Secure API Key Storage**: A dedicated settings screen to configure API keys and other preferences, stored securely on the device.

## Setup and Configuration

This application requires API keys and other settings to function correctly.

1.  Launch the application.
2.  Tap the **settings icon** in the top-right corner of the main screen.
3.  Enter your **Notion API Key** and **Gemini API Key** into the respective fields.
4.  To use the YouTube summarizer, sign in with your Google Account in the "YouTube Account" section.
5.  To use Google Cloud TTS for audio generation, enter your **Google TTS API Key**.
6.  Set a **Save Folder Path** for your audio files using the folder picker. If left blank, a temporary directory will be used.
7.  Adjust the **Speaking Rate** slider to control the speed of the generated speech.

All settings are saved automatically and persisted on the device using `shared_preferences`.

## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

- Ensure you have the Flutter SDK installed.

### Installation

1.  Clone the repository and navigate to the project directory.
    ```sh
    git clone <your-repository-url>
    cd english_speech
    ```
2.  Install dependencies:
    ```sh
    flutter pub get
    ```
3.  Run the application:
    ```sh
    flutter run
    ```
