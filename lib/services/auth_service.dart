import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(fullName);

        final defaultAvatar = AppConstants.getDefaultAvatar(fullName);
        await user.updatePhotoURL(defaultAvatar);

        await user.sendEmailVerification();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'fullName': fullName,
          'avatarUrl': defaultAvatar,
          'initialAvatarUrl': defaultAvatar,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final googleUser = await googleSignIn.authenticate();

      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          final googleAvatar =
              user.photoURL ??
              AppConstants.getDefaultAvatar(user.displayName ?? "G");

          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'fullName': user.displayName ?? 'Người dùng Google',
            'avatarUrl': googleAvatar,
            'initialAvatarUrl': googleAvatar,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final data = userDoc.data() as Map<String, dynamic>;
          final currentAvatar = data['avatarUrl'] as String?;

          if (currentAvatar != null &&
              currentAvatar.contains('ui-avatars.com') &&
              user.photoURL != null) {
            await _firestore.collection('users').doc(user.uid).update({
              'avatarUrl': user.photoURL,
              'fullName': user.displayName ?? data['fullName'],
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    } catch (e) {
      throw Exception('Lỗi đăng nhập Google. Vui lòng thử lại.');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Email này chưa được đăng ký trong hệ thống.');
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  String _handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng. Vui lòng đăng nhập.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần ít nhất 8 ký tự).';
      case 'too-many-requests':
        return 'Tài khoản tạm khóa do nhập sai nhiều lần. Hãy thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      default:
        return 'Đã xảy ra lỗi ($errorCode). Vui lòng thử lại sau.';
    }
  }
}
