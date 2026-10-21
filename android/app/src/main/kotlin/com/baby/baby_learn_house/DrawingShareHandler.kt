package com.baby.baby_learn_house

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

interface DrawingSharePlatform {
    val directory: File
    fun decodePng(bytes: ByteArray): Boolean
    fun available(): Boolean
    fun present(file: File)
}

class DrawingShareHandler(private val platform: DrawingSharePlatform) {
    constructor(activity: Activity): this(AndroidDrawingSharePlatform(activity))
    companion object {
        fun validHeader(bytes: ByteArray): Boolean {
            val signature = byteArrayOf(137.toByte(),80,78,71,13,10,26,10)
            if (bytes.size < 24 || bytes.size > 12*1024*1024) return false
            return signature.indices.all { bytes[it] == signature[it] }
        }
        fun cleanOld(directory: File, now: Long) {
            directory.listFiles()?.filter { it.isFile && it.extension == "png" && now-it.lastModified() > 86400000L }
                ?.forEach { it.delete() }
        }
    }
    fun share(arguments: Any?, result: MethodChannel.Result) {
        try {
            val args = arguments as? Map<*,*> ?: error("Missing arguments")
            val bytes = args["bytes"] as? ByteArray ?: error("Missing PNG")
            require(validHeader(bytes)) { "Invalid PNG bytes" }
            val anchor = args["anchor"] as? Map<*,*> ?: error("Missing anchor")
            for (key in listOf("x","y","width","height")) {
                val number = (anchor[key] as? Number)?.toDouble() ?: error("Invalid anchor")
                require(number.isFinite() && (key !in listOf("width","height") || number > 0))
            }
            require(platform.decodePng(bytes)) { "PNG decoding failed" }
            check(platform.available()) { "Activity unavailable" }
            val directory = platform.directory.apply { mkdirs() }
            cleanOld(directory,System.currentTimeMillis())
            val file = File(directory,"drawing-${UUID.randomUUID()}.png")
            file.writeBytes(bytes)
            platform.present(file)
            result.success(mapOf("status" to "presented"))
        } catch (e: Exception) {
            result.error("drawing_share_failed",e.message,null)
        }
    }
}

private class AndroidDrawingSharePlatform(private val activity: Activity): DrawingSharePlatform {
    override val directory get() = File(activity.cacheDir,"drawing_exports")
    override fun available() = !activity.isFinishing && !activity.isDestroyed
    override fun decodePng(bytes: ByteArray): Boolean {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes,0,bytes.size,options)
        if (options.outWidth != 1024 || options.outHeight != 1024 || options.outMimeType != "image/png") return false
        val bitmap = BitmapFactory.decodeByteArray(bytes,0,bytes.size) ?: return false
        bitmap.recycle(); return true
    }
    override fun present(file: File) {
        val uri = FileProvider.getUriForFile(activity,"${activity.packageName}.drawing_share",file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM,uri)
            clipData = ClipData.newUri(activity.contentResolver,"画板PNG",uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(Intent.createChooser(send,"分享画板PNG").apply { addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION) })
    }
}
