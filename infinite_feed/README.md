# infinite_feed

This app is a 4K wallpaper downloader.

The app is optimized for high performance.

This project uses Riverpod for state management.

## Approach

I have used a `PostRepository` — it contains the functions that make the
actual Supabase calls, including the `toggle_like` RPC function call.

This repo is then used inside the provider (`FeedProvider`).

There is a `FeedState` — an object representing the current state of the
feed, like whether there are more posts, the current list of posts, etc.

Then I made a `FeedNotifier`, which is a `StateNotifier`. It updates the
`FeedState` using the repository's functions.

`FeedNotifier` has functions like:
- `loadFirstPage()`
- `loadMore()`
- `toggleLikeOptimistic()`

`toggleLikeOptimistic` updates the UI instantly, but uses a 600ms debounce
before actually sending the request to the backend — so rapid taps don't
spam the server, but the user never feels any delay.

## Structure

```
UI (FeedScreen)
   │  ref.watch(feedProvider)         → rebuilds on state change
   │  ref.read(feedProvider.notifier) → calls actions
   ▼
FeedNotifier (business logic, debouncing, error handling)
   │
   ▼
PostRepository (raw Supabase queries — no Riverpod awareness)
```

## Verification
 
**RepaintBoundary** — Verified using Flutter DevTools' Performance tab in
profile mode while scrolling the feed continuously. Frame Time (UI) and
Frame Time (Raster) both stayed well under the 16.6ms threshold for 60fps
across all sampled frames, with zero jank (red) frames recorded. This
confirms the heavy `BoxShadow` on each card is rasterized once and reused
on subsequent frames rather than being recomputed during scroll.
 
**memCacheWidth** — Verified using DevTools' Memory tab while scrolling
through the feed. Heap memory stayed flat and low throughout the scroll
session, with external memory (where decoded image buffers live) holding
steady well under 200MB despite continuously loading new images. This is
consistent with images being decoded at their on-screen display size
rather than their original resolution.
