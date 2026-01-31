import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4DFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const SongListScreen(),
    );
  }
}

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Canción reproduciéndose actualmente
  String _currentTitle = "Selecciona una canción";
  String _currentArtist = "Cuicatl Player";
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    
    // Escuchar cambios del reproductor para actualizar el icono de play/pause
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  // Pedir permisos de forma agresiva para asegurar que funcione
  void requestPermissions() async {
    await Permission.storage.request();
    await Permission.audio.request(); 
    await Permission.mediaLibrary.request();
    setState(() {}); // Recargar la pantalla al tener permisos
  }

  void playSong(String? uri, String title, String artist) {
    try {
      if (uri == null) return;
      _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri)));
      _audioPlayer.play();
      setState(() {
        _currentTitle = title;
        _currentArtist = artist;
      });
    } catch (e) {
      debugPrint("Error al reproducir: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tu Biblioteca"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // FutureBuilder espera a que la consulta de canciones termine
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),
        builder: (context, item) {
          if (item.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (item.data!.isEmpty) {
            return const Center(child: Text("No se encontraron canciones 😔\n(Revisa los permisos de la app)"));
          }

          // LISTA DE CANCIONES
          return ListView.builder(
            itemCount: item.data!.length,
            padding: const EdgeInsets.only(bottom: 100), // Espacio para el mini-player
            itemBuilder: (context, index) {
              var song = item.data![index];
              return ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                ),
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist ?? "Desconocido", style: const TextStyle(color: Colors.white54)),
                onTap: () {
                  playSong(song.uri, song.title, song.artist ?? "Artista");
                },
              );
            },
          );
        },
      ),
      // MINI REPRODUCTOR FLOTANTE (Abajo)
      bottomSheet: Container(
        height: 80,
        color: const Color(0xFF1E1E2C),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(Icons.music_note, color: Color(0xFF6B4DFF), size: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(_currentArtist, maxLines: 1, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 50, color: Colors.white),
              onPressed: () {
                if (_isPlaying) _audioPlayer.pause();
                else _audioPlayer.play();
              },
            )
          ],
        ),
      ),
    );
  }
}
