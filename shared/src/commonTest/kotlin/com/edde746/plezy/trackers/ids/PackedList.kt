package com.edde746.plezy.trackers.ids

/**
 * Writes anime-mappings' packed list (unpacked) as its README's "The format" lays it out, for tests: [file] of
 * [table]s of [column]s, each column's data from the type's own writer ([ints], [intDeltas], [strs], [dict],
 * [intLists], [strLists]; `null` for an absent value).
 */
internal object PackedList {
    fun file(vararg tables: ByteArray, magic: String = "AMAP", version: Int = 1): ByteArray =
        magic.encodeToByteArray() + byteArrayOf(version.toByte()) + varint(tables.size.toLong()) + tables.join()

    fun table(name: String, rows: Int, vararg columns: ByteArray): ByteArray =
        string(name) + varint(rows.toLong()) + varint(columns.size.toLong()) + columns.join()

    fun column(name: String, type: Int, data: ByteArray): ByteArray =
        string(name) + byteArrayOf(type.toByte()) + varint(data.size.toLong()) + data

    fun ints(vararg values: Long?): ByteArray = values.map { v -> v?.let { varint(zigzag(it) + 1) } ?: absent }.join()

    fun intDeltas(vararg values: Long?): ByteArray {
        var previous = 0L
        return values.map { v ->
            if (v == null) return@map absent
            varint(zigzag(v - previous) + 1).also { previous = v }
        }.join()
    }

    fun strs(vararg values: String?): ByteArray =
        values.map { v -> v?.encodeToByteArray()?.let { varint(it.size + 1L) + it } ?: absent }.join()

    /** The dictionary in the order the values first appear. */
    fun dict(vararg values: String?): ByteArray {
        val words = values.filterNotNull().distinct()
        return varint(words.size.toLong()) + words.map(::string).join() +
            values.map { v -> v?.let { varint(words.indexOf(it) + 1L) } ?: absent }.join()
    }

    fun intLists(vararg values: List<Long>?): ByteArray =
        values.map { v -> v?.let { list -> varint(list.size + 1L) + list.map { varint(zigzag(it)) }.join() } ?: absent }.join()

    fun strLists(vararg values: List<String>?): ByteArray =
        values.map { v -> v?.let { list -> varint(list.size + 1L) + list.map(::string).join() } ?: absent }.join()

    fun string(s: String): ByteArray = s.encodeToByteArray().let { varint(it.size.toLong()) + it }

    fun varint(n: Long): ByteArray {
        val out = ArrayList<Byte>()
        var rest = n
        while (rest ushr 7 != 0L) {
            out += ((rest and 0x7F) or 0x80).toByte()
            rest = rest ushr 7
        }
        out += rest.toByte()
        return out.toByteArray()
    }

    private fun zigzag(n: Long): Long = (n shl 1) xor (n shr 63)

    private val absent = byteArrayOf(0)

    private fun Array<out ByteArray>.join(): ByteArray = toList().join()

    private fun List<ByteArray>.join(): ByteArray = fold(ByteArray(0)) { acc, b -> acc + b }
}

/** anime-mappings' file built from the excerpt, as released (gzipped); its source: [AnimeMappingIndexTest]. */
internal fun animeMappingsExcerpt(): ByteArray = ANIME_MAPPINGS_EXCERPT_HEX.hexToByteArray()

/** [animeMappingsExcerpt]'s bytes, `xxd -p` of the gzipped file. */
private const val ANIME_MAPPINGS_EXCERPT_HEX =
    "1f8b08000000000002ff95560d6c14c7159ed9b9ddbbbdf3c53e1b0cc8382c210958edd8fb7f7b9e4615ae9a1f2504542855a4a6eefa6e8c57bebb3d" +
    "eded615c54a9563017b06883dac44a5d621c5445244a29519c0a45294a1d871214a5529ab6a99ba22aa50a4228a2124d1be4aab37b8eedd486c8a399" +
    "d9d979df7bf3de9bf7deeed66d5b77c008dfeb393d3df58d117fb04423ad88dbb59bdfb67df7035f47db776f85908310c1e081d888d94527d7d3ede4" +
    "b8f51d8fbeda38b5f152e390f461eb73cdd32d93f0a470115e499de4c6560b053b1f805a51dbd3cdbf8b5d15afea13df3d7f0a5647e18dc8954630d9" +
    "7e4d38a9c4fa1dbf5c0985a135c3abfe199d8d7d70f7c52d93cd55eb04772c0ec6d68da2e157511d3bb34c6d2fdb1742cfaf1d8fbf95ba76e744e4c3" +
    "4d7f6b9c9566d6a55f8f8113ab2ea14f56c71934ef94fd2567bf360c875a074ff0e0ed73e24c6cf2299862c802cdba95a29f73078a01c3dd535391d1" +
    "b5c757fd5abcb8e1f9a68fbffce223efbd42ce8cc3b3cf0b93ff86437f4dcebec91d1b6b8f959d427f7e050c4de151453a502e527fc0f5fa43335a3e" +
    "ae7bb6ee4cf754fc887e5a7e61cba9db1f13ae47c078eb29f8f3d6babcb39766fb6c2f3464fda4f192fcfab70fb7b9d7e171f3007abf65ff58a40acf" +
    "8aefc269dae0f7d182bbd7a1e1adb4fb7be1e6f1bfa3d7de8980ab6fc05a9f7c977fe76cf4c98331c046ad836b67124d9fe70c97fc5a00b8672f4440" +
    "d8b8972771f0f8cb1fee0151a710e2845f424ef47d5955344db3c2a56659a69a416ca9645439a3cbc1a66cb1b519d233a66aa9b758321e4b55e560a9" +
    "99aa92ce84bb86a99ab21a9e60688a6228faffef2ebb4ca77543362d2eceb4514c4bd64d2beaef0d55876d2f9c1647fe2b82cb3362ad4fffe3f6e9a1" +
    "3b2e3d73176063be4f5cc709166f65b7d81e70c27a040042900dc0c32844f3c4c21222404db4e494dd1ced767b7bcbd49f931078735d7dcdab200a96" +
    "800a4b400024c2b0e90ec2b95c7f5b344cbc2fccbbe0b895595ae3e8f6e93e3fd20cf9300c0080351d6a8f548ef6da95bc1f406bb62ff149f312484d" +
    "622384764d0afcccaee49cf135db97f846089cb182308e07f865b502a87e8176537542fe657501355d9cdccdb342704280c036b885f89fc32d44eedc" +
    "db5c6c8248d12e503484925f73077adc41a98bf6b8a5f8f622957638344bd7dce714f7d8d22eca8a63cead4845577ac4f52ac9aebc9ded971eb2f7b8" +
    "6e71e3e2974e69571f9576b26a56cc495db6e7d97be89d9f077cc3eda19e6f6f2e4b5d79d7cd49bb3cdbc9afb99f553fea49fba4b9c516555694b6f6" +
    "7b6d9f76ecf4ed41e961674f9fdf297db398770a8e4f99f4bc9da3d2b758112b8768bdadb9cbed0f75bc9f7aaeb435cbe805c7ae7f903104bb0fdbd2" +
    "80dddeba2c2894906ebb05d1bc15d16a939727b2c2266d0be2b853bab7e2db9ef319a4e13e8fdabeb4c3a33e2de6a827f4d05ed7a368e1c66b6dd5a2" +
    "d4eb2ed8a512bb9072676c3e07bb3a1e852b69b35a2d5d217cae194e6cba085f6c4b84b2e6e2b6937d6257d2e01c9ecdf14549c9c480651be2a36222" +
    "599f6a5abd665d4beb868d9beedadcf625dc1188e1a3c1d79d5f9c459d3763005fd8f83273b70f6d04d0f78fc133b0ca4d7087d005743472829fe54f" +
    "0b6f0ba3b111b11abf129f499caffb20f99fe46329d4f4557bff9179f039748441a7a323b1aa7845fc63e2e91036db70a8313064e0c71ce001d880d8" +
    "fdc16c14ec1f83bf82c3dc385745e7d18f2213fc0dfe947041783276481c8e5f8ebf9f38573793fc243994aa36a6eee91e1c99474fa311869d8a1e8a" +
    "0d8b97c5f712a321ee4643353806548e722739d002408730571a9849f07b3f85afc003dc33dc41f45bf4c3c871fe53fe17c25bc24f628f8b07e21fc5" +
    "ff9478b3eecfc97f257f90820d5ff9cebec3f3e037d06106fd4df4f1d801f123f1f789a742d8a70d07c3b3fc2738c001b03e12542874140944c732f9" +
    "194714aca6898a35a2e10cdb53646260452726a3a6d9b0d8c8b0a1c8c1a404931a4c5a3005221423984cac2944496355238a85559d2819ac5a4495b1" +
    "9a21aa823599a8019faa614d25aa8e359da801a7ca384da2a6b1c6b4b0b0ce763258578826635d259a8275a6998a759d681ad60da2e9584f13cdc0ba" +
    "453413eb19a2a5b12113cdc206e3ca604325ba8c0d8de80a3674a2abd83088ae61c324ba8e8d34d1836375131b16d1192b33dac226dbc9605321868c" +
    "4d95180a36350256d2041288bd8db9d360de349937d3a49904fe0acc0ebc15382bc08460052b247ca84408bd0fd62eae06e54aa994a7ec77ceb7f370" +
    "a122c00ebe27ef66fb594a453d5a62b59746d8a546690d1b11a150f62b39c785b56b8ec576568a1efbad4539a7102085ac9b77bd72c854f2282b5e03" +
    "ec43f63f39795e87a10b0000"

/** [animeMappingsExcerpt]'s indexes. */
internal val ANIME_MAPPINGS_EXCERPT: AnimeMappingIndexes by lazy { AnimeMappings.read(gunzip(animeMappingsExcerpt())) }
