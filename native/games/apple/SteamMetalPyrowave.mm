// SPDX-License-Identifier: GPL-3.0-or-later
#include "SteamMetalPyrowave.h"
#include "pyrowave_metal.h"
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <array>

namespace plezy::steam {
namespace {
// The color tags are checked by the portable parser. This pipeline only
// accepts sRGB/BT.709 SDR; HDR requires a different display surface.
constexpr char convertShader[] = R"metal(
#include <metal_stdlib>
using namespace metal;
struct Parameters { uint fullRange; uint chroma444; uint chromaLeft; uint unused; };
kernel void convert(texture2d<float,access::read> y [[texture(0)]],
                    texture2d<float,access::sample> cb [[texture(1)]],
                    texture2d<float,access::sample> cr [[texture(2)]],
                    texture2d<float,access::write> rgb [[texture(3)]],
                    constant Parameters& p [[buffer(0)]], uint2 pos [[thread_position_in_grid]]) {
  if (pos.x >= rgb.get_width() || pos.y >= rgb.get_height()) return;
  constexpr sampler chroma(coord::pixel, address::clamp_to_edge, filter::linear);
  float2 uv = float2(pos) + .5f;
  if (!p.chroma444) uv = uv * .5f + float2(p.chromaLeft ? .25f : 0.f,0.f);
  float luma = y.read(pos).r;
  float u = cb.sample(chroma,uv).r - (128.f/255.f);
  float v = cr.sample(chroma,uv).r - (128.f/255.f);
  if (!p.fullRange) { luma = (luma - 16.f/255.f) * (255.f/219.f); u *= 255.f/224.f; v *= 255.f/224.f; }
  float3 value(luma + 1.5748f*v, luma - .187324f*u - .468124f*v, luma + 1.8556f*u);
  rgb.write(float4(clamp(value,0.f,1.f),1.f),pos);
}
)metal";
}
struct MetalPyrowave::Impl {
  id<MTLDevice> gpu;
  id<MTLCommandQueue> queue;
  id<MTLComputePipelineState> conversion;
  std::array<id<MTLTexture>,3> planes;
  pyrowave_device device = nullptr;
  pyrowave_decoder decoder = nullptr;
  CVMetalTextureCacheRef cache = nullptr;
  CVPixelBufferPoolRef pool = nullptr;
  int width = 0, height = 0;
  bool chroma444 = false;
  ~Impl() { reset(); }
  void reset() {
    if (decoder) pyrowave_decoder_destroy(decoder);
    if (device) pyrowave_device_destroy(device);
    decoder = nullptr; device = nullptr;
    planes.fill(nil); conversion = nil; queue = nil; gpu = nil;
    if (pool) CVPixelBufferPoolRelease(pool);
    if (cache) CFRelease(cache);
    pool = nullptr; cache = nullptr; width = height = 0;
  }
  bool configure(const PyrowaveFrameInfo& info) {
    if (decoder) return chroma444 == info.chroma444;
    chroma444 = info.chroma444;
    pyrowave_decoder_create_info config{};
    config.device = device; config.width = width; config.height = height;
    config.chroma = chroma444 ? PYROWAVE_CHROMA_SUBSAMPLING_444 : PYROWAVE_CHROMA_SUBSAMPLING_420;
    if (pyrowave_decoder_create(&config,&decoder) != PYROWAVE_SUCCESS) return false;
    for (size_t i = 0; i < planes.size(); ++i) {
      const bool subsampled = i && !chroma444;
      auto spec = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR16Unorm
          width:width/(subsampled ? 2 : 1) height:height/(subsampled ? 2 : 1) mipmapped:NO];
      spec.storageMode = MTLStorageModePrivate;
      spec.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
      planes[i] = [gpu newTextureWithDescriptor:spec];
      if (!planes[i]) return false;
    }
    return true;
  }
};
MetalPyrowave::MetalPyrowave() : impl_(std::make_unique<Impl>()) {}
MetalPyrowave::~MetalPyrowave() = default;
void MetalPyrowave::reset() { impl_->reset(); }
bool MetalPyrowave::chroma444() const { return impl_->chroma444; }
bool MetalPyrowave::supported() {
  @autoreleasepool {
    auto gpu = MTLCreateSystemDefaultDevice();
    return gpu && pyrowave_device_is_supported((__bridge void*)gpu);
  }
}
bool MetalPyrowave::start(int width,int height,const uint8_t* extra,size_t length) {
  reset();
  if (width < 2 || height < 2 || width > 1920 || height > 1080 || (width & 1) || (height & 1) ||
      length > 2*1024*1024 || (length && !extra)) return false;
  impl_->width = width; impl_->height = height;
  impl_->gpu = MTLCreateSystemDefaultDevice();
  if (!impl_->gpu || !pyrowave_device_is_supported((__bridge void*)impl_->gpu)) return false;
  pyrowave_device_create_info info{};
  info.mtl_device = (__bridge void*)impl_->gpu;
  info.message_callback = [](void*,const char*) {}; // No host bitstream/details in application logs.
  if (pyrowave_device_create(&info,&impl_->device) != PYROWAVE_SUCCESS) return false;
  impl_->queue = [impl_->gpu newCommandQueue];
  auto library = [impl_->gpu newLibraryWithSource:@(convertShader) options:nil error:nil];
  auto function = [library newFunctionWithName:@"convert"];
  if (!impl_->queue || !function) return false;
  impl_->conversion = [impl_->gpu newComputePipelineStateWithFunction:function error:nil];
  if (!impl_->conversion || impl_->conversion.maxTotalThreadsPerThreadgroup < 64) return false;
  if (CVMetalTextureCacheCreate(kCFAllocatorDefault,nullptr,impl_->gpu,nullptr,&impl_->cache) != kCVReturnSuccess) return false;
  NSDictionary* attributes = @{
    (__bridge NSString*)kCVPixelBufferWidthKey:@(width), (__bridge NSString*)kCVPixelBufferHeightKey:@(height),
    (__bridge NSString*)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
    (__bridge NSString*)kCVPixelBufferIOSurfacePropertiesKey:@{}, (__bridge NSString*)kCVPixelBufferMetalCompatibilityKey:@YES,
  };
  if (CVPixelBufferPoolCreate(kCFAllocatorDefault,nullptr,(__bridge CFDictionaryRef)attributes,&impl_->pool) != kCVReturnSuccess) return false;
  if (length) {
    PyrowaveFrameInfo frame;
    if (!parsePyrowaveFrame(extra,length,width,height,frame,true) || !impl_->configure(frame) ||
        pyrowave_decoder_push_packet(impl_->decoder,extra,length) != PYROWAVE_SUCCESS) return false;
  }
  return true;
}
PyrowaveDecodeStatus MetalPyrowave::decode(const uint8_t* bytes,size_t length,CVPixelBufferRef* output) {
  if (!output) return PyrowaveDecodeStatus::invalid;
  *output = nullptr;
  PyrowaveFrameInfo frame;
  if (!impl_->device || !impl_->pool || !parsePyrowaveFrame(bytes,length,impl_->width,impl_->height,frame,true) ||
      !impl_->configure(frame) || pyrowave_decoder_push_packet(impl_->decoder,bytes,length) != PYROWAVE_SUCCESS)
    return PyrowaveDecodeStatus::invalid;
  if (!pyrowave_decoder_decode_is_ready(impl_->decoder,false)) return PyrowaveDecodeStatus::pending;
  CVPixelBufferRef pixel = nullptr;
  NSDictionary* limit = @{(__bridge NSString*)kCVPixelBufferPoolAllocationThresholdKey:@4};
  auto result = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault,impl_->pool,(__bridge CFDictionaryRef)limit,&pixel);
  if (result == kCVReturnWouldExceedAllocationThreshold) return PyrowaveDecodeStatus::pending;
  if (result != kCVReturnSuccess || !pixel) return PyrowaveDecodeStatus::invalid;
  CVMetalTextureRef surface = nullptr;
  NSDictionary* attributes = @{(__bridge NSString*)kCVMetalTextureUsage:@(MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite)};
  result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,impl_->cache,pixel,(__bridge CFDictionaryRef)attributes,
      MTLPixelFormatBGRA8Unorm,impl_->width,impl_->height,0,&surface);
  bool success = false;
  if (result == kCVReturnSuccess && surface) {
    auto command = [impl_->queue commandBuffer];
    pyrowave_gpu_buffers planes{};
    for (size_t i = 0; i < 3; ++i) planes.planes[i] = (__bridge void*)impl_->planes[i];
    if (command && pyrowave_decoder_decode_gpu_buffer(impl_->decoder,(__bridge void*)command,&planes) == PYROWAVE_SUCCESS) {
      auto convert = [command computeCommandEncoder];
      if (convert) {
        [convert setComputePipelineState:impl_->conversion];
        for (size_t i = 0; i < 3; ++i) [convert setTexture:impl_->planes[i] atIndex:i];
        [convert setTexture:CVMetalTextureGetTexture(surface) atIndex:3];
        const uint32_t params[] = {frame.fullRange,frame.chroma444,frame.chromaLeft,0};
        [convert setBytes:params length:sizeof(params) atIndex:0];
        [convert dispatchThreadgroups:MTLSizeMake((impl_->width+7)/8,(impl_->height+7)/8,1) threadsPerThreadgroup:MTLSizeMake(8,8,1)];
        [convert endEncoding];
        // Serial worker bounds submissions; the raster thread receives only a
        // finished pixel buffer. No GPU pixels are mapped or copied to the CPU.
        [command commit]; [command waitUntilCompleted];
        success = command.status == MTLCommandBufferStatusCompleted;
      }
    }
  }
  if (surface) CFRelease(surface);
  CVMetalTextureCacheFlush(impl_->cache,0);
  if (!success) { CVPixelBufferRelease(pixel); return PyrowaveDecodeStatus::invalid; }
  *output = pixel;
  return PyrowaveDecodeStatus::frame;
}
}
