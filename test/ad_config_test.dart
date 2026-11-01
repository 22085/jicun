import 'package:flutter_test/flutter_test.dart';
import 'package:jicun/services/ad_config.dart';

/// 广告 ID 的形状锁:演示 ID 阶段,每种类型必须各有自己的 ID 且
/// 全部非空。拿一个 ID 顶两个类型时,后台看到的是同一种广告,
/// 填充与结算都会串。正式 ID 到了只换值,「各类型不同」这条判据不变。
void main() {
  test('each ad type has its own non-empty placement id', () {
    final ids = <String>{
      AdConfig.splashId,
      AdConfig.interstitialId,
      AdConfig.rewardId,
      AdConfig.feedId,
      AdConfig.bannerId,
    };
    expect(AdConfig.appId, isNotEmpty);
    expect(ids, hasLength(5));
    expect(ids.every((id) => id.isNotEmpty), isTrue);
  });

  test('interstitial cadence constants are sane', () {
    expect(AdConfig.parsesPerInterstitial, greaterThan(0));
    expect(
      AdConfig.interstitialMinInterval,
      greaterThan(Duration.zero),
    );
  });
}
