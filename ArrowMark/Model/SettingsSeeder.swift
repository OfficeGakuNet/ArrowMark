import CoreData

/// アプリ初回起動時に 1 回だけ呼び出して CoreData を初期化する
struct SettingsSeeder {

    /// ⚠️ ここを書き換えれば初期データを増減できます
    private static let defaultRows: [(Int16, Int16, String, Bool)] = [
        // masterID , no , content      , isSelected
        (1, 0, "天候",           false),
        (1, 1, "晴れ",           true ),
        (1, 2, "曇り",           false),
        (1, 3, "雨",             false),

        (2, 0, "風",             false),
        (2, 1, "無風",           true ),
        (2, 2, "弱風",           false),
        (2, 3, "強風",           false),

        (3, 0, "場所",           false),

        (4, 0, "タイトル",        false),
        (4, 1, "練習",           true ),
        (4, 2, "記録会",         false),

        (5, 0, "距離",           false),
        (5, 1, "18m",            false),
        (5, 2, "30m",            false),
        (5, 3, "50m",            true ),
        (5, 4, "70m",            false),

        (6, 0, "的の種類",        false),
        (6, 1, "大的",           true ),
        (6, 2, "40cm",          false)
    ]

    /// 既に投入済みなら何もしない
    static func initializeIfNeeded(context: NSManagedObjectContext) {
        let key = "isSettingsSeeded"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        context.performAndWait {
            for row in defaultRows {
                let e = SettingItemEntity(context: context)
                e.id         = UUID().uuidString
                e.masterID   = row.0
                e.no         = row.1
                e.content    = row.2
                e.isSelected = row.3
            }
            try? context.save()
            UserDefaults.standard.set(true, forKey: key)
            print("✅ CoreData に初期設定を投入しました (\(defaultRows.count) rows)")
        }
    }
}
