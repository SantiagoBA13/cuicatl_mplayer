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
  // MODO INMERSIVO: Oculta barras de sistema
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
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E1E2C),
        ),
      ),
      home: const RootHandler(),
    );
  }
}
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
    setState(() { _hasName = prefs.containsKey('userName'); });
  }
  @override
  Widget build(BuildContext context) {
    if (_hasName == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_hasName == false) return const OnboardingScreen();
    return const MainHomeScreen();
  }
}

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
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainHomeScreen()));
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
      extendBody: true,
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
                            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("For you ($_userName)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              _buildForYouCard(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text("Popular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    if (item.data == null || item.data!.isEmpty) return const Center(child: Text("Sin canciones."));
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
        gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20, child: Icon(Icons.headphones, size: 150, color: Colors.black.withOpacity(0.1))),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Music for Your Mood", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("Soundtracks that match your\nevery mood.", style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(color: const Color(0xFF1E1E2C).withOpacity(0.9), borderRadius: BorderRadius.circular(30)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.home_filled, color: Color(0xFF8B5CF6)),
          Icon(Icons.explore_outlined, color: Colors.white30),
          Icon(Icons.favorite_border, color: Colors.white30),
          Icon(Icons.person_outline, color: Colors.white30),
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
          id: song.id, type: ArtworkType.AUDIO,
          nullArtworkWidget: Container(width: 50, height: 50, color: Colors.white10, child: const Icon(Icons.music_note)),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist ?? "Artist", maxLines: 1, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white),
      onTap: () {
        Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => PlayerScreen(song: song, audioPlayer: _audioPlayer),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ));
      },
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final SongModel song;
  final AudioPlayer audioPlayer;
  const PlayerScreen({super.key, required this.song, required this.audioPlayer});
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
      await widget.audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(widget.song.uri!)));
      widget.audioPlayer.play();
      widget.audioPlayer.playerStateStream.listen((state) { if(mounted) setState(() => _isPlaying = state.playing); });
      widget.audioPlayer.durationStream.listen((d) { if(mounted) setState(() => _duration = d ?? Duration.zero); });
      widget.audioPlayer.positionStream.listen((p) { if(mounted) setState(() => _position = p); });
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: const Key("player"),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(context)),
          title: Text(widget.song.artist ?? "Artist", style: const TextStyle(fontSize: 14, color: Colors.white70)),
          centerTitle: true,
          actions: [IconButton(icon: const Icon(Icons.graphic_eq), onPressed: () {})],
        ),
        body: Stack(
          children: [
            Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [const Color(0xFF6B4DFF).withOpacity(0.8), const Color(0xFF0F0F1E)],
            ))),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
                        Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Container(
                    height: 320, width: 320,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40)]),
                    child: ClipRRect(borderRadius: BorderRadius.circular(30), child: QueryArtworkWidget(
                      id: widget.song.id, type: ArtworkType.AUDIO, artworkHeight: 320, artworkWidth: 320,
                      nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, size: 100)),
                    )),
                  ),
                  const SizedBox(height: 40),
                  Align(alignment: Alignment.centerLeft, child: Text(widget.song.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),
                  SizedBox(height: 60, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(30, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2), width: 4, height: 10 + (i % 5) * 10.0 + (_isPlaying ? 10 : 0),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(5)),
                  )))),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), trackHeight: 2),
                    child: Slider(
                      activeColor: Colors.white, inactiveColor: Colors.white24,
                      min: 0, max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                      onChanged: (v) => widget.audioPlayer.seek(Duration(seconds: v.toInt())),
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 40, color: Colors.white), onPressed: () {}),
                    GestureDetector(
                      onTap: () => _isPlaying ? widget.audioPlayer.pause() : widget.audioPlayer.play(),
                      child: Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: const Color(0xFF6B4DFF), size: 30),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 40, color: Colors.white), onPressed: () {}),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
