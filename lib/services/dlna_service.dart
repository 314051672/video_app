class DlnaService {
  static final DlnaService _instance = DlnaService._internal();
  factory DlnaService() => _instance;
  DlnaService._internal();

  List<dynamic> _devices = [];
  bool _isPlaying = false;

  List<dynamic> get devices => _devices;
  bool get isPlaying => _isPlaying;

  Future<void> searchDevices() async {
    _devices = [];
  }

  Future<bool> castVideo(String videoUrl, String title, {String? imageUrl}) async {
    return false;
  }

  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}

  void selectDevice(dynamic device) {}
  void clearDevice() {}
  void dispose() {}
}
