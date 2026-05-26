import SwiftUI

struct SparklineLineChart: View {
    var data: [Double]
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                let width = geometry.size.width
                let height = geometry.size.height
                let maxVal = data.max() ?? 1.0
                let minVal = data.min() ?? 0.0
                let range = max(maxVal - minVal, 0.001)

                let points = data.enumerated().map { index, val -> CGPoint in
                    let x = CGFloat(index) * (width / CGFloat(data.count - 1))
                    let y = height - CGFloat((val - minVal) / range) * height
                    return CGPoint(x: x, y: y)
                }

                path.move(to: points[0])
                for i in 0..<points.count - 1 {
                    let p0 = points[i]
                    let p1 = points[i + 1]
                    let control1 = CGPoint(x: p0.x + (p1.x - p0.x) / 2, y: p0.y)
                    let control2 = CGPoint(x: p0.x + (p1.x - p0.x) / 2, y: p1.y)
                    path.addCurve(to: p1, control1: control1, control2: control2)
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}

struct ReclaimBarChart: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<14, id: \.self) { index in
                let height: CGFloat = 6 + CGFloat(index * index) * 0.22
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(AppTheme.cyan.opacity(0.35 + Double(index) * 0.05))
                    .frame(width: 4, height: min(height, 50))
            }
        }
    }
}

struct MemoryMonitorAreaChart: View {
    var data: [Double] = [32, 35, 30, 42, 38, 45, 52, 48, 50, 42, 45, 48, 42, 44, 38, 40, 45, 42, 35, 40, 42]
    var color: Color = Color(red: 0.2, green: 0.72, blue: 0.45)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    guard data.count > 1 else { return }
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(data.count - 1)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height - CGFloat(data[0] / 100.0) * height))
                    
                    for index in 1..<data.count {
                        let x = CGFloat(index) * stepX
                        let y = height - CGFloat(data[index] / 100.0) * height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.22), color.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    guard data.count > 1 else { return }
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(data.count - 1)
                    
                    let points = data.enumerated().map { index, val -> CGPoint in
                        let x = CGFloat(index) * stepX
                        let y = height - CGFloat(val / 100.0) * height
                        return CGPoint(x: x, y: y)
                    }

                    path.move(to: points[0])
                    for i in 0..<points.count - 1 {
                        let p0 = points[i]
                        let p1 = points[i + 1]
                        let control1 = CGPoint(x: p0.x + (p1.x - p0.x) / 2, y: p0.y)
                        let control2 = CGPoint(x: p0.x + (p1.x - p0.x) / 2, y: p1.y)
                        path.addCurve(to: p1, control1: control1, control2: control2)
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
