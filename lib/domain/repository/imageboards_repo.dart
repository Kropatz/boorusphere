import 'package:boorusphere/data/repository/booru/entity/page_option.dart';
import 'package:boorusphere/data/repository/booru/entity/post.dart';
import 'package:boorusphere/data/repository/server/entity/server.dart';
import 'package:boorusphere/presentation/provider/booru/suggestion_state.dart';

abstract interface class ImageboardRepo {
  Server get server;
  Future<Iterable<Suggestion>> getSuggestion(String query);
  Future<Iterable<Post>> getPage(PageOption option, int index);
}
