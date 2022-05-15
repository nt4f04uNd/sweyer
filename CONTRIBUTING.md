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

```shell
flutter test
```

This will run regular automated tests located in `test/` folder,
as well as golden tests, located in `test/golden`.

If you find that some automated tests failed - fix them.

If you find that some golden tests failed, ensure that those changes
are indeed expected, and if no - adjust your code, if yes - update
golden tests files.

## Updating golden tests

Because Flutter golden files are platform-specific, the golden files will vary slightly depending
on what platform you are using. To avoid creating unnecessary changes and to have the golden tests
consistent on the continuous integration tests, they should only be regenerated on Linux.

You can update golden tests files locally on Linux just by running
```shell
flutter test --update-goldens
```

To update the golden tests from Windows or MacOS, run the
[`Update Goldens`](https://github.com/nt4f04uNd/sweyer/actions/workflows/update_goldens.yml)
workflow on GitHub **in your fork**. Unless you are a contributor, you can't run it on the main
repository. In the popup, choose on which branch the goldens should be updated and whether
the workflow should automatically create a commit on that branch with the updated golden artifacts:

![The workflow site on GitHub](static_assets/readme/run_update_goldens_workflow.png)

The workflow also uploads a `golden-test-updated` artifact, which will contain the generated
golden files:

![The workflow result site on GitHub](static_assets/readme/update_goldens_workflow_result.png)

Those new files can be put into `test/golden/goldens` folder and manually pushed to your PR.
