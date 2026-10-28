// SPDX-License-Identifier: AGPL-3.0-only
#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
NS_ASSUME_NONNULL_BEGIN
#ifdef __cplusplus
extern "C" {
#endif
BOOL PlezyVisualizationTapAvailable(void);
int PlezyVisualizationTapEnable(void* player, BOOL enabled);
int PlezyVisualizationTapRead(void* player, double pts, void* output, size_t size);
#ifdef __cplusplus
}
#endif

@interface PlezyMilkRustHost : NSObject
+ (NSString*)dependencyError;
- (nullable instancetype)initWithAudioReader:(int (^)(void*, size_t))reader
    frameAvailable:(void (^)(void))frameAvailable error:(NSError* _Nullable* _Nullable)error;
- (BOOL)loadPreset:(NSString*)path root:(NSString*)root error:(NSError* _Nullable* _Nullable)error;
- (void)resizeWidth:(NSInteger)width height:(NSInteger)height;
- (void)setPaused:(BOOL)paused;
- (NSDictionary<NSString*, id>*)status;
- (nullable CVPixelBufferRef)copyPixelBuffer CF_RETURNS_RETAINED;
- (void)close;
@end
NS_ASSUME_NONNULL_END
