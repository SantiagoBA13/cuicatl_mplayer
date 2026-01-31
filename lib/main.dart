import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // MODO INMERSIVO TOTAL (Camuflaje de barras)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const CuicatlApp());
}

class CuicatlApp extends StatelessWidget {
  const CuicatlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuicatl Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E), // Fondo Deep Purple
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6), // Violeta ECHOO
          secondary: Color(0xFFEC4899), // Rosa neón
          surface: Color(0xFF1E1E2C),
        ),
      ),
      home: const RootHandler(),
    );
  }
}

// --- GESTOR DE INICIO (¿Ya sabemos su nombre?) ---
class RootHandler extends StatefulWidget {
  const RootHandler({super.key});
  @override
  State<RootHandler> createState() => _RootHandlerState();
}

class _RootHandlerState extends State<RootHandler> {
  bool? _hasName;

  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  Future<void> _checkUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasName = prefs.containsKey('userName');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasName == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_hasName == false) return const OnboardingScreen();
    return const MainHomeScreen();
  }
}

// --- PANTALLA DE BIENVENIDA ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _saveName() async {
    if (_nameController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4C1D95), Color(0xFF0F0F1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text("Bienvenido a Cuicatl", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Tu experiencia de audio definitiva.", style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "¿Cómo te llamas?",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Comenzar", style: TextStyle(color: Colors.white, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA PRINCIPAL (HOME - Imagen Derecha) ---
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});
  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _userName = "Usuario";

  @override
  void initState() {
    super.initState();
    _loadName();
    _requestPermissions();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? "Usuario");
  }

  void _requestPermissions() async {
    await [Permission.storage, Permission.audio, Permission.mediaLibrary].request();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Para que el contenido fluya bajo la barra de navegación
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF0F0F1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ECHOO", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    IconButton(icon: const Icon(Icons.search, size: 28), onPressed: () {}),
                  ],
                ),
              ),
              
              // TABS (Pills)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildTab("All", true),
                    _buildTab("Music", false),
                    _buildTab("Podcasts", false),
                    _buildTab("Books", false),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION: FOR YOU (Tarjeta Verde)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("For you ($ _userName)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              _buildForYouCard(),

              const SizedBox(height: 20),

              // SECTION: POPULAR (Lista de canciones)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Popular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text("Show all", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              
              Expanded(
                child: FutureBuilder<List<SongModel>>(
                  future: _audioQuery.querySongs(
                    sortType: SongSortType.DATE_ADDED,
                    orderType: OrderType.DESC_OR_GREATER,
                    uriType: UriType.EXTERNAL,
                    ignoreCase: true,
                  ),
                  builder: (context, item) {
                    if (item.data == null || item.data!.isEmpty) {
                      return const Center(child: Text("Sin canciones."));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: item.data!.length,
                      itemBuilder: (context, index) {
                        return _buildSongTile(item.data![index], item.data!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF8B5CF6) : Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.white60)),
    );
  }

  Widget _buildForYouCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)], // Verde estilo imagen
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, bottom: -20,
            child: Icon(Icons.headphones, size: 150, color: Colors.black.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Music for Your Mood", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Soundtracks that match your\nevery mood.", style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text("Check out"), SizedBox(width: 5), Icon(Icons.play_arrow, size: 16)],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSongTile(SongModel song, List<SongModel> queue) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          nullArtworkWidget: Container(
            width: 50, height: 50, color: Colors.white10,
            child: const Icon(Icons.music_note, color: Colors.white30),
          ),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(song.artist ?? "Desconocido", maxLines: 1, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
        child: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
      ),
      onTap: () {
        // ABRIR REPRODUCTOR FULL SCREEN
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => PlayerScreen(song: song, audioPlayer: _audioPlayer, fullQueue: queue),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_filled, true),
          _navItem(Icons.explore_outlined, false),
          _navItem(Icons.favorite_border, false),
          _navItem(Icons.person_outline, false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: isActive ? const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle) : null,
      child: Icon(icon, color: isActive ? Colors.white : Colors.white30),
    );
  }
}

// --- PANTALLA REPRODUCTOR (PLAYER - Imagen Izquierda) ---
class PlayerScreen extends StatefulWidget {
  final SongModel song;
  final AudioPlayer audioPlayer;
  final List<SongModel> fullQueue;

  const PlayerScreen({super.key, required this.song, required this.audioPlayer, required this.fullQueue});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // Configurar audio de alta calidad
      await widget.audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(widget.song.uri!)),
        preload: true,
      );
      widget.audioPlayer.play();
      
      widget.audioPlayer.playerStateStream.listen((state) {
        if(mounted) setState(() => _isPlaying = state.playing);
      });

      widget.audioPlayer.durationStream.listen((d) {
        if(mounted) setState(() => _duration = d ?? Duration.zero);
      });

      widget.audioPlayer.positionStream.listen((p) {
        if(mounted) setState(() => _position = p);
      });

    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // GESTOS: Deslizar abajo para cerrar
    return Dismissible(
      key: const Key("player"),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.song.artist ?? "Artista", style: const TextStyle(fontSize: 14, color: Colors.white70)),
          centerTitle: true,
          actions: [
             // Botón de Ecualizador (Simulado por ahora)
             IconButton(icon: const Icon(Icons.graphic_eq), onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ecualizador Activado: Bass Boost")));
             }),
          ],
        ),
        body: Stack(
          children: [
            // FONDO CON BLUR DINÁMICO
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6B4DFF).withOpacity(0.8),
                    const Color(0xFF0F0F1E),
                  ],
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),

            // CONTENIDO PRINCIPAL
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  // CARÁTULA GIGANTE
                  Container(
                    height: 320,
                    width: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: QueryArtworkWidget(
                        id: widget.song.id,
                        type: ArtworkType.AUDIO,
                        artworkHeight: 320,
                        artworkWidth: 320,
                        nullArtworkWidget: Container(
                          color: Colors.white10,
                          child: const Icon(Icons.music_note, size: 100, color: Colors.white30),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // TÍTULO E INFO
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.song.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(widget.song.year != null ? "Lanzamiento: ${widget.song.year}" : "Desconocido", 
                             style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // VISUALIZADOR DE ONDA (Simulado visualmente estilo imagen)
                  SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(30, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: 10 + (index % 5) * 10.0 + (_isPlaying ? 10 : 0), // Animación simple
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BARRA DE PROGRESO
   
