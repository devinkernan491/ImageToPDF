package com.devinkernan.imagetopdf

import android.content.Context
import android.graphics.*
import android.graphics.pdf.PdfDocument
import android.net.Uri
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import kotlin.math.max

data class FileItem(
    val uri: Uri,
    val name: String,
    val size: Long,
    val isCode: Boolean,
    val extension: String
)

object PdfConverter {

    fun convertFilesToPdf(context: Context, items: List<FileItem>, outputFile: File) {
        val document = PdfDocument()

        for (item in items) {
            if (item.isCode) {
                renderCodeFile(context, item, document)
            } else {
                renderImageFile(context, item, document)
            }
        }

        FileOutputStream(outputFile).use { out ->
            document.writeTo(out)
        }
        document.close()
    }

    private fun renderImageFile(context: Context, item: FileItem, document: PdfDocument) {
        var bitmap: Bitmap? = null
        try {
            val input: InputStream? = context.contentResolver.openInputStream(item.uri)
            bitmap = BitmapFactory.decodeStream(input)
            input?.close()
        } catch (e: Exception) {
            e.printStackTrace()
            return
        }

        if (bitmap == null) return

        val imgWidth = bitmap.width
        val imgHeight = bitmap.height

        // Letter size 612x792
        val pageWidth = 612
        val pageHeight = 792

        val pageInfo = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, document.pages.size + 1).create()
        val page = document.startPage(pageInfo)
        val canvas = page.canvas

        // Background white
        canvas.drawColor(Color.WHITE)

        // Fit image
        val scale = minOf(pageWidth.toFloat() / imgWidth, pageHeight.toFloat() / imgHeight)
        val drawW = imgWidth * scale
        val drawH = imgHeight * scale
        val left = (pageWidth - drawW) / 2f
        val top = (pageHeight - drawH) / 2f

        val destRect = RectF(left, top, left + drawW, top + drawH)
        canvas.drawBitmap(bitmap, null, destRect, null)

        document.finishPage(page)
        bitmap.recycle()
    }

    private fun renderCodeFile(context: Context, item: FileItem, document: PdfDocument) {
        val content: String = try {
            val input = context.contentResolver.openInputStream(item.uri)
            input?.bufferedReader()?.use { it.readText() } ?: ""
        } catch (e: Exception) {
            return
        }

        val rawLines = content.lines()
        val pageWidth = 612
        val pageHeight = 792

        val leftMargin = 36f
        val rightMargin = 36f
        val topMargin = 40f
        val bottomMargin = 40f

        val headerY = topMargin + 16f
        val dividerY = topMargin + 26f
        val contentStartY = topMargin + 48f

        val lineHeight = 14f
        val fontSize = 9.5f

        val textPaint = Paint().apply {
            textSize = fontSize
            typeface = Typeface.MONOSPACE
            isAntiAlias = true
        }

        val gutterPaint = Paint().apply {
            textSize = 8.5f
            typeface = Typeface.MONOSPACE
            color = Color.parseColor("#888888")
            isAntiAlias = true
        }

        val linePaint = Paint().apply {
            color = Color.parseColor("#E0E0E0")
            strokeWidth = 1f
        }

        val gutterBgPaint = Paint().apply {
            color = Color.parseColor("#F9F9FA")
            style = Paint.Style.FILL
        }

        val headerPaint = Paint().apply {
            textSize = 10.5f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            color = Color.parseColor("#222222")
            isAntiAlias = true
        }

        val digits = max(2, rawLines.size.toString().length)
        val gutterWidth = digits * 7f + 16f
        val codeStartX = leftMargin + gutterWidth + 8f

        val availableHeight = pageHeight - contentStartY - bottomMargin
        val linesPerPage = max(1, (availableHeight / lineHeight).toInt())
        val totalPages = max(1, (rawLines.size + linesPerPage - 1) / linesPerPage)

        var currentLineIdx = 0
        var pageNum = 1

        while (currentLineIdx < rawLines.size || (rawLines.isEmpty() && pageNum == 1)) {
            val pageInfo = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, document.pages.size + 1).create()
            val page = document.startPage(pageInfo)
            val canvas = page.canvas

            canvas.drawColor(Color.WHITE)

            // Header
            canvas.drawText("${item.name}  [${item.extension.uppercase()}]", leftMargin, headerY, headerPaint)
            val pageStr = "Page $pageNum of $totalPages"
            val pageStrW = gutterPaint.measureText(pageStr)
            canvas.drawText(pageStr, pageWidth - rightMargin - pageStrW, headerY, gutterPaint)

            // Header divider line
            canvas.drawLine(leftMargin, dividerY, pageWidth - rightMargin, dividerY, linePaint)

            // Gutter background
            canvas.drawRect(leftMargin, dividerY, leftMargin + gutterWidth, pageHeight - bottomMargin, gutterBgPaint)
            canvas.drawLine(leftMargin + gutterWidth, dividerY, leftMargin + gutterWidth, pageHeight - bottomMargin, linePaint)

            // Lines
            var currY = contentStartY
            var rendered = 0

            while (currentLineIdx < rawLines.size && rendered < linesPerPage) {
                val lineNo = currentLineIdx + 1
                val rawLine = rawLines[currentLineIdx].replace("\t", "    ")

                // Line number
                val lineNoStr = lineNo.toString()
                val lineNoW = gutterPaint.measureText(lineNoStr)
                canvas.drawText(lineNoStr, leftMargin + gutterWidth - lineNoW - 6f, currY, gutterPaint)

                // Highlighted text
                val chunks = CodeHighlighter.highlightLine(rawLine, item.extension)
                var currX = codeStartX
                for (chunk in chunks) {
                    textPaint.color = chunk.color
                    canvas.drawText(chunk.text, currX, currY, textPaint)
                    currX += textPaint.measureText(chunk.text)
                }

                currY += lineHeight
                rendered++
                currentLineIdx++
            }

            document.finishPage(page)
            pageNum++
            if (rawLines.isEmpty()) break
        }
    }
}
