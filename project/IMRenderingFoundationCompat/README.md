# IMRenderingFoundationCompat

Launch-only compatibility layer for running Lion iChat 6.0.2 on Mac OS X Snow Leopard 10.6.8.

## Why it exists

Lion iChat directly imports 36 symbols from `IMRenderingFoundation`. Snow Leopard already provides 26 of them. The missing Lion ABI surface observed during bring-up is:

- `OBJC_CLASS_$_ArchivedMessagePlaceholder`
- `OBJC_CLASS_$_BaseInstantMessage`
- `OBJC_IVAR_$_BaseInstantMessage._bgColor`
- `OBJC_METACLASS_$_BaseInstantMessage`
- `RectToFitInAccordingToHeight`
- `RectToFitInAccordingToWidth`
- `kAttachedFileURLAttributeName`
- `kInlineFileURLAttributeName`
- `kOriginalFontAttributeName`
- `kTextEquivalentAttributeName`

The shim re-exports Snow Leopard's native `IMRenderingFoundation` for the symbols Snow already implements and supplies only the missing Lion-facing ABI.

## Observed Lion class ABI

`BaseInstantMessage`:

- Lion superclass: `IMMessage`
- `instanceStart = 120`
- `_fgColor @ 120`
- `_bgColor @ 128`
- `instanceSize = 136`

No exported `OBJC_CLASS_$_IMMessage` was found in the searched Snow Leopard framework binaries. For Milestone 1, the compatibility class derives from `NSObject` and uses explicit padding to preserve the imported `_bgColor` offset without registering a speculative duplicate `IMMessage` class.

`ArchivedMessagePlaceholder`:

- superclass: `NSObject`
- `_message @ 8`
- `_chatItem @ 16`
- `instanceSize = 24`

## Geometry helpers

The Lion binary exports `RectToFitInAccordingToHeight` and `RectToFitInAccordingToWidth` as normal C text symbols, but no public prototype has been located. Their current implementations are deliberately marked launch-only and use the surrounding `RectToFitIn` geometry-helper convention. Do not treat their exact semantics as verified until call sites or a private header establish the original prototypes.

## Scope

This target is for Milestone 1 only: launch the Lion iChat GUI on Snow Leopard. It is not a full reimplementation of Lion `IMRenderingFoundation`.
