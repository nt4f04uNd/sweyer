# sweyer_plugin

Plugin for native components of Sweyer.

## Why is this needed

Sweyer needs to interface with some native functionality and uses a MethodChannel to communicate
with the native side. This MethodChannel needs to be registered. When Sweyer is started normally,
this can be done in the main activity. But if Sweyer is started from the audio service, the main
activity is never started (because Sweyer only runs in the background). Therefore, to ensure that
the MethodChannel is always registered, a plugin is used.
