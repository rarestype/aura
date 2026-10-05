## Testing for developmemt

Always run `swift test` in release mode (`-c release`). Debug builds are extremely slow for atmospheric computation.


## Testing before submitting a pull request

Before submitting a pull request, consider running the `Scripts/TestAll` script, which runs the full test suite, including formatting and golden reference verification.

The script will error out if there are untracked changes in the repository, and the golden reference verification takes a very long time to run, even in release mode, so it is not recommended to run `Scripts/TestAll` after every minor change.
