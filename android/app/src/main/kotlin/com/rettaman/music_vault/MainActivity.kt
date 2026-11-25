package com.rettaman.music_vault

import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "music_vault/storage"
    private val folderPath = "Music/MusicVault/"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getSongs" -> result.success(getSongs())
                    "importAudio" -> {
                        val name = call.argument<String>("name")
                        val bytes = call.argument<ByteArray>("bytes")

                        if (name == null || bytes == null) {
                            result.error("INVALID_FILE", "File audio tidak valid", null)
                        } else {
                            importAudio(name, bytes)
                            result.success(true)
                        }
                    }
                    "deleteSong" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_PATH", "Lokasi file tidak valid", null)
                        } else {
                            val deleted = contentResolver.delete(
                                Uri.parse(path),
                                null,
                                null
                            )
                            if (deleted > 0) {
                                result.success(true)
                            } else {
                                result.error("DELETE_FAILED", "File tidak ditemukan atau gagal dihapus", null)
                            }
                        }
                    }
                    "getStorageBytes" -> result.success(getStorageBytes())
                    "openMusicVaultFolder" -> {
                        openMusicVaultFolder()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("MUSICVAULT_STORAGE_ERROR", e.message, e.toString())
            }
        }
    }

    private fun requireModernStorage() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw IllegalStateException(
                "Folder publik MusicVault membutuhkan Android 10 atau lebih baru."
            )
        }
    }

    private fun importAudio(name: String, bytes: ByteArray) {
        requireModernStorage()

        val extension = name.substringAfterLast('.', "").lowercase()
        val mimeType = MimeTypeMap.getSingleton()
            .getMimeTypeFromExtension(extension) ?: "application/octet-stream"

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, folderPath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = contentResolver.insert(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            values
        ) ?: throw IllegalStateException("Tidak bisa membuat file di folder MusicVault.")

        try {
            contentResolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: throw IllegalStateException("Tidak bisa menulis file audio.")

            val completed = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            contentResolver.update(uri, completed, null, null)
        } catch (e: Exception) {
            contentResolver.delete(uri, null, null)
            throw e
        }
    }

    private fun getSongs(): List<Map<String, Any?>> {
        requireModernStorage()

        val songs = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION
        )

        val cursor = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            "${MediaStore.MediaColumns.RELATIVE_PATH} = ?",
            arrayOf(folderPath),
            "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
        )

        cursor?.use {
            val idColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

            while (it.moveToNext()) {
                val id = it.getLong(idColumn)
                val uri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id
                )

                songs.add(
                    mapOf(
                        "id" to id.toInt(),
                        "title" to it.getString(titleColumn),
                        "artist" to it.getString(artistColumn),
                        "album" to it.getString(albumColumn),
                        "duration" to it.getLong(durationColumn).toInt(),
                        "path" to uri.toString()
                    )
                )
            }
        }

        return songs
    }

    private fun getStorageBytes(): Long {
        requireModernStorage()

        var total = 0L
        val projection = arrayOf(MediaStore.Audio.Media.SIZE)

        val cursor = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            "${MediaStore.MediaColumns.RELATIVE_PATH} = ?",
            arrayOf(folderPath),
            null
        )

        cursor?.use {
            val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            while (it.moveToNext()) {
                total += it.getLong(sizeColumn)
            }
        }

        return total
    }

    private fun openMusicVaultFolder() {
        requireModernStorage()

        val folderUri = DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:Music/MusicVault"
        )

        try {
            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(
                    folderUri,
                    DocumentsContract.Document.MIME_TYPE_DIR
                )
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            }
            startActivity(viewIntent)
        } catch (_: Exception) {
            val treeIntent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, folderUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            }
            startActivity(treeIntent)
        }
    }
}
