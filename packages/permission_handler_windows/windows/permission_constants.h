#include <string>

class PermissionConstants {
public:
    inline static int PERMISSION_CODE = 24;
    inline static int PERMISSION_CODE_IGNORE_BATTERY_OPTIMIZATIONS = 209;
    inline static int PERMISSION_CODE_MANAGE_EXTERNAL_STORAGE = 210;
    inline static int PERMISSION_CODE_SYSTEM_ALERT_WINDOW = 211;
    inline static int PERMISSION_CODE_REQUEST_INSTALL_PACKAGES = 212;
    inline static int PERMISSION_CODE_ACCESS_NOTIFICATION_POLICY = 213;

    //PERMISSION_GROUP
    enum class PermissionGroup {
        CALENDAR = 0,
        CAMERA = 1,
        CONTACTS = 2,
        LOCATION = 3,
        LOCATION_ALWAYS = 4,
        LOCATION_WHEN_IN_USE = 5,
        MEDIA_LIBRARY = 6,
        MICROPHONE = 7,
        PHONE = 8,
        PHOTOS = 9,
        PHOTOS_ADD_ONLY = 10,
        REMINDERS = 11,
        SENSORS = 12,
        SMS = 13,
        SPEECH = 14,
        STORAGE = 15,
        IGNORE_BATTERY_OPTIMIZATIONS = 16,
        NOTIFICATION = 17,
        ACCESS_MEDIA_LOCATION = 18,
        ACTIVITY_RECOGNITION = 19,
        UNKNOWN = 20,
        BLUETOOTH = 21,
        MANAGE_EXTERNAL_STORAGE = 22,
        SYSTEM_ALERT_WINDOW = 23,
        REQUEST_INSTALL_PACKAGES = 24,
        APP_TRACK_TRANSPARENCY = 25,
        CRITICAL_ALERTS = 26,
        ACCESS_NOTIFICATION_POLICY = 27,
        BLUETOOTH_SCAN = 28,
        BLUETOOTH_ADVERTISE = 29,
        BLUETOOTH_CONNECT = 30,
        NEARBY_WIFI_DEVICES = 31,
        VIDEOS = 32,
        AUDIO = 33,
        SCHEDULE_EXACT_ALARM = 34,
        SENSORS_ALWAYS = 35,
        CALENDAR_WRITE_ONLY = 36,
        CALENDAR_FULL_ACCESS = 37,
        ASSISTANT = 38,
        BACKGROUND_REFRESH = 39,
        ACCESS_LOCAL_NETWORK = 40,
    };

    //PERMISSION_STATUS
    enum class PermissionStatus {
        DENIED = 0,
        GRANTED = 1,
        RESTRICTED = 2,
        LIMITED = 3,
        NEVER_ASK_AGAIN = 4
    };

    //SERVICE_STATUS
    enum class ServiceStatus {
        DISABLED = 0,
        ENABLED = 1,
        NOT_APPLICABLE = 2
    };
};
