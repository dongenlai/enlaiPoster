var g_reloadJsArray = [
    "src/c/ngc.js",
    "src/c/PubUtils.js",
    "src/c/BaseClass.js",
    "src/c/audio.js",
    "src/c/netPack.js",
    "src/c/layerNet.js",
    "src/c/Math.uuid.js",
    "src/l/sceneLoader.js",
    "src/h/resource.js",
    "src/h/loadGame.js",
    "src/h/sceneMain.js"
];

cc.game.onStart = function(){
    if(!cc.sys.isNative && document.getElementById("cocosLoading")) //If referenced loading.js, please remove it
        document.body.removeChild(document.getElementById("cocosLoading"));

    // Pass true to enable retina display, on Android disabled by default to improve performance
    cc.view.enableRetina(cc.sys.os === cc.sys.OS_IOS ? true : false);
    // Adjust viewport meta
    cc.view.adjustViewPort(true);
    // Setup the resolution policy and design resolution size
    cc.view.setDesignResolutionSize(1334, 750, cc.ResolutionPolicy.SHOW_ALL);
    // Instead of set design resolution, you can also set the real pixel resolution size
    // Uncomment the following line and delete the previous line.
    // cc.view.setRealPixelResolution(960, 640, cc.ResolutionPolicy.SHOW_ALL);
    // The game will be resized when browser size change
    cc.view.resizeWithBrowserSize(true);
    //load resources
    cc.loader.loadJs(g_reloadJsArray, function(err) {
        if(err)
            console.log("loadJs: " + err);

        if(!cc.sys.isNative){
            cc.loader.load(ngc.loader.resources,
                function (result, count, loadedCount){
                },
                function () {
                    ngc.loader.startLoading();
                });
        } else {
            ngc.loader.startLoading();
        }
    });
};
cc.game.run();