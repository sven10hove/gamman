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
- Managed AI service status (server-side keys)
- Insight generation preferences
- Data statistics and reset options

## Requirements

- iOS 16.0+ (iOS 16 runs in compatibility mode; full SwiftData experience on iOS 17+)
- Xcode 15.0+
- A configured AI proxy backend (recommended)

## Installation

1. Clone the repository
2. Open `gamman.xcodeproj` in Xcode
3. Copy `Config/LocalSecrets.xcconfig.example` to `Config/LocalSecrets.xcconfig`
4. Set `GAMMAN_AI_PROXY_BASE_URL` in `Config/LocalSecrets.xcconfig` (use `https:$(SLASH)$(SLASH)...`)
5. Build and run on simulator or device

For release/App Store builds, set production proxy URL in `Config/Release.xcconfig` (or CI overrides), not in local secret files.

Detailed setup: `AI_PROXY_SETUP.md`
Vercel backend setup: `backend/README.md`

## CI Quality Gates

GitHub Actions workflow: `.github/workflows/ios-ci.yml`

- `lint`: blocks common source-level issues (debug prints, forced try/cast, trailing whitespace)
- `build-and-test`: runs iOS simulator build-for-testing and test-without-building

Run the same gates locally:

```bash
./scripts/ci/lint.sh
DESTINATION="$(./scripts/ci/detect_simulator_destination.sh)"
./scripts/ci/build_for_testing.sh "$DESTINATION"
./scripts/ci/test_without_building.sh "$DESTINATION"
```

## Tech Stack

- **UI**: SwiftUI
- **Data**: SwiftData (local persistence)
- **AI**: Claude API (Haiku model)
- **Charts**: Swift Charts
- **Security**: Server-side key management via proxy

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
- Vendor API keys are managed server-side (not entered by end users)
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
