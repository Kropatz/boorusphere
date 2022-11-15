import 'package:boorusphere/data/repository/booru/entity/post.dart';
import 'package:boorusphere/data/repository/server/entity/server_data.dart';
import 'package:boorusphere/presentation/i18n/strings.g.dart';
import 'package:boorusphere/presentation/provider/favorite_post.dart';
import 'package:boorusphere/presentation/provider/server.dart';
import 'package:boorusphere/presentation/screens/home/timeline/controller.dart';
import 'package:boorusphere/presentation/screens/home/timeline/timeline.dart';
import 'package:boorusphere/presentation/widgets/favicon.dart';
import 'package:boorusphere/presentation/widgets/notice_card.dart';
import 'package:boorusphere/utils/extensions/buildcontext.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFav =
        ref.watch(favoritePostProvider.select((it) => it.isNotEmpty));
    return hasFav ? _FavoritesView() : _EmptyView();
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.favorites.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: NoticeCard(
                icon: const Icon(Icons.favorite),
                margin: const EdgeInsets.only(top: 64),
                children: Text(t.favorites.placeholder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesView extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(favoritePostProvider.select(
      (it) => it.values.groupListsBy((e) => ref
          .watch(serverStateProvider.notifier)
          .getById(e.post.serverId, or: ServerData.empty)),
    ));

    final entries = grouped.entries
        .where((it) => it.key != ServerData.empty)
        .sortedBy((it) => it.key.id);
    final servers = entries.map((e) => e.key);
    final pages = entries.map(
      (e) => MapEntry(
        e.key,
        e.value.map((e) => e.post).toList(),
      ),
    );

    return DefaultTabController(
      length: servers.length,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Text(t.favorites.title),
        ),
        body: TabBarView(
          children: [
            for (final page in pages)
              _Content(serverData: page.key, data: page.value),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: context.colorScheme.background.withOpacity(0.97),
          elevation: 0,
          child: TabBar(
            labelStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.all(8),
            isScrollable: true,
            tabs: [
              for (final server in servers) _Tab(serverData: server),
            ],
            indicator: BoxDecoration(
              color: context.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.serverData});

  final ServerData serverData;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Favicon(
            url: serverData.homepage,
            size: 16,
            shape: BoxShape.circle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(serverData.name),
        ),
      ],
    );
  }
}

class _Content extends HookWidget {
  const _Content({required this.data, required this.serverData});

  final List<Post> data;
  final ServerData serverData;

  @override
  Widget build(BuildContext context) {
    final controller = useTimelineController(
      heroKeyBuilder: (post) => 'fav@$serverData-${post.id}',
      keys: [data.hashCode],
    );

    return CustomScrollView(
      controller: controller.scrollController,
      slivers: [
        SliverSafeArea(
          sliver: SliverPadding(
            padding: const EdgeInsets.all(10),
            sliver: Timeline(controller: controller),
          ),
        ),
      ],
    );
  }
}