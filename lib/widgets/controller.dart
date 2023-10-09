import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerController {
  /// the video_player controller
  static VideoPlayerController _videoPlayerController;
  StreamSubscription _playerEventSubs;

  /// [videoPlayerController] instace of VideoPlayerController
  VideoPlayerController get videoPlayerController => _videoPlayerController;


  static PlayerController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MeeduPlayerProvider>()
        .controller;
  }
}


class MeeduPlayerProvider extends InheritedWidget {
  final PlayerController controller;

  const MeeduPlayerProvider({
    Key key,
     Widget child,
     this.controller,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
