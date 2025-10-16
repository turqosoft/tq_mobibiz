// class ApiException implements Exception {
//   final String? _message;
//   final String? prefix;

//   ApiException([this._message, this.prefix]);

//   @override
//   String toString() {
//     return _message ?? "";
//   }
// }

// class FetchDataException extends ApiException {
//   FetchDataException([String? message]) : super(message, "Error during communication");
// }
// class NoInternetException extends ApiException {
//   NoInternetException([String? message]) : super(message, "No internet connection");
// }

// class BadRequestException extends ApiException {
//   BadRequestException([String? message]) : super(message, "Invalid request");
// }

// class UnauthorisedException extends ApiException {
//   UnauthorisedException([message]) : super(message, "Unauthorised:");
// }

// class InvalidInputException extends ApiException {
//   InvalidInputException([String? message]) : super(message, "Invalid Input:");
// }

// class ServerException extends ApiException {
//   ServerException([String? message]) : super(message, "Internal Server Error");
// }

//  ApiException handleError(int statusCode) {
//     switch (statusCode) {
//       case 400:
//         return BadRequestException("Invalid request");
//       case 401:
//         return UnauthorisedException("Unauthorised");
//       case 500:
//         return ServerException("Internal Server Error");
//       default:
//         return ApiException("Unexpected error occurred");
//     }
//  }