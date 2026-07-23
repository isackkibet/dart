import 'dart:io';
import 'package:flutter/services.dart';

class YohPalIosPipService {
  static const MethodChannel _channel = MethodChannel('yohpal.live/ios_pip');
  Future<bool> isSupported() async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>('isPiPSupported') ?? false;
  }
  Future<bool> prepare({
    required String videoUrl,
    required bool isLive,
  }) async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>('preparePiP', {
          'videoUrl': videoUrl,
          'isLive': isLive,
        }) ??
        false;
  }
  Future<bool> start() async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>('startPiP') ?? false;
  }
  Future<bool> stop() async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>('stopPiP') ?? false;
  }
}
