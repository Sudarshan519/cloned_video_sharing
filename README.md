# Flutter Video Sharing app

![final.gif](https://www.learningsomethingnew.com/flutter-video-hls/final.gif)

An example app to demonstrate video sharing using Firebase Cloud Storage and with HLS.

Read the full tutorial in my [blog](https://www.learningsomethingnew.com/flutter-video-upload-firebase-storage-hls).

## Getting Started

You need to setup Firebase credentials in order to run the sample:

### Firebase setup
Complete the setup process as described [here](https://firebase.google.com/docs/flutter/setup).

You should add two files:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`


### Run the project
Run the project as usual using `flutter run`


### required config

service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read;
      allow write;
    }
  }
}

### default config
rules_version = '2';

// Craft rules based on data in your Firestore database
// allow write: if firestore.get(
//    /databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin;
service firebase.storage {
  match /b/{bucket}/o {

    // This rule allows anyone with your Storage bucket reference to view, edit,
    // and delete all data in your Storage bucket. It is useful for getting
    // started, but it is configured to expire after 30 days because it
    // leaves your app open to attackers. At that time, all client
    // requests to your Storage bucket will be denied.
    //
    // Make sure to write security rules for your app before that time, or else
    // all client requests to your Storage bucket will be denied until you Update
    // your rules
    match /{allPaths=**} {
      allow read, write: if request.time < timestamp.date(2023, 7, 26);
    }
  }
}# cloned_video_sharing
# cloned_video_sharing
