package org.cocos2dx.javascript;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.Bitmap.Config;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.LinearGradient;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.PorterDuff.Mode;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Shader.TileMode;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;

public class ImageUtil {

    /**

     * 由资源id获取图片

     *

     * @param context

     * @param resId

     * @return

     */

    public static Drawable getDrawableById(Context context, int resId) {

              if (context == null) {

                       return null;

              }

              return context.getResources().getDrawable(resId);

    }

    /**

     * 由资源id获取位图

     *

     * @param context

     * @param resId

     * @return

     */

    public static Bitmap getBitmapById(Context context, int resId) {

              if (context == null) {

                       return null;

              }

              return BitmapFactory.decodeResource(context.getResources(), resId);

    }



    /**

     * 将Bitmap转化为字节数组

     *

     * @param bitmap

     * @return

     */

    public static byte[] bitmap2byte(Bitmap bitmap) {

              ByteArrayOutputStream baos = null;

              try {

                       baos = new ByteArrayOutputStream();

                       bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);

                       byte[] array = baos.toByteArray();

                       baos.flush();

                       baos.close();

                       return array;

              } catch (Exception e) {

                       e.printStackTrace();

              }

              return null;



    }



    /**

     * 将byte数组转化为bitmap

     *

     * @param data

     * @return

     */

    public static Bitmap byte2bitmap(byte[] data) {

              if (null == data) {

                       return null;

              }

              return BitmapFactory.decodeByteArray(data, 0, data.length);

    }



    /**

     * 将Drawable转化为Bitmap

     *

     * @param drawable

     * @return

     */

    public static Bitmap drawable2bitmap(Drawable drawable) {

              if (null == drawable) {

                       return null;

              }

              int width = drawable.getIntrinsicWidth();

              int height = drawable.getIntrinsicHeight();

              Bitmap bitmap = Bitmap.createBitmap(width, height, drawable

                                .getOpacity() != PixelFormat.OPAQUE ? Bitmap.Config.ARGB_8888

                                : Bitmap.Config.RGB_565);

              Canvas canvas = new Canvas(bitmap);

              drawable.setBounds(0, 0, width, height);

              drawable.draw(canvas);// 重点

              return bitmap;



    }



    /**

     * 将bitmap转化为drawable

     *

     * @param bitmap

     * @return

     */

    public static Drawable bitmap2Drawable(Bitmap bitmap) {

              if (bitmap == null) {

                       return null;

              }

              return new BitmapDrawable(bitmap);

    }



    /**

     * 按指定宽度和高度缩放图片,不保证宽高比例

     *

     * @param bitmap

     * @param w

     * @param h

     * @return

     */

    public static Bitmap zoomBitmap(Bitmap bitmap, int w, int h) {

              if (bitmap == null) {

                       return null;

              }

              int width = bitmap.getWidth();

              int height = bitmap.getHeight();

              Matrix matrix = new Matrix();

              float scaleWidht = ((float) w / width);

              float scaleHeight = ((float) h / height);

              matrix.postScale(scaleWidht, scaleHeight);

              Bitmap newbmp = Bitmap.createBitmap(bitmap, 0, 0, width, height,

                                matrix, true);

              return newbmp;

    }



    /**

     * 将bitmap位图保存到path路径下，图片格式为Bitmap.CompressFormat.PNG，质量为100

     *

     * @param bitmap

     * @param path

     */

    public static boolean saveBitmap(Bitmap bitmap, String path) {

              try {

                       File file = new File(path);

                       File parent = file.getParentFile();

                       if (!parent.exists()) {

                                parent.mkdirs();

                       }

                       FileOutputStream fos = new FileOutputStream(file);

                       boolean b = bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);

                       fos.flush();

                       fos.close();

                       return b;

              } catch (FileNotFoundException e) {

                       e.printStackTrace();

              } catch (IOException e) {

                       e.printStackTrace();

              }

              return false;

    }



    /**

     * 将bitmap位图保存到path路径下

     *

     * @param bitmap

     * @param path

     *            保存路径-Bitmap.CompressFormat.PNG或Bitmap.CompressFormat.JPEG.PNG

     * @param format

     *            格式

     * @param quality

     *            Hint to the compressor, 0-100. 0 meaning compress for small

     *            size, 100 meaning compress for max quality. Some formats, like

     *            PNG which is lossless, will ignore the quality setting

     * @return

     */

    public static boolean saveBitmap(Bitmap bitmap, String path,

                       CompressFormat format, int quality) {

              try {

                       File file = new File(path);

                       File parent = file.getParentFile();

                       if (!parent.exists()) {

                                parent.mkdirs();

                       }

                       FileOutputStream fos = new FileOutputStream(file);

                       boolean b = bitmap.compress(format, quality, fos);

                       fos.flush();

                       fos.close();

                       return b;

              } catch (FileNotFoundException e) {

                       e.printStackTrace();

              } catch (IOException e) {

                       e.printStackTrace();

              }

              return false;

    }



    /**

     * 获得圆角图片

     *

     * @param bitmap

     * @param roundPx

     * @return

     */

    public static Bitmap getRoundedCornerBitmap(Bitmap bitmap, float roundPx) {

              if (bitmap == null) {

                       return null;

              }



              Bitmap output = Bitmap.createBitmap(bitmap.getWidth(),

                                bitmap.getHeight(), Config.ARGB_8888);

              Canvas canvas = new Canvas(output);



              final int color = 0xff424242;

              final Paint paint = new Paint();

              final Rect rect = new Rect(0, 0, bitmap.getWidth(), bitmap.getHeight());

              final RectF rectF = new RectF(rect);



              paint.setAntiAlias(true);

              canvas.drawARGB(0, 0, 0, 0);

              paint.setColor(color);

              canvas.drawRoundRect(rectF, roundPx, roundPx, paint);



              paint.setXfermode(new PorterDuffXfermode(Mode.SRC_IN));

              canvas.drawBitmap(bitmap, rect, rect, paint);



              return output;

    }



    /**

     * 获得带倒影的图片

     */

    public static Bitmap createReflectionImageWithOrigin(Bitmap bitmap) {

              if (bitmap == null) {

                       return null;

              }

              final int reflectionGap = 4;

              int width = bitmap.getWidth();

              int height = bitmap.getHeight();



              Matrix matrix = new Matrix();

              matrix.preScale(1, -1);



              Bitmap reflectionImage = Bitmap.createBitmap(bitmap, 0, height / 2,

                                width, height / 2, matrix, false);



              Bitmap bitmapWithReflection = Bitmap.createBitmap(width,

                                (height + height / 2), Config.ARGB_8888);



              Canvas canvas = new Canvas(bitmapWithReflection);

              canvas.drawBitmap(bitmap, 0, 0, null);

              Paint deafalutPaint = new Paint();

              canvas.drawRect(0, height, width, height + reflectionGap, deafalutPaint);



              canvas.drawBitmap(reflectionImage, 0, height + reflectionGap, null);



              Paint paint = new Paint();

              LinearGradient shader = new LinearGradient(0, bitmap.getHeight(), 0,

                                bitmapWithReflection.getHeight() + reflectionGap, 0x70ffffff,

                                0x00ffffff, TileMode.CLAMP);

              paint.setShader(shader);

              // Set the Transfer mode to be porter duff and destination in

              paint.setXfermode(new PorterDuffXfermode(Mode.DST_IN));

              // Draw a rectangle using the paint with our linear gradient

              canvas.drawRect(0, height, width, bitmapWithReflection.getHeight()

                                + reflectionGap, paint);



              return bitmapWithReflection;

    }

}