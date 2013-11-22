package com.orcatech.Esh7n;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.telephony.TelephonyManager;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.RelativeLayout;
import android.widget.Toast;

public class MyActivity extends Activity {
    /**
     * Called when the activity is first created.
     */
    public Esh7nAPI _esh7n;

    private CameraView mPreview;
    private RelativeLayout mLayout;
    private boolean CapturingStatus = false;
    public ProgressDialog pd;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        mLayout = (RelativeLayout) findViewById(R.id.CameraLayout);
        Button captureBtn = (Button) findViewById(R.id.capturebutton);
        captureBtn.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                if (!NetworkInterface.isNetworkAvailable(MyActivity.this)) {
                    Toast.makeText(MyActivity.this, "Couldn't connect to internet!", Toast.LENGTH_LONG).show();
                    return;
                }
                pd.show();
                CapturingStatus = true;
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        mPreview.snapShot();
                    }
                });
            }
        });

        String mCountry = "";
        String mManufacture = "";
        String mModel = "";
        String mOS = "";
        String mNetworkOperatorName = "";
        String mPhoneSerialNo = "";

        try{
            TelephonyManager mTelephonyMgr = (TelephonyManager)getSystemService(TELEPHONY_SERVICE);

            mCountry = mTelephonyMgr.getSimCountryIso();
            mManufacture = android.os.Build.MANUFACTURER;
            mModel = android.os.Build.MODEL;
            mOS = "Android";
            mNetworkOperatorName = mTelephonyMgr.getNetworkOperatorName();
            mPhoneSerialNo = mTelephonyMgr.getDeviceId();
        }catch(Exception ignored){
        }

        _esh7n = new Esh7nAPI(this, mCountry, mManufacture, mModel, mOS, mNetworkOperatorName, mPhoneSerialNo);

        pd = new ProgressDialog(this);
        pd.setTitle("Processing...");
        pd.setMessage("Please wait.");
        pd.setCancelable(false);
        pd.setIndeterminate(true);
    }
    @Override
    protected void onResume() {
        super.onResume();

        if(CapturingStatus) return;

        mPreview = new CameraView(this, 0, CameraView.LayoutMode.FitToParent);

        RelativeLayout.LayoutParams previewLayoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
        mLayout.addView(mPreview, 0, previewLayoutParams);
    }
    @Override
    protected void onPause() {
        super.onPause();

        if(CapturingStatus) return;

        mPreview.stop();
        mLayout.removeView(mPreview); // This is necessary.
        mPreview = null;
    }
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle item selection
        switch (item.getItemId()) {
            case R.id.reset_button:
                Rest();
                pd.dismiss();
                return true;
            case R.id.flash_on_off_button:
                mPreview.toggleFlash();
                return true;
            case R.id.GetLastNumber_button:
                if (_esh7n.getLastNumbers(false).isEmpty()) {
                    Toast.makeText(MyActivity.this, "No Last Operation Found", Toast.LENGTH_LONG).show();
                    return true;
                }
                if (!NetworkInterface.isNetworkAvailable(MyActivity.this)) {
                    Toast.makeText(MyActivity.this, "Couldn't connect to internet!", Toast.LENGTH_LONG).show();
                    return true;
                }
                pd.show();
                _esh7n.getNumbersByOperationId("");
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }


    public void onDetectionDone(String OperationID, String number, String Error) {

        String message = "Number is: " + number;
        if(number.trim().isEmpty()) message = "No Number Detected!";
        if(!Error.trim().isEmpty()) message = "Error: " + Error;

        String title = "Operation Id: "+ OperationID;

        AlertDialog.Builder builder = new AlertDialog.Builder(this);

        builder.setTitle(title)
                .setMessage(message)
                .setPositiveButton("Send Recharge Status", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                        pd.show();
                        _esh7n.sendRechargeFlag();
                        dialog.dismiss();
                    }
                })
                .setNegativeButton("Close", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                        CapturingStatus = false;
                        mPreview.start();
                        dialog.dismiss();
                    }
                });

        AlertDialog dialog = builder.create();
        dialog.show();
        dialog.getButton(Dialog.BUTTON_POSITIVE).setEnabled(Error.trim().isEmpty() && !number.trim().isEmpty());

    }
    public void Rest() {
        CapturingStatus = false;
        mPreview.start();
    }


}
