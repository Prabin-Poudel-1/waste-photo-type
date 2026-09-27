class AppFailure implements Exception {
  final String message;
  final bool permissionDenied;
  const AppFailure(this.message, {this.permissionDenied = false});
  @override
  String toString() => message;
}
