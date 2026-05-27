using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Timers;
using ElmSharp;
using Tizen.Flutter.Embedding;
using Tizen.Multimedia;

// P/Invoke to clear the video window's Wayland input region so keyboard/pointer
// events fall through to Flutter's DALi window instead of being consumed here.
internal static class WlInput
{
    [DllImport("libevas.so.1")]
    internal static extern IntPtr evas_object_evas_get(IntPtr obj);

    [DllImport("libecore_evas.so.1")]
    internal static extern IntPtr ecore_evas_ecore_evas_get(IntPtr e);

    [DllImport("libecore_evas.so.1")]
    internal static extern IntPtr ecore_evas_wayland2_window_get(IntPtr ee);

    // Setting w=0, h=0 creates an empty region; the window receives no input.
    [DllImport("libecore_wl2.so.1")]
    internal static extern void ecore_wl2_window_input_region_set(IntPtr win, int x, int y, int w, int h);
}

namespace Runner
{
    /// <summary>
    /// Native Tizen TV media player using hardware compositor overlay.
    /// Renders video via Display(ElmSharp.Window) + DisplaySettings.SetRoi() on a
    /// dedicated hardware plane, keeping Flutter's GPU free for the UI.
    /// </summary>
    internal class TizenMediaPlayer : IEventStreamHandler, IDisposable
    {
        private readonly ElmSharp.Window _videoWindow;
        // SynchronizationContext captured on the main thread in Setup() so we
        // can post back to it from timer/player callbacks (thread-pool threads).
        private SynchronizationContext _mainContext;
        private Player _player;
        private IEventSink _eventSink;
        private System.Timers.Timer _positionTimer;
        private bool _disposed;
        private bool _isSeeking;
        private int _pendingSeekMs = -1;
        private int _openGeneration;
        private PlayerDisplayMode _currentDisplayMode = PlayerDisplayMode.FullScreen;

        public TizenMediaPlayer(ElmSharp.Window videoWindow)
        {
            _videoWindow = videoWindow;
        }

        public void Setup()
        {
            // Capture the main thread's SynchronizationContext (Setup() is called from App.OnCreate()).
            _mainContext = SynchronizationContext.Current ?? new SynchronizationContext();

            var methodChannel = new MethodChannel("com.plezy/tizen_player");
            methodChannel.SetMethodCallHandler(HandleMethodCall);

            var eventChannel = new EventChannel("com.plezy/tizen_player/events");
            eventChannel.SetStreamHandler(this);
        }

        private async Task<object> HandleMethodCall(MethodCall call)
        {
            // Flutter's StandardMethodCodec serializes Dart Maps as Hashtable on C#.
            // Cast to non-generic IDictionary so string keys resolve correctly.
            var args = call.Arguments as System.Collections.IDictionary;
            switch (call.Method)
            {
                case "open":
                    await OpenAsync(args);
                    return null;

                case "play":
                    Play();
                    return null;

                case "pause":
                    Pause();
                    return null;

                case "stop":
                    _openGeneration++;
                    Stop();
                    return null;

                case "seek":
                    await SeekAsync(Convert.ToInt32(args?["positionMs"]));
                    return null;

                case "setVolume":
                    SetVolume(Convert.ToDouble(args?["volume"]));
                    return null;

                case "setRate":
                    SetRate(Convert.ToDouble(args?["rate"]));
                    return null;

                case "setVideoRect":
                    SetVideoRect(args);
                    return null;

                case "setDisplayMode":
                    SetDisplayMode(Convert.ToInt32(args?["mode"] ?? call.Arguments));
                    return null;

                case "selectAudioTrack":
                    SelectAudioTrack(Convert.ToInt32(args?["index"]));
                    return null;

                case "selectSubtitleTrack":
                    SelectSubtitleTrack(Convert.ToInt32(args?["index"]));
                    return null;

                case "setVisible":
                    SetVisible(Convert.ToBoolean(args?["visible"]));
                    return null;

                case "dispose":
                    _openGeneration++;
                    DisposePlayer();
                    return null;

                default:
                    throw new MissingPluginException();
            }
        }

        private async Task OpenAsync(System.Collections.IDictionary args)
        {
            var gen = ++_openGeneration;
            DisposePlayer();

            var url = args?["url"] as string;
            if (string.IsNullOrEmpty(url))
            {
                Post(() => _eventSink?.Success(ErrorEvent("open", "url is null or empty")));
                return;
            }

            var openPlayer = new Player();
            _player = openPlayer;

            if (_videoWindow != null)
            {
                try
                {
                    // Display(ElmSharp.Window) uses the correct EWL handle format for player_set_display(OVERLAY).
                    openPlayer.Display = new Display(_videoWindow);
                    openPlayer.DisplaySettings.Mode = PlayerDisplayMode.FullScreen;
                    openPlayer.DisplaySettings.IsVisible = true;
                    _videoWindow.Show();
                    _videoWindow.Lower(); // below Flutter's DALi window

                    // Empty input region → all normal key/pointer events fall through
                    // to Flutter's DALi window (which has Wayland keyboard focus).
                    SetEmptyInputRegion();

                    // KeyGrab captures privileged TV keys the system intercepts before Wayland
                    // and relays them to Flutter via the event channel.
                    _videoWindow.KeyGrab("XF86Back", false);
                    _videoWindow.KeyGrab("Back", false);
                    _videoWindow.KeyDown += OnVideoWindowKeyDown;
                    Log("Player display set via ElmSharp.Window");
                }
                catch (Exception e)
                {
                    Log($"Display setup failed: {e.Message}", isError: true);
                }
            }
            else
            {
                Log("Video window unavailable, video overlay disabled", isError: true);
            }

            // Player events fire on native threads; dispatch directly to the
            // EFL main loop (same thread Flutter's platform channels run on).
            openPlayer.PlaybackCompleted += (s, e) =>
                Post(() =>
                {
                    if (!IsCurrentOpen(gen, openPlayer)) return;
                    _eventSink?.Success(new Dictionary<string, object> { ["event"] = "completed" });
                });

            openPlayer.SubtitleUpdated += (s, e) =>
                Post(() =>
                {
                    if (!IsCurrentOpen(gen, openPlayer)) return;
                    _eventSink?.Success(new Dictionary<string, object>
                    {
                        ["event"] = "subtitle",
                        ["text"] = e.Text ?? "",
                        ["durationMs"] = (int)e.Duration,
                    });
                });

            openPlayer.BufferingProgressChanged += (s, e) =>
                Post(() =>
                {
                    if (!IsCurrentOpen(gen, openPlayer)) return;
                    _eventSink?.Success(new Dictionary<string, object>
                    {
                        ["event"] = "buffering",
                        ["isBuffering"] = e.Percent < 100,
                        ["percent"] = e.Percent,
                    });
                });

            openPlayer.ErrorOccurred += (s, e) =>
                Post(() =>
                {
                    if (!IsCurrentOpen(gen, openPlayer)) return;
                    _eventSink?.Success(ErrorEvent("playback", e.Error.ToString()));
                });

            // HTTP headers: Cookie and UserAgent are properties on Player.
            if (args?["headers"] is System.Collections.IDictionary headers)
                ApplyHttpHeaders(headers);

            openPlayer.SetSource(new MediaUriSource(url));

            try
            {
                await openPlayer.PrepareAsync();
            }
            catch (Exception e)
            {
                if (!IsCurrentOpen(gen, openPlayer)) return;
                Post(() => _eventSink?.Success(ErrorEvent("prepare", e.Message)));
                return;
            }

            // A newer open() call arrived while PrepareAsync was awaited; discard.
            if (!IsCurrentOpen(gen, openPlayer)) return;

            var startMs = args?["startMs"] != null ? Convert.ToInt32(args["startMs"]) : 0;
            if (startMs > 0)
            {
                try { await openPlayer.SetPlayPositionAsync(startMs, false); }
                catch { }
            }
            if (!IsCurrentOpen(gen, openPlayer)) return;

            int durationMs = openPlayer.StreamInfo.GetDuration();
            int width = 0, height = 0;
            int audioSampleRate = 0, audioChannels = 0;
            string videoCodec = null, audioCodec = null, decoderType = null;
            try
            {
                var vp = openPlayer.StreamInfo.GetVideoProperties();
                width = vp.Size.Width;
                height = vp.Size.Height;
                videoCodec = openPlayer.StreamInfo.GetVideoCodec();
                audioCodec = openPlayer.StreamInfo.GetAudioCodec();

                var ap = openPlayer.StreamInfo.GetAudioProperties();
                audioSampleRate = ap.SampleRate;
                audioChannels = ap.Channels;

                // AudioCodecType tells us whether the decoder is hardware or software.
                decoderType = openPlayer.AudioCodecType == CodecType.Hardware ? "Hardware" : "Software";
            }
            catch { }

            // Enumerate audio and embedded subtitle tracks via PlayerTrackInfo.
            var audioTracks = new System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>();
            var embeddedSubtitleTracks = new System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>();
            // PlayerTrackInfo exposes no Count; enumerate by index until GetLanguageCode throws.
            try
            {
                var info = openPlayer.AudioTrackInfo;
                int current = info.Selected;
                for (int i = 0; i < 32; i++)
                {
                    string lang;
                    try { lang = info.GetLanguageCode(i) ?? ""; }
                    catch { break; }
                    audioTracks.Add(new System.Collections.Generic.Dictionary<string, object>
                    {
                        ["index"] = i,
                        ["language"] = lang,
                        ["isDefault"] = i == current,
                    });
                }
            }
            catch { }
            try
            {
                var info = openPlayer.SubtitleTrackInfo;
                int current = info.Selected;
                for (int i = 0; i < 32; i++)
                {
                    string lang;
                    try { lang = info.GetLanguageCode(i) ?? ""; }
                    catch { break; }
                    embeddedSubtitleTracks.Add(new System.Collections.Generic.Dictionary<string, object>
                    {
                        ["index"] = i,
                        ["language"] = lang,
                        ["isDefault"] = i == current,
                    });
                }
            }
            catch { }

            if (!IsCurrentOpen(gen, openPlayer)) return;
            Post(() =>
            {
                if (!IsCurrentOpen(gen, openPlayer)) return;
                _eventSink?.Success(new Dictionary<string, object>
                {
                    ["event"] = "initialized",
                    ["durationMs"] = durationMs,
                    ["width"] = width,
                    ["height"] = height,
                    ["videoCodec"] = videoCodec ?? "",
                    ["audioCodec"] = audioCodec ?? "",
                    ["audioSampleRate"] = audioSampleRate,
                    ["audioChannels"] = audioChannels,
                    ["decoderType"] = decoderType ?? "",
                    ["audioTracks"] = audioTracks,
                    ["embeddedSubtitleTracks"] = embeddedSubtitleTracks,
                });
            });

            // System.Timers.Timer runs on the thread pool; Post() marshals back to
            // the EFL main thread where platform channel calls must be made.
            _positionTimer = new System.Timers.Timer(250);
            _positionTimer.Elapsed += OnPositionTick;
            _positionTimer.AutoReset = true;
            _positionTimer.Start();

            var autoPlay = args["play"] != null && Convert.ToBoolean(args["play"]);
            if (autoPlay) Play();
        }

        private bool IsCurrentOpen(int generation, Player player)
            => !_disposed && generation == _openGeneration && object.ReferenceEquals(_player, player);

        private void ApplyHttpHeaders(System.Collections.IDictionary headers)
        {
            try
            {
                if (headers["Cookie"] is string cookieStr)
                    _player.Cookie = cookieStr;
                if (headers["User-Agent"] is string uaStr)
                    _player.UserAgent = uaStr;
            }
            catch (Exception e)
            {
                Log($"{e.Message}", isError: true);
            }
        }

        private void SelectAudioTrack(int index)
        {
            try { _player.AudioTrackInfo.Selected = index; }
            catch (Exception e) { Log($"SelectAudioTrack failed: {e.Message}", isError: true); }
        }

        private void SelectSubtitleTrack(int index)
        {
            try { _player.SubtitleTrackInfo.Selected = index; }
            catch (Exception e) { Log($"SelectSubtitleTrack failed: {e.Message}", isError: true); }
        }

        private void SetVisible(bool visible)
        {
            if (_videoWindow == null) return;
            try
            {
                if (visible)
                {
                    _videoWindow.Show();
                    _videoWindow.Lower();
                    SetEmptyInputRegion();
                }
                else
                {
                    _videoWindow.Hide();
                }
            }
            catch (Exception e) { Log($"SetVisible failed: {e.Message}", isError: true); }
        }

        private void OnPositionTick(object source, ElapsedEventArgs e)
        {
            Post(() =>
            {
                if (_disposed) return;

                try
                {
                    var state = _player?.State;
                    if (state == PlayerState.Playing || state == PlayerState.Paused)
                    {
                        _eventSink?.Success(new Dictionary<string, object>
                        {
                            ["event"] = "position",
                            ["positionMs"] = _player.GetPlayPosition(),
                        });
                    }
                }
                catch { }
            });
        }

        private void Play()
        {
            try
            {
                var state = _player?.State;
                if (state == PlayerState.Ready || state == PlayerState.Paused)
                {
                    _player.Start();
                    _eventSink?.Success(new Dictionary<string, object>
                    {
                        ["event"] = "playing",
                        ["isPlaying"] = true,
                    });
                }
            }
            catch (Exception e) { Log($"{e.Message}", isError: true); }
        }

        private void Pause()
        {
            try
            {
                if (_player?.State == PlayerState.Playing)
                {
                    _player.Pause();
                    _eventSink?.Success(new Dictionary<string, object>
                    {
                        ["event"] = "playing",
                        ["isPlaying"] = false,
                    });
                }
            }
            catch (Exception e) { Log($"{e.Message}", isError: true); }
        }

        private void Stop()
        {
            try
            {
                var state = _player?.State;
                if (state == PlayerState.Playing || state == PlayerState.Paused)
                {
                    _player.Stop();
                    _eventSink?.Success(new Dictionary<string, object>
                    {
                        ["event"] = "playing",
                        ["isPlaying"] = false,
                    });
                }
            }
            catch (Exception e) { Log($"{e.Message}", isError: true); }
        }

        private async Task SeekAsync(int positionMs)
        {
            // Always record the latest requested position.
            _pendingSeekMs = positionMs;

            // If a seek is already running, let it finish and it will pick up
            // _pendingSeekMs automatically; don't stack another async chain.
            if (_isSeeking) return;

            _isSeeking = true;
            try
            {
                while (_pendingSeekMs >= 0)
                {
                    int targetMs = _pendingSeekMs;
                    _pendingSeekMs = -1;

                    var state = _player?.State;
                    if (state == PlayerState.Playing ||
                        state == PlayerState.Paused ||
                        state == PlayerState.Ready)
                    {
                        await _player.SetPlayPositionAsync(targetMs, false);
                        _eventSink?.Success(new Dictionary<string, object>
                        {
                            ["event"] = "position",
                            ["positionMs"] = targetMs,
                        });
                    }
                }
            }
            catch (Exception e) { Log($"Seek failed: {e.Message}", isError: true); }
            finally { _isSeeking = false; }
        }

        private void SetVolume(double volume)
        {
            try
            {
                if (_player != null)
                    _player.Volume = (float)Math.Max(0.0, Math.Min(1.0, volume / 100.0));
            }
            catch { }
        }

        private void SetRate(double rate)
        {
            try { _player?.SetPlaybackRate((float)rate); }
            catch { }
        }

        // Display modes: 0=contain(letterbox), 1=cover(crop), 2=fill(stretch), matches Dart's boxFitMode ordering.
        private static readonly PlayerDisplayMode[] DisplayModes =
        {
            PlayerDisplayMode.LetterBox,   // 0 = contain
            PlayerDisplayMode.CroppedFull, // 1 = cover
            PlayerDisplayMode.FullScreen,  // 2 = fill/stretch
        };

        private void SetDisplayMode(int mode)
        {
            if (_player == null) return;
            if (mode < 0 || mode >= DisplayModes.Length) return;
            try
            {
                var m = DisplayModes[mode];
                _currentDisplayMode = m;
                _player.DisplaySettings.Mode = m;
            }
            catch { }
        }

        private void SetVideoRect(System.Collections.IDictionary args)
        {
            if (_player == null || _videoWindow == null || args == null) return;
            try
            {
                // Coordinates arrive as physical pixels (Dart already multiplied by dpr).
                // Pass them straight to SetRoi; no further scaling needed.
                int left = Convert.ToInt32(args["left"]);
                int top = Convert.ToInt32(args["top"]);
                int right = Convert.ToInt32(args["right"]);
                int bottom = Convert.ToInt32(args["bottom"]);

                // OriginalOrFull is required by the Tizen API to enable SetRoi.
                // Re-apply _currentDisplayMode afterward so a user-set mode is not lost.
                _player.DisplaySettings.Mode = PlayerDisplayMode.OriginalOrFull;
                _player.DisplaySettings.SetRoi(
                    new Tizen.Multimedia.Rectangle(left, top, right - left, bottom - top));
                if (_currentDisplayMode != PlayerDisplayMode.OriginalOrFull)
                    _player.DisplaySettings.Mode = _currentDisplayMode;
            }
            catch (Exception e) { Log($"{e.Message}", isError: true); }
        }

        private static IDictionary<string, object> ErrorEvent(string code, string message)
            => new Dictionary<string, object>
            {
                ["event"] = "error",
                ["code"] = code,
                ["message"] = message,
            };

        // Marshals action to the EFL main thread (native callbacks and timer ticks
        // run on the thread pool; Flutter channel calls must be on the main thread).
        private void Post(Action action)
            => _mainContext.Post(_ => action(), null);

        private void OnVideoWindowKeyDown(object sender, EvasKeyEventArgs e)
        {
            var keyName = e.KeyName;
            Log($"Video window KeyDown: '{keyName}'");
            if (keyName != "XF86Back" && keyName != "Back") return;
            Post(() => _eventSink?.Success(new Dictionary<string, object>
            {
                ["event"] = "nativeKey",
                ["keyName"] = keyName,
            }));
        }

        private void SetEmptyInputRegion()
        {
            try
            {
                var evas = WlInput.evas_object_evas_get(_videoWindow.Handle);
                var ecoreEv = WlInput.ecore_evas_ecore_evas_get(evas);
                var wlWin = WlInput.ecore_evas_wayland2_window_get(ecoreEv);
                WlInput.ecore_wl2_window_input_region_set(wlWin, 0, 0, 0, 0);
                Log("Video window input region cleared; keyboard falls through to Flutter");
            }
            catch (Exception e)
            {
                Log($"SetEmptyInputRegion failed: {e.Message}", isError: true);
            }
        }

        private static void Log(string message, bool isError = false)
        {
            if (isError) Console.Error.WriteLine($"[TizenPlayer] {message}");
            else Console.WriteLine($"[TizenPlayer] {message}");
        }

        public void OnListen(object arguments, IEventSink events)
        {
            _eventSink = events;
        }

        public void OnCancel(object arguments)
        {
            _eventSink = null;
        }

        private void DisposePlayer()
        {
            if (_positionTimer != null)
            {
                _positionTimer.Stop();
                _positionTimer.Elapsed -= OnPositionTick;
                _positionTimer.Dispose();
                _positionTimer = null;
            }

            if (_player != null)
            {
                try
                {
                    var state = _player.State;
                    if (state == PlayerState.Playing) _player.Stop();
                    if (state != PlayerState.Idle) _player.Unprepare();
                }
                catch { }
                _player.Dispose();
                _player = null;
            }

            if (_videoWindow != null)
            {
                _videoWindow.KeyDown -= OnVideoWindowKeyDown;
                try { _videoWindow.KeyUngrab("XF86Back"); } catch { }
                try { _videoWindow.KeyUngrab("Back"); } catch { }
                _videoWindow.Hide();
            }
        }

        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            DisposePlayer();
            _eventSink = null;
        }
    }
}
