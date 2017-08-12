var ngc = ngc || {};

ngc.cfg = ngc.cfg || {};
ngc.flag = ngc.flag || {};

ngc.loader = ngc.loader || {};

ngc.EImageStatus = {loading: 1, loadSuccess: 2, loadError: 3};
ngc.urlImageStatus = ngc.urlImageStatus || {};

ngc.g_mainScene = ngc.g_mainScene || null;
ngc.hall = ngc.hall || {};
ngc.hall.layer = ngc.hall.layer || {};

ngc.game = ngc.game || {};
ngc.game.layer = ngc.game.layer || {};
ngc.game.node = ngc.game.node || {};
ngc.game.scene=ngc.game.scene||{};


ngc.cfg = {
    shareUrlN:"http://www.nenniu.com/",
    protocolUrlN:"http://www.nenniu.com/update/protocol.html",       //协议地址
    ruleUrlN:"http://www.nenniu.com/update/rule.html",               //协议地址
    urlRecord: "http://115.159.41.197:8080/fileserver/videoDownload.do?method=download",
    // urlHs:"http://172.16.207.139:9081/hs",                           //虚拟机内网
    urlHs:"http://114.215.132.134:9081/hs",                         //外网
    appVersion:"1.0.0",
    appkey:"YSQP",
    pver: "1.0",
    smUserId: 1,
    smPinYin: "ngc",
    localStorageVersion:1,
    GAME_FSADRRESS:"",     //fs缓存
    GAME_ADRRESS:"114.215.132.134",
    // GAME_ADRRESS:"172.16.207.139",
    // GAME_PORT:8873,
    // GAME_PORT:8876,  //3人
    GAME_PORT:0,   //2ren
    _testState:false,
};

ngc.flag = {
    SOUND_FLAG: true,
    MUSIC_FLAG: true,
    SHAKE_FLAG: true,
    HAND_FLAG: false
};

ngc.TUserBaseInfo = cc.Class.extend({
    userId: 0,
    userType: 0,
    score: 0,
    bean: 0,
    userName: "",
    nickName: "",
    sex: 0,
    level: 0,
    faceId: 0,
    faceUrl: "",
    specialGold: "",            // 房卡
    bulletText:"",

    readFromJson: function(json){
        this.userId = json['userId'];
        this.userType = json['userType'];
        this.score = json['score'];
        this.bean = json['bean'];
        this.userName = json['userName'];
        this.nickName = json['nickName'];
        this.sex = json['sex'];
        this.level = json['level'];
        this.faceId = json['faceId'];
        this.faceUrl = json['faceUrl'];
        this.specialGold = json['specialGold'];
        //this.bulletText = json[''];
    },

    /**
     * @param {ngc.TUserBaseInfo} src
     */
    copyFrom: function(src){
        this.userId = src.userId;
        this.userType = src.userType;
        this.score = src.score;
        this.bean = src.bean;
        this.userName = src.userName;
        this.nickName = src.nickName;
        this.sex = src.sex;
        this.level = src.level;
        this.faceId = src.faceId;
        this.faceUrl = src.faceUrl;
    },

    isLogon: function(){
        return this.userId > 0;
    },

    calcFaceUrl: function(){
        var url = this.faceUrl;
        if(url.length < 1)
            return url;

        if(url.substring(0, 4) === "http"){
            return url;
        } else {
            if(url[0] === "/")
                return ngc.cfg.urlHs + url;
            else
                return ngc.cfg.urlHs + "/" + url;
        }
    }
});

ngc.CGameInfo = cc.Class.extend({
    gameId: 0,
    fsUrl: "",
    resJs: "",

    /**
     * @return Boolean
     */
    myInit: function(json){
        var gameId = json["gameId"];
        var fsUrl = json["fs"];
        var resJs = json["res"];
        if(!gameId || !fsUrl || !resJs){
            ngc.log.error("CGameInfo no userData");
            return false;
        }

        this.gameId = gameId;
        this.fsUrl = fsUrl;
        this.resJs = resJs;

        return true;
    },

    /**
     * @param {ngc.CGameInfo} src
     */
    copyFrom: function(src) {
        this.gameId = src.gameId;
        this.fsUrl = src.fsUrl;
        this.resJs = src.resJs;
    }
});