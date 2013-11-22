package com.orcatech.Esh7n;

/**
 * User: Orca Tech
 * Date: 11/16/13
 * Time: 9:46 AM
 */
import android.app.Activity;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import com.loopj.android.http.*;

import java.io.ByteArrayInputStream;

public class NetworkInterface {
    private static final String BASE_URL = "http://esh7n.byorca.com/";
    private static AsyncHttpClient client = new AsyncHttpClient();

    public static void post(String url, RequestParams params, AsyncHttpResponseHandler responseHandler) {
        client.post(getAbsoluteUrl(url), params, responseHandler);
    }

    public static void get(String url, RequestParams params, AsyncHttpResponseHandler responseHandler) {
        client.get(getAbsoluteUrl(url), params, responseHandler);
    }

    private static String getAbsoluteUrl(String relativeUrl) {
        return BASE_URL + relativeUrl;
    }

    public static boolean isNetworkAvailable(Activity mActivity) {
        ConnectivityManager cm = (ConnectivityManager)
                mActivity.getSystemService(mActivity.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = cm.getActiveNetworkInfo();
        // if no network is available networkInfo will be null
        // otherwise check if we are connected
        return networkInfo != null && networkInfo.isConnected();
    }
}
