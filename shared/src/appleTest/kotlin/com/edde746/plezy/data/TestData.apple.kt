package com.edde746.plezy.data

internal actual fun inMemoryDatabase(): DatabaseFactory = DatabaseFactory.inMemory()

internal actual fun fileDatabase(): FileDatabase {
    val dir = kotlinx.io.files.Path(kotlinx.io.files.SystemTemporaryDirectory, "plezy-db-${platform.Foundation.NSUUID().UUIDString}")
    kotlinx.io.files.SystemFileSystem.createDirectories(dir)
    return FileDatabase(DatabaseFactory(dir.toString()), kotlinx.io.files.Path(dir, DATABASE_FILE_NAME))
}
