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


UI (FeedScreen)
   │  ref.watch(feedProvider)         → rebuilds on state change
   │  ref.read(feedProvider.notifier) → calls actions
   ▼
FeedNotifier (business logic, debouncing, error handling)
   │
   ▼
PostRepository (raw Supabase queries — no Riverpod awareness)