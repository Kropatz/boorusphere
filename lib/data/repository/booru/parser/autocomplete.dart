import 'dart:convert';

import 'package:boorusphere/data/repository/booru/parser/booru_parser.dart';
import 'package:boorusphere/data/repository/booru/utils/booru_util.dart';
import 'package:boorusphere/data/repository/server/entity/server.dart';
import 'package:boorusphere/presentation/provider/booru/suggestion_state.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:dio/dio.dart';

class AutocompleteJsonParser extends BooruParser {
  @override
  final id = 'Autocomplete.json';

  @override
  final suggestionQuery = 'autocomplete.php?q={tag-part}';

  @override
  List<BooruParserType> get type => [
        BooruParserType.suggestion,
      ];

  @override
  bool canParsePage(Response res) {
    return false;
  }

  @override
  bool canParseSuggestion(Response res) {
    final data = res.data;

    if (data is Map) {
      return false;
    } else if (data is List) {
      return data.toString().contains('label') &&
          data.toString().contains('value');
    }
    try {
      final isList = jsonDecode(data) is List;
      final canParse = isList &&
          data.toString().contains('label') &&
          data.toString().contains('value');
      return canParse;
    } catch (e) {
      return false;
    }

  }

  @override
  Set<Suggestion> parseSuggestion(Server server, Response res) {
    final entries = res.data is List ? List.from(res.data) : List.from(jsonDecode(res.data));
    final result = <Suggestion>{};
    for (final Map<String, dynamic> entry in entries) {
      final label = pick(entry, 'label').asStringOrNull() ?? '';
      final tag = pick(entry, 'value').asStringOrNull() ?? '';
      // post count is in label at the end of the string "<tag> (post count)"
      final postCount = int.tryParse(
              label.split(' ').last.replaceAll('(', '').replaceAll(')', '')) ??
          0;
      if (postCount > 0 && tag.isNotEmpty) {
        result.add(Suggestion(BooruUtil.decodeTag(tag), postCount));
      }
    }

    return result;
  }
}
