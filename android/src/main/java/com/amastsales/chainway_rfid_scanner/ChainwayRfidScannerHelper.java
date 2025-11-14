package com.amastsales.chainway_rfid_scanner;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.SystemClock;
import android.text.TextUtils;
import android.util.Log;

import com.amastsales.chainway_rfid_scanner.control.EpcUtil;
import com.rscja.deviceapi.RFIDWithUHFBLE;
import com.rscja.deviceapi.entity.UHFTAGInfo;
import com.rscja.deviceapi.interfaces.ConnectionStatus;
import com.rscja.deviceapi.interfaces.ConnectionStatusCallback;
import com.rscja.deviceapi.interfaces.IUHFInventoryCallback;
import com.rscja.deviceapi.interfaces.KeyEventCallback;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class ChainwayRfidScannerHelper {
    // -- -- DEBUG
    private static final String TAG = ChainwayRfidScannerHelper.class.getSimpleName();
    private static final boolean D = Constants.HELPER_D;

    // -- -- VARIABLES
    private Context mContext;
    private FlutterPlugin.FlutterPluginBinding mBinding;
    private Activity mActivity;
    private Handler mOptionHandler;
    private RFIDWithUHFBLE mReader;
    private Boolean isScanning = false;
    private Boolean isKeyDownUp = false;
    private int mScanPower = Constants.POWER_HI;
    private int maxRunTime = 99999999;
    private String mConnectState;
    private String mScanMode = Constants.MODE_AUTO;
    private String dAddress = null;
    private final ConnectivityHandler mConnectivityHandler = new ConnectivityHandler();
    private List<UHFTAGInfo> tempDatas = new ArrayList<>();
    private List<HashMap<String, String>> tagList = new ArrayList<>();
    private ConnectionStatusCallback<Object> btCallback = new ConnectionStatusCallback(){
        @Override
        public void getStatus(ConnectionStatus connectionStatus, Object device1) {
            if (D) Log.d(TAG, connectionStatus.toString());
        };
    };
    private KeyEventCallback mKeyEventCallback = new KeyEventCallback(){
        @Override
        public void onKeyDown(int keycode) {

            if (D) Log.d(TAG, "keycode = $keycode");

            if (mReader.getConnectStatus() == ConnectionStatus.CONNECTED) {
                switch (mScanMode) {
                    case Constants.MODE_AUTO:
                        if (D) Log.d(TAG, "AUTO");
                        if (keycode == 3) {
                            isKeyDownUp = true;
                            fPerformInventory();
                        } else {
                            if(!isKeyDownUp){
                                if (keycode == 1) {
                                    if (isScanning) {
                                        fStopInventory();
                                    } else {
                                        fPerformInventory();
                                    }
                                }
                            }
                            if (keycode == 2) {
                                if (isScanning) {
                                    fStopInventory();

                                    SystemClock.sleep(100);
                                }

                                //MR20
                                //inventory();
                            }
                        }

                        break;
                    case Constants.MODE_SINGLE:
                        if (D) Log.d(TAG, "SINGLE");
                        if (keycode == 1) {
                            fPerformSingleInventory();
                        }

                        break;
                }

                switch (mScanPower) {
                    case Constants.POWER_LOW:
                        mReader.setPower(Constants.POWER_LOW);

                        break;
                    case Constants.POWER_MED:
                        mReader.setPower(Constants.POWER_MED);

                        break;
                    case Constants.POWER_HI:
                        mReader.setPower(Constants.POWER_HI);

                        break;
                    case Constants.POWER_MAX:
                        mReader.setPower(Constants.POWER_MAX);

                        break;
                }
            }
        }

        @Override
        public void onKeyUp(int keycode) {

            if (D) Log.d(TAG, "keycode = $keycode");

            if (keycode == 4) {
                fStopInventory();
            }
        }
    };
    private IUHFInventoryCallback mInventoryCallback = new IUHFInventoryCallback() {
        @Override
        public void callback(UHFTAGInfo uhftagInfo) {
            mConnectivityHandler.sendMessage(mConnectivityHandler.obtainMessage(Constants.FLAG_UHFINFO, uhftagInfo));

            if (D) Log.d(TAG,"FLAG_UHFINFO " + uhftagInfo.toString());
        }
    };

    // -- -- CONSTRUCTORS
    private static ChainwayRfidScannerHelper instance;
    public ChainwayRfidScannerHelper(Context context, FlutterPlugin.FlutterPluginBinding binding) {
        mContext = context;
        mBinding = binding;
    }
    public ChainwayRfidScannerHelper(Context context, Activity activity) {
        mContext = context;
        mActivity = activity;
    }

    public static ChainwayRfidScannerHelper getInstance(Context context, FlutterPlugin.FlutterPluginBinding binding) {
        Log.d(TAG, "getInstance");
        if (instance == null) {
            instance = new ChainwayRfidScannerHelper(context, binding);
        }
        return instance;
    }
    public static ChainwayRfidScannerHelper getInstance(Context context, Activity activity) {
        Log.d(TAG, "getInstance");
        if (instance == null) {
            instance = new ChainwayRfidScannerHelper(context, activity);
        } else {
            instance.mActivity = activity;
        }
        return instance;
    }

    // -- -- FUNC
    // -- -- -- PUBLIC (PLUGIN FUNCTIONS)
    public void initReader() {
        if (D) Log.d(TAG, "initReader");

        boolean initResult = false;
        // boolean isConnected = false;

        int isConnectedState = 1;

        mReader = RFIDWithUHFBLE.getInstance();
        if (mReader != null) {
            initResult = mReader.init(mContext);
        }

        if (initResult) {
            Log.i(TAG, "Reader initialized");
            // modelIDStr = (mReader.SD_GetModel() == SDConsts.MODEL.RFR900) ? "RFR900" : "RFR901";
            if (mReader.getConnectStatus() == ConnectionStatus.CONNECTING) {
                // isConnected = true;
                isConnectedState = 0;
            }
        } else if (!initResult) {
            if (D) Log.e(TAG, "Reader open failed");
            // isConnected = false;
            isConnectedState = 2;
        }

        // mAdapter = new TagListAdapter(mContext);
        // mRfidList = new ListNoView(mContext);

        updateConnectState(isConnectedState);
    }
    public boolean connect(String address) {
        if (D) Log.d(TAG, "connect() to " + address);
        dAddress = address;
        if (D) Log.d(TAG, "dAddress as " + dAddress);

        fConnect();

        boolean connected = false;

        for (int i = 0; i < 10; i++) {
            fGetConnectState();

            if (Objects.equals(mConnectState, "Connected")) {
                connected = true;
                mReader.setPower(Constants.POWER_HI);
            }
            if (Objects.equals(mConnectState, "Disconnected")) {
                connected = false;
                dAddress = null;
            }

            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                if (D) Log.e(TAG, "connect() interrupted");
            }

        }

        // if connected, attach mKeyEvent to the mReader
        if (connected) {
            mReader.setKeyEventCallback(mKeyEventCallback);
        }

        if (D) Log.d(TAG, "connect result = " + connected);

        return connected;

    }
    public boolean disconnect() {

        mReader.disconnect();

        for (int i = 0; i < 10; i++) {
            fGetConnectState();
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                if (D) Log.e(TAG, "disconnect() interrupted");
            }
        }

        dAddress = null;

        if (D) Log.d(TAG, "disconnect result = " + mConnectState);

        return Objects.equals(mConnectState, "Disconnected");
    }
    public String getConnectState() {
        fGetConnectState();

        return mConnectState;
    }
    public void setScanMode(String scanMode) {
        mScanMode = scanMode;
    }
    public void setScanPower(int scanPower) {
        mScanPower = scanPower;
    }
    public List<HashMap<String, String>> performInventory() {
        Log.d(TAG, "performInventory");

        if (D) Log.d(TAG, "pInv TagList " + this.tagList.size());

        return this.tagList;
    }
    public void clearInventory() {
        tagList.clear();
        tempDatas.clear();
    }
    public void clearActivity() {
        if (D) Log.d(TAG, "clearActivity");

        mActivity = null;
    }


    // -- -- -- PRIVATE
    private static class ConnectivityHandler extends Handler {
        public ConnectivityHandler() {
            super(Looper.getMainLooper());
        }

        @Override
        public void handleMessage(Message msg) {
            if (instance != null) {
                instance.handleMessage(msg);
            }
        }
    }
    private void handleMessage(Message m) {
        if (D) Log.d(TAG, "mDefaultHandler");
        if (D) Log.d(TAG, "command = " + m.arg1 + " result = " + m.arg2 + " obj = data");

        switch (m.what) {
            case Constants.FLAG_TIME_OVER:
                if (D) Log.d(TAG, "FLAG_TIME_OVER");
                fStopInventory();

                break;
            case Constants.FLAG_STOP:
                if (D) Log.d(TAG, "FLAG_STOP");

                break;
            case Constants.FLAG_UHFINFO_LIST:
                if (D) Log.d(TAG, "FLAG_UHFINFO_LIST");

                List<UHFTAGInfo> list= (List<UHFTAGInfo>) m.obj;

                addUhfTag(list);

                break;
            case Constants.FLAG_START:
                if (D) Log.d(TAG, "FLAG_START");

                break;
            case Constants.FLAG_UPDATE_TIME:
                if (D) Log.d(TAG, "FLAG_UPDATE_TIME");

                mConnectivityHandler.removeMessages(Constants.FLAG_UPDATE_TIME);

                break;
            case Constants.FLAG_UHFINFO:
                if (D) Log.d(TAG, "FLAG_UHFINFO");

                UHFTAGInfo info = (UHFTAGInfo) m.obj;

                addUhfTag(info);

                break;

        }
    }
    private void addUhfTag(List<UHFTAGInfo> list) {
        for (int k = 0; k < list.size(); k++) {
            addUhfTag(list.get(k));
        }
    }
    private void addUhfTag(UHFTAGInfo uhfTag) {
        boolean[] exists = new boolean[1];
        List<UHFTAGInfo> immutableTempData = new ArrayList<>(tempDatas);

        int idx = EpcUtil.getInsertIndex(immutableTempData, uhfTag, exists);

        insertTag(uhfTag, idx, exists[0]);
    }
    private void insertTag(UHFTAGInfo info, int index, Boolean exists) {

        String data = info.getEPC();

        if(!TextUtils.isEmpty(info.getTid())){
            StringBuilder stringBuilder = new StringBuilder();

            stringBuilder.append("EPC:");
            stringBuilder.append(info.getEPC());
            stringBuilder.append("\n");
            stringBuilder.append("TID:");
            stringBuilder.append(info.getTid());

            if(!TextUtils.isEmpty(info.getUser())){
                stringBuilder.append("\n");
                stringBuilder.append("USER:");
                stringBuilder.append(info.getUser());
            }

            data = stringBuilder.toString();
        }

        HashMap<String,String> tagMap = new HashMap<>();

        if(exists){
            tagMap = tagList.get(index);
            tagMap.put(Constants.TAG_COUNT, String.valueOf(Double.parseDouble(tagMap.get(Constants.TAG_COUNT)) + 1));
        } else {

            tagMap.put(Constants.TAG_EPC, info.getEPC());
            tagMap.put(Constants.TAG_COUNT, "1");
            tempDatas.add(index, info);
            tagList.add(index, tagMap);
        }
        tagMap.put(Constants.TAG_USER, info.getUser());
        tagMap.put(Constants.TAG_DATA, data);
        tagMap.put(Constants.TAG_TID, info.getTid());
        tagMap.put(Constants.TAG_RSSI, info.getRssi());

        if (D) Log.d(TAG, "Tag List Size: " + String.valueOf(tagList.size()));
    }
    private void fConnect() {
        if (D) Log.d(TAG, "fConnect() dAddress " + dAddress);

        Thread toConnect = new Thread(() -> {
            mReader.connect(dAddress, btCallback);
        });

        toConnect.start();

        try {
            toConnect.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
    private void fGetConnectState() {
        ConnectionStatus con = mReader.getConnectStatus();

        if (con == ConnectionStatus.CONNECTED) {
            if (D) Log.d(TAG, "connected");
            updateConnectState(0);
        }
        else if (con == ConnectionStatus.DISCONNECTED) {
            if (D) Log.d(TAG, "disconnected");
            updateConnectState(1);
        }
        else {
            if (D) Log.d(TAG, "other state");
            updateConnectState(2);
        }

        if (D) Log.d(TAG, "connect state = " + con.toString());
    }
    private void fPerformInventory()  {
        if (isScanning) {
            return;
        }

        mReader.setInventoryCallback(mInventoryCallback);

        isScanning = true;

        Message msg = mConnectivityHandler.obtainMessage(Constants.FLAG_START);
        if (D) Log.i(TAG, "startInventoryTag() 1");

        if (mReader.startInventoryTag()) {
            msg.arg1 = Constants.FLAG_SUCCESS;
            mConnectivityHandler.sendEmptyMessage(Constants.FLAG_UPDATE_TIME);
            mConnectivityHandler.removeMessages(Constants.FLAG_TIME_OVER);
            mConnectivityHandler.sendEmptyMessageDelayed(Constants.FLAG_TIME_OVER, maxRunTime);
        } else {
            msg.arg1 = Constants.FLAG_FAIL;
            isScanning = false;
        }

        mConnectivityHandler.sendMessage(msg);

    }
    private void fPerformSingleInventory() {
        if (D) Log.d(TAG, "fPerformSingleInventory");

        try {
            UHFTAGInfo info = mReader.inventorySingleTag();

            if (info != null) {
                Message msg = mConnectivityHandler.obtainMessage(Constants.FLAG_UHFINFO);
                msg.obj = info;

                mConnectivityHandler.sendMessage(msg);
            }

            mConnectivityHandler.sendEmptyMessage(Constants.FLAG_UPDATE_TIME);
        } catch (Exception e) {
            mReader.stopInventory();
            if (D) Log.d(TAG, "No Tag" + e.toString());
        }

        SystemClock.sleep(100);

        if (D) Log.d(TAG, "Taglist" + tagList.size());
    }
    private void fStopInventory() {
        if (mContext != null && isScanning)
            mReader.stopInventory();

        isScanning = false;
        mConnectivityHandler.removeMessages(Constants.FLAG_TIME_OVER);
    }
    private void updateConnectState(int i) {
        switch (i) {
            case 0 :
                mConnectState = "Connected";
                if (mOptionHandler != null)
                    mOptionHandler.obtainMessage(Constants.MSG_OPTION_CONNECTED).sendToTarget();

                break;
            case 1 :
                mConnectState = "Disconnected";
                if (mOptionHandler != null)
                    mOptionHandler.obtainMessage(Constants.MSG_OPTION_DISCONNECTED).sendToTarget();

                break;
            case 2 :
                mConnectState = "Undetected";
                if (mOptionHandler != null)
                    mOptionHandler.obtainMessage(Constants.MSG_OPTION_UNDETECTED).sendToTarget();

                break;


        }
    }
}
