package com.edde746.plezy.data

import androidx.test.platform.app.InstrumentationRegistry

internal actual fun inMemoryDatabase(): DatabaseFactory =
    DatabaseFactory.inMemory(InstrumentationRegistry.getInstrumentation().targetContext)

internal actual fun fileDatabase(): FileDatabase {
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    val name = "test-${java.util.UUID.randomUUID()}.db"
    return FileDatabase(DatabaseFactory.named(context, name), kotlinx.io.files.Path(context.getDatabasePath(name).path))
}
