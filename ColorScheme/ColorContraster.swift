//
//  ColorConstraster.swift
//  ColorScheme
//
//  Created by Richard Fox on 8/13/15.
//  Copyright (c) 2015 Assorted Intelligence. All rights reserved.
//

import Foundation
import Cocoa

extension CGFloat{
    var d:Double{
        get{
            return Double(self)
        }
    }
}

extension NSColor {
    
    func colorMatch()->NSColor?{
        let c   = colorComponents()
        let color = luminanace(c[0], g: c[1], b: c[2])
        let blk = luminanace(0.0, g: 0.0, b: 0.0)
        let wht = luminanace(1.0, g: 1.0, b: 1.0)
        
        let blkC = color/blk
        let whtC = wht/color
        
        print("blk = \(blkC), whtC = \(whtC)")
        
        if blkC > whtC{
            return NSColor.black
        }else{
            return NSColor.white
        }
    }

    func luminanace(_ r:Double, g:Double, b:Double) -> Double {
        let colors:[Double] = [r,g,b]
        let a = colors.map { (v:Double) -> Double in
            
            return  (v <= 0.03928) ?
                (v / 12.92) :
                (pow( ((v+0.055)/1.055), 2.4));
        }
        return (a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722) + 0.05;
    }
    
    
    func colorComponents() -> [Double]{
        
        let c = self.usingColorSpace(.genericRGB)
        if c == nil{
            assert(false, "colorspace converts to nil")
        }
        let fRed   : CGFloat  = c!.redComponent
        let fGreen : CGFloat  = c!.greenComponent
        let fBlue  : CGFloat  = c!.blueComponent
        
        return [fRed.d,fGreen.d,fBlue.d]
    }

}

