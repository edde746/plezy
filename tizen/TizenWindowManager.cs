using System;
using System.Collections;
using System.Threading.Tasks;
using ElmSharp;
using Tizen.Flutter.Embedding;

namespace Runner
{
    /// <summary>
    /// Tizen TV stub for the window_manager Flutter plugin.
    /// Registers on the same channel and returns fixed TV defaults (always fullscreen,
    /// maximized, focused; all setters are no-ops) so Dart code that calls
    /// window_manager works without platform branches.
    /// </summary>
    internal class TizenWindowManager
    {
        private readonly int _screenWidth;
        private readonly int _screenHeight;

        public TizenWindowManager(int screenWidth, int screenHeight)
        {
            _screenWidth = screenWidth;
            _screenHeight = screenHeight;
        }

        public void Setup()
        {
            var channel = new MethodChannel("window_manager");
            channel.SetMethodCallHandler(HandleMethodCall);
        }

        private Task<object> HandleMethodCall(MethodCall call)
        {
            object result = Respond(call.Method);
            return Task.FromResult(result);
        }

        private object Respond(string method)
        {
            // Boolean queries: TV is always fullscreen, maximized, focused, visible.
            if (method == "isFullScreen") return true;
            if (method == "isMaximized") return true;
            if (method == "isFocused") return true;
            if (method == "isVisible") return true;
            if (method == "isMinimized") return false;
            if (method == "isAlwaysOnTop") return false;
            if (method == "isMovable") return false;
            if (method == "isResizable") return false;
            if (method == "hasShadow") return false;
            if (method == "isPreventClose") return false;

            // Numeric/string queries.
            if (method == "getOpacity") return 1.0;
            if (method == "getBrightness") return "normal";
            if (method == "getTitleBarHeight") return 0;
            if (method == "getTitle") return "Plezy";

            // Size/position, queried from the actual screen at startup.
            if (method == "getSize")
                return new Hashtable { { "width", (double)_screenWidth }, { "height", (double)_screenHeight } };
            if (method == "getPosition")
                return new Hashtable { { "x", 0.0 }, { "y", 0.0 } };

            // Everything else (setters, listeners, close, destroy) are no-ops.
            return null;
        }
    }
}
