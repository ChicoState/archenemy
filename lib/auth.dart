import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Mainly for the User type
export 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();
User? get user => _auth.currentUser;
bool get hasUser => user != null;
Stream<User?> get stateChanges => _auth.authStateChanges();

Future<User?> signIn() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  if (googleUser == null) return null;

  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  UserCredential userCredential = await _auth.signInWithCredential(credential);
  return userCredential.user;
}

Future<void> signOut() async {
  await _googleSignIn.signOut();
  await _auth.signOut();
}
