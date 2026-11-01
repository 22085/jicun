package com.flutter.ads_plugin.flutter_ads_plugin.view;

import android.app.Activity;
import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.flutter.ads_plugin.flutter_ads_plugin.utils.DensityUtil;
import com.hzhj.openads.HJAdsSdkBanner;
import com.hzhj.openads.domain.HJAdError;
import com.hzhj.openads.listener.HJOnAdsSdkBannerListener;
import com.hzhj.openads.req.HJBannerAdRequest;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class BannerView implements PlatformView, MethodChannel.MethodCallHandler {
    private View myNativeView;
    private HJAdsSdkBanner hjAdsSdkBanner;
    // 加载是异步的:Flutter 侧重建/切页时 dispose() 可能先于加载回调到达。
    // 回调里再碰 hjAdsSdkBanner(已置 null)就是空指针,直接闪退。先记已销毁,
    // 所有回调一律放行,绝不在销毁后碰 SDK 对象。
    private volatile boolean disposed = false;

    private MethodChannel methodChannel;

    BannerView(Activity activity, Context context, BinaryMessenger messenger, int id, Map<String, Object> params) {
        int width = 0;
        int height = 0;
        if (params.containsKey("width")) {
            width = (int) params.get("width");
        }
        if (params.containsKey("height")) {
            height = (int) params.get("height");
        }
        FrameLayout container = new FrameLayout(context);
        container.setLayoutParams(new ViewGroup.LayoutParams(DensityUtil.dp2px(context, width), DensityUtil.dp2px(context, height)));
        this.myNativeView = container;
        String channelName = (String) params.get("channelName");
        methodChannel = new MethodChannel(messenger, channelName);
        methodChannel.setMethodCallHandler(this);
        String codeId = (String) params.get("codeId");
        loadBanner(activity, container, codeId, width, height);
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        // 在接口的回调方法中可以接收到来自Flutter的调用
    }

    @Override
    public View getView() {
        return myNativeView;
    }

    @Override
    public void dispose() {
        disposed = true;
        if (myNativeView instanceof ViewGroup) {
            ((ViewGroup) myNativeView).removeAllViews();
        }
        hjAdsSdkBanner = null;
        if (methodChannel != null) {
            methodChannel.setMethodCallHandler(null);
        }
    }

    private void loadBanner(Activity context, FrameLayout container, String codeId, float width, float height) {
        android.util.Log.d("banner____", "loadBanner");
        hjAdsSdkBanner = new HJAdsSdkBanner(context, new HJOnAdsSdkBannerListener() {
            @Override
            public void onAdLoadSuccess(String s) {
                if (disposed) return;
                HJAdsSdkBanner banner = hjAdsSdkBanner;
                if (banner == null) return;
                methodChannel.invokeMethod("onAdLoadSuccess", null);
                if (banner.isReady()) {
                    banner.showAd(container);
                }
            }

            @Override
            public void onAdLoadError(HJAdError hjAdError, String s) {
                if (disposed) return;
                Map<String, Object> args = new HashMap<>();
                args.put("msg", hjAdError.msg);
                methodChannel.invokeMethod("onAdLoadError", args);
            }

            @Override
            public void onAdShown() {
                if (disposed) return;
                methodChannel.invokeMethod("onAdShown", null);
            }

            @Override
            public void onAdClicked() {
                if (disposed) return;
                methodChannel.invokeMethod("onAdClicked", null);
            }

            @Override
            public void onAdClosed() {
                if (disposed) return;
                methodChannel.invokeMethod("onAdClosed", null);
            }

            @Override
            public void onAdAutoRefreshed() {
                if (disposed) return;
                methodChannel.invokeMethod("onAdAutoRefreshed", null);
            }

            @Override
            public void onAdAutoRefreshFail(HJAdError hjAdError, String s) {
                if (disposed) return;
                methodChannel.invokeMethod("onAdAutoRefreshFail", null);
            }
        });
        HJBannerAdRequest hjBannerAdRequest = new HJBannerAdRequest(codeId, null, null);
        hjAdsSdkBanner.loadAd(hjBannerAdRequest);
    }
}
