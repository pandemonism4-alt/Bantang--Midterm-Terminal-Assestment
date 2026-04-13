import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

/// Wraps FirebaseAuth with clean sign-in, register, and sign-out methods.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Stream of the currently authenticated user (null when signed out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the current user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Signs in with [email] and [password].
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Log the login activity
      await _firestoreService.logActivity(
        type: 'login',
        details: 'User logged in via mobile app.',
      );
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  /// Creates a new account with [email], [password], and optional [displayName].
  Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      // Log the registration activity
      await _firestoreService.logActivity(
        type: 'registration',
        details: 'New account created: $email',
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _firestoreService.logActivity(
      type: 'logout',
      details: 'User logged out.',
    );
    await _auth.signOut();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
