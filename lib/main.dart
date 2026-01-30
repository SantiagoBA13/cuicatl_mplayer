import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CuicatlApp());
}

class CuicatlApp extends StatelessWidget {
  const CuicatlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuicatl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        primaryColor: const Color(0xFF6B4DFF),
      ),
      home: const MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E2E4D), Color(0xFF0F0F1E)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Carátula simulada
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4DFF).withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(Icons.music_note, size: 120, color: Colors.white30),
            ),
            const SizedBox(height: 40),
            // Títulos
            const Text(
              "Sapphire",
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              "Cuicatl Demo",
              style: TextStyle(fontSize: 18, color: Colors.white54),
            ),
            const SizedBox(height: 40),
            // Controles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 40),
                    onPressed: () {}, color: Colors.white),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4DFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4DFF).withOpacity(0.5),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                ),
                IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 40),
                    onPressed: () {}, color: Colors.white),
              ],
            )
          ],
        ),
      ),
    );
  }
}
