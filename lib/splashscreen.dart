/////// STILL TESTING ///////
///
///
// import 'package:flutter/material.dart';
// import 'main.dart'; // Root is defined in main.dart

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   SplashScreenState createState() => SplashScreenState();
// }

// class SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Wait 1 second (or adjust as needed) then navigate to Root
//     Future.delayed(const Duration(seconds: 1), () {
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (context) => const Root()),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Text(
//           'ARCHENEMY',
//           style: TextStyle(
//             fontSize: 48,
//             fontWeight: FontWeight.bold,
//             color: Colors.redAccent,
//             letterSpacing: 4,
//           ),
//         ),
//       ),
//     );
//   }
// }
