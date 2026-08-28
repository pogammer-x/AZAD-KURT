import Foundation

struct Company: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isActive: Bool = true
    var createdAt: Date = Date()
    var balance: Double = 0

    private enum CodingKeys: String, CodingKey {
        case id, name, isActive, createdAt, balance
    }

    init(
        id: UUID = UUID(),
        name: String,
        isActive: Bool = true,
        createdAt: Date = Date(),
        balance: Double = 0
    ) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.createdAt = createdAt
        self.balance = balance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        balance = try container.decodeIfPresent(
            Double.self,
            forKey: .balance
        ) ?? 0
    }
}
