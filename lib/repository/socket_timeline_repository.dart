import 'dart:async';

import 'package:collection/collection.dart';
import 'package:miria/extensions/date_time_extension.dart';
import 'package:miria/repository/time_line_repository.dart';
import 'package:misskey_dart/misskey_dart.dart';

abstract class SocketTimelineRepository extends TimelineRepository {
  SocketController? socketController;

  SocketTimelineRepository(super.noteRepository,
      super.globalNotificationRepository, super.tabSetting);

  Future<Iterable<Note>> requestNotes({String? untilId});

  SocketController createSocketController(void Function(Note note) onReceived,
      FutureOr<void> Function(String id, TimelineReacted reaction) onReacted);

  void reloadLatestNotes() {
    moveToOlder();
    requestNotes().then((resultNotes) {
      if (olderNotes.isEmpty) {
        olderNotes.addAll(resultNotes);
        notifyListeners();
        return;
      }

      if (olderNotes.first.createdAt < resultNotes.last.createdAt) {
        olderNotes
          ..clear()
          ..addAll(resultNotes);
        notifyListeners();
        return;
      }

      for (final note in resultNotes.toList().reversed) {
        final index = olderNotes.indexWhere((element) => element.id == note.id);
        if (index != -1) {
          olderNotes[index] = note;
          noteRepository.registerNote(note);
        } else {
          olderNotes.addFirst(note);
        }
      }
      notifyListeners();
    });
  }

  @override
  void startTimeLine() {
    if (olderNotes.isEmpty) {
      requestNotes().then((resultNotes) {
        olderNotes.addAll(resultNotes);
        notifyListeners();
      }, onError: (e, s) {
        print(e);
        print(s);
      });
    } else {
      reloadLatestNotes();
    }

    socketController = createSocketController((note) {
      newerNotes.add(note);

      notifyListeners();
    }, (id, value) {
      final registeredNote = noteRepository.notes[id];
      if (registeredNote == null) return;
      final reaction = Map.of(registeredNote.reactions);
      reaction[value.reaction] = (reaction[value.reaction] ?? 0) + 1;
      noteRepository.registerNote(registeredNote.copyWith(reactions: reaction));
    })
      ..startStreaming();
  }

  @override
  void disconnect() {
    socketController?.disconnect();
  }

  @override
  void reconnect() {
    super.reconnect();
    socketController?.reconnect();
    reloadLatestNotes();
  }

  @override
  Future<void> previousLoad() async {
    if (newerNotes.isEmpty && olderNotes.isEmpty) {
      return;
    }
    final resultNotes = await requestNotes(
      untilId: olderNotes.lastOrNull?.id ?? newerNotes.first.id,
    );
    olderNotes.addAll(resultNotes);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    socketController?.disconnect();
    socketController = null;
  }

  @override
  void subscribe(SubscribeItem item) {
    if (!tabSetting.isSubscribe) return;
    final index =
        subscribedList.indexWhere((element) => element.noteId == item.noteId);
    final isSubscribed = subscribedList.indexWhere((element) =>
        element.noteId == item.noteId ||
        element.renoteId == item.noteId ||
        element.replyId == item.noteId);

    if (index == -1) {
      subscribedList.add(item);
      if (isSubscribed == -1) {
        socketController?.send(ChannelDataType.subNote, item.noteId);
      }
    } else {
      subscribedList[index] = item;
    }

    final renoteId = item.renoteId;

    if (renoteId != null) {
      final isRenoteSubscribed = subscribedList.indexWhere((element) =>
          element.noteId == renoteId ||
          element.renoteId == renoteId ||
          element.replyId == renoteId);
      if (isRenoteSubscribed == -1) {
        socketController?.send(ChannelDataType.subNote, renoteId);
      }
    }

    final replyId = item.replyId;
    if (replyId != null) {
      socketController?.send(ChannelDataType.subNote, replyId);
      final isRenoteSubscribed = subscribedList.indexWhere((element) =>
          element.noteId == replyId ||
          element.renoteId == replyId ||
          element.replyId == replyId);
      if (isRenoteSubscribed == -1) {
        socketController?.send(ChannelDataType.subNote, replyId);
      }
    }
  }

  @override
  void describe(String id) {
    if (!tabSetting.isSubscribe) return;
    socketController?.send(ChannelDataType.unsubNote, id);
  }
}
