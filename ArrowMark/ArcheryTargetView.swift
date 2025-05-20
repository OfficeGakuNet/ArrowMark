import SwiftUI

struct ArcheryTargetView: View {
    var onComplete: ([String]) -> Void = { _ in }
    let ringCount = 11
    let ringColors: [Color] = [
        .yellow, .yellow, .yellow,  // X, 10, 9
        .red, .red,                // 8, 7
        .blue, .blue,              // 6, 5
        .black, .black,            // 4, 3
        .white, .white             // 2, 1
    ]

    let maxRadius: CGFloat = 190
    @State private var tapPoints: [(CGPoint, String)] = []

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.width / 2)
            let step = maxRadius / CGFloat(ringCount)

            VStack {
                ZStack {
                    Canvas { context, size in
                        for i in (0..<ringCount).reversed() {
                            let radius = maxRadius * CGFloat(i + 1) / CGFloat(ringCount)
                            let rect = CGRect(
                                x: center.x - radius,
                                y: center.y - radius,
                                width: radius * 2,
                                height: radius * 2
                            )
                            context.stroke(Path(ellipseIn: rect), with: .color(.gray), lineWidth: 1)
                            context.fill(Path(ellipseIn: rect), with: .color(ringColors[i]))
                        }

                        for (point, score) in tapPoints {
                            let circleRect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                            context.stroke(Path(ellipseIn: circleRect), with: .color(.green), lineWidth: 1)
                            context.fill(Path(ellipseIn: circleRect), with: .color(.green))
                            context.draw(Text(score).font(.system(size: 20)).foregroundColor(.black), at: CGPoint(x: point.x + 12, y: point.y))
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.width)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let dist = distance(from: center, to: value.location)
                                let scoreIndex = Int(dist / step)
                                let score = scoreFromIndex(scoreIndex)
                                tapPoints.append((value.location, score))
                            }
                    )
                }

                HStack(spacing: 20) {
                    Button("1本戻す") {
                        if !tapPoints.isEmpty {
                            tapPoints.removeLast()
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)

                    Button("リセット") {
                        tapPoints.removeAll()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                }
                .padding(.top)

                Button("完了") {
                    onComplete(tapPoints.map { $0.1 })
                }
                .padding(12)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }

    func scoreFromIndex(_ index: Int) -> String {
        let scores = ["X", "10", "9", "8", "7", "6", "5", "4", "3", "2", "1"]
        return index < scores.count ? scores[index] : "M"
    }
}

struct ArcheryTargetView_Previews: PreviewProvider {
    static var previews: some View {
        ArcheryTargetView() { scores in
            print("Scores: \(scores)")
        }
    }
}
