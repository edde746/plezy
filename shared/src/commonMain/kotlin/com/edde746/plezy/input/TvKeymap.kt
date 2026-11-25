package com.edde746.plezy.input

/** D-pad remotes (Android TV, Fire TV, tvOS): no pointer on the video; the remote's keys go through the store's key handling. */
internal object TvKeymap : Keymap {
    override fun click(x: Float, context: InputContext): PlayerCommand? = null

    override fun doubleClick(x: Float, context: InputContext): PlayerCommand? = null
}
