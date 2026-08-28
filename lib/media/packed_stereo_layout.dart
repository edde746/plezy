/// Packed stereo layouts Plezy can pass through without rearranging either eye.
enum PackedStereoLayout {
  unknown,
  mono,
  sideBySideLeftFirst,
  sideBySideRightFirst,
  topBottomLeftFirst,
  topBottomRightFirst;

  bool get isPacked => switch (this) {
    sideBySideLeftFirst || sideBySideRightFirst || topBottomLeftFirst || topBottomRightFirst => true,
    unknown || mono => false,
  };

  bool get isSideBySide => this == sideBySideLeftFirst || this == sideBySideRightFirst;

  static PackedStereoLayout fromMpvStereoInput(String? value) => switch (value) {
    'sbs2l' => sideBySideLeftFirst,
    'sbs2r' => sideBySideRightFirst,
    'ab2l' => topBottomLeftFirst,
    'ab2r' => topBottomRightFirst,
    'mono' => mono,
    _ => unknown,
  };
}
