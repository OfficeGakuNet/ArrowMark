// CoreData/CoreData/SettingsInitializer.swift
import CoreData

struct SettingsInitializer {

    static func resetSettingsData(context: NSManagedObjectContext) {
        // ---- 既存を完全削除 ----
        let fetch: NSFetchRequest<NSFetchRequestResult> = SettingItemEntity.fetchRequest()
        let delete = NSBatchDeleteRequest(fetchRequest: fetch)
        _ = try? context.execute(delete)

        // ★ キャッシュをクリア（これを入れないと古い行が見え続ける）
        context.reset()

        // ---- 初期データ ----
        let defaults: [(Int16, Int16,  String,  Bool)] = [
            /* master , no , content , isSelected */
            (1, 0,  "天候", false),
            (1, 1,  "晴れ", true ),
            (1, 2,  "曇り", false),
            (1, 3,  "雨"  , false),

            (2, 0,  "風",   false),
            (2, 1,  "無風", true ),
            (2, 2,  "弱風", false),
            (2, 3,  "強風", false),

            (3, 0,  "場所", false),

            (4, 0,  "タイトル", false),
            (4, 1,  "練習",     true ),
            (4, 2,  "記録会",   false),

            (5, 0,  "距離", false),
            (5, 1,  "18 m", true ),
            (5, 2,  "30 m", false),
            (5, 3,  "50 m", false),
            (5, 4,  "70 m", false),

            (6, 0,  "的の種類", false),
            (6, 1,  "大的",   true ),
            (6, 2,  "40 cm",  false),
            (6, 3,  "三つ目的", false)
        ]

        for (mid, no, content, sel) in defaults {
            let e = SettingItemEntity(context: context)
            e.id         = UUID().uuidString
            e.masterID   = mid
            e.no         = no
            e.content    = content
            e.isSelected = sel
        }
        try? context.save()
    }
}
