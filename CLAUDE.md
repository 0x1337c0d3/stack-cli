# stack-cli

Swift CLI for macOS Reminders (EventKit) and Notes (NSAppleScript). Modeled on [keith/reminders-cli](https://github.com/keith/reminders-cli).

## Build & test

```bash
swift build
swift test
swift build -c release
```

Binary lands at `.build/debug/stack-cli` or `.build/release/stack-cli`.

## Project structure

```
Sources/
  stack-cli/main.swift          # Entry point: requests Reminders access, calls CLI.main()
  StackLibrary/
    CLI.swift                   # All ArgumentParser command definitions
    Reminders.swift             # EventKit wrapper + encodeToJson()
    Notes.swift                 # NSAppleScript wrapper for Notes.app
    NoteModels.swift            # NoteItem / FolderItem Encodable structs
    EKReminder+Encodable.swift  # JSON encoding for EKReminder
    Sort.swift                  # Sort / CustomSortOrder enums
    NaturalLanguage.swift       # NSDataDetector date parsing for --due-date
    CollectionType+Extension.swift  # safe subscript, find()
Tests/StackTests/StackTests.swift   # NaturalLanguage date parsing tests
```

## Command structure

All reminders commands are grouped under `stack reminders`:
- `show-lists`, `show`, `show-all`, `add`, `complete`, `uncomplete`, `delete`, `edit`, `new-list`, `move`

All notes commands are grouped under `stack notes`:
- `list-folders`, `list`, `show-all`, `create`, `delete`, `read`, `append`, `search`

The `move` command takes the source list as the first positional argument: `stack reminders move <list> <index> --to <dest>`.

## Architecture

- **Reminders**: `private let Store = EKEventStore()` is file-level in `Reminders.swift` — must stay long-lived or the access grant is lost.
- **Async pattern**: EventKit callbacks are bridged to synchronous calls via `DispatchSemaphore`.
- **NSAppleScript**: Called synchronously on the main thread (fine — ArgumentParser's `run()` is on main). No `import AppKit` needed; `NSAppleScript` is in Foundation on macOS.
- **JSON**: `encodeToJson()` is module-level in `Reminders.swift` and shared by `Notes.swift`. All commands accept `--json` (boolean flag).
- **move command**: Reassigns `reminder.calendar` to the destination `EKCalendar` and calls `Store.save()`. `EKCalendarItem.calendar` is a mutable property so no copy is needed.

## Notes AppleScript

`Notes.swift` queries the Notes app using parallel-array AppleScript (e.g. `name of every note`, `id of every note`) and parses the returned `NSAppleEventDescriptor` list-of-lists. AppleScript lists are 1-based; the CLI presents 0-based indexes. Special characters in folder/note names are escaped before interpolation into AppleScript source strings.

`read` and `append` locate a note by name using `first note whose name is "<name>"`. `read` returns the HTML body; `stripHtml()` converts it to plain text for the default output. `append` sets the body to `(body) & "<p>text</p>"`. `search` iterates all folders/notes filtering where `name contains kw or body contains kw`, then reuses `parseAllNotesDescriptor`.

## Adding commands

**New reminders command**: add a `private struct` implementing `ParsableCommand` in `CLI.swift`, add `@Flag var json: Bool = false`, call a new method on the `Reminders` instance. Register the struct in `RemindersCommand.configuration.subcommands`.

**New notes subcommand**: add a `private struct` with `commandName` set, call a method on the `Notes` instance. Register in `NotesCommand.configuration.subcommands`.

## macOS compatibility

- Minimum deployment target: macOS 10.15
- `Store.requestFullAccessToReminders` requires macOS 14+ — the `#available(macOS 14.0, *)` guard in `Reminders.requestAccess()` must be preserved.
- `Calendar.Component.dayOfYear` requires macOS 15+ — guarded with `#available(macOS 15.0, *)` in `NaturalLanguage.swift`.
