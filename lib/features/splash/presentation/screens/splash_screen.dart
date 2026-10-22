// import 'package:flutter/material.dart';

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF3B5998),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               'assets/images/logo/logo_alert360.png',
//               width: 150,
//               height: 150,
//               fit: BoxFit.contain,
//               errorBuilder: (context, error, stackTrace) {
//                 return const Icon(
//                   Icons.shield_rounded,
//                   size: 120,
//                   color: Colors.white,
//                 );
//               },
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               "Alert'360",
//               style: TextStyle(
//                 fontSize: 30,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'Votre sécurité, notre priorité',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 15, color: Colors.white70),
//             ),
//             const SizedBox(height: 36),
//             const SizedBox(
//               width: 26,
//               height: 26,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2.5,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
