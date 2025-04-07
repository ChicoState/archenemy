import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'log.dart';

User? user;

Future<void> init() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.idTokenChanges().listen((User? newUser) {
    user = newUser;
    if (user == null) {
      log.w("User signed out");
    } else {
      log.i("User signed in");
    }
  });

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
