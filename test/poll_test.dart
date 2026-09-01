import 'dart:async';

Stream<List<T>> pollStream<T>(
  Future<List<T>> Function() fetch, {
  Duration interval = const Duration(minutes: 5),
}) {
  final controller = StreamController<List<T>>();
  Future<void> tick() async {
    try {
      final data = await fetch();
      if (!controller.isClosed) controller.add(data);
    } catch (_) {}
  }
  tick();
  final timer = Timer.periodic(interval, (_) => tick());
  controller.onCancel = () {
    timer.cancel();
    controller.close();
  };
  return controller.stream;
}

Future<void> main() async {
  int calls = 0;
  final stream = pollStream<int>(() async {
    calls++;
    await Future.delayed(const Duration(milliseconds: 300));
    return [calls];
  }, interval: const Duration(seconds: 1));

  // Simulate StreamBuilder: subscribe AFTER a delay (post-build frame)
  await Future.delayed(const Duration(milliseconds: 50));
  final sub = stream.listen((data) {
    print('GOT DATA: $data');
  });
  await Future.delayed(const Duration(milliseconds: 1500));
  await sub.cancel();
  print('done, fetch calls=$calls');
}