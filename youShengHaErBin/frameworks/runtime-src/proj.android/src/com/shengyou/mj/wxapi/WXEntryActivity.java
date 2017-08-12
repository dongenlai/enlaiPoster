package com.shengyou.mj.wxapi;

import org.cocos2dx.javascript.AppActivity;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.shengyou.mj.Constants;
import com.tencent.mm.sdk.modelbase.BaseReq;
import com.tencent.mm.sdk.modelbase.BaseResp;
import com.tencent.mm.sdk.modelmsg.SendAuth;
import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.IWXAPIEventHandler;
import com.tencent.mm.sdk.openapi.WXAPIFactory;

public class WXEntryActivity extends Activity implements IWXAPIEventHandler {
	private IWXAPI api;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		api = WXAPIFactory.createWXAPI(this, Constants.WX_APP_ID, false);
		api.handleIntent(getIntent(), this);
		super.onCreate(savedInstanceState);
		// setContentView
	}

	@Override
	protected void onNewIntent(Intent intent) {
		super.onNewIntent(intent);
		setIntent(intent);
		api.handleIntent(intent, this);
	}

	@Override
	public void onReq(BaseReq arg0) {
	}

	@Override
	public void onResp(BaseResp resp) {
		Intent intent = new Intent(this, AppActivity.class);
		if (resp instanceof SendAuth.Resp) {
			int res = 0;
			switch (resp.errCode) {
			case BaseResp.ErrCode.ERR_OK:
				SendAuth.Resp rep = (SendAuth.Resp) resp;
				res = 1;
				intent.putExtra("code", rep.code);
				intent.putExtra("state", rep.state);
				break;
			case BaseResp.ErrCode.ERR_USER_CANCEL:
				res = -1;
				break;
			case BaseResp.ErrCode.ERR_AUTH_DENIED:
				res = -2;
				break;
			}
			intent.putExtra("from", "WX_Login");
			intent.putExtra("res", res);
		} else {
			int shareResult = 0;
			switch (resp.errCode) {
			case BaseResp.ErrCode.ERR_OK:
				// 分享成功
				shareResult = 1;
				break;
			case BaseResp.ErrCode.ERR_USER_CANCEL:
				// 分享取消
				shareResult = 2;
				break;
			case BaseResp.ErrCode.ERR_AUTH_DENIED:
				// 分享拒绝
				shareResult = 0;
				break;
			}
			intent.putExtra("from", "WX_Share");
			intent.putExtra("shareResult", shareResult);
		}
		AppActivity.instance.processIntent(intent);

		// startActivity(intent);

		finish();
	}

	@Override
	public void onResume() {
		super.onResume();
	}

	@Override
	public void onPause() {
		super.onPause();
	}
}
