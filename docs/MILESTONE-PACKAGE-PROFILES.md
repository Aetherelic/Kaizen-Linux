# Milestone: Package Profiles

This milestone proves that Kaizen Linux can install its productivity and gaming package profiles on Fedora 44.

## Confirmed working

### Productivity

- LibreOffice
- Thunderbird
- Podman
- Distrobox
- GitHub CLI
- Flatpak
- Obsidian via Flathub
- Visual Studio Code via Flathub

### Gaming

- Steam
- Lutris
- Wine
- Winetricks
- GameMode
- MangoHud
- gamescope
- Vulkan tools
- Mesa Vulkan drivers
- Mesa DRI drivers

## Flatpak strategy

Flatpak apps are installed per-user instead of system-wide.

This avoids authentication hangs inside Hyprland or minimal desktop sessions.

## Known notes

- hyprpaper is currently optional.
- swaybg is used for the default wallpaper.
- NVIDIA driver support is not part of this milestone yet.
- Quickshell / AetherDeck is not part of this milestone yet.
