# ISO Build Notes

Kaizen Linux will use Fedora image-building tools to move from a post-install project to a real Fedora Remix ISO.

## Current status

The post-install installer is the source of truth.

The Kickstart file exists as an early prototype:

kickstart/kaizen-fedora.ks

## Planned build environment

The first ISO build target should be a Fedora VM/build machine, not the main Arch host.

Recommended build packages on Fedora:

sudo dnf install -y lorax pykickstart spin-kickstarts mock git

## Planned ISO path

1. Validate repository.
2. Validate Kickstart syntax.
3. Build from Kickstart using Fedora tools.
4. Test ISO in virt-manager.
5. Iterate until the live session and installer are reliable.

## Notes

Do not build directly on the main daily-driver system yet.

Use a Fedora build VM or disposable Fedora install.
