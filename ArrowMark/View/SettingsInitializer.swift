import FirebaseFirestore

func saveSettingsToFirestore() {
    let keys = [
        "weatherOptions",
        "windOptions",
        "locationOptions",
        "titleOptions",
        "distanceOptions",
        "targetTypeOptions"
    ]
    
    var data: [String: Any] = [:]
    
    for key in keys {
        if let value = UserDefaults.standard.string(forKey: key) {
            let options = value.split(separator: ",").map { String($0) }
            data[key] = options
        }
    }
    
    Firestore.firestore()
        .collection("settings")
        .document("default")
        .setData(data) { error in
            if let error = error {
                print("⚠️ 設定の保存に失敗: \(error.localizedDescription)")
            } else {
                print("✅ 設定がFirestoreに保存されました")
            }
        }
}
