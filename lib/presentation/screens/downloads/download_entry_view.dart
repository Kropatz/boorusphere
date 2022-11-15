import 'package:auto_route/auto_route.dart';
import 'package:boorusphere/data/entity/download_entry.dart';
import 'package:boorusphere/data/entity/download_status.dart';
import 'package:boorusphere/data/services/download.dart';
import 'package:boorusphere/presentation/i18n/strings.g.dart';
import 'package:boorusphere/presentation/provider/booru/extension/post.dart';
import 'package:boorusphere/presentation/provider/server.dart';
import 'package:boorusphere/presentation/provider/settings/download/download_settings.dart';
import 'package:boorusphere/presentation/routes/routes.dart';
import 'package:boorusphere/presentation/widgets/download_dialog.dart';
import 'package:boorusphere/utils/extensions/buildcontext.dart';
import 'package:boorusphere/utils/extensions/number.dart';
import 'package:boorusphere/utils/extensions/string.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:separated_row/separated_row.dart';

class DownloadEntryView extends ConsumerWidget {
  const DownloadEntryView({super.key, required this.entry});

  final DownloadEntry entry;

  IconData downloadStatusIconOf(DownloadEntry entry, DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloaded:
        return entry.isFileExists
            ? Icons.download_done_rounded
            : Icons.error_outline_rounded;
      case DownloadStatus.downloading:
        return Icons.downloading_rounded;
      case DownloadStatus.canceled:
      case DownloadStatus.failed:
        return Icons.cancel_rounded;
      default:
        return Icons.file_open;
    }
  }

  Color downloadStatusColorOf(
      DownloadEntry entry, DownloadStatus status, ColorScheme scheme) {
    switch (status) {
      case DownloadStatus.downloaded:
        return entry.isFileExists
            ? Colors.lightBlueAccent
            : scheme.onBackground.withAlpha(125);
      case DownloadStatus.canceled:
      case DownloadStatus.failed:
        return Colors.pinkAccent;
      default:
        return scheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloader = ref.watch(downloadProvider);
    final groupByServer = ref.watch(DownloadSettingsProvider.groupByServer);
    final progress = downloader.getProgress(entry.id);

    return ListTile(
      title: Text(
        entry.destination.fileName.asDecoded,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SeparatedRow(
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          children: [
            if (progress.status.isDownloading || progress.status.isPending) ...[
              SizedBox(
                height: 18,
                width: 18,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CircularProgressIndicator(
                    value: progress.status.isPending
                        ? null
                        : progress.progress.ratio,
                    strokeWidth: 2.5,
                    backgroundColor: context.colorScheme.surfaceVariant,
                  ),
                ),
              ),
              Text('${progress.progress}%'),
            ] else
              Icon(
                downloadStatusIconOf(entry, progress.status),
                color: downloadStatusColorOf(
                  entry,
                  progress.status,
                  context.colorScheme,
                ),
                size: 18,
              ),
            if (progress.status.isDownloaded && !entry.isFileExists)
              Text(t.downloader.noFile)
            else
              Text(progress.status.name.capitalized),
            if (!groupByServer) ...[
              const Text('•'),
              Text(ref
                  .watch(serverStateProvider.notifier)
                  .getById(entry.post.serverId)
                  .name),
            ],
          ],
        ),
      ),
      leading: ExtendedImage.network(
        entry.post.previewFile,
        headers: entry.post.getHeaders(ref),
        width: 42,
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        fit: BoxFit.cover,
      ),
      trailing: _EntryPopupMenu(entry: entry),
      dense: true,
      onTap: !progress.status.isDownloaded || !entry.isFileExists
          ? null
          : () => downloader.openEntryFile(id: entry.id),
    );
  }
}

class _EntryPopupMenu extends ConsumerWidget {
  const _EntryPopupMenu({required this.entry});

  final DownloadEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloader = ref.watch(downloadProvider);
    final progress = downloader.getProgress(entry.id);

    return PopupMenuButton(
      onSelected: (value) {
        switch (value) {
          case 'redownload':
            DownloaderDialog.show(
              context: context,
              post: entry.post,
              onItemClick: (type) async {
                await downloader.clearEntry(id: entry.id);
              },
            );
            break;
          case 'retry':
            downloader.retryEntry(id: entry.id);
            break;
          case 'cancel':
            downloader.cancelEntry(id: entry.id);
            break;
          case 'clear':
            downloader.clearEntry(id: entry.id);
            break;
          case 'show-detail':
            context.router.push(PostDetailsRoute(post: entry.post));
            break;
          default:
            break;
        }
      },
      itemBuilder: (context) {
        return [
          if (progress.status.isDownloaded && !entry.isFileExists)
            PopupMenuItem(
              value: 'redownload',
              child: Text(t.downloader.redownload),
            ),
          if (progress.status.isCanceled || progress.status.isFailed)
            PopupMenuItem(
              value: 'retry',
              child: Text(t.retry),
            ),
          if (progress.status.isDownloading)
            PopupMenuItem(
              value: 'cancel',
              child: Text(t.cancel),
            ),
          PopupMenuItem(
            value: 'show-detail',
            child: Text(t.downloader.detail),
          ),
          PopupMenuItem(
            value: 'clear',
            child: Text(t.clear),
          ),
        ];
      },
    );
  }
}