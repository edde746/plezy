// Definitions for symbols the production sources reference but that only exist
// on the target platform, so the host tests can link them.
//
// `mallopt` is bionic API 26+ (M_PURGE is 28+), above libmpv's minSdk, so
// `main.cpp` declares it `__attribute__((weak))` and skips the call on an older
// device. A weak *declaration* only becomes an optional undefined symbol under
// ELF; Mach-O needs `weak_import`, so the host link fails on macOS. Defining a
// no-op here keeps the production declaration correct for the platform it ships
// to instead of adding host-only preprocessor branches to it.
extern "C" int mallopt(int, int) { return 0; }
