package com.edde746.plezy.data

internal actual fun inMemoryDatabase(): DatabaseFactory = DatabaseFactory.inMemory()

internal actual fun fileDatabase(): FileDatabase {
    val file = java.nio.file.Files.createTempDirectory("plezy-db").resolve(DATABASE_FILE_NAME)
    return FileDatabase(DatabaseFactory(file), kotlinx.io.files.Path(file.toString()))
}
