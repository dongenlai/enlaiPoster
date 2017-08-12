/**
 * Created by Administrator on 2017/1/19.
 */

ngc.game.layer.GangLayer = ngc.CLayerBase.extend({

    _bg: null,
    _tipBg: null,
    _selectBtn: null,
    _sendArr: [],
    _selectArr: [],
    _allGangArr: [],

    ctor: function () {
        this._super();
        this._sendArr = [];
        this._selectArr = [];
        this._allGangArr = [];
        this.myInit();
    },

    myInit: function () {
        this._super(ngc.game.jsonRes.gangLayer, true);
        this.mySetVisibleTrue();
        this._checkGangCards();
    },

    _checkGangCards: function () {
        var scene = cc.director.getRunningScene();
        var selfInfo = scene.getPlayerByCIndex(0);
        var allCards = selfInfo.layerPart3d.getCardsInfo();
        var cards = allCards[0].slice();
        for (var i = 0; i < cards.length; ++i) {
            var _card = cards[i];
            if (_card > 26) {
                this._allGangArr.push(_card);
            }
        }

        this._showGangCards(this._allGangArr);
    },

    _showGangCards: function (cards) {
        var size = this._bg.getContentSize(),
            pox = size.width / cards.length,
            idx = 0;
        for (var i = 0; i < cards.length; ++i) {
            var _vlu = cards[i];
            var sprite = this._bg.getChildByTag(_vlu);
            if (sprite)
                continue;

            sprite = this._createMj(_vlu);
            sprite.setPosition(cc.p(idx * 120 + pox, 160));
            this._bg.addChild(sprite, 100, _vlu);
            ++idx;
        }
    },

    _createMj: function (value) {
        var mj = new ccui.ImageView("res/g/mjBloody/ui/mj_bg.png");
        var _file = getCardLocalResByValue(value);
        var icon = new cc.Sprite(_file);
        icon.setScale(0.75);
        icon.setPosition(cc.p(37, 50));
        mj.addChild(icon, 1, "icon");

        var self = this;
        mj.setTouchEnabled(true);
        mj.addClickEventListener(function (sender) {
            self.onTouchCards.call(self, sender);
        });
        return mj;
    },

    onTouchCards: function (sender) {
        var tag = sender.getTag();
        var flag = this._selectArr.indexOf(tag);

        if (flag == -1) {
            sender.setColor(cc.color(150, 150, 150));
            var icon = sender.getChildByName("icon");
            icon.setColor(cc.color(150, 150, 150));
            this._selectArr.push(tag);
        } else {
            sender.setColor(cc.color(255, 255, 255));
            var icon1 = sender.getChildByName("icon");
            icon1.setColor(cc.color(255, 255, 255));
            this._selectArr.splice(flag, 1);
        }
    },

    _checkCanGang: function () {
        var scene = cc.director.getRunningScene();
        var specialType = scene.specialGang;
        var flag = false;
        var _selArr = this._selectArr;
        var length = _selArr.length;
        var data = { "gangFlag": 0, "cards": "" };
        this._selectArr.sort();
        if (length == 3) {
            if (_selArr[0] == 31 && _selArr[2] == 33) {
                data.gangFlag = 1;
                this._sendArr.push(data);
                flag = true;
            }

        } else if (length == 4) {
            if (_selArr[0] == 27 && _selArr[3] == 30) {
                this._sendArr.push(data);
                flag = true;
            }

        } else if (length == 5 && specialType == 2) {
            if (_selArr[2] <= 30 && _selArr[3] >= 31) {
                data.gangFlag = 2;
                data.cards = _selArr.join(",");
                this._sendArr.push(data);
                flag = true;
            }
        }

        if (flag) {
            this._clearSelect(flag);
            return true;
        } else {
            return false
        }
    },

    _clearSelect: function () {
        this._bg.removeAllChildren(true);
        for (var i = 0; i < this._selectArr.length; ++i) {
            var _card = this._selectArr[i];
            var idx = this._allGangArr.indexOf(_card);
            if (idx != -1) {
                this._allGangArr.splice(idx, 1);
                this._selectArr.splice(i, 1);
                --i;
            }
        }

        this._selectArr = [];
        this._selectArr.length = 0;
    },

    _checkArray: function (cards) {
        if (cards.length == 0)
            return 0;
        var temp = cards[0];
        var tag = 1;
        for (var i = 1; i < cards.length; ++i) {
            if ((temp + 1) == cards[i]) {
                ++tag;
                temp = cards[i];
            } else {
                temp = cards[i];
            }
        }

        return tag;
    },

    _checkCardsCanGang: function () {
        var card = this._allGangArr;
        card.sort();
        var arr3 = [],
            arr4 = [];

        for (var i = 0; i < card.length; ++i) {
            var _value = card[i];
            if (_value < 31) {
                arr3.push(_value);
            } else {
                arr4.push(_value);
            }
        }

        var tag3 = this._checkArray(arr3);
        var tag4 = this._checkArray(arr4);

        if (tag3 == 4 || tag4 == 3 || (tag3 == 3 && tag4 == 2)) {
            return true;
        } else {
            return false;
        }
    },

    onCancel: function () {
        var scene = cc.director.getRunningScene();
        var pack = {"action":game_msgId_send.SPECIAL_GANG, "data": this._sendArr};
        scene.net.sendData(pack);
        this.removeFromParent(true);
    },

    onSure: function () {
        this._tipBg.setVisible(false);
        this._selectBtn.setTouchEnabled(true);
        this._showGangCards(this._allGangArr);
    },

    onSelect: function () {
        var fff = this._checkCanGang();
        if (!fff) {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "请重新选牌！！");
            this.addChild(commonLayer);
            return;
        }
        var flag = this._checkCardsCanGang();
        if (flag) {
            this._tipBg.setVisible(true);
            this._selectBtn.setTouchEnabled(false);
        } else {
            var scene = cc.director.getRunningScene();
            var pack = {"action":game_msgId_send.SPECIAL_GANG, "data": this._sendArr};
            scene.net.sendData(pack);
            this.removeFromParent(true);
        }
    },

    onExit: function() {
        this._super();
        this._sendArr = [];
        this._sendArr.length = 0;
        this._selectArr = [];
        this._selectArr.length = 0;
        this._allGangArr = [];
        this._allGangArr.length = 0;
    }
});