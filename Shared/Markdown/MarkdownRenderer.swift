//
//  MarkdownRenderer.swift
//  ColourNoteProj
//
//  Created for Markdown support
//  Copyright © 2026 Paul Williams. All rights reserved.
//

import UIKit

class MarkdownRenderer {
    static let shared = MarkdownRenderer()

    // Default fonts
    private let bodyFont = UIFont(name: "BaiJamjuree-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
    private let boldFont = UIFont(name: "BaiJamjuree-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
    private let italicFont = UIFont(name: "BaiJamjuree-Italic", size: 16) ?? UIFont.italicSystemFont(ofSize: 16)
    private let codeFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    private init() {}

    /// Renders Markdown string to styled NSAttributedString
    /// - Parameters:
    ///   - markdown: The Markdown text to render
    ///   - categoryColor: Optional category color for theming
    /// - Returns: NSAttributedString with Markdown formatting
    func render(markdown: String, categoryColor: UIColor? = nil) -> NSAttributedString? {
        let attributedString = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")

        var inCodeBlock = false
        var codeBlockContent = ""

        for (index, line) in lines.enumerated() {
            // Handle code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    let codeAttr = formatCodeBlock(codeBlockContent)
                    attributedString.append(codeAttr)
                    codeBlockContent = ""
                    inCodeBlock = false
                } else {
                    // Start code block
                    inCodeBlock = true
                }
                continue
            }

            if inCodeBlock {
                codeBlockContent += (codeBlockContent.isEmpty ? "" : "\n") + line
                continue
            }

            // Process non-code-block line
            let processedLine = processLine(line)
            attributedString.append(processedLine)

            // Add newline if not the last line
            if index < lines.count - 1 {
                attributedString.append(NSAttributedString(string: "\n"))
            }
        }

        // Apply category-specific styling if provided
        if let color = categoryColor {
            return styleForCategory(attributedString, color: color)
        }

        return attributedString
    }

    /// Process a single line of markdown
    private func processLine(_ line: String) -> NSAttributedString {
        // Check for headers
        if let headerResult = processHeader(line) {
            return headerResult
        }

        // Check for blockquote
        if line.hasPrefix(">") {
            return processBlockquote(line)
        }

        // Check for list items
        if let listResult = processList(line) {
            return listResult
        }

        // Check for horizontal rule
        if line.trimmingCharacters(in: .whitespaces) == "---" ||
           line.trimmingCharacters(in: .whitespaces) == "***" ||
           line.trimmingCharacters(in: .whitespaces) == "___" {
            return processHorizontalRule()
        }

        // Process inline formatting
        return processInlineFormatting(line)
    }

    /// Process header lines (# ## ### etc)
    private func processHeader(_ line: String) -> NSAttributedString? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Count leading hashes
        var hashCount = 0
        for char in trimmed {
            if char == "#" {
                hashCount += 1
            } else {
                break
            }
        }

        guard hashCount > 0 && hashCount <= 6 else { return nil }

        // Get the text after the hashes
        let headerText = String(trimmed.dropFirst(hashCount)).trimmingCharacters(in: .whitespaces)

        // Calculate font size based on header level
        let fontSize: CGFloat = {
            switch hashCount {
            case 1: return 28
            case 2: return 24
            case 3: return 20
            case 4: return 18
            case 5: return 16
            default: return 14
            }
        }()

        let headerFont = UIFont(name: "BaiJamjuree-Bold", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.label
        ]

        return NSAttributedString(string: headerText, attributes: attributes)
    }

    /// Process blockquote lines (> text)
    private func processBlockquote(_ line: String) -> NSAttributedString {
        let text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 20

        let attributes: [NSAttributedString.Key: Any] = [
            .font: italicFont,
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraphStyle,
            .backgroundColor: UIColor.systemGray6
        ]

        return NSAttributedString(string: "│ " + text, attributes: attributes)
    }

    /// Process list items (- * 1.)
    private func processList(_ line: String) -> NSAttributedString? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Unordered list
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            let text = String(trimmed.dropFirst(2))
            let bulletText = "• " + text
            return processInlineFormatting(bulletText)
        }

        // Ordered list (1. 2. etc)
        let pattern = "^(\\d+)\\. (.+)$"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
            if let numberRange = Range(match.range(at: 1), in: trimmed),
               let textRange = Range(match.range(at: 2), in: trimmed) {
                let number = trimmed[numberRange]
                let text = String(trimmed[textRange])
                let listText = "\(number). " + text
                return processInlineFormatting(listText)
            }
        }

        return nil
    }

    /// Process horizontal rule
    private func processHorizontalRule() -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: 280, height: 1)

        // Create a simple line
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 280, height: 1))
        attachment.image = renderer.image { context in
            UIColor.separator.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 280, height: 1))
        }

        return NSAttributedString(attachment: attachment)
    }

    /// Process inline formatting (bold, italic, code, links)
    private func processInlineFormatting(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: [
            .font: bodyFont,
            .foregroundColor: UIColor.label
        ])

        // Process inline code first (to prevent interference with other formatting)
        processInlineCode(in: result)

        // Process bold (**text** or __text__)
        processBold(in: result)

        // Process italic (*text* or _text_)
        processItalic(in: result)

        // Process links [text](url)
        processLinks(in: result)

        return result
    }

    /// Process inline code (`code`)
    private func processInlineCode(in attributedString: NSMutableAttributedString) {
        let pattern = "`([^`]+)`"
        processPattern(pattern, in: attributedString) { range, _ in
            attributedString.addAttributes([
                .font: self.codeFont,
                .backgroundColor: UIColor.systemGray5,
                .foregroundColor: UIColor.systemRed
            ], range: range)
        }

        // Remove the backticks
        var text = attributedString.string
        while let range = text.range(of: "`") {
            let nsRange = NSRange(range, in: text)
            attributedString.replaceCharacters(in: nsRange, with: "")
            text = attributedString.string
        }
    }

    /// Process bold (**text**)
    private func processBold(in attributedString: NSMutableAttributedString) {
        // Match **text** or __text__
        let patterns = ["\\*\\*([^*]+)\\*\\*", "__([^_]+)__"]

        for pattern in patterns {
            processPattern(pattern, in: attributedString) { range, _ in
                attributedString.addAttribute(.font, value: self.boldFont, range: range)
            }
        }

        // Remove the markers
        removeMarkers(["**", "__"], from: attributedString)
    }

    /// Process italic (*text* or _text_)
    private func processItalic(in attributedString: NSMutableAttributedString) {
        // Match *text* or _text_ (but not ** or __)
        let patterns = ["(?<!\\*)\\*(?!\\*)([^*]+)(?<!\\*)\\*(?!\\*)", "(?<!_)_(?!_)([^_]+)(?<!_)_(?!_)"]

        for pattern in patterns {
            processPattern(pattern, in: attributedString) { range, _ in
                attributedString.addAttribute(.font, value: self.italicFont, range: range)
            }
        }

        // Remove single markers (careful not to remove double markers)
        var text = attributedString.string
        // Simple approach: just mark positions and remove
        let singleStarPattern = "(?<!\\*)\\*(?!\\*)"
        if let regex = try? NSRegularExpression(pattern: singleStarPattern) {
            var offset = 0
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                let adjustedRange = NSRange(location: match.range.location - offset, length: match.range.length)
                attributedString.replaceCharacters(in: adjustedRange, with: "")
                offset += match.range.length
            }
        }

        text = attributedString.string
        let singleUnderscorePattern = "(?<!_)_(?!_)"
        if let regex = try? NSRegularExpression(pattern: singleUnderscorePattern) {
            var offset = 0
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                let adjustedRange = NSRange(location: match.range.location - offset, length: match.range.length)
                attributedString.replaceCharacters(in: adjustedRange, with: "")
                offset += match.range.length
            }
        }
    }

    /// Process links [text](url)
    private func processLinks(in attributedString: NSMutableAttributedString) {
        let pattern = "\\[([^\\]]+)\\]\\(([^)]+)\\)"

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let text = attributedString.string
        var offset = 0

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }

            let fullRange = NSRange(location: match.range.location - offset, length: match.range.length)

            if let textRange = Range(match.range(at: 1), in: text),
               let urlRange = Range(match.range(at: 2), in: text) {
                let linkText = String(text[textRange])
                let urlString = String(text[urlRange])

                // Replace the markdown link with just the text
                let linkAttributed = NSMutableAttributedString(string: linkText)

                if let url = URL(string: urlString) {
                    linkAttributed.addAttributes([
                        .link: url,
                        .foregroundColor: UIColor.systemBlue,
                        .underlineStyle: NSUnderlineStyle.single.rawValue
                    ], range: NSRange(location: 0, length: linkText.count))
                }

                attributedString.replaceCharacters(in: fullRange, with: linkAttributed)
                offset += match.range.length - linkText.count
            }
        }
    }

    /// Helper to process regex patterns
    private func processPattern(_ pattern: String, in attributedString: NSMutableAttributedString, handler: (NSRange, NSTextCheckingResult) -> Void) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let text = attributedString.string
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches {
            handler(match.range, match)
        }
    }

    /// Helper to remove formatting markers
    private func removeMarkers(_ markers: [String], from attributedString: NSMutableAttributedString) {
        for marker in markers {
            var text = attributedString.string
            while let range = text.range(of: marker) {
                let nsRange = NSRange(range, in: text)
                attributedString.replaceCharacters(in: nsRange, with: "")
                text = attributedString.string
            }
        }
    }

    /// Format code block
    private func formatCodeBlock(_ code: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 10
        paragraphStyle.firstLineHeadIndent = 10
        paragraphStyle.tailIndent = -10

        let attributes: [NSAttributedString.Key: Any] = [
            .font: codeFont,
            .foregroundColor: UIColor.label,
            .backgroundColor: UIColor.systemGray6,
            .paragraphStyle: paragraphStyle
        ]

        return NSAttributedString(string: code + "\n", attributes: attributes)
    }

    /// Applies category color theme to rendered Markdown
    private func styleForCategory(_ attributedString: NSAttributedString, color: UIColor) -> NSMutableAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let range = NSRange(location: 0, length: mutableString.length)

        // Set text color based on background luminance
        let textColor = getContrastingTextColor(for: color)

        // Only apply text color to ranges that don't have special colors (like links)
        mutableString.enumerateAttribute(.foregroundColor, in: range, options: []) { (value, attrRange, stop) in
            if let existingColor = value as? UIColor {
                // Don't change link colors or special colors
                if existingColor != UIColor.systemBlue && existingColor != UIColor.systemRed {
                    mutableString.addAttribute(.foregroundColor, value: textColor, range: attrRange)
                }
            } else {
                mutableString.addAttribute(.foregroundColor, value: textColor, range: attrRange)
            }
        }

        return mutableString
    }

    /// Determines contrasting text color based on background luminance
    private func getContrastingTextColor(for backgroundColor: UIColor) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Calculate luminance using standard formula
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue

        // Return black for light backgrounds, white for dark backgrounds
        return luminance > 0.5 ? .black : .white
    }
}
