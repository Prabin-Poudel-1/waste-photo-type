class AppFailure implements Exception {
  final String message;
  final bool permissionDenied;

  const AppFailure(
      this.message, {
        this.permissionDenied = false,
      });

  @override
  String toString() => message;
}// Placeholder: paste the contents of mobile/lib/core/errors/app_failure.dart from your app here.
