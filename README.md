# MEMO - An iOS English Vocabulary Practice App

MEMO is an iOS app designed to help users practice English vocabulary in a unique way. Instead of traditional flashcards, MEMO encourages users to provide vocabulary words within sentences and then turns those sentences into fill-in-the-blank exercises, where the user must drag and drop the correct word into the blank. The app is developed using Swift, with code written in Cursor and later transferred to Xcode for compilation. 

- **Xcode Version**: 14

## Table of Contents
- [Features](#features)
- [User Interface](#user-interface)
- [Installation](#installation)
- [Usage](#usage)
- [Feedback and Contributions](#feedback-and-contributions)

## Features
1. **Fill-in-the-Blank Practice**: 
   - Users input vocabulary in the format of `word; sentence` (e.g., `meet;Nice to meet you`).
   - MEMO automatically converts sentences to contain a blank (e.g., `Nice to ______ you`), creating a matching exercise where users drag the missing word into the blank.

2. **Customizable Lists**:
   - Users can create and organize words into lists for specific study sets.
   - A default list is provided, and users can add or delete custom lists as needed.

3. **Configurable Settings**:
   - Users can set the number of sentences per practice group (3, 6, or 9).
   - An optional "Read Aloud" feature reads sentences and words aloud during practice for enhanced learning.

4. **Sorting Options**:
   - Sort words within lists by error count, alphabetical order, creation date, or randomized order.
   - Sorting preferences include earliest to latest and latest to earliest, depending on the selected criterion.

5. **Error Feedback and Re-attempts**:
   - After each practice session, the app provides feedback on the number of correct and incorrect answers.
   - Users can choose to redo the entire exercise, focus only on incorrect answers, or move to the next group if all answers are correct.

## User Interface

### Main Screen
- **List Buttons**: Displays existing lists, including a default list. Users can click a list button to open it.
- **Add Word Button**: Opens a dialog for users to add a new word and sentence. The word must be assigned to a specific list.
- **Add List Button**: Opens a small dialog to create a new list with a custom name.
- **Settings Button**: Opens a settings menu where users can:
  - Set the number of sentences per practice group.
  - Toggle the "Read Aloud" feature.

### List View
- Displays all sentences in the selected list, with options to:
  - **Practice**: Start a practice session.
  - **Sort By**: Sort list contents by error count, alphabetical order, creation date, or random order.

### Practice Screen
- Users drag the missing word to fill in the blanks in sentences.
- **Submit Button**: After completing a group, users can submit answers. If incorrect answers are detected, the app displays a dialog showing the number of errors and offers:
  - **Retry All**: Redo the entire group.
  - **Retry Incorrect Only**: Retry only the incorrect answers.
- If all answers are correct, options are:
  - **Retry**: Restart the current group.
  - **Next Group**: Move to the next group (if not the last).
  - **Return to Lists**: Go back to the main screen after finishing the last group.

### Add Word Screen
- When adding a word, users must follow the `word; sentence` format:
  - If incorrect format, a dialog will display the appropriate error message, such as:
    - "Format error, each entry must include a `;`."
    - "Both word and sentence cannot be empty."
    - "The sentence must include the word."

## Usage
1. Launch the app and create a new list or select the default list.
2. Add vocabulary words in the format `word; sentence`.
3. Begin practicing by selecting a list and choosing "Practice."
4. Drag the correct word into each blank, then click "Submit" to check your answers.
5. Use the feedback to retry incorrect answers or advance to the next group.
