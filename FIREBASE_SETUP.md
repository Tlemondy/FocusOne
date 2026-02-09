# Firebase Setup Instructions

The Firebase configuration files are not included in version control for security reasons.

## Setup Steps

1. Download your `GoogleService-Info.plist` files from the Firebase Console
2. Copy them to the following locations:
   - `ios/Runner/GoogleService-Info.plist`
   - `macos/Runner/GoogleService-Info.plist`

Template files are provided at:
- `ios/Runner/GoogleService-Info.plist.template`
- `macos/Runner/GoogleService-Info.plist.template`

## Note

Never commit the actual `GoogleService-Info.plist` files to version control as they contain sensitive API keys.
