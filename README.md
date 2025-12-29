# Gamman - Nervous System Journal

A SwiftUI iOS app for tracking and understanding your nervous system through journaling, education, and AI-powered insights.

## Features

### Journal
- Track your nervous system state (Ventral/Sympathetic/Dorsal Vagal)
- Log intensity levels (1-10)
- Record triggers and body sensations
- View entries with visual state indicators

### Learn
- 5 pre-built lessons on polyvagal theory:
  - Introduction to Polyvagal Theory
  - Fight, Flight, and Freeze
  - Understanding Vagal Tone
  - The Window of Tolerance
  - Co-Regulation
- Create custom AI-generated lessons via Claude API
- Track lesson completion progress

### Insights
- AI-powered analysis of your journal patterns
- Visual charts showing:
  - State distribution
  - Intensity over time
  - Entries by day of week
- Personalized suggestions for nervous system regulation

### Settings
- Secure API key storage (iOS Keychain)
- Insight generation preferences
- Data statistics and reset options

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Claude API key (get one at [console.anthropic.com](https://console.anthropic.com))

## Installation

1. Clone the repository
2. Open `gamman.xcodeproj` in Xcode
3. Build and run on simulator or device
4. Add your Claude API key in Settings

## Tech Stack

- **UI**: SwiftUI
- **Data**: SwiftData (local persistence)
- **AI**: Claude API (Haiku model)
- **Charts**: Swift Charts
- **Security**: iOS Keychain for API key storage

## Architecture

```
gamman/
├── Models/          # SwiftData models
├── Views/           # SwiftUI views organized by feature
├── Services/        # API, Keychain, Network services
└── Resources/       # Bundled lesson content (JSON)
```

## Privacy

- All journal data stored locally on device
- API key stored securely in iOS Keychain
- No data leaves your device except for AI API calls
- Journal content sent to Claude API only when generating insights

## Future Roadmap

- [ ] Apple HealthKit integration (HRV, sleep data)
- [ ] iCloud sync
- [ ] Apple Watch companion app
- [ ] Widgets for quick logging
- [ ] Guided regulation exercises

## License

MIT License

## Acknowledgments

- Polyvagal Theory by Dr. Stephen Porges
- Claude AI by Anthropic
