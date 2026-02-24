import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream to listen for authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print("Error signing in with Google: $e");
      rethrow;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Error signing in with Email: $e");
      rethrow;
    }
  }

  // Sign up with Email and Password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Error signing up with Email: $e");
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  // Re-authenticate
  Future<void> reauthenticate(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("No user currently logged in.");
    }
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  // Delete Account
  Future<void> deleteAccount(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("No user currently logged in.");
    }

    try {
      // Re-authenticate User First (in case step 2 token expired, though unlikely)
      await reauthenticate(password);

      // Trigger deletion of user data from Firestore
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(user.uid);

      // 1. Delete 'swipes' subcollection
      final swipesQuery = await userRef.collection('swipes').get();
      WriteBatch batch = db.batch();
      for (var doc in swipesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 2. Delete main document
      await userRef.delete();

      // Delete the user from Firebase Auth (this automatically signs them out locally)
      await user.delete();

      // Do NOT await signOut() here because GoogleSignIn.signOut() can hang indefinitely
      // if the user had logged in via Email/Password and has no active Google session.
    } catch (e) {
      print("Error deleting account: $e");
      rethrow;
    }
  }
}
