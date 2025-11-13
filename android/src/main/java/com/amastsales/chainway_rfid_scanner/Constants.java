package com.amastsales.chainway_rfid_scanner;

public class Constants {

    public static final String VERSION = "20231205";

    public static final boolean MAIN_D = true;

    public static final boolean HELPER_D = true;

    public static final boolean BTCALLBACK_D = true;

    public static final boolean TAG_LIST_ADAPTER_D = true;

    // flag
    public static final int FLAG_START = 0;
    public static final int FLAG_STOP = 1;
    public static final int FLAG_UPDATE_TIME = 2;
    public static final int FLAG_UHFINFO = 3;
    public static final int FLAG_UHFINFO_LIST = 5;
    public static final int FLAG_SUCCESS = 10;
    public static final int FLAG_FAIL = 11;
    public static final int FLAG_TIME_OVER= 12;

    // TAG
    public static final String TAG_DATA = "tagData";
    public static final String TAG_EPC = "tagEpc";
    public static final String TAG_TID = "tagTid";
    public static final String TAG_USER = "tagUser";
    public static final String TAG_LEN = "tagLen";
    public static final String TAG_COUNT = "tagCount";
    public static final String TAG_RSSI = "tagRssi";

    // MODE
    public static final String MODE_AUTO = "auto";
    public static final String MODE_SINGLE = "single";

    // MESSAGE OPTION
    public static final int MSG_OPTION_CONNECT_STATE_CHANGED = 0;
    public static final int MSG_OPTION_DISCONNECTED = 0;
    public static final int MSG_OPTION_UNDETECTED = -1;
    public static final int MSG_OPTION_CONNECTED = 1;
    public static final int MSG_BACK_PRESSED = 2;
    public static final int MSG_BATT_NOTI = 3; // Always be display Battery

    // POWER
    public static final int POWER_LOW = 5;
    public static final int POWER_MED = 10;
    public static final int POWER_HI = 20;
    public static final int POWER_MAX = 30;

    //<-[20250402]Add Bulk encoding
    public static final String BB_PW = "11112222";
    public static final String PRIVATE_SUFFIX_PW = "0002";
    public static final String REVIVE_SUFFIX_PW = "0000";

    public static class EncodeMode {
        public static final int MASS = 0;
        public static final int PRIVATE = 1;
        public static final int REVIVE = 2;
    }

    public static class EPCItem {
        public String mEPC;
        public String mAccessPW;
        public int mSeqID;

        public EPCItem(String epc, String acPw) {
            mEPC = epc;
            mAccessPW = acPw;
        }
    }
    //[20250402]Add Bulk encoding->

    //<-[20250424]Add other inventory api for test
    public static class InventoryType {
        public static final int NORAML = 0;
        public static final int RSSI_TO_LOCATE = 1;
        public static final int FIND_LOCATE = 2;
        public static final int CUSTOM = 3;
        public static final int RSSI_LIMIT = 4;
        public static final int WITH_PAHSE_FREQ = 5;
    }
    //[20250424]Add other inventory api for test->
}
