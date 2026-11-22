import 'dart:convert';
import 'dart:developer';

import 'package:boorusphere/data/repository/booru/entity/post.dart';
import 'package:boorusphere/data/repository/booru/parser/booru_parser.dart';
import 'package:boorusphere/data/repository/booru/utils/booru_util.dart';
import 'package:boorusphere/data/repository/server/entity/server.dart';
import 'package:boorusphere/presentation/provider/booru/suggestion_state.dart';
import 'package:boorusphere/utils/extensions/pick.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:dio/dio.dart';

class E621JsonParser extends BooruParser {
  @override
  final id = 'E621.json';

  @override
  final searchQuery =
      'posts.json?tags={tags}&page={page-id}&limit={post-limit}';

  @override
  final suggestionQuery =
      'tags/autocomplete.json?search[name-matches]={tag-part}';

  @override
  List<BooruParserType> get type => [
        BooruParserType.search,
        BooruParserType.suggestion,
      ];

  @override
  int get pageOffset => 1;

  @override
  bool canParsePage(Response res) {
    final data = res.data;
    if (data is Map) {
      return false;
    } else if (data is List) {
      String asStr = data.toString();
      return asStr.contains('id') &&
          asStr.contains('created_at') &&
          asStr.contains('change_seq') &&
          asStr.contains('comment_count');
    }
    return false;
  }

  @override
  List<Post> parsePage(Server server, Response res) {
    final entries = List.from(res.data);
    final result = <Post>[];
    for (final post in entries.whereType<Map<String, dynamic>>()) {
      final id = pick(post, 'id').asIntOrNull() ?? -1;
      if (result.any((it) => it.id == id)) {
        // duplicated result, skipping
        continue;
      }

      final files = pick(post, 'files').asMapOrEmpty();
      final fileMap = pick(files, 'original').asMapOrEmpty();
      final sampleMap = pick(files, 'sample').asMapOrEmpty();
      final previewMap = pick(files, 'preview').asMapOrEmpty();
      final tagsList = pick(post, 'tags').asStringList();

      final originalFile = pick(fileMap, 'url').asStringOrNull() ?? '';
      final sampleFile = pick(sampleMap, 'webp').asStringOrNull() ?? '';
      final previewFile = pick(previewMap, 'webp').asStringOrNull() ?? '';
      final tagsGeneral = tagsList;
      final width = pick(fileMap, 'width').asIntOrNull() ?? 0;
      final height = pick(fileMap, 'height').asIntOrNull() ?? 0;
      final sampleWidth = pick(sampleMap, 'width').asIntOrNull() ?? 0;
      final sampleHeight = pick(sampleMap, 'height').asIntOrNull() ?? 0;
      final previewWidth = pick(previewMap, 'width').asIntOrNull() ?? 0;
      final previewHeight = pick(previewMap, 'height').asIntOrNull() ?? 0;
      final rating = pick(post, 'rating').asStringOrNull() ?? 'q';
      final sources = pick(post, 'sources').asStringList();
      final source = sources.isNotEmpty ? sources.first : '';

      final hasFile = originalFile.isNotEmpty && previewFile.isNotEmpty;
      final hasContent = width > 0 && height > 0;
      final postUrl = server.postUrlOf(id);
      final score = pick(post, 'score', 'total').asIntOrNull() ?? 0;

      if (hasFile && hasContent) {
        result.add(
          Post(
            id: id,
            originalFile: BooruUtil.normalizeUrl(server, originalFile),
            sampleFile: BooruUtil.normalizeUrl(server, sampleFile),
            previewFile: BooruUtil.normalizeUrl(server, previewFile),
            width: width,
            height: height,
            sampleWidth: sampleWidth,
            sampleHeight: sampleHeight,
            previewWidth: previewWidth,
            previewHeight: previewHeight,
            serverId: server.id,
            postUrl: postUrl,
            rateValue: rating.isEmpty ? 'q' : rating,
            source: source,
            tagsGeneral: tagsGeneral.map(BooruUtil.decodeTag).toList(),
            score: score,
          ),
        );
      }
    }

    return result;
  }

  @override
  bool canParseSuggestion(Response res) {
    final data = res.data;

    if (data is Map) {
      return false;
    } else if (data is List) {
      return data.toString().contains('id') &&
          data.toString().contains('name') &&
          data.toString().contains('post_count');
    }
    try {
      final isList = jsonDecode(data) is List;
      final canParse = isList &&
          data.toString().contains('id') &&
          data.toString().contains('name') &&
          data.toString().contains('post_count');
      return canParse;
    } catch (e) {
      return false;
    }
  }

  @override
  Set<Suggestion> parseSuggestion(Server server, Response res) {
    final entries = res.data is List
        ? List.from(res.data)
        : List.from(jsonDecode(res.data));
    final result = <Suggestion>{};
    for (final Map<String, dynamic> entry in entries) {
      final tag = pick(entry, 'name').asStringOrNull() ?? '';
      final postCount = pick(entry, 'post_count').asIntOrNull() ?? 0;
      if (postCount > 0 && tag.isNotEmpty) {
        result.add(Suggestion(BooruUtil.decodeTag(tag), postCount));
      }
    }

    return result;
  }
}
