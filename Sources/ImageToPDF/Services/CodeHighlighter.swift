import Foundation
import AppKit

public struct CodeLanguage {
    public let name: String
    public let keywords: Set<String>
    public let lineCommentPrefix: String?
    public let blockCommentStart: String?
    public let blockCommentEnd: String?
    public let types: Set<String>

    public static func forExtension(_ ext: String) -> CodeLanguage {
        let e = ext.lowercased()
        switch e {
        case "py":
            return CodeLanguage(
                name: "Python",
                keywords: ["def", "class", "import", "from", "return", "if", "elif", "else", "while", "for", "in", "try", "except", "finally", "with", "as", "lambda", "yield", "pass", "break", "continue", "global", "nonlocal", "async", "await", "raise", "assert", "del", "True", "False", "None", "self"],
                lineCommentPrefix: "#",
                blockCommentStart: "\"\"\"",
                blockCommentEnd: "\"\"\"",
                types: ["int", "float", "str", "list", "dict", "set", "tuple", "bool", "bytes", "object"]
            )
        case "cpp", "cc", "cxx", "hpp", "h":
            return CodeLanguage(
                name: "C++",
                keywords: ["alignas", "alignof", "and", "auto", "bool", "break", "case", "catch", "char", "class", "concept", "const", "constexpr", "continue", "decltype", "default", "delete", "do", "double", "dynamic_cast", "else", "enum", "explicit", "export", "extern", "false", "float", "for", "friend", "goto", "if", "inline", "int", "long", "mutable", "namespace", "new", "noexcept", "nullptr", "operator", "override", "private", "protected", "public", "reinterpret_cast", "return", "short", "signed", "sizeof", "static", "static_assert", "static_cast", "struct", "switch", "template", "this", "throw", "true", "try", "typedef", "typeid", "typename", "union", "unsigned", "using", "virtual", "void", "volatile", "while"],
                lineCommentPrefix: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                types: ["std", "string", "vector", "map", "unordered_map", "set", "pair", "tuple", "unique_ptr", "shared_ptr", "size_t", "int32_t", "int64_t", "uint32_t", "uint64_t", "uint8_t"]
            )
        case "c":
            return CodeLanguage(
                name: "C",
                keywords: ["auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum", "extern", "float", "for", "goto", "if", "int", "long", "register", "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while"],
                lineCommentPrefix: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                types: ["size_t", "uint8_t", "uint16_t", "uint32_t", "uint64_t", "int8_t", "int16_t", "int32_t", "int64_t", "FILE"]
            )
        case "swift":
            return CodeLanguage(
                name: "Swift",
                keywords: ["associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout", "internal", "let", "open", "operator", "private", "precedencegroup", "protocol", "public", "rethrows", "static", "struct", "subscript", "typealias", "var", "break", "case", "catch", "continue", "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw", "switch", "where", "while", "as", "any", "false", "is", "nil", "self", "Self", "super", "true", "try", "throws", "async", "await", "some", "consuming", "borrowing"],
                lineCommentPrefix: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                types: ["Int", "Double", "Float", "String", "Bool", "Character", "Array", "Dictionary", "Set", "Optional", "View", "UUID", "URL", "Data", "CGSize", "CGRect", "CGFloat"]
            )
        case "js", "jsx", "ts", "tsx":
            return CodeLanguage(
                name: e.hasPrefix("t") ? "TypeScript" : "JavaScript",
                keywords: ["async", "await", "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete", "do", "else", "enum", "export", "extends", "false", "finally", "for", "function", "if", "implements", "import", "in", "instanceof", "interface", "let", "new", "null", "package", "private", "protected", "public", "return", "super", "switch", "this", "throw", "true", "try", "typeof", "var", "void", "while", "with", "yield", "type", "from", "as", "readonly"],
                lineCommentPrefix: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                types: ["string", "number", "boolean", "any", "void", "Promise", "Array", "Record", "Object"]
            )
        case "rs":
            return CodeLanguage(
                name: "Rust",
                keywords: ["as", "async", "await", "break", "const", "continue", "crate", "dyn", "else", "enum", "extern", "false", "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "return", "self", "Self", "static", "struct", "super", "trait", "true", "type", "unsafe", "use", "where", "while"],
                lineCommentPrefix: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                types: ["i32", "i64", "u32", "u64", "f32", "f64", "usize", "isize", "bool", "char", "str", "String", "Vec", "Option", "Result"]
            )
        case "go":
            return CodeLanguage(
                name: "Go",
                keywords: ["break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough", "for", "func", "go", "goto", "if", "import", "interface", "map", "package", "range", "return", "select", "struct", "switch", "type", "var", "true", "false", "nil"],
                lineCommentPrefix: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                types: ["string", "int", "int64", "float64", "bool", "byte", "rune", "error"]
            )
        case "sh", "bash", "zsh":
            return CodeLanguage(
                name: "Shell",
                keywords: ["if", "then", "else", "elif", "fi", "case", "esac", "for", "while", "until", "do", "done", "in", "function", "select", "time", "return", "exit", "echo", "local", "export"],
                lineCommentPrefix: "#",
                blockCommentStart: nil,
                blockCommentEnd: nil,
                types: []
            )
        case "json":
            return CodeLanguage(
                name: "JSON",
                keywords: ["true", "false", "null"],
                lineCommentPrefix: nil,
                blockCommentStart: nil,
                blockCommentEnd: nil,
                types: []
            )
        default:
            return CodeLanguage(
                name: e.uppercased(),
                keywords: [],
                lineCommentPrefix: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                types: []
            )
        }
    }
}

public final class CodeHighlighter {
    public static let shared = CodeHighlighter()

    private let keywordColor = NSColor(red: 0.65, green: 0.12, blue: 0.60, alpha: 1.0) // Purple
    private let stringColor = NSColor(red: 0.78, green: 0.22, blue: 0.15, alpha: 1.0)  // Brick red
    private let commentColor = NSColor(red: 0.38, green: 0.45, blue: 0.38, alpha: 1.0) // Olive green
    private let typeColor = NSColor(red: 0.15, green: 0.45, blue: 0.75, alpha: 1.0)    // Blue
    private let numberColor = NSColor(red: 0.10, green: 0.50, blue: 0.55, alpha: 1.0)  // Teal
    private let defaultColor = NSColor(red: 0.15, green: 0.16, blue: 0.18, alpha: 1.0) // Near black

    private init() {}

    public func highlight(code: String, language: CodeLanguage, font: NSFont) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: code,
            attributes: [
                .font: font,
                .foregroundColor: defaultColor
            ]
        )

        let nsString = code as NSString
        let length = nsString.length
        guard length > 0 else { return attributed }

        // Highlight line comments
        if let prefix = language.lineCommentPrefix {
            let pattern = "\(NSRegularExpression.escapedPattern(for: prefix)).*$"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: length))
                for match in matches {
                    attributed.addAttribute(.foregroundColor, value: commentColor, range: match.range)
                }
            }
        }

        // Highlight block comments
        if let start = language.blockCommentStart, let end = language.blockCommentEnd {
            let pattern = "\(NSRegularExpression.escapedPattern(for: start))[\\s\\S]*?\(NSRegularExpression.escapedPattern(for: end))"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: length))
                for match in matches {
                    attributed.addAttribute(.foregroundColor, value: commentColor, range: match.range)
                }
            }
        }

        // Highlight strings ("...", '...', `...`)
        let stringPattern = "(\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\")|('[^'\\\\]*(?:\\\\.[^'\\\\]*)*')|(`[^`\\\\]*(?:\\\\.[^`\\\\]*)*`)"
        if let regex = try? NSRegularExpression(pattern: stringPattern, options: []) {
            let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: length))
            for match in matches {
                // Only color if not already inside comment
                var existingColor: NSColor?
                if match.range.location < attributed.length {
                    existingColor = attributed.attribute(.foregroundColor, at: match.range.location, effectiveRange: nil) as? NSColor
                }
                if existingColor != commentColor {
                    attributed.addAttribute(.foregroundColor, value: stringColor, range: match.range)
                }
            }
        }

        // Highlight numbers
        let numberPattern = "\\b\\d+(\\.\\d+)?\\b"
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: length))
            for match in matches {
                let currentColor = attributed.attribute(.foregroundColor, at: match.range.location, effectiveRange: nil) as? NSColor
                if currentColor == defaultColor {
                    attributed.addAttribute(.foregroundColor, value: numberColor, range: match.range)
                }
            }
        }

        // Highlight keywords
        for keyword in language.keywords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: length))
                for match in matches {
                    let currentColor = attributed.attribute(.foregroundColor, at: match.range.location, effectiveRange: nil) as? NSColor
                    if currentColor == defaultColor {
                        attributed.addAttribute(.foregroundColor, value: keywordColor, range: match.range)
                        attributed.addAttribute(.font, value: NSFont(name: "Menlo-Bold", size: font.pointSize) ?? font, range: match.range)
                    }
                }
            }
        }

        // Highlight known types
        for typeName in language.types {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: typeName))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: length))
                for match in matches {
                    let currentColor = attributed.attribute(.foregroundColor, at: match.range.location, effectiveRange: nil) as? NSColor
                    if currentColor == defaultColor {
                        attributed.addAttribute(.foregroundColor, value: typeColor, range: match.range)
                    }
                }
            }
        }

        return attributed
    }
}
