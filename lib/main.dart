import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const apiKey = 'YOUR_API_KEY';
const playlistId = 'YOUR_PLAYLIST_ID';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PlaylistHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PlaylistHome extends StatefulWidget {
  const PlaylistHome({Key? key}) : super(key: key);

  @override
  State<PlaylistHome> createState() => _PlaylistHomeState();
}

class _PlaylistHomeState extends State<PlaylistHome> {
  List videos = [];

  @override
  void initState() {
    super.initState();
    fetchPlaylist();
  }

  Future<void> fetchPlaylist() async {
    final url =
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=60&playlistId=$playlistId&key=$apiKey';
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);
    setState(() {
      videos = data['items'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Playlist'),
        backgroundColor: Colors.redAccent,
      ),
      body: videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, i) {
                final snippet = videos[i]['snippet'];
                final videoId = snippet['resourceId']['videoId'];
                return Card(
                  color: Colors.grey[900],
                  child: ListTile(
                    leading: Image.network(snippet['thumbnails']['default']['url']),
                    title: Text(snippet['title'],
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(videoId: videoId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  const VideoPlayerScreen({required this.videoId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
    );
  }
}