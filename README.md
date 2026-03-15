# PorkNotes

Write notes about other players.

A plugin for TurtleWoW (1.12 / Lua 5.0).

Based on [CaramelNotes](https://github.com/MrToffee/CaramelNotes) by MrToffee.

## Installation

1. Download and extract the zip
2. Rename the folder to `PorkNotes` if it isn't already
3. Place the `PorkNotes` folder in your `Interface/AddOns` directory
4. Log in and type `/pn` or `/porknotes` to open

## Commands

- `/porknotes` or `/pn` — Open the notes window
- `/pn import` — Import notes from CaramelNotes
- `/pndebug` — Toggle debug output in chat

## Features

- Write and store notes for any player
- Notes appear in player tooltips on hover
- Chat alerts when a noted player sends a message, with a clickable link to edit their note
- Right-click any player to add or edit their note
- World and LookingForGroup channel alerts route to a configurable chat frame
- Settings window to toggle tooltip display, chat alerts, and metadata display

## Importing from CaramelNotes

If you have existing notes in CaramelNotes you can import them into PorkNotes in a few steps:

1. Download and install the CaramelNotes compatibility release: [LINK PLACEHOLDER]
2. Make sure both PorkNotes and CaramelNotes are enabled in your addon list
3. Log in to the game
4. Type `/pn import` in chat, or click **Import from CaramelNotes** in the PorkNotes settings window
5. Your notes will be imported — any players you already have notes for in PorkNotes will be skipped
6. Once the import is complete you can disable or uninstall CaramelNotes

## Credits

- Original addon [CaramelNotes](https://github.com/MrToffee/CaramelNotes) by MrToffee
