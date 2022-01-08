There are to strategies for UI tests:

* if widget is pure UI and doesn't depend on the app state - just write a regular UI test
* otherwise use fake data providers located in the `fakes` folder to emulate the app state

The goal is to fake as little classes as possible, so only only source data providers
are faked. For example, I do not fake the `ContentControl`, instead faking the `ContentChannel`.
