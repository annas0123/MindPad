import 'dart:async';

/// A service to notify the HomeScreen to refresh its data when a note is
/// restored from the recycle bin or other changes occur that require a refresh.
class HomeUpdater {
  // Singleton pattern
  static HomeUpdater? _instance;
  static HomeUpdater? get instance => _instance;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get stream => _controller.stream;

  // Create the instance
  HomeUpdater._() {
    _instance = this;
  }

  // Factory constructor to return the same instance
  factory HomeUpdater() {
    return _instance ?? HomeUpdater._();
  }

  // Notify HomeScreen to refresh its data
  void notifyHomeToRefresh() {
    _controller.add(true);
  }

  // Dispose the stream controller when no longer needed
  void dispose() {
    _controller.close();
    _instance = null;
  }
} 