import 'dart:async';

import 'package:flutter_ads_plugin/flutter_ads_plugin.dart';

import 'ad_config.dart';

/// 激励视频结果:只有 [granted] 才算拿到奖励。
enum RewardOutcome {
  /// 播放完成并拿到奖励回调。
  granted,

  /// 用户在拿到奖励前关闭了广告。
  dismissed,

  /// 加载/播放失败或超时:调用方按 fail-open 处理,不挡住用户。
  failed,
}

/// 灰鲸广告的唯一入口:初始化、开屏、插屏、激励。
///
/// 全部方法都 fail-open:SDK 未初始化、加载失败、超时、非 Android
/// 平台时直接返回,不抛异常、不挡住解析与下载。广告永远不能成为
/// 用户用即存的障碍。解析结果、下载、设置这些核心流程里,调用
/// 这里的方法一律不 await(展示页里用户主动点的按钮除外)。
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  final FlutterAdsPlugin _plugin = FlutterAdsPlugin();

  bool _initialized = false;
  bool _interstitialShowing = false;
  DateTime? _lastInterstitialShownAt;
  int _successfulParses = 0;

  bool get isReady => AdConfig.isSupported && _initialized;

  /// 冷启动时调用一次(见 `bootstrap.dart` 的 `warmUp`)。
  /// 插件的 init 没有完成回调:这里只发初始化指令,加载发生在
  /// 用户真正用到广告位之后,原生 SDK 有足够时间完成启动。
  Future<void> init() async {
    if (_initialized || !AdConfig.isSupported) return;
    try {
      _plugin.initAd(AdConfig.appId, 1);
      _initialized = true;
    } catch (_) {
      // 初始化失败也不抛:后面每次调用都按未就绪直接放行。
    }
  }

  /// 开屏广告:冷启动展示一次。加载失败、关闭或超时都直接放行,
  /// 绝不阻塞启动;原生 SDK 刚初始化时留 1 秒宽限再加载。
  Future<void> showSplash() async {
    if (!isReady) return;
    try {
      final completer = Completer<void>();
      void done() {
        if (!completer.isCompleted) completer.complete();
      }

      await Future<void>.delayed(const Duration(seconds: 1));
      _plugin.loadAndShowSplash(
        AdConfig.splashId,
        onSplashClosed: done,
        onSplashAdFailToLoad: (_, _, _) => done(),
      );
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: done,
      );
    } catch (_) {
      // 开屏失败 = 没有开屏,启动照常。
    } finally {
      try {
        _plugin.destroySplash();
      } catch (_) {}
    }
  }

  /// 解析成功后记一次数,够 [AdConfig.parsesPerInterstitial] 次且
  /// 满足最短间隔时试一次插屏。调用方在解析结果已经展示之后再调,
  /// 插屏弹不出来也不影响结果。
  Future<void> noteSuccessfulParse() async {
    _successfulParses++;
    if (_successfulParses % AdConfig.parsesPerInterstitial != 0) return;
    await maybeShowInterstitial();
  }

  /// 插屏:满足最短间隔才尝试展示,失败或超时直接放行。
  Future<void> maybeShowInterstitial() async {
    if (!isReady) return;
    if (_interstitialShowing) return;
    final now = DateTime.now();
    final last = _lastInterstitialShownAt;
    if (last != null &&
        now.difference(last) < AdConfig.interstitialMinInterval) {
      return;
    }
    _interstitialShowing = true;
    try {
      final completer = Completer<void>();
      void done() {
        if (!completer.isCompleted) completer.complete();
      }

      _plugin.loadInterstitial(
        AdConfig.interstitialId,
        onInterstitialAdLoadSuccess: (_) {
          _lastInterstitialShownAt = DateTime.now();
          _plugin.showInterstitial();
        },
        onInterstitialAdClosed: done,
        onInterstitialAdLoadError: (_, _, _) => done(),
        onInterstitialAdPlayError: (_, _, _) => done(),
      );
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: done,
      );
    } catch (_) {
      // 插屏失败 = 没有插屏,用户继续用。
    } finally {
      _interstitialShowing = false;
      try {
        _plugin.destroyInterstitial();
      } catch (_) {}
    }
  }

  /// 激励视频:拿到奖励回调才返回 [RewardOutcome.granted]。
  /// 展示前先加载,加载成功回调里才 show;超时按失败处理。
  /// 即存里激励只在广告展示页主动触发,不用来解锁任何功能。
  Future<RewardOutcome> showReward() async {
    if (!isReady) return RewardOutcome.failed;
    bool rewarded = false;
    final completer = Completer<RewardOutcome>();
    void done(RewardOutcome outcome) {
      if (!completer.isCompleted) completer.complete(outcome);
    }

    try {
      _plugin.loadReward(
        AdConfig.rewardId,
        'jicun-user',
        <String, Object>{},
        onVideoAdLoadSuccess: (_) {
          _plugin.showReward(<String, Object>{'func_type': 1, 'key': '888'});
        },
        onVideoRewarded: (_) {
          rewarded = true;
        },
        onVideoAdClosed: () {
          done(rewarded ? RewardOutcome.granted : RewardOutcome.dismissed);
        },
        onVideoAdLoadError: (_, _, _) => done(RewardOutcome.failed),
        onVideoAdPlayError: (_, _, _) => done(RewardOutcome.failed),
      );
      return await completer.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () => RewardOutcome.failed,
      );
    } catch (_) {
      return RewardOutcome.failed;
    } finally {
      try {
        _plugin.destroyReward();
      } catch (_) {}
    }
  }
}
