abstract class Disposable {
  Future<void> dispose();
}

mixin DisposableMixin implements Disposable {
  bool _isDisposed = false;
  
  bool get isDisposed => _isDisposed;
  
  void ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('Object has been disposed');
    }
  }
  
  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await onDispose();
  }
  
  Future<void> onDispose();
}