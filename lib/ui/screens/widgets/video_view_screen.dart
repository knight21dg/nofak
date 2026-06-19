import 'package:nofak/ui/theme/theme.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';

import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/ui/screens/widgets/youtube_player_widget.dart';

class VideoViewScreen extends StatefulWidget {
  final String videoUrl;
  final FlickManager? flickManager;
  const VideoViewScreen({
    super.key,
    required this.videoUrl,
    this.flickManager,
  });

  @override
  State<VideoViewScreen> createState() => _VideoViewScreenState();
}

class _VideoViewScreenState extends State<VideoViewScreen> {
  @override
  void dispose() {
    widget.flickManager?.flickControlManager?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
          iconTheme: IconThemeData(color: context.color.territoryColor),
        ),
        backgroundColor: context.color.backgroundColor,
        body: Center(
          child: HelperUtils.checkVideoType(
            widget.videoUrl,
            onYoutubeVideo: () {
              return YoutubePlayerWidget(
                videoUrl: widget.videoUrl,
                onLandscape: () {},
                onPortrate: () {},
              );
            },
            onOtherVideo: () {
              if (widget.flickManager != null) {
                return FlickVideoPlayer(flickManager: widget.flickManager!);
              }
              return Container();
            },
          ),
        ),
      ),
    );
  }
}
