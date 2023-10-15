import 'dart:async';
import 'dart:io';

class ProgressBar {
  static final controller = StreamController<String>();
  final _progressBar = ['.', '..', '...'];
  late final StreamSubscription _subscription;

  void run() {
    _updateProgressBar();
    _subscription = controller.stream.listen((progress) {
      stdout.write('\r$progress');
    });
  }

  void stop() {
    _subscription.cancel();
  }

  void _updateProgressBar() async {
    int index = 0;
    while (!controller.isClosed) {
      await Future.delayed(Duration(milliseconds: 800));
      controller.sink.add('Загрузка${_progressBar[index]}');
      index = (index + 1) % _progressBar.length;
    }
  }
}
