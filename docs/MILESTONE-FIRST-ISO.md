# Milestone: First Bootable ISO

Kaizen Linux successfully produced its first bootable Fedora-based ISO prototype.

## Confirmed working

- livemedia-creator ISO build completed
- ISO file was generated successfully
- ISO boots in virt-manager
- Fedora kernel boots successfully
- System reaches TTY login
- kaizen user can log in
- MOTD branding appears correctly

## Current limitation

The ISO currently boots into a text login prompt.

This is expected because the current Kickstart is still a minimal Fedora base prototype.

## Next milestone

Build a desktop-enabled ISO that includes the Kaizen Hyprland desktop directly in the image.
