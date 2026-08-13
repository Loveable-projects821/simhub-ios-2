# SimHub — iOS Companion App (Phase 1)

Connects directly to the Android hub's local WebSocket server (`ws://<android-ip>:8765`),
no cloud in between — matches the protocol from the Android `SimHubAndroid` project.

## Why no .xcodeproj is included
Xcode project files are a binary/plist format that's easy to corrupt by hand-editing
outside Xcode. Instead, this project includes `project.yml` — a spec for **XcodeGen**
(a free, standard tool) that generates a correct `.xcodeproj` automatically, both
locally and in Codemagic's cloud build below. That's what `codemagic.yaml` does
in its "Generate Xcode project" step.

## Build with Codemagic — no Mac needed
1. Create a free account at **codemagic.io**, connect your GitHub account.
2. Push/upload this entire `SimHubIOS` folder to a new GitHub repository
   (`codemagic.yaml` and `project.yml` must sit at the repo root).
3. In Codemagic, add the repo as a new app — it auto-detects `codemagic.yaml`.
4. Under the app's **Team settings → Code signing identities**, connect your
   **Apple ID** (free account is fine) so Codemagic can sign the build automatically.
5. Register your iPhone: Codemagic will prompt for its device UDID the first time —
   it gives you a link to open on the iPhone in Safari, which captures the UDID
   automatically, no manual steps.
6. Edit `codemagic.yaml`'s `recipients:` line to your real email, or skip publishing
   and just download the `.ipa` artifact from the build results page instead.
7. Click **Start new build**. When it finishes, download the `.ipa`.
8. Get it onto the iPhone with either:
   - **Sideloadly** (Windows/Mac app, drag in the `.ipa`, sign in with the same
     Apple ID, install over USB), or
   - Upload the `.ipa` to **diawi.com** (free), open the link it gives you in
     **Safari on the iPhone**, tap Install directly — no laptop step at all.
9. On the iPhone: **Settings → General → VPN & Device Management** → trust the profile.

Reminder: a **free** Apple ID means the install expires after 7 days — repeat step 8
to reinstall. A $99/year paid Apple Developer account removes that limit.

## Setup steps (only needed if building locally on a Mac instead)
1. Open Xcode → **File → New → Project → iOS → App**.
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Name it `SimHub` (or anything you like)
2. Delete the auto-generated `ContentView.swift` and `SimHubApp.swift` (or `<YourName>App.swift`).
3. Drag all 5 files from this `Sources/` folder into the Xcode project navigator
   (check "Copy items if needed").
4. Open **Info.plist** (or the Info tab of your target) and add:
   - `App Transport Security Settings → Allow Arbitrary Loads` = **YES**
     (needed because the hub uses plain `ws://` on the local hotspot, not `wss://`)
   - `Privacy - Local Network Usage Description` = "SimHub connects to your Android hub over WiFi."
5. Open target **Signing & Capabilities** → **+ Capability** → add **Background Modes**
   → check **Voice over IP** (lets the app keep the socket open briefly in the background;
   see the limitation note below).
6. Build & run on a **real iPhone** (CallKit doesn't behave fully on the Simulator).

## What this build does
- Native iOS tab UI: **Keypad, Recents, Contacts, Messages, Signal**
- Keypad places real calls through Android's SIM (`ACTION_CALL` on the Android side)
- Contacts: merges the iPhone's own address book with contacts relayed from Android
  (Gmail contacts are NOT included — see limitation below)
- Messages: view incoming SMS and send new ones (relayed through Android's SmsManager)
- Real native **CallKit** incoming-call screen when Android reports a ring
- A real **live two-way audio call** (WebRTC) between the two apps — this is genuine
  working VoIP audio, not a mock

## The one limitation that doesn't go away: real caller audio
The WebRTC audio channel connects **the iPhone app's mic/speaker to the Android app's
own mic/speaker** — a real call between the two devices. It cannot carry the voice of
whoever actually called the SIM's real phone number, in either direction. Stock,
non-rooted Android blocks third-party apps from capturing or injecting audio on a real
cellular call — this is an OS-level restriction, not something fixable in this codebase.
If you need genuinely hearing/talking to the real caller through the iPhone, that
requires dedicated GSM-modem hardware instead of a stock Android phone (see the very
first conversation about this constraint).

## Gmail contacts — why they're not included
Syncing an actual Google account's contacts requires Google Sign-In + the People API,
which means talking to Google's servers — the one piece of this whole system that
can't be fully local, similar to the PushKit caveat below. Can be added as a later
step if you want it; flagged here rather than silently skipped.

## Background/lock-screen alerting limitation (unchanged from before)
  Apple deprecated always-on background VoIP sockets years ago. Reliable "ring even
  if the app was killed" behavior requires **PushKit + a VoIP push certificate**,
  which means Apple's push servers have to be in the loop for that one specific
  piece — it can't be 100% local/no-cloud the way the Android-to-iPhone data path is.
  While the app is open/foregrounded on the same WiFi, everything above works with
  no cloud involved at all. If you want true background ringing later, that's the
  one piece that needs a (free, Apple-provided) push certificate — happy to add it
  when you're ready.

## Protocol reference
Same as documented in the Android project's README — first message sent must be:
```json
{ "type": "pair", "pin": "123456" }
```
Then the app listens for `"signal"`, `"call"`, and `"sms"` events broadcast from the hub.
