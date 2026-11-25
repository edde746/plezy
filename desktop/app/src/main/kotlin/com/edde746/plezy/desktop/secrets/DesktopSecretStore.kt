package com.edde746.plezy.desktop.secrets

import com.edde746.plezy.secrets.SecretStore
import java.nio.file.Path

/**
 * The [SecretStore] of the OS the app runs on: Windows Credential Manager ([WindowsCredentialStore]) or, on Linux, the
 * freedesktop Secret Service through libsecret with [SECRETS_FILE] in [directory] (the app's data folder) where the
 * session has none ([LinuxSecretStore]). Nothing native is loaded until the first call.
 */
internal fun desktopSecretStore(directory: Path): SecretStore {
    val os = System.getProperty("os.name")
    return when {
        os.startsWith("Windows") -> WindowsCredentialStore()
        os.startsWith("Linux") -> LinuxSecretStore(LibsecretStore(), SecretFile(directory.resolve(SECRETS_FILE)))
        else -> throw UnsupportedOperationException("No secret store for $os: the desktop app supports Windows and Linux")
    }
}

/** The Linux secrets' file without a Secret Service, in the app's data folder. */
internal const val SECRETS_FILE = "secrets.properties"
