import 'package:miria/model/tab_setting.dart';
import 'package:miria/providers.dart';
import 'package:miria/repository/time_line_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TabType {
  localTimeline("ローカルタイムライン"),
  homeTimeline("ホームタイムライン"),
  globalTimeline("グローバルタイムライン"),
  hybridTimeline("ソーシャルタイムライン"),
  channel("チャンネル"),
  ;

  final String displayName;
  const TabType(this.displayName);

  ChangeNotifierProvider<TimelineRepository> timelineProvider(
      TabSetting setting) {
    switch (this) {
      case TabType.localTimeline:
        return localTimeLineProvider(setting);
      case TabType.homeTimeline:
        return homeTimeLineProvider(setting);
      case TabType.globalTimeline:
        return globalTimeLineProvider(setting);
      case TabType.hybridTimeline:
        return hybridTimeLineProvider(setting); //FIXME
      case TabType.channel:
        return channelTimelineProvider(setting);
    }
  }
}
