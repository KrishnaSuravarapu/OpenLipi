import AppKit

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
let size = NSSize(width: 22, height: 22)
let font = NSFont.systemFont(ofSize: 17, weight: .regular)
let glyph = "ఱ"

func drawIcon(dotColor: NSColor, glyphColor: NSColor, fileName: String) {
    let image = NSImage(size: size)
    image.lockFocus()

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: glyphColor
    ]

    let textSize = (glyph as NSString).size(withAttributes: attributes)
    let textX = (size.width - textSize.width) / 2.0
    let textY = (size.height - textSize.height) / 2.0 + 1.0
    (glyph as NSString).draw(at: NSPoint(x: textX, y: textY), withAttributes: attributes)

    let dotSize: CGFloat = 5.5
    let dotX = size.width - dotSize - 1.0
    let dotY = 1.0
    dotColor.setFill()
    NSBezierPath(ovalIn: NSRect(x: dotX, y: dotY, width: dotSize, height: dotSize)).fill()

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        return
    }

    let url = URL(fileURLWithPath: outputDir).appendingPathComponent(fileName)
    try? png.write(to: url)
}

drawIcon(dotColor: .systemGreen, glyphColor: .black, fileName: "icon_on_light.png")
drawIcon(dotColor: .systemGray, glyphColor: .black, fileName: "icon_off_light.png")
drawIcon(dotColor: .systemGreen, glyphColor: .white, fileName: "icon_on_dark.png")
drawIcon(dotColor: .systemGray, glyphColor: .white, fileName: "icon_off_dark.png")
