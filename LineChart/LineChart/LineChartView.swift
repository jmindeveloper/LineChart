//
//  LineChartView.swift
//  LineChart
//
//  Created by J_Min on 2022/11/19.
//

import UIKit

final class LineChartView: UIView {
    
    private let lineGap: CGFloat = 60
    private let topSpace: CGFloat = 40
    private let bottomSpace: CGFloat = 40
    private var dataPoints: [CGPoint]?
    private var outerRadius: CGFloat = 12
    private var innerRadius: CGFloat = 12
    private let topHorizontalLine: CGFloat = 1
    private var data: [Int]? {
        didSet {
            reset()
            drawChart()
        }
    }
    
    private let dataLayer = CALayer()
    private let gradientLayer = CAGradientLayer()
    private let mainLayer = CALayer()
    private let scrollView = UIScrollView()
    private let horizontalGridLayer = CALayer()
    
    var isDrawCurve: Bool = false
    var isDrawLineShadow: Bool = false
    var isDrawDots: Bool = false
    var isDrawHorizontalGrid: Bool = false
    var isDrawVerticalGrid: Bool = false
    var isDrawValueLabels: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayers()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setLayers()
    }
    
    private func setLayers() {
        scrollView.bounces = false
        gradientLayer.colors = [UIColor.orange.cgColor, UIColor.white.cgColor]
        scrollView.layer.addSublayer(gradientLayer)
        mainLayer.addSublayer(dataLayer)
        scrollView.layer.addSublayer(mainLayer)

        layer.addSublayer(horizontalGridLayer)
        addSubview(scrollView)
        self.backgroundColor = .white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
    }
    
    /// 차트에 대한 모든 설정 완료후 호출해야 버그없음ㅋ
    func setData(datas: [Int]) {
        self.data = datas
    }
    
    private func drawChart() {
        if let data = data {
            scrollView.contentSize = CGSize(width: CGFloat(data.count) * lineGap + lineGap * 2, height: frame.height)
            mainLayer.frame = CGRect(x: 0, y: 0, width: CGFloat(data.count) * lineGap, height: frame.height)
            dataLayer.frame = CGRect(x: 0, y: topSpace, width: mainLayer.frame.width, height: mainLayer.frame.height - topSpace - bottomSpace)
            gradientLayer.frame = dataLayer.frame
            dataPoints = convertDataEntriesToPoints(entries: data)
            horizontalGridLayer.frame = CGRect(x: 0, y: topSpace, width: frame.width, height: mainLayer.frame.height - topSpace - bottomSpace)
            maskGradientLayer()
            if isDrawHorizontalGrid { drawHorizontalGrid() }
            if isDrawCurve {
                drawCurveChartLine()
            } else {
                drawChartLine()
            }
            if isDrawDots { drawChartDots() }
            if isDrawValueLabels { drawLabels() }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.moveChartFirst(animated: true)
        }
        setNeedsDisplay()
    }
    
    private func moveChartFirst(animated: Bool) {
        let offset = CGPoint(x: scrollView.contentSize.width - scrollView.bounds.width + scrollView.contentInset.right, y: 0)
        scrollView.setContentOffset(offset, animated: animated)
    }
    
    private func convertDataEntriesToPoints(entries: [Int]) -> [CGPoint] {
        if let max = entries.max(),
           let min = entries.min() {
            
            var result: [CGPoint] = []
            let minMaxRange: CGFloat = CGFloat(max - min) * topHorizontalLine
            
            for i in 0..<entries.count {
                let height = dataLayer.frame.height * (1 - ((CGFloat(entries[i]) - CGFloat(min)) / minMaxRange))
                let point = CGPoint(x: CGFloat(i) * lineGap + 40, y: height)
                result.append(point)
            }
            return result
        }
        return []
    }
    
    private func maskGradientLayer() {
        guard let dataPoints = dataPoints, dataPoints.count > 0 else { return }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: dataPoints[0].x, y: dataLayer.frame.height))
        path.addLine(to: dataPoints[0])
        if isDrawCurve {
            if let linePath = CurvePathAlgorithm.shared.createCurvePath(dataPoints) {
                path.append(linePath)
            }
        } else {
            if let linePath = createPath() {
                path.append(linePath)
            }
        }
        path.addLine(to: CGPoint(x: dataPoints[dataPoints.count - 1].x, y: dataLayer.frame.height))
        path.addLine(to: CGPoint(x: dataPoints[0].x, y: dataLayer.frame.height))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.strokeColor = UIColor.clear.cgColor
        maskLayer.lineWidth = 0
        
        gradientLayer.mask = maskLayer
    }
    
    private func drawChartLine() {
        guard let dataPoints = dataPoints,
              dataPoints.count > 0,
              let path = createPath() else {
            return
        }
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor.yellow.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        dataLayer.addSublayer(lineLayer)
        
        if isDrawLineShadow {
            drawLineShadow(lineLayer: lineLayer)
        }
    }
    
    private func drawCurveChartLine() {
        guard let dataPoints = dataPoints,
                dataPoints.count > 0,
              let path = CurvePathAlgorithm.shared.createCurvePath(dataPoints) else {
            return
        }
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor.yellow.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        dataLayer.addSublayer(lineLayer)
        
        if isDrawLineShadow {
            drawLineShadow(lineLayer: lineLayer)
        }
    }
    
    private func drawLineShadow(lineLayer: CAShapeLayer) {
        lineLayer.shadowColor = UIColor.black.cgColor
        lineLayer.shadowRadius = 3
        lineLayer.shadowOpacity = 1
        lineLayer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    private func createPath() -> UIBezierPath? {
        guard let dataPoints = dataPoints, dataPoints.count > 0 else { return nil }
        let path = UIBezierPath()
        path.move(to: dataPoints[0])
        
        for i in 1..<dataPoints.count {
            path.addLine(to: dataPoints[i])
        }
        
        return path
    }
    
    private func drawChartDots() {
        var dotLayers: [DotLayer] = []
        guard let dataPoints = dataPoints else { return }
        for point in dataPoints {
            let xValue = point.x - outerRadius / 2
            let yValue = (point.y + topSpace - 20) - (outerRadius * 2)
            let dotLayer = DotLayer()
            dotLayer.dotInnerColor = .white
            dotLayer.radius = innerRadius
            dotLayer.backgroundColor = UIColor.yellow.cgColor
            dotLayer.cornerRadius = outerRadius / 2
            dotLayer.frame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
            dotLayers.append(dotLayer)
            
            dataLayer.addSublayer(dotLayer)
            
            if isDrawVerticalGrid {
                dataLayer.addSublayer(drawVerticalGrid(point: point))
            }
        }
    }
    
    private func drawVerticalGrid(point: CGPoint) -> CAShapeLayer {
        let xPoint = point.x
        let height = dataLayer.frame.height
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: xPoint, y: 0))
        path.addLine(to: CGPoint(x: xPoint, y: height))
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = path.cgPath
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor.black.withAlphaComponent(0.3).cgColor
        lineLayer.lineWidth = 0.5
        
        return lineLayer
    }
    
    private func drawHorizontalGrid() {
        let gridYPointValues: [CGFloat] = [0, 0.25, 0.5, 0.75, 1]
        let gridTextValue: [String] = ["0", "7", "15", "22", "30"].reversed()
        
        for (index, value) in gridYPointValues.enumerated() {
            let yPoint = value * horizontalGridLayer.frame.size.height
            let width = horizontalGridLayer.frame.width
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: yPoint))
            path.addLine(to: CGPoint(x: width, y: yPoint))
            
            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.fillColor = UIColor.clear.cgColor
            lineLayer.strokeColor = UIColor.black.withAlphaComponent(0.3).cgColor
            lineLayer.lineWidth = 0.5
            if value > 0 && value < 1 {
                lineLayer.lineDashPattern = [4, 4]
            }
            
            horizontalGridLayer.addSublayer(lineLayer)
            
            let textLayer = CATextLayer()
            textLayer.frame = CGRect(x: 4, y: yPoint, width: 50, height: 16)
            textLayer.foregroundColor = UIColor.black .cgColor
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
            textLayer.fontSize = 12
            textLayer.string = gridTextValue[index]
            
            horizontalGridLayer.addSublayer(textLayer)
        }
    }
    
    private func drawLabels() {
        guard let data = data,
              let dataPoints = dataPoints,
              dataPoints.count > 0 else {
            return
        }
        
        for i in 0..<dataPoints.count {
            let xValue = dataPoints[i].x - 8
            let yValue = dataPoints[i].y + 17
            let textLayer = CATextLayer()
            textLayer.frame = CGRect(x: xValue, y: yValue, width: 30, height: 22)
            textLayer.string = String(data[i])
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.alignmentMode = .left
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
            textLayer.fontSize = 20
            dataLayer.addSublayer(textLayer)
        }
    }
    
    private func reset() {
        mainLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        dataLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        horizontalGridLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        mainLayer.addSublayer(dataLayer)
    }
    
}

final class DotLayer: CALayer {
    var radius = CGFloat.zero
    var dotInnerColor = UIColor.black
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        let inset = self.bounds.size.width - radius
        let innerDotLayer = CALayer()
        innerDotLayer.frame = self.bounds.insetBy(dx: inset / 2, dy: inset / 2)
        innerDotLayer.cornerRadius = radius / 2
        self.addSublayer(innerDotLayer)
    }
    
}

struct CurvedSegment {
    var controlPoint1: CGPoint
    var controlPoint2: CGPoint
}

final class CurvePathAlgorithm {
    static let shared = CurvePathAlgorithm()
    
    private func controlPointsFrom(points: [CGPoint]) -> [CurvedSegment] {
        var result: [CurvedSegment] = []
        
        let delta: CGFloat = 0.3 // The value that help to choose temporary control points.
        
        // Calculate temporary control points, these control points make Bezier segments look straight and not curving at all
        for i in 1..<points.count {
            let A = points[i-1]
            let B = points[i]
            let controlPoint1 = CGPoint(x: A.x + delta*(B.x-A.x), y: A.y + delta*(B.y - A.y))
            let controlPoint2 = CGPoint(x: B.x - delta*(B.x-A.x), y: B.y - delta*(B.y - A.y))
            let curvedSegment = CurvedSegment(controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            result.append(curvedSegment)
        }
        
        // Calculate good control points
        for i in 1..<points.count-1 {
            /// A temporary control point
            let M = result[i-1].controlPoint2
            
            /// A temporary control point
            let N = result[i].controlPoint1
            
            /// central point
            let A = points[i]
            
            /// Reflection of M over the point A
            let MM = CGPoint(x: 2 * A.x - M.x, y: 2 * A.y - M.y)
            
            /// Reflection of N over the point A
            let NN = CGPoint(x: 2 * A.x - N.x, y: 2 * A.y - N.y)
            
            result[i].controlPoint1 = CGPoint(x: (MM.x + N.x)/2, y: (MM.y + N.y)/2)
            result[i-1].controlPoint2 = CGPoint(x: (NN.x + M.x)/2, y: (NN.y + M.y)/2)
        }
        
        return result
    }
    
    /**
     Create a curved bezier path that connects all points in the dataset
     */
    func createCurvePath(_ dataPoints: [CGPoint]) -> UIBezierPath? {
        let path = UIBezierPath()
        path.move(to: dataPoints[0])
        
        var curveSegments: [CurvedSegment] = []
        curveSegments = controlPointsFrom(points: dataPoints)
        
        for i in 1..<dataPoints.count {
            path.addCurve(to: dataPoints[i], controlPoint1: curveSegments[i-1].controlPoint1, controlPoint2: curveSegments[i-1].controlPoint2)
        }
        return path
    }
}
