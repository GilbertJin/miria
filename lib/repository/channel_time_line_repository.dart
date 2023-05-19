import 'dart:async';

import 'package:miria/repository/socket_timeline_repository.dart';
import 'package:misskey_dart/misskey_dart.dart';

class ChannelTimelineRepository extends SocketTimelineRepository {
  final Misskey misskey;

  ChannelTimelineRepository(
    this.misskey,
    super.noteRepository,
    super.globalNotificationRepository,
    super.tabSetting,
  );

  @override
  SocketController createSocketController(void Function(Note note) onReceived,
      FutureOr<void> Function(String id, TimelineReacted reaction) onReacted) {
    return misskey.channelStream(tabSetting.channelId!, onReceived, onReacted);
  }

  @override
  Future<Iterable<Note>> requestNotes({String? untilId}) async {
    return await misskey.channels.timeline(ChannelsTimelineRequest(
        channelId: tabSetting.channelId!, limit: 30, untilId: untilId));
  }
}
