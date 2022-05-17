// ignore_for_file: constant_identifier_names

abstract class Command<T> {
  const Command();

  Future<T> get();
  Future<void> perform(Action action, T value);

  Future<void> set(T value) => perform(Action.Set, value);
  Future<void> remove(T value) => perform(Action.Remove, value);
  Future<void> add(T value) => perform(Action.Add, value);
}

enum Action {
  Get,
  Add,
  Remove,
  Set,
}
