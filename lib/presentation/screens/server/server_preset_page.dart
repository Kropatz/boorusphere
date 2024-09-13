import 'package:auto_route/auto_route.dart';
import 'package:boorusphere/data/repository/server/entity/server.dart';
import 'package:boorusphere/domain/provider.dart';
import 'package:boorusphere/presentation/i18n/strings.g.dart';
import 'package:boorusphere/presentation/provider/server_data_state.dart';
import 'package:boorusphere/presentation/widgets/favicon.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@RoutePage()
class ServerPresetPage extends ConsumerWidget {
  const ServerPresetPage({super.key, this.onReturned});

  final void Function(Server newData)? onReturned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaults = ref.watch(serverRepoProvider.select((it) => it.defaults));
    final servers = ref.watch(serverStateProvider);
    final all = {...defaults.values, ...servers};

    return Scaffold(
      appBar: AppBar(title: Text(context.t.servers.select)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: all.map((it) {
              return ListTile(
                title: Text(it.name),
                subtitle: Text(it.homepage),
                leading: Favicon(url: it.homepage),
                dense: true,
                onTap: () {
                  onReturned?.call(it);
                  context.router.maybePop();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
