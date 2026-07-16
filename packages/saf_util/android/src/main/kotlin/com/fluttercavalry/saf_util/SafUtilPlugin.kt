package com.fluttercavalry.saf_util

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.Point
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC
import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.core.net.toUri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** SafUtilPlugin */
class SafUtilPlugin :
  FlutterPlugin,
  MethodCallHandler,
  ActivityAware {
  // / The MethodChannel that will the communication between Flutter and native Android
  // /
  // / This local reference serves to register the plugin with the Flutter Engine and unregister it
  // / when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel

  private lateinit var context: Context
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null

  private var pendingResult: Result? = null
  private var pendingArguments: PendingArguments? = null
  private val requestCodeOpenDocumentTree = 1001
  private val requestCodeOpenFiles = 1002
  private val requestCodePickMedia = 1003
  private val activityResultListener = PluginRegistry.ActivityResultListener { requestCode, resultCode, data ->
    onActivityResult(requestCode, resultCode, data)
  }
  private val fdMap = mutableMapOf<Int, ParcelFileDescriptor>()

  /** Takes ownership before replying so a Result can never be answered twice. */
  private fun takePendingResult(): Result? {
    val result = pendingResult
    pendingResult = null
    pendingArguments = null
    return result
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "saf_util")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onDetachedFromActivity() {
    detachFromActivityBinding()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    attachToActivity(binding)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    attachToActivity(binding)
  }

  private fun attachToActivity(binding: ActivityPluginBinding) {
    detachFromActivityBinding()
    activityBinding = binding
    activity = binding.activity
    binding.addActivityResultListener(activityResultListener)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    detachFromActivityBinding()
  }

  private fun detachFromActivityBinding() {
    activityBinding?.removeActivityResultListener(activityResultListener)
    activityBinding = null
    activity = null
  }

  override fun onMethodCall(
    call: MethodCall,
    result: Result
  ) {
    when (call.method) {
      "list" -> {
        CoroutineScope(Dispatchers.IO).launch {
          var cursor: Cursor? = null
          try {
            val uri = call.argument<String>("uri") as String

            val dir = documentFileFromUri(uri, true) ?: throw Exception("Failed to get DocumentFile from $uri")
            val resolver = context.contentResolver
            val mUri = dir.uri
            val childrenUri =
              DocumentsContract.buildChildDocumentsUriUsingTree(
                mUri,
                DocumentsContract.getDocumentId(mUri)
              )
            val results = mutableListOf<Map<String, Any?>>()

            cursor =
              resolver.query(
                childrenUri,
                arrayOf(
                  DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                  DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                  DocumentsContract.Document.COLUMN_SIZE,
                  DocumentsContract.Document.COLUMN_MIME_TYPE,
                  DocumentsContract.Document.COLUMN_LAST_MODIFIED
                ),
                null,
                null,
                null
              )

            while (cursor?.moveToNext() == true) {
              val documentId = cursor.getString(0)
              val fileName = cursor.getString(1)
              val fileSize = cursor.getLong(2)
              val mimeType = cursor.getString(3)
              val lastModified = cursor.getLong(4)
              val documentUri = DocumentsContract.buildDocumentUriUsingTree(mUri, documentId)

              // Determine if the file is a directory based on the MIME type
              val isDirectory = DocumentsContract.Document.MIME_TYPE_DIR == mimeType

              // Create a dictionary (map) for each file with its details
              val fileInfo =
                fileObjMap(
                  documentUri,
                  isDirectory,
                  fileName,
                  fileSize,
                  lastModified
                )
              results.add(fileInfo)
            }

            launch(Dispatchers.Main) { result.success(results) }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          } finally {
            try {
              cursor?.close()
            } catch (_: Exception) {
            }
          }
        }
      }

      "documentFileFromUri" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val isDir = call.argument<Boolean>("isDir")

            val df = documentFileFromUri(uri, isDir)
            if (df == null) {
              launch(Dispatchers.Main) {
                result.success(null)
              }
              return@launch
            }
            launch(Dispatchers.Main) {
              result.success(documentFileToMap(df))
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "stat" -> {
        // Unlike `documentFileFromUri` this returns null if `uri` doesn't exist.
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val isDir = call.argument<Boolean>("isDir")
            val throws = call.argument<Boolean>("throws") ?: false

            val df = documentFileFromUri(uri, isDir)
            if (df == null) {
              if (throws) {
                throw Exception("Failed to get DocumentFile from $uri")
              }
              launch(Dispatchers.Main) {
                result.success(null)
              }
              return@launch
            }
            if (!df.exists()) {
              if (throws) {
                throw Exception("DocumentFile at $uri does not exist")
              }
              launch(Dispatchers.Main) {
                result.success(null)
              }
              return@launch
            }
            launch(Dispatchers.Main) {
              result.success(documentFileToMap(df))
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "exists" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val isDir = call.argument<Boolean>("isDir") as Boolean

            val df = documentFileFromUri(uri, isDir)
            if (df == null) {
              launch(Dispatchers.Main) {
                result.success(false)
              }
              return@launch
            }
            launch(Dispatchers.Main) {
              result.success(df.exists())
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "delete" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val isDir = call.argument<Boolean>("isDir") as Boolean

            val df = documentFileFromUri(uri, isDir) ?: throw Exception("Failed to get DocumentFile from $uri")
            launch(Dispatchers.Main) {
              result.success(df.delete())
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "getFileDescriptor" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String

            val df = documentFileFromUri(uri, false) ?: throw Exception("Failed to get DocumentFile from $uri")
            val fd =
              context.contentResolver.openFileDescriptor(df.uri, "r") ?: throw Exception("Failed to open file descriptor")
            val fdInt = fd.fd
            fdMap[fdInt] = fd

            launch(Dispatchers.Main) {
              result.success(fdInt)
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "closeFileDescriptor" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fdInt = call.argument<Int>("fd") as Int
            val fd = fdMap.remove(fdInt)
            fd?.close()

            launch(Dispatchers.Main) {
              result.success(null)
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "mkdirp" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String?>("uri") as String
            val names =
              call.argument<ArrayList<String>>("names") as ArrayList<String>

            var curDocument = documentFileFromUri(uri, true) ?: throw Exception("Failed to get DocumentFile from $uri")
            for (curName in names) {
              val findRes = findDirectChild(curDocument.uri, curName)
              val nextDocument: DocumentFile?
              if (findRes == null) {
                val createRes = curDocument.createDirectory(curName)
                if (createRes != null && createRes.name != curName) {
                  // There are cases where the created directory has a different name due to concurrent operations.
                  // In this case, we need to find the directory with the correct name again.
                  val findRes2 = findDirectChild(curDocument.uri, curName)
                  nextDocument =
                    if (findRes2 != null) {
                      documentFileFromUriObj(findRes2.uri, findRes2.isDir)
                    } else {
                      null
                    }
                } else {
                  nextDocument = createRes
                }
              } else {
                nextDocument = documentFileFromUriObj(findRes.uri, findRes.isDir)
              }

              if (nextDocument == null) {
                throw Exception("Failed to create directory at $curName")
              }
              if (nextDocument.isFile) {
                throw Exception("File found at $curName while creating directory")
              }
              curDocument = nextDocument
            }

            launch(Dispatchers.Main) {
              result.success(documentFileToMap(curDocument))
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "child" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val names = call.argument<ArrayList<String>>("names") as ArrayList<String>

            var curDocument = documentFileFromUri(uri, true) ?: throw Exception("Failed to get DocumentFile from $uri")
            for (curName in names) {
              val findRes = findDirectChild(curDocument.uri, curName)
              if (findRes == null) {
                launch(Dispatchers.Main) {
                  result.success(null)
                }
                return@launch
              }
              curDocument =
                documentFileFromUriObj(findRes.uri, findRes.isDir)
                  ?: throw Exception("Failed to get DocumentFile at $curName")
            }

            launch(Dispatchers.Main) {
              result.success(documentFileToMap(curDocument))
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "rename" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val isDir = call.argument<Boolean>("isDir") as Boolean
            val newName = call.argument<String>("newName") as String

            val df = documentFileFromUri(uri, isDir) ?: throw Exception("Failed to get DocumentFile from $uri")
            if (isDir) {
              val success = df.renameTo(newName)
              if (!success) {
                throw Exception("Failed to rename to $newName")
              }
              launch(Dispatchers.Main) {
                result.success(documentFileToMap(df))
              }
            } else {
              val newUri =
                renameFileDocumentFile(df, newName)
                  ?: throw Exception("Failed to rename to $newName")
              val newDF =
                documentFileFromUriObj(newUri, false)
                  ?: throw Exception("Failed to get DocumentFile from $newUri")
              launch(Dispatchers.Main) {
                result.success(documentFileToMap(newDF))
              }
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "moveTo" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val isDir = call.argument<Boolean>("isDir") as Boolean
            val parentUri = call.argument<String>("parentUri") as String
            val newParentUri = call.argument<String>("newParentUri") as String

            val uriObj = uri.toUri()
            val parentUriObj = parentUri.toUri()
            val newParentUriObj = newParentUri.toUri()

            val resUri =
              DocumentsContract.moveDocument(
                context.contentResolver,
                uriObj,
                parentUriObj,
                newParentUriObj
              ) ?: throw Exception("Failed to move document")

            val resultDF = documentFileFromUriObj(resUri, isDir) ?: throw Exception("Failed to get DocumentFile from $resUri")
            launch(Dispatchers.Main) {
              result.success(documentFileToMap(resultDF))
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "copyTo" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val isDir = call.argument<Boolean>("isDir") as Boolean
            val newParentUri = call.argument<String>("newParentUri") as String

            val uriObj = uri.toUri()
            val newParentUriObj = newParentUri.toUri()

            val resUri =
              DocumentsContract.copyDocument(
                context.contentResolver,
                uriObj,
                newParentUriObj
              ) ?: throw Exception("Failed to move document")

            val resultDF = documentFileFromUriObj(resUri, isDir) ?: throw Exception("Failed to get DocumentFile from $resUri")

            launch(Dispatchers.Main) {
              result.success(documentFileToMap(resultDF))
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "pickDirectory" -> {
        try {
          val initialUri = call.argument<String>("initialUri")
          val writePermission = call.argument<Boolean>("writePermission") ?: false
          val persistablePermission = call.argument<Boolean>("persistablePermission") ?: false

          if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
          }
          if (pendingResult != null) {
            result.error("ALREADY_PICKING", "Another picker process is already in progress", null)
            return
          }

          // Store the result to return the URI later
          pendingResult = result
          pendingArguments = PendingDirArguments(writePermission, persistablePermission)
          val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
          if (initialUri != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
              intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri.toUri())
            }
          }
          if (persistablePermission) {
            intent.addFlags(
              Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
          }
          intent.addFlags(
            if (writePermission) {
              Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION
            } else {
              Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
          )

          activity?.startActivityForResult(intent, requestCodeOpenDocumentTree)
        } catch (err: Exception) {
          takePendingResult()
          result.error("PluginError", err.message, null)
        }
      }

      "pickFiles" -> {
        try {
          val initialUri = call.argument<String>("initialUri")
          val multiple = call.argument<Boolean>("multiple") ?: true
          val mimeTypes = call.argument<ArrayList<String>>("mimeTypes") ?: arrayListOf()

          if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
          }
          if (pendingResult != null) {
            result.error("ALREADY_PICKING", "Another picker process is already in progress", null)
            return
          }

          // Store the result to return the URI later
          pendingResult = result
          val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
          intent.addCategory(Intent.CATEGORY_OPENABLE)
          if (initialUri != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
              intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri.toUri())
            }
          }
          if (multiple) {
            intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
          }

          if (mimeTypes.isEmpty()) {
            intent.type = "*/*"
          } else if (mimeTypes.size == 1) {
            intent.type = mimeTypes[0]
          } else {
            intent.type = "*/*"
            intent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
          }

          activity?.startActivityForResult(intent, requestCodeOpenFiles)
        } catch (err: Exception) {
          takePendingResult()
          result.error("PluginError", err.message, null)
        }
      }

      "pickMedia" -> {
        try {
          val multiple = call.argument<Boolean>("multiple") ?: false
          val mode = call.argument<String>("mode") ?: "all"

          if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.error("NOT_SUPPORTED", "Photo Picker is only supported on Android 13 (API 33) and above", null)
            return
          }
          if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
          }
          if (pendingResult != null) {
            result.error("ALREADY_PICKING", "Another picker process is already in progress", null)
            return
          }

          val normalizedMode = mode.lowercase()
          if (normalizedMode != "photo" && normalizedMode != "video" && normalizedMode != "all") {
            result.error("INVALID_ARGUMENT", "mode must be one of: photo, video, all", null)
            return
          }

          pendingResult = result
          pendingArguments = PendingMediaArguments(multiple)
          val intent = Intent(MediaStore.ACTION_PICK_IMAGES)
          intent.type =
            when (normalizedMode) {
              "photo" -> "image/*"
              "video" -> "video/*"
              else -> "*/*"
            }
          if (multiple) {
            intent.putExtra(
              MediaStore.EXTRA_PICK_IMAGES_MAX,
              MediaStore.getPickImagesMaxLimit()
            )
          }

          activity?.startActivityForResult(intent, requestCodePickMedia)
        } catch (err: Exception) {
          takePendingResult()
          result.error("PluginError", err.message, null)
        }
      }

      "hasPersistedPermission" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val checkRead = call.argument<Boolean>("checkRead") ?: true
            val checkWrite = call.argument<Boolean>("checkWrite") ?: false

            val persisted =
              hasPersistedUriPermission(
                context,
                uri.toUri(),
                checkRead,
                checkWrite
              )
            launch(Dispatchers.Main) {
              result.success(persisted)
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "releasePersistedPermission" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = call.argument<String>("uri") as String
            val read = call.argument<Boolean>("read") ?: true
            val write = call.argument<Boolean>("write") ?: false

            context.contentResolver.releasePersistableUriPermission(
              uri.toUri(),
              if (read && write) {
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
              } else if (read) {
                Intent.FLAG_GRANT_READ_URI_PERMISSION
              } else if (write) {
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
              } else {
                0
              }
            )
            launch(Dispatchers.Main) {
              result.success(null)
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      "saveThumbnailToFile" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val uri = (call.argument<String>("uri") as String).toUri()
            val dest = call.argument<String>("destPath")!!
            val format = call.argument<String>("format") ?: "jpeg"
            val isPng = format == "png"
            val quality = call.argument("quality") ?: if (isPng) 100 else 80

            val width = call.argument<Int>("width")!!
            val height = call.argument<Int>("height")!!

            val df = DocumentFile.fromSingleUri(context, uri)
            val mime = df?.type
            if (mime == null) {
              launch(Dispatchers.Main) {
                result.success(false)
              }
              return@launch
            }

            val bitmap: Bitmap?
            // Use MediaMetadataRetriever for video files.
            if (mime.startsWith("video/")) {
              val mmr = MediaMetadataRetriever()
              mmr.setDataSource(context, uri)
              bitmap =
                if (Build.VERSION.SDK_INT >= 27) {
                  mmr.getScaledFrameAtTime(-1, OPTION_CLOSEST_SYNC, width, height)
                } else {
                  mmr.frameAtTime
                }
            } else {
              // Use DocumentsContract for other files.
              bitmap =
                DocumentsContract.getDocumentThumbnail(
                  context.contentResolver,
                  uri,
                  Point(width, height),
                  null
                )
            }

            if (bitmap != null) {
              File(dest).writeBitmap(
                bitmap,
                if (isPng) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG,
                quality
              )
              launch(Dispatchers.Main) {
                result.success(true)
              }
            } else {
              launch(Dispatchers.Main) {
                result.success(false)
              }
            }
          } catch (err: Exception) {
            launch(Dispatchers.Main) {
              result.error("PluginError", err.message, null)
            }
          }
        }
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  // Handle folder/file/media picker results; unrelated request codes are not ours.
  private fun onActivityResult(
    requestCode: Int,
    resultCode: Int,
    data: Intent?
  ): Boolean {
    if (
      requestCode != requestCodeOpenDocumentTree &&
      requestCode != requestCodeOpenFiles &&
      requestCode != requestCodePickMedia
    ) {
      return false
    }

    val args = pendingArguments
    val result = takePendingResult() ?: return true
    try {
      if (requestCode == requestCodeOpenDocumentTree) {
        if (resultCode == Activity.RESULT_OK && data != null) {
          val uri: Uri? = data.data
          if (uri != null && args is PendingDirArguments && args.persistablePermission) {
            context.contentResolver.takePersistableUriPermission(
              uri,
              if (args.writePermission) {
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION
              } else {
                Intent.FLAG_GRANT_READ_URI_PERMISSION
              }
            )
          }
          val df = documentFileFromUri(uri.toString(), true)
          result.success(if (df != null) documentFileToMap(df) else null)
        } else {
          result.success(null)
        }
      } else {
        if (resultCode == Activity.RESULT_OK && data != null) {
          val allowMultiple =
            if (requestCode == requestCodePickMedia) {
              (args as? PendingMediaArguments)?.multiple ?: false
            } else {
              true
            }
          val uris: List<Uri> =
            if (allowMultiple && data.clipData != null) {
              val clipData = data.clipData!!
              List(clipData.itemCount) { index -> clipData.getItemAt(index).uri }
            } else {
              listOf(data.data!!)
            }

          val documentFileMaps: MutableList<Map<String, Any?>> = mutableListOf()
          for (uri in uris) {
            val df = documentFileFromUri(uri.toString(), false)
            if (df != null) documentFileMaps.add(documentFileToMap(df))
          }
          result.success(documentFileMaps)
        } else {
          result.success(null)
        }
      }
    } catch (err: Exception) {
      try {
        result.error("PluginError", err.message, null)
      } catch (_: IllegalStateException) {
        // A duplicate native delivery must not crash the host Activity.
      }
    }
    return true
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun documentFileFromUri(
    uri: String,
    isDir: Boolean?
  ): DocumentFile? {
    val uriObj = uri.toUri()
    val isDirRes =
      isDir ?: DocumentsContract.isTreeUri(uriObj)
    return documentFileFromUriObj(uriObj, isDirRes)
  }

  private fun documentFileFromUriObj(
    uriObj: Uri,
    isDir: Boolean
  ): DocumentFile? {
    val res =
      if (isDir) {
        DocumentFile.fromTreeUri(context, uriObj)
      } else {
        DocumentFile.fromSingleUri(context, uriObj)
      }
    return res
  }

  private fun hasPersistedUriPermission(
    context: Context,
    uri: Uri,
    checkRead: Boolean,
    checkWrite: Boolean
  ): Boolean {
    val permissions = context.contentResolver.persistedUriPermissions
    for (permission in permissions) {
      if (areSameDocumentLocation(permission.uri, uri)) {
        val hasRead = !checkRead || permission.isReadPermission
        val hasWrite = !checkWrite || permission.isWritePermission
        return hasRead && hasWrite
      }
    }
    return false
  }

  private fun areSameDocumentLocation(
    treeUri: Uri,
    docUri: Uri
  ): Boolean {
    val treeDocId = DocumentsContract.getTreeDocumentId(treeUri)
    val docId = DocumentsContract.getDocumentId(docUri)
    return treeDocId == docId
  }

  private fun findDirectChild(
    parentUri: Uri,
    name: String
  ): UriInfo? {
    var cursor: Cursor? = null
    try {
      val resolver = context.contentResolver
      val childrenUri =
        DocumentsContract.buildChildDocumentsUriUsingTree(
          parentUri,
          DocumentsContract.getDocumentId(parentUri)
        )
      cursor =
        resolver.query(
          childrenUri,
          arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE
          ),
          null,
          null,
          null
        )

      while (cursor?.moveToNext() == true) {
        val documentId = cursor.getString(0)
        val fileName = cursor.getString(1)
        val mimeType = cursor.getString(2)
        val isDirectory = DocumentsContract.Document.MIME_TYPE_DIR == mimeType

        if (fileName == name) {
          val documentUri = DocumentsContract.buildDocumentUriUsingTree(parentUri, documentId)
          return UriInfo(documentUri, fileName, isDirectory)
        }
      }
      return null
    } finally {
      try {
        cursor?.close()
      } catch (_: Exception) {
      }
    }
  }

  private fun renameFileDocumentFile(
    df: DocumentFile,
    newName: String
  ): Uri? {
    // https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:documentfile/documentfile/src/main/java/androidx/documentfile/provider/TreeDocumentFile.java
    try {
      val result =
        DocumentsContract.renameDocument(
          context.contentResolver,
          df.uri,
          newName
        )
      return result
    } catch (err: Exception) {
      return null
    }
  }

  private fun documentFileToMap(file: DocumentFile): Map<String, Any?> = fileObjMap(
    file.uri,
    file.isDirectory,
    file.name ?: "",
    file.length(),
    file.lastModified()
  )

  private fun fileObjMap(
    uri: Uri,
    isDir: Boolean,
    name: String,
    length: Long,
    lastMod: Long
  ): Map<String, Any?> = mapOf(
    "uri" to uri.toString(),
    "isDir" to isDir,
    "name" to name,
    "length" to length,
    "lastModified" to lastMod
  )

  private fun File.writeBitmap(
    bitmap: Bitmap,
    format: Bitmap.CompressFormat,
    quality: Int
  ) {
    outputStream().use { out ->
      bitmap.compress(format, quality, out)
      out.flush()
    }
  }
}

internal data class UriInfo(
  val uri: Uri,
  val name: String,
  val isDir: Boolean
)

internal open class PendingArguments

internal class PendingDirArguments(
  val writePermission: Boolean,
  val persistablePermission: Boolean
) : PendingArguments()

internal class PendingMediaArguments(
  val multiple: Boolean
) : PendingArguments()
