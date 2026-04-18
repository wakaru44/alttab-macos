# Lessons Learnt

## 2026-04-06: ScreenCaptureKit Migration & TCC Challenges

### Deprecated CGWindowListCreateImage
- `CGWindowListCreateImage` is obsolete on macOS 15 (Sequoia) - returns `nil` silently
- Apple deprecated this API with compiler warnings
- **Solution**: Migrated to ScreenCaptureKit (`SCScreenshotManager.captureImage`)
- Raised minimum deployment target from macOS 13.0 → **14.0** (Sonoma)
  - `SCScreenshotManager` is only available in macOS 14.0+
  - macOS 13 (Ventura) is EOL anyway

### TCC (Transparency, Consent, and Control) Hell

#### The Core Problem
- **Ad-hoc signing** (development builds) creates a new signature every rebuild
- TCC caches permission decisions based on code signature
- Each rebuild = different signature = TCC gets confused
- Result: TCC claims "user declined" when user was never asked

#### What We Tried (and failed)
1. ❌ `tccutil reset ScreenCapture com.alttab.app` - doesn't work if bundle not in database
2. ❌ Clearing build artifacts alone - not enough
3. ❌ Killing `tccd` daemon - helps but not sufficient
4. ❌ Programmatically requesting permission on toggle - fails silently if TCC has cached denial

#### What Actually Works
1. **Manual addition to System Settings**: Open System Settings → Privacy & Security → Screen Recording → Click "+" → Add the app manually

2. **Production solution**: Sign with a stable Apple Developer certificate (not ad-hoc)
   - TCC uses code signature to identify "same app" across builds
   - Ad-hoc signing = unstable identity = TCC confusion
   - Developer ID signing = stable identity = TCC remembers permissions correctly

#### Key TCC Insights
- **AdhocSignatureCache** at `~/Library/Application Support/com.apple.TCC/AdhocSignatureCache/` caches old denials
- TCC daemon (`tccd`) must be killed to reload permission state
- Launch Services database can also cache stale app metadata
- Multiple app instances (e.g., debug build + installed release) confuse TCC further

**Sources:**
- [Apple Developer Forums - TCC permissions](https://developer.apple.com/forums/thread/730043)
- [The Eclectic Light Company - TCC woes](https://eclecticlight.co/2023/02/09/should-you-reset-its-database-or-delete-it-the-woes-of-tcc/)
- [Michael Tsai - Resetting TCC](https://mjtsai.com/blog/2023/02/09/resetting-tcc/)

### Entitlements Are Required
`ScreenCaptureKit` requires explicit entitlement:
```xml
<key>com.apple.security.personal-information.screen-capture</key>
<true/>
```

Added to `AltTab/AltTab/AltTab.entitlements` - verify with:
```bash
codesign -d --entitlements - path/to/AltTab.app
```

### os.log vs NSLog
- `os.log`'s `Logger` writes to unified logging system (not stdout/stderr)
- Our debug logs redirect stdout/stderr to `/tmp/alttab-debug.log`
- **Result**: `os.log` messages were invisible in our logs
- **Solution**: Use `NSLog()` for development debugging (writes to stderr)

### Caching Strategy
- **Problem**: Icons loaded first, then thumbnails "popped in" a second later (jarring UX)
- **Root cause**: Cache was populated asynchronously in background thread
- **Solution**: Apply cached thumbnails **synchronously** before showing UI
  - First pass: Check cache, apply immediately
  - Return to UI with cached thumbnails (instant!)
  - Second pass: Capture only cache misses in background
  - Update UI when fresh captures complete

Result: Second+ invocation shows thumbnails instantly (no flash!)

### UI Improvements
- Added app icon badge (32x32) overlaid on thumbnails in bottom-right corner
- Helps users identify which app each window belongs to
- Badge only shows when thumbnail exists (hidden for icon fallback)

### Settings Window Architecture
- Created proper Settings window (not just menu toggle)
- Permission management centralized in one place
- Real-time permission status checking every 2 seconds
- Direct links to System Settings for manual permission grants
- **Lesson**: Complex UX (permission requests) needs proper UI, not just alerts

### Unresolved Issues

#### Window Enumeration Problems
- `CGWindowListCopyWindowInfo` returns 25 windows, but only 8 pass filters
- Filters in `parseWindowInfo`: `layer == 0`, `width > 0`, `height > 0`
- Likely too aggressive - filtering out valid windows
- Current window sometimes missing from list
- Minimized windows taking precedence over active windows in MRU ordering
- **Need investigation**: Why are 17 windows being filtered? Are filter criteria too strict?

#### Screen Recording Permission Check is Expensive
- **CRITICAL**: Calling `SCShareableContent.current` to check permission is extremely expensive
- Doing this every 2 seconds in Settings window caused 60% CPU usage on WindowServer
- The check itself can fail even when permission is actually granted (false negative)
- **Discovery**: Constant polling/checking eventually "warmed up" TCC and made it work
- **Solution**:
  - Slow down timer from 2s → 5s
  - Make permission check optimistic (assume granted if app is in System Settings list)
  - Don't call `SCShareableContent.current` just to check - only call when actually capturing

**Lesson**: Permission checks should be lightweight. Don't repeatedly call expensive APIs to verify permissions.

## Multiple Instance Mixup (Previous Issue)

At some point I had 2 different builds of the app coexisting somehow.
I had to clean up everything to find it and remove it.

**Location found**: `/Users/jmorales/Applications/AltTab.app` (old installed version)

**Lesson**: Always check for existing installed versions before debugging permission issues.
