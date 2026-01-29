// The MIT License(MIT)
//
// Copyright(c) 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files(the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// NVIDIA Image Scaling v1.0.2 by NVIDIA
// ported to mpv by agyild

// Changelog
// Made it directly operate on LUMA plane, since the original shader was operating
// on LUMA by deriving it from RGB. This should cause a major increase in performance,
// especially on OpenGL 4.0+ renderers

//!HOOK LUMA
//!BIND HOOKED
//!BIND coef_scaler
//!BIND coef_usm
//!DESC NVIDIA Image Scaling and Sharpening v1.0.2
//!COMPUTE 32 24 256 1
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * / 1.0 >
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h

// User variables
#define SHARPNESS 0.25 // Amount of sharpening. 0.0 to 1.0.
#define NIS_THREAD_GROUP_SIZE 256 // May be set to 128 for better performance on NVIDIA hardware, otherwise set to 256. Don't forget to modify the COMPUTE directive accordingly as well (e.g., COMPUTE 32 24 128 1).
#define NIS_HDR_MODE 0 // Must be set to 1 for content with PQ colorspace. 0 or 1.

// Constant variables
#define NIS_BLOCK_WIDTH 32
#define NIS_BLOCK_HEIGHT 24
#define kPhaseCount  64
#define kFilterSize  6
#define kSupportSize 6
#define kPadSize     kSupportSize
#define NIS_SCALE_INT 1
#define NIS_SCALE_FLOAT 1.0f
#define kTilePitch (NIS_BLOCK_WIDTH + kPadSize)
#define kTileSize (kTilePitch * (NIS_BLOCK_HEIGHT + kPadSize))
#define kEdgeMapPitch (NIS_BLOCK_WIDTH + 2)
#define kEdgeMapSize (kEdgeMapPitch * (NIS_BLOCK_HEIGHT + 2))
const float sharpen_slider = clamp(SHARPNESS, 0.0f, 1.0f) - 0.5f;
const float MaxScale = (sharpen_slider >= 0.0f) ? 1.25f : 1.75f;
const float MinScale = (sharpen_slider >= 0.0f) ? 1.25f : 1.0f;
const float LimitScale = (sharpen_slider >= 0.0f) ? 1.25f : 1.0f;
const float kDetectRatio = 2 * 1127.f / 1024.f;
const float kDetectThres = (bool(NIS_HDR_MODE) ? 32.0f : 64.0f) / 1024.0f;
const float kMinContrastRatio = bool(NIS_HDR_MODE) ? 1.5f : 2.0f;
const float kMaxContrastRatio = bool(NIS_HDR_MODE) ? 5.0f : 10.0f;
const float kSharpStartY = bool(NIS_HDR_MODE) ? 0.35f : 0.45f;
const float kSharpEndY = bool(NIS_HDR_MODE) ? 0.55f : 0.9f;
const float kSharpStrengthMin = max(0.0f, 0.4f + sharpen_slider * MinScale * (bool(NIS_HDR_MODE) ? 1.1f : 1.2));
const float kSharpStrengthMax = ((bool(NIS_HDR_MODE) ? 2.2f : 1.6f) + sharpen_slider * MaxScale * 1.8f);
const float kSharpLimitMin = max((bool(NIS_HDR_MODE) ? 0.06f :0.1f), (bool(NIS_HDR_MODE) ? 0.1f : 0.14f) + sharpen_slider * LimitScale * (bool(NIS_HDR_MODE) ? 0.28f : 0.32f));
const float kSharpLimitMax = ((bool(NIS_HDR_MODE) ? 0.6f : 0.5f) + sharpen_slider * LimitScale * 0.6f);
const float kRatioNorm = 1.0f / (kMaxContrastRatio - kMinContrastRatio);
const float kSharpScaleY = 1.0f / (kSharpEndY - kSharpStartY);
const float kSharpStrengthScale = kSharpStrengthMax - kSharpStrengthMin;
const float kSharpLimitScale = kSharpLimitMax - kSharpLimitMin;
const float kContrastBoost = 1.0f;
const float kEps = 1.0f;
#define kScaleX (HOOKED_size.x / target_size.x)
#define kScaleY (HOOKED_size.y / target_size.y)
#define kSrcNormX HOOKED_pt.x
#define kSrcNormY HOOKED_pt.y

// HLSL to GLSL macros
#define saturate(x) clamp(x, 0, 1)
#define lerp(a, b, x) mix(a, b, x)

// CS Shared variables
shared float shPixelsY[kTileSize];
shared float shCoefScaler[kPhaseCount][kFilterSize];
shared float shCoefUSM[kPhaseCount][kFilterSize];
shared vec4 shEdgeMap[kEdgeMapSize];

// Shader code

vec4 GetEdgeMap(float p[4][4], int i, int j) {
	const float g_0 = abs(p[0 + i][0 + j] + p[0 + i][1 + j] + p[0 + i][2 + j] - p[2 + i][0 + j] - p[2 + i][1 + j] - p[2 + i][2 + j]);
	const float g_45 = abs(p[1 + i][0 + j] + p[0 + i][0 + j] + p[0 + i][1 + j] - p[2 + i][1 + j] - p[2 + i][2 + j] - p[1 + i][2 + j]);
	const float g_90 = abs(p[0 + i][0 + j] + p[1 + i][0 + j] + p[2 + i][0 + j] - p[0 + i][2 + j] - p[1 + i][2 + j] - p[2 + i][2 + j]);
	const float g_135 = abs(p[1 + i][0 + j] + p[2 + i][0 + j] + p[2 + i][1 + j] - p[0 + i][1 + j] - p[0 + i][2 + j] - p[1 + i][2 + j]);

	const float g_0_90_max = max(g_0, g_90);
	const float g_0_90_min = min(g_0, g_90);
	const float g_45_135_max = max(g_45, g_135);
	const float g_45_135_min = min(g_45, g_135);

	float e_0_90 = 0;
	float e_45_135 = 0;

	if (g_0_90_max + g_45_135_max == 0)
	{
		return vec4(0, 0, 0, 0);
	}

	e_0_90 = min(g_0_90_max / (g_0_90_max + g_45_135_max), 1.0f);
	e_45_135 = 1.0f - e_0_90;

	bool c_0_90 = (g_0_90_max > (g_0_90_min * kDetectRatio)) && (g_0_90_max > kDetectThres) && (g_0_90_max > g_45_135_min);
	bool c_45_135 = (g_45_135_max > (g_45_135_min * kDetectRatio)) && (g_45_135_max > kDetectThres) && (g_45_135_max > g_0_90_min);
	bool c_g_0_90 = g_0_90_max == g_0;
	bool c_g_45_135 = g_45_135_max == g_45;

	float f_e_0_90 = (c_0_90 && c_45_135) ? e_0_90 : 1.0f;
	float f_e_45_135 = (c_0_90 && c_45_135) ? e_45_135 : 1.0f;

	float weight_0 = (c_0_90 && c_g_0_90) ? f_e_0_90 : 0.0f;
	float weight_90 = (c_0_90 && !c_g_0_90) ? f_e_0_90 : 0.0f;
	float weight_45 = (c_45_135 && c_g_45_135) ? f_e_45_135 : 0.0f;
	float weight_135 = (c_45_135 && !c_g_45_135) ? f_e_45_135 : 0.0f;

	return vec4(weight_0, weight_90, weight_45, weight_135);
}

void LoadFilterBanksSh(int i0, int di) {
	// Load up filter banks to shared memory
	// The work is spread over (kPhaseCount * 2) threads
	for (int i = i0; i < kPhaseCount * 2; i += di)
	{
		int phase = i >> 1;
		int vIdx = i & 1;

		vec4 v = vec4(texelFetch(coef_scaler, ivec2(vIdx, phase), 0));
		int filterOffset = vIdx * 4;
		shCoefScaler[phase][filterOffset + 0] = v.x;
		shCoefScaler[phase][filterOffset + 1] = v.y;
		if (vIdx == 0)
		{
			shCoefScaler[phase][2] = v.z;
			shCoefScaler[phase][3] = v.w;
		}

		v = vec4(texelFetch(coef_usm, ivec2(vIdx, phase), 0));
		shCoefUSM[phase][filterOffset + 0] = v.x;
		shCoefUSM[phase][filterOffset + 1] = v.y;
		if (vIdx == 0)
		{
			shCoefUSM[phase][2] = v.z;
			shCoefUSM[phase][3] = v.w;
		}
	}
}

float CalcLTI(float p0, float p1, float p2, float p3, float p4, float p5, int phase_index)
{
	const bool selector = (phase_index <= kPhaseCount / 2);
	float sel = selector ? p0 : p3;
	const float a_min = min(min(p1, p2), sel);
	const float a_max = max(max(p1, p2), sel);
	sel = selector ? p2 : p5;
	const float b_min = min(min(p3, p4), sel);
	const float b_max = max(max(p3, p4), sel);

	const float a_cont = a_max - a_min;
	const float b_cont = b_max - b_min;

	const float cont_ratio = max(a_cont, b_cont) / (min(a_cont, b_cont) + kEps);
	return (1.0f - saturate((cont_ratio - kMinContrastRatio) * kRatioNorm)) * kContrastBoost;
}

vec4 GetInterpEdgeMap(const vec4 edge[2][2], float phase_frac_x, float phase_frac_y)
{
	vec4 h0 = lerp(edge[0][0], edge[0][1], phase_frac_x);
	vec4 h1 = lerp(edge[1][0], edge[1][1], phase_frac_x);
	return lerp(h0, h1, phase_frac_y);
}

float EvalPoly6(const float pxl[6], int phase_int)
{
	float y = 0.f;
	{
		for (int i = 0; i < 6; ++i)
		{
			y += shCoefScaler[phase_int][i] * pxl[i];
		}
	}
	float y_usm = 0.f;
	{
		for (int i = 0; i < 6; ++i)
		{
			y_usm += shCoefUSM[phase_int][i] * pxl[i];
		}
	}

	// let's compute a piece-wise ramp based on luma
	const float y_scale = 1.0f - saturate((y * (1.0f / NIS_SCALE_FLOAT) - kSharpStartY) * kSharpScaleY);

	// scale the ramp to sharpen as a function of luma
	const float y_sharpness = y_scale * kSharpStrengthScale + kSharpStrengthMin;

	y_usm *= y_sharpness;

	// scale the ramp to limit USM as a function of luma
	const float y_sharpness_limit = (y_scale * kSharpLimitScale + kSharpLimitMin) * y;

	y_usm = min(y_sharpness_limit, max(-y_sharpness_limit, y_usm));
	// reduce ringing
	y_usm *= CalcLTI(pxl[0], pxl[1], pxl[2], pxl[3], pxl[4], pxl[5], phase_int);

	return y + y_usm;
}

float FilterNormal(const float p[6][6], int phase_x_frac_int, int phase_y_frac_int)
{
	float h_acc = 0.0f;
	for (int j = 0; j < 6; ++j)
	{
		float v_acc = 0.0f;
		for (int i = 0; i < 6; ++i)
		{
			v_acc += p[i][j] * shCoefScaler[phase_y_frac_int][i];
		}
		h_acc += v_acc * shCoefScaler[phase_x_frac_int][j];
	}

	// let's return the sum unpacked -> we can accumulate it later
	return h_acc;
}

float AddDirFilters(float p[6][6], float phase_x_frac, float phase_y_frac, int phase_x_frac_int, int phase_y_frac_int, vec4 w)
{
	float f = 0.f;
	if (w.x > 0.0f)
	{
		// 0 deg filter
		float interp0Deg[6];
		{
			for (int i = 0; i < 6; ++i)
			{
				interp0Deg[i] = lerp(p[i][2], p[i][3], phase_x_frac);
			}
		}
		f += EvalPoly6(interp0Deg, phase_y_frac_int) * w.x;
	}

	if (w.y > 0.0f)
	{
		// 90 deg filter
		float interp90Deg[6];
		{
			for (int i = 0; i < 6; ++i)
			{
				interp90Deg[i] = lerp(p[2][i], p[3][i], phase_y_frac);
			}
		}
		f += EvalPoly6(interp90Deg, phase_x_frac_int) * w.y;
	}
	if (w.z > 0.0f)
	{
		//45 deg filter
		float pphase_b45;
		pphase_b45 = 0.5f + 0.5f * (phase_x_frac - phase_y_frac);

		float temp_interp45Deg[7];
		temp_interp45Deg[1] = lerp(p[2][1], p[1][2], pphase_b45);
		temp_interp45Deg[3] = lerp(p[3][2], p[2][3], pphase_b45);
		temp_interp45Deg[5] = lerp(p[4][3], p[3][4], pphase_b45);
		{
			pphase_b45 = pphase_b45 - 0.5f;
			float a = (pphase_b45 >= 0.f) ? p[0][2] : p[2][0];
			float b = (pphase_b45 >= 0.f) ? p[1][3] : p[3][1];
			float c = (pphase_b45 >= 0.f) ? p[2][4] : p[4][2];
			float d = (pphase_b45 >= 0.f) ? p[3][5] : p[5][3];
			temp_interp45Deg[0] = lerp(p[1][1], a, abs(pphase_b45));
			temp_interp45Deg[2] = lerp(p[2][2], b, abs(pphase_b45));
			temp_interp45Deg[4] = lerp(p[3][3], c, abs(pphase_b45));
			temp_interp45Deg[6] = lerp(p[4][4], d, abs(pphase_b45));
		}

		float interp45Deg[6];
		float pphase_p45 = phase_x_frac + phase_y_frac;
		if (pphase_p45 >= 1)
		{
			for (int i = 0; i < 6; i++)
			{
				interp45Deg[i] = temp_interp45Deg[i + 1];
			}
			pphase_p45 = pphase_p45 - 1;
		}
		else
		{
			for (int i = 0; i < 6; i++)
			{
				interp45Deg[i] = temp_interp45Deg[i];
			}
		}
		f += EvalPoly6(interp45Deg, int(pphase_p45 * 64)) * w.z;
	}
	
	if (w.w > 0.0f)
	{
		//135 deg filter
		float pphase_b135 = 0.5f * (phase_x_frac + phase_y_frac);

		float temp_interp135Deg[7];

		temp_interp135Deg[1] = lerp(p[3][1], p[4][2], pphase_b135);
		temp_interp135Deg[3] = lerp(p[2][2], p[3][3], pphase_b135);
		temp_interp135Deg[5] = lerp(p[1][3], p[2][4], pphase_b135);

		{
			pphase_b135 = pphase_b135 - 0.5f;
			float a = (pphase_b135 >= 0.f) ? p[5][2] : p[3][0];
			float b = (pphase_b135 >= 0.f) ? p[4][3] : p[2][1];
			float c = (pphase_b135 >= 0.f) ? p[3][4] : p[1][2];
			float d = (pphase_b135 >= 0.f) ? p[2][5] : p[0][3];
			temp_interp135Deg[0] = lerp(p[4][1], a, abs(pphase_b135));
			temp_interp135Deg[2] = lerp(p[3][2], b, abs(pphase_b135));
			temp_interp135Deg[4] = lerp(p[2][3], c, abs(pphase_b135));
			temp_interp135Deg[6] = lerp(p[1][4], d, abs(pphase_b135));
		}


		float interp135Deg[6];
		float pphase_p135 = 1 + (phase_x_frac - phase_y_frac);
		if (pphase_p135 >= 1)
		{
			for (int i = 0; i < 6; ++i)
			{
				interp135Deg[i] = temp_interp135Deg[i + 1];
			}
			pphase_p135 = pphase_p135 - 1;
		}
		else
		{
			for (int i = 0; i < 6; ++i)
			{
				interp135Deg[i] = temp_interp135Deg[i];
			}
		}
		f += EvalPoly6(interp135Deg, int(pphase_p135 * 64)) * w.w;
	}
	return f;
}

void hook()
{
	uvec2 blockIdx = gl_WorkGroupID.xy;
	uint threadIdx = gl_LocalInvocationID.x;

	// Figure out the range of pixels from input image that would be needed to be loaded for this thread-block
	int dstBlockX = int(NIS_BLOCK_WIDTH * blockIdx.x);
	int dstBlockY = int(NIS_BLOCK_HEIGHT * blockIdx.y);

	const int srcBlockStartX = int(floor((dstBlockX + 0.5f) * kScaleX - 0.5f));
	const int srcBlockStartY = int(floor((dstBlockY + 0.5f) * kScaleY - 0.5f));
	const int srcBlockEndX = int(ceil((dstBlockX + NIS_BLOCK_WIDTH + 0.5f) * kScaleX - 0.5f));
	const int srcBlockEndY = int(ceil((dstBlockY + NIS_BLOCK_HEIGHT + 0.5f) * kScaleY - 0.5f));

	int numTilePixelsX = srcBlockEndX - srcBlockStartX + kSupportSize - 1;
	int numTilePixelsY = srcBlockEndY - srcBlockStartY + kSupportSize - 1;

	// round-up load region to even size since we're loading in 2x2 batches
	numTilePixelsX += numTilePixelsX & 0x1;
	numTilePixelsY += numTilePixelsY & 0x1;
	const int numTilePixels = numTilePixelsX * numTilePixelsY;

	// calculate the equivalent values for the edge map
	const int numEdgeMapPixelsX = numTilePixelsX - kSupportSize + 2;
	const int numEdgeMapPixelsY = numTilePixelsY - kSupportSize + 2;
	const int numEdgeMapPixels = numEdgeMapPixelsX * numEdgeMapPixelsY;

	// fill in input luma tile (shPixelsY) in batches of 2x2 pixels
	// we use texture gather to get extra support necessary
	// to compute 2x2 edge map outputs too
	{
		for (uint i = threadIdx * 2; i < uint(numTilePixels) >> 1; i += NIS_THREAD_GROUP_SIZE * 2)
		{
			uint py = (i / numTilePixelsX) * 2;
			uint px = i % numTilePixelsX;

			// 0.5 to be in the center of texel
			// - (kSupportSize - 1) / 2 to shift by the kernel support size
			float kShift = 0.5f - (kSupportSize - 1) / 2;

			const float tx = (srcBlockStartX + px + kShift) * kSrcNormX;
			const float ty = (srcBlockStartY + py + kShift) * kSrcNormY;

			float p[2][2];
#ifdef HOOKED_gather
			{
				const vec4 sY = HOOKED_gather(vec2(tx, ty), 0);

				p[0][0] = sY.w;
				p[0][1] = sY.z;
				p[1][0] = sY.x;
				p[1][1] = sY.y;
			}
#else
			for (int j = 0; j < 2; j++)
			{
				for (int k = 0; k < 2; k++)
				{
					const float px = HOOKED_tex(vec2(tx + k * kSrcNormX, ty + j * kSrcNormY)).r;
					p[j][k] = px;
				}
			}
#endif
			const uint idx = py * kTilePitch + px;
			shPixelsY[idx] = float(p[0][0]);
			shPixelsY[idx + 1] = float(p[0][1]);
			shPixelsY[idx + kTilePitch] = float(p[1][0]);
			shPixelsY[idx + kTilePitch + 1] = float(p[1][1]);
		}
	}

	groupMemoryBarrier();
	barrier();

	{
		// fill in the edge map of 2x2 pixels
		for (uint i = threadIdx * 2; i < uint(numEdgeMapPixels) >> 1; i += NIS_THREAD_GROUP_SIZE * 2)
		{
			uint py = (i / numEdgeMapPixelsX) * 2;
			uint px = i % numEdgeMapPixelsX;

			const uint edgeMapIdx = py * kEdgeMapPitch + px;

			uint tileCornerIdx = (py+1) * kTilePitch + px + 1;
			float p[4][4];
			for (int j = 0; j < 4; j++)
			{
				for (int k = 0; k < 4; k++)
				{
					p[j][k] = shPixelsY[tileCornerIdx + j * kTilePitch + k];
				}
			}

			shEdgeMap[edgeMapIdx] = vec4(GetEdgeMap(p, 0, 0));
			shEdgeMap[edgeMapIdx + 1] = vec4(GetEdgeMap(p, 0, 1));
			shEdgeMap[edgeMapIdx + kEdgeMapPitch] = vec4(GetEdgeMap(p, 1, 0));
			shEdgeMap[edgeMapIdx + kEdgeMapPitch + 1] = vec4(GetEdgeMap(p, 1, 1));
		}
	}

	LoadFilterBanksSh(int(threadIdx), NIS_THREAD_GROUP_SIZE);

	groupMemoryBarrier();
	barrier();

	// output coord within a tile
	const ivec2 pos = ivec2(uint(threadIdx) % uint(NIS_BLOCK_WIDTH), uint(threadIdx) / uint(NIS_BLOCK_WIDTH));
	// x coord inside the output image
	const int dstX = dstBlockX + pos.x;
	// x coord inside the input image
	const float srcX = (0.5f + dstX) * kScaleX - 0.5f;
	// nearest integer part
	const int px = int(floor(srcX) - srcBlockStartX);
	// fractional part
	const float fx = srcX - floor(srcX);
	// discretized phase
	const int fx_int = int(fx * kPhaseCount);

	for (int k = 0; k < NIS_BLOCK_WIDTH * NIS_BLOCK_HEIGHT / NIS_THREAD_GROUP_SIZE; ++k)
	{
		// y coord inside the output image
		const int dstY = dstBlockY + pos.y + k * (NIS_THREAD_GROUP_SIZE / NIS_BLOCK_WIDTH);
		// y coord inside the input image
		const float srcY = (0.5f + dstY) * kScaleY - 0.5f;

		// nearest integer part
		const int py = int(floor(srcY) - srcBlockStartY);
		// fractional part
		const float fy = srcY - floor(srcY);
		// discretized phase
		const int fy_int = int(fy * kPhaseCount);

		// generate weights for directional filters
		const int startEdgeMapIdx = py * kEdgeMapPitch + px;
		vec4 edge[2][2];
		for (int i = 0; i < 2; i++)
		{
			for (int j = 0; j < 2; j++)
			{
				// need to shift edge map sampling since it's a 2x2 centered inside 6x6 grid
				edge[i][j] = shEdgeMap[startEdgeMapIdx + (i * kEdgeMapPitch) + j];
			}
		}
		const vec4 w = GetInterpEdgeMap(edge, fx, fy) * NIS_SCALE_INT;

		// load 6x6 support to regs
		const int startTileIdx = py * kTilePitch + px;
		float p[6][6];
		{
			for (int i = 0; i < 6; ++i)
			{
				for (int j = 0; j < 6; ++j)
				{
					p[i][j] = shPixelsY[startTileIdx + i * kTilePitch + j];
				}
			}
		}

		// weigth for luma
		const float baseWeight = NIS_SCALE_FLOAT - w.x - w.y - w.z - w.w;

		// final luma is a weighted product of directional & normal filters
		float opY = 0;

		// get traditional scaler filter output
		opY += FilterNormal(p, fx_int, fy_int) * baseWeight;

		// get directional filter bank output
		opY += AddDirFilters(p, fx, fy, fx_int, fy_int, w);

		// do bilinear tap for luma upscaling
		vec4 op = HOOKED_tex(vec2((srcX + 0.5f) * kSrcNormX, (srcY + 0.5f) * kSrcNormY));

		const float corr = opY * (1.0f / NIS_SCALE_FLOAT) - op.r;
		op.x += corr;

		imageStore(out_image, ivec2(dstX, dstY), op);
	}
}

//!TEXTURE coef_scaler
//!SIZE 2 64
//!FORMAT rgba32f
//!FILTER NEAREST
00000000000000000000803f0000000000000000000000000000000000000000ed0d3e3ba91350bc0000803fd044583c89d25ebb0000000000000000000000003b70ce3b16fbcbbcb29d7f3f645ddc3c89d2debb000000000000000000000000e02d103c98dd13bda4df7e3fe7fb293d55c128bc6f12033a00000000000000005bb13f3c812642bd5b427e3ff931663d1ea768bc6f12033a00000000000000001ea7683cfaed6bbdfb5c7d3fbc05923d744694bc6f12033a0000000000000000b9fc873c03098abda3017c3fc5feb23d5839b4bc6f12833a0000000000000000075f983cbf0e9cbdfa7e7a3ff4fdd43dd044d8bca69bc43a00000000000000009eefa73c7b14aebdde02793f22fdf63d4850fcbc6f12033b0000000000000000ec51b83ced0dbebd22fd763f4d840d3ee02d10bd52491d3b0000000000000000efc9c33c5f07cebdb81e753f098a1f3e9c3322bded0d3e3b0000000000000000a913d03c88f4dbbd01de723fa1f8313e7dd033bd89d25e3b0000000000000000d044d83cf90fe9bd4e62703f9487453e82e247bde02d903b0000000000000000d3bce33cb3eaf3bd849e6d3f50fc583e88f45bbd2e90a03b0000000000000000faedeb3cdbf9febd83c06a3f448b6c3e44fa6dbdca54c13b00000000000000008e06f03c6f8104be82e2673f1283803e250681bd3b70ce3b0000000000000000b537f83ccc7f08be6f81643f83c08a3e280f8bbdd734ef3b00000000000000004850fc3c16fb0bbe97ff603f7d3f953e2b1895bdb9fc073c00000000000000004850fc3c60760fbe849e5d3f77be9f3ec0ec9ebd075f183c00000000000000006e34003dbc0512beecc0593ffa7eaa3ec3f5a8bd55c1283c00000000000000006e34003dcff713bec6dc553f7d3fb53ec5feb2bd3480373c00000000000000006e34003d068115bea5bd513f8941c03ec807bdbd82e2473c00000000000000006e34003d2b8716befb5c4d3f0c02cb3ea60ac6bdf775603c00000000000000004850fc3c197317be151d493fa245d63ea913d0bdd7346f3c0000000000000000b537f83c197317be34a2443f933ae13e8716d9bd24977f3c0000000000000000211ff43c197317bec520403f9f3cec3e6519e2bdb9fc873c00000000000000008e06f03c2b8716be083d3b3fab3ef73ed5e7eabd7446943c0000000000000000faedeb3c068115be143f363f2041013ffc18f3bde3a59b3c0000000000000000d3bce33ccff713bee561313f27c2063fb515fbbd0ad7a33c000000000000000040a4df3cce8812be68222c3f2d430c3f250601bec520b03c0000000000000000d044d83c857c10bee71d273fa5bd113f810405beec51b83c0000000000000000a913d03c5f070ebe6ade213fe71d173fb9fc07be5bb1bf3c000000000000000082e2c73cf1f40abe287e1c3f287e1c3ff1f40abe82e2c73c00000000000000005bb1bf3cb9fc07bee71d173f6ade213f5f070ebea913d03c0000000000000000ec51b83c810405bea5bd113fe71d273f857c10bed044d83c0000000000000000c520b03c250601be2d430c3f68222c3fce8812be40a4df3c00000000000000000ad7a33cb515fbbd27c2063fe561313fcff713bed3bce33c0000000000000000e3a59b3cfc18f3bd2041013f143f363f068115befaedeb3c00000000000000007446943cd5e7eabdab3ef73e083d3b3f2b8716be8e06f03c0000000000000000b9fc873c6519e2bd9f3cec3ec520403f197317be211ff43c000000000000000024977f3c8716d9bd933ae13e34a2443f197317beb537f83c0000000000000000d7346f3ca913d0bda245d63e151d493f197317be4850fc3c0000000000000000f775603ca60ac6bd0c02cb3efb5c4d3f2b8716be6e34003d000000000000000082e2473cc807bdbd8941c03ea5bd513f068115be6e34003d00000000000000003480373cc5feb2bd7d3fb53ec6dc553fcff713be6e34003d000000000000000055c1283cc3f5a8bdfa7eaa3eecc0593fbc0512be6e34003d0000000000000000075f183cc0ec9ebd77be9f3e849e5d3f60760fbe4850fc3c0000000000000000b9fc073c2b1895bd7d3f953e97ff603f16fb0bbe4850fc3c0000000000000000d734ef3b280f8bbd83c08a3e6f81643fcc7f08beb537f83c00000000000000003b70ce3b250681bd1283803e82e2673f6f8104be8e06f03c0000000000000000ca54c13b44fa6dbd448b6c3e83c06a3fdbf9febdfaedeb3c00000000000000002e90a03b88f45bbd50fc583e849e6d3fb3eaf3bdd3bce33c0000000000000000e02d903b82e247bd9487453e4e62703ff90fe9bdd044d83c000000000000000089d25e3b7dd033bda1f8313e01de723f88f4dbbda913d03c0000000000000000ed0d3e3b9c3322bd098a1f3eb81e753f5f07cebdefc9c33c000000000000000052491d3be02d10bd4d840d3e22fd763fed0dbebdec51b83c00000000000000006f12033b4850fcbc22fdf63dde02793f7b14aebd9eefa73c0000000000000000a69bc43ad044d8bcf4fdd43dfa7e7a3fbf0e9cbd075f983c00000000000000006f12833a5839b4bcc5feb23da3017c3f03098abdb9fc873c00000000000000006f12033a744694bcbc05923dfb5c7d3ffaed6bbd1ea7683c00000000000000006f12033a1ea768bcf931663d5b427e3f812642bd5bb13f3c00000000000000006f12033a55c128bce7fb293da4df7e3f98dd13bde02d103c00000000000000000000000089d2debb645ddc3cb29d7f3f16fbcbbc3b70ce3b00000000000000000000000089d25ebbd044583c0000803fa91350bced0d3e3b0000000000000000

//!TEXTURE coef_usm
//!SIZE 2 64
//!FORMAT rgba32f
//!FILTER NEAREST
0000000027a019bf27a0993f27a019bf00000000000000000000000000000000ed0d3e3b1ac01bbf006f993fe71d17bfed0d3ebb0000000000000000000000002e90a03bfb5c1dbff90f993fe63f14bf89d2debb6f12033a0000000000000000d734ef3b1b9e1ebf2731983fd3de10bf55c128bc000000000000000000000000075f183cb29d1fbfcb10973fff210dbffe6577bc0000000000000000000000003480373c4e6220bf48bf953fde0209bf77be9fbc6f12033a000000000000000082e2473c128320bfe63f943f34a204bf3d2cd4bc6f12033a00000000000000001ea7683cd3de20bfbe9f923fc52000bfdcd701bd6f12033a000000000000000024977f3c4e6220bfa54e903f7d3ff5be091b1ebd6f12033a0000000000000000b9fc873cb29d1fbf6ff08d3fe7fbe9be5af539bd6f12833a0000000000000000e02d903c20631ebf4f408b3fe483debe3ee859bd6f12833a00000000000000007446943cff211dbf696f883fbc05d2be6de77bbda69bc43a0000000000000000e3a59b3ccc5d1bbf1b2f853ff8c2c4be4df38ebda69bc43a000000000000000077be9f3cecc019bf910f823f22fdb6be5305a3bd6f12033b00000000000000000ad7a33cbec117bfc4427d3f423ea8be10e9b7bd52491d3b00000000000000000ad7a33cf4fd14bf7d3f753f50fc98be3b01cdbded0d3e3b00000000000000000ad7a33c05a312bf0de06d3f5eba89be6519e2bd89d25e3b00000000000000000ad7a33c3bdf0fbf8fc2653fb37b72beb515fbbd24977f3b00000000000000009eefa73cb1bf0cbfc4425d3faa8251bef08509bee02d903b00000000000000000ad7a33c637f09bf6f81543f69002fbe190416be2e90a03b000000000000000077be9f3c4f1e06bfcc5d4b3f16fb0bbe418222be7cf2b03b000000000000000077be9f3c3cbd02bf4182423fce19d1bda08930beca54c13b0000000000000000e3a59b3c5b42febe151d393f4bea84bddbf93ebe3b70ce3b0000000000000000075f983c99bbf6bef2412f3ffaedebbc287e4cbe89d2de3b0000000000000000075f983c6900efbe4260253f075f183cac8b5bbed734ef3b0000000000000000e02d903c27c2e6be0c021b3fca32443dfa7e6abeb9fc073c00000000000000004d158c3c77bedfbea5bd113f57ecaf3d6c787abee02d103c000000000000000026e4833c22fdd6beab3e073f1283003e810485be2e90203c000000000000000026e4833cf241cfbe7502fa3ed578293e3b018dbe55c1283c0000000000000000fe65773cb003c7be143fe63e97ff503ef4fd94be0e4f2f3c00000000000000001ea7683cd200bebe857cd03e6c787a3eadfa9cbe5bb13f3c0000000000000000f775603c1904b6bea301bc3ebc05923e0b46a5be82e2473c0000000000000000d044583cd6c5adbeb003a73eb003a73ed6c5adbed044583c000000000000000082e2473c0b46a5bebc05923ea301bc3e1904b6bef775603c00000000000000005bb13f3cadfa9cbe6c787a3e857cd03ed200bebe1ea7683c00000000000000000e4f2f3cf4fd94be97ff503e143fe63eb003c7befe65773c000000000000000055c1283c3b018dbed578293e7502fa3ef241cfbe26e4833c00000000000000002e90203c810485be1283003eab3e073f22fdd6be26e4833c0000000000000000e02d103c6c787abe57ecaf3da5bd113f77bedfbe4d158c3c0000000000000000b9fc073cfa7e6abeca32443d0c021b3f27c2e6bee02d903c0000000000000000d734ef3bac8b5bbe075f183c4260253f6900efbe075f983c000000000000000089d2de3b287e4cbefaedebbcf2412f3f99bbf6be075f983c00000000000000003b70ce3bdbf93ebe4bea84bd151d393f5b42febee3a59b3c0000000000000000ca54c13ba08930bece19d1bd4182423f3cbd02bf77be9f3c00000000000000007cf2b03b418222be16fb0bbecc5d4b3f4f1e06bf77be9f3c00000000000000002e90a03b190416be69002fbe6f81543f637f09bf0ad7a33c0000000000000000e02d903bf08509beaa8251bec4425d3fb1bf0cbf9eefa73c000000000000000024977f3bb515fbbdb37b72be8fc2653f3bdf0fbf0ad7a33c000000000000000089d25e3b6519e2bd5eba89be0de06d3f05a312bf0ad7a33c0000000000000000ed0d3e3b3b01cdbd50fc98be7d3f753ff4fd14bf0ad7a33c000000000000000052491d3b10e9b7bd423ea8bec4427d3fbec117bf0ad7a33c00000000000000006f12033b5305a3bd22fdb6be910f823fecc019bf77be9f3c0000000000000000a69bc43a4df38ebdf8c2c4be1b2f853fcc5d1bbfe3a59b3c0000000000000000a69bc43a6de77bbdbc05d2be696f883fff211dbf7446943c00000000000000006f12833a3ee859bde483debe4f408b3f20631ebfe02d903c00000000000000006f12833a5af539bde7fbe9be6ff08d3fb29d1fbfb9fc873c00000000000000006f12033a091b1ebd7d3ff5bea54e903f4e6220bf24977f3c00000000000000006f12033adcd701bdc52000bfbe9f923fd3de20bf1ea7683c00000000000000006f12033a3d2cd4bc34a204bfe63f943f128320bf82e2473c00000000000000006f12033a77be9fbcde0209bf48bf953f4e6220bf3480373c000000000000000000000000fe6577bcff210dbfcb10973fb29d1fbf075f183c00000000000000000000000055c128bcd3de10bf2731983f1b9e1ebfd734ef3b00000000000000006f12033a89d2debbe63f14bff90f993ffb5c1dbf2e90a03b000000000000000000000000ed0d3ebbe71d17bf006f993f1ac01bbfed0d3e3b0000000000000000