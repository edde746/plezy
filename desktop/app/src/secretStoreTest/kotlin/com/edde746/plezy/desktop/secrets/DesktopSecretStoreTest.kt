package com.edde746.plezy.desktop.secrets

import com.edde746.plezy.secrets.SecretStore
import com.edde746.plezy.secrets.SecretStoreContract
import java.nio.file.Files

/**
 * The contract against this OS's store: Windows Credential Manager or libsecret (`:app-desktop:secretStoreTest`), its
 * Linux fallback file in a folder of this run's own.
 */
class DesktopSecretStoreTest : SecretStoreContract() {
    override fun createStore(): SecretStore = desktopSecretStore(directory)

    private companion object {
        val directory = Files.createTempDirectory("plezy-secrets")
    }
}
