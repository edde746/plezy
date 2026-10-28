// SPDX-License-Identifier: GPL-3.0-or-later
#import <XCTest/XCTest.h>
#include "SteamAppleSink.h"
#include "../steam/tests/red_h264.h"
#include <condition_variable>

@interface SteamAppleSinkTests : XCTestCase
@end
@implementation SteamAppleSinkTests
- (void)testRealH264PixelsAndTeardown {
  std::mutex mutex;
  std::condition_variable ready;
  bool failed = false, presented = false, red = false;
  plezy::steam::AppleSink sink([&](CVPixelBufferRef image,uint32_t id) {
    bool valid = id == 7 && CVPixelBufferGetWidth(image) == 64 && CVPixelBufferGetHeight(image) == 64;
    if (CVPixelBufferLockBaseAddress(image,kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess) {
      auto* pixel = static_cast<const uint8_t*>(CVPixelBufferGetBaseAddress(image));
      valid = valid && pixel && pixel[0] < 50 && pixel[1] < 50 && pixel[2] > 200 && pixel[3] == 255;
      CVPixelBufferUnlockBaseAddress(image,kCVPixelBufferLock_ReadOnly);
    } else valid = false;
    { std::lock_guard<std::mutex> lock(mutex); red = valid; presented = true; }
    ready.notify_one(); return true;
  },[](uint32_t,bool) {},[&](bool) {
    { std::lock_guard<std::mutex> lock(mutex); failed = true; }
    ready.notify_one();
  });
  XCTAssertFalse(sink.video(IHS_StreamVideoCodecPyrowave,64,64,nullptr,0));
  XCTAssertFalse(sink.video(IHS_StreamVideoCodecH264,100000,64,nullptr,0));
  XCTAssertFalse(sink.frame(redH264,2*1024*1024+1,1,true));
  XCTAssertTrue(sink.video(IHS_StreamVideoCodecH264,64,64,nullptr,0));
  XCTAssertTrue(sink.frame(redH264,sizeof(redH264),7,true));
  {
    std::unique_lock<std::mutex> lock(mutex);
    ready.wait_for(lock,std::chrono::seconds(5),[&]{ return failed || presented; });
    XCTAssertFalse(failed);
    XCTAssertTrue(presented && red);
  }
  sink.close(); sink.close();
  XCTAssertFalse(sink.frame(redH264,sizeof(redH264),8,true));
}
@end
