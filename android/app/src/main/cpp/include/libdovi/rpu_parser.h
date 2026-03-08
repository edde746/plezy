// SPDX-License-Identifier: MIT

#ifndef DOVI_H
#define DOVI_H


#define RPU_PARSER_MAJOR 3
#define RPU_PARSER_MINOR 3
#define RPU_PARSER_PATCH 2


#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

#define DoviNUM_COMPONENTS 3

/**
 * Opaque Dolby Vision RPU.
 *
 * Use dovi_rpu_free to free.
 * It should be freed regardless of whether or not an error occurred.
 */
typedef struct DoviRpuOpaque DoviRpuOpaque;

/**
 * Struct representing a data buffer
 */
typedef struct {
    /**
     * Pointer to the data buffer
     */
    const uint8_t *data;
    /**
     * Data buffer size
     */
    size_t len;
} DoviData;

/**
 * C struct for rpu_data_header()
 */
typedef struct {
    /**
     * Profile guessed from the values in the header
     */
    uint8_t guessed_profile;
    /**
     * Enhancement layer type (FEL or MEL) if the RPU is profile 7
     * null pointer if not profile 7
     */
    const char *el_type;
    /**
     * Deprecated since 3.2.0
     * The field is not actually part of the RPU header
     */
    uint8_t rpu_nal_prefix;
    uint8_t rpu_type;
    uint16_t rpu_format;
    uint8_t vdr_rpu_profile;
    uint8_t vdr_rpu_level;
    bool vdr_seq_info_present_flag;
    bool chroma_resampling_explicit_filter_flag;
    uint8_t coefficient_data_type;
    uint64_t coefficient_log2_denom;
    uint8_t vdr_rpu_normalized_idc;
    bool bl_video_full_range_flag;
    uint64_t bl_bit_depth_minus8;
    uint64_t el_bit_depth_minus8;
    uint64_t vdr_bit_depth_minus8;
    bool spatial_resampling_filter_flag;
    uint8_t reserved_zero_3bits;
    bool el_spatial_resampling_filter_flag;
    bool disable_residual_flag;
    bool vdr_dm_metadata_present_flag;
    bool use_prev_vdr_rpu_flag;
    uint64_t prev_vdr_rpu_id;
} DoviRpuDataHeader;

/**
 * Struct representing a data buffer
 */
typedef struct {
    /**
     * Pointer to the data buffer. Can be null if length is zero.
     */
    const uint16_t *data;
    /**
     * Data buffer size
     */
    size_t len;
} DoviU16Data;

/**
 * Struct representing a data buffer
 */
typedef struct {
    /**
     * Pointer to the data buffer. Can be null if length is zero.
     */
    const uint64_t *data;
    /**
     * Data buffer size
     */
    size_t len;
} DoviU64Data;

/**
 * Struct representing a data buffer
 */
typedef struct {
    /**
     * Pointer to the data buffer
     */
    const int64_t *data;
    /**
     * Data buffer size
     */
    size_t len;
} DoviI64Data;

/**
 * Struct representing a 2D data buffer
 */
typedef struct {
    /**
     * Pointer to the list of Data structs
     */
    const DoviI64Data *const *list;
    /**
     * List length
     */
    size_t len;
} DoviI64Data2D;

/**
 * Struct representing a 2D data buffer
 */
typedef struct {
    /**
     * Pointer to the list of Data structs
     */
    const DoviU64Data *const *list;
    /**
     * List length
     */
    size_t len;
} DoviU64Data2D;

typedef struct {
    DoviU64Data poly_order_minus1;
    DoviData linear_interp_flag;
    DoviI64Data2D poly_coef_int;
    DoviU64Data2D poly_coef;
} DoviPolynomialCurve;

/**
 * Struct representing a 3D data buffer
 */
typedef struct {
    /**
     * Pointer to the list of I64Data2D structs
     */
    const DoviI64Data2D *const *list;
    /**
     * List length
     */
    size_t len;
} DoviI64Data3D;

/**
 * Struct representing a 3D data buffer
 */
typedef struct {
    /**
     * Pointer to the list of U64Data2D structs
     */
    const DoviU64Data2D *const *list;
    /**
     * List length
     */
    size_t len;
} DoviU64Data3D;

typedef struct {
    DoviData mmr_order_minus1;
    DoviI64Data mmr_constant_int;
    DoviU64Data mmr_constant;
    DoviI64Data3D mmr_coef_int;
    DoviU64Data3D mmr_coef;
} DoviMMRCurve;

typedef struct {
    /**
     * [2, 9]
     */
    uint64_t num_pivots_minus2;
    DoviU16Data pivots;
    /**
     * Consistent for a component
     * Luma (component 0): Polynomial = 0
     * Chroma (components 1 and 2): MMR = 1
     */
    uint8_t mapping_idc;
    /**
     * mapping_idc = 0, null pointer otherwise
     */
    const DoviPolynomialCurve *polynomial;
    /**
     * mapping_idc = 1, null pointer otherwise
     */
    const DoviMMRCurve *mmr;
} DoviReshapingCurve;

/**
 * C struct for rpu_data_nlq()
 */
typedef struct {
    uint16_t nlq_offset[DoviNUM_COMPONENTS];
    uint64_t vdr_in_max_int[DoviNUM_COMPONENTS];
    uint64_t vdr_in_max[DoviNUM_COMPONENTS];
    uint64_t linear_deadzone_slope_int[DoviNUM_COMPONENTS];
    uint64_t linear_deadzone_slope[DoviNUM_COMPONENTS];
    uint64_t linear_deadzone_threshold_int[DoviNUM_COMPONENTS];
    uint64_t linear_deadzone_threshold[DoviNUM_COMPONENTS];
} DoviRpuDataNlq;

/**
 * C struct for rpu_data_mapping()
 */
typedef struct {
    uint64_t vdr_rpu_id;
    uint64_t mapping_color_space;
    uint64_t mapping_chroma_format_idc;
    uint64_t num_x_partitions_minus1;
    uint64_t num_y_partitions_minus1;
    DoviReshapingCurve curves[DoviNUM_COMPONENTS];
    /**
     * Set to -1 to represent Option::None
     */
    int32_t nlq_method_idc;
    /**
     * Set to -1 to represent Option::None
     */
    int32_t nlq_num_pivots_minus2;
    /**
     * Length of zero when not present. Only present in profile 4 and 7.
     */
    DoviU16Data nlq_pred_pivot_value;
    /**
     * Pointer to `RpuDataNlq` struct, null if not dual layer profile
     */
    const DoviRpuDataNlq *nlq;
} DoviRpuDataMapping;

/**
 * Statistical analysis of the frame: min, max, avg brightness.
 */
typedef struct {
    uint16_t min_pq;
    uint16_t max_pq;
    uint16_t avg_pq;
} DoviExtMetadataBlockLevel1;

/**
 * Creative intent trim passes per target display peak brightness
 */
typedef struct {
    uint16_t target_max_pq;
    uint16_t trim_slope;
    uint16_t trim_offset;
    uint16_t trim_power;
    uint16_t trim_chroma_weight;
    uint16_t trim_saturation_gain;
    int16_t ms_weight;
} DoviExtMetadataBlockLevel2;

typedef struct {
    /**
     * Pointer to the list of ExtMetadataBlockLevel2 structs
     */
    const DoviExtMetadataBlockLevel2 *const *list;
    /**
     * List length
     */
    size_t len;
} DoviLevel2BlockList;

/**
 * Level 1 offsets.
 */
typedef struct {
    uint16_t min_pq_offset;
    uint16_t max_pq_offset;
    uint16_t avg_pq_offset;
} DoviExtMetadataBlockLevel3;

/**
 * Something about temporal stability
 */
typedef struct {
    uint16_t anchor_pq;
    uint16_t anchor_power;
} DoviExtMetadataBlockLevel4;

/**
 * Active area of the picture (letterbox, aspect ratio)
 */
typedef struct {
    uint16_t active_area_left_offset;
    uint16_t active_area_right_offset;
    uint16_t active_area_top_offset;
    uint16_t active_area_bottom_offset;
} DoviExtMetadataBlockLevel5;

/**
 * ST2086/HDR10 metadata fallback
 */
typedef struct {
    uint16_t max_display_mastering_luminance;
    uint16_t min_display_mastering_luminance;
    uint16_t max_content_light_level;
    uint16_t max_frame_average_light_level;
} DoviExtMetadataBlockLevel6;

/**
 * Creative intent trim passes per target display peak brightness
 * For CM v4.0, L8 metadata only is present and used to compute L2
 *
 * This block can have varying byte lengths: 10, 12, 13, 19, 25
 * Depending on the length, the fields parsed default to zero and may not be set.
 * Up to (including):
 *     - 10: ms_weight
 *     - 12: target_mid_contrast
 *     - 13: clip_trim
 *     - 19: saturation_vector_field[0-5]
 *     - 25: hue_vector_field[0-5]
 */
typedef struct {
    uint64_t length;
    uint8_t target_display_index;
    uint16_t trim_slope;
    uint16_t trim_offset;
    uint16_t trim_power;
    uint16_t trim_chroma_weight;
    uint16_t trim_saturation_gain;
    uint16_t ms_weight;
    uint16_t target_mid_contrast;
    uint16_t clip_trim;
    uint8_t saturation_vector_field0;
    uint8_t saturation_vector_field1;
    uint8_t saturation_vector_field2;
    uint8_t saturation_vector_field3;
    uint8_t saturation_vector_field4;
    uint8_t saturation_vector_field5;
    uint8_t hue_vector_field0;
    uint8_t hue_vector_field1;
    uint8_t hue_vector_field2;
    uint8_t hue_vector_field3;
    uint8_t hue_vector_field4;
    uint8_t hue_vector_field5;
} DoviExtMetadataBlockLevel8;

typedef struct {
    /**
     * Pointer to the list of ExtMetadataBlockLevel8 structs
     */
    const DoviExtMetadataBlockLevel8 *const *list;
    /**
     * List length
     */
    size_t len;
} DoviLevel8BlockList;

/**
 * Source/mastering display color primaries
 *
 * This block can have varying byte lengths: 1 or 17
 * Depending on the length, the fields parsed default to zero and may not be set.
 * Up to (including):
 *     - 1: source_primary_index
 *     - 17: source_primary_{red,green,blue,white}_{x,y}
 */
typedef struct {
    uint64_t length;
    uint8_t source_primary_index;
    uint16_t source_primary_red_x;
    uint16_t source_primary_red_y;
    uint16_t source_primary_green_x;
    uint16_t source_primary_green_y;
    uint16_t source_primary_blue_x;
    uint16_t source_primary_blue_y;
    uint16_t source_primary_white_x;
    uint16_t source_primary_white_y;
} DoviExtMetadataBlockLevel9;

/**
 * Custom target display information
 *
 * This block can have varying byte lengths: 5 or 21
 * Depending on the length, the fields parsed default to zero and may not be set.
 * Up to (including):
 *     - 5: target_primary_index
 *     - 21: target_primary_{red,green,blue,white}_{x,y}
 */
typedef struct {
    uint64_t length;
    uint8_t target_display_index;
    uint16_t target_max_pq;
    uint16_t target_min_pq;
    uint8_t target_primary_index;
    uint16_t target_primary_red_x;
    uint16_t target_primary_red_y;
    uint16_t target_primary_green_x;
    uint16_t target_primary_green_y;
    uint16_t target_primary_blue_x;
    uint16_t target_primary_blue_y;
    uint16_t target_primary_white_x;
    uint16_t target_primary_white_y;
} DoviExtMetadataBlockLevel10;

typedef struct {
    /**
     * Pointer to the list of ExtMetadataBlockLevel10 structs
     */
    const DoviExtMetadataBlockLevel10 *const *list;
    /**
     * List length
     */
    size_t len;
} DoviLevel10BlockList;

/**
 * Content type metadata level
 */
typedef struct {
    uint8_t content_type;
    uint8_t whitepoint;
    bool reference_mode_flag;
    uint8_t reserved_byte2;
    uint8_t reserved_byte3;
} DoviExtMetadataBlockLevel11;

/**
 * Metadata level present in CM v4.0
 */
typedef struct {
    uint8_t dm_mode;
    uint8_t dm_version_index;
} DoviExtMetadataBlockLevel254;

/**
 * Metadata level optionally present in CM v2.9.
 * Different display modes (calibration/verify/bypass), debugging
 */
typedef struct {
    uint8_t dm_run_mode;
    uint8_t dm_run_version;
    uint8_t dm_debug0;
    uint8_t dm_debug1;
    uint8_t dm_debug2;
    uint8_t dm_debug3;
} DoviExtMetadataBlockLevel255;

/**
 * C struct for the list of ext_metadata_block()
 */
typedef struct {
    /**
     * Number of metadata blocks
     */
    uint64_t num_ext_blocks;
    const DoviExtMetadataBlockLevel1 *level1;
    DoviLevel2BlockList level2;
    const DoviExtMetadataBlockLevel3 *level3;
    const DoviExtMetadataBlockLevel4 *level4;
    const DoviExtMetadataBlockLevel5 *level5;
    const DoviExtMetadataBlockLevel6 *level6;
    DoviLevel8BlockList level8;
    const DoviExtMetadataBlockLevel9 *level9;
    DoviLevel10BlockList level10;
    const DoviExtMetadataBlockLevel11 *level11;
    const DoviExtMetadataBlockLevel254 *level254;
    const DoviExtMetadataBlockLevel255 *level255;
} DoviDmData;

/**
 * C struct for vdr_dm_data()
 */
typedef struct {
    bool compressed;
    uint64_t affected_dm_metadata_id;
    uint64_t current_dm_metadata_id;
    uint64_t scene_refresh_flag;
    int16_t ycc_to_rgb_coef0;
    int16_t ycc_to_rgb_coef1;
    int16_t ycc_to_rgb_coef2;
    int16_t ycc_to_rgb_coef3;
    int16_t ycc_to_rgb_coef4;
    int16_t ycc_to_rgb_coef5;
    int16_t ycc_to_rgb_coef6;
    int16_t ycc_to_rgb_coef7;
    int16_t ycc_to_rgb_coef8;
    uint32_t ycc_to_rgb_offset0;
    uint32_t ycc_to_rgb_offset1;
    uint32_t ycc_to_rgb_offset2;
    int16_t rgb_to_lms_coef0;
    int16_t rgb_to_lms_coef1;
    int16_t rgb_to_lms_coef2;
    int16_t rgb_to_lms_coef3;
    int16_t rgb_to_lms_coef4;
    int16_t rgb_to_lms_coef5;
    int16_t rgb_to_lms_coef6;
    int16_t rgb_to_lms_coef7;
    int16_t rgb_to_lms_coef8;
    uint16_t signal_eotf;
    uint16_t signal_eotf_param0;
    uint16_t signal_eotf_param1;
    uint32_t signal_eotf_param2;
    uint8_t signal_bit_depth;
    uint8_t signal_color_space;
    uint8_t signal_chroma_format;
    uint8_t signal_full_range_flag;
    uint16_t source_min_pq;
    uint16_t source_max_pq;
    uint16_t source_diagonal;
    DoviDmData dm_data;
} DoviVdrDmData;

/**
 * Heap allocated list of valid RPU pointers
 */
typedef struct {
    DoviRpuOpaque *const *list;
    size_t len;
    const char *error;
} DoviRpuOpaqueList;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/**
 * # Safety
 * The pointer to the data must be valid.
 *
 * Parse a Dolby Vision RPU from unescaped byte buffer.
 * Adds an error if the parsing fails.
 */
DoviRpuOpaque *dovi_parse_rpu(const uint8_t *buf, size_t len);

/**
 * # Safety
 * The pointer to the data must be valid.
 *
 * Parse a Dolby Vision from a AV1 ITU-T T.35 metadata OBU byte buffer.
 * Adds an error if the parsing fails.
 */
DoviRpuOpaque *dovi_parse_itu_t35_dovi_metadata_obu(const uint8_t *buf, size_t len);

/**
 * # Safety
 * The pointer to the data must be valid.
 *
 * Parse a Dolby Vision from a (possibly) escaped HEVC UNSPEC 62 NAL unit byte buffer.
 * Adds an error if the parsing fails.
 */
DoviRpuOpaque *dovi_parse_unspec62_nalu(const uint8_t *buf, size_t len);

/**
 * # Safety
 * The pointer to the opaque struct must be valid.
 * Avoid using on opaque pointers obtained through `dovi_parse_rpu_bin_file`.
 *
 * Free the RpuOpaque
 */
void dovi_rpu_free(DoviRpuOpaque *ptr);

/**
 * # Safety
 * The pointer to the opaque struct must be valid.
 *
 * Get the last logged error for the RpuOpaque operations.
 *
 * On invalid parsing, an error is added.
 * The user should manually verify if there is an error, as the parsing does not return an error code.
 */
const char *dovi_rpu_get_error(const DoviRpuOpaque *ptr);

/**
 * # Safety
 * The data pointer should exist, and be allocated by Rust.
 *
 * Free a Data buffer
 */
void dovi_data_free(const DoviData *data);

/**
 * # Safety
 * The struct pointer must be valid.
 *
 * Writes the encoded RPU as a byte buffer.
 * If an error occurs in the writing, it is logged to RpuOpaque.error
 */
const DoviData *dovi_write_rpu(DoviRpuOpaque *ptr);

/**
 * # Safety
 * The struct pointer must be valid.
 *
 * Writes the encoded RPU, escapes the bytes for HEVC and prepends the buffer with 0x7C01.
 * If an error occurs in the writing, it is logged to RpuOpaque.error
 */
const DoviData *dovi_write_unspec62_nalu(DoviRpuOpaque *ptr);

/**
 * # Safety
 * The struct pointer must be valid.
 * The mode must be between 0 and 4.
 *
 * Converts the RPU to be compatible with a different Dolby Vision profile.
 * Possible modes:
 *     - 0: Don't modify the RPU
 *     - 1: Converts the RPU to be MEL compatible
 *     - 2: Converts the RPU to be profile 8.1 compatible. Both luma and chroma mapping curves are set to no-op.
 *          This mode handles source profiles 5, 7 and 8.
 *     - 3: Converts to static profile 8.4
 *     - 4: Converts to profile 8.1 preserving luma and chroma mapping. Old mode 2 behaviour.
 *
 * If an error occurs, it is logged to RpuOpaque.error.
 * Returns 0 if successful, -1 otherwise.
 */
int32_t dovi_convert_rpu_with_mode(DoviRpuOpaque *ptr,
                                   uint8_t mode);

/**
 * # Safety
 * The pointer to the opaque struct must be valid.
 *
 * Get the DoVi RPU header struct.
 */
const DoviRpuDataHeader *dovi_rpu_get_header(const DoviRpuOpaque *ptr);

/**
 * # Safety
 * The pointer to the struct must be valid.
 *
 * Frees the memory used by the RPU header.
 */
void dovi_rpu_free_header(const DoviRpuDataHeader *ptr);

/**
 * # Safety
 * The pointer to the opaque struct must be valid.
 *
 * Get the DoVi RpuDataMapping struct.
 */
const DoviRpuDataMapping *dovi_rpu_get_data_mapping(const DoviRpuOpaque *ptr);

/**
 * # Safety
 * The pointer to the struct must be valid.
 *
 * Frees the memory used by the RpuDataMapping.
 */
void dovi_rpu_free_data_mapping(const DoviRpuDataMapping *ptr);

/**
 * # Safety
 * The pointer to the opaque struct must be valid.
 *
 * Get the DoVi VdrDmData struct.
 */
const DoviVdrDmData *dovi_rpu_get_vdr_dm_data(const DoviRpuOpaque *ptr);

/**
 * # Safety
 * The pointer to the struct must be valid.
 *
 * Frees the memory used by the VdrDmData struct.
 */
void dovi_rpu_free_vdr_dm_data(const DoviVdrDmData *ptr);

/**
 * # Safety
 * The pointer to the file path must be valid.
 *
 * Parses an existing RPU binary file.
 *
 * Returns the heap allocated `DoviRpuList` as a pointer.
 * The returned pointer may be null, or the list could be empty if an error occurred.
 */
const DoviRpuOpaqueList *dovi_parse_rpu_bin_file(const char *path);

/**
 * # Safety
 * The pointer to the struct must be valid.
 *
 * Frees the memory used by the DoviRpuOpaqueList struct.
 */
void dovi_rpu_list_free(const DoviRpuOpaqueList *ptr);

/**
 * # Safety
 * The struct pointer must be valid.
 *
 * Sets the L5 metadata active area offsets.
 * If there is no L5 block present, it is created with the offsets.
 */
int32_t dovi_rpu_set_active_area_offsets(DoviRpuOpaque *ptr,
                                         uint16_t left,
                                         uint16_t right,
                                         uint16_t top,
                                         uint16_t bottom);

/**
 * # Safety
 * The struct pointer must be valid.
 *
 * Converts the existing reshaping/mapping to become no-op.
 */
int32_t dovi_rpu_remove_mapping(DoviRpuOpaque *ptr);

/**
 * # Safety
 * The struct pointer must be valid.
 *
 * Writes the encoded RPU as `itu_t_t35_payload_bytes` for AV1 ITU-T T.35 metadata OBU
 * If an error occurs in the writing, it is logged to RpuOpaque.error
 */
const DoviData *dovi_write_av1_rpu_metadata_obu_t35_payload(DoviRpuOpaque *ptr);

/**
 * # Safety
 * The struct pointer must be valid.
 *
 * Writes the encoded RPU a complete AV1 `metadata_itut_t35()` OBU
 * If an error occurs in the writing, it is logged to RpuOpaque.error
 */
const DoviData *dovi_write_av1_rpu_metadata_obu_t35_complete(DoviRpuOpaque *ptr);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  /* DOVI_H */
