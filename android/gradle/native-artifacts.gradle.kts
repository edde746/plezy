import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
import java.util.UUID

// Checksum + atomic-promotion helpers shared by :app and :libmpv, which both
// download pinned native artifact trees. Exposed as extra properties because
// Kotlin DSL script plugins cannot export functions directly.
extra["verifySha256"] = fun(file: File, expected: String, identity: String) {
  val digest = MessageDigest.getInstance("SHA-256")
  file.inputStream().buffered().use { input ->
    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
    while (true) {
      val count = input.read(buffer)
      if (count < 0) break
      digest.update(buffer, 0, count)
    }
  }
  val actual = digest.digest().joinToString("") {
    (it.toInt() and 0xff).toString(16).padStart(2, '0')
  }
  if (actual != expected) {
    throw GradleException("SHA-256 mismatch for $identity: expected $expected, got $actual")
  }
}

extra["promoteDirectory"] = fun(staging: File, destination: File) {
  val backup = File(destination.parentFile, "${destination.name}.backup-${UUID.randomUUID()}")
  val hadDestination = destination.exists()
  try {
    if (hadDestination) {
      Files.move(destination.toPath(), backup.toPath(), StandardCopyOption.ATOMIC_MOVE)
    }
    try {
      Files.move(staging.toPath(), destination.toPath(), StandardCopyOption.ATOMIC_MOVE)
    } catch (promotionFailure: Exception) {
      if (hadDestination && backup.exists()) {
        try {
          Files.move(backup.toPath(), destination.toPath(), StandardCopyOption.ATOMIC_MOVE)
        } catch (restoreFailure: Exception) {
          promotionFailure.addSuppressed(restoreFailure)
        }
      }
      throw promotionFailure
    }
    if (hadDestination && backup.exists() && !backup.deleteRecursively()) {
      throw GradleException("Failed to remove obsolete native artifact backup at ${backup.absolutePath}")
    }
  } finally {
    staging.deleteRecursively()
  }
}
