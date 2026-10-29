package com.devinkernan.imagetopdf

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.widget.*
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.FileProvider
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class MainActivity : AppCompatActivity() {

    private val selectedItems = mutableListOf<FileItem>()
    private lateinit var adapter: ArrayAdapter<String>
    private val displayStrings = mutableListOf<String>()

    private val selectFilesLauncher = registerForActivityResult(ActivityResultContracts.GetMultipleContents()) { uris: List<Uri> ->
        if (uris.isNotEmpty()) {
            for (uri in uris) {
                val item = extractFileItem(uri)
                if (item != null) {
                    selectedItems.add(item)
                }
            }
            refreshList()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 48, 32, 32)
        }

        val titleView = TextView(this).apply {
            text = "Image to PDF Converter"
            textSize = 24f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(0, 0, 0, 24)
        }
        layout.addView(titleView)

        val btnLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
        }

        val addBtn = Button(this).apply {
            text = "Add Files / Images"
            setOnClickListener {
                selectFilesLauncher.launch("*/*")
            }
        }
        btnLayout.addView(addBtn)

        val clearBtn = Button(this).apply {
            text = "Clear"
            setOnClickListener {
                selectedItems.clear()
                refreshList()
            }
        }
        btnLayout.addView(clearBtn)
        layout.addView(btnLayout)

        val statusView = TextView(this).apply {
            text = "Selected files will appear below:"
            textSize = 14f
            setPadding(0, 24, 0, 12)
        }
        layout.addView(statusView)

        val listView = ListView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        }
        adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, displayStrings)
        listView.adapter = adapter
        layout.addView(listView)

        val convertBtn = Button(this).apply {
            text = "Convert to PDF"
            textSize = 16f
            setPadding(0, 24, 0, 24)
            setOnClickListener {
                if (selectedItems.isEmpty()) {
                    Toast.makeText(this@MainActivity, "Please select at least one file.", Toast.LENGTH_SHORT).show()
                } else {
                    processConversion()
                }
            }
        }
        layout.addView(convertBtn)

        setContentView(layout)
    }

    private fun extractFileItem(uri: Uri): FileItem? {
        var name = "file"
        var size = 0L

        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (cursor.moveToFirst()) {
                if (nameIndex != -1) name = cursor.getString(nameIndex) ?: name
                if (sizeIndex != -1) size = cursor.getLong(sizeIndex)
            }
        }

        val ext = name.substringAfterLast('.', "").lowercase()
        val isCode = setOf("py", "cpp", "c", "h", "hpp", "swift", "js", "ts", "rs", "go", "java", "kt", "sh", "json", "md", "txt").contains(ext)

        return FileItem(uri, name, size, isCode, ext)
    }

    private fun refreshList() {
        displayStrings.clear()
        for ((idx, item) in selectedItems.withIndex()) {
            val badge = if (item.isCode) "[CODE]" else "[IMG]"
            displayStrings.add("${idx + 1}. ${item.name} $badge")
        }
        adapter.notifyDataSetChanged()
    }

    private fun processConversion() {
        val outputFile = File(cacheDir, "Converted_${System.currentTimeMillis()}.pdf")
        Toast.makeText(this, "Generating PDF...", Toast.LENGTH_SHORT).show()

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                PdfConverter.convertFilesToPdf(this@MainActivity, selectedItems, outputFile)
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@MainActivity, "PDF Created Successfully!", Toast.LENGTH_LONG).show()
                    sharePdf(outputFile)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@MainActivity, "Error creating PDF: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun sharePdf(file: File) {
        val uri: Uri = try {
            FileProvider.getUriForFile(this, "${packageName}.provider", file)
        } catch (e: Exception) {
            Uri.fromFile(file)
        }

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, "Open or Share PDF"))
    }
}
