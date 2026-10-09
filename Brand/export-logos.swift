import AppKit
import CoreText
import Foundation
let root = URL(fileURLWithPath:CommandLine.arguments[1])
try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
let font = CTFontCreateWithName("Arial-Black" as CFString,180,nil)
let word = CGMutablePath()
var x:CGFloat=253
for ch in "rewind".utf16 {
 var u=ch;var g:CGGlyph=0
 CTFontGetGlyphsForCharacters(font,&u,&g,1)
 var advance=CGSize.zero;CTFontGetAdvancesForGlyphs(font,.horizontal,&g,&advance,1)
 if let glyph=CTFontCreatePathForGlyph(font,g,nil) {var t=CGAffineTransform(a:1,b:0,c:0,d:-1,tx:x,ty:176);word.addPath(glyph,transform:t)}
 x += advance.width - 10.8
}
let W=ceil(word.boundingBoxOfPath.maxX+8),H:CGFloat=210
let mark=CGMutablePath()
for off:CGFloat in [0,86] {
 let shape=CGMutablePath();shape.move(to:CGPoint(x:70,y:8));shape.addQuadCurve(to:CGPoint(x:82,y:15),control:CGPoint(x:82,y:0));shape.addLine(to:CGPoint(x:82,y:85));shape.addQuadCurve(to:CGPoint(x:70,y:92),control:CGPoint(x:82,y:100));shape.addLine(to:CGPoint(x:10,y:57));shape.addQuadCurve(to:CGPoint(x:10,y:43),control:CGPoint(x:-2,y:50));shape.closeSubpath()
 mark.addPath(shape,transform:CGAffineTransform(a:1.17,b:0,c:0,d:1.17,tx:off*1.17,ty:45))
}
func svgPath(_ p:CGPath)->String {var s="";func v(_ p:CGPoint)->String {String(format:"%.3f %.3f",Double(p.x),Double(p.y))};p.applyWithBlock{e in let q=e.pointee;switch q.type {case .moveToPoint:s += "M"+v(q.points[0]);case .addLineToPoint:s += "L"+v(q.points[0]);case .addQuadCurveToPoint:s += "Q"+v(q.points[0])+" "+v(q.points[1]);case .addCurveToPoint:s += "C"+v(q.points[0])+" "+v(q.points[1])+" "+v(q.points[2]);case .closeSubpath:s += "Z";@unknown default:break}};return s}
func color(_ hex:String)->CGColor {let n=UInt32(hex.dropFirst(),radix:16)!;return CGColor(red:CGFloat((n>>16)&255)/255,green:CGFloat((n>>8)&255)/255,blue:CGFloat(n&255)/255,alpha:1)}
for (name,ink,mint,icon) in [("rewind-logo-primary","#151716","#3ECF8E",false),("rewind-logo-reverse","#F6F3ED","#3ECF8E",false),("rewind-logo-ink","#151716","#151716",false),("rewind-logo-white","#FFFFFF","#FFFFFF",false),("rewind-mark-mint","#3ECF8E","#3ECF8E",true)] {
 let width=icon ? 210 : W
 let svg="<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(width) \(H)\" role=\"img\" aria-label=\"rewind\"><path fill=\"\(mint)\" d=\"\(svgPath(mark))\"/>"+(icon ? "" : "<path fill=\"\(ink)\" d=\"\(svgPath(word))\"/>")+"</svg>\n"
 try svg.write(to:root.appendingPathComponent(name+".svg"),atomically:true,encoding:.utf8)
 let px=icon ? 1024 : 3200;let scale=CGFloat(px)/width;let py=Int(ceil(H*scale))
 let context=CGContext(data:nil,width:px,height:py,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 context.translateBy(x:0,y:CGFloat(py));context.scaleBy(x:scale,y:-scale);context.setFillColor(color(mint));context.addPath(mark);context.fillPath();if !icon{context.setFillColor(color(ink));context.addPath(word);context.fillPath()}
 let png=NSBitmapImageRep(cgImage:context.makeImage()!).representation(using:.png,properties:[:])!
 try png.write(to:root.appendingPathComponent(name+".png"))
}
print("Exported 5 outlined SVG logos and 5 transparent PNGs.")
