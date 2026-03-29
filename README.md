# stack-cli

A Swift CLI for interacting with macOS Reminders and Notes from the command line.

## Reminders

#### Show all lists

```
$ stack reminders show-lists
Personal
Work
Soon
```

#### Show reminders on a list

```
$ stack reminders show Soon
0: Write README
1: Ship stack-cli
```

#### Add a reminder

```
$ stack reminders add Soon "Contribute to open source"
$ stack reminders add Soon "Go to the grocery store" --due-date "tomorrow 9am"
$ stack reminders add Soon "Something really important" --priority high
$ stack reminders show Soon
0: Contribute to open source
1: Go to the grocery store (in 10 hours)
2: Something really important (priority: high)
```

#### Move a reminder to another list

```
$ stack reminders move Soon 0 --to Work
Moved 'Contribute to open source' to 'Work'
```

#### Complete a reminder

```
$ stack reminders complete Soon 0
Completed 'Write README'
```

#### Uncomplete a reminder

```
$ stack reminders show Soon --only-completed
0: Write README
$ stack reminders uncomplete Soon 0
Uncompleted 'Write README'
```

#### Edit a reminder

```
$ stack reminders edit Soon 0 Updated reminder text
Updated reminder 'Updated reminder text'
```

#### Delete a reminder

```
$ stack reminders delete Soon 0
Deleted 'Write README'
```

#### Show reminders due on or by a date

```
$ stack reminders show-all --due-date today
$ stack reminders show-all --due-date today --include-overdue
$ stack reminders show Soon --due-date "next monday"
```

#### JSON output

All commands accept `--json`:

```
$ stack reminders show-lists --json
[
  "Personal",
  "Work",
  "Soon"
]
$ stack reminders show Soon --json
[
  {
    "externalId": "...",
    "isCompleted": false,
    "list": "Soon",
    "title": "Ship stack-cli"
  }
]
```

---

## Notes

#### List all folders

```
$ stack notes list-folders
Personal (4)
Work (12)
```

#### List notes in a folder

```
$ stack notes list Personal
0: Meeting notes
1: Shopping list
2: Ideas
```

#### Read a note

```
$ stack notes read Personal "Meeting notes"
Discussed Q2 roadmap
Action items:
- Follow up with design
- Schedule next sync
```

#### Append to a note

```
$ stack notes append Personal "Meeting notes" --text "Follow-up scheduled for Friday"
Appended to 'Meeting notes' in 'Personal'
```

#### Create a note

```
$ stack notes create Personal "Shopping list"
$ stack notes create Personal "Meeting notes" --body "Discussed Q2 roadmap"
```

#### Search notes

```
$ stack notes search "Q2"
0: [Work] Q2 planning
1: [Personal] Meeting notes
```

#### Show all notes across all folders

```
$ stack notes show-all
0: [Personal] Meeting notes
1: [Personal] Shopping list
2: [Work] Q2 planning
```

#### Delete a note

```
$ stack notes delete Personal 0
Deleted note at index 0 in 'Personal'
```

#### JSON output

```
$ stack notes list-folders --json
[
  {
    "count": 4,
    "name": "Personal"
  }
]
$ stack notes list Personal --json
[
  {
    "creationDate": "Sunday, 29 March 2026",
    "folder": "Personal",
    "id": "x-coredata://...",
    "modificationDate": "Sunday, 29 March 2026",
    "name": "Shopping list"
  }
]
$ stack notes read Personal "Meeting notes" --json
<html><body>...</body></html>
```

---

## Permissions

On first run, macOS will prompt for:
- **Reminders access** — required for all `stack reminders` commands
- **Notes automation access** — required on first use of any `stack notes` command

---

## Building

Requires Xcode command line tools.

```
$ swift build -c release
$ cp .build/release/stack-cli /usr/local/bin/stack
```

#### Run tests

```
$ swift test
```

#### Shell completion

```
$ stack --generate-completion-script zsh > /usr/local/share/zsh/site-functions/_stack
```

---

## Help

```
$ stack --help
$ stack reminders --help
$ stack notes --help
$ stack reminders move --help
```
