package com.shengyou.mj.wxapi;

import org.cocos2dx.javascript.AppActivity;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;

import com.shengyou.mj.Constants;
import com.tencent.mm.sdk.modelbase.BaseReq;
import com.tencent.mm.sdk.modelbase.BaseResp;
import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.IWXAPIEventHandler;
import com.tencent.mm.sdk.openapi.WXAPIFactory;

public class WXPayEntryActivity extends Activity implements IWXAPIEventHandler {
	private IWXAPI api;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		api = WXAPIFactory.createWXAPI(this, Constants.WX_APP_ID, false);
		api.handleIntent(getIntent(), this);
		super.onCreate(savedInstanceState);
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
//		Toast.makeText(
//				this,
//				"resp.getType:" + resp.getType() + "瀵邦喕淇婇弨顖欑帛缂佹挻鐏�:" + resp.errStr
//						+ ";errCode=" + String.valueOf(resp.errCode), 1).show();
		if (resp.errCode == 0) {
			Intent intent = new Intent(this, AppActivity.class);
			intent.putExtra("from", "WX_Pay");
			startActivity(intent);
		} else {
			Toast.makeText(
					this,
					"瀵邦喕淇婇弨顖欑帛闁挎瑨顕ら幋鏍у絿濞戯拷:" + resp.errStr + ";code="
							+ String.valueOf(resp.errCode), 1).show();
		}
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
