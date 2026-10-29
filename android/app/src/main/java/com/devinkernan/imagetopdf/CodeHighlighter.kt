package com.devinkernan.imagetopdf

import android.graphics.Color
import java.util.regex.Pattern

data class HighlightedChunk(val text: String, val color: Int)

object CodeHighlighter {
    private val KEYWORD_COLOR = Color.parseColor("#8A2BE2") // Purple
    private val STRING_COLOR = Color.parseColor("#B22222")  // Brick Red
    private val COMMENT_COLOR = Color.parseColor("#2E8B57") // Forest Green
    private val NUMBER_COLOR = Color.parseColor("#D97706")  // Amber
    private val TYPE_COLOR = Color.parseColor("#0066CC")    // Blue
    private val DEFAULT_COLOR = Color.parseColor("#222222") // Dark Gray

    private val KEYWORDS = setOf(
        "def", "class", "import", "from", "return", "if", "elif", "else", "while", "for", "in",
        "try", "except", "finally", "with", "as", "lambda", "yield", "pass", "break", "continue",
        "func", "var", "let", "val", "fun", "public", "private", "protected", "override", "const",
        "int", "float", "double", "char", "void", "bool", "boolean", "auto", "struct", "enum",
        "namespace", "using", "include", "template", "typename", "new", "delete", "true", "false",
        "null", "nil", "None", "True", "False", "async", "await", "function"
    )

    fun highlightLine(line: String, extension: String): List<HighlightedChunk> {
        val trimmed = line.trimStart()
        val isComment = (extension == "py" || extension == "sh") && trimmed.startsWith("#") ||
                trimmed.startsWith("//")

        if (isComment) {
            return listOf(HighlightedChunk(line, COMMENT_COLOR))
        }

        val chunks = mutableListOf<HighlightedChunk>()
        // Simple regex tokenizer for words, numbers, strings, and punctuation
        val pattern = Pattern.compile("(\"[^\"]*\"|'[^']*')|(\\b\\d+(\\.\\d+)?\\b)|([a-zA-Z_][a-zA-Z0-9_]*)|(\\s+)|(.)")
        val matcher = pattern.matcher(line)

        while (matcher.find()) {
            val token = matcher.group()
            val color = when {
                token.startsWith("\"") || token.startsWith("'") -> STRING_COLOR
                token.matches(Regex("\\d+(\\.\\d+)?")) -> NUMBER_COLOR
                KEYWORDS.contains(token) -> KEYWORD_COLOR
                else -> DEFAULT_COLOR
            }
            chunks.add(HighlightedChunk(token, color))
        }

        return if (chunks.isEmpty()) listOf(HighlightedChunk(line, DEFAULT_COLOR)) else chunks
    }
}
