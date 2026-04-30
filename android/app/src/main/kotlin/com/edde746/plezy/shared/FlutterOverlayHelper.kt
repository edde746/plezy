package com.edde746.plezy.shared

import android.graphics.PixelFormat
import android.os.Build
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup

object FlutterOverlayHelper {

    /**
     * Find the top-level container holding the Flutter render surface. Returns the
     * direct child of [contentView] that contains a FlutterSurfaceView/FlutterTextureView
     * at any depth — `bringChildToFront` only works for direct children, so this is the
     * node to pass to [configureFlutterZOrder].
     *
     * Searches any depth because an app may wrap Flutter (e.g. for key-event dispatch)
     * and push it below the direct-child level.
     */
    fun findFlutterContainer(contentView: ViewGroup, excludeView: View? = null): ViewGroup? {
        for (i in contentView.childCount - 1 downTo 0) {
            val child = contentView.getChildAt(i)
            if (child === excludeView || child !is ViewGroup) continue
            if (findRenderSurface(child) != null) return child
        }
        return null
    }

    private fun findRenderSurface(root: ViewGroup): View? {
        for (i in 0 until root.childCount) {
            val child = root.getChildAt(i)
            if (child is SurfaceView || child is TextureView) return child
            if (child is ViewGroup) findRenderSurface(child)?.let { return it }
        }
        return null
    }

    /**
     * Apply [SurfaceView.setCompositionOrder] on API 36+; no-op on older APIs where
     * the legacy [SurfaceView.setZOrderOnTop]/[SurfaceView.setZOrderMediaOverlay]
     * bucket settings govern Z-order instead.
     *
     * The value maps directly to the SurfaceView's `mSubLayer`. Per AOSP semantics:
     * `mSubLayer >= 0` (non-negative `order`) is composited above the parent window
     * and skips the hole-punch in `draw()`; `mSubLayer < 0` (negative `order`) is
     * behind the parent window and the SurfaceView is made visible by punching a
     * transparent hole in the parent canvas. Valid range is `[-2, 2]`. Picking the
     * right sign matters: any view that draws on the parent canvas (e.g. Media3's
     * `CanvasSubtitleOutput` for SRT/VTT/SDH) is hidden by SurfaceViews with
     * non-negative orders that sit on top of the same area.
     */
    fun applyCompositionOrder(view: SurfaceView, order: Int) {
        if (Build.VERSION.SDK_INT >= 36) view.compositionOrder = order
    }

    /**
     * Configure z-ordering so the Flutter UI renders above the video/subtitle surfaces.
     *
     * On API 36+ the value is applied via [SurfaceView.setCompositionOrder] and maps
     * directly to `mSubLayer` (see [applyCompositionOrder] for the sign semantics).
     * On pre-36 SurfaceView builds the value is mapped to the legacy on-top bucket
     * when positive. On TextureView builds the value is unused (view hierarchy order
     * handles it).
     *
     * Pass a non-negative value (e.g. `1`) so Flutter renders above the parent canvas
     * and lets the legacy transparent-mode `setZOrderOnTop(true)` semantics carry over.
     */
    fun configureFlutterZOrder(contentView: ViewGroup, container: ViewGroup, compositionOrder: Int) {
        contentView.bringChildToFront(container)
        when (val surface = findRenderSurface(container)) {
            is SurfaceView -> {
                if (Build.VERSION.SDK_INT >= 36) {
                    // Clear legacy bucket hints so compositionOrder is authoritative.
                    // Flutter's FlutterSurfaceView sets setZOrderOnTop(true) in its
                    // transparent-mode constructor, which otherwise pins it to z=1.
                    surface.setZOrderOnTop(false)
                    surface.setZOrderMediaOverlay(false)
                    surface.compositionOrder = compositionOrder
                } else {
                    // Pre-36 has 3 coarse sublayer buckets. Put Flutter in the on-top
                    // bucket so it renders above the video (default) and libass subtitle
                    // (media overlay) SurfaceViews. NB: setZOrderMediaOverlay overwrites
                    // mSubLayer internally, so don't call it here or it cancels setZOrderOnTop.
                    surface.setZOrderOnTop(compositionOrder > 0)
                }
                surface.holder.setFormat(PixelFormat.TRANSLUCENT)
            }
            is TextureView -> surface.isOpaque = false
        }
    }
}
