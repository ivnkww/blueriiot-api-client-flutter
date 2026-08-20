/// Error returned by the Blue Riiot API or thrown when a request fails.
class BlueriiotException implements Exception {
  BlueriiotException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'BlueriiotException: $message'
      : 'BlueriiotException($statusCode): $message';
}
