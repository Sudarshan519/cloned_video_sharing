import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_sharing/widgets/embeded_subtitle.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'apis/encoding_provider.dart';
import 'apis/firebase_provider.dart';
import 'package:path/path.dart' as p;
import 'models/video_info.dart';
import 'widgets/player.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'widgets/vlc_with_subtitle.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Video Sharing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Video Sharing'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final thumbWidth = 100;
  final thumbHeight = 150;
  List<VideoInfo> _videos = <VideoInfo>[];
  bool _imagePickerActive = false;
  bool _processing = false;
  bool _canceled = false;
  double _progress = 0.0;
  int _videoDuration = 0;
  String _processPhase = '';
  final bool _debugMode = false;

  @override
  void initState() {
    FirebaseProvider.listenToVideos((newVideos) {
      setState(() {
        _videos = newVideos;
      });
    });

    EncodingProvider.enableStatisticsCallback((int time,
        int size,
        double bitrate,
        double speed,
        int videoFrameNumber,
        double videoQuality,
        double videoFps) {
      if (_canceled) return;

      setState(() {
        _progress = time / _videoDuration;
      });
    });

    super.initState();
  }

  void _onUploadProgress(event) {
    if (event.type == StorageTaskEventType.progress) {
      final double progress =
          event.snapshot.bytesTransferred / event.snapshot.totalByteCount;
      setState(() {
        _progress = progress;
      });
    }
  }

  Future<String> _uploadFile(filePath, folderName) async {
    final file = new File(filePath);
    final basename = p.basename(filePath);

    final StorageReference ref =
        FirebaseStorage.instance.ref().child(folderName).child(basename);
    StorageUploadTask uploadTask = ref.putFile(file);
    uploadTask.events.listen(_onUploadProgress);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String videoUrl = await taskSnapshot.ref.getDownloadURL();
    return videoUrl;
  }

  String getFileExtension(String fileName) {
    final exploded = fileName.split('.');
    return exploded[exploded.length - 1];
  }

  void _updatePlaylistUrls(File file, String videoName) {
    final lines = file.readAsLinesSync();
    var updatedLines = List<String>();

    for (final String line in lines) {
      var updatedLine = line;
      if (line.contains('.ts') || line.contains('.m3u8')) {
        updatedLine = '$videoName%2F$line?alt=media';
      }
      updatedLines.add(updatedLine);
    }
    final updatedContents =
        updatedLines.reduce((value, element) => value + '\n' + element);

    file.writeAsStringSync(updatedContents);
  }

  Future<String> _uploadHLSFiles(dirPath, videoName) async {
    final videosDir = Directory(dirPath);

    var playlistUrl = '';

    final files = videosDir.listSync();
    int i = 1;
    for (FileSystemEntity file in files) {
      final fileName = p.basename(file.path);
      final fileExtension = getFileExtension(fileName);
      if (fileExtension == 'm3u8') _updatePlaylistUrls(file, videoName);

      setState(() {
        _processPhase = 'Uploading video file $i out of ${files.length}';
        _progress = 0.0;
      });

      final downloadUrl = fileName == 'master.m3u8'
          ? await _uploadFile(file.path, videoName)
          : _uploadFile(file.path, videoName);

      if (fileName == 'master.m3u8') {
        playlistUrl = downloadUrl;
      }
      i++;
    }

    return playlistUrl;
  }

  Future<void> _processVideo(File rawVideoFile) async {
    final String rand = '${new Random().nextInt(10000)}';
    final videoName = 'video$rand';
    final Directory extDir = await getApplicationDocumentsDirectory();

    if (rawVideoFile.path.endsWith('.jpg')) {
      _uploadMkv(rawVideoFile.path, videoName);
    } else {
      setState(() {
        _processPhase = '';
        _progress = 0.0;
        _processing = false;
      });
    }
    print(rawVideoFile.path);
    //  else {
    //   final outDirPath = '${extDir.path}/Videos/$videoName';
    //   final videosDir = new Directory(outDirPath);
    //   videosDir.createSync(recursive: true);

    //   final rawVideoPath = rawVideoFile.path;
    //   final info = await EncodingProvider.getMediaInformation(rawVideoPath);
    //   final aspectRatio = EncodingProvider.getAspectRatio(info);

    //   setState(() {
    //     _processPhase = 'Generating thumbnail';
    //     _videoDuration = EncodingProvider.getDuration(info);
    //     _progress = 0.0;
    //   });

    //   final thumbFilePath = await EncodingProvider.getThumb(
    //       rawVideoPath, thumbWidth, thumbHeight);

    //   final thumbUrl = await _uploadFile(thumbFilePath, 'thumbnail');

    //   setState(() {
    //     _processPhase = 'Encoding video';
    //     _progress = 0.0;
    //   });

    //   /// encode if not mkv
    //   ///
    //   final encodedFilesDir =
    //       await EncodingProvider.encodeHLS(rawVideoPath, outDirPath);

    //   setState(() {
    //     _processPhase = 'Uploading thumbnail to firebase storage';
    //     _progress = 0.0;
    //   });
    //   final videoUrl = await _uploadHLSFiles(encodedFilesDir, videoName);

    //   final videoInfo = VideoInfo(
    //     videoUrl: videoUrl,
    //     thumbUrl: thumbUrl,
    //     coverUrl: thumbUrl,
    //     aspectRatio: aspectRatio,
    //     uploadedAt: DateTime.now().millisecondsSinceEpoch,
    //     videoName: videoName,
    //   );

    //   setState(() {
    //     _processPhase = 'Saving video metadata to cloud firestore';
    //     _progress = 0.0;
    //   });

    //   await FirebaseProvider.saveVideo(videoInfo);

    //   setState(() {
    //     _processPhase = '';
    //     _progress = 0.0;
    //     _processing = false;
    //   });
    // }
  }

  void _uploadMkv(rawVideoPath, videoName) async {
    final info = await EncodingProvider.getMediaInformation(rawVideoPath);
    final aspectRatio = EncodingProvider.getAspectRatio(info);

    var playlistUrl = '';
    final thumbFilePath =
        await EncodingProvider.getThumb(rawVideoPath, thumbWidth, thumbHeight);
    final thumbUrl = await _uploadFile(thumbFilePath, 'thumbnail');

    final videoUrl = await _uploadFile(rawVideoPath, videoName);

    final videoInfo = VideoInfo(
      videoUrl: videoUrl,
      thumbUrl: thumbUrl,
      coverUrl: thumbUrl,
      aspectRatio: aspectRatio,
      uploadedAt: DateTime.now().millisecondsSinceEpoch,
      videoName: videoName,
    );

    setState(() {
      _processPhase = 'Saving video metadata to cloud firestore';
      _progress = 0.0;
    });

    await FirebaseProvider.saveVideo(videoInfo);

    setState(() {
      _processPhase = '';
      _progress = 0.0;
      _processing = false;
    });
  }

  void _takeVideo() async {
    var videoFile;
    if (_debugMode) {
      videoFile = File(
          '/storage/emulated/0/Android/data/com.learningsomethingnew.flutter_video_sharing/files/Pictures/ebbafabc-dcbe-433b-93dd-80e7777ee4704451355941378265171.mp4');
    } else {
      if (_imagePickerActive) return;

      _imagePickerActive = true;
      videoFile = await ImagePicker.pickVideo(source: ImageSource.gallery);
      _imagePickerActive = false;

      if (videoFile == null) return;
    }
    setState(() {
      _processing = true;
    });

    try {
      await _processVideo(videoFile);
    } catch (e) {
      print('${e.toString()}');
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  _getListView() {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _videos.length,
        itemBuilder: (BuildContext context, int index) {
          final video = _videos[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return VideoPlayerWithSubtitles(
                          videoPath: video.videoUrl,
                        ) ??
                        Player(
                          video: video,
                        );
                  },
                ),
              );
            },
            child: Card(
              child: new Container(
                padding: new EdgeInsets.all(10.0),
                child: Stack(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CachedNetworkImage(
                              imageUrl: video.thumbUrl,
                              height: 180,
                              width: 120,
                              fit: BoxFit.cover,
                            ) ??
                            Stack(
                              children: <Widget>[
                                Container(
                                  width: thumbWidth.toDouble(),
                                  height: thumbHeight.toDouble(),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                ClipRRect(
                                  borderRadius: new BorderRadius.circular(8.0),
                                  child: FadeInImage.memoryNetwork(
                                    placeholder: kTransparentImage,
                                    image: video.thumbUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                        Expanded(
                          child: Container(
                            margin: new EdgeInsets.only(left: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Text("${video.videoName}"),
                                Container(
                                  margin: new EdgeInsets.only(top: 12.0),
                                  child: Text(
                                      'Uploaded ${timeago.format(new DateTime.fromMillisecondsSinceEpoch(video.uploadedAt))}'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  _getProgressBar() {
    return Container(
      padding: EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 30.0),
            child: Text(_processPhase),
          ),
          LinearProgressIndicator(
            value: _progress,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(child: _processing ? _getProgressBar() : _getListView()),
      floatingActionButton: FloatingActionButton(
          child: _processing
              ? CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Icon(Icons.add),
          onPressed: _takeVideo),
    );
  }
}

Future<List<String>> uploadFiles(List _images) async {
  List<String> imagesUrls = [];

  _images.forEach((_image) async {
    StorageReference storageReference =
        FirebaseStorage.instance.ref().child('posts/${_image.path}');
    StorageUploadTask uploadTask = storageReference.putFile(_image);

    imagesUrls.add(await (await uploadTask.onComplete).ref.getDownloadURL());
  });
  print(imagesUrls);
  return imagesUrls;
// List<String> urls = Future.wait(uploadFiles(_images));
}
