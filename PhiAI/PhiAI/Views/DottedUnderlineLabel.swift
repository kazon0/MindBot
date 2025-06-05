//
//  DottedUnderlineLabel.swift
//  PhiAI
//

import SwiftUI
import UIKit

extension String {
    func insertLineBreaks(every n: Int) -> String {
        var result = ""
        for (index, char) in self.enumerated() {
            result.append(char)
            if (index + 1) % n == 0 {
                result.append("\n")
            }
        }
        return result
    }
}

class DottedUnderlineLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect)
        
        guard let ctx = UIGraphicsGetCurrentContext(),
              let text = self.text,
              let font = self.font else { return }
        
        let attrString = NSAttributedString(string: text, attributes: [
            .font: font
        ])
        
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let path = CGMutablePath()
        path.addRect(rect)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var origins = Array(repeating: CGPoint.zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)

        ctx.setLineWidth(1)
        ctx.setStrokeColor(UIColor.gray.cgColor)
        ctx.setLineDash(phase: 0, lengths: [4, 4])
        
        for i in 0..<lines.count {
            let origin = origins[i]
            let underlineOffset: CGFloat = 5
            let y = rect.height - origin.y + underlineOffset
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: rect.width, y: y))
            ctx.strokePath()
        }
    }
}

struct DottedUnderlineText: UIViewRepresentable {
    var text: String
    var font: UIFont

    func makeUIView(context: Context) -> DottedUnderlineLabel {
        let label = DottedUnderlineLabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .black
        label.font = font
        return label
    }

    func updateUIView(_ uiView: DottedUnderlineLabel, context: Context) {
        uiView.text = text
    }
}
