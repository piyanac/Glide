# Glide

Glide is a lightweight macOS menu bar alarm app built with SwiftUI. It helps you create quick countdowns or exact-time alarms, choose a message, and bring up a full-screen blocking alert when time is up.

For old Mac users, this may be a replacement for now-gone ChronoSlider Lite. 

## ⚠️ Disclaimer

- This app is a product of cognitive automation. Involved models include: GPT 5.4.
- We urge the avoidance of using this app. We are not responsible for any result. We do not promise anything.

## Why Glide

Glide focuses on fast alarm creation with minimal friction:

- open from the menu bar
- choose a time quickly
- pick or customize a message
- get an impossible-to-miss alert when the alarm triggers

## Features

- Lives in the macOS menu bar with a simple alarm list and quick actions
- Create alarms as either countdown timers or exact clock-time reminders
- Customize the alarm message before saving
- Optional system sound playback with selectable default sound
- Full-screen blocking alert presentation when an alarm fires
- Preferences for default sound behavior and reusable message presets

## Requirements

- macOS 13 or later
- Xcode 16+ recommended
- English / Traditional Chinese literacy. 

## Project Structure

```text
Sources/Glide
  Models/      Alarm data types and date resolution logic
  Services/    Scheduling, alert presentation, menu state, preferences
  UI/          Menu bar UI, editing flows, preferences, blocking alert
```

## Run Locally

### Get from Release

Download signed & nortarized app from the Release section. 

### With Xcode

1. Open `Glide.xcodeproj`.
2. Select the `Glide` scheme.
3. Run the app on macOS.

### With Swift Package Manager

```bash
swift run Glide
```



## Contributions

This repo does not accept contributions. Fork it as you like.
