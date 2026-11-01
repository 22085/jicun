import 'dart:io';

/// 灰鲸广告的全部 ID 都只在这里。
///
/// 现在全是**演示 ID**(插件示例里的那套,App ID 222700):只能验证
///「初始化 → 加载 → 展示」这条链路通不通,大概率没有填充、没有收入。
/// 即存自己的正式 App ID 与每个类型的正式广告位 ID 必须由用户在文字里
/// 发来、替换到这里 —— 陪玩那个应用的 ID 绝不能复用到即存上,每个类型
/// 都要自己的广告位 ID,别拿一个 ID 顶两个类型。
///
/// 形态与插件能力的对应关系(插件只提供这几种,别按名字脑补没有的):
/// - 开屏:插件 `loadAndShowSplash`。
/// - 插屏/全屏:插件 `loadInterstitial` + `showInterstitial`。
/// - 激励视频:插件 `loadReward` + `showReward`。
/// - 横幅:插件 PlatformView `bannerview`。
/// - 信息流/原生:插件 PlatformView `feedview`(模板 express 形态)。
/// - 画中画/短剧 DJX、WEB 信息流:插件没有对应的 Android SDK 接口,
///   不加。短剧那套是另一个播放器组件,和即存的解析下载无关。
class AdConfig {
  AdConfig._();

  /// 总开关。关掉时 [AdService] 不初始化,各广告位渲染为空。
  static const bool enabled = true;

  /// 灰鲸演示 App ID。正式 ID 到了只改这一行。
  static const String appId = '222700';

  /// 开屏广告位(演示)。冷启动只展示一次。
  static const String splashId = '8184694064941594';

  /// 插屏广告位(演示)。
  static const String interstitialId = '8586650432385914';

  /// 激励视频广告位(演示)。
  static const String rewardId = '2868305903877175';

  /// 信息流/原生广告位(演示)。
  static const String feedId = '1720369284141436';

  /// 横幅广告位(演示)。
  static const String bannerId = '8918335087174889';

  /// 插屏最短间隔:太密会挡住用户连续解析,3 分钟内只试一次。
  static const Duration interstitialMinInterval = Duration(minutes: 3);

  /// 解析成功多少次之后试一次插屏。计数只影响「试不试」,解析结果
  /// 本身先展示、插屏后弹,绝不拿广告挡住解析。
  static const int parsesPerInterstitial = 5;

  /// 只在 Android 上跑:插件是 Android-only,别的平台没有原生实现。
  static bool get isSupported => Platform.isAndroid && enabled;
}
