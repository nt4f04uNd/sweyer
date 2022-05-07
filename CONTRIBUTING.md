## Code style

The repo has a set of lints in [analysis_options](https://github.com/nt4f04uNd/sweyer/blob/master/analysis_options.yaml)
that enfore the style that I'm following, so just following
them and the code that you see around you should be fine.

The coding style is very similar (but not exactly the same)
to the style [Flutter framework itself uses](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo),
and the set of lints was created by copying and redacting Flutter's
[analysis_options](https://github.com/flutter/flutter/blob/master/analysis_options.yaml).
In particular, it includes not using auto-formatter.

## Tests and golden tests

After you made some changes, run the tests

```
flutter test
```

This will run regular automated tests located in `test/` folder,
as well as golden tests, located in `test/golden`.

If you find that some automated tests failed - fix them.

If you find that some golden tests failed, ensure that those changes
are indeed expected, and if no - adjust your code, if yes - update
golden tests files.

## Updating golden tests

Because Flutter golden files are platform-specific, the process
will depend on what platform you are using.

If you are using Linux, you can update golden tests files locally just by running

```
flutter test --update-goldens
```

To update the golden tests on Windows or macOS, open the [sweyer.yml](.github/workflows/sweyer.yml)
workflow and set `update_goldens` to `true`:

```yml
name: Sweyer
on: [push, pull_request]

jobs:
  build:
    uses: ./.github/workflows/flutter_package.yml
    with:
      flutter_channel: stable
      flutter_version: 2.10.5
      min_coverage: 0
      update_goldens: true # set this from false to true
```

Then push your code to a pull request and wait for the workflow to finish,
then open the workflow summary and download a `golden-test-updated` artifact,
which will contain the generated golden files.

Put those new files into `test/golden/goldens` folder, then set `update_goldens`
back to `false` and push these changes to your PR.
