//
//  SMFpsMonitor.swift
//  Swifter
//
//  Created by Magic on 6/5/2016.
//  Copyright © 2016 Magic. All rights reserved.
//

import Foundation
import UIKit

public class SMFpsMonitor {
    private lazy var lb: UILabel = {
        let v = UILabel()
        v.frame = CGRectMake(0, 44, 80, 60)
        v.backgroundColor = .blackColor()
        v.textColor = .whiteColor()
        v.numberOfLines = 2
        v.textAlignment = .Center
        v.userInteractionEnabled = true
        
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(SMFpsMonitor.handlePan(_:)))
        v.addGestureRecognizer(panGes)
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(SMFpsMonitor.handleTap(_:)))
        v.addGestureRecognizer(tapGes)
        return v
    }()
    
    private var displayLink: CADisplayLink!
    
    public func run() {
        UIApplication.sharedApplication().keyWindow?.addSubview(lb)
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(SMFpsMonitor.calculator))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    public func shutDown() {
        lb.removeFromSuperview()
        displayLink?.invalidate()
    }
    
    private var befor: CFAbsoluteTime = 0
    private var frames: Int = 0
    private var avgFps: Double = 60
    private var avgArr: [Double] = []
    
    @objc private func calculator() {
        let current = CFAbsoluteTimeGetCurrent()
        let differ = current - befor
        if differ > 0.5 {
            let fps = Double(frames) / differ
            avgFps = avgFps * 0.382 + fps * 0.618
            lb.text = "FPS: " + "\(fps.format("%2.0lf"))" + "\nAvg: " + "\(avgFps.format("%2.0lf"))"
            avgArr.append(avgFps)
            befor = current
            frames = 0
        }
        else {
            frames += 1
        }
    }
    
    private var fpsV = SMFpsV()
    
    @objc private func handlePan(ges: UIPanGestureRecognizer) {
        let tran = ges.translationInView(lb.superview)
        print(tran)
        lb.center = CGPoint(x: lb.center.x + tran.x, y: lb.center.y + tran.y)
        ges.setTranslation(CGPointZero, inView: lb.superview)
    }
    
    @objc private func handleTap(ges: UITapGestureRecognizer) {
        fpsV.drawWith(avgArr)
        avgArr.removeAll()
    }
}

private class SMFpsV: UIControl {
    override init(frame: CGRect) {
        super.init(frame: UIScreen.mainScreen().bounds)

        addSubview(backgroundV)
        backgroundV.layer.addSublayer(shapeLy)
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activateConstraints(
                [backgroundV.leftAnchor.constraintEqualToAnchor(leftAnchor),
                backgroundV.rightAnchor.constraintEqualToAnchor(rightAnchor),
                backgroundV.centerYAnchor.constraintEqualToAnchor(centerYAnchor),
                backgroundV.heightAnchor.constraintEqualToAnchor(backgroundV.widthAnchor, multiplier:scale)])
        
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        addTarget(self, action: #selector(UIView.removeFromSuperview), forControlEvents: .TouchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var shapeLy: CAShapeLayer = {
        let ly = CAShapeLayer()
        ly.fillColor = UIColor.clearColor().CGColor
        ly.strokeColor = UIColor.redColor().CGColor
        ly.lineWidth = 3
        return ly
    }()
    
    lazy var backgroundV: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.8)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.userInteractionEnabled = false
        return v
    }()
    
    let scale: CGFloat = 0.56
    var width: CGFloat {
        if backgroundV.bounds.size.width.isZero {
            return bounds.size.width
        }
        return backgroundV.bounds.size.width }
    var height: CGFloat { return width * scale }
    
    func drawWith(data: [Double]) {
        UIApplication.sharedApplication().keyWindow?.addSubview(self)
        UIGraphicsBeginImageContext(frame.size)
        
        let path = UIBezierPath()
        let count = data.count - 1
        for (index, x) in CGFloat(1).stride(to: width, by: width/CGFloat(count)).enumerate() {
            let y = height - CGFloat(data[Int(index)]) * height / 60
            let pt = CGPoint(x: x, y: y)
            index == 0 ? path.moveToPoint(pt):path.addLineToPoint(pt)
        }
        
        shapeLy.path = path.CGPath
        
        UIGraphicsEndImageContext()
        
        let am = CABasicAnimation(keyPath: "strokeEnd")
        am.fromValue = 0
        am.toValue = 1
        am.duration = 2
        am.removedOnCompletion = true
        shapeLy.addAnimation(am, forKey: "show")
        
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superV = superview else { return }
        NSLayoutConstraint.activateConstraints(
            [leftAnchor.constraintEqualToAnchor(superV.leftAnchor),
            rightAnchor.constraintEqualToAnchor(superV.rightAnchor),
            topAnchor.constraintEqualToAnchor(superV.topAnchor),
            bottomAnchor.constraintEqualToAnchor(superV.bottomAnchor)])
    }
}

private extension FloatingPointType where Self: CVarArgType {
    func format(f: String) -> String { return String(format: f, self) }
}

