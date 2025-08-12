import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.sendEmailVerification();
    await _saveUserToFirestore(cred.user!);
    return cred;
  }

  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// ✅ Login / Register dengan Google
Future<UserCredential?> signInWithGoogle({required bool isRegister}) async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user == null) return null;

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (isRegister) {
      if (userDoc.exists) {
        throw Exception("Akun sudah terdaftar. Silakan login.");
      } else {
        await _saveUserToFirestore(user);
      }
    } else {
      if (!userDoc.exists) {
        throw Exception(
          "Akun belum terdaftar. Silakan daftar terlebih dahulu.",
        );
      }
    }

    return cred;
  }

  /// ✅ Menautkan akun login sekarang ke Google
  Future<void> linkWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception("Google sign-in dibatalkan");

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final user = _auth.currentUser;
    if (user == null) throw Exception("Tidak ada pengguna login");

    await user.linkWithCredential(credential);
    await _saveUserToFirestore(user);
  }

  /// ✅ Unlink akun Google dari pengguna aktif
  Future<void> unlinkGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Tidak ada pengguna login");

    try {
      await user.unlink('google.com');
      await _saveUserToFirestore(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'no-such-provider') {
        throw Exception("Akun ini belum tertaut dengan Google");
      } else {
        throw Exception("Gagal unlink akun Google: ${e.message}");
      }
    }
  }

  /// ✅ Simpan atau update user di Firestore
Future<void> _saveUserToFirestore(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();

    final userData = {
      'uid': user.uid,
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'linkedWithGoogle': user.providerData.any(
        (p) => p.providerId == 'google.com',
      ),
    };

    if (!doc.exists) {
      userData['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(userData);
    } else {
      await ref.update(userData);
    }
  }

  /// ✅ Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// ✅ Logout dari Firebase dan Google
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
