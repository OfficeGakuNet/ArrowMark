import SwiftUI
import FirebaseFirestore

struct SettingsDetailView: View {
    let header: SettingHeader

    @State private var items: [SettingItem] = []
    @State private var showAddSheet = false
    @State private var newContent = ""

    var body: some View {
        List {
            ForEach(items) { item in
                HStack {
                    Text(item.content)
                    Spacer()
                    if item.isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectItem(item)
                }
            }
            .onDelete(perform: deleteItems)

            Button(action: {
                showAddSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("新規追加")
                        .foregroundColor(.blue)
                }
                .font(.title3)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(Color.clear)
        }
        .navigationTitle(header.content)
        .onAppear(perform: loadItems)
        // ↓↓↓ カスタムシートUI（濃い色、中央寄せ） ↓↓↓
        .sheet(isPresented: $showAddSheet) {
            VStack(spacing: 24) {
                Text("新規追加")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 16)
                TextField("内容", text: $newContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 32)
                HStack {
                    Button("キャンセル") {
                        showAddSheet = false
                        newContent = ""
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    Button("追加") {
                        addItem()
                        showAddSheet = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(newContent.isEmpty ? Color.blue.opacity(0.3) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(newContent.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGray6))
            .cornerRadius(24)
            .padding(.horizontal, 16)
        }
    }

    private func loadItems() {
        let db = Firestore.firestore()
        db.collection("settings")
            .whereField("masterID", isEqualTo: header.masterID)
            .whereField("no", isGreaterThan: 0)
            .order(by: "no")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let snapshot = snapshot {
                        self.items = snapshot.documents.compactMap { doc in
                            try? doc.data(as: SettingItem.self)
                        }
                    } else {
                        print("⚠️ 子項目の読み込み失敗: \(error?.localizedDescription ?? "不明なエラー")")
                    }
                }
            }
    }

    private func addItem() {
        let db = Firestore.firestore()
        let newNo = (items.map { $0.no }.max() ?? 0) + 1
        let id = "m\(header.masterID)_n\(newNo)"
        let newItem = SettingItem(id: id, masterID: header.masterID, no: newNo, content: newContent, isSelected: false)

        do {
            try db.collection("settings").document(id).setData(from: newItem) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Firestore保存エラー: \(error.localizedDescription)")
                    } else {
                        self.newContent = ""
                        self.loadItems()
                    }
                }
            }
        } catch {
            print("❌ Firestore保存エラー: \(error.localizedDescription)")
        }
    }

    private func selectItem(_ selected: SettingItem) {
        let db = Firestore.firestore()
        for var item in items {
            let isNowSelected = item.id == selected.id
            item.isSelected = isNowSelected
            if let id = item.id {
                db.collection("settings").document(id).updateData(["isSelected": isNowSelected])
            }
        }
        for i in 0..<items.count {
            items[i].isSelected = (items[i].id == selected.id)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let db = Firestore.firestore()
        for index in offsets {
            if let id = items[index].id {
                db.collection("settings").document(id).delete()
            }
        }
        items.remove(atOffsets: offsets)
    }
}

struct SettingItem: Identifiable, Codable {
    @DocumentID var id: String?
    var masterID: Int
    var no: Int
    var content: String
    var isSelected: Bool

    // ここに直接追加
    func toDictionary() -> [String: Any] {
        [
            "id": id ?? "",
            "masterID": masterID,
            "no": no,
            "content": content,
            "isSelected": isSelected
        ]
    }
}

