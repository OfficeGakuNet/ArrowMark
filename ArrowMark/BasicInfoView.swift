import SwiftUI
import FirebaseFirestore

struct BasicInfoView: View {
    // MARK: — 設定読み出し
    private var weatherOptions:    [String] { UserDefaults.standard.string(forKey: "weatherOptions")?.split(separator: ",").map(String.init) ?? [] }
    private var windOptions:       [String] { UserDefaults.standard.string(forKey: "windOptions")?.split(separator: ",").map(String.init) ?? [] }
    private var locationOptions:   [String] { UserDefaults.standard.string(forKey: "locationOptions")?.split(separator: ",").map(String.init) ?? [] }
    private var titleOptions:      [String] { UserDefaults.standard.string(forKey: "titleOptions")?.split(separator: ",").map(String.init) ?? [] }
    private var distanceOptions:   [String] { UserDefaults.standard.string(forKey: "distanceOptions")?.split(separator: ",").map(String.init) ?? [] }
    private var targetTypeOptions: [String] { UserDefaults.standard.string(forKey: "targetTypeOptions")?.split(separator: ",").map(String.init) ?? [] }

    // MARK: — 入力用 State
    @State private var date        = Date()
    @State private var weather     = ""
    @State private var wind        = ""
    @State private var location    = ""
    @State private var title       = ""
    @State private var distance    = ""
    @State private var targetType  = ""
    @State private var comment     = ""
    @FocusState private var shotCountFocused: Bool

    // MARK: — エンド集計用
    @State private var ends: [[String]] = []

    // MARK: — 画面制御／アラート
    @State private var showScoreEntry = false
    @State private var validShotCount = 6
    @State private var showAlert       = false
    @State private var alertMessage    = ""

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                scoreNavigationSection
                if !ends.isEmpty {
                    endSummarySection
                }
            }
            .navigationTitle("新規入力")
            .toolbar {
                keyboardToolbar  // ← これはキーボード用
                // 👇 ここにフッターメニュー追加
                ToolbarItemGroup(placement: .bottomBar) {
                    NavigationLink(destination: HistoryView()) {
                        Text("履歴を見る")
                    }
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Text("設定へ")
                    }
                }
            }
            .navigationDestination(isPresented: $showScoreEntry) {
                ArcheryTargetView() { scores in
                    ends.append(scores)
                    showScoreEntry = false
                }
            }
            .alert("保存結果", isPresented: $showAlert) {
                Button("OK") {
                    ends.removeAll()
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear(perform: initializeDefaults)
        }
    }

    private func initializeDefaults() {
        weather    = weatherOptions.first ?? ""
        wind       = windOptions.first ?? ""
        location   = locationOptions.first ?? ""
        title      = titleOptions.first ?? ""
        distance   = distanceOptions.first ?? ""
        targetType = targetTypeOptions.first ?? ""
    }

    private var basicInfoSection: some View {
        Section("基本情報") {
            DatePicker("日付", selection: $date, displayedComponents: .date)
            Picker("天候",   selection: $weather)    { ForEach(weatherOptions,    id: \.self) { Text($0) } }
            Picker("風（任意）", selection: $wind)     { ForEach(windOptions,       id: \.self) { Text($0) } }
            Picker("場所",   selection: $location)   { ForEach(locationOptions,   id: \.self) { Text($0) } }
            Picker("タイトル（任意）", selection: $title)    { ForEach(titleOptions,      id: \.self) { Text($0) } }
            Picker("距離（例：70m）", selection: $distance) { ForEach(distanceOptions,   id: \.self) { Text($0) } }
            Picker("的の種類（例：大的）", selection: $targetType) { ForEach(targetTypeOptions, id: \.self) { Text($0) } }
            TextField("コメント（任意）", text: $comment)
        }
    }

    private var scoreNavigationSection: some View {
        Section {
            Button("スコア入力へ進む") {
                shotCountFocused = false
                showScoreEntry = true
            }
        }
    }

    private var endSummarySection: some View {
        let total = computeTotalAccum()
        let arrows = validShotCount * ends.count
        let perfect = arrows * 10
        let avg = arrows > 0 ? String(format: "%.2f", Double(total) / Double(arrows)) : "0.00"

        return Section("エンド集計") {
            Text("累積合計: \(total)／\(perfect)（\(avg)）")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(ends.indices, id: \.self) { idx in
                let scores = ends[idx]
                let subtotal = computeSubTotal(for: scores)
                HStack {
                    Text("No \(idx+1): \(scores.joined(separator: ", "))")
                    Spacer()
                    Text("小計: \(subtotal)")
                }
            }

            Button("Save") {
                saveToFirestore()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func computeTotalAccum() -> Int {
        var sum = 0
        for end in ends {
            for s in end {
                if s == "X" || s == "10" {
                    sum += 10
                } else if let n = Int(s) {
                    sum += n
                }
            }
        }
        return sum
    }

    private func computeSubTotal(for scores: [String]) -> Int {
        var sum = 0
        for s in scores {
            if s == "X" || s == "10" {
                sum += 10
            } else if let n = Int(s) {
                sum += n
            }
        }
        return sum
    }

    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("完了") { shotCountFocused = false }
        }
    }

    private func saveToFirestore() {
        let endsData = ends.map { ["scores": $0] as [String:Any] }
        let doc: [String:Any] = [
            "date": Timestamp(date: date),
            "weather": weather,
            "wind": wind,
            "location": location,
            "title": title,
            "distance": distance,
            "targetType": targetType,
            "shotCount": validShotCount,
            "comment": comment,
            "ends": endsData,
            "createdAt": Timestamp(date: Date())
        ]
        Firestore.firestore()
            .collection("archeryScores")
            .addDocument(data: doc) { error in
                DispatchQueue.main.async {
                    if let e = error {
                        alertMessage = "保存失敗: \(e.localizedDescription)"
                    } else {
                        alertMessage = "保存完了！"
                    }
                    showAlert = true
                }
            }
    }
}

struct BasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoView()
    }
}
