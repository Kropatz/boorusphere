import 'package:boorusphere/data/entity/download_entry.dart';
import 'package:boorusphere/data/services/download.dart';
import 'package:boorusphere/presentation/i18n/strings.g.dart';
import 'package:boorusphere/presentation/provider/server_data.dart';
import 'package:boorusphere/presentation/provider/settings/download/group_by_server.dart';
import 'package:boorusphere/presentation/screens/downloads/download_entry_view.dart';
import 'package:boorusphere/presentation/widgets/expandable_group_list_view.dart';
import 'package:boorusphere/presentation/widgets/notice_card.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloader = ref.watch(downloadProvider);
    final groupByServer = ref.watch(downloadGroupByServerSettingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.downloader.title),
        actions: [
          if (downloader.entries.isNotEmpty)
            PopupMenuButton(
              onSelected: (value) {
                switch (value) {
                  case 'clear-all':
                    downloader.clearEntries();
                    break;
                  case 'group-by-server':
                    ref
                        .read(
                            downloadGroupByServerSettingStateProvider.notifier)
                        .update(!groupByServer);
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: 'group-by-server',
                    child: Text(
                      groupByServer
                          ? context.t.downloader.ungroup
                          : context.t.downloader.groupByServer,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear-all',
                    child: Text(context.t.clear),
                  ),
                ];
              },
            )
        ],
      ),
      body: SafeArea(
        child: downloader.entries.isEmpty
            ? Column(
                children: [
                  Center(
                    child: NoticeCard(
                      icon: const Icon(Icons.cloud_download),
                      margin: const EdgeInsets.only(top: 64),
                      children: Text(context.t.downloader.placeholder),
                    ),
                  ),
                ],
              )
            : ExpandableGroupListView<DownloadEntry, String>(
                items: downloader.entries.reversed.toList(),
                groupedBy: (entry) => entry.post.serverId,
                groupTitle: (id) => Text(ref
                    .watch(serverDataStateProvider.notifier)
                    .getById(id)
                    .name),
                itemBuilder: (entry) => DownloadEntryView(entry: entry),
                ungroup: !groupByServer,
              ),
      ),
    );
  }
}
