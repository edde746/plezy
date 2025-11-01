#!/bin/bash

# Android Screenshot Automation Script
# Starts emulators, runs Flutter app, executes maestro tests, and organizes screenshots

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MAESTRO_DIR="$PROJECT_ROOT/maestro"
FASTLANE_IMAGES_DIR="$PROJECT_ROOT/android/fastlane/metadata/android/en-GB/images"
ENV_FILE="$PROJECT_ROOT/.env"

# Source common screenshot functions
source "${SCRIPT_DIR}/screenshot_common.sh"

# Check if required tools are installed
check_dependencies() {
    # Check common dependencies first
    if ! check_common_dependencies; then
        exit 1
    fi

    log_info "Checking Android-specific dependencies..."

    # Try to find emulator binary
    if ! command -v emulator &> /dev/null; then
        # Try common Android SDK locations
        POSSIBLE_PATHS=(
            "$ANDROID_HOME/emulator/emulator"
            "$ANDROID_SDK_ROOT/emulator/emulator"
            "~/Android/Sdk/emulator/emulator"
            "~/Library/Android/sdk/emulator/emulator"
        )

        EMULATOR_PATH=""
        for path in "${POSSIBLE_PATHS[@]}"; do
            if [ -f "$path" ]; then
                EMULATOR_PATH="$path"
                break
            fi
        done

        if [ -z "$EMULATOR_PATH" ]; then
            log_error "Android emulator not found. Please ensure Android SDK is installed and ANDROID_HOME is set."
            exit 1
        fi

        # Create an alias for emulator
        alias emulator="$EMULATOR_PATH"
    fi

    log_success "All dependencies found"
}

# Get list of available AVDs
get_avds() {
    # Parse flutter emulators output to get Android emulator IDs
    flutter emulators 2>/dev/null | grep "android$" | awk '{print $1}'
}

# Stop all running emulators
stop_emulators() {
    log_info "Stopping any running emulators..."

    # Get list of running emulators
    local running_emulators=$(adb devices | grep emulator | cut -f1)

    if [ -n "$running_emulators" ]; then
        for emulator in $running_emulators; do
            log_info "Stopping emulator $emulator"
            adb -s "$emulator" emu kill 2>/dev/null || true
        done

        # Wait for emulators to fully stop - check periodically
        log_info "Waiting for emulators to fully shut down..."
        local timeout=30  # 30 seconds timeout
        local elapsed=0

        while [ $elapsed -lt $timeout ]; do
            local still_running=$(adb devices | grep emulator | cut -f1)
            if [ -z "$still_running" ]; then
                log_success "All emulators stopped"
                return 0
            fi
            sleep 2
            elapsed=$((elapsed + 2))

            # Show progress every 6 seconds
            if [ $((elapsed % 6)) -eq 0 ]; then
                log_info "Still waiting for emulators to stop... (${elapsed}s elapsed)"
            fi
        done

        log_warning "Timeout waiting for emulators to stop completely"
    else
        log_info "No emulators are currently running"
    fi
}

# Start emulator and wait for it to be ready
start_emulator() {
    local avd_name="$1"
    local device_type="$2"

    log_info "Starting $device_type emulator: $avd_name"

    # Double-check if any emulator is still running
    local running_emulators=$(adb devices | grep emulator | cut -f1)
    if [ -n "$running_emulators" ]; then
        log_warning "Emulator still running: $running_emulators"
        log_info "Forcing stop before starting new emulator..."
        stop_emulators
    fi

    # Start emulator in background with proper output redirection
    log_info "Launching emulator..."
    flutter emulators --launch "$avd_name" > /dev/null 2>&1 &
    local emulator_pid=$!

    log_info "Waiting for $device_type emulator to boot..."

    # Wait for emulator to appear in adb devices
    local timeout=120  # 2 minutes timeout
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if adb devices | grep -q "emulator.*device"; then
            log_success "$device_type emulator is ready"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))

        # Show progress every 10 seconds
        if [ $((elapsed % 10)) -eq 0 ]; then
            log_info "Still waiting... (${elapsed}s elapsed)"
        fi
    done

    log_error "Timeout waiting for $device_type emulator to start"
    return 1
}

# Detect device type based on screen size
detect_device_type() {
    local device_id="$1"

    # Get screen density and size
    local density=$(adb -s "$device_id" shell wm density | cut -d: -f2 | tr -d ' ')
    local size=$(adb -s "$device_id" shell wm size | cut -d: -f2 | tr -d ' ')

    # Extract width and height
    local width=$(echo "$size" | cut -d'x' -f1)
    local height=$(echo "$size" | cut -d'x' -f2)

    # Calculate diagonal in inches (approximate)
    local diagonal_pixels=$(echo "sqrt($width*$width + $height*$height)" | bc -l)
    local diagonal_inches=$(echo "$diagonal_pixels / $density" | bc -l)

    # Convert to integer for comparison
    local diagonal_int=$(echo "$diagonal_inches" | cut -d'.' -f1)

    if [ "$diagonal_int" -ge 9 ]; then
        echo "tablet"
    else
        echo "phone"
    fi
}

# Run Flutter app on specified device
run_flutter_app() {
    local device_id="$1"
    local device_type="$2"

    log_info "Running Flutter app on $device_type ($device_id)"

    cd "$PROJECT_ROOT"
    flutter run -d "$device_id" --hot &
    local flutter_pid=$!

    # Wait for app to be installed and launched
    sleep 30

    # Check if app is running
    if adb -s "$device_id" shell pm list packages | grep -q "com.edde746.plezy"; then
        log_success "Flutter app is running on $device_type"
        return 0
    else
        log_error "Failed to start Flutter app on $device_type"
        return 1
    fi
}

# Detect device type based on image dimensions
detect_device_type() {
    local image_path="$1"

    local dimensions=$(get_image_dimensions "$image_path")
    if [ -z "$dimensions" ]; then
        log_warning "Could not get dimensions for $image_path"
        echo "phone"  # Default to phone
        return
    fi

    local width=$(echo "$dimensions" | cut -d',' -f1)
    local height=$(echo "$dimensions" | cut -d',' -f2)

    # Determine shorter and longer sides
    local shorter_side=$((width < height ? width : height))
    local longer_side=$((width > height ? width : height))

    # Calculate diagonal using shell arithmetic (approximate)
    # For simplicity, we'll use the shorter side as the main criteria
    # Tablets typically have shorter side >= 1200px
    # Phones typically have shorter side < 1200px

    if [ "$shorter_side" -ge 1200 ]; then
        echo "tablet"
    else
        echo "phone"
    fi
}

# Organize screenshots into correct fastlane folders
organize_screenshots() {
    log_info "Organizing screenshots using ffprobe analysis..."

    # Create directories if they don't exist
    mkdir -p "$FASTLANE_IMAGES_DIR/phoneScreenshots"
    mkdir -p "$FASTLANE_IMAGES_DIR/sevenInchScreenshots"
    mkdir -p "$FASTLANE_IMAGES_DIR/tenInchScreenshots"

    # Find all screenshot files generated by maestro
    local android_screenshots_dir="$MAESTRO_DIR/android"
    if [ ! -d "$android_screenshots_dir" ]; then
        log_warning "No Android screenshots directory found at $android_screenshots_dir"
        return 1
    fi

    local screenshots=($(find "$android_screenshots_dir" -name "*.png" | sort))

    if [ ${#screenshots[@]} -eq 0 ]; then
        log_warning "No Android screenshots found in $android_screenshots_dir"
        return 1
    fi

    log_info "Found ${#screenshots[@]} screenshots"

    # Group screenshots by device type
    local phone_screenshots=()
    local tablet_screenshots=()

    for screenshot in "${screenshots[@]}"; do
        local device_type=$(detect_device_type "$screenshot")
        log_image_info "$screenshot" "$device_type"

        if [ "$device_type" = "tablet" ]; then
            tablet_screenshots+=("$screenshot")
        else
            phone_screenshots+=("$screenshot")
        fi
    done

    # Copy and rename phone screenshots
    local phone_count=1
    for screenshot in "${phone_screenshots[@]}"; do
        if [ $phone_count -gt 4 ]; then
            break  # Limit to 4 screenshots
        fi

        local target_name="${phone_count}_en-GB.png"

        # Copy to phone directory
        cp "$screenshot" "$FASTLANE_IMAGES_DIR/phoneScreenshots/$target_name"

        # Copy to seven inch directory (phone screenshots go here too)
        cp "$screenshot" "$FASTLANE_IMAGES_DIR/sevenInchScreenshots/$target_name"

        log_success "Copied phone screenshot $phone_count: $(basename "$screenshot")"
        phone_count=$((phone_count + 1))
    done

    # Copy and rename tablet screenshots
    local tablet_count=1
    for screenshot in "${tablet_screenshots[@]}"; do
        if [ $tablet_count -gt 4 ]; then
            break  # Limit to 4 screenshots
        fi

        local target_name="${tablet_count}_en-GB.png"
        cp "$screenshot" "$FASTLANE_IMAGES_DIR/tenInchScreenshots/$target_name"

        log_success "Copied tablet screenshot $tablet_count: $(basename "$screenshot")"
        tablet_count=$((tablet_count + 1))
    done

    log_success "Organized $((phone_count-1)) phone screenshots and $((tablet_count-1)) tablet screenshots"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."

    # Kill any running Flutter processes
    pkill -f "flutter run" 2>/dev/null || true

    # Stop emulators using our function
    stop_emulators

    log_success "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting Android screenshot automation..."

    # Set up cleanup trap
    trap cleanup EXIT INT TERM

    # Clean up old screenshots at the very beginning
    clean_old_screenshots "android ios"

    # Check dependencies
    check_dependencies

    # Stop any running emulators first
    stop_emulators

    # Get available AVDs
    log_info "Getting available Android Virtual Devices..."

    # Store AVDs in an array, handling potential spaces in names
    local avds_raw=$(get_avds)
    if [ -z "$avds_raw" ]; then
        log_error "No Android Virtual Devices found. Please create AVDs first."
        log_info "Create AVDs using: flutter emulators --create"
        exit 1
    fi

    # Convert to array (each line is an AVD)
    IFS=$'\n' read -d '' -r -a avds <<< "$avds_raw" || true

    log_info "Found ${#avds[@]} Android AVD(s): ${avds[*]}"

    # For now, we'll use the first two AVDs as phone and tablet
    # In a real scenario, you'd want to specify which AVDs to use
    local phone_avd="${avds[0]}"
    local tablet_avd="${avds[1]:-${avds[0]}}"  # Use first AVD if only one available

    if [ ${#avds[@]} -eq 1 ]; then
        log_warning "Only one AVD available. Using it for both phone and tablet tests."
    fi

    # Start phone emulator
    start_emulator "$phone_avd" "phone"

    # Get device ID for phone
    local phone_device=$(adb devices | grep emulator | head -n1 | cut -f1)

    # Run Flutter app on phone
    run_flutter_app "$phone_device" "phone"

    # Run maestro tests for phone
    MAESTRO_DEVICE="$phone_device" run_maestro_tests

    # If we have a different tablet AVD, start it
    if [ "$phone_avd" != "$tablet_avd" ]; then
        # Stop phone emulator
        log_info "Switching from phone to tablet emulator"
        stop_emulators

        # Start tablet emulator
        start_emulator "$tablet_avd" "tablet"

        # Get device ID for tablet
        local tablet_device=$(adb devices | grep emulator | head -n1 | cut -f1)

        # Run Flutter app on tablet
        run_flutter_app "$tablet_device" "tablet"

        # Run maestro tests for tablet
        MAESTRO_DEVICE="$tablet_device" run_maestro_tests
    fi

    # Organize screenshots
    organize_screenshots

    log_success "Android screenshot automation completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi