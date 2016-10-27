//
//  DynamicBlurView.swift
//  DynamicBlurView
//
//  Created by Kyohei Ito on 2015/04/08.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import Accelerate

public class DynamicBlurView: UIView {
    private class BlurLayer: CALayer {
        @NSManaged var blurRadius: CGFloat
        
        override class func needsDisplay(forKey key: String) -> Bool {
            if key == "blurRadius" {
                return true
            }
            return super.needsDisplay(forKey: key)
        }
    }
    
    public enum DynamicMode {
        case Tracking   // refresh only scrolling
        case Common     // always refresh
        case None       // not refresh
        
        func mode() -> String {
            switch self {
            case .Tracking:
                return RunLoopMode.UITrackingRunLoopMode.rawValue
            case .Common:
                return RunLoopMode.commonModes.rawValue
            case .None:
                return ""
            }
        }
    }
    
    private var staticImage: UIImage?
    private var fromBlurRadius: CGFloat?
    private var displayLink: CADisplayLink?
    private let DisplayLinkSelector: Selector = "displayDidRefresh:"
    private var blurLayer: BlurLayer {
        return layer as! BlurLayer
    }
    
    private var blurPresentationLayer: BlurLayer {
        if let layer = blurLayer.presentation(){
            return layer
        }
        
        return blurLayer
    }
    
    public var blurRadius: CGFloat {
        set { blurLayer.blurRadius = newValue }
        get { return blurLayer.blurRadius }
    }
    
    /// Default is Tracking.
    public var dynamicMode: DynamicMode = .None {
        didSet {
            if dynamicMode != oldValue {
                linkForDisplay()
            }
        }
    }
    
    /// Blend color.
    public var blendColor: UIColor?
    
    /// Default is 3.
    public var iterations: Int = 3
    
    /// Please be on true if the if Layer is not captured. Such as UINavigationBar and UIToolbar. Can be used only with DynamicMode.None.
    public var fullScreenCapture: Bool = false
    
    /// Ratio of radius. Defauot is 1.
    public var blurRatio: CGFloat = 1 {
        didSet {
            if oldValue != blurRatio {
                if let image = staticImage {
                    setCaptureImage(image: image, radius: blurRadius)
                }
            }
        }
    }
    
    public override class var layerClass: AnyClass {
        return BlurLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        isUserInteractionEnabled = false
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview == nil {
            displayLink?.invalidate()
            displayLink = nil
        } else {
            linkForDisplay()
        }
    }
    
    public override func action(for: CALayer, forKey event: String) -> CAAction? {
        if event == "blurRadius" {
            fromBlurRadius = nil
            
            if dynamicMode == .None {
                staticImage = capturedImage()
            } else {
                staticImage = nil
            }
            
            if let action = super.action(for: layer, forKey: "backgroundColor") as? CAAnimation {
                fromBlurRadius = blurPresentationLayer.blurRadius
                
                let animation = CABasicAnimation()
                animation.fromValue = fromBlurRadius
                animation.beginTime = CACurrentMediaTime() + action.beginTime
                animation.duration = action.duration
                animation.speed = action.speed
                animation.timeOffset = action.timeOffset
                animation.repeatCount = action.repeatCount
                animation.repeatDuration = action.repeatDuration
                animation.autoreverses = action.autoreverses
                animation.fillMode = action.fillMode
                
                //CAAnimation attributes
                animation.timingFunction = action.timingFunction
                animation.delegate = action.delegate
                
                return animation
            }
        }
        
        return super.action(for: layer, forKey: event)
    }
    
    public override func display(_ layer: CALayer) {
        let blurRadius: CGFloat
        
        if let radius = fromBlurRadius {
            if layer.presentation() == nil {
                blurRadius = radius
            } else {
                blurRadius = blurPresentationLayer.blurRadius
            }
        } else {
            blurRadius = blurLayer.blurRadius
        }
        
        DispatchQueue.global().async {
            if let capture = self.staticImage ?? self.capturedImage() {
                self.setCaptureImage(image: capture, radius: blurRadius)
            }
        }
    }
    
    /// Get blur image again. for DynamicMode.None
    public func refresh() {
        staticImage = nil
        fromBlurRadius = nil
        blurRatio = 1
        display(blurLayer)
    }
    
    /// Delete blur image. for DynamicMode.None
    public func remove() {
        staticImage = nil
        fromBlurRadius = nil
        blurRatio = 1
        layer.contents = nil
    }
    
    private func linkForDisplay() {
        displayLink?.invalidate()
        displayLink = UIScreen.main.displayLink(withTarget: self, selector: DisplayLinkSelector)
        displayLink?.add(to: RunLoop.main, forMode: RunLoopMode(rawValue: dynamicMode.mode()))
    }
    
    private func setCaptureImage(image: UIImage, radius: CGFloat) {
        let setImage: (() -> Void) = {
            if let blurredImage = image.blurredImage(radius: radius, iterations: self.iterations, ratio: self.blurRatio, blendColor: self.blendColor) {
                DispatchQueue.main.sync() {
                    self.setContentImage(image: blurredImage)
                }
            }
        }
        
        if Thread.current.isMainThread {
            DispatchQueue.global().async(execute: setImage)
        } else {
            setImage()
        }
    }
    
    private func setContentImage(image: UIImage) {
        layer.contents = image.cgImage
        layer.contentsScale = image.scale
    }
    
    private func prepareLayer() -> [CALayer]? {
        let sublayers = superview?.layer.sublayers as [CALayer]?
        
        return sublayers?.reduce([], { acc, layer -> [CALayer] in
            if acc.isEmpty {
                if layer != self.blurLayer {
                    return acc
                }
            }
            
            if layer.isHidden == false {
                layer.isHidden = true
                
                return acc + [layer]
            }
            
            return acc
        })
    }
    
    private func restoreLayer(layers: [CALayer]) {
        _ = layers.map { $0.isHidden = false }
    }
    
    private func capturedImage() -> UIImage! {
        let bounds = blurLayer.convert(blurLayer.bounds, to: superview?.layer)
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 1)
        let context = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = .none
        context!.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
        
        if Thread.current.isMainThread {
            renderInContext(ctx: context)
        } else {
            DispatchQueue.main.sync() {
                self.renderInContext(ctx: context)
            }
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func renderInContext(ctx: CGContext!) {
        let layers = prepareLayer()
        
        if fullScreenCapture && dynamicMode == .None {
            if let superview = superview {
                UIView.setAnimationsEnabled(false)
                superview.drawHierarchy(in: superview.bounds, afterScreenUpdates: true)
                UIView.setAnimationsEnabled(true)
            }
        } else {
            superview?.layer.render(in: ctx)
        }
        
        if let layers = layers {
            restoreLayer(layers: layers)
        }
    }
    
    func displayDidRefresh(displayLink: CADisplayLink) {
        display(blurLayer)
    }
}

public extension UIImage {
    func blurredImage(radius: CGFloat, iterations: Int, ratio: CGFloat, blendColor: UIColor?) -> UIImage! {
        if floorf(Float(size.width)) * floorf(Float(size.height)) <= 0.0 {
            return self
        }
        
        guard let imageRef = self.cgImage else { return self }
        var boxSize = UInt32(radius * scale * ratio)
        if boxSize % 2 == 0 {
            boxSize += 1
        }
        
        let height = imageRef.height
        let width = imageRef.width
        let rowBytes = imageRef.bytesPerRow
        let bytes = rowBytes * height
        
        let inData = malloc(bytes)
        var inBuffer = vImage_Buffer(data: inData, height: UInt(height), width: UInt(width), rowBytes: rowBytes)
        
        let outData = malloc(bytes)
        var outBuffer = vImage_Buffer(data: outData, height: UInt(height), width: UInt(width), rowBytes: rowBytes)
        
        let tempFlags = vImage_Flags(kvImageEdgeExtend + kvImageGetTempBufferSize)
        let tempSize = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, boxSize, boxSize, nil, tempFlags)
        let tempBuffer = malloc(tempSize)
        
        guard let provider = imageRef.dataProvider else { return self }
        let copy = provider.data
        let source = CFDataGetBytePtr(copy)
        memcpy(inBuffer.data, source, bytes)
        
        let flags = vImage_Flags(kvImageEdgeExtend)
        for _ in 0 ..< iterations {
            vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, tempBuffer, 0, 0, boxSize, boxSize, nil, flags)
            
            let temp = inBuffer.data
            inBuffer.data = outBuffer.data
            outBuffer.data = temp
        }
        
        free(outBuffer.data)
        free(tempBuffer)
        
        guard let colorSpace = imageRef.colorSpace else { return self }
        let bitmapInfo = imageRef.bitmapInfo
        guard let bitmapContext = CGContext(data: inBuffer.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return self }
        
        if let color = blendColor {
            bitmapContext.setFillColor(color.cgColor)
            bitmapContext.setBlendMode(.plusLighter)
            bitmapContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        let bitmap = bitmapContext.makeImage()
        let image = UIImage(cgImage: bitmap!, scale: scale, orientation: imageOrientation)
        free(inBuffer.data)
        
        return image
    }
}
