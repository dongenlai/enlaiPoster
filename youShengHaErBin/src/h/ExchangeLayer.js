/**
 * Created by admin on 2016/8/19.
 */

ngc.game.layer.ExchangeLayer = ngc.CLayerBase.extend({

    _tempPanel: null,
    _tempView: null,
    _exBtn: null,
    _exRecordUi: null,
    _itemListView: null,
    _recordListView: null,
    _flag: true,

    ctor: function () {
       this._super();
        this.myInit();
    },


    myInit: function () {
        this._super(ngc.hall.jsonRes.exchangeLayer, true);
        this.mySetVisible(true);

        this._initListView();
    },

    _initListView: function () {

        for (var i = 0; i < 3; ++i) {
            var _tempPanel = this._tempPanel.clone();
            var _exIcon = _tempPanel.getChildByName("exIcon");
            var _exContent = _tempPanel.getChildByName("exContent");
            var _exTime = _tempPanel.getChildByName("exTime");
            //_exIcon.setTexture("");
            //_exContent.string = "";
            //_exTime.string = "";
            this._recordListView.pushBackCustomItem(_tempPanel);
        }

        for (var j = 0; j < 6; ++j) {
            if (j % 3 == 0) {
                var _tempItem = new ccui.Layout();
                _tempItem.setContentSize(cc.size(970, 250));
                this._itemListView.pushBackCustomItem(_tempItem);
            } else {
                var _items = this._itemListView.getItems();
                var _tempItem = this._itemListView.getItem(_items.length - 1);
            }
            var _tempView = this._tempView.clone();
            var _icon = _tempView.getChildByName("icon");
            var _nameTxt = _tempView.getChildByName("nameTxt");
            //_icon.setTexture("");
            //_nameTxt.string = "";
            _tempView.setPosition(cc.p((j%3)*330 + 150, 120));
            _tempItem.addChild(_tempView);
        }
    },

    onEnter: function () {
        this._super();
    },

    onExit: function () {
        this._super();
    },

    onChange: function (sender) {
        var _file = this._flag ? ngc.hall.pngRes.exBtn2 : ngc.hall.pngRes.exBtn1;
        sender.loadTextureNormal(_file);
        sender.loadTexturePressed(_file);
        sender.loadTextureDisabled(_file);
        this._flag = !this._flag;
        this._exRecordUi.setVisible(this._flag);
        this._itemListView.setVisible(!this._flag);
    },

    onClose: function () {
        this.mySetVisibleFalse();
    }
});
