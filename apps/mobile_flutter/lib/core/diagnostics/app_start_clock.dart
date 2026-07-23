/// Marks true process cold-start time, set once at the top of `main()`
/// before `Firebase.initializeApp()`. Used to compute `appStartMs` and
/// related startup diagnostics from any part of the widget tree.
final DateTime appStartTime = DateTime.now();

int msSinceAppStart() => DateTime.now().difference(appStartTime).inMilliseconds;
