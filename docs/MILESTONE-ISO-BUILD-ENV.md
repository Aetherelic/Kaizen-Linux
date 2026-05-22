# Milestone: ISO Build Environment

This milestone proves that a Fedora build VM can prepare the tools needed for Kaizen Linux ISO work.

## Confirmed working

- Fedora VM build environment
- Lorax image tooling
- livemedia-creator
- pykickstart / ksvalidator
- mock group setup
- Kickstart validation path

## Notes

- spin-kickstarts is optional because package availability can vary.
- The post-install installer remains the source of truth.
- The current Kickstart is still a prototype.
- The next milestone is the first bootable ISO build attempt.
