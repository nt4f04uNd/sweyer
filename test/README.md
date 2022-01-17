There are two strategies for UI tests:

* if widget is pure UI and doesn't depend on the app state - just write a regular UI test, which
  is rarely the case, so
* otherwise use fake data providers located in the `fakes` folder to emulate the app state

The goal is to fake as few classes as possible, so only source data providers are faked.
For example, I'm not faking the `ContentControl`, and instead faking the `ContentChannel`.
