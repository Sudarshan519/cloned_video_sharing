import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VideoPlayerWithEmbeddedSubtitlesSwitch extends StatefulWidget {
  final String videoPath;

  VideoPlayerWithEmbeddedSubtitlesSwitch({this.videoPath});

  @override
  _VideoPlayerWithEmbeddedSubtitlesSwitchState createState() =>
      _VideoPlayerWithEmbeddedSubtitlesSwitchState();
}

class _VideoPlayerWithEmbeddedSubtitlesSwitchState
    extends State<VideoPlayerWithEmbeddedSubtitlesSwitch> {
  VlcPlayerController _vlcController;
  int selectedSubtitleIndex = 0; // Initial subtitle track
  var subtitleTrackCount = 0;
  var initialized = false;
  @override
  void initState() {
    super.initState();
    _vlcController = VlcPlayerController.network(
        'https://media.w3.org/2010/05/sintel/trailer.mp4' ?? widget.videoPath)
      ..initialize().then((_) {
        initialized = true;
        setState(() {});
        _vlcController.getSpuTracksCount().then((value) => setState(() {
              subtitleTrackCount = value;
            }));
      });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.videoPath);
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player with Embedded Subtitles (Switch)'),
      ),
      body: Center(
        child: initialized //&& _vlcController.value.isInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  VlcPlayer(
                    controller: _vlcController,
                    aspectRatio: 16 / 9, // Adjust this as needed
                  ),
                  DropdownButton<int>(
                    value: selectedSubtitleIndex,
                    items: List.generate(
                      subtitleTrackCount,
                      (index) => DropdownMenuItem<int>(
                        value: index,
                        child: Text('Subtitle Track ${index + 1}'),
                      ),
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        selectedSubtitleIndex = newValue ?? 0;
                        _vlcController.setSpuTrack(selectedSubtitleIndex);
                      });
                    },
                  ),
                ],
              )
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_vlcController.value.isPlaying) {
              _vlcController.pause();
            } else {
              _vlcController.play();
            }
          });
        },
        child: Icon(
          _vlcController.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _vlcController.dispose();
  }
}
