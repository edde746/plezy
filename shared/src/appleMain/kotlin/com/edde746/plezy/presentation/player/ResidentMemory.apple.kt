package com.edde746.plezy.presentation.player

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.alloc
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.reinterpret
import kotlinx.cinterop.sizeOf
import kotlinx.cinterop.value
import platform.darwin.KERN_SUCCESS
import platform.darwin.MACH_TASK_BASIC_INFO
import platform.darwin.integer_tVar
import platform.darwin.mach_msg_type_number_tVar
import platform.darwin.mach_task_basic_info_data_t
import platform.darwin.mach_task_self_
import platform.darwin.task_info

/** The task's resident size (`MACH_TASK_BASIC_INFO`). */
@OptIn(ExperimentalForeignApi::class)
internal actual fun residentMemoryBytes(): Long? = memScoped {
    val info = alloc<mach_task_basic_info_data_t>()
    val count = alloc<mach_msg_type_number_tVar>()
    count.value = (sizeOf<mach_task_basic_info_data_t>() / sizeOf<integer_tVar>()).toUInt()
    val result = task_info(mach_task_self_, MACH_TASK_BASIC_INFO.toUInt(), info.ptr.reinterpret(), count.ptr)
    if (result == KERN_SUCCESS) info.resident_size.toLong() else null
}
