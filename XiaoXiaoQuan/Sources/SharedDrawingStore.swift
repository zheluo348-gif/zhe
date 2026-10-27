import Foundation

@MainActor extension CircleStore {
    @discardableResult func startSharedDrawing() -> UUID {
        let message = ChatMessage(text: "一起续画", sender: myName, mine: true, kind: "sharedDrawing",
            sharedDrawing: SharedDrawingSession(players: memberNames))
        update { $0.messages.append(message) }
        return message.id
    }

    func submitDrawingRound(_ id: UUID, drawing: Data, note: String, revision: Int) -> Bool {
        guard let i = current.messages.firstIndex(where: { $0.id == id }),
              var session = current.messages[i].sharedDrawing,
              session.append(drawing: drawing, note: note, revision: revision) else { return false }
        update { $0.messages[i].sharedDrawing = session }
        return true
    }

    func finishSharedDrawing(_ id: UUID, revision: Int) -> Bool {
        guard let i = current.messages.firstIndex(where: { $0.id == id }),
              var session = current.messages[i].sharedDrawing,
              session.finish(revision: revision) else { return false }
        update { $0.messages[i].sharedDrawing = session }
        return true
    }
}
