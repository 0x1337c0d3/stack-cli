import Foundation

@discardableResult
private func executeAppleScript(_ source: String) -> NSAppleEventDescriptor? {
    var error: NSDictionary?
    guard let script = NSAppleScript(source: source) else {
        print("error: failed to create AppleScript")
        exit(1)
    }
    let result = script.executeAndReturnError(&error)
    if let error = error {
        let message = error["NSAppleScriptErrorMessage"] as? String ?? "unknown error"
        print("AppleScript error: \(message)")
        exit(1)
    }
    return result
}

private func parseStringList(_ desc: NSAppleEventDescriptor) -> [String] {
    guard desc.numberOfItems > 0 else { return [] }
    return (1...Int(desc.numberOfItems)).compactMap { desc.atIndex($0)?.stringValue }
}

private func escapeForAppleScript(_ string: String) -> String {
    return string.replacingOccurrences(of: "\\", with: "\\\\")
                 .replacingOccurrences(of: "\"", with: "\\\"")
}

public final class Notes {

    public func listFolders(json: Bool) {
        let result = executeAppleScript("""
            tell application "Notes"
                set output to {}
                repeat with f in every folder
                    set end of output to {name of f, count of notes of f}
                end repeat
                return output
            end tell
            """)!

        var folders: [FolderItem] = []
        guard result.numberOfItems > 0 else {
            if json {
                print(encodeToJson(data: folders))
            }
            return
        }

        for i in 1...Int(result.numberOfItems) {
            guard let record = result.atIndex(i) else { continue }
            let name = record.atIndex(1)?.stringValue ?? ""
            let count = Int(record.atIndex(2)?.int32Value ?? 0)
            folders.append(FolderItem(name: name, count: count))
        }

        if json {
            print(encodeToJson(data: folders))
        } else {
            for folder in folders {
                print("\(folder.name) (\(folder.count))")
            }
        }
    }

    public func showFolder(_ folderName: String, json: Bool) {
        let escaped = escapeForAppleScript(folderName)
        let result = executeAppleScript("""
            tell application "Notes"
                tell folder "\(escaped)"
                    set noteNames to name of every note
                    set noteIds to id of every note
                    set noteDates to {}
                    set modDates to {}
                    repeat with n in every note
                        set end of noteDates to date string of (creation date of n)
                        set end of modDates to date string of (modification date of n)
                    end repeat
                    return {noteNames, noteIds, noteDates, modDates}
                end tell
            end tell
            """)!

        let notes = parseNoteDescriptor(result, folder: folderName)

        if json {
            print(encodeToJson(data: notes))
        } else {
            for (i, note) in notes.enumerated() {
                print("\(i): \(note.name)")
            }
        }
    }

    public func showAllNotes(json: Bool) {
        let result = executeAppleScript("""
            tell application "Notes"
                set allNames to {}
                set allIds to {}
                set allFolders to {}
                set allDates to {}
                set allModDates to {}
                repeat with f in every folder
                    set folderName to name of f
                    repeat with n in every note of f
                        set end of allNames to name of n
                        set end of allIds to id of n
                        set end of allFolders to folderName
                        set end of allDates to date string of (creation date of n)
                        set end of allModDates to date string of (modification date of n)
                    end repeat
                end repeat
                return {allNames, allIds, allFolders, allDates, allModDates}
            end tell
            """)!

        let notes = parseAllNotesDescriptor(result)

        if json {
            print(encodeToJson(data: notes))
        } else {
            for (i, note) in notes.enumerated() {
                print("\(i): [\(note.folder)] \(note.name)")
            }
        }
    }

    public func addNote(toFolder folderName: String, title: String, body: String?) {
        let escapedFolder = escapeForAppleScript(folderName)
        let escapedTitle = escapeForAppleScript(title)
        let bodyScript: String
        if let body = body {
            let escapedBody = escapeForAppleScript(body)
            bodyScript = "make new note with properties {name:\"\(escapedTitle)\", body:\"\(escapedBody)\"}"
        } else {
            bodyScript = "make new note with properties {name:\"\(escapedTitle)\"}"
        }

        executeAppleScript("""
            tell application "Notes"
                tell folder "\(escapedFolder)"
                    \(bodyScript)
                end tell
            end tell
            """)

        print("Added '\(title)' to '\(folderName)'")
    }

    public func deleteNote(inFolder folderName: String, atIndex index: Int) {
        let escaped = escapeForAppleScript(folderName)
        // AppleScript lists are 1-based; CLI presents 0-based indexes
        let appleScriptIndex = index + 1

        executeAppleScript("""
            tell application "Notes"
                tell folder "\(escaped)"
                    set noteList to every note
                    if \(appleScriptIndex) > (count of noteList) then
                        error "Index out of range"
                    end if
                    delete item \(appleScriptIndex) of noteList
                end tell
            end tell
            """)

        print("Deleted note at index \(index) in '\(folderName)'")
    }

    public func readNote(inFolder folderName: String, named noteName: String, json: Bool) {
        let escapedFolder = escapeForAppleScript(folderName)
        let escapedName = escapeForAppleScript(noteName)
        let result = executeAppleScript("""
            tell application "Notes"
                tell folder "\(escapedFolder)"
                    set selectedNote to first note whose name is "\(escapedName)"
                    return body of selectedNote
                end tell
            end tell
            """)!

        let body = result.stringValue ?? ""

        if json {
            print(body)
        } else {
            print(stripHtml(body))
        }
    }

    public func appendNote(inFolder folderName: String, named noteName: String, text: String) {
        let escapedFolder = escapeForAppleScript(folderName)
        let escapedName = escapeForAppleScript(noteName)
        let escapedText = escapeForAppleScript(text)

        executeAppleScript("""
            tell application "Notes"
                tell folder "\(escapedFolder)"
                    set selectedNote to first note whose name is "\(escapedName)"
                    set body of selectedNote to (body of selectedNote) & "<p>\(escapedText)</p>"
                end tell
            end tell
            """)

        print("Appended to '\(noteName)' in '\(folderName)'")
    }

    public func searchNotes(keyword: String, json: Bool) {
        let escapedKeyword = escapeForAppleScript(keyword)
        let result = executeAppleScript("""
            tell application "Notes"
                set matchNames to {}
                set matchIds to {}
                set matchFolders to {}
                set matchDates to {}
                set matchModDates to {}
                repeat with f in every folder
                    set folderName to name of f
                    repeat with n in every note of f
                        if name of n contains "\(escapedKeyword)" or body of n contains "\(escapedKeyword)" then
                            set end of matchNames to name of n
                            set end of matchIds to id of n
                            set end of matchFolders to folderName
                            set end of matchDates to date string of (creation date of n)
                            set end of matchModDates to date string of (modification date of n)
                        end if
                    end repeat
                end repeat
                return {matchNames, matchIds, matchFolders, matchDates, matchModDates}
            end tell
            """)!

        let notes = parseAllNotesDescriptor(result)

        if json {
            print(encodeToJson(data: notes))
        } else {
            for (i, note) in notes.enumerated() {
                print("\(i): [\(note.folder)] \(note.name)")
            }
        }
    }

    // MARK: - Private helpers

    private func stripHtml(_ html: String) -> String {
        var text = html
        for tag in ["</p>", "</div>", "</li>", "<br>", "<br/>"] {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>") {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseNoteDescriptor(_ result: NSAppleEventDescriptor, folder: String) -> [NoteItem] {
        guard result.numberOfItems >= 4 else { return [] }
        let namesDesc  = result.atIndex(1)!
        let idsDesc    = result.atIndex(2)!
        let datesDesc  = result.atIndex(3)!
        let modDatesDesc = result.atIndex(4)!
        let count = Int(namesDesc.numberOfItems)
        guard count > 0 else { return [] }

        return (1...count).map { i in
            NoteItem(
                id:               idsDesc.atIndex(i)?.stringValue    ?? "",
                name:             namesDesc.atIndex(i)?.stringValue   ?? "",
                folder:           folder,
                creationDate:     datesDesc.atIndex(i)?.stringValue,
                modificationDate: modDatesDesc.atIndex(i)?.stringValue
            )
        }
    }

    private func parseAllNotesDescriptor(_ result: NSAppleEventDescriptor) -> [NoteItem] {
        guard result.numberOfItems >= 5 else { return [] }
        let namesDesc    = result.atIndex(1)!
        let idsDesc      = result.atIndex(2)!
        let foldersDesc  = result.atIndex(3)!
        let datesDesc    = result.atIndex(4)!
        let modDatesDesc = result.atIndex(5)!
        let count = Int(namesDesc.numberOfItems)
        guard count > 0 else { return [] }

        return (1...count).map { i in
            NoteItem(
                id:               idsDesc.atIndex(i)?.stringValue      ?? "",
                name:             namesDesc.atIndex(i)?.stringValue     ?? "",
                folder:           foldersDesc.atIndex(i)?.stringValue   ?? "",
                creationDate:     datesDesc.atIndex(i)?.stringValue,
                modificationDate: modDatesDesc.atIndex(i)?.stringValue
            )
        }
    }
}
