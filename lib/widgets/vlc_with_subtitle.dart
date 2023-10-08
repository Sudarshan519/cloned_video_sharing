// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// class VideoPlayerWithSubtitles extends StatefulWidget {
//   final String videoPath;
//   final String subtitlePath;

//   VideoPlayerWithSubtitles({required this.videoPath, required this.subtitlePath});

//   @override
//   _VideoPlayerWithSubtitlesState createState() => _VideoPlayerWithSubtitlesState();
// }

// class _VideoPlayerWithSubtitlesState extends State<VideoPlayerWithSubtitles> {
//   late VideoPlayerController _videoController;
//   late VlcPlayerController _subtitleController;

//   @override
//   void initState() {
//     super.initState();
//     _videoController = VideoPlayerController.asset(widget.videoPath)
//       ..initialize().then((_) {
//         setState(() {});
//       });

//     _subtitleController = VlcPlayerController.network(widget.subtitlePath)
//       ..initialize().then((_) {
//         setState(() {});
//       });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Player with Subtitles'),
//       ),
//       body: Center(
//         child: _videoController.value.initialized
//             ? Stack(
//                 alignment: Alignment.bottomCenter,
//                 children: <Widget>[
//                   AspectRatio(
//                     aspectRatio: _videoController.value.aspectRatio,
//                     child: VideoPlayer(_videoController),
//                   ),
//                   VlcPlayer(
//                     controller: _subtitleController,
//                     aspectRatio: _videoController.value.aspectRatio,
//                   ),
//                 ],
//               )
//             : CircularProgressIndicator(),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             if (_videoController.value.isPlaying) {
//               _videoController.pause();
//               _subtitleController.pause();
//             } else {
//               _videoController.play();
//               _subtitleController.play();
//             }
//           });
//         },
//         child: Icon(
//           _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _videoController.dispose();
//     _subtitleController.dispose();
//   }
// }
