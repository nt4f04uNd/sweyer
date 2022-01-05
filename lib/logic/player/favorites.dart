import 'package:sweyer/sweyer.dart';

// class FavoriteRepository {
//   FavoriteRepository._();
//   static final instance = FavoriteRepository._();

//   final _serializers = ContentMap<IntListSerializer>();

//   @override
//   Future<void> markFavorite<T extends Content>(bool value) async {
//     assert(T != Content);
//     _serializers.getValue<T>();
//   }
// }

// class _FavoriteBatch {
//   bool committed = false;

//   void commit() {
//     assert(!committed);
//     committed = true;
//   }

//   void markFavorite<T extends Content>(bool value) {
//     assert(!committed);
//   }
// }