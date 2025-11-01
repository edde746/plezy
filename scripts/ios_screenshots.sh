#!/bin/bash

# iOS Screenshot Automation Script
# Starts simulators, runs Flutter app, executes maestro tests, and organizes screenshots

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MAESTRO_DIR="$PROJECT_ROOT/maestro"
FASTLANE_SCREENSHOTS_DIR="$PROJECT_ROOT/ios/fastlane/screenshots/en-US"
ENV_FILE="$PROJECT_ROOT/.env"

# Source common screenshot functions
source "${SCRIPT_DIR}/screenshot_common.sh"

# Check if required tools are installed
check_dependencies() {
    # Check common dependencies first
    if ! check_common_dependencies; then
        exit 1
    fi

    log_info "Checking iOS-specific dependencies..."

    if ! command -v xcrun &> /dev/null; then
        log_error "xcrun is not installed - Xcode is required"
        exit 1
    fi

    log_success "All dependencies found"
}

# Get list of available iOS simulators
get_simulators() {
    xcrun simctl list devices available -j | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime and devices:
        for device in devices:
            if device['isAvailable']:
                print(f\"{device['udid']}|{device['name']}\")
" 2>/dev/null || echo ""
}

# Stop all running simulators
stop_simulators() {
    log_info "Stopping any running simulators..."

    # Get list of running simulators
    local running_simulators=$(xcrun simctl list devices | grep "Booted" | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" || echo "")

    if [ -n "$running_simulators" ]; then
        while IFS= read -r simulator; do
            log_info "Stopping simulator $simulator"
            xcrun simctl shutdown "$simulator" 2>/dev/null || true
        done <<< "$running_simulators"

        # Wait for simulators to fully stop
        log_info "Waiting for simulators to fully shut down..."
        sleep 3
        log_success "All simulators stopped"
    else
        log_info "No simulators are currently running"
    fi
}

# Start simulator and wait for it to be ready
start_simulator() {
    local simulator_udid="$1"
    local simulator_name="$2"
    local device_type="$3"

    log_info "Starting $device_type simulator: $simulator_name"

    # Double-check if any simulator is still running
    local running_simulators=$(xcrun simctl list devices | grep "Booted" | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" || echo "")
    if [ -n "$running_simulators" ]; then
        log_warning "Simulator still running"
        log_info "Forcing stop before starting new simulator..."
        stop_simulators
    fi

    # Start simulator
    log_info "Launching simulator..."
    xcrun simctl boot "$simulator_udid" 2>/dev/null || log_warning "Simulator may already be booting"

    log_info "Waiting for $device_type simulator to be ready..."

    # Wait for simulator to boot
    local timeout=120  # 2 minutes timeout
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        local state=$(xcrun simctl list devices | grep "$simulator_udid" | grep -oE "(Booted|Shutdown)")
        if [ "$state" = "Booted" ]; then
            # Give it a bit more time to fully initialize
            sleep 5
            log_success "$device_type simulator is ready"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))

        # Show progress every 10 seconds
        if [ $((elapsed % 10)) -eq 0 ]; then
            log_info "Still waiting... (${elapsed}s elapsed)"
        fi
    done

    log_error "Timeout waiting for $device_type simulator to start"
    return 1
}

# Rotate simulator to landscape
rotate_simulator_landscape() {
    local simulator_udid="$1"

    log_info "Rotating simulator to landscape orientation..."

    # Open Simulator app and bring it to front
    open -a Simulator
    sleep 2

    # Use AppleScript to send rotation keyboard shortcut (Cmd+Left arrow rotates counterclockwise)
    # Key code 123 is left arrow
    osascript -e 'tell application "Simulator" to activate' \
              -e 'tell application "System Events" to key code 123 using command down'

    sleep 2
    log_success "Simulator rotated to landscape"
}

# Detect device type based on image dimensions for iOS
detect_ios_device_type() {
    local image_path="$1"

    local dimensions=$(get_image_dimensions "$image_path")
    if [ -z "$dimensions" ]; then
        log_warning "Could not get dimensions for $image_path"
        echo "iphone_6_5"  # Default
        return
    fi

    local width=$(echo "$dimensions" | cut -d',' -f1)
    local height=$(echo "$dimensions" | cut -d',' -f2)

    # Determine shorter and longer sides (for portrait orientation)
    local shorter_side=$((width < height ? width : height))
    local longer_side=$((width > height ? width : height))

    # iOS App Store screenshot sizes (based on shorter side in portrait)
    # Reference: https://help.apple.com/app-store-connect/#/devd274dd925

    # iPad Pro 12.9" (3rd gen and later): 2048 x 2732
    if [ "$shorter_side" -ge 2000 ] && [ "$longer_side" -ge 2700 ]; then
        echo "ipad_pro_12_9_3rd_gen"
    # iPad Pro 12.9" (2nd gen): 2048 x 2732
    elif [ "$shorter_side" -ge 2000 ] && [ "$longer_side" -ge 2700 ]; then
        echo "ipad_pro_12_9_2nd_gen"
    # iPhone 6.9" display (iPhone Air Pro Max, 16 Pro Max, etc.): 1320 x 2868
    elif [ "$shorter_side" -ge 1300 ] && [ "$longer_side" -ge 2800 ]; then
        echo "iphone_6_9"
    # iPhone 6.7" display (iPhone 14 Pro Max, etc.): 1290 x 2796
    elif [ "$shorter_side" -ge 1250 ] && [ "$longer_side" -ge 2700 ]; then
        echo "iphone_6_7"
    # iPhone 6.3" display (iPhone 17, 16 Pro, 15 Pro, 14 Pro): 1206 x 2622
    elif [ "$shorter_side" -ge 1200 ] && [ "$shorter_side" -lt 1242 ] && [ "$longer_side" -ge 2600 ] && [ "$longer_side" -lt 2688 ]; then
        echo "iphone_6_3"
    # iPhone 6.5" display (iPhone 14 Plus, 13 Pro Max, 11 Pro Max, XS Max, etc.): 1242 x 2688 or 1284 x 2778
    elif [ "$shorter_side" -ge 1200 ] && [ "$longer_side" -ge 2600 ]; then
        echo "iphone_6_5"
    # iPhone 5.5" display (iPhone 8 Plus, etc.): 1242 x 2208
    elif [ "$shorter_side" -ge 1200 ] && [ "$longer_side" -ge 2200 ]; then
        echo "iphone_5_5"
    else
        # Default to 6.5" for unknown iPhone sizes
        echo "iphone_6_5"
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
    log_info "Waiting for Flutter app to launch..."
    sleep 40  # iOS typically takes longer to launch

    # Check if simulator is still running
    local state=$(xcrun simctl list devices | grep "$device_id" | grep -oE "(Booted|Shutdown)")
    if [ "$state" = "Booted" ]; then
        log_success "Flutter app should be running on $device_type"
        return 0
    else
        log_error "Simulator not running anymore"
        return 1
    fi
}

# Map device type to fastlane naming convention
get_fastlane_device_name() {
    local device_type="$1"

    case "$device_type" in
        ipad_pro_12_9_3rd_gen|ipad_pro_12_9_2nd_gen)
            echo "IPAD_PRO_3GEN_129"
            ;;
        iphone_6_9)
            echo "IPHONE_69"
            ;;
        iphone_6_7)
            echo "IPHONE_67"
            ;;
        iphone_6_5)
            echo "IPHONE_65"
            ;;
        iphone_6_3)
            echo "IPHONE_63"
            ;;
        iphone_5_5)
            echo "IPHONE_55"
            ;;
        *)
            echo "IPHONE_67"  # Default to 6.7"
            ;;
    esac
}

# Organize screenshots into correct fastlane folders
organize_screenshots() {
    log_info "Organizing screenshots using ffprobe analysis..."

    # Ensure target directory exists
    mkdir -p "$FASTLANE_SCREENSHOTS_DIR"

    # Find all screenshot files generated by maestro
    local ios_screenshots_dir="$MAESTRO_DIR/ios"
    if [ ! -d "$ios_screenshots_dir" ]; then
        log_warning "No iOS screenshots directory found at $ios_screenshots_dir"
        return 1
    fi

    local screenshots=($(find "$ios_screenshots_dir" -name "*.png" | sort))

    if [ ${#screenshots[@]} -eq 0 ]; then
        log_warning "No iOS screenshots found in $ios_screenshots_dir"
        return 1
    fi

    log_info "Found ${#screenshots[@]} screenshots"

    # First pass: detect and log all device types
    local device_types=()
    for screenshot in "${screenshots[@]}"; do
        local device_type=$(detect_ios_device_type "$screenshot")
        log_image_info "$screenshot" "$device_type"

        # Add to device_types if not already present
        local found=0
        for dt in "${device_types[@]}"; do
            if [ "$dt" = "$device_type" ]; then
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            device_types+=("$device_type")
        fi
    done

    # Second pass: copy and rename screenshots for each device type
    for device_type in "${device_types[@]}"; do
        local fastlane_name=$(get_fastlane_device_name "$device_type")
        local count=0

        for screenshot in "${screenshots[@]}"; do
            local detected_type=$(detect_ios_device_type "$screenshot")

            # Only process screenshots matching this device type
            if [ "$detected_type" = "$device_type" ]; then
                # Format: {index}_APP_{DEVICE_TYPE}_{index}.png
                local target_name="${count}_APP_${fastlane_name}_${count}.png"
                cp "$screenshot" "$FASTLANE_SCREENSHOTS_DIR/$target_name"

                log_success "Copied $device_type screenshot: $(basename "$screenshot") -> $target_name"
                count=$((count + 1))
            fi
        done
    done

    log_success "Screenshot organization completed"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."

    # Kill any running Flutter processes
    pkill -f "flutter run" 2>/dev/null || true

    # Stop simulators
    stop_simulators

    log_success "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting iOS screenshot automation..."

    # Set up cleanup trap
    trap cleanup EXIT INT TERM

    # Clean up old screenshots at the very beginning
    clean_old_screenshots "ios"

    # Clean up old fastlane screenshots to prevent mixing old/new with different naming
    log_info "Cleaning old fastlane screenshots..."
    if [ -d "$FASTLANE_SCREENSHOTS_DIR" ]; then
        rm -rf "$FASTLANE_SCREENSHOTS_DIR"/*
        log_success "Fastlane screenshots directory cleaned"
    fi

    # Check dependencies
    check_dependencies

    # Stop any running simulators first
    stop_simulators

    # Get available simulators
    log_info "Getting available iOS Simulators..."

    local simulators_raw=$(get_simulators)
    if [ -z "$simulators_raw" ]; then
        log_error "No iOS Simulators found. Please install simulators via Xcode."
        exit 1
    fi

    # Parse simulators into arrays
    declare -a simulator_udids
    declare -a simulator_names

    while IFS='|' read -r udid name; do
        simulator_udids+=("$udid")
        simulator_names+=("$name")
    done <<< "$simulators_raw"

    log_info "Found ${#simulator_udids[@]} iOS Simulator(s)"

    # Find iPhone Air and iPad Pro 13" simulators
    local iphone_idx=-1
    local ipad_idx=-1

    for i in "${!simulator_names[@]}"; do
        if [[ "${simulator_names[$i]}" =~ iPhone\ Air ]] && [ $iphone_idx -eq -1 ]; then
            iphone_idx=$i
            log_info "Found iPhone Air: ${simulator_names[$i]}"
        elif [[ "${simulator_names[$i]}" =~ iPad.*13 ]] && [ $ipad_idx -eq -1 ]; then
            ipad_idx=$i
            log_info "Found iPad Pro 13\": ${simulator_names[$i]}"
        fi
    done

    if [ $iphone_idx -eq -1 ]; then
        log_error "iPhone Air simulator not found. Please create it in Xcode."
        exit 1
    fi

    if [ $ipad_idx -eq -1 ]; then
        log_error "iPad Pro 13\" simulator not found. Please create it in Xcode."
        exit 1
    fi

    log_info "Using iPhone: ${simulator_names[$iphone_idx]}"
    log_info "Using iPad: ${simulator_names[$ipad_idx]}"

    # Start iPhone Air simulator
    start_simulator "${simulator_udids[$iphone_idx]}" "${simulator_names[$iphone_idx]}" "iPhone Air"

    # Run Flutter app on iPhone Air
    run_flutter_app "${simulator_udids[$iphone_idx]}" "iPhone Air"

    # Run maestro tests for iPhone Air
    run_maestro_tests "${simulator_udids[$iphone_idx]}"

    # Stop iPhone simulator and switch to iPad
    log_info "Switching from iPhone Air to iPad Pro 13\" simulator"
    stop_simulators

    # Start iPad Pro 13" simulator
    start_simulator "${simulator_udids[$ipad_idx]}" "${simulator_names[$ipad_idx]}" "iPad Pro 13\""

    # Rotate iPad to landscape
    # rotate_simulator_landscape "${simulator_udids[$ipad_idx]}"

    # Run Flutter app on iPad
    run_flutter_app "${simulator_udids[$ipad_idx]}" "iPad Pro 13\""

    # Run maestro tests for iPad
    run_maestro_tests "${simulator_udids[$ipad_idx]}"

    # Organize screenshots
    organize_screenshots

    log_success "iOS screenshot automation completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
