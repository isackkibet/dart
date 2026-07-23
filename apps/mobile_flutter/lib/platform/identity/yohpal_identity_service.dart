import 'yohpal_identity.dart';

abstract class YohPalIdentityService {
  Stream<YohPalIdentity?> watchCurrentIdentity();
  Future<YohPalIdentity?> getCurrentIdentity();
  Future<void> signOut();
  Future<bool> hasRole(String role);
}
