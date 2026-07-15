import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Get Current User (Kya koi user logged in hai?)
  User? get currentUser => _auth.currentUser;

  // 2. Auth State Stream (Real-time check karta hai ki user login hai ya logout)
  Stream<User?> get userStream => _auth.authStateChanges();

  // 3. REGISTER / SIGN UP (Naya User Account Banane Ke Liye)
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Sign Up Error Code: ${e.code}");
      rethrow; // Isse error screen par catch ho sakega
    } catch (e) {
      print("Register Error: ${e.toString()}");
      return null;
    }
  }

  // 4. LOGIN / SIGN IN (Existing User Ke Liye)
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Login Error Code: ${e.code}");
      rethrow; // Isse login screen par handle karne mein madad milegi
    } catch (e) {
      print("Login Error: ${e.toString()}");
      return null;
    }
  }

  // 5. LOGOUT (Sign Out Karne Ke Liye)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Logout Error: ${e.toString()}");
    }
  }
}