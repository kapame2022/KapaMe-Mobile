# Focused trip pages

Service selection stays on Home. The selected map shows route controls for booking or the selected request for driving. Booking adds a review and confirmation screen, and trip details show the route, contact action and saved pick-up map.

## Review screens

![private ride](focused-trip-pages/private-ride.png)

## Validation

The Flutter suite checks all eight service pages and the booking review and retry flow. Screenshot capture passed.

The screenshot shows a location-pending test fixture. Native map tiles, permissions and live booking still need a device smoke test.

Screenshots render production widgets with synthetic review data. Recreate them from this worktree:

```sh
FLUTTER_ROOT=/path/to/flutter flutter test --no-pub test/focused_trip_pages_review_test.dart --dart-define=CAPTURE_REVIEW=true
```
