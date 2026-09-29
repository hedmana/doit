// Renders the app icon into an .iconset directory: swift AppIcon.swift <out.iconset>
import AppKit

let canvas: CGFloat = 1024
let out = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

// Shadows ignore the CTM, so their offset and blur take the pixel scale by hand
func draw(in ctx: CGContext, scale: CGFloat) {
    // macOS icon grid: 824pt body centred on a 1024pt canvas, the margin holds the shadow
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * scale), blur: 28 * scale, color: CGColor(gray: 0, alpha: 0.35))
    ctx.addPath(shape)
    ctx.setFillColor(CGColor(srgbRed: 0.12, green: 0.37, blue: 0.85, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [
        CGColor(srgbRed: 0.33, green: 0.62, blue: 1.0, alpha: 1),
        CGColor(srgbRed: 0.12, green: 0.37, blue: 0.85, alpha: 1),
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: body.maxY), end: CGPoint(x: 512, y: body.minY), options: [])
    ctx.restoreGState()

    let disc = CGRect(x: 512 - 250, y: 512 - 250, width: 500, height: 500)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8 * scale), blur: 20 * scale, color: CGColor(gray: 0, alpha: 0.25))
    ctx.setFillColor(.white)
    ctx.fillEllipse(in: disc)
    ctx.restoreGState()

    ctx.setStrokeColor(CGColor(srgbRed: 0.14, green: 0.42, blue: 0.92, alpha: 1))
    ctx.setLineWidth(64)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: 400, y: 520))
    ctx.addLine(to: CGPoint(x: 480, y: 435))
    ctx.addLine(to: CGPoint(x: 640, y: 610))
    ctx.strokePath()
}

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let factor = CGFloat(pixels) / canvas
        ctx.scaleBy(x: factor, y: factor)
        draw(in: ctx, scale: factor)
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
        try rep.representation(using: .png, properties: [:])!.write(to: out.appending(path: name))
    }
}
