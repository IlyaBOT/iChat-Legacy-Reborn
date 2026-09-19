# BatchCompat

Batch ABI compatibility pack for the iChat 6-on-Snow-Leopard Milestone 1 launch path.

Targets:

- AppKitCompat: re-exports Snow AppKit; adds Lion window notifications, NSTableCellView and NSTableRowView.
- CoreServicesCompat: re-exports Snow CoreServices; adds the observed LaunchServices key and a launch-safe Metadata sort shim.
- QuartzCompat: re-exports Snow Quartz; adds QLSeamlessOpener and the ImageKit faces-album key.
- ScreenSharingCompat: re-exports Snow ScreenSharing; adds the Lion-only classes/functions directly imported by iChat.
- LibSystemCompat: re-exports Snow libSystem; adds strnlen and Lion bootstrap_*3 compatibility wrappers.

Exact string constant values are generated at build time from the user's local Lion binaries by tools/generate_batch_constants.py. No Apple binaries are stored in this repository.

The class/function implementations are intentionally narrow and launch-oriented. Feature-complete behavior (especially view-based tables and Screen Sharing) is a later milestone.
