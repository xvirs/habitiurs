class Lazy<T> {
  final T Function() _factory;
  T? _value;
  bool _isInitialized = false;
  
  Lazy(this._factory);
  
  T get value {
    if (!_isInitialized) {
      _value = _factory();
      _isInitialized = true;
    }
    return _value!;
  }
  
  bool get isInitialized => _isInitialized;
  
  void reset() {
    _value = null;
    _isInitialized = false;
  }
}

class AsyncLazy<T> {
  final Future<T> Function() _factory;
  Future<T>? _future;
  
  AsyncLazy(this._factory);
  
  Future<T> get value {
    return _future ??= _factory();
  }
  
  bool get isStarted => _future != null;
  
  void reset() {
    _future = null;
  }
}