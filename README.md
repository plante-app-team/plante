<h1 align="center">Plante🌱 app</h1>
<h3 align="center">
Community-based vegan groceries map
<br />
https://planteapp.com/
</h3>

<br />

<p align="center">
  <a href="https://apps.apple.com/be/app/plante/id1574070382">
    <img alt="app-store" src="https://github.com/plante-app-team/plante/blob/master/readme_resources/app-store.png" />
  </a>
  <a href="https://play.google.com/store/apps/details?id=vegancheckteam.plante">
    <img alt="google-play" src="https://github.com/plante-app-team/plante/blob/master/readme_resources/play-store.png" />
  </a>
</p>

<br />

![screenshots](https://github.com/plante-app-team/plante/blob/master/readme_resources/screenshots.jpg)

## 🗣 Translations

We don't speak that many languages - if you would help us to translate the app into a langauge you speak that would be very good for the project! 🙂

We have 2 projects in POEditor:
- Main project for almost all of the app's text: https://poeditor.com/join/project?hash=vQy5XjnrGL
- Project for iOS-only text: https://poeditor.com/join/project?hash=o9hhL1K1fD


## 📦 How to build

### Install Flutter

Plante is a standard Flutter app and can be built with the standard Flutter environment 🙂

https://docs.flutter.dev/get-started/install

### Install dependencies

Open Food Facts SDK is used as a submodule, to initialize it for the first time you should run:

```bash
$ git submodule update --init --recursive
```

### Secrets

Even thought the source code is public, Google secrets cannot be public - that would violate Google's terms of service and would create a serious app vulnerability.

This means that while the `flutter test` command will work out of the box, to build and run the app you should either obtain app's secrets from us or use your own secrets.

#### Obtain existing secrets

If you're willing to help the project, you can get in touch with us on our Discord server: https://discord.gg/kXgXrTVpGY

We will gladly provide you any needed information and will help you with any problems 🙂

#### Your own secrets

To assemble the app you will need next files:
- `android/app/google-services.json` (Android)
- `android/app/debug.keystore` (Android)
- `ios/GoogleService-Info.plist` (iOS)
- `.env`

The `.env` file is the only non-standard file. It should contain secrets in next format:
```
VAR_NAME1=VALUE1
VAR_NAME2=VALUE2
...
```
Currently used variables on Android:
- `PLANTE_ANDROID_GOOGLE_CLOUD_CLIENT_ID`
- `PLANTE_ANDROID_GOOGLE_MAPS_KEY`

On iOS:
- `PLANTE_IOS_GOOGLE_CLOUD_CLIENT_ID`
- `PLANTE_IOS_GOOGLE_CLOUD_CLIENT_ID_REVERSE`
- `PLANTE_IOS_GOOGLE_MAPS_KEY`

To contribute on iOS you will need a (generated) tmp.xconfig. 
- Follow the steps as described in https://github.com/ByneappLLC/flutter_config/blob/master/doc/IOS.md

## 👩🏾‍💻 Development

- `flutter format` is used to enforce app's coding style - you should run `$ flutter format .` from project's root directory before each commit.

- The [built_value package](https://pub.dev/packages/built_value) is used for value types. You should read its documentation if you want to edit any `implements Built` class, or if you want to create a new one. We run next command when we update/create such a class: `$ flutter pub run build_runner build --delete-conflicting-outputs`.

- Tests are used extensively and are very appreciated. Please try to write new (or modify existing) tests when you're working on a patch.


## ©️ Open source - licence

Repository and contributions are under [GNU General Public License v3.0](https://github.com/plante-app-team/plante/blob/master/LICENSE.txt)
