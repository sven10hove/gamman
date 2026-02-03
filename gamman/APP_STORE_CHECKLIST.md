## App Store Submission Checklist

### Before archiving
- Update version and build number in Xcode (MARKETING_VERSION, CURRENT_PROJECT_VERSION).
- Confirm icons and launch screen.
- Validate all required Info.plist entries (no unused permissions).
- Run app on device and verify core flows.

### Archive and upload
- Product -> Archive in Xcode.
- Validate the archive in Organizer.
- Distribute App -> App Store Connect -> Upload.

### App Store Connect setup
- Add the uploaded build to the app version.
- Complete App Information (name, subtitle, category, rating).
- Complete App Privacy questionnaire (see `APP_STORE_PRIVACY_NOTES.md`).
- Add screenshots for required device sizes (see `APP_STORE_METADATA.md`).
- Add support and privacy policy URLs.
- Add App Review notes (see `APP_REVIEW_NOTES.md`).
- Export compliance: select the appropriate option for standard encryption only (if applicable).

### Submit
- Submit for review and monitor status.
- Be ready to answer review questions about AI data handling.
