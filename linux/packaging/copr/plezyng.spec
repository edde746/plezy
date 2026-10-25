Name:           plezyng
Version:        2.24.1
Release:        1%{?dist}
Summary:        Native media client for Plex, Jellyfin, and Emby
License:        GPL-3.0-only
URL:            https://github.com/snapetech-org/PlezyNG
Source0:        plezy-linux-x64.tar.gz
Source1:        plezy-linux-arm64.tar.gz
Source2:        plezy.sh
Source3:        org.snapetech.plezyng.desktop
Source4:        plezy.png
Source5:        LICENSE
BuildRequires:  tar
Requires:       gtk3
Requires:       libepoxy
Requires:       alsa-lib
Requires:       libevdev
Requires:       glib2
Requires:       libwayland-client
Requires:       libwayland-cursor
Requires:       libwayland-egl
Requires:       libglvnd
Requires:       libglvnd-egl
Requires:       libva
Requires:       libdrm
Requires:       mesa-libgbm
Requires:       libX11
Requires:       libX11-xcb
Requires:       libXext
Requires:       libxcb
ExclusiveArch:  x86_64 aarch64
AutoReqProv:    no

%description
PlezyNG is a native desktop client for Plex, Jellyfin, and Emby media servers.

%prep
%setup -q -c -T
%ifarch x86_64
tar -xzf %{SOURCE0} -C .
%else
tar -xzf %{SOURCE1} -C .
%endif

%build

%install
install -d %{buildroot}/opt/plezy
cp -a . %{buildroot}/opt/plezy/
install -Dm755 %{SOURCE2} %{buildroot}/usr/bin/plezy
install -Dm644 %{SOURCE3} %{buildroot}/usr/share/applications/org.snapetech.plezyng.desktop
install -Dm644 %{SOURCE4} %{buildroot}/usr/share/icons/hicolor/512x512/apps/plezy.png
install -Dm644 %{SOURCE5} %{buildroot}/usr/share/licenses/%{name}/LICENSE
chmod 0755 %{buildroot}/opt/plezy/plezy %{buildroot}/opt/plezy/lib/crashpad_handler

%post
/bin/chmod 0755 /opt/plezy/plezy /opt/plezy/lib/crashpad_handler 2>/dev/null || :

%files
/opt/plezy
/usr/bin/plezy
/usr/share/applications/org.snapetech.plezyng.desktop
/usr/share/icons/hicolor/512x512/apps/plezy.png
%license /usr/share/licenses/%{name}/LICENSE
