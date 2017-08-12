ngc.game.layer.table2d=ngc.CLayerBase.extend({
    _imgpan:null,
    _imgdir1:null,
    _imgdir2:null,
    _imgdir3:null,
    _imgdir4:null,
    _num1:null,
    _num2:null,
    _ani_pare:null,

    _head1:null,
    _head2:null,
    _head3:null,
    _head4:null,

    _num: null,
    _voiceBtn: null,
    _chatBtn:null,
    _voicInfo: null,

    _downList: null,
    _hintLayer: null,
    isMySelf:null, //是否同意其他人退出房间
    isctrlCode:0,           //自己活着其他玩家退桌的标志位

    _clearTableText:null,
    _roomIdTxt: null,
    _inviteBtn: null,
    _startTip: null,

    _roundInfo:null,

    //充值提示
    _ani_cz2:null,
    _ani_cz3:null,
    _ani_cz4:null,

    //选牌提示
    _ani_xq2:null,
    _ani_xq3:null,
    _ani_xq4:null,

    //定缺提示
    _ani_dq2:null,
    _ani_dq3:null,
    _ani_dq4:null,

    //定缺结果展示
    _ani_dqrs1:null,
    _ani_dqrs2:null,
    _ani_dqrs3:null,
    _ani_dqrs4:null,

    //操作结果展示
    _ani_oprs1:null,
    _ani_oprs2:null,
    _ani_oprs3:null,
    _ani_oprs4:null,

    //加减分提示
    _ani_score1:null,
    _ani_score2:null,
    _ani_score3:null,
    _ani_score4:null,

    //掉线提示
    _ui_offline2:null,
    _ui_offline3:null,
    _ui_offline4:null,

    _quiTip:null,

    _discardTip:null,

    _swapDes:null,
    _swapDir:null,


    num:null,
    dir:1,
    _decRecordCount: -1,
    _mJNum:0,        //剩余麻将数量
    _imageHeadAry:[null, null, null, null], //头像数组

    _autoHint: null,
    chatLayer:null,

    countTime:0,
    notVibrate:false,
    curIndex:0,
    _playTypeText:null,

    _ui_bao:null,
    _ani_bao:null,

    myInit:function(){
        this._super(ngc.game.jsonRes.layerTable2d,false);

        var loadInfo = ngc.uiUtils.loadJson(this, ngc.game.jsonRes.layerTable2dbttom);
        loadInfo.node.setCameraMask(cc.CameraFlag.USER3);
        this.addChild(loadInfo.node);


        this.mySetVisibleTrue();
        this._inviteBtn.setVisible(true);
        this._startTip.setVisible(true);

        //添加聊天层(后删除掉为了加载表情缓存)
        this.chatLayer = new ngc.game.layer.chat();
        this.addChild(this.chatLayer, 100);
        this.chatLayer.setVisible(false);
        this.chatLayer.removeFromParent(true);
        this.chatLayer = null;


        this.aniPos=[
            cc.p(cc.winSize.width/2,cc.winSize.height/2-100),
            cc.p(cc.winSize.width/2-220,cc.winSize.height/2+80),
            cc.p(cc.winSize.width/2,cc.winSize.height/2+220),
            cc.p(cc.winSize.width/2+220,cc.winSize.height/2+80),
        ];
        this.aniNode={};
        this.schedule(this.checkDecRecord, 1);

        this.notVibrate=false;

        this._quiTip=null;
    },

    hideInviteTip:function(){
        if(this._inviteBtn)
            this._inviteBtn.setVisible(false);
        if(this._startTip)
            this._startTip.setVisible(false);
    },

    hideAll:function(){
        //this._imgpan.setVisible(false);
        //this._imgdir1.setVisible(false);
        //this._imgdir2.setVisible(false);
        //this._imgdir3.setVisible(false);
        //this._imgdir4.setVisible(false);
        //this._num1.setVisible(false);
        //this._num2.setVisible(false);
        this._ani_pare.setVisible(false);

        //this._head1.setVisible(false);
        //this._head2.setVisible(false);
        //this._head3.setVisible(false);
        //this._head4.setVisible(false);

        //充值提示
        this._ani_cz2.setVisible(false);
        this._ani_cz3.setVisible(false);
        this._ani_cz4.setVisible(false);

        //选牌提示
        this._ani_xq2.setVisible(false);
        this._ani_xq3.setVisible(false);
        this._ani_xq4.setVisible(false);

        //宝
        this._ui_bao.setVisible(false);
        this._ani_bao.setVisible(false);

            //定缺提示
        this._ani_dq2.setVisible(false);
        this._ani_dq3.setVisible(false);
        this._ani_dq4.setVisible(false);

        //定缺结果展示
        this._ani_dqrs1.setVisible(false);
        this._ani_dqrs2.setVisible(false);
        this._ani_dqrs3.setVisible(false);
        this._ani_dqrs4.setVisible(false);

        //操作结果展示
        this._ani_oprs1.setVisible(false);
        this._ani_oprs2.setVisible(false);
        this._ani_oprs3.setVisible(false);
        this._ani_oprs4.setVisible(false);

        this._swapDes.setVisible(false);

        this.showTrustStatus(false);

        this._swapDir.setVisible(false);
    },

    setPlayTypeText : function(data){
        try{
        ngc.log.info("data = " + JSON.stringify(data));

        var isChunJia = data.isChunJia;
        var isLaizi = data.isLaizi;
        var isGuaDaFeng = data.isGuaDaFeng;
        var isSanQiJia = data.isSanQiJia;
        var isDanDiaoJia = data.isDanDiaoJia;
        var isGuaDaFeng = data.isGuaDaFeng;
        var isZhiDuiJia = data.isZhiDuiJia;
        var isZhanLiHu = data.isZhanLiHu;
        var isMenQing = data.isMenQing;
        var isAnKe = data.isAnKe;
        var isKaiPaiZha = data.isKaiPaiZha;
        var isBaoZhongBao = data.isBaoZhongBao;
        var isHEBorDQ = data.isHEBorDQ;

        var playType = "";
        if(isChunJia)
            playType +=  "纯夹 ";
        if(isLaizi)
            playType +=  "红中宝 ";
        if(isSanQiJia)
            playType +=  "三期夹 ";
        if(isDanDiaoJia)
            playType +=  "单吊夹 ";
        if(isZhanLiHu)
            playType +=  "站立胡 ";
        if(isGuaDaFeng)
            playType +=  "刮大风 ";
        if(isMenQing)
            playType +=  "门清 ";
        if(isAnKe)
            playType +=  "暗刻 ";
        if(isKaiPaiZha)
            playType +=  "开牌炸 ";
        if(isBaoZhongBao)
            playType +=  "宝中宝 ";
        if(isHEBorDQ==0)
            playType +=  "哈尔滨玩法 ";
        else if(isHEBorDQ == 1)
            playType +=  "大庆玩法 ";
        }catch(e){
            ngc.log.info(""+e);
        }
        var test = playType.replace(/(.{15})/g,'$1\n');
        ngc.log.info("test = " + test);
        this._playTypeText.setString(test);
    },

    onBackClick:function(){
        if (ngc.g_mainScene._tableRunning) {
            this._autoHint.setVisible(true);
            var self = this;
            this.scheduleOnce(function() {
                self._autoHint.setVisible(false);
            }, 1.5, "hid");
        } else {
            //当只有自己的时候先请求一下散桌
            //if( !ngc.g_mainScene._userIdAry[1] || !ngc.g_mainScene._userIdAry[2] || !ngc.g_mainScene._userIdAry[3]){
            //    var msg = cc.formatStr("请申请一下散桌！");
            //    var commonLayer = new ngc.game.layer.commonBombBoxLayer(3, true, true, msg);
            //    this.addChild(commonLayer);
            //}
            var loadInfo = ngc.uiUtils.loadJson(this, ngc.game.jsonRes.quitTip);
            this.addChild(loadInfo.node);
            this._quiTip=loadInfo.node;
        }
    },
    onQuitTipClose:function(){
        if(this._quiTip){
            var temp=this._quiTip;
            this._quiTip=null;
            temp.removeFromParent(true);
        }
    },
    onQuit:function(){
        var data={
            op:opSelfAction.mjQuit
        };
        cc.eventManager.dispatchCustomEvent(OPEventName,data);
    },

    counting1:function(){
        if(--this.countTime<0){
            this.unschedule(this.counting2);
            return;
        }
        if(this.countTime<=5){
            this.unschedule(this.counting1);
            this.setWarningCount(this.countTime);
        }
        this.setCountStr();
    },

    counting2:function(){
        if(--this.countTime<0){
            this.unschedule(this.counting2);
            return;
        }
        if(ngc.flag&&ngc.flag.SHAKE_FLAG&&this.curIndex==0&&!this.notVibrate&&this.countTime<3){
            this.vibrate();
        }
        this.setCountStr();
    },

    showPareLoading:function(show){
        var timeLine=this._ani_pare.getActionByTag(this._ani_pare.getTag());
        if(show){
            this._ani_pare.setVisible(true);
            timeLine.play("animation0",true);
        }
        else{
            this._ani_pare.setVisible(false);
            var timeLine=this._ani_pare.getActionByTag(this._ani_pare.getTag());
            timeLine.pause();
        }
    },

    setCountStr:function(){
        if(this.countTime>=10)
            this.num.setString(this.countTime.toString());
        else
            this.num.setString("0"+this.countTime.toString());
    },

    //警告计时
    setWarningCount:function(second){
        this._num1.setVisible(false);
        this._num2.setVisible(true);
        this.num=this._num2;
        this.countTime=second||6;
        this.setCountStr();
        this.unschedule(this.counting2);
        this.schedule(this.counting2,1,second-1,0);
    },

    //正常计时
    setNormalCount:function(second,indexInClient,notVibrate){
        if(notVibrate)
            this.notVibrate=true;
        else
            this.notVibrate=false;
        this.curIndex=indexInClient;
        this._num1.setVisible(true);
        this._num2.setVisible(false);

        for(var i=1;i<=4;i++){
            var obj=eval("this._imgdir"+i);
            obj.setVisible(false);
            obj.stopAllActions();
        }

        var obj=eval("this._imgdir"+(indexInClient+1));
        obj.setVisible(true);
        obj.setOpacity(255);
        obj.runAction(cc.repeatForever(cc.sequence(cc.delayTime(0.7),cc.fadeTo(0.7,30),cc.fadeTo(0.7,255))));

        this.num=this._num1;
        second=30;//固定时间
        this.countTime=second||30;
        this.setCountStr();
        this.unschedule(this.counting1);
        this.unschedule(this.counting2);
        this.schedule(this.counting1,1,second-1,0);

        this.showHeadWaitingAni(indexInClient);
    },

    //停止计时
    stopCount:function(){
        this.unschedule(this.counting1);
        this.unschedule(this.counting2);
    },

    //震动
    vibrate:function(){
        if(cc.sys.os==cc.sys.OS_ANDROID)
            jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity","vibrate","()V");
    },

    setSelfDir:function(dir){
        this.dir=dir;

        switch (dir){
            case SitDir.EAST:
                this._imgpan.loadTexture(ngc.game.pngRes.east5,ccui.Widget.LOCAL_TEXTURE);
                break;
            case SitDir.SOURTH:
                this._imgpan.loadTexture(ngc.game.pngRes.sourth5,ccui.Widget.LOCAL_TEXTURE);
                break;
            case SitDir.WEST:
                this._imgpan.loadTexture(ngc.game.pngRes.west5,ccui.Widget.LOCAL_TEXTURE);
                break;
            case SitDir.NORTH:
                this._imgpan.loadTexture(ngc.game.pngRes.north5,ccui.Widget.LOCAL_TEXTURE);
                break;
        }


        var indexInClient=((this.dir-SitDir.EAST)+4)%4;
        var obj=eval("this._imgdir"+(indexInClient+1));
        obj.loadTexture(eval("ngc.game.pngRes.east"+(indexInClient+1)),ccui.Widget.LOCAL_TEXTURE);

        var indexInClient=((this.dir-SitDir.SOURTH)+4)%4;
        var obj=eval("this._imgdir"+(indexInClient+1));
        obj.loadTexture(eval("ngc.game.pngRes.sourth"+(indexInClient+1)),ccui.Widget.LOCAL_TEXTURE);

        var indexInClient=((this.dir-SitDir.WEST)+4)%4;
        var obj=eval("this._imgdir"+(indexInClient+1));
        obj.loadTexture(eval("ngc.game.pngRes.west"+(indexInClient+1)),ccui.Widget.LOCAL_TEXTURE);

        var indexInClient=((this.dir-SitDir.NORTH)+4)%4;
        var obj=eval("this._imgdir"+(indexInClient+1));
        obj.loadTexture(eval("ngc.game.pngRes.north"+(indexInClient+1)),ccui.Widget.LOCAL_TEXTURE);
    },

    getTableDir:function(){
        return this.dir;
    },

    showDiscardTipDelay:function(){
        this.scheduleOnce(this.showDiscardTip,10);
    },

    showDiscardTip:function(){
        this._discardTip.setVisible(true);
    },

    hideDiscardTip:function(){
        this._discardTip.setVisible(false);
        this.unschedule(this.showDiscardTip);
    },

    showBankerByCIndex:function(index,visible){
        var head=eval("this._head"+(index+1));
        var imgState=ccui.helper.seekWidgetByName(head, "_imgState");
        if(imgState){
            imgState.setVisible(visible);
            imgState.loadTexture("res/g/mjBloody/ui/ui_zhaungmk.png",ccui.Widget.LOCAL_TEXTURE);
        }
    },

    showHead:function(index,userInfo,ZScore,ip){
        var head=eval("this._head"+(index+1));
        head.setVisible(true);
        var panel=head.getChildByName("Panel_1");
        var _headIcon = panel.getChildByName("_imgHead");
        var url = userInfo.faceUrl;
        if (_headIcon) {
            this.onChangeIcon(_headIcon, url);
            this._imageHeadAry[index] = _headIcon;
        }
        var beanText=ccui.helper.seekWidgetByName(head, "_beanNum");
        if(beanText){
            beanText.setLocalZOrder(1);
            if(parseInt(ZScore.toString()) < 0 ){
                beanText.setString('/' + Math.abs(ZScore).toString());//userInfo["bean"]
            }else{
                beanText.setString(ZScore.toString());//userInfo["bean"]
            }
        }
        var nameText=ccui.helper.seekWidgetByName(head, "_txtName");
        if(nameText)
            nameText.setString(userInfo["nickName"]);

        if(ip){
            var infoCon=ccui.helper.seekWidgetByName(head, "_userInfoCon");
            if(infoCon){
                var idLbl=ccui.helper.seekWidgetByName(head, "_userId");
                var ipLbl=ccui.helper.seekWidgetByName(head, "_userIp");
                if(idLbl) idLbl.setString(userInfo["userId"]);
                if(ipLbl) ipLbl.setString(ip);
            }
        }

        //if (index == 0) {
        //    this._voiceBtn.setVisible(true);
        //}
    },

    onHeadTouch:function(sender,type){
        if(type == ccui.Widget.TOUCH_ENDED){
            var parent=sender.getParent();
            if(parent){
                var userInfoCon=ccui.helper.seekWidgetByName(parent, "_userInfoCon");
                if(userInfoCon) userInfoCon.setVisible(!userInfoCon.isVisible());
            }
        }
    },

    hideHead:function(index){
        var head=eval("this._head"+(index+1));
        head.setVisible(false);
        //var panel=head.getChildByName("Panel_1");
        //var headIcon = panel.getChildByName("_imgHead");
        //var _file = "res/h/a/head.png";
        //headIcon.setTexture(_file);
    },

    refreshScore:function(index, ZScore){
        var head=eval("this._head"+(index+1));
        var beanText=ccui.helper.seekWidgetByName(head, "_beanNum");
        if(beanText){
            var oldBeanStr=beanText.getString();
            if(parseInt(ZScore.toString()) < 0 ){
                beanText.setString('/' + Math.abs(ZScore).toString());//userInfo["bean"]
            }else{
                beanText.setString(ZScore.toString());//userInfo["bean"]
            }
            if(oldBeanStr!=beanText.getString()){
                var scale=1.5;
                beanText.runAction(cc.sequence(cc.scaleTo(0.2,scale+2.5),cc.delayTime(0.2),cc.scaleTo(0.1,scale)));
            }
        }
    },

    onChangeIcon: function (headIcon, url) {
        var user = ngc.curUser;
        //var faceUrl = user.baseInfo.calcFaceUrl();
        var faceUrl = url;
        if (faceUrl.length > 0) {
            this.loadFaceUrl(faceUrl, headIcon);
        } else {
            var _file = "res/hallUi/a/head.png";
            headIcon.setTexture(_file);
        }

    },

    loadFaceUrl: function (url, headIcon) {
        var data = {type: "selfFace"};
        if (cc.sys.os == cc.sys.OS_IOS) {//ios 头像无法载入bug暂行办法
            JsbBZ.loadHeadImage(headIcon, url, null, data);
            return;
        }
        ngc.uiUtils.replaceTextureUrl(headIcon, url, null, data);
    },


    showHeadAni:function(index,cardType){
        var obj=this.getObjAndPlayAni("this._head",index+1,true);
        var res="";
        switch (cardType){
            case CardType.WAN:
                res="res/g/mjBloody/ui/PlayerState_que0.png";
                break;
            case CardType.TIAO:
                res="res/g/mjBloody/ui/PlayerState_que1.png";
                break;
            case CardType.TONG:
                res="res/g/mjBloody/ui/PlayerState_que2.png";
                break;
        }
        var imgState=ccui.helper.seekWidgetByName(obj, "_imgState");
        imgState.loadTexture(res,ccui.Widget.LOCAL_TEXTURE);
        imgState.setVisible(true);

        var imgLight=obj.getChildByName("_imgLight");
        imgLight.setVisible(true);
    },

    showHeadWaitingAni:function(index){
        for(var i=0;i<4;i++){
            if(i!=index){
                var obj=eval("this._head"+(i+1));
                var sprite=obj.getChildByName("_headWait");
                if(sprite){
                    sprite.stopAllActions();
                    sprite.setVisible(false);
                }
            }
        }
        var obj=eval("this._head"+(index+1));
        if(obj){
            var sprite=obj.getChildByName("_headWait");
            if(sprite&&!sprite.isVisible()){
                cc.spriteFrameCache.addSpriteFrames(ngc.game.plistRes.headAni);
                var frameNames=[
                    "headai_1_03.png","headai_2_03.png","headai_3_03.png","headai_4_03.png","headai_5_03.png",
                    "headai_6_03.png","headai_7_03.png","headai_8_03.png","headai_9_03.png","headai_10_03.png",
                    "headai_11_03.png","headai_12_03.png","headai_13_03.png","headai_14_03.png","headai_15_03.png",
                    "headai_16_03.png","headai_17_03.png","headai_18_03.png","headai_19_03.png","headai_20_03.png",
                    "headai_21_03.png"
                ]
                var animation=new cc.Animation();
                for(var i=0 in frameNames){
                    animation.addSpriteFrame(cc.spriteFrameCache.getSpriteFrame(frameNames[i]));
                }
                animation.setDelayPerUnit(0.1);
                var action = cc.animate(animation);
                sprite.runAction(cc.repeatForever(action));
                sprite.setVisible(true);
            }
        }
    },

    getObjAndPlayAni:function(str,index,once){
        var obj = eval(str+index);
        if(obj){
            obj.setVisible(true);
            var timeLine=obj.getActionByTag(obj.getTag());
            if(timeLine){
                if(!once)
                    timeLine.play("animation0",true);
                else
                    timeLine.play("animation0",false);
            }
            return obj;
        }
    },

    hideTip:function(indexInClient){
        var obj = eval("this._ani_cz"+(indexInClient+1));
        if(obj) obj.setVisible(false);
        var obj = eval("this._ani_xq"+(indexInClient+1));
        if(obj) obj.setVisible(false);
        var obj = eval("this._ani_dq"+(indexInClient+1));
        if(obj) obj.setVisible(false);
    },

    /**
     * 充值提示
     * @param indexInClient
     */
    showCZTip:function(indexInClient){
        this.getObjAndPlayAni("this._ani_cz",indexInClient+1);
    },
    /**
     *选牌提示
     * @param indexInClient
     */
    showXPTip:function(indexInClient){
        this.getObjAndPlayAni("this._ani_xq",indexInClient+1);
    },

    showDQTip:function(indexInClient){
        this.getObjAndPlayAni("this._ani_dq",indexInClient+1);
    },

    showDQRSAni:function(indexInClient,cardType){
        var obj = this.getObjAndPlayAni("this._ani_dqrs",indexInClient+1);
        var timeLine=obj.getActionByTag(obj.getTag());
        var res="";
        if(indexInClient!=0){
            switch (cardType){
                case CardType.WAN:
                    res="res/g/mjBloody/ani/PlayerState_text0.png";
                    break;
                case CardType.TIAO:
                    res="res/g/mjBloody/ani/PlayerState_text1.png";
                    break;
                case CardType.TONG:
                    res="res/g/mjBloody/ani/PlayerState_text2.png";
                    break;
            }
            var imgCon=ccui.helper.seekWidgetByName(obj, "_imgCon");
            imgCon.loadTexture(res,ccui.Widget.LOCAL_TEXTURE);
        }
        else{
            var imgWan=obj.getChildByName("_imgWan");
            var imgTiao=obj.getChildByName("_imgTiao");
            var imgTong=obj.getChildByName("_imgTong");

            imgWan.setVisible(false);
            imgTiao.setVisible(false);
            imgTong.setVisible(false);

            switch (cardType){
                case CardType.WAN:
                    imgWan.setVisible(true);
                    timeLine.play("animation0",false);
                    break;
                case CardType.TIAO:
                    imgTiao.setVisible(true);
                    timeLine.play("animation1",false);
                    break;
                case CardType.TONG:
                    imgTong.setVisible(true);
                    timeLine.play("animation2",false);
                    break;
            }
        }
        var me=this;
        timeLine.setLastFrameCallFunc(function(){
            timeLine.gotoFrameAndPause(0);
            obj.setVisible(false);
            me.showHeadAni(indexInClient,cardType);
        });
    },

    showOPRSAni:function(indexInClient,action,isZiMo){
        ngc.log.info("showOPRSAni = " + action);
        var obj = this.getObjAndPlayAni("this._ani_oprs",indexInClient+1,true);
        var timeLine=obj.getActionByTag(obj.getTag());
        var imgCon=ccui.helper.seekWidgetByName(obj, "_imgCon");
        var imgani = obj.getChildByName("_imgani");
        switch (action){
            case opServerActionCodes.mjaChi:
                imgCon.loadTexture("res/g/mjBloody/ani/BlockOther_chi.png",ccui.Widget.LOCAL_TEXTURE);
                break;
            case opServerActionCodes.mjaPeng:
                imgCon.loadTexture("res/g/mjBloody/ani/BlockOther_peng.png",ccui.Widget.LOCAL_TEXTURE);
                break;
            case opServerActionCodes.mjaTing:
            case opServerActionCodes.mjaTingGang:
            case opServerActionCodes.mjaTingChi:
            case opServerActionCodes.mjaTingPeng:

                imgCon.loadTexture("res/g/hebmj/ani/BlockOther_ting.png",ccui.Widget.LOCAL_TEXTURE);
                break;
            case opServerActionCodes.mjaHu:
                if(isZiMo){
                    imgCon.loadTexture("res/g/mjBloody/ani/BlockOther_zimo.png",ccui.Widget.LOCAL_TEXTURE);
                    imgCon.setContentSize(cc.size(287,161));
                }
                else{
                    imgCon.loadTexture("res/g/mjBloody/ani/BlockOther_hu.png",ccui.Widget.LOCAL_TEXTURE);
                }
                break;
            case opServerActionCodes.mjaDaMingGang:
            case opServerActionCodes.mjaJiaGang:
                imgCon.loadTexture("res/g/hebmj/ani/BlockOther_gang.png",ccui.Widget.LOCAL_TEXTURE);
                break;
                //obj.setVisible(false);
                /*timeLine.gotoFrameAndPause(0);
                this.showGuaFeng(indexInClient);
                var _file = (ngc.curUser.baseInfo.sex == 1) ? "guafeng" : "guafeng";
                this._barOp(_file);*/
            case opServerActionCodes.mjaAnGang:
                imgCon.loadTexture("res/g/hebmj/ani/BlockOther_gang.png",ccui.Widget.LOCAL_TEXTURE);
                break;
                //obj.setVisible(false);
                /*timeLine.gotoFrameAndPause(0);
                this.showXiaYu(indexInClient);
                var _file = (ngc.curUser.baseInfo.sex == 1) ? "xiayu" : "xiayu";
                this._barOp(_file);*/
                //imgCon.loadTexture("res/g/hebmj/ani/BlockOther_gang.png",ccui.Widget.LOCAL_TEXTURE);
                //imgani.setVisible(true);
            default:
                break;
        }
        var me=this;
        timeLine.clearLastFrameCallFunc();
        timeLine.setLastFrameCallFunc(function(){
            timeLine.gotoFrameAndPause(0);
            obj.setVisible(false);
            imgani.setVisible(false);
        });
    },

    //杠
    showGuaFeng:function(index){
        this.showGangAni(ngc.game.jsonRes.aniGuaFeng,"guafeng",index);
    },
    //暗杠
    showXiaYu:function(index){
        this.showGangAni(ngc.game.jsonRes.aniXiaYu,"xiayu",index);
    },
    //点炮
    showLuoLei:function(index,gl2Dpos,callBack,callBackTarget){
        var node=this.showGangAni(ngc.game.jsonRes.aniLuoLei,"luolei",index);
        node.setPosition(gl2Dpos);
        if(callBack&&callBackTarget){
            node.getAnimation().setMovementEventCallFunc(callBack,callBackTarget);
        }
    },
    showGangAni:function(res,name,index){
        if(name=="luolei"||!this.aniNode[name]){
            ccs.armatureDataManager.addArmatureFileInfo(res);
            var node=ccs.Armature.create(name);
            node.setPosition(this.aniPos[index]);
            this.addChild(node);
            if(name=="luolei"&&this.aniNode[name]){
                this.aniNode[name].removeFromParent(true);
                this.aniNode[name]=null;
            }
            this.aniNode[name]=node;
        }
        var node=this.aniNode[name];
        if(node){
            if(this.aniPos[index])
                node.setPosition(this.aniPos[index]);
            node.getAnimation().play(name);
        }
        return node;
    },

    showScoresAni:function(indexInClient,addScores,delayTime){
        this.scheduleOnce(function(){
            var obj=this.getObjAndPlayAni("this._ani_score",indexInClient+1,true);
            var addImg=ccui.helper.seekWidgetByName(obj, "_addImg");
            var minusImg=ccui.helper.seekWidgetByName(obj, "_minusImg");
            if(addScores>=0){
                addImg.setString("+"+addScores.toString());
                addImg.setVisible(true);
                minusImg.setVisible(false);
            }
            else if(addScores<0){
                minusImg.setString(addScores.toString());
                minusImg.setVisible(true);
                addImg.setVisible(false);
            }
        },delayTime);
    },

    _barOp: function (file) {
        if (!ngc.hall.musicGame[file])
            ngc.log.info("Error : file is not found file = " + file);

        //cc.audioEngine.playEffect(ngc.hall.musicGame[file], false);
        if(ngc.flag.SOUND_FLAG)
            ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame[file]);
    },

    //摸宝动画
    showBaoAni:function(showAni){
        if(showAni){
            this._ani_bao.setVisible(true);
            //var cardNode2=this._ani_bao.getChildByName("_card2").getChildByName("_selCard2");
            //cardNode2.loadTexture(getCardLocalResByValue(card2),ccui.Widget.LOCAL_TEXTURE);
            var timeLine=this._ani_bao.getActionByTag(this._ani_bao.getTag());
            if(timeLine){
                this._ani_bao.runAction(cc.sequence(cc.delayTime(0.5),cc.callFunc(function(){
                    timeLine.play("animation0",false);
                })));
                var self=this;
                timeLine.setLastFrameCallFunc(function(){
                    timeLine.gotoFrameAndPause(0);
                    self._ani_bao.setVisible(false);
                    self._ui_bao.setVisible(true);
                });
            }
        }
        else{
            this._ui_bao.setVisible(true);
        }
        //var card3=ccui.helper.seekWidgetByName(this._ui_bao, "_selCard0");
        //card3.loadTexture(getCardLocalResByValue(card2),ccui.Widget.LOCAL_TEXTURE);
    },

    /**
     * @param direction 0:对家，1:顺时针，2:逆时针
     */
    showSwapDes:function(direction,addCards){
        this._swapDes.setVisible(true);
        var txtDes=null;
        switch (direction){
            case 0:
                txtDes=ccui.helper.seekWidgetByName(this._swapDes, "_tx3");
                break;
            case 1:
                txtDes=ccui.helper.seekWidgetByName(this._swapDes, "_tx1");
                break;
            case 2:
                txtDes=ccui.helper.seekWidgetByName(this._swapDes, "_tx2");
                break;
        }
        if(txtDes) txtDes.setVisible(true);
        this.scheduleOnce(function(){
            this.showSwapDirTip(direction,addCards);
        },5);

        this.scheduleOnce(function(){
            this._swapDes.setVisible(false);
            txtDes.setVisible(false);
        },2.8);
    },

    showSwapDirTip:function(direction,swapCards){
        this._swapDir.setVisible(true);
        var swapDir0=this._swapDir.getChildByName("_swap0");
        swapDir0.setVisible(false);
        var swapDir1=this._swapDir.getChildByName("_swap1");
        swapDir1.setVisible(false);
        var swapDir2=this._swapDir.getChildByName("_swap2");
        swapDir2.setVisible(false);

        var swapDir=this._swapDir.getChildByName("_swap"+direction);
        if(swapDir)
            swapDir.setVisible(true);

        if(swapCards.length>0){
            var selCon=ccui.helper.seekWidgetByName(this._swapDir, "_selCon");
            selCon.setVisible(true);
            for(var i=0;i<=2;i++){
                var card=ccui.helper.seekWidgetByName(this._swapDir, "_selCard"+i);
                if(card&&swapCards[i]!=undefined){
                    card.loadTexture(getCardLocalResByValue(swapCards[i]),ccui.Widget.LOCAL_TEXTURE);
                }
            }
        }
    },

    setTingStateVis: function (index, bool) {
        if(arguments.length>0) {
            var obj = this["_head" + (index + 1)];
            var _tingState = obj.getChildByName("_tingState");
            _tingState.setVisible(bool);
        }else{
            for(var i=0;i<=3;++i) {
                var obj = this["_head" + (i + 1)];
                var _tingState = obj.getChildByName("_tingState");
                _tingState.setVisible(false);
            }
        }
    },


    showTrustStatus:function(isTrust){
        if(isTrust){
            var layer=new ngc.game.opcanceltrust();
            layer.myInit();
            this.addChild(layer,0,11114);
        }
        else{
            this.removeChildByTag(11114);
        }
    },

    setRoundInfo:function(curRound,totalRound){
        if(this._roundInfo){
            this._roundInfo.setString(curRound+"/"+totalRound);
        }
    },

    /**
     *掉线提示
     */
    showOfflineTip:function(indexInClient,netState){
        if(netState>=PlayerNetState.tusOffline){//玩家掉线
            var obj=eval("this._ui_offline"+(indexInClient+1));
            if(obj) obj.setVisible(true);
        }
        else{
            var obj=eval("this._ui_offline"+(indexInClient+1));
            if(obj) obj.setVisible(false);
        }
    },

    showResultOne:function(pack){
        var scene=this.getParent();
        var layer=scene.getChildByTag(11115);
        if(layer) {
            layer.setVisible(true);
            return;
        }

        for(var key=0 in pack.scores){
            var player=scene.getPlayerBySIndex(parseInt(key));
            if(player){
                pack.scores[key]["userInfo"]=player.userInfo;
                if(player.isBanker())
                    pack.scores[key]["isBanker"]=1;

                pack.scores[key]["huPai"]=player.getCardsByIndex(2);
            }
        }

        var player = scene.getPlayerBySIndex(0);
        pack.cards0.push(-1);
        pack.cards0 = pack.cards0.concat(player.getCardsByIndex(1));
        //
        var player = scene.getPlayerBySIndex(1);
        pack.cards1.push(-1);
        pack.cards1 = pack.cards1.concat(player.getCardsByIndex(1));

        var slice2State = false;
        if(scene._maJiangRenShu == 2){
            slice2State = true;
        }
        var slice3State = false;
        if(scene._maJiangRenShu == 3){
            slice3State = true;
        }

        if(!slice2State){
            var player = scene.getPlayerBySIndex(2);
            pack.cards2.push(-1);
            pack.cards2 = pack.cards2.concat(player.getCardsByIndex(1));

            if(!slice3State){
                var player = scene.getPlayerBySIndex(3);
                pack.cards3.push(-1);
                pack.cards3 = pack.cards3.concat(player.getCardsByIndex(1));
            }
        }

        var layer=new ngc.game.resultone();
        layer.myInit();
        layer.setData(pack,ngc.g_mainScene.dyNum,ngc.g_mainScene.dyType,ngc.g_mainScene.isMenQ);
        scene.addChild(layer,0,133331);
        return layer;
    },
    removeResultOne:function(){
        var scene=this.getParent();
        if(scene){
            scene.removeChildByTag(133331);
        }
    },
    hideResultOne:function(){
        var scene=this.getParent();
        if(scene){
            var layer=scene.getChildByTag(133331);
            if(layer) layer.setVisible(false);
        }
    },
    setRoundData:function(data){
        var scene=this.getParent();
        if(scene){
            this.roundData=data;
            for(var key=0 in data.countInfo){
                var player=scene.getPlayerBySIndex(parseInt(key));
                if(player){
                    data.countInfo[key]["userInfo"]=player.userInfo;
                }
            }
            try {
                var resultLayer = scene.getChildByTag(133331);
            }catch (e){
                ngc.log.info("the err is"+e);
            }
            if(resultLayer) {
                resultLayer.changeToLastRound();
            }
        }
    },
    /*
      @param {String} argStr 这个参数存在代表的是结算后的状态位
    */
    showRoundResult:function(){
        if(this.roundData!=undefined){
            var scene=this.getParent();
            if(scene){
                var layer=new ngc.game.resultall();
                layer.myInit();
                layer.setData(this.roundData);
                scene.addChild(layer,0,11116);
                this.hideResultOne();
            }
        }
    },
    removeRoundResult:function() {
        var scene=this.getParent();
        if(scene){
            scene.removeChildByTag(11116);
        }
    },

    checkDecRecord: function(){
        if(this._decRecordCount > 0){
            --this._decRecordCount;
            if(this._decRecordCount <= 0){
                this.onBtnRecordClick(null,ccui.Widget.TOUCH_ENDED);
            } else {
                this.updateButton();
            }
        }
    },

    updateButton: function () {
        var audio = ngc.g_mainScene.getAudio();
        this._voicInfo.setVisible(audio.isRecording());
        this._num.string = this._decRecordCount;
        //此时应该恢复音乐
        if(!audio.isRecording()){
            if (ngc.flag.MUSIC_FLAG){
                ngc.audio.getInstance().playBackMusic(ngc.hall.musicGame.bgm);
            }
        }
    },

    //聊天按钮
    onBtnChatClick: function (sender) {
        if(this.chatLayer){
           return;
        }
        //var _gangArray = [{"a":9, "e":"27,28,29,30"},{"a":9, "e":"31,32,33,33"},{"a":9, "e":"31,32,33,33"},{"a":9, "e":"31,32,33,33"},{"a":9, "e":"27,28,29,30"}];
        //  this.removeChildByTag(1123);
        //var layer = new ngc.game.opselectSpecialGang();
        //layer.myInit(_gangArray);
        //this.addChild(layer, 0, 1123);
        //return;

        this.chatLayer = new ngc.game.layer.chat();
        this.addChild(this.chatLayer, 100);
    },

    onBtnRecordClick: function(sender,type){
        var audio = ngc.g_mainScene.getAudio();
        if(type==ccui.Widget.TOUCH_BEGAN){
            if(sender) sender.setScale(1.5);

            if(0 == audio.isRecording()){
                //当点击录音的时候应该先暂停掉背景音乐和音效
                if (ngc.flag.MUSIC_FLAG){
                    ngc.audio.getInstance().removeBackMusic();
                }
                if(0 !== audio.startRecord()){
                    ngc.log.info("录音失败");
                    //cc.audioEngine.resumeMusic();
                    if(ngc.flag.MUSIC_FLAG)
                        ngc.audio.getInstance().playBackMusic(ngc.hall.musicGame.bgm);
                } else {
                    this._decRecordCount = 30;
                }
            }
        }
        else if(type == ccui.Widget.TOUCH_ENDED||type==ccui.Widget.TOUCH_CANCELED){
            if(sender) sender.setScale(1.0);
            if(audio.isRecording()){
                var strRecord = audio.endRecord();
                if(strRecord.length > 0){
                    var _net = ngc.g_mainScene.getNet();
                    _net.sendPackChat(game_sound_type.voice, strRecord);
                }
                ngc.g_mainScene.setVoiceTime(30 - this._decRecordCount);
                this._decRecordCount = -1;
            }
        }

        this.updateButton();
    },

    onPromptClick:function(){
        var data={
            op:opSelfAction.mjChaTing,
        };
        cc.eventManager.dispatchCustomEvent(OPEventName,data);
    },

    onDownList: function () {
        this._downList.setVisible(!this._downList.isVisible());
    },

    onSetting: function() {
        var _setLayer = new ngc.game.layer.SettingLayer(true);
        this.addChild(_setLayer);
        this._downList.setVisible(false);
    },

    onRecvCtrlNotify: function (userName, isctrlCode, isAgree) {
        if (isctrlCode == 0) {
            this.isctrlCode = 1;
            this.isMySelf = null;
            this._hintLayer.setVisible(true);
            this._downList.setVisible(false);
            this._clearTableText.string = cc.formatStr("玩家%s申请"+ "\n" + "解散本桌游戏" + "，您是否同意？", userName);
        } else if(isctrlCode == 1) {
            if(isAgree == 1){
                var msg = cc.formatStr("玩家%s"+ "\n" + "同意解散游戏", userName);
                var commonLayer = new ngc.game.layer.commonBombBoxLayer(3, true, true, msg);
                this.addChild(commonLayer);
            }else{
               this._hintLayer.setVisible(false);
                var msg = cc.formatStr("玩家%s"+ "\n" + "不同意解散游戏", userName);
                var commonLayer = new ngc.game.layer.commonBombBoxLayer(3, true, true, msg);
                this.addChild(commonLayer);
            }
        }else {
            //todo error
        }
    },

    //散桌
    onScattered: function () {
        this.isctrlCode = 0;
        this.isMySelf = true;
        //this._clearTableText.string = "您正在申请解散"+ "\n" + "本桌游戏，是否继续？";
        //说明此时玩家人数已满
        if(ngc.g_mainScene._userIdAry[1] || ngc.g_mainScene._userIdAry[2] || ngc.g_mainScene._userIdAry[3]){
            var netlayer = ngc.g_mainScene.getNet();
            netlayer.sendPackClearTable(this.isctrlCode,  1);

            var clearTableLayer = new ngc.game.clearTableLayer();
            this.addChild(clearTableLayer);
            clearTableLayer.myInit(true, 300);
            ngc.g_mainScene._clearTableLayer = clearTableLayer;
        }else{
            this._hintLayer.setVisible(true);
            this._downList.setVisible(false);
        }
        return;
    },

    onCancel: function () {
        this._hintLayer.setVisible(false);
        //其他人发包自己直接隐藏弹框
        if(this.isctrlCode != 0){
            var netlayer = ngc.g_mainScene.getNet();
            netlayer.sendPackClearTable(1, 0);
        }
    },

    onSure: function () {
        this._hintLayer.setVisible(false);
        var netLayer = ngc.g_mainScene.getNet();
        netLayer.sendPackClearTable(this.isctrlCode,  1);
        if(this.isMySelf){
            var msg = cc.formatStr("您已经申请了散桌请求！");
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(3, true, true, msg);
            this.addChild(commonLayer);
        }
        this.isMySelf = null;
        this.isctrlCode = 0;
    },

    //邀请好友
    onInvite: function () {
        var gameScene = ngc.g_mainScene;
        var tableNum =  gameScene.tableNum;
        var totalRound = gameScene.tableRound;
        var str = "";
        ShareBZ.doShare(1, 4, "", "哈尔滨麻将——房号：" + tableNum, ngc.cfg.shareUrlN, totalRound.toString() + "局" + str+ "小伙伴们，速度来啊！[宝乐棋牌]", 0, function () {
           //console.log("邀请成功");
        });

    }
});
