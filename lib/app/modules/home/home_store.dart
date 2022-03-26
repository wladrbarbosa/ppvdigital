import 'package:mobx/mobx.dart';

class HomeStore extends HomeStoreBase {}

abstract class HomeStoreBase {
  final Observable<int> _counter = Observable<int>(0, name: 'contador');

  int get counter => _counter.value;

  late final increment = Action(_increment, name: 'increment');

  void _increment() {
    _counter.value++;
  }
}
