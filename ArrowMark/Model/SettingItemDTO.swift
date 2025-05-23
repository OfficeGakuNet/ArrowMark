import Foundation
import FirebaseFirestore   // 同期用

/// Firestore ⇔ CoreData の橋渡し用データ転送オブジェクト
struct SettingItemDTO: Identifiable, Codable {
    var id: String
    var masterID: Int
    var no: Int
    var content: String
    var isSelected: Bool

    // MARK: - CoreData → DTO 変換
    init(entity: SettingItemEntity) {
        self.id         = entity.id ?? UUID().uuidString
        self.masterID   = Int(entity.masterID)
        self.no         = Int(entity.no)
        self.content    = entity.content ?? ""
        self.isSelected = entity.isSelected
    }

    // MARK: - Firestore 書き込み用辞書
    func toDictionary() -> [String:Any] {
        ["id"        : id,
         "masterID"  : masterID,
         "no"        : no,
         "content"   : content,
         "isSelected": isSelected]
    }
}
