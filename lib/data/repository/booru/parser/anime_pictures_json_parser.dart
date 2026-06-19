import 'package:boorusphere/data/repository/booru/entity/post.dart';
import 'package:boorusphere/data/repository/booru/parser/booru_parser.dart';
import 'package:boorusphere/data/repository/booru/utils/booru_util.dart';
import 'package:boorusphere/data/repository/server/entity/server.dart';
import 'package:boorusphere/presentation/provider/booru/suggestion_state.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:dio/dio.dart';

class AnimePicturesJsonParser extends BooruParser {
  @override
  final id = 'AnimePictures.json';

  @override
  final searchQuery = 'api/v3/posts?page={page-id}&search_tag={tags}&posts_per_page={post-limit}&lang=en';

  @override
  final suggestionQuery =
      'api/v3/tags:autocomplete?tag={tag-part}&lang=en';

  @override
  final postUrl = 'posts/{post-id}';

  @override
  List<BooruParserType> get type => [
        BooruParserType.search,
        BooruParserType.suggestion,
      ];

  // Images aren't included in the API response; they are served from dedicated
  // hosts and addressed by the post's md5 (the first 3 chars are the bucket).
  static const _imageHost = 'https://oimages.anime-pictures.net';
  static const _previewHost = 'https://opreviews.anime-pictures.net';

  String _bucket(String md5) => md5.substring(0, 3);

  @override
  bool canParsePage(Response res) {
    final data = res.data;
    return data is Map &&
        data.containsKey('posts') &&
        data.containsKey('posts_per_page');
  }

  @override
  List<Post> parsePage(Server server, Response res) {
    final entries = List.from(res.data['posts']);
    final result = <Post>[];
    for (final post in entries.whereType<Map<String, dynamic>>()) {
      final id = pick(post, 'id').asIntOrNull() ?? -1;
      if (result.any((it) => it.id == id)) {
        // duplicated result, skipping
        continue;
      }

      final md5 = pick(post, 'md5').asStringOrNull() ?? '';
      final ext = pick(post, 'ext').asStringOrNull() ?? '';
      final width = pick(post, 'width').asIntOrNull() ?? -1;
      final height = pick(post, 'height').asIntOrNull() ?? -1;
      final score = pick(post, 'score_number').asIntOrNull() ?? 0;
      final rating = _ratingOf(pick(post, 'erotics').asIntOrNull() ?? 0);

      final hasFile = md5.length >= 3 && ext.isNotEmpty;
      final hasContent = width > 0 && height > 0;

      if (hasFile && hasContent) {
        final bucket = _bucket(md5);
        var post = Post(
          id: id,
          originalFile: '$_imageHost/$bucket/$md5$ext',
          sampleFile: '$_previewHost/$bucket/${md5}_bp.avif',
          previewFile: '$_previewHost/$bucket/${md5}_cp.avif',
          width: width,
          height: height,
          serverId: server.id,
          postUrl: server.postUrlOf(id),
          rateValue: rating,
          score: score,
        );
        result.add(
          post,
        );
      }
    }

    return result;
  }

  // anime-pictures grades eroticism from 0 (none) to 3 (hentai)
  String _ratingOf(int erotics) {
    switch (erotics) {
      case 0:
        return 'safe';
      case 2:
        return 'sensitive';
      case 3:
        return 'explicit';
      default:
        return 'questionable';
    }
  }

  @override
  bool canParseSuggestion(Response res) {
    final data = res.data;
    if (data is! Map || data['tags'] is! List) return false;
    final tags = data['tags'] as List;
    // anime-pictures keys the tag name under 't'; other 'tags'-wrapped
    // responses (e.g. booru-on-rails) don't, so don't claim those
    return tags.isNotEmpty &&
        tags.first is Map &&
        (tags.first as Map).containsKey('t');
  }

  @override
  Set<Suggestion> parseSuggestion(Server server, Response res) {
    final entries = List.from(res.data['tags']);
    final result = <Suggestion>{};
    for (final entry in entries.whereType<Map<String, dynamic>>()) {
      final tag = pick(entry, 't').asStringOrNull() ?? '';
      if (tag.isNotEmpty) {
        // autocomplete doesn't expose a post count
        result.add(Suggestion(BooruUtil.decodeTag(tag), 0));
      }
    }

    return result;
  }
}
