import 'package:boorusphere/data/provider.dart';
import 'package:boorusphere/data/repository/booru/entity/page_option.dart';
import 'package:boorusphere/data/repository/booru/parser/anime_pictures_json_parser.dart';
import 'package:boorusphere/data/repository/server/entity/server.dart';
import 'package:boorusphere/data/repository/server/user_server_repo.dart';
import 'package:boorusphere/domain/provider.dart';
import 'package:boorusphere/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../presentation/state/app_version_test.dart';
import '../../utils/dio.dart';
import '../../utils/hive.dart';
import '../../utils/mocktail.dart';
import '../../utils/riverpod.dart';

void main() async {
  setupLogger(test: true);
  setupMocktailFallbacks();
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AnimePictures', () async {
    final ref = ProviderContainer(overrides: [
      defaultServersProvider.overrideWithValue(await provideDefaultServers()),
      envRepoProvider.overrideWithValue(FakeEnvRepo()),
    ]);
    final hiveContainer = HiveTestContainer();

    addTearDown(() async {
      await hiveContainer.dispose();
      ref.dispose();
    });

    await UserServerRepo.prepare();
    ref.setupTestFor(dioProvider);
    final adapter = DioAdapterMock(ref.read(dioProvider));

    ref.setupTestFor(serverRepoProvider);
    await ref.read(serverRepoProvider).populate();
    final parser = AnimePicturesJsonParser();
    final server = Server(
        homepage: 'https://anime-pictures.net',
        apiAddr: 'https://api.anime-pictures.net',
        searchUrl: parser.searchQuery,
        tagSuggestionUrl: parser.suggestionQuery);

    const option = PageOption(limit: 80);

    const fakePage = 'animepictures/posts.json';
    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => FakeResponseBody.fromFixture(fakePage, 200));

    expect(
      await ref.read(imageboardRepoProvider(server)).getPage(option, 0),
      isA<Iterable>().having((x) => x.length, 'total', 80),
    );

    const fakeTags = 'animepictures/tags.json';
    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => FakeResponseBody.fromFixture(fakeTags, 200));

    expect(
      await ref.read(imageboardRepoProvider(server)).getSuggestion('hatsune'),
      isA<Iterable>().having((x) => x.length, 'total', 10),
    );
  });
}
