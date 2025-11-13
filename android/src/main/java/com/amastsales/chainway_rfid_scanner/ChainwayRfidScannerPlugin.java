package com.amastsales.chainway_rfid_scanner;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** ChainwayRfidScannerPlugin */
public class ChainwayRfidScannerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private static final String TAG = ChainwayRfidScannerPlugin.class.getSimpleName();
  private static final boolean D = Constants.MAIN_D;

  private MethodChannel channel;
  private ChainwayRfidScannerHelper helper;
  private Context context;
  private FlutterPluginBinding binding;
  private Activity activity;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "chainway_rfid_scanner");
    context = flutterPluginBinding.getApplicationContext();
    binding = flutterPluginBinding;
    channel.setMethodCallHandler(this);

    helper = ChainwayRfidScannerHelper.getInstance(context, binding);

    EventChannel ePerformInventory = new EventChannel(binding.getBinaryMessenger(), EVENT_PerformChainwayInventory);
    ePerformInventory.setStreamHandler(new EventChannelHandler(this, EVENT_PerformChainwayInventory));
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    handleMethods(call, result);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();

    helper = ChainwayRfidScannerHelper.getInstance(context, activity);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
    if (helper != null) {
      helper.clearActivity();
    }
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
    if (helper != null) {
      helper.clearActivity();
    }
  }

  private void handleMethods(@NonNull MethodCall call, @NonNull Result result) {

    switch (call.method) {
      case CHANNEL_GetPlatformVersion:
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;

      case CHANNEL_InitReader:
        if (D) Log.d(TAG, CHANNEL_InitReader);

        try {
          helper.initReader();

          result.success("Reader initialized");

        } catch (Exception e) {
          if (D) Log.d(TAG, CHANNEL_InitReader);
          result.error(TAG, CHANNEL_InitReader, e.toString());

        }

        break;

      case CHANNEL_Connect:
        if (D) Log.d(TAG, CHANNEL_Connect);

        try {
          final String address = call.argument("address");

          Thread connectThread = new Thread(() -> {
            final boolean res = helper.connect(address);

            activity.runOnUiThread(() -> result.success(res));

          });

          connectThread.start();

        } catch (Exception e) {
          if (D) Log.d(TAG, CHANNEL_Connect);
          result.error(TAG, CHANNEL_Connect, e.toString());

        }

        break;

      case CHANNEL_Disconnect:
        if (D) Log.d(TAG, CHANNEL_Disconnect);

        try {
          Thread disconnectThread = new Thread(() -> {
            final boolean res = helper.disconnect();

            activity.runOnUiThread(() -> result.success(res));

          });

          disconnectThread.start();

        } catch (Exception e) {
          if (D) Log.d(TAG, CHANNEL_Disconnect);
          result.error(TAG, CHANNEL_Disconnect, e.toString());

        }

        break;
      case CHANNEL_GetConnectState:
        if (D) Log.d(TAG, CHANNEL_GetConnectState);

        try {
          final String res = helper.getConnectState();

          result.success(res);

        } catch (Exception e) {
          if (D) Log.d(TAG, CHANNEL_GetConnectState);
          result.error(TAG, CHANNEL_GetConnectState, e.toString());

        }

        break;

      case CHANNEL_ClearInventory:
        if (D) Log.d(TAG, CHANNEL_ClearInventory);

        try {
          helper.clearInventory();

          result.success("ListItem cleared");

        } catch (Exception e) {
          if (D) Log.d(TAG, CHANNEL_ClearInventory);
          result.error(TAG, CHANNEL_ClearInventory, e.toString());

        }

        break;

      case CHANNEL_SetScanMode:
        if (D) Log.d(TAG, CHANNEL_SetScanMode);

        final String scanMode = call.argument("scanMode");
        if (D) Log.d(TAG, "String ScanMode" + scanMode);

        if (!Objects.equals(scanMode, Constants.MODE_SINGLE) || !Objects.equals(scanMode, Constants.MODE_AUTO)) {
          result.success(false);
        }

        try {
          helper.setScanMode(scanMode);

          result.success(true);
        } catch (Exception e) {
          if (D) Log.d(TAG, CHANNEL_SetScanMode);
          result.error(TAG, CHANNEL_SetScanMode, e.toString());
        }

        break;

      case CHANNEL_SetScanPower:
        if (D) Log.d(TAG,CHANNEL_SetScanPower);

        final int scanPower = call.argument("scanPower");
        if (D) Log.d(TAG, "Int ScanPower" + scanPower);

        if (scanPower < Constants.POWER_LOW || scanPower > Constants.POWER_MAX) {
          result.success(false);
        }

        try {
          helper.setScanPower(scanPower);

          result.success(true);
        } catch (Exception e) {
          if (D) Log.d(TAG, CHANNEL_SetScanPower);
          result.error(TAG, CHANNEL_SetScanPower, e.toString());
        }

        break;

      default:
        result.notImplemented();
    }
  }

  // -- normal channels
  private static final String CHANNEL_GetPlatformVersion = "getPlatformVersion";
  private static final String CHANNEL_InitReader = "initReader";
  private static final String CHANNEL_Connect = "connect";
  private static final String CHANNEL_Disconnect = "disconnect";
  private static final String CHANNEL_GetConnectState = "getConnectState";
  private static final String CHANNEL_ClearInventory = "clearInventory";
  private static final String CHANNEL_SetScanMode = "setScanMode";
  private static final String CHANNEL_SetScanPower = "setScanPower";


  // -- event channels
  private static final String EVENT_PerformChainwayInventory = "performChainwayInventory";


  // -- handlers
  private class EventChannelHandler implements EventChannel.StreamHandler{

    private EventChannel.EventSink eSink = null;
    private ChainwayRfidScannerPlugin eContext;
    private String eChannel;
    private Boolean eTriggerActivity;
    private volatile Boolean isListening = false;


    public EventChannelHandler(ChainwayRfidScannerPlugin context, String channel) {
      if (eContext == null)
        eContext = context;

      eChannel = channel;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
      eSink = events;
      isListening = true;

      new Thread(() -> {
        while(isListening) {
          switch (eChannel) {
            case EVENT_PerformChainwayInventory:
              if (D) Log.d(TAG, EVENT_PerformChainwayInventory);
              List<Map<String, Object>> list = new ArrayList<>();

              try {
                List<HashMap<String, String>> mItemList = helper.performInventory();

                 Log.d(TAG, eChannel + " " + String.valueOf(mItemList.size()));

                for (HashMap<String, String> item : mItemList) {
                  Log.d(TAG, eChannel + " " +String.valueOf(item));

                  Map<String, Object> map = new HashMap<>();
                  map.put("epc", item.get(Constants.TAG_EPC));
                  map.put("info", item.get(Constants.TAG_RSSI));
                  map.put("dupCount", item.get(Constants.TAG_COUNT));

                  list.add(map);
                }

                if (activity != null && eSink != null) {
                  activity.runOnUiThread(() -> {
                    if (eSink != null)
                      eSink.success(list);
                  });
                }

                Thread.sleep(1000);

              } catch (Exception e) {
                Log.e(eChannel, "", e);
                eSink.error(eChannel, e.getMessage(), null);
              }

              break;
          }
        }


      }).start();

    }

    @Override
    public void onCancel(Object arguments) {
      isListening = false;
      eSink = null;
    }
  }
}
