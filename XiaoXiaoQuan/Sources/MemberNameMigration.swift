import Foundation

extension SpaceData {
    /// Rename only identity metadata. Message bodies, IDs and attachments stay intact.
    mutating func adoptSugarName() -> Bool {
        let old = "小鱼", new = "小糖"
        var changed = false
        for i in messages.indices where messages[i].sender == old {
            messages[i].sender = new; changed = true
        }
        for i in petLog.indices where petLog[i].hasPrefix(old + "给团团") {
            petLog[i] = new + petLog[i].dropFirst(old.count); changed = true
        }
        for i in memories.indices {
            if memories[i].note == "由\(old)主动分享" {
                memories[i].note = "由\(new)主动分享"; changed = true
            } else if memories[i].note == "来自\(old)的聊天" {
                memories[i].note = "来自\(new)的聊天"; changed = true
            }
        }
        if var quiz = creative?.quiz, quiz.players.contains(old) {
            quiz.players = quiz.players.map { $0 == old ? new : $0 }
            if let answer = quiz.answers.removeValue(forKey: old) { quiz.answers[new] = answer }
            creative?.quiz = quiz; changed = true
        }
        if var p = playground {
            for i in p.expenses.indices where p.expenses[i].members.contains(old) {
                p.expenses[i].members = p.expenses[i].members.map { $0 == old ? new : $0 }
                if p.expenses[i].paid.remove(old) != nil { p.expenses[i].paid.insert(new) }
                changed = true
            }
            if changed { playground = p }
        }
        return changed
    }
}
