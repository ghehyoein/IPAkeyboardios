# Keyboard scrolling and compatibility

The symbol browser uses one continuous `UICollectionView`, reusable cells, native
scroll physics and a cancellation-aware category strip. It does not paginate or
move the category strip automatically when the selected section changes.

Layout caches section offsets until dimensions or item counts change. Only cells
intersecting the requested rectangle receive layout attributes. A bounded cache
and UIKit prefetching prepare localized labels and font fallback checks. The
catalog indexes symbols by text. Section selection updates only on a section
boundary, and the collection no longer has a full-surface gradient mask.

These changes reduce repeated main-thread work and offscreen compositing. They do
not imply a measured frame rate or parity with Apple's private emoji keyboard.
Actual performance should be profiled on physical devices with Instruments.

Geometry uses the input window width, orientation and device idiom. Narrow iPad
windows use compact dimensions. The symbol panel retains five rows. Deployment
starts at iOS 17; fonts on older OS versions may not contain newer Unicode glyphs.
Missing glyphs display their code points without changing the inserted text.

## Public references

- Apple, [Make blazing fast lists and collection views](https://developer.apple.com/videos/play/wwdc2021/10252/).
- Apple, [Building high-performance lists and collection views](https://developer.apple.com/documentation/uikit/building-high-performance-lists-and-collection-views).
- Apple, [Prefetching collection view data](https://developer.apple.com/documentation/uikit/prefetching-collection-view-data).
- Apple, [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

`ios.yml` validates simulator behavior before release; the workflow result is the
record of which OS/device configurations actually passed. `capture_screenshots.py`
produces native simulator screenshots and a manifest identifying each language,
device and runtime. The demonstration screen is accessible from Settings.
