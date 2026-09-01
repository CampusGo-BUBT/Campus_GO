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

// Simulates StreamBuilder: every time build() runs, a NEW stream is created
// and subscribed; the old one is cancelled.
Future<void> main() async {
  int calls = 0;
  StreamSubscription? sub;
  int rebuilds = 0;

  Future<void> build() async {
    // cancel old subscription (StreamBuilder does this)
    await sub?.cancel();
    final stream = pollStream<int>(() async {
      calls++;
      await Future.delayed(const Duration(milliseconds: 400));
      return [calls];
    }, interval: const Duration(seconds: 60));
    sub = stream.listen((data) {
      print('BUILD#$rebuilds GOT DATA: $data');
    });
  }

  // mimic: initial build, then a few extra rebuilds before fetch completes
  await build(); rebuilds = 1;
  await Future.delayed(const Duration(milliseconds: 100));
  await build(); rebuilds = 2;
  await Future.delayed(const Duration(milliseconds: 100));
  await build(); rebuilds = 3;
  await Future.delayed(const Duration(milliseconds: 100));
  await build(); rebuilds = 4;

  await Future.delayed(const Duration(seconds: 2));
  await sub?.cancel();
  print('done, total fetch calls=$calls');
}