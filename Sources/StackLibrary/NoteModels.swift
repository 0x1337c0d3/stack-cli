import Foundation

public struct NoteItem: Encodable {
    public let id: String
    public let name: String
    public let folder: String
    public let creationDate: String?
    public let modificationDate: String?
}

public struct FolderItem: Encodable {
    public let name: String
    public let count: Int
}
