package com.pmk.pro_coding_studio

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.jcraft.jsch.JSch

class MainActivity: FlutterActivity() {
  private val CHANNEL = "com.pmk.pro_coding_studio/file_explorer"
  private val SSH_CHANNEL = "com.pmk.pro_coding_studio/github_ssh"
  private val REQUEST_CODE_OPEN_DIRECTORY = 1001
  private val REQUEST_CODE_OPEN_DOCUMENT = 1002
  private var pendingResult: MethodChannel.Result? = null
  private lateinit var sshHandler: GitHubSSHHandler

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    
    // Initialize SSH handler
    sshHandler = GitHubSSHHandler(this)
    
    // Set up SSH method channel
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SSH_CHANNEL).setMethodCallHandler { call, result ->
      sshHandler.handleMethodCall(call, result)
    }
    
    // Set up file explorer method channel
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "openDocumentTree" -> {
          openDocumentTree(result)
        }
        "openDocument" -> {
          openDocument(result)
        }
        "listFiles" -> {
          val directoryUri = call.argument<String>("directoryUri") ?: ""
          
          try {
            val uri = Uri.parse(directoryUri)
            val documentFile = DocumentFile.fromTreeUri(context, uri)
            
            if (documentFile != null && documentFile.exists() && documentFile.isDirectory) {
              val files = documentFile.listFiles()
              val filesList = ArrayList<Map<String, Any>>()
              
              for (file in files) {
                filesList.add(mapOf(
                  "name" to (file.name ?: "Unnamed"),
                  "isDirectory" to file.isDirectory,
                  "uri" to file.uri.toString(),
                  "mimeType" to (file.type ?: ""),
                  "size" to (file.length()),
                  "lastModified" to (file.lastModified())
                ))
              }
              
              result.success(filesList)
            } else {
              result.error("DIRECTORY_ERROR", "Directory does not exist or is not accessible", null)
            }
          } catch (e: Exception) {
            result.error("URI_ERROR", "Error processing URI: ${e.message}", null)
          }
        }
        "readFileContent" -> {
          val fileUri = call.argument<String>("fileUri") ?: ""
          
          try {
            val uri = Uri.parse(fileUri)
            val inputStream = contentResolver.openInputStream(uri)
            
            if (inputStream != null) {
              val content = inputStream.bufferedReader().use { it.readText() }
              inputStream.close()
              result.success(content)
            } else {
              result.error("READ_ERROR", "Could not open file for reading", null)
            }
          } catch (e: Exception) {
            result.error("READ_ERROR", "Error reading file: ${e.message}", null)
          }
        }
        "readFileBytes" -> {
          val fileUri = call.argument<String>("fileUri") ?: ""
          
          try {
            val uri = Uri.parse(fileUri)
            val inputStream = contentResolver.openInputStream(uri)
            
            if (inputStream != null) {
              val bytes = inputStream.readBytes()
              inputStream.close()
              result.success(bytes)
            } else {
              result.error("READ_ERROR", "Could not open file for reading bytes", null)
            }
          } catch (e: Exception) {
            result.error("READ_ERROR", "Error reading file bytes: ${e.message}", null)
          }
        }
        "readFileBase64" -> {
          val fileUri = call.argument<String>("fileUri") ?: ""
          
          try {
            val uri = Uri.parse(fileUri)
            val inputStream = contentResolver.openInputStream(uri)
            
            if (inputStream != null) {
              val bytes = inputStream.readBytes()
              inputStream.close()
              val base64String = android.util.Base64.encodeToString(bytes, android.util.Base64.DEFAULT)
              result.success(base64String)
            } else {
              result.error("READ_ERROR", "Could not open file for reading as base64", null)
            }
          } catch (e: Exception) {
            result.error("READ_ERROR", "Error reading file as base64: ${e.message}", null)
          }
        }
        "writeFileContent" -> {
          // Accept both 'uri' and 'fileUri' for compatibility
          val fileUri = call.argument<String>("uri") ?: call.argument<String>("fileUri") ?: ""
          val content = call.argument<String>("content") ?: ""
          val isBase64 = call.argument<Boolean>("isBase64") ?: false
          
          try {
            val uri = Uri.parse(fileUri)
            // Log the URI for debugging
            android.util.Log.d("SAF_WRITE", "Attempting to write to URI: $uri")
            
            // For Save As operations, the URI might be newly created and may not need persistent permissions
            // Only try to take persistable permission for existing files
            if (!fileUri.contains("document/primary")) {
              try {
                val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                // Only attempt to take permission if not already granted
                val persisted = contentResolver.persistedUriPermissions.any { it.uri == uri }
                if (!persisted) {
                  contentResolver.takePersistableUriPermission(uri, takeFlags)
                  android.util.Log.d("SAF_WRITE", "Persistable permission granted for $uri")
                } else {
                  android.util.Log.d("SAF_WRITE", "Persistable permission already granted for $uri")
                }
              } catch (e: Exception) {
                // This warning is expected for some URIs (e.g., Save As on new files)
                android.util.Log.w("SAF_WRITE", "Could not take persistable permission (often harmless for Save As): ${e.message}")
              }
            }
            
            try {
              val outputStream = contentResolver.openOutputStream(uri, "wt") // "wt" mode for write and truncate
              if (outputStream != null) {
                // Handle base64 content if specified
                val bytes = if (isBase64) {
                  android.util.Base64.decode(content, android.util.Base64.DEFAULT)
                } else {
                  content.toByteArray()
                }
                
                outputStream.write(bytes)
                outputStream.flush()
                outputStream.close()
                result.success(true)
              } else {
                android.util.Log.e("SAF_WRITE", "outputStream is null for uri: $uri")
                result.error("FILE_ERROR", "Could not open file for writing", null)
              }
            } catch (e: Exception) {
              android.util.Log.e("SAF_WRITE", "Exception during write: ${e.message}", e)
              result.error("WRITE_ERROR", "Error writing to file: ${e.message}", null)
            }
          } catch (e: Exception) {
            result.error("WRITE_ERROR", "Error writing to file: ${e.message}", null)
          }
        }
        "createFile" -> {
          val directoryUri = call.argument<String>("directoryUri") ?: ""
          val fileName = call.argument<String>("fileName") ?: ""
          val mimeType = call.argument<String>("mimeType") ?: "text/plain"
          
          android.util.Log.d("SAF_CREATE", "Creating file: $fileName with mime type: $mimeType in directory: $directoryUri")
          
          try {
            val uri = Uri.parse(directoryUri)
            
            // Try to take persistable permission if possible
            try {
              val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
              contentResolver.takePersistableUriPermission(uri, takeFlags)
              android.util.Log.d("SAF_CREATE", "Persistable permission granted for $uri")
            } catch (e: Exception) {
              android.util.Log.w("SAF_CREATE", "Could not take persistable permission: ${e.message}")
            }
            
            val documentFile = DocumentFile.fromTreeUri(context, uri)
            
            if (documentFile != null && documentFile.exists() && documentFile.isDirectory) {
              android.util.Log.d("SAF_CREATE", "Directory exists, creating file...")
              
              // Check if file with same name already exists and delete it if it does
              val existingFiles = documentFile.listFiles()
              for (existing in existingFiles) {
                if (existing.name == fileName && !existing.isDirectory) {
                  android.util.Log.d("SAF_CREATE", "File with same name exists, deleting it first")
                  existing.delete()
                  break
                }
              }
              
              val newFile = documentFile.createFile(mimeType, fileName)
              if (newFile != null) {
                android.util.Log.d("SAF_CREATE", "File created successfully: ${newFile.uri}")
                result.success(mapOf(
                  "uri" to newFile.uri.toString(),
                  "name" to (newFile.name ?: fileName),
                  "isDirectory" to false,
                  "mimeType" to (newFile.type ?: mimeType),
                  "size" to 0L,
                  "lastModified" to System.currentTimeMillis()
                ))
              } else {
                android.util.Log.e("SAF_CREATE", "createFile returned null")
                result.error("CREATE_ERROR", "Could not create file", null)
              }
            } else {
              android.util.Log.e("SAF_CREATE", "Directory does not exist or is not accessible")
              result.error("DIRECTORY_ERROR", "Parent directory does not exist or is not accessible", null)
            }
          } catch (e: Exception) {
            android.util.Log.e("SAF_CREATE", "Error creating file: ${e.message}", e)
            result.error("CREATE_ERROR", "Error creating file: ${e.message}", null)
          }
        }
        "createDirectory" -> {
          val directoryUri = call.argument<String>("directoryUri") ?: ""
          val folderName = call.argument<String>("folderName") ?: ""
          
          try {
            val uri = Uri.parse(directoryUri)
            val documentFile = DocumentFile.fromTreeUri(context, uri)
            
            if (documentFile != null && documentFile.exists() && documentFile.isDirectory) {
              val newFolder = documentFile.createDirectory(folderName)
              if (newFolder != null) {
                result.success(mapOf(
                  "uri" to newFolder.uri.toString(),
                  "name" to (newFolder.name ?: folderName),
                  "isDirectory" to true
                ))
              } else {
                result.error("CREATE_ERROR", "Could not create directory", null)
              }
            } else {
              result.error("DIRECTORY_ERROR", "Parent directory does not exist or is not accessible", null)
            }
          } catch (e: Exception) {
            result.error("CREATE_ERROR", "Error creating directory: ${e.message}", null)
          }
        }
        "getParentUri" -> {
          val uri = call.argument<String>("uri") ?: ""
          
          try {
            val parsedUri = Uri.parse(uri)
            val documentFile = DocumentFile.fromTreeUri(context, parsedUri)
            
            if (documentFile != null && documentFile.exists()) {
              val parentFile = documentFile.parentFile
              if (parentFile != null) {
                result.success(parentFile.uri.toString())
              } else {
                // If parent is null, we're likely at the root
                result.success(null)
              }
            } else {
              result.error("URI_ERROR", "Document does not exist or is not accessible", null)
            }
          } catch (e: Exception) {
            result.error("PARENT_ERROR", "Error getting parent URI: ${e.message}", null)
          }
        }
        "extractZipToContentUri" -> {
          println("TEMPLATE_DEBUG: extractZipToContentUri method called")
          val zipFilePath = call.argument<String>("zipFilePath") ?: ""
          val targetDirectoryUri = call.argument<String>("targetDirectoryUri") ?: ""
          
          try {
            println("TEMPLATE_DEBUG: Starting ZIP extraction to content URI")
            println("TEMPLATE_DEBUG: ZIP file path: $zipFilePath")
            println("TEMPLATE_DEBUG: Target directory URI: $targetDirectoryUri")
            
            // Get the target directory as a DocumentFile
            val targetUri = Uri.parse(targetDirectoryUri)
            val targetDir = DocumentFile.fromTreeUri(context, targetUri)
            
            println("TEMPLATE_DEBUG: Target directory name: ${targetDir?.name}")
            println("TEMPLATE_DEBUG: Target directory exists: ${targetDir?.exists()}")
            println("TEMPLATE_DEBUG: Target directory is directory: ${targetDir?.isDirectory}")
            
            if (targetDir == null || !targetDir.exists() || !targetDir.isDirectory) {
              println("TEMPLATE_DEBUG: ERROR - Target directory does not exist or is not accessible")
              result.error("DIRECTORY_ERROR", "Target directory does not exist or is not accessible", null)
              return@setMethodCallHandler
            }
            
            // List existing files in target directory
            println("TEMPLATE_DEBUG: Existing files in target directory:")
            targetDir.listFiles().forEach { file ->
              println("TEMPLATE_DEBUG: - ${file.name} (${if (file.isDirectory) "directory" else "file"})")
            }
            
            // Open the ZIP file
            val zipFile = java.util.zip.ZipFile(zipFilePath)
            val entries = zipFile.entries()
            var extractedCount = 0
            val totalEntries = zipFile.size()
            
            println("TEMPLATE_DEBUG: ZIP file contains $totalEntries entries")
            
            // Process each entry in the ZIP file
            while (entries.hasMoreElements()) {
              val entry = entries.nextElement()
              val entryName = entry.name
              
              println("TEMPLATE_DEBUG: Processing entry: $entryName (${if (entry.isDirectory) "directory" else "file"})")
              
              // Skip directories in the ZIP file
              if (entry.isDirectory) {
                println("TEMPLATE_DEBUG: Creating directory: $entryName")
                // Create the directory in the target location
                val newDir = createDirectoryHierarchy(targetDir, entryName)
                println("TEMPLATE_DEBUG: Directory created: ${newDir.name} at ${newDir.uri}")
                continue
              }
              
              // Get the parent directory for this file
              val parentPath = entryName.substringBeforeLast('/', "")
              println("TEMPLATE_DEBUG: Parent path for $entryName: $parentPath")
              
              val parentDir = if (parentPath.isEmpty()) {
                println("TEMPLATE_DEBUG: Using root directory as parent")
                targetDir
              } else {
                println("TEMPLATE_DEBUG: Creating parent directory hierarchy: $parentPath")
                createDirectoryHierarchy(targetDir, parentPath)
              }
              
              // Create the file in the target directory
              val fileName = entryName.substringAfterLast('/')
              val mimeType = getMimeType(fileName)
              println("TEMPLATE_DEBUG: Creating file: $fileName with mime type: $mimeType")
              
              val newFile = parentDir.createFile(mimeType, fileName)
              
              if (newFile != null) {
                println("TEMPLATE_DEBUG: File created: ${newFile.name} at ${newFile.uri}")
                
                // Write the file content
                val inputStream = zipFile.getInputStream(entry)
                val outputStream = contentResolver.openOutputStream(newFile.uri)
                
                if (outputStream != null) {
                  val buffer = ByteArray(8192)
                  var len: Int
                  var bytesWritten = 0L
                  
                  while (inputStream.read(buffer).also { len = it } > 0) {
                    outputStream.write(buffer, 0, len)
                    bytesWritten += len
                  }
                  
                  outputStream.close()
                  extractedCount++
                  println("TEMPLATE_DEBUG: File written: $bytesWritten bytes")
                } else {
                  println("TEMPLATE_DEBUG: ERROR - Could not open output stream for ${newFile.uri}")
                }
                
                inputStream.close()
              } else {
                println("TEMPLATE_DEBUG: ERROR - Failed to create file: $fileName")
              }
            }
            
            zipFile.close()
            
            // List files after extraction
            println("TEMPLATE_DEBUG: Files in target directory after extraction:")
            targetDir.listFiles().forEach { file ->
              println("TEMPLATE_DEBUG: - ${file.name} (${if (file.isDirectory) "directory" else "file"})")
            }
            
            println("TEMPLATE_DEBUG: Extraction complete. Extracted $extractedCount files")
            result.success(true)
          } catch (e: Exception) {
            println("TEMPLATE_DEBUG: ERROR - ${e.message}")
            e.printStackTrace()
            result.error("EXTRACT_ERROR", "Error extracting ZIP to content URI: ${e.message}", null)
          }
        }
        "deleteFile" -> {
          val fileUri = call.argument<String>("fileUri") ?: ""
          
          android.util.Log.d("SAF_DELETE", "Delete request received for URI: $fileUri")
          
          try {
            val uri = Uri.parse(fileUri)
            // First try with fromSingleUri for regular files
            var documentFile = DocumentFile.fromSingleUri(context, uri)
            
            // If null, try with fromTreeUri for files in a directory structure
            if (documentFile == null) {
              android.util.Log.d("SAF_DELETE", "fromSingleUri returned null, trying fromTreeUri")
              documentFile = DocumentFile.fromTreeUri(context, uri)
            }
            
            if (documentFile != null && documentFile.exists()) {
              android.util.Log.d("SAF_DELETE", "File exists, attempting to delete: ${documentFile.name}")
              
              // Try to take persistable permission if possible
              try {
                val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                contentResolver.takePersistableUriPermission(uri, takeFlags)
                android.util.Log.d("SAF_DELETE", "Persistable permission granted for $uri")
              } catch (e: Exception) {
                android.util.Log.w("SAF_DELETE", "Could not take persistable permission: ${e.message}")
              }
              
              val success = documentFile.delete()
              if (success) {
                android.util.Log.d("SAF_DELETE", "File deleted successfully")
                result.success(true)
              } else {
                android.util.Log.e("SAF_DELETE", "File exists but delete() returned false")
                result.error("DELETE_ERROR", "Failed to delete file", null)
              }
            } else {
              android.util.Log.e("SAF_DELETE", "File does not exist or is not accessible")
              result.error("FILE_ERROR", "File does not exist or is not accessible", null)
            }
          } catch (e: Exception) {
            android.util.Log.e("SAF_DELETE", "Error deleting file: ${e.message}", e)
            result.error("DELETE_ERROR", "Error deleting file: ${e.message}", null)
          }
        }
        else -> result.notImplemented()
      }
    }
  }
  
  private fun openDocumentTree(result: MethodChannel.Result) {
    try {
      val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
      startActivityForResult(intent, REQUEST_CODE_OPEN_DIRECTORY)
      pendingResult = result
    } catch (e: Exception) {
      result.error("INTENT_ERROR", "Error launching directory picker: ${e.message}", null)
    }
  }
  
  private fun openDocument(result: MethodChannel.Result) {
    try {
      val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
        addCategory(Intent.CATEGORY_OPENABLE)
        type = "*/*" // Allow all file types
      }
      startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT)
      pendingResult = result
    } catch (e: Exception) {
      result.error("INTENT_ERROR", "Error launching file picker: ${e.message}", null)
    }
  }
  
  // Helper method to create directory hierarchy in a DocumentFile
  private fun createDirectoryHierarchy(rootDir: DocumentFile, path: String): DocumentFile {
    var currentDir = rootDir
    val segments = path.split("/")
    
    for (segment in segments) {
      if (segment.isEmpty()) continue
      
      // Check if directory already exists
      var found = false
      for (child in currentDir.listFiles()) {
        if (child.isDirectory && child.name == segment) {
          currentDir = child
          found = true
          break
        }
      }
      
      // Create directory if it doesn't exist
      if (!found) {
        val newDir = currentDir.createDirectory(segment)
        if (newDir != null) {
          currentDir = newDir
        } else {
          throw Exception("Failed to create directory: $segment")
        }
      }
    }
    
    return currentDir
  }
  
  // Helper method to get MIME type from file extension
  private fun getMimeType(fileName: String): String {
    return when (fileName.substringAfterLast('.', "").lowercase()) {
      "txt" -> "text/plain"
      "html", "htm" -> "text/html"
      "js" -> "application/javascript"
      "css" -> "text/css"
      "json" -> "application/json"
      "xml" -> "application/xml"
      "png" -> "image/png"
      "jpg", "jpeg" -> "image/jpeg"
      "gif" -> "image/gif"
      "pdf" -> "application/pdf"
      "zip" -> "application/zip"
      "md" -> "text/markdown"
      "dart" -> "application/dart"
      "java" -> "text/x-java-source"
      "kt" -> "text/x-kotlin"
      "swift" -> "text/x-swift"
      "py" -> "text/x-python"
      "c" -> "text/x-c"
      "cpp" -> "text/x-c++"
      "h" -> "text/x-c"
      "hpp" -> "text/x-c++"
      "gradle" -> "text/x-gradle"
      "yaml", "yml" -> "application/x-yaml"
      else -> "application/octet-stream"
    }
  }
  
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    
    if (resultCode == RESULT_OK) {
      val uri = data?.data
      if (uri != null) {
        // Take persistable permission
        val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or 
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        contentResolver.takePersistableUriPermission(uri, takeFlags)
        
        when (requestCode) {
          REQUEST_CODE_OPEN_DIRECTORY -> {
            pendingResult?.success(uri.toString())
            pendingResult = null
          }
          REQUEST_CODE_OPEN_DOCUMENT -> {
            // Get file information
            val documentFile = DocumentFile.fromSingleUri(context, uri)
            if (documentFile != null && documentFile.exists()) {
              val fileInfo = mapOf(
                "uri" to uri.toString(),
                "name" to (documentFile.name ?: "Unknown"),
                "isDirectory" to false,
                "mimeType" to (documentFile.type ?: ""),
                "size" to documentFile.length(),
                "lastModified" to documentFile.lastModified()
              )
              pendingResult?.success(fileInfo)
            } else {
              pendingResult?.error("FILE_ERROR", "File does not exist or is not accessible", null)
            }
            pendingResult = null
          }
        }
      } else {
        pendingResult?.error("URI_ERROR", "Null URI returned", null)
        pendingResult = null
      }
    } else if (resultCode == RESULT_CANCELED) {
      pendingResult?.error("CANCELED", "User canceled the picker", null)
      pendingResult = null
    }
  }
}
