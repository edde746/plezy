#!/bin/bash

# Screenshot Automation Common Functions
# Shared functionality between Android and iOS screenshot scripts

# This script should be sourced, not executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly"
    exit 1
fi

# Configuration - these should be set before sourcing this file, but defaults provided
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(dirname "$SCRIPT_DIR")}"
MAESTRO_DIR="${MAESTRO_DIR:-$PROJECT_ROOT/maestro}"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check common dependencies (flutter, maestro, dotenv, ffprobe)
check_common_dependencies() {
    log_info "Checking common dependencies..."

    local all_found=true

    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        all_found=false
    fi

    if ! command -v maestro &> /dev/null; then
        log_error "Maestro is not installed or not in PATH"
        all_found=false
    fi

    if ! command -v dotenv &> /dev/null; then
        log_error "dotenv is not installed or not in PATH"
        all_found=false
    fi

    if ! command -v ffprobe &> /dev/null; then
        log_error "ffprobe is not installed or not in PATH (part of ffmpeg)"
        all_found=false
    fi

    if [ "$all_found" = false ]; then
        return 1
    fi

    log_success "Common dependencies found"
    return 0
}

# Get image dimensions using ffprobe
get_image_dimensions() {
    local image_path="$1"
    ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$image_path" 2>/dev/null
}

# Log image information for debugging
log_image_info() {
    local image_path="$1"
    local device_type="$2"

    local dimensions=$(get_image_dimensions "$image_path")
    local filename=$(basename "$image_path")

    if [ -n "$dimensions" ]; then
        local width=$(echo "$dimensions" | cut -d',' -f1)
        local height=$(echo "$dimensions" | cut -d',' -f2)
        log_info "Screenshot: $filename - ${width}x${height} - $device_type"
    else
        log_warning "Could not analyze: $filename - assuming $device_type"
    fi
}

# Clean up old maestro screenshots for specified platform(s)
# Usage: clean_old_screenshots "android" or clean_old_screenshots "ios" or clean_old_screenshots "android ios"
clean_old_screenshots() {
    local platforms="$1"

    log_info "Cleaning up old screenshots..."

    for platform in $platforms; do
        local platform_dir="$MAESTRO_DIR/$platform"

        if [ -d "$platform_dir" ]; then
            local old_count=$(find "$platform_dir" -name "*.png" 2>/dev/null | wc -l)
            if [ "$old_count" -gt 0 ]; then
                log_info "Removing $old_count old screenshot(s) from maestro/$platform/"
                rm -f "$platform_dir"/*.png
            else
                log_info "No old screenshots found in maestro/$platform/"
            fi
        else
            log_info "No $platform screenshot directory found"
        fi
    done

    log_success "Screenshot cleanup completed"
}

# Execute maestro tests
# Usage: run_maestro_tests [device_id]
run_maestro_tests() {
    local device_id="${1:-}"

    if [ -n "$device_id" ]; then
        log_info "Running maestro screenshot tests on device $device_id..."
    else
        log_info "Running maestro screenshot tests..."
    fi

    # Check if .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        log_error "Environment file not found at $ENV_FILE"
        log_info "Please create a .env file with required Maestro variables"
        return 1
    fi

    log_info "Using environment file: $ENV_FILE"
    cd "$MAESTRO_DIR"

    # Run maestro tests with optional device specification
    if [ -n "$device_id" ]; then
        log_info "Executing: MAESTRO_DEVICE=$device_id dotenv -f $ENV_FILE run maestro test screenshots.yaml"
        MAESTRO_DEVICE="$device_id" dotenv -f "$ENV_FILE" run maestro test screenshots.yaml
    else
        log_info "Executing: dotenv -f $ENV_FILE run maestro test screenshots.yaml"
        dotenv -f "$ENV_FILE" run maestro test screenshots.yaml
    fi

    local maestro_exit_code=$?
    if [ $maestro_exit_code -eq 0 ]; then
        log_success "Maestro tests completed successfully"
        return 0
    else
        log_error "Maestro tests failed with exit code $maestro_exit_code"
        return 1
    fi
}

# Run Flutter app on specified device
# Platform-specific validation should be done in the calling script
run_flutter_app() {
    local device_id="$1"
    local device_type="$2"
    local wait_time="${3:-30}"  # Optional wait time, default 30s

    log_info "Running Flutter app on $device_type ($device_id)"

    cd "$PROJECT_ROOT"
    flutter run -d "$device_id" --hot &
    local flutter_pid=$!

    # Wait for app to be installed and launched
    log_info "Waiting for Flutter app to launch..."
    sleep "$wait_time"

    log_success "Flutter app should be running on $device_type"
    return 0
}
