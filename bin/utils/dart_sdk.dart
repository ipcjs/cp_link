// ignore_for_file: unnecessary_this

extension MapIterableExt<K, V> on Iterable<Map<K, V>> {
  Map<K, V> merge([Map<K, V>? initialMap]) =>
      this.fold(initialMap ?? {}, (map, it) {
        map.addAll(it);
        return map;
      });
}
