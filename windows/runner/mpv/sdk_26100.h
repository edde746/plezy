#ifndef SDK_26100_H_
#define SDK_26100_H_

// Win11 24H2 (SDK 10.0.26100.0) struct shims for HDR APIs.
// These types may not be present in older Windows SDK versions.
// Based on Kodi's SDK_26100.h (xbmc/platform/win32/SDK_26100.h).

#include <Windows.h>

// Only define these if the SDK doesn't already have them (SDK < 10.0.26100.0).
#ifndef NTDDI_WIN11_GE

enum {
  DISPLAYCONFIG_DEVICE_INFO_SET_RESERVED1 = 14,
  DISPLAYCONFIG_DEVICE_INFO_GET_ADVANCED_COLOR_INFO_2 = 15,
  DISPLAYCONFIG_DEVICE_INFO_SET_HDR_STATE = 16,
  DISPLAYCONFIG_DEVICE_INFO_SET_WCG_STATE = 17,
};

typedef enum _DISPLAYCONFIG_ADVANCED_COLOR_MODE {
  DISPLAYCONFIG_ADVANCED_COLOR_MODE_SDR,
  DISPLAYCONFIG_ADVANCED_COLOR_MODE_WCG,
  DISPLAYCONFIG_ADVANCED_COLOR_MODE_HDR
} DISPLAYCONFIG_ADVANCED_COLOR_MODE;

typedef struct _DISPLAYCONFIG_GET_ADVANCED_COLOR_INFO_2 {
  DISPLAYCONFIG_DEVICE_INFO_HEADER header;
  union {
    struct {
      UINT32 advancedColorSupported : 1;
      UINT32 advancedColorActive : 1;
      UINT32 reserved1 : 1;
      UINT32 advancedColorLimitedByPolicy : 1;
      UINT32 highDynamicRangeSupported : 1;
      UINT32 highDynamicRangeUserEnabled : 1;
      UINT32 wideColorSupported : 1;
      UINT32 wideColorUserEnabled : 1;
      UINT32 reserved : 24;
    };
    UINT32 value;
  };
  DISPLAYCONFIG_COLOR_ENCODING colorEncoding;
  UINT32 bitsPerColorChannel;
  DISPLAYCONFIG_ADVANCED_COLOR_MODE activeColorMode;
} DISPLAYCONFIG_GET_ADVANCED_COLOR_INFO_2;

typedef struct _DISPLAYCONFIG_SET_HDR_STATE {
  DISPLAYCONFIG_DEVICE_INFO_HEADER header;
  union {
    struct {
      UINT32 enableHdr : 1;
      UINT32 reserved : 31;
    };
    UINT32 value;
  };
} DISPLAYCONFIG_SET_HDR_STATE;

#endif  // NTDDI_WIN11_GE

// DisplayConfig virtual-refresh-rate awareness flags for Dynamic Refresh Rate
// (Win11 22H2+, SDK 10.0.22621.0+). Guarded individually because, unlike the
// 24H2 structs above, older SDKs (10.0.19041.0) lack them while 22621 has
// them without NTDDI_WIN11_GE.
#ifndef QDC_VIRTUAL_REFRESH_RATE_AWARE
#define QDC_VIRTUAL_REFRESH_RATE_AWARE 0x00000040
#endif

#ifndef SDC_VIRTUAL_REFRESH_RATE_AWARE
#define SDC_VIRTUAL_REFRESH_RATE_AWARE 0x00020000
#endif

#endif  // SDK_26100_H_
