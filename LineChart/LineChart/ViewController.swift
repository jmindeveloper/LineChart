//
//  ViewController.swift
//  LineChart
//
//  Created by J_Min on 2022/11/19.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var curveLineChartView: LineChartView!
    
    private let randomDataRange = (0...30)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        // Do any additional setup after loading the view.
        let datas: [Int] = {
            var datas = [Int]()
            for _ in 0..<100 {
                let data = randomDataRange.randomElement() ?? 0
                datas.append(data)
            }
            return datas
        }()
        
        lineChartView.isDrawCurve = false
        lineChartView.isDrawLineShadow = true
        lineChartView.isDrawDots = true
        lineChartView.isDrawHorizontalGrid = true
        lineChartView.isDrawVerticalGrid = true
        lineChartView.isDrawValueLabels = true
        lineChartView.setData(datas: datas)
        
        curveLineChartView.isDrawCurve = true
        curveLineChartView.isDrawLineShadow = true
        curveLineChartView.isDrawDots = true
        curveLineChartView.isDrawHorizontalGrid = true
        curveLineChartView.isDrawVerticalGrid = true
        curveLineChartView.isDrawValueLabels = true
        curveLineChartView.setData(datas: datas)
    }
}

