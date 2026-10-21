package com.baby.baby_learn_house

import org.junit.Assert.*
import org.junit.Test
import java.nio.file.Files
import java.io.File
import io.flutter.plugin.common.MethodChannel

class DrawingShareHandlerTest {
    private class Platform(override val directory: File): DrawingSharePlatform {
        var available = true
        var validImage = false
        var failPresent = false
        var presents = 0
        override fun available() = available
        override fun decodePng(bytes: ByteArray) = validImage
        override fun present(file: File) { presents++; if (failPresent) error("cannot launch") }
    }
    private class Result: MethodChannel.Result {
        var error: String? = null
        var value: Any? = null
        override fun success(result: Any?) { value = result }
        override fun error(code: String, message: String?, details: Any?) { error = code }
        override fun notImplemented() { error = "unimplemented" }
    }
    @Test fun shareReportsNativeFailuresAndOnlyPresentsValidFiles() {
        val dir = Files.createTempDirectory("drawing-workflow").toFile()
        try {
            val platform = Platform(dir)
            val handler = DrawingShareHandler(platform)
            val header = ByteArray(24).apply { byteArrayOf(137.toByte(),80,78,71,13,10,26,10).copyInto(this) }
            val anchor = mapOf("x" to 1.0,"y" to 1.0,"width" to 48.0,"height" to 48.0)
            fun invoke(args: Any?): Result = Result().also { handler.share(args,it) }
            for(args in listOf(null, emptyMap<String,Any>(),mapOf("bytes" to header),
                mapOf("bytes" to header,"anchor" to anchor + ("width" to Double.NaN)),
                mapOf("bytes" to header,"anchor" to anchor))) {
                assertNotNull(invoke(args).error)
            }
            assertEquals(0,platform.presents); assertEquals(0,dir.listFiles()!!.size)
            platform.validImage = true; platform.available = false
            val args = mapOf("bytes" to header,"anchor" to anchor)
            assertNotNull(invoke(args).error); assertEquals(0,platform.presents)
            platform.available = true; platform.failPresent = true
            assertNotNull(invoke(args).error)
            platform.failPresent = false
            val result = invoke(args)
            assertNull(result.error); assertEquals(mapOf("status" to "presented"),result.value)
            assertEquals(2,platform.presents); assertTrue(dir.listFiles()!!.all { it.extension == "png" })
        } finally { dir.deleteRecursively() }
    }
    @Test fun rejectsMalformedAndKeepsCurrentFiles() {
        assertFalse(DrawingShareHandler.validHeader(byteArrayOf()))
        assertFalse(DrawingShareHandler.validHeader(ByteArray(12*1024*1024+1)))
        assertFalse(DrawingShareHandler.validHeader(byteArrayOf(137.toByte(),80,78,71,13,10,26,10)))
        val dir = Files.createTempDirectory("drawing-test").toFile()
        try {
            val old = dir.resolve("old.png").apply { writeText("old"); setLastModified(1) }
            val current = dir.resolve("new.png").apply { writeText("current") }
            val other = dir.resolve("keep.txt").apply { writeText("keep") }
            DrawingShareHandler.cleanOld(dir, System.currentTimeMillis())
            assertFalse(old.exists()); assertTrue(current.exists()); assertTrue(other.exists())
        } finally { dir.deleteRecursively() }
    }
}
