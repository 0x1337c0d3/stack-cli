import ArgumentParser
import Foundation

private let reminders = Reminders()
private let notes = Notes()

// MARK: - Reminders commands

private struct ShowLists: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print the name of lists to pass to other commands")

    @Flag(help: "Output as JSON")
    var json: Bool = false

    func run() {
        reminders.showLists(json: json)
    }
}

private struct ShowAll: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print all reminders")

    @Flag(help: "Show completed items only")
    var onlyCompleted = false

    @Flag(help: "Include completed items in output")
    var includeCompleted = false

    @Flag(help: "When using --due-date, also include items due before the due date")
    var includeOverdue = false

    @Option(
        name: .shortAndLong,
        help: "Show only reminders due on this date")
    var dueDate: DateComponents?

    @Option(
        name: .shortAndLong,
        help: "Filter by tag (without #)")
    var tag: String?

    @Flag(help: "Output as JSON")
    var json: Bool = false

    func validate() throws {
        if self.onlyCompleted && self.includeCompleted {
            throw ValidationError(
                "Cannot specify both --show-completed and --only-completed")
        }
    }

    func run() {
        var displayOptions = DisplayOptions.incomplete
        if self.onlyCompleted {
            displayOptions = .complete
        } else if self.includeCompleted {
            displayOptions = .all
        }

        reminders.showAllReminders(
            dueOn: self.dueDate, includeOverdue: self.includeOverdue,
            displayOptions: displayOptions, tag: tag, json: json)
    }
}

private struct Show: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print the items on the given list")

    @Argument(
        help: "The list to print items from, see 'show-lists' for names",
        completion: .custom(listNameCompletion))
    var listName: String

    @Flag(help: "Show completed items only")
    var onlyCompleted = false

    @Flag(help: "Include completed items in output")
    var includeCompleted = false

    @Flag(help: "When using --due-date, also include items due before the due date")
    var includeOverdue = false

    @Option(
        name: .shortAndLong,
        help: "Show the reminders in a specific order, one of: \(Sort.commaSeparatedCases)")
    var sort: Sort = .none

    @Option(
        name: [.customShort("o"), .long],
        help: "How the sort order should be applied, one of: \(CustomSortOrder.commaSeparatedCases)")
    var sortOrder: CustomSortOrder = .ascending

    @Option(
        name: .shortAndLong,
        help: "Show only reminders due on this date")
    var dueDate: DateComponents?

    @Option(
        name: .shortAndLong,
        help: "Filter by tag (without #)")
    var tag: String?

    @Flag(help: "Output as JSON")
    var json: Bool = false

    func validate() throws {
        if self.onlyCompleted && self.includeCompleted {
            throw ValidationError(
                "Cannot specify both --show-completed and --only-completed")
        }
    }

    func run() {
        var displayOptions = DisplayOptions.incomplete
        if self.onlyCompleted {
            displayOptions = .complete
        } else if self.includeCompleted {
            displayOptions = .all
        }

        reminders.showListItems(
            withName: self.listName, dueOn: self.dueDate, includeOverdue: self.includeOverdue,
            displayOptions: displayOptions, tag: tag, json: json, sort: sort, sortOrder: sortOrder)
    }
}

private struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Add a reminder to a list")

    @Argument(
        help: "The list to add to, see 'show-lists' for names",
        completion: .custom(listNameCompletion))
    var listName: String

    @Argument(
        parsing: .remaining,
        help: "The reminder contents")
    var reminder: [String]

    @Option(
        name: .shortAndLong,
        help: "The date the reminder is due")
    var dueDate: DateComponents?

    @Option(
        name: .shortAndLong,
        help: "The priority of the reminder")
    var priority: Priority = .none

    @Option(
        name: .shortAndLong,
        help: "The notes to add to the reminder")
    var notes: String?

    @Option(
        name: .shortAndLong,
        help: "Comma-separated tags (e.g. work,urgent)")
    var tags: String?

    @Flag(help: "Output as JSON")
    var json: Bool = false

    func run() {
        let tagList = tags.map { $0.split(separator: ",").map(String.init) } ?? []
        reminders.addReminder(
            string: self.reminder.joined(separator: " "),
            notes: self.notes,
            tags: tagList,
            toListNamed: self.listName,
            dueDateComponents: self.dueDate,
            priority: priority,
            json: json)
    }
}

private struct Complete: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Complete a reminder")

    @Argument(
        help: "The list to complete a reminder on, see 'show-lists' for names",
        completion: .custom(listNameCompletion))
    var listName: String

    @Argument(
        help: "The index or id of the reminder to complete, see 'show' for indexes")
    var index: String

    func run() {
        reminders.setComplete(true, itemAtIndex: self.index, onListNamed: self.listName)
    }
}

private struct Uncomplete: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Uncomplete a reminder")

    @Argument(
        help: "The list to uncomplete a reminder on, see 'show-lists' for names",
        completion: .custom(listNameCompletion))
    var listName: String

    @Argument(
        help: "The index or id of the reminder to uncomplete, see 'show' for indexes")
    var index: String

    func run() {
        reminders.setComplete(false, itemAtIndex: self.index, onListNamed: self.listName)
    }
}

private struct Delete: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Delete a reminder")

    @Argument(
        help: "The list to delete a reminder on, see 'show-lists' for names",
        completion: .custom(listNameCompletion))
    var listName: String

    @Argument(
        help: "The index or id of the reminder to delete, see 'show' for indexes")
    var index: String

    func run() {
        reminders.delete(itemAtIndex: self.index, onListNamed: self.listName)
    }
}

private struct Edit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Edit the text of a reminder")

    @Argument(
        help: "The list to edit a reminder on, see 'show-lists' for names",
        completion: .custom(listNameCompletion))
    var listName: String

    @Argument(
        help: "The index or id of the reminder to edit, see 'show' for indexes")
    var index: String

    @Option(
        name: .shortAndLong,
        help: "The notes to set on the reminder, overwriting previous notes")
    var notes: String?

    @Argument(
        parsing: .remaining,
        help: "The new reminder contents")
    var reminder: [String] = []

    func validate() throws {
        if self.reminder.isEmpty && self.notes == nil {
            throw ValidationError("Must specify either new reminder content or new notes")
        }
    }

    func run() {
        let newText = self.reminder.joined(separator: " ")
        reminders.edit(
            itemAtIndex: self.index,
            onListNamed: self.listName,
            newText: newText.isEmpty ? nil : newText,
            newNotes: self.notes
        )
    }
}

private struct NewList: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Create a new list")

    @Argument(
        help: "The name of the new list")
    var listName: String

    @Option(
        name: .shortAndLong,
        help: "The name of the source of the list, if all your lists use the same source it will default to that")
    var source: String?

    func run() {
        reminders.newList(with: self.listName, source: self.source)
    }
}

private struct Move: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Move a reminder from one list to another")

    @Argument(
        help: "The source list name",
        completion: .custom(listNameCompletion))
    var from: String

    @Argument(
        help: "The index or id of the reminder to move, see 'show' for indexes")
    var index: String

    @Option(
        name: .shortAndLong,
        help: "The destination list name",
        completion: .custom(listNameCompletion))
    var to: String

    func run() {
        reminders.move(itemAtIndex: index, fromListNamed: from, toListNamed: to)
    }
}

func listNameCompletion(_ arguments: [String]) -> [String] {
    // NOTE: A list name with ':' was separated in zsh completion, there might be more of these or
    // this might break other shells
    return reminders.getListNames().map { $0.replacingOccurrences(of: ":", with: "\\:") }
}

private struct RemindersCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reminders",
        abstract: "Interact with macOS Reminders from the command line",
        subcommands: [
            ShowLists.self,
            ShowAll.self,
            Show.self,
            Add.self,
            Complete.self,
            Uncomplete.self,
            Delete.self,
            Edit.self,
            NewList.self,
            Move.self,
        ]
    )
}

// MARK: - Notes subcommand group

private struct NotesList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-folders",
        abstract: "Print all Notes folders")

    @Flag(help: "Output as JSON")
    var json: Bool = false

    func run() {
        notes.listFolders(json: json)
    }
}

private struct NotesShow: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Print notes in a folder")

    @Argument(help: "The folder to show notes from")
    var folder: String

    @Flag(help: "Output as JSON")
    var json: Bool = false

    func run() {
        notes.showFolder(folder, json: json)
    }
}

private struct NotesShowAll: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show-all",
        abstract: "Print all notes across all folders")

    @Flag(help: "Output as JSON")
    var json: Bool = false

    func run() {
        notes.showAllNotes(json: json)
    }
}

private struct NotesAdd: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a note in a folder")

    @Argument(help: "The folder to add the note to")
    var folder: String

    @Argument(
        parsing: .remaining,
        help: "The note title")
    var title: [String]

    @Option(
        name: .shortAndLong,
        help: "The body of the note")
    var body: String?

    func run() {
        notes.addNote(toFolder: folder, title: title.joined(separator: " "), body: body)
    }
}

private struct NotesDelete: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a note from a folder")

    @Argument(help: "The folder containing the note")
    var folder: String

    @Argument(help: "The index of the note to delete, see 'notes list' for indexes")
    var index: Int

    func run() {
        notes.deleteNote(inFolder: folder, atIndex: index)
    }
}

private struct NotesRead: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Read the body of a note")

    @Argument(help: "The folder containing the note")
    var folder: String

    @Argument(help: "The name of the note to read")
    var noteName: String

    @Flag(help: "Output raw HTML body")
    var json: Bool = false

    func run() {
        notes.readNote(inFolder: folder, named: noteName, json: json)
    }
}

private struct NotesAppend: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "append",
        abstract: "Append text to an existing note")

    @Argument(help: "The folder containing the note")
    var folder: String

    @Argument(help: "The name of the note to append to")
    var noteName: String

    @Option(
        name: .shortAndLong,
        help: "The text to append")
    var text: String

    func run() {
        notes.appendNote(inFolder: folder, named: noteName, text: text)
    }
}

private struct NotesSearch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search all notes for a keyword")

    @Argument(help: "The keyword to search for")
    var keyword: String

    @Flag(help: "Output as JSON")
    var json: Bool = false

    func run() {
        notes.searchNotes(keyword: keyword, json: json)
    }
}

private struct NotesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notes",
        abstract: "Interact with macOS Notes from the command line",
        subcommands: [
            NotesList.self,
            NotesShow.self,
            NotesShowAll.self,
            NotesAdd.self,
            NotesDelete.self,
            NotesRead.self,
            NotesAppend.self,
            NotesSearch.self,
        ]
    )
}

// MARK: - Top-level CLI

public struct CLI: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "stack",
        abstract: "Interact with macOS Reminders and Notes from the command line",
        subcommands: [
            RemindersCommand.self,
            NotesCommand.self,
        ]
    )

    public init() {}
}
