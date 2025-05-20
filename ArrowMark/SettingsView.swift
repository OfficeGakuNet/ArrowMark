
import SwiftUI
import FirebaseFirestore
//import FirebaseFirestoreSwift

struct SettingsView: View {
    @State private var headers: [SettingHeader] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(headers) { header in
                    NavigationLink(destination: SettingsDetailView(header: header)) {
                        Text(header.content)
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear(perform: loadHeaders)
        }
    }

    private func loadHeaders() {
        let db = Firestore.firestore()
        db.collection("settings")
            .whereField("no", isEqualTo: 0)
            .order(by: "masterID")
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    self.headers = documents.compactMap { doc in
                        try? doc.data(as: SettingHeader.self)
                    }
                } else {
                    print("⚠️ 設定ヘッダの読み込みに失敗: \(error?.localizedDescription ?? "不明なエラー")")
                }
            }
    }
}

struct SettingHeader: Identifiable, Codable {
    @DocumentID var id: String?
    var masterID: Int
    var no: Int
    var content: String
    var isSelected: Bool
}
