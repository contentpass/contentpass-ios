# Example Project

## Configuration

To get the example up and running you just need your configuration file. Get yours at [support@contentpass.de](support@contentpass.de).

Replace the dummy `contentpass_configuration.json` with your configuration file and you're good to go.


## Notes

The `ContentPass` SDK is held by the `SceneDelegate` in this case, but it could be any top level state object of your app. You should only hold one instance of the `ContentPass` class throughout your app at any one time.

The `ViewModel` handles all communication with, as well as delegation by, the `ContentPass` object. Refer to that class on how to interact with the sdk.
