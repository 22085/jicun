import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../services/ad_config.dart';

/// 各页面底部的横幅广告(灰鲸横幅形态)。
///
/// 仅 Android 生效;其它平台或总开关关闭时渲染为空。加载失败时
/// 原生侧回调 onAdLoadError,本组件自动隐藏,不留空白条、不挡内容。
///
/// 调用处必须传一个页面内唯一的稳定 key(见各页的 `ValueKey('banner-…')`):
/// 列表里兄弟项增减(比如解析页报错条出现/消失)时,没 key 的平台视图会
/// 按位置错配、反复销毁重建,原生加载回调就可能撞上已销毁的视图而闪退。
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, this.height = 50});

  final double height;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  static int _channelSeq = 0;
  late final String _channelName;
  MethodChannel? _channel;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _channelName = 'flutter_ads_plugin/banner_callback_${_channelSeq++}';
    _channel = MethodChannel(_channelName)
      ..setMethodCallHandler((call) async {
        if (call.method == 'onAdLoadError') {
          if (mounted) setState(() => _visible = false);
        }
      });
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid || !AdConfig.enabled || !_visible) {
      return const SizedBox.shrink();
    }
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AndroidView(
        viewType: 'flutter_ads_plugin/bannerview',
        creationParams: <String, Object>{
          'codeId': AdConfig.bannerId,
          'channelName': _channelName,
          'width': width.toInt(),
          'height': widget.height.toInt(),
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
