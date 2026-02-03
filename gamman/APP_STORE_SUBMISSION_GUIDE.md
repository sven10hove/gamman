## App Store Submission Guide

### 1) Archive and upload (Xcode)
1. Open the project in Xcode.
2. Select the correct Team, Signing, and Bundle ID.
3. Update version and build number.
4. Product -> Archive.
5. In Organizer, Validate the archive.
6. Distribute App -> App Store Connect -> Upload.

### 2) App Store Connect setup
1. Open App Store Connect -> My Apps -> gamman -> App Store.
2. Create or edit the version entry (e.g., 1.0).
3. Add the uploaded build to the version.
4. Fill in:
   - App name, subtitle, keywords, description (see `APP_STORE_METADATA.md`)
   - App Review notes (see `APP_REVIEW_NOTES.md`)
   - Support and privacy policy URLs
   - Screenshots for required devices
5. Complete App Privacy questionnaire (see `APP_STORE_PRIVACY_NOTES.md`).
6. Export compliance: choose the option for standard encryption only if applicable.
7. Save and submit for review.

### 3) After submission
- Monitor status and respond to any review requests.
- If rejected, address feedback and submit a new build.
