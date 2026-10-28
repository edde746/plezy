-keep class org.snapetech.plezyng.games.steam.EmbeddedSteam { public static *; }
-keep class org.snapetech.plezyng.games.steam.NativeSteam { *; }
-keep class org.snapetech.plezyng.games.steam.SteamDecoder { public boolean onVideo(...); public boolean onFrame(...); public boolean onAudio(...); public void onSamples(...); }
-keep class org.snapetech.plezyng.games.steam.SteamStreamView {
    public <init>(android.content.Context, java.util.Map);
    public void setAudioEnabled(boolean);
    public void setInputEnabled(boolean);
    public void setOnFailure(java.lang.Runnable);
    public void setOnStateChanged(java.lang.Runnable);
    public java.lang.String getSessionState();
    public boolean isFailed();
    public void toggleTouchControls();
    public void setControllerState(java.util.Map, java.util.Map);
    public void inputKey(java.lang.String, boolean);
    public void resetInput();
    public void close();
    public void awaitTermination();
}
