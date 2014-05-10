package com.orcatech.Esh7n;

import android.widget.Toast;
import com.loopj.android.http.JsonHttpResponseHandler;
import com.loopj.android.http.RequestParams;
import org.json.JSONObject;

import java.io.ByteArrayInputStream;

/**
 * User: Orca Tech
 * Date: 11/16/13
 * Time: 9:39 AM
 */
public class Esh7nAPI {

    //Get these info by contacting info@byorca.com
    final static String AppId = <APPID>;
    final static String APPSecret = <APPSECRET>;
    final String MinDetectedNumbers = "6";
    final Boolean isTestMode = true;
    /////////////////////////////////////////////

    private MyActivity mActivity;
    private String Country = "";
    private String Manufacture = "";
    private String Model = "";
    private String OS = "";
    private String NetworkOperatorName = "";
    private String PhoneSerialNo = "";

    private String LastOperationId = "";
    private String LastNumbers = "";

    public Esh7nAPI(MyActivity mContext, String mCountry, String mManufacture, String mModel, String mOS, String mNetworkOperatorName, String mPhoneSerialNo) {

        mActivity = mContext;

        Country = mCountry;
        Manufacture = mManufacture;
        Model = mModel;
        OS = mOS;
        NetworkOperatorName = mNetworkOperatorName;
        PhoneSerialNo = mPhoneSerialNo;
    }


    public void DetectNumbers(byte[] data, String mNotes){
        String url = "DetectNumbers";
        RequestParams params = new RequestParams();
        params.put("image", new ByteArrayInputStream(data), "image.jpeg");

        if (!AppId.isEmpty()) {
            params.add("appId", AppId);
        }
        if (!APPSecret.isEmpty()) {
            params.add("appSecret", APPSecret);
        }
        if (!Country.isEmpty()) {
            params.add("country", Country);
        }
        if (!Manufacture.isEmpty()) {
            params.add("manufacture", Manufacture);
        }
        if (!Model.isEmpty()) {
            params.add("model", Model);
        }
        if (!OS.isEmpty()) {
            params.add("os", OS);
        }
        if (!NetworkOperatorName.isEmpty()) {
            params.add("networkOperatorName", NetworkOperatorName);
        }
        if (!PhoneSerialNo.isEmpty()) {
            params.add("phoneSerialNo", PhoneSerialNo);
        }
        params.add("minDetectedNumbers", MinDetectedNumbers);

        if (!mNotes.isEmpty()) {
            params.add("notes", mNotes);
        }
        params.add("isTestMode", isTestMode.toString());


        NetworkInterface.post(url,params, new JsonHttpResponseHandler() {
            @Override
            public void onStart()
            {
                Toast.makeText(mActivity, "Connecting Esh7n Server", Toast.LENGTH_SHORT).show();
            }
            @Override
            public void onSuccess(JSONObject JResponse) {

                if (JResponse == null){
                        Toast.makeText(mActivity, "Error: Detecting Numbers is failed", Toast.LENGTH_LONG).show();
                        mActivity.Rest();
                    return;
                }
                try {
                    LastOperationId = JResponse.getString("Operationid");
                    LastNumbers = JResponse.getString("Numbers");
                    int Errorno = JResponse.getInt("Errorno");
                    Esh7NErrorCodes errorMessage = Esh7NErrorCodes.fromInteger(Errorno);
                    if(errorMessage == Esh7NErrorCodes.NoError)
                        mActivity.onDetectionDone(LastOperationId, LastNumbers, "");
                    else
                        mActivity.onDetectionDone(LastOperationId, LastNumbers,  errorMessage.toString());
                } catch (Exception e) {
                    Toast.makeText(mActivity, "Error: Detecting Numbers is failed", Toast.LENGTH_LONG).show();
                    mActivity.Rest();
                }
            }
            @Override
            public void onFailure(Throwable error, JSONObject content)
            {
                Toast.makeText(mActivity, "Failed to connect Esh7n Server", Toast.LENGTH_LONG).show();
                mActivity.Rest();
            }

            @Override
            public void onFinish()
            {
                mActivity.pd.dismiss();
                mActivity.Rest();
            }
        });

    }

    public void sendRechargeFlag(){
        String url = "SendRechargeFlag";
        RequestParams params = new RequestParams();

        if (!AppId.isEmpty()) {
            params.add("appId", AppId);
        }
        if (!APPSecret.isEmpty()) {
            params.add("appSecret", APPSecret);
        }
        if (!LastOperationId.isEmpty()) {
            params.add("operationId", LastOperationId);
        }

        NetworkInterface.get(url,params, new JsonHttpResponseHandler() {
            @Override
            public void onStart()
            {
                Toast.makeText(mActivity, "Connecting Esh7n Server", Toast.LENGTH_SHORT).show();
            }
            @Override
            public void onSuccess(JSONObject JResponse) {

                if (JResponse == null){
                    Toast.makeText(mActivity, "Error: Send Recharge Flag is failed", Toast.LENGTH_LONG).show();
                    mActivity.Rest();
                    return;
                }
                try {
                    int Errorno = JResponse.getInt("Errorno");
                    Esh7NErrorCodes errorMessage = Esh7NErrorCodes.fromInteger(Errorno);
                    if(errorMessage == Esh7NErrorCodes.NoError)
                        Toast.makeText(mActivity, "Recharge Flag is sent ", Toast.LENGTH_LONG).show();
                    else
                        Toast.makeText(mActivity, "Error: " + errorMessage.toString(), Toast.LENGTH_LONG).show();
                } catch (Exception e) {
                    Toast.makeText(mActivity, "Error: Send Recharge Flag is failed", Toast.LENGTH_LONG).show();
                }
            }
            @Override
            public void onFailure(Throwable error, String content)
            {
                Toast.makeText(mActivity, "Failed to connect Esh7n Server", Toast.LENGTH_LONG).show();
            }

            @Override
            public void onFinish()
            {
                mActivity.pd.dismiss();
                mActivity.Rest();
            }
        });

    }

    public void getNumbersByOperationId(String OperationId){
        if(OperationId.isEmpty()) OperationId = LastOperationId;

        String url = "GetNumbersByOperationId";
        RequestParams params = new RequestParams();

        if (!AppId.isEmpty()) {
            params.add("appId", AppId);
        }
        if (!APPSecret.isEmpty()) {
            params.add("appSecret", APPSecret);
        }
        if (!OperationId.isEmpty()) {
            params.add("operationId", OperationId);
        }

        NetworkInterface.get(url,params, new JsonHttpResponseHandler() {
            @Override
            public void onStart()
            {
                Toast.makeText(mActivity, "Connecting Esh7n Server", Toast.LENGTH_SHORT).show();
            }
            @Override
            public void onSuccess(JSONObject JResponse) {

                if (JResponse == null){
                    Toast.makeText(mActivity, "Error to retrieve Numbers", Toast.LENGTH_LONG).show();
                    return;
                }
                try {
                    LastNumbers = JResponse.getString("Numbers");
                    int Errorno = JResponse.getInt("Errorno");
                    Esh7NErrorCodes errorMessage = Esh7NErrorCodes.fromInteger(Errorno);
                    String message = "Number is: " + LastNumbers;
                    if(LastNumbers.trim().isEmpty()) message = "No Number Detected!";
                    if(errorMessage == Esh7NErrorCodes.NoError)
                        Toast.makeText(mActivity, message, Toast.LENGTH_LONG).show();
                    else
                        Toast.makeText(mActivity, "Error: " + errorMessage.toString(), Toast.LENGTH_LONG).show();
                } catch (Exception e) {
                    Toast.makeText(mActivity, "Error to retrieve Numbers", Toast.LENGTH_LONG).show();
                }
                mActivity.Rest();
            }
            @Override
            public void onFailure(Throwable error, String content)
            {
                Toast.makeText(mActivity, "Failed to connect Esh7n Server", Toast.LENGTH_LONG).show();
            }

            @Override
            public void onFinish()
            {
                mActivity.pd.dismiss();
            }
        });

    }

    public String getLastNumbers(boolean isFormatted) {
        String LastUnFormattedNumbers = LastNumbers.replace(" ", "");
        return isFormatted ? LastNumbers : LastUnFormattedNumbers;
    }

    public enum Esh7NErrorCodes {
        ErrorUnexpected("Unexpected Error Occur", -2),
        NoError("No Errors Found", -1),
        SuccessfullInitialization("Successful Initialization", 0),
        ErrorInvalidAppidOrAppsecret("Invalid AppId or AppSecret", 1),
        ErrorInvalidImageFile("Invalid Image Data", 2),
        ErrorServerDown("Server is down",3),
        ErrorOperationidNotfound("Operation Id is not found",4),
        ErrorTrialHasEnded("Expired Account", 5);

        private String stringValue;
        private Esh7NErrorCodes(String toString, int value) {
            stringValue = toString;
        }

        @Override
        public String toString() {
            return stringValue;
        }
        public static  Esh7NErrorCodes fromInteger(int x) {
            switch(x) {
                case -2:
                    return ErrorUnexpected;
                case -1:
                    return NoError;
                case 0:
                    return SuccessfullInitialization;
                case 1:
                    return ErrorInvalidAppidOrAppsecret;
                case 2:
                    return ErrorInvalidImageFile;
                case 3:
                    return ErrorServerDown;
                case 4:
                    return ErrorOperationidNotfound;
                case 5:
                    return ErrorTrialHasEnded;
            }
            return null;
        }

    }
}
