import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/firebase.dart' as fb;

final class CreatorAvatarService {
  CreatorAvatarService({
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _auth = auth ?? fb.tryFirebaseAuth(),
        _storage = storage ?? fb.tryFirebaseStorage(),
        _picker = picker ?? ImagePicker();

  final FirebaseAuth? _auth;
  final FirebaseStorage? _storage;
  final ImagePicker _picker;

  /// Picks an image and uploads it to profile_pictures/{uid}/avatar.jpg,
  /// returning the download URL — replaces the raw URL text field that
  /// previously let a creator paste in any arbitrary image link.
  ///
  /// Uses profile_pictures/, not the docs' example creatorAvatars/ path —
  /// storage.rules only grants owner write access under profile_pictures/;
  /// creatorAvatars/ isn't listed there and would fall through to the
  /// catch-all `allow write: if false` rule.
  Future<String?> pickAndUpload() async {
    final auth = _auth;
    if (auth == null) throw StateError('Firebase not initialized');
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be signed in.');
    }

    final storage = _storage;
    if (storage == null) throw StateError('Firebase not initialized');

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return null;

    final reference = storage.ref('profile_pictures/$uid/avatar.jpg');
    await reference.putFile(
      File(image.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return reference.getDownloadURL();
  }
}