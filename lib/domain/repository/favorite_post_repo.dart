import 'package:boorusphere/data/repository/booru/entity/post.dart';

abstract interface class FavoritePostRepo {
  Iterable<Post> get();
  Future<void> clear();
  Future<void> remove(Post post);
  Future<void> save(Post post);
}
