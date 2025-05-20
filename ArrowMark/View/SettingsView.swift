import SwiftUI
import CoreData
import FirebaseFirestore

struct SettingsView: View {
    // 1️⃣ CoreData Context は 1 つだけ
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showSyncAlert = false   // ← 表示フラグ
    @State private var syncMessage   = ""      // ← 表示するメッセージ文字列

    // 2️⃣ ヘッダー（no == 0）のみ取得
    @FetchRequest(
        entity: SettingItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SettingItemEntity.masterID, ascending: true)],
        predicate: NSPredicate(format: "no == 0")
    ) private var headers: FetchedResults<SettingItemEntity>

    var body: some View {
        NavigationStack {
            List {
                ForEach(headers) { header in
                    NavigationLink {
                        SettingsDetailView(headerEntity: header)
                    } label: {
                        Text(header.content ?? "未設定")
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("FireStoreへアップロード",  action: uploadAllToFirebase)
                        Button("FireStoreからダウンロード", action: downloadAllFromFirebase)
                    } label: {
                        Label("同期", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .alert("同期結果", isPresented: $showSyncAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncMessage)
            }
        }
    }

    // MARK: - Firestore ⇄ CoreData 同期

    private func uploadAllToFirebase() {
        let req: NSFetchRequest<SettingItemEntity> = SettingItemEntity.fetchRequest()
        let all  = (try? viewContext.fetch(req)) ?? []

        let db = Firestore.firestore()
        for entity in all {
            let dto = SettingItemDTO(entity: entity)
            db.collection("settings").document(dto.id)
              .setData(dto.toDictionary())
        }
        print("✅ アップロード \(all.count) 件")
        syncMessage   = "アップロードが完了しました（\(all.count) 件）"
        showSyncAlert = true
    }

    private func downloadAllFromFirebase() {
        let db = Firestore.firestore()
        let context = viewContext

        db.collection("settingsBackup")
              .document("all")
              .getDocument(source: .server) { snap, err in   // ← server 強制
                  if let err = err {
                      syncMessage = "ダウンロード失敗: \(err.localizedDescription)"
                      showSyncAlert = true
                      return                              // ⚠️ ここで終了
                  }
                  guard
                      let data = snap?.data(),
                      let list = data["items"] as? [[String:Any]]
                  else {
                      syncMessage = "データが存在しません"
                      showSyncAlert = true
                      return
                  }

            context.perform {
                // 既存を全削除
                let fetch: NSFetchRequest<NSFetchRequestResult> = SettingItemEntity.fetchRequest()
                let delete = NSBatchDeleteRequest(fetchRequest: fetch)
                _ = try? context.execute(delete)

                // 取り込み
                for dict in list {
                    let e = SettingItemEntity(context: context)
                    e.id         = dict["id"]         as? String
                    e.masterID   = Int16(dict["masterID"] as? Int ?? 0)
                    e.no         = Int16(dict["no"]         as? Int ?? 0)
                    e.content    = dict["content"]    as? String
                    e.isSelected = dict["isSelected"] as? Bool ?? false
                }
                try? context.save()
            }
        }
    }
}
