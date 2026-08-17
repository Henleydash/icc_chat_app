import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models.dart';

/// Gère l'authentification via un compte Google (Firebase Auth +
/// google_sign_in). C'est Google qui garantit la sécurité et l'unicité du
/// compte — l'app se contente de créer (au premier lancement) ou de
/// retrouver le profil correspondant dans Firestore.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn(scopes: ['email']);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  /// Ouvre la fenêtre de connexion Google, authentifie l'utilisateur auprès
  /// de Firebase, puis crée son profil Firestore s'il n'existe pas encore.
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // L'utilisateur a fermé la fenêtre de connexion Google.
      throw AuthException('Connexion annulée.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    late final UserCredential userCred;
    try {
      userCred = await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }

    final user = userCred.user!;
    final docRef = _db.collection('users').doc(user.uid);
    final existing = await docRef.get();

    if (!existing.exists) {
      await docRef.set({
        'username': user.displayName ?? googleUser.displayName ?? 'Étudiant',
        'email': user.email ?? googleUser.email,
        'photoUrl': user.photoURL ?? googleUser.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final doc = await docRef.get();
    return AppUser.fromDoc(doc);
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Ce compte Google est déjà associé à une autre méthode de connexion.';
      case 'network-request-failed':
        return 'Connexion internet indisponible. Réessaie.';
      default:
        return 'La connexion a échoué. Réessaie.';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<AppUser?> fetchCurrentAppUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Stream<AppUser?> watchCurrentAppUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
        );
  }
}

/// Exception dédiée pour porter un message déjà prêt à afficher à
/// l'utilisateur, indépendamment du code d'erreur Firebase sous-jacent.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
