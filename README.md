Even thought the source code is open, Google secrets cannot be opened - that would violate Google's terms of service and would endanger our wallets.
If you're willing to help the project, you can get in touch with @blazern and he'll gladly provided you the needed secrets.

You will have to create a file caleld ".env" in the project's root, where you will have to define ...

Android:
- PLANTE_ANDROID_GOOGLE_CLOUD_CLIENT_ID
- PLANTE_ANDROID_GOOGLE_MAPS_KEY

iOS:
- PLANTE_IOS_GOOGLE_CLOUD_CLIENT_ID
- PLANTE_IOS_GOOGLE_MAPS_KEY

https://pub.dev/packages/flutter_config is used to handle the .env file - if project building fails even though the variables are specified, it could be that something related to the package has changed.

On Android you will need a 'android/app/debug.keystore' file in order for Google services to work properly.