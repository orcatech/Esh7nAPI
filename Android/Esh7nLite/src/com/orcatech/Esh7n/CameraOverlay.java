package com.orcatech.Esh7n;

/**
 * User: Orca Tech
 * Date: 11/16/13
 * Time: 8:37 AM
 */
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.SurfaceView;

public class CameraOverlay extends SurfaceView{
    public static Rect CameraHole;

    private Paint rectPaint = new Paint();
    private Paint outPaint = new Paint();
    private Rect above = new Rect();
    private Rect bottom = new Rect();
    private Rect right = new Rect();
    private Rect left = new Rect();

    private DisplayMetrics metrics;


    public CameraOverlay(Context context, AttributeSet attrs) {
        super(context, attrs);

        // Create out paint to use for drawing
        rectPaint.setARGB(0, 0, 0, 0);
        outPaint.setARGB(229, 229, 229, 229);

        metrics = getResources().getDisplayMetrics();
        CameraHole = new Rect(0,0,0,0);

        // This call is necessary, or else the
        // draw method will not be called.
        setWillNotDraw(false);
    }

    @Override
    protected void onDraw(Canvas canvas){
        super.onDraw(canvas);


        int x = (int) (0.1 * getWidth());
        int y = (int) (0.2 * getHeight());
        int w = (int) (0.8 * getWidth());
        int h = (int) (50* metrics.density);

        CameraHole.set(x, y, x+w, y+h);

        above.set(0, 0, getWidth() , y);
        bottom.set(0, y+h, getWidth(), getHeight());
        left.set(0, y, x, y + h);
        right.set(x+w, y, getWidth(), y + h);


        canvas.drawRect(CameraHole.left, CameraHole.top, CameraHole.right, CameraHole.bottom, rectPaint);
        canvas.drawRect(above, outPaint);
        canvas.drawRect(bottom, outPaint);
        canvas.drawRect(left, outPaint);
        canvas.drawRect(right, outPaint);


    }
}
