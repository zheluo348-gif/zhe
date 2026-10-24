import SwiftUI
import UIKit

struct StickerRecord: Identifiable, Codable {
    var id = UUID()
    var pose: Int
    var caption: String
    var date = Date()
}
struct QuizSession: Codable {
    var round = 0
    var player = 0
    var players: [String]
    var answers: [String: Int] = [:]
    var revealed = false
    var finished = false
}
struct CreativeSpace: Codable {
    var stickerPhoto: String?
    var moodDraft = ""
    var captionDraft = ""
    var selectedPose = 0
    var stickers: [StickerRecord] = []
    var previewBeforeAI = true
    var animations = true
    var quiz: QuizSession?
    var acceptedHugs: [String] = []
    var city = ""
    var shareBattery = false
    var shareWeather = false
    var expressionDraft = ""
    var storyDraft = ""
    var habitChecks: [String] = []
}
struct AIReply: Codable {
    var text: String?
    var images: [String]?
}
enum CreativeServiceError: LocalizedError {
    case disabled, notConnected, invalidResponse, rejected
    var errorDescription: String? {
        switch self {
        case .disabled: return "你已关闭AI，可继续使用基础玩法。"
        case .notConnected: return "AI 服务还未连接，你写下的内容已保存在本机。"
        case .invalidResponse: return "这次没有收到完整结果，请稍后再试。"
        case .rejected: return "这次内容需要调整，修改一下再试试。"
        }
    }
}
/// App talks only to its own backend. Provider credentials never belong in the app.
struct CreativeService {
    var accessToken: String? = nil
    var baseURL: URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "CircleAPIBaseURL") as? String,
              let u = URL(string: s), u.scheme == "https" else { return nil }
        return u
    }
    func generate(prompt: String, mode: String, space: String, userOptedIn: Bool = false) async throws -> AIReply {
        guard userOptedIn else { throw CreativeServiceError.disabled }
        guard let baseURL else { throw CreativeServiceError.notConnected }
        guard let accessToken, !accessToken.isEmpty else { throw CreativeServiceError.notConnected }
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/creative/generate"))
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["prompt": prompt, "mode": mode, "spaceID": space])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CreativeServiceError.invalidResponse }
        if http.statusCode == 422 { throw CreativeServiceError.rejected }
        guard http.statusCode == 200 else { throw CreativeServiceError.invalidResponse }
        return try JSONDecoder().decode(AIReply.self, from: data)
    }
}
@MainActor extension CircleStore {
    var creative: CreativeSpace { current.creative ?? CreativeSpace() }
    func updateCreative(_ change: (inout CreativeSpace) -> Void) {
        update { data in
            var creative = data.creative ?? CreativeSpace()
            change(&creative)
            data.creative = creative
        }
    }
    func addLocalSpace(_ mode: String) {
        guard ["couple", "friends"].contains(mode) else { return }
        if !(state.joinedSpaces ?? []).contains(mode) {
            state.joinedSpaces = (state.joinedSpaces ?? ["couple"]) + [mode]
        }
        selectSpace(mode); persist()
    }
    func sendSticker(pose: Int, caption: String) {
        let sender = myName
        update { $0.messages.append(ChatMessage(text: caption, sender: sender, mine: true, kind: "sticker:\(pose)")) }
    }
    func collectSticker(pose: Int, caption: String) {
        updateCreative { data in
            guard !data.stickers.contains(where: { $0.pose == pose && $0.caption == caption }) else { return }
            data.stickers.insert(StickerRecord(pose: pose, caption: caption), at: 0)
        }
    }
    func acceptHug(_ id: UUID) {
        updateCreative { if !$0.acceptedHugs.contains(id.uuidString) { $0.acceptedHugs.append(id.uuidString) } }
    }
    func sendHug() { send("一个抱抱正在路上～", kind: "hug") }
    func startQuiz() {
        let players = memberNames
        updateCreative { $0.quiz = QuizSession(players: players) }
    }
    func submitQuizAnswer(_ choice: Int) {
        guard (0..<4).contains(choice) else { return }
        updateCreative { data in
            guard var q = data.quiz, !q.revealed, !q.finished, q.player < q.players.count else { return }
            q.answers[q.players[q.player]] = choice
            if q.answers.count == q.players.count { q.revealed = true }
            else { q.player += 1 }
            data.quiz = q
        }
    }
    func nextQuizRound() {
        updateCreative { data in
            guard var q = data.quiz, q.revealed else { return }
            if q.round == 2 { q.finished = true }
            else { q.round += 1; q.player = 0; q.answers = [:]; q.revealed = false }
            data.quiz = q
        }
    }
    func saveDrawing(_ image: UIImage) throws {
        guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
        try sendPhoto(data)
    }
    var currentSpaceLabel: String { spaceName }
}
