import 'package:flutter/cupertino.dart';
import 'package:jicun/services/ad_config.dart';
import 'package:jicun/services/ad_service.dart';
import 'package:jicun/ui/ad_banner.dart';
import 'package:jicun/ui/ad_feed_card.dart';
import 'package:jicun/ui/glass.dart';
import 'package:jicun/ui/motion.dart';

/// 「设置 → 广告展示(演示)」二级页:灰鲸每种广告类型各试一次的地方。
///
/// 全部是演示 ID,只能验证链路通不通:加载失败、没有填充是演示 ID 的
/// 正常表现,不是 APP 坏了。正式 ID 替换到 `lib/services/ad_config.dart`
/// 之后,这里不用再改。点这里的按钮不会影响解析、下载与设置 ——
/// 激励视频在这里也不解锁任何东西,只报一个结果。
class AdShowcasePage extends StatefulWidget {
  const AdShowcasePage({super.key});

  @override
  State<AdShowcasePage> createState() => _AdShowcasePageState();
}

class _AdShowcasePageState extends State<AdShowcasePage> {
  String _status = '还没点过任何广告。';

  void _setStatus(String text) {
    if (mounted) setState(() => _status = text);
  }

  Future<void> _showSplash() async {
    _setStatus('正在加载开屏…');
    await AdService.instance.showSplash();
    _setStatus('开屏已结束(展示、失败或超时都会回到这里)。');
  }

  Future<void> _showInterstitial() async {
    _setStatus('正在加载插屏…');
    await AdService.instance.maybeShowInterstitial();
    _setStatus('插屏已结束(展示、失败或超时都会回到这里)。');
  }

  Future<void> _showReward() async {
    _setStatus('正在加载激励视频…');
    final outcome = await AdService.instance.showReward();
    _setStatus(switch (outcome) {
      RewardOutcome.granted => '拿到奖励回调(演示,不解锁任何功能)。',
      RewardOutcome.dismissed => '提前关闭了,没有拿到奖励。',
      RewardOutcome.failed => '加载或播放失败,已放行。',
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return SubPage(
      title: '广告展示(演示)',
      child: GoogleSurface(
        brightness: isDark ? Brightness.dark : Brightness.light,
        child: SafeArea(
          child: ListView(
            physics: const ShortBounceScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              GlassPanel(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '演示 ID,仅验证链路',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'App ID ${AdConfig.appId},每种类型一个演示广告位。'
                        '没有填充、加载失败都正常,正式 ID 到了替换 '
                        'lib/services/ad_config.dart 即可。',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '状态:$_status',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CupertinoButton(
                        onPressed: _showSplash,
                        child: const Text('开屏广告'),
                      ),
                      CupertinoButton(
                        onPressed: _showInterstitial,
                        child: const Text('插屏广告'),
                      ),
                      CupertinoButton(
                        onPressed: _showReward,
                        child: const Text('激励视频'),
                      ),
                      const Text(
                        '横幅在页面最下面,信息流是下面这张卡。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const AdFeedCard(),
              const SizedBox(height: 12),
              const AdBanner(),
            ],
          ),
        ),
      ),
    );
  }
}
