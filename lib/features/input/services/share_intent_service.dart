import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Adapts platform share intents to plain text for the existing input flow.
class ShareIntentService {
  const ShareIntentService({this._receiveSharingIntent});

  final ReceiveSharingIntent? _receiveSharingIntent;

  ReceiveSharingIntent get _intent =>
      _receiveSharingIntent ?? ReceiveSharingIntent.instance;

  Future<String?> initialSharedText() async {
    final text = _textFrom(await _intent.getInitialMedia());
    if (text != null) await _intent.reset();
    return text;
  }

  Stream<String> get sharedText => _intent
      .getMediaStream()
      .map(_textFrom)
      .where((text) => text != null)
      .map((text) => text!);

  String? _textFrom(List<SharedMediaFile> files) {
    for (final file in files) {
      if (file.type == SharedMediaType.text && file.path.trim().isNotEmpty) {
        return file.path.trim();
      }
    }
    return null;
  }
}
