# samsara_example

Example app showcasing the [samsara](../) engine library (Flutter + Flame).

Each demo is organized as a separate `Scene` inside this single app; the main
menu scene navigates to them via `pushScene` / `popScene`.

## Run

```bash
flutter pub get
flutter run -d windows
```

Note: the samsara library resolves `hetu_script` and `fluent_ui` via relative
paths to sibling directories, so those repos must exist next to this one for
`flutter pub get` to succeed.
