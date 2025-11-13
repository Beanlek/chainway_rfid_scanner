package com.amastsales.chainway_rfid_scanner.control;

import com.rscja.deviceapi.entity.UHFTAGInfo;

import java.util.List;

public class EpcUtil {
    public static int getInsertIndex(List<UHFTAGInfo> listData, UHFTAGInfo newInfo, boolean[] exists) {
        int startIndex = 0;
        int endIndex = listData.size();
        int judgeIndex;
        int ret;

        if (endIndex == 0) {
            exists[0] = false;
            return 0;
        }

        endIndex--;

        while (true) {
            judgeIndex = (startIndex + endIndex) / 2;
            ret = compareBytes(newInfo.getEpcBytes(), listData.get(judgeIndex).getEpcBytes());

            if (ret > 0) {
                if (judgeIndex == endIndex) {
                    exists[0] = false;
                    return judgeIndex + 1;
                }
                startIndex = judgeIndex + 1;
            } else if (ret < 0) {
                if (judgeIndex == startIndex) {
                    exists[0] = false;
                    return judgeIndex;
                }
                endIndex = judgeIndex - 1;
            } else {
                exists[0] = true;
                return judgeIndex;
            }
        }
    }

    private static int compareBytes(byte[] b1, byte[] b2) {
        byte[] len = (b1.length < b2.length) ? b1 : b2;
        int value1, value2;

        for (int i = 0; i < len.length; i++) {
            value1 = b1[i] & 0xFF;
            value2 = b2[i] & 0xFF;

            if (value1 > value2) {
                return 1;
            } else if (value1 < value2) {
                return -1;
            }
        }

        if (b1.length > b2.length) {
            return 2;
        } else if (b1.length < b2.length) {
            return -2;
        } else {
            return 0;
        }
    }
}
