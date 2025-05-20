import SwiftUI
import CoreData
import FirebaseFirestore

struct SettingsDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // 親ヘッダー
    let headerEntity: SettingItemEntity

    // 子レコード（no > 0）を自動監視
    @FetchRequest private var items: FetchedResults<SettingItemEntity>

    @State private var showAddModal = false
    @State private var newContent   = ""
    @State private var isAdding     = false

    init(headerEntity: SettingItemEntity) {
        self.headerEntity = headerEntity
        _items = FetchRequest(
            entity: SettingItemEntity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \SettingItemEntity.no, ascending: true)],
            predicate: NSPredicate(format: "masterID == %d AND no > 0", headerEntity.masterID)
        )
    }

    var body: some View {
        Form {
            Section {
                if items.isEmpty {
                    Text("データがありません").foregroundColor(.gray)
                } else {
                    ForEach(items) { item in
                        HStack {
                            Text(item.content ?? "")
                            Spacer()
                            if item.isSelected { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { select(item) }
                    }
                    .onDelete(perform: delete)
                }
            }

            Section {
                Button {
                    newContent = ""
                    showAddModal = true
                } label: {
                    Label("新規追加", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle(headerEntity.content ?? "")
        .sheet(isPresented: $showAddModal) { addModal }
    }

    // MARK: - 新規追加モーダル
    private var addModal: some View {
        NavigationStack {
            Form { TextField("内容", text: $newContent) }
                .navigationTitle("新規追加")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") { showAddModal = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("追加") { addItem() }
                            .disabled(newContent.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
                    }
                }
        }
    }

    // MARK: - CoreData & Firestore 操作
    private func addItem() {
        isAdding = true
        let e         = SettingItemEntity(context: viewContext)
        e.id          = UUID().uuidString
        e.masterID    = headerEntity.masterID
        e.no          = (items.map { $0.no }.max() ?? 0) + 1
        e.content     = newContent
        e.isSelected  = false
        try? viewContext.save()

        sync(e)       // Firestore へアップロード
        isAdding = false
        showAddModal = false
    }

    private func delete(at offsets: IndexSet) {
        offsets.forEach { viewContext.delete(items[$0]) }
        try? viewContext.save()
    }

    private func select(_ selected: SettingItemEntity) {
        for item in items {
            item.isSelected = (item == selected)
            sync(item)
        }
        try? viewContext.save()
    }

    // Firestore 1 レコード同期
    private func sync(_ entity: SettingItemEntity) {
        let dto = SettingItemDTO(entity: entity)
        Firestore.firestore()
            .collection("settings")
            .document(dto.id)
            .setData(dto.toDictionary())
    }
}
