# Full Rice Integration Status

Branch: full-rice-integration

Confirmed working in installed VM: kaizen-dev-fullrice

## Working

- Installed system boots into Hyprland after manual BLS repair on this VM.
- Super + L opens hyprlock.
- Super + N opens SwayNC.
- Super + Shift + A opens Kaizen wallpaper picker.
- Wallpaper picker changes wallpaper successfully.
- swaybg is used as the Fedora-safe wallpaper backend.
- awww startup is disabled until packaged.
- Quickshell/AetherDeck startup is disabled until packaged.
- Super + T opens Kaizen Tools.
- Kaizen Tools desktop launcher appears in the app launcher.
- Kaizen Tools menu entries work.

## Committed fixes

- Fixed wallpaper picker background apply.
- Added Kaizen wallpaper collection.
- Added Kaizen beginner tools menu.
- Added Kaizen Tools desktop launcher.
- Installed custom Kaizen desktop launchers.
- Disabled unpackaged awww and Quickshell startup.
- Added Calamares shellprocess patch for Fedora BLS entries with Btrfs @boot.

## Still needs testing

- Fresh v0.2.0-alpha-test1 ISO install.
- Confirm Calamares BLS patch fixes boot without manual repair.
- Confirm fresh install includes Kaizen Tools launcher.
- Confirm fresh install has working wallpaper picker.
- Confirm fresh install does not auto-start Quickshell or awww.
