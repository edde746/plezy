using System;
using ElmSharp;
using Tizen.Flutter.Embedding;

namespace Runner
{
    public class App : FlutterApplication
    {
        private TizenMediaPlayer _tizenPlayer;

        protected override void OnCreate()
        {
            base.OnCreate();

            GeneratedPluginRegistrant.RegisterPlugins(this);

            // EFL window for video rendering, lowered beneath Flutter's DALi window so
            // video shows through the transparent hole left by VideoRectSupport.
            Window videoWindow = new Window("plezy-video");
            var screenSize = videoWindow.ScreenSize;
            int screenWidth = screenSize.Width;
            int screenHeight = screenSize.Height;
            videoWindow.Resize(screenWidth, screenHeight);
            Console.WriteLine($"[App] Video window created ({screenWidth}x{screenHeight})");

            _tizenPlayer = new TizenMediaPlayer(videoWindow);
            _tizenPlayer.Setup();

            new TizenWindowManager(screenWidth, screenHeight).Setup();
        }

        protected override void OnTerminate()
        {
            _tizenPlayer?.Dispose();
            base.OnTerminate();
        }

        static void Main(string[] args)
        {
            var app = new App();
            app.Run(args);
        }
    }
}
