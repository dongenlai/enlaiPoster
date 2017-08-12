/****************************************************************************
Copyright (c) 2008-2010 Ricardo Quesada
Copyright (c) 2010-2012 cocos2d-x.org
Copyright (c) 2011      Zynga Inc.
Copyright (c) 2013-2014 Chukong Technologies Inc.
 
http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 ****************************************************************************/
package org.cocos2dx.javascript;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.Date;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.cocos2dx.lib.Cocos2dxJavascriptJavaBridge;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.os.Vibrator;
import android.text.TextUtils;
import android.util.Log;
import android.view.WindowManager;
import android.widget.Toast;

import com.alipay.sdk.pay.Base64;
import com.alipay.sdk.pay.PayResult;
import com.shengyou.mj.Constants;
import com.shengyou.mj.MD5;
import com.tencent.mm.sdk.modelmsg.SendAuth;
import com.tencent.mm.sdk.modelmsg.SendMessageToWX;
import com.tencent.mm.sdk.modelmsg.WXImageObject;
import com.tencent.mm.sdk.modelmsg.WXMediaMessage;
import com.tencent.mm.sdk.modelmsg.WXTextObject;
import com.tencent.mm.sdk.modelmsg.WXWebpageObject;
import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.WXAPIFactory;


// The name of .so is specified in AndroidMenifest.xml. NativityActivity will load it automatically for you.
// You can use "System.loadLibrary()" to load other .so files.

@SuppressLint("DefaultLocale") public class AppActivity extends Cocos2dxActivity {

	static String hostIPAdress = "0.0.0.0";
	public static Activity mActivity;
	static private AppActivity self = null;
	private IWXAPI wxApi; // 鐎甸偊鍠曟穱濂眕i

	private static int gameId; // 婵炴挸鎲￠崹娆戠磽閺嵮冨▏
	private static int sharePoint; // 闁告帒妫旈棅鈺呮倷閿燂拷
	private static int channel; // 闁告帒妫旈棅鈺併�掗悩璁冲

	private static final int SDK_PAY_FLAG = 1;

	private static final int SDK_CHECK_FLAG = 2;

	private static final int REQUEST_EPAY = 20;// 闁哄嫭鎸搁悿鍌炲绩椤栨瑧甯�

	private static final int RESULT_LOAD_IMAGE = 10;
	private static final int RESULT_TAKE_PHOTO = 11;
	private static final int CROP_SMALL_PICTURE = 12;

	private static final int WX_THUMB_SIZE = 100; // 寰俊璁剧疆 瀹介珮

	private Bundle bundle; // 闁哄牏鎮綾tivity閻炴凹鍋婇崳鎼佸棘閺夋寧鏆呴梺杈ㄥ笚濡炲倿鎯冮崟顒佹闁圭櫢鎷�

	public static AppActivity instance;
	private static int lastOrderId;// 濞戞挸锕ラ鑲╋拷瑙勮壘瀹曠喖宕ｉ敓锟�(閺夆晜鐟﹂悧閬嶅磻濮橆厽绠掗柛娆樺灥閸忔ɑ绋夐姀鐘杭闁挎稑鏈〒鑸电附閻ｅ本鐣遍柡鍌滄嚀缁憋繝寮伴娑欐澒闁革负鍔戦崢銈囩磾椤旇姤鐎ù鐘烘硾閵囨瑦绋夐敓锟�)

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		// TODO Auto-generated method stub
		super.onCreate(savedInstanceState);
		// 鐎甸偊鍠曟穱濠偽熼垾铏仴
		instance = this;
		wxApi = WXAPIFactory.createWXAPI(this, Constants.WX_APP_ID);
		wxApi.registerApp(Constants.WX_APP_ID);
		self = this;
		if (nativeIsLandScape()) {
			setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
		} else {
			setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
		}
		// if(nativeIsDebug()){
		getWindow().setFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
				WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
		// }
		hostIPAdress = getHostIpAddress();
	}

	@Override
	public Cocos2dxGLSurfaceView onCreateView() {
		Cocos2dxGLSurfaceView glSurfaceView = new Cocos2dxGLSurfaceView(this);// super.onCreateView();//
		// TestCpp should create stencil buffer

//		String phoneFac = android.os.Build.BRAND.toLowerCase();
//		if ("meizu".equals(phoneFac) || "letv".equals(phoneFac)) {
			glSurfaceView.setEGLConfigChooser(5, 6, 5, 0, 16, 8);
//		} else {
//			glSurfaceView.setEGLConfigChooser(new BaseConfigChooser());
//		}

		return glSurfaceView;
	}

	public String getHostIpAddress() {
		WifiManager wifiMgr = (WifiManager) getSystemService(WIFI_SERVICE);
		WifiInfo wifiInfo = wifiMgr.getConnectionInfo();
		int ip = wifiInfo.getIpAddress();
		return ((ip & 0xFF) + "." + ((ip >>>= 8) & 0xFF) + "."
				+ ((ip >>>= 8) & 0xFF) + "." + ((ip >>>= 8) & 0xFF));
	}

	public static String getLocalIpAddress() {
		return hostIPAdress;
	}

	private static native boolean nativeIsLandScape();

	private static native boolean nativeIsDebug();

	private Handler mHandler = new Handler() {
		public void handleMessage(Message msg) {
			switch (msg.what) {
			case SDK_PAY_FLAG: {
				final DoOrDerRes doOrDerRes = (DoOrDerRes) msg.obj;
				PayResult payResult = new PayResult(doOrDerRes.result);

				// 闁猴拷椤栨瑧甯涢悗瑙勭箚缁绘垿宕堕悙鎼妰婵炲棌鍓濋弫顔界濡偐娉㈤柡瀣矊瀵兘宕濋悩娈垮姰闁挎稑鑻紓鎾舵媼椤旂⒈鍤犻柡锟介娆戝笡閻庤绻勯鐑藉触瀹ュ嫪绻嗛柟顓у灡鐎ｄ胶绮甸崜褍顔婇柡鍐煐閺侇喗绂掑Ο铏规澓闁圭粯鍔掔欢鐢告儍閸曨偄褰嗛梺濮愬劚娴犳稒顨ュ畝锟介锟�
				String resultInfo = payResult.getResult();
				String resultStatus = payResult.getResultStatus();
				Log.e("alipay", "resultStatus:" + resultStatus);
				Log.e("alipay", "resultInfo:" + resultInfo);
				Log.e("alipay", "memo:" + payResult.getMemo());
				// 闁告帇鍊栭弻鍣恊sultStatus
				// 濞戞捁銆�閿熸枻鎷�9000闁炽儲绻傞崹顖涚閿濆牄锟藉啴寮ㄩ娆戝笡闁瑰瓨鍔曟慨娑㈡晬鐏炶棄寰斿ù锝嗘尵婵悂骞�娴ｈ櫣鍨冲ù鐙呯秬閵嗗啴宕ラ锛勭枀闁告瑯鍨板顒勬嚀閸愨晛澶嶉柛娆欑稻閺嬪啫顩奸敓锟�
				byte[] bytes = null;
				try {
					bytes = doOrDerRes.result.getBytes("utf-8");
				} catch (UnsupportedEncodingException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				final String infos = Base64.encode(bytes);

				if (TextUtils.equals(resultStatus, "9000")) {
					// Toast.makeText(AppActivity.this, "闁猴拷椤栨瑧甯涢柟瀛樺姇婵拷",
					// Toast.LENGTH_SHORT).show();
					instance.runOnGLThread(new Runnable() {
						@Override
						public void run() {
							// doOrDerRes.result.replaceAll("\\\"","\\\\\"").replaceAll("\\\'","\\\\\'")
							Cocos2dxJavascriptJavaBridge
									.evalString("PayBZ.notifyPayRes("
											+ doOrDerRes.orderId + ","
											+ doOrDerRes.channelId + ",\""
											+ infos + "\",1)");
						}
					});
				} else {
					// 闁告帇鍊栭弻鍣恊sultStatus 濞戞挻妞藉顏堝灳閿燂拷9000闁炽儲绻傞崹顖涚閿濆牄锟藉啴宕ｉ婵嗗幋闁猴拷椤栨瑧甯涘鎯扮簿鐟欙拷
					// 闁炽儻鎷�8000闁炽儲绻�閸烆剛鎮伴妸锔芥殰濞寸姵顭囩划銊╁几濠婂啯绀堝☉鎾跺劋閺侇喗绂掑Ο鑽ゎ儓闂侇剚鎸哥敮顐﹀炊閻樺啿鐏楅柤鏉挎噽闁绱掗悢宄版枾闁搞儳濮剧换鏇㈠捶閵娧呮惣鐎垫澘鎳忛弫顔界濡偐娉㈤柡瀣矌閳ユ鎷嬮妶蹇曠闁哄牞鎷风紓浣哥墔濮橈箓寮伴幘瀛樞﹂柛姘鹃檮閸ㄦ岸宕濋悢鏈电鞍闁哄牆绉存慨鐔虹博椤栨氨纾芥慨婵勫劦閿熻姤姘ㄩ悡鈩冪▔閸濆嫬娅欓柨娑樼墕閻剙顫楅崒婊冭姵闁绘鍩栭敓鎴掔筏缁憋拷
					if (TextUtils.equals(resultStatus, "8000")) {
						instance.runOnGLThread(new Runnable() {
							@Override
							public void run() {
								Cocos2dxJavascriptJavaBridge
										.evalString("PayBZ.notifyPayRes("
												+ doOrDerRes.orderId + ","
												+ doOrDerRes.channelId + ",\""
												+ infos + "\",0)");
							}
						});

					} else {
						instance.runOnGLThread(new Runnable() {
							@Override
							public void run() {
								Cocos2dxJavascriptJavaBridge
										.evalString("PayBZ.notifyPayRes("
												+ doOrDerRes.orderId + ","
												+ doOrDerRes.channelId + ",\""
												+ infos + "\",-1)");
							}
						});
					}
				}
				break;
			}
			case SDK_CHECK_FLAG: {
				Toast.makeText(AppActivity.this, "婵☆偓鎷烽柡灞诲劤缁劑寮稿锟界拹鐔兼晬閿燂拷" + msg.obj,
						Toast.LENGTH_SHORT).show();
				break;
			}
			default:
				break;
			}
		};
	};

	public static void screenShot(String fullPath, String fileName)
			throws Exception {
		fullPath += "/" + fileName;
		boolean sdcardExist = Environment.getExternalStorageState().equals(
				android.os.Environment.MEDIA_MOUNTED);
		if (sdcardExist) {
			String pathString = Environment.getExternalStorageDirectory() + "/";
			File f1 = new File(fullPath);
			pathString = pathString + "DCIM/Camera";
			File path = new File(pathString);
			String filePath = pathString + "/" + fileName;
			File file2 = new File(filePath);
			if (!path.exists()) {
				path.mkdirs();
			}
			try {
				if (!file2.exists()) {
					file2.createNewFile();
				}
				copyforJava(f1, file2);
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

			Intent intent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
			Uri uri = Uri.fromFile(file2);
			intent.setData(uri);
			self.sendBroadcast(intent);

		}
	}

	public static long copyforJava(File f1, File f2) throws Exception {
		long time = new Date().getTime();
		int length = 2097152;
		FileInputStream in = new FileInputStream(f1);
		FileOutputStream out = new FileOutputStream(f2);
		byte[] buffer = new byte[length];
		while (true) {
			int ins = in.read(buffer);
			if (ins == -1) {
				in.close();
				out.flush();
				out.close();
				return new Date().getTime() - time;
			} else
				out.write(buffer, 0, ins);
		}
	}

	public static class DoOrDerRes {
		public int orderId;
		public int channelId;
		public String thirdOrderId;
		public String result;
	}

	public void processIntent(Intent intent) {
		final Bundle bundle = intent.getExtras();
		if (bundle != null && bundle.getString("from") != null) {
			mHandler.postDelayed(new Runnable() {
				@Override
				public void run() {
					String from = bundle.getString("from");
					try {
						if ("WX_Share".equals(from)) {
							final int shareResult = bundle
									.getInt("shareResult");// 0濠㈡儼绮剧憴锟�,1闁瑰瓨鍔曟慨锟�,2闁告瑦鐗楃粔锟�
							runOnGLThread(new Runnable() {
								@Override
								public void run() {
									long t = System.currentTimeMillis();
									String key = MD5.encrypt("" + gameId
											+ channel + sharePoint + t
											+ shareResult);
									byte[] bytes = null;
									try {
										bytes = key.getBytes("utf-8");
									} catch (UnsupportedEncodingException e) {
										// TODO Auto-generated catch block
										e.printStackTrace();
									}
									final String base64key = Base64
											.encode(bytes);
									Cocos2dxJavascriptJavaBridge
											.evalString("ShareBZ.onResult("
													+ channel + ","
													+ sharePoint + "," + t
													+ "," + shareResult + ",\""
													+ base64key + "\")");
								}
							});
						} else if ("WX_Login".equals(from)) {
							int res = bundle.getInt("res");
							String state = bundle.getString("state") == null ? ""
									: bundle.getString("state");
							String code = bundle.getString("code") == null ? ""
									: bundle.getString("code");
							final String evalStr = "LayerLogic.WXLoginRes("
									+ res + ",\"" + code + "\",\"" + state
									+ "\")";
							runOnGLThread(new Runnable() {
								public void run() {
									Cocos2dxJavascriptJavaBridge
											.evalString(evalStr);
								}
							});
						} else if ("WX_Pay".equals(from)) {
							instance.runOnGLThread(new Runnable() {
								public void run() {
									// doOrDerRes.result.replaceAll("\\\"","\\\\\"").replaceAll("\\\'","\\\\\'")
									Cocos2dxJavascriptJavaBridge
											.evalString("PayBZ.notifyPayRes("
													+ lastOrderId + "," + 2
													+ ",\"\",1)");
								}
							});
						}
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
			}, 80); // 80
		}
	}

	@SuppressLint("DefaultLocale") 
	public static String getPhoneFactoryInfo() {
		String mtype = android.os.Build.MODEL.toLowerCase(); // 閹靛婧�閸ㄥ褰�
		String mtyb = android.os.Build.BRAND.toLowerCase();// 閹靛婧�閸濅胶澧�

		return mtype + "&" + mtyb;
	}

	/**
	 * 濞撴碍甯泂閻犲鍟伴弫銈夊储閻旂儤鏅搁柣銊ュ娴滄洘绌遍垾鍐茬�诲ù婊庡亝鐢挳宕ｉ敓锟�
	 * 
	 * @param gameId
	 *            鐟滅増鎸告晶鐘层�掗崨濠傜亞缂傚倹鐗曡ぐ锟�
	 * @param channel
	 *            闁告帒妫旈棅鈺併�掗悩璁冲,闁烩晩鍠栨晶锟�1闁哄嫷鍨版禍鏇熺┍閿燂拷
	 * @param sharePoint
	 *            闁告帒妫旈棅鈺呮倷閿燂拷
	 * @param pathName
	 *            闁搞儱澧芥晶鏍儍閸曨剚鎷遍柛锔芥緲濠�鎾锤閿燂拷
	 * @param title
	 *            闁告帒妫旈棅鈺呮儍閸曨剛鍨煎Λ甯嫹
	 * @param url
	 *            閺夆晝鍋炵敮鎾捶閺夋寧绲�(婵炲备鍓濆﹢渚�鎮介妸褉鏁勯悗娑欘殘椤戜焦绋夐敓锟�)
	 * @param description
	 *            闁告帒妫旈棅鈺呮儍閸曨剙浼庨弶鈺嬫嫹
	 * @param flag
	 *            (0:闁告帒妫旈棅鈺呭礆閺夊じ绨冲ǎ鍥ｏ拷鐐藉仺闁告瑥顑戠槐锟�1闁挎稒鑹鹃崹搴㈢椤愩垹鐓傜�甸偊鍠曟穱濠囧嫉鐎ｎ亜鍑犻柛锔兼嫹)
	 */
	public static void doShareWithText(int gameId, int channel, String text,
			int flag) {
		AppActivity.gameId = gameId;
		AppActivity.sharePoint = 0;
		AppActivity.channel = channel;
		WXTextObject textObj = new WXTextObject();
		textObj.text = text;
		WXMediaMessage msg = new WXMediaMessage();
		msg.mediaObject = textObj;
		msg.description = text;
		final SendMessageToWX.Req req = new SendMessageToWX.Req();
		req.transaction = String.valueOf(System.currentTimeMillis());
		req.message = msg;
		req.scene = flag == 0 ? SendMessageToWX.Req.WXSceneSession
				: SendMessageToWX.Req.WXSceneTimeline;
		instance.runOnUiThread(new Runnable() {

			@Override
			public void run() {
				instance.wxApi.sendReq(req);
			}
		});
	}

	/**
	 * 濞撴碍甯泂閻犲鍟伴弫銈夊储閻旂儤鏅搁柣銊ュ娴滄洘绌遍垾鍐茬�诲ù婊庡亝鐢挳宕ｉ敓锟�
	 * 
	 * @param gameId
	 *            鐟滅増鎸告晶鐘层�掗崨濠傜亞缂傚倹鐗曡ぐ锟�
	 * @param channel
	 *            闁告帒妫旈棅鈺併�掗悩璁冲,闁烩晩鍠栨晶锟�1闁哄嫷鍨版禍鏇熺┍閿燂拷
	 * @param sharePoint
	 *            闁告帒妫旈棅鈺呮倷閿燂拷
	 * @param pathName
	 *            闁搞儱澧芥晶鏍儍閸曨剚鎷遍柛锔芥緲濠�鎾锤閿燂拷
	 * @param title
	 *            闁告帒妫旈棅鈺呮儍閸曨剛鍨煎Λ甯嫹
	 * @param url
	 *            閺夆晝鍋炵敮鎾捶閺夋寧绲�(婵炲备鍓濆﹢渚�鎮介妸褉鏁勯悗娑欘殘椤戜焦绋夐敓锟�)
	 * @param description
	 *            闁告帒妫旈棅鈺呮儍閸曨剙浼庨弶鈺嬫嫹
	 * @param flag
	 *            (0:闁告帒妫旈棅鈺呭礆閺夊じ绨冲ǎ鍥ｏ拷鐐藉仺闁告瑥顑戠槐锟�1闁挎稒鑹鹃崹搴㈢椤愩垹鐓傜�甸偊鍠曟穱濠囧嫉鐎ｎ亜鍑犻柛锔兼嫹)
	 */
	public static void doShare(int gameId, int channel, int sharePoint,
			String pathName, String title, String url, String description,
			int flag) {
		AppActivity.gameId = gameId;
		AppActivity.sharePoint = sharePoint;
		AppActivity.channel = channel;
		WXWebpageObject webpage = new WXWebpageObject();
		webpage.webpageUrl = url;
		WXMediaMessage msg = new WXMediaMessage(webpage);
		msg.title = title;
		msg.description = description;

		// 鐎甸偊鍠曟穱濠囧礆閸℃洟鐓╅柛銉ュ⒔婢э拷 By 闁戒緤绲炬禒濂稿级閿燂拷
		String pathString = Environment.getExternalStorageDirectory() + "/";
		pathString = pathString + "DCIM/Camera";
		String filePath = pathString + "/" + pathName;
		
		Bitmap thumb = BitmapFactory.decodeFile(filePath);
		if (thumb != null) {
			WXImageObject imageObject = new WXImageObject(thumb);
			msg.mediaObject = imageObject;
			// 閻犱礁澧介悿鍡欑磽閳哄啯娈ｉ柛銉嫹
			Bitmap thumbBmp = Bitmap.createScaledBitmap(thumb, WX_THUMB_SIZE,
					WX_THUMB_SIZE, true);
			thumb.recycle();
		
			msg.thumbData = ImageUtil.bitmap2byte(thumbBmp);

			// msg.setThumbImage(thumb);
		}
		final SendMessageToWX.Req req = new SendMessageToWX.Req();
		req.transaction = String.valueOf(System.currentTimeMillis());
		req.message = msg;
	
		req.scene = flag == 0 ? SendMessageToWX.Req.WXSceneSession
				: SendMessageToWX.Req.WXSceneTimeline;
		instance.runOnUiThread(new Runnable() {

			@Override
			public void run() {
				instance.wxApi.sendReq(req);
			}

		});
	}

	@Override
	public void onNewIntent(Intent intent) {
		Log.v("Edwater", "onNewIntent");
		super.onNewIntent(intent);
		this.bundle = intent.getExtras();
	}

	@Override
	public void onPause() {
		super.onPause();
	}

	@Override
	protected void onResume() {
		super.onResume();
		if (bundle != null) {
			// instance.runOnGLThread(new Runnable() {
			// @Override
			// public void run() {
			// Cocos2dxJavascriptJavaBridge.evalString("PayBZ.resume()");
			// }
			// });
			String from = bundle.getString("from");
			if ("WX_Share".equals(from)) {
				Log.v("Edwater", "WX_Share");
				final int shareResult = bundle.getInt("shareResult");// 0濠㈡儼绮剧憴锟�,1闁瑰瓨鍔曟慨锟�,2闁告瑦鐗楃粔锟�
				runOnGLThread(new Runnable() {
					@Override
					public void run() {
						Log.v("Edwater", "WX_Share1");
						long t = System.currentTimeMillis();
						String key = MD5.encrypt("" + gameId + channel
								+ sharePoint + t + shareResult);
						byte[] bytes = null;
						try {
							bytes = key.getBytes("utf-8");
						} catch (UnsupportedEncodingException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
						final String base64key = Base64.encode(bytes);
						Log.v("Edwater", "WX_Share2");
						Cocos2dxJavascriptJavaBridge
								.evalString("ShareBZ.onResult(" + channel + ","
										+ sharePoint + "," + t + ","
										+ shareResult + ",\"" + base64key
										+ "\")");
					}
				});
			} else if ("WX_Pay".equals(from)) {
				instance.runOnGLThread(new Runnable() {
					@Override
					public void run() {
						// doOrDerRes.result.replaceAll("\\\"","\\\\\"").replaceAll("\\\'","\\\\\'")

						Cocos2dxJavascriptJavaBridge
								.evalString("PayBZ.notifyPayRes(" + lastOrderId
										+ "," + 2 + ",\"\",1)");
					}
				});
			}
			bundle = null;
		}
	}

	@SuppressLint("NewApi")
	public static void setClipboardStr(final String copyStr) {
		instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				ClipboardManager clip = (ClipboardManager) AppActivity
						.getContext().getSystemService(
								Context.CLIPBOARD_SERVICE);
				ClipData cd = ClipData.newPlainText("text", copyStr);
				clip.setPrimaryClip(cd);
			}
		});
	}

	/**
	 * 濞撴碍甯泂閻犲鍟伴弫銈夊储閻旂儤鏅搁悗骞垮灪閸╂稓绮╅婊勭暠濞戞挸顑呭畷鐔煎箳閵夈儱缍� 闁告瑦鍨块敓鎴掔娴滄洘绌遍敍鍕仮鐟滅増娲濋顒�效閿燂拷
	 * 
	 * @param orderId
	 */
	public static void sendWXLoginRequest(String state) {
		final SendAuth.Req req = new SendAuth.Req();
		req.scope = "snsapi_userinfo";
		req.state = state; // 闁烩偓鍔嬬花顒佺┍濠靛洤鐦悹鍥敱閻即宕仦鑺ョ閻犲鍟板▓鎴︽偐閼哥鎷锋笟濠勭闁瑰搫鐗婂鍫㈡嫚闁垮婀撮柛姘鐢偊寮藉畡鎵暔闁搞儳鍋熺划鎵箔椤戣法鐟忛柡鍌氱畭閿熻棄鍊介姘跺矗閸屾稒娈堕柛娆樺灣閺併倖绂嶆惔銊π╂慨婵愭櫑srf闁猴拷鐠囨彃姣婇柨娑樼墣濞夋洜绮╁▎鎺濆殲婵懓鍊烽崥澶愭焻閻樿櫕鏆伴柛鎴滅串缁辨岸鏁嶇仦鐣岀处閻犱緡鍠氶鍥ㄧ▔婢跺鐓欓悽顖ょ細缁楀倻鎷犻妷銉ユ闁轰礁搴滅槐婵嬪矗椤栨繍鍟庣紓鍐惧枙鐠愮喓绮婚敓浠嬪础閺囩姵鐣遍梻鍛箲濠э拷闁轰焦婢樻慨鐎瀍ssion閺夆晜绋栭、鎴﹀冀閿熺姷宕�
		instance.wxApi.sendReq(req);
	}
	
	public static void vibrate(){
		Vibrator vibrator = (Vibrator)self.getSystemService(Context.VIBRATOR_SERVICE);
	    long [] pattern = {100,2000,1000,2000}; // 鍋滄 寮�鍚� 鍋滄 寮�鍚�
	    vibrator.vibrate(500);
	}

}
