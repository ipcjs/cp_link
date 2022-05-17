import 'package:tuple/tuple.dart';

extension MapIterableExt<K, V> on Iterable<Map<K, V>> {
  Map<K, V> merge([Map<K, V>? initialMap]) =>
      this.fold(initialMap ?? {}, (map, it) {
        map.addAll(it);
        return map;
      });
}

extension IterableTuple2Ext<A, B> on Tuple2<Iterable<A>, Iterable<B>> {
  /// @see [Iterable.map]
  Iterable<T> map<T>(T Function(Tuple2<A, B> e) toElement) sync* {
    final it1 = this.item1.iterator;
    final it2 = this.item2.iterator;
    while (it1.moveNext() && it2.moveNext()) {
      yield toElement(Tuple2(it1.current, it2.current));
    }
  }
}
