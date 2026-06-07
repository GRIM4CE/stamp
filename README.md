# Stamp

Small macOS app for stamping invoices ahead of accountant review.

Drag in many invoice PDFs at once, choose **100%** or **50%** tax deduction per
document, and the app stamps a red badge onto page 1 — auto-placed in the
largest area of whitespace so it breathes. Preview and drag the stamp to adjust,
then approve to save a new stamped PDF (originals are never modified).

Native SwiftUI + PDFKit. No runtime dependencies, no Electron.

## Build (developer)

Requires only Apple's **Command Line Tools** (no full Xcode):

```sh
xcode-select --install      # once, if not already installed
./Scripts/build-app.sh      # produces dist/Stamp.app
open dist/Stamp.app
```

Add `--universal` to also target Intel Macs:

```sh
./Scripts/build-app.sh --universal
```

### Run from source / tests

```sh
swift run Stamp        # launch the app
swift run StampTests   # run the test suite (also writes preview PNGs to /tmp)
```

### Regenerating assets

The stamp PNGs and app icon are committed, so a normal build needs no extra
tools. To regenerate them from `temp/*.svg`:

```sh
swift Scripts/rasterize-stamps.swift   # temp/*.svg  -> Resources/stamp-{100,50}.png
swift Scripts/make-icon.swift          # -> build/AppIcon-1024.png (then iconutil -> Resources/AppIcon.icns)
```

## Handing the app to someone else

The app is **ad-hoc signed**, not notarized (that needs a paid Apple Developer
account). It runs fine on the Mac that built it. When copied to another Mac,
macOS Gatekeeper quarantines it. Two reliable options:

1. **Build on her Mac (best).** Install Command Line Tools, copy this folder,
   run `./Scripts/build-app.sh`, drag `dist/Stamp.app` to `/Applications`.
   Locally built apps aren't quarantined, so it just opens.
2. **Copy the app, then clear quarantine once** (run on her Mac after copying):
   ```sh
   xattr -dr com.apple.quarantine /Applications/Stamp.app
   ```
   After that it opens normally.

For double-click-anywhere distribution you'd need the Apple Developer Program
($99/yr) to sign with a Developer ID and notarize — out of scope here.

## How it works

- **Whitespace detection** (`Sources/StampKit/PDF/WhitespaceDetector.swift`):
  rasterizes page 1 to grayscale, builds an integral image of "ink," and slides
  a stamp-sized window to find the emptiest spot, biased toward the bottom-right.
- **Stamping** (`Sources/StampKit/PDF/PDFStamper.swift`): re-renders page 1
  through a `CGPDFContext` and draws the stamp into the content stream, so it's
  flattened and permanent (not a deletable annotation). Other pages are untouched.
- **Output** (`Sources/StampKit/Services/OutputService.swift`): writes
  `<name>-stamped.pdf` to the chosen folder (default `~/Documents/Stamped Invoices`),
  appending ` 2`, ` 3`, … on collision.

## License

See [LICENSE](LICENSE).
