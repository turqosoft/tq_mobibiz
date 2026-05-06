// lib/services/user_cache_service.dart
class UserCacheService {
  String? _cachedSalesPerson;
  String? _cachedLoggedUser;
  DateTime? _cacheTime;

  static const _cacheDuration = Duration(hours: 1);

  bool get isCacheValid =>
      _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration;

  String? get salesPerson => isCacheValid ? _cachedSalesPerson : null;
  String? get loggedUser => isCacheValid ? _cachedLoggedUser : null;

  void cacheSalesPerson(String salesPerson, String loggedUser) {
    _cachedSalesPerson = salesPerson;
    _cachedLoggedUser = loggedUser;
    _cacheTime = DateTime.now();
  }

  void clearCache() {
    _cachedSalesPerson = null;
    _cachedLoggedUser = null;
    _cacheTime = null;
  }
}