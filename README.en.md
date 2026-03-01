[🇯🇵 日本語](README.md) | [🇺🇸 English](README.en.md)

# EdoTime (江戸時間)

EdoTime is an iOS app that visualizes the current time using the traditional Japanese **Edo-period temporal hour system**.

Instead of fixed-length hours, daytime and nighttime are each divided into six equal segments based on **sunrise and sunset**.
The app shows which segment the current time falls into and how much time remains until the next segment.

## Why Edo Time?

Modern clocks assume that every hour has a fixed length.
In contrast, during the Edo period in Japan, time was measured using a **temporal hour system**, where daytime and nighttime were each divided into six equal segments based on sunrise and sunset.

EdoTime aims to visualize this alternative sense of time in a modern context.
By linking time to natural phenomena rather than fixed units, the app invites users to reconsider time not as an absolute constant, but as something shaped by environment and daily rhythm.

This project is not a historical reconstruction alone, but a tool for re-experiencing the present moment through a different temporal framework.

## Overview

- Calculates sunrise and sunset for the current location (or manual fallback)
- Divides daytime and nighttime into six equal segments each
- Displays the current Edo time segment and remaining time
- Visualizes the flow of the day using a timeline
- Built with SwiftUI and runs fully offline (NOAA-based solar calculation)

## Screenshots

![Home Screen](screenshots/screenshot-home.png)

## Technical Notes

- Sunrise and sunset are calculated using an offline NOAA-based algorithm
- Time zone and date boundaries are carefully handled to avoid UTC offset issues
- Designed as a learning project for SwiftUI, time calculation, and historical time systems

## Requirements

- iOS 17+
- Xcode 15+

## Status

This project is under active development.
Features and UI may change.
