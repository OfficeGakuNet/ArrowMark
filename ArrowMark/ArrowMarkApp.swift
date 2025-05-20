import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestore

@main
struct ArrowMarkApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            BasicInfoView()
                .onAppear {
                    initializeSettingsIfNeededToFirestore()
                }
        }
    }
}

private func initializeSettingsIfNeededToFirestore() {
    let key = "isStructuredSettingsUploaded"
    let defaults = UserDefaults.standard

    if defaults.bool(forKey: key) {
        print("ℹ️ Firestore構造化設定はすでに初期化済み")
        return
    }

    let defaultData: [(Int, Int, String, Bool)] = [
        (1, 0, "天候", false),
        (2, 0, "風", false),
        (3, 0, "場所", false),
        (4, 0, "タイトル", false),
        (5, 0, "距離", false),
        (6, 0, "的の種類", false)
    ]

    let db = Firestore.firestore()
    for (masterID, no, content, isSelected) in defaultData {
        let docID = "m\(masterID)_n\(no)"
        db.collection("settings").document(docID).setData([
            "masterID": masterID,
            "no": no,
            "content": content,
            "isSelected": isSelected
        ]) { error in
            if let error = error {
                print("❌ Firestore保存失敗（\(docID)）: \(error.localizedDescription)")
            } else {
                print("✅ Firestore保存成功（\(docID)）")
            }
        }
    }

    defaults.set(true, forKey: key)
    print("✅ Firestore 初期設定を保存しました")
}

