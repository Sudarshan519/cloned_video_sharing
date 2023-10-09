import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VideoPlayerWithSubtitles extends StatefulWidget {
  final String videoPath;
  final String subtitlePath;

  VideoPlayerWithSubtitles({this.videoPath, this.subtitlePath});

  @override
  _VideoPlayerWithSubtitlesState createState() =>
      _VideoPlayerWithSubtitlesState();
}

class _VideoPlayerWithSubtitlesState extends State<VideoPlayerWithSubtitles> {
  VlcPlayerController _videoController;
  VlcPlayerController _subtitleController;
  var initialized = false;

  var sliderPosition = Duration();

  bool _isSliderMoving;
  setPlayer() async {
    print(widget.videoPath);
    if (widget.videoPath == null) return;
    _videoController = VlcPlayerController.network(
        // widget.videoPath ??
        "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4" ??
            widget.videoPath,
        autoInitialize: true,
        autoPlay: true, onInit: () {
      print("INIT");
      _videoController.addListener(() {
        sliderPosition = _videoController.value.position;
        setState(() {});
      });
    });
    setState(() {
      initialized = true;
    });
  }

  @override
  void initState() {
    super.initState();
    setPlayer();
    // _videoController = VideoPlayerController.asset(widget.videoPath)
    //   ..initialize().then((_) {
    //     setState(() {});
    //   });

    // _subtitleController = VlcPlayerController.network(widget.subtitlePath)
    //   ..initialize().then((_) {
    //     initialized=true;
    //     setState(() {});
    //   });
  }

  @override
  Widget build(BuildContext context) {
    var max = 100.0;
    var colorTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player with Subtitles'),
      ),
      body: (widget.videoPath == null)
          ? Text("No Video")
          : !initialized
              ? CircularProgressIndicator()
              : Column(
                  children: [
                        LayoutBuilder(
                          builder: (_, constraints) => VlcPlayer(
                            controller: _videoController,
                            aspectRatio: 16 / 9,
                          ),
                        ),
                        Row(children: [
                          Text(printDuration(sliderPosition) +
                              "/" +
                              printDuration(_videoController.value.duration)),
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 30,
                              ),
                              padding: const EdgeInsets.only(
                                  bottom: 8, left: 10, right: 10),
                              alignment: Alignment.center,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackShape: MSliderTrackShape(),
                                  showValueIndicator: ShowValueIndicator.always,
                                  thumbColor: colorTheme,
                                  activeTrackColor: colorTheme,
                                  trackHeight: 10,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 4.0),
                                ),
                                child: Slider(
                                  min: 0,
                                  divisions: null,
                                  value:
                                      sliderPosition.inMilliseconds.toDouble(),
                                  activeColor: Colors.red,
                                  onChangeStart: (v) {
                                    onChangedSliderStart();
                                  },
                                  onChangeEnd: (v) {
                                    onChangedSliderEnd();
                                    seekTo(
                                      Duration(milliseconds: v.floor()),
                                    );
                                  },
                                  label: printDuration(sliderPosition),
                                  max: _videoController
                                      .value.duration.inMilliseconds
                                      .toDouble(),
                                  onChanged: _onChangedSlider,
                                ),
                              ),
                            ),
                          )
                        ])
                      ] ??
                      Center(
                        child: initialized
                            ? Stack(
                                alignment: Alignment.bottomCenter,
                                children: <Widget>[
                                  // AspectRatio(
                                  //   aspectRatio: _videoController.value.aspectRatio,
                                  //   child: VideoPlayer(_videoController),
                                  // ),
                                  VlcPlayer(
                                    controller: _subtitleController,
                                    aspectRatio:
                                        _videoController.value.aspectRatio,
                                  ),
                                ],
                              )
                            : CircularProgressIndicator(),
                      ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_videoController.value.isPlaying) {
              _videoController.pause();
              _subtitleController.pause();
            } else {
              _videoController.play();
              _subtitleController.play();
            }
          });
        },
        child: Icon(
          (Icons.play_arrow) ??
              (_videoController.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _videoController.dispose();
  }

  printDuration(Duration duration) {
    if (duration == null) return "--:--";

    /*String twoDigits(int n) {
    if (n >= 10||n < 0) return "$n";
    return "0$n";
  }*/
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String twoDigitMinutes = twoDigits(duration.inMinutes).replaceAll("-", "");
    String twoDigitSeconds =
        twoDigits(duration.inSeconds.remainder(60)).replaceAll("-", "");
    //customDebugPrint(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  _onChangedSlider(double v) {
    var _sliderPosition;
    sliderPosition = Duration(milliseconds: v.floor());
    setState(() {});
  }

  /// seek the current video position
  Future<void> seekTo(Duration position) async {
    var duration = _videoController.value.duration;
    var _position = _videoController.value.position;
    if (position >= duration) {
      position = duration - const Duration(milliseconds: 100);
    }
    if (position < Duration.zero) {
      position = Duration.zero;
    }
    _position = position;
    customDebugPrint("position in seek function is ${_position.toString()}");
    customDebugPrint("duration in seek function is ${duration.toString()}");

    if (duration.inSeconds != 0) {
      customDebugPrint(
          "video controller duration ${_videoController.value.duration.toString()}");

      await _videoController?.seekTo(position);
      customDebugPrint("position after seek is ${_position.toString()}");

      // _checkIfSeekIsSuccess(position);

      // if (playerStatus.stopped) {
      //   play();
      // }
    } else {
      // _timerForReSeek(position);
    }
  }

  void customDebugPrint(String s) {}

  void onChangedSliderStart() {
    _isSliderMoving = true;
    var controls = true;
  }

  void onChangedSliderEnd() {
    _isSliderMoving = false;
  }
}

class MSliderTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 1;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2 + 4;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
