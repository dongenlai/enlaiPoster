/**
 * @module ngccAudioJsb
 */
var ngcc = ngcc || {};

/**
 * @class CNgcAudio
 */
ngcc.CNgcAudio = cc.Class.extend({

    ctor: function () {

    },

    /**
     * @method update
     */
    update: function () {
    },

    /**
     * @method setPaused
     * @param {int} arg0
     */
    setPaused: function (int) {
        if (0 === int) {
            cc.audioEngine.resumeMusic();
        } else {
            cc.audioEngine.pauseMusic();
        }
    },

    /**
     * @method playBackMusic
     * @param {String} arg0
     * @return {int}
     */
    playBackMusic: function (str) {
        cc.audioEngine.playMusic(str, true);
        return 0;
    },

    /**
     * @method playGameSound
     * @param {String} arg0
     * @return {int}
     */
    playGameSound: function (str) {
        cc.audioEngine.playEffect(str, false);
        return 0;
    },

    /**
     * @method setVolumeBackMusic
     * @param {float} arg0
     * @return {int}
     */
    setVolumeBackMusic: function (float) {
        cc.audioEngine.setMusicVolume(float);
        return 0;
    },

    /**
     * @method setVolumeVoice
     * @param {float} arg0
     * @return {int}
     */
    setVolumeVoice: function (float) {
        cc.audioEngine.setEffectsVolume(float);
        return 0;
    },

    /**
     * @method setVolumeGame
     * @param {float} arg0
     * @return {int}
     */
    setVolumeGame: function (float) {
        cc.audioEngine.setEffectsVolume(float);
        return 0;
    },

    /**
     * @method mayRecord
     * @return {int}
     */
    mayRecord: function () {
        return 0;
    },

    /**
     * @method isRecording
     * @return {int}
     */
    isRecording: function () {
        return 0;
    },

    /**
     * @method startRecord
     * @return {int}
     */
    startRecord: function () {
        return 0;
    },

    /**
     * @method endRecord
     * @return {String}
     */
    endRecord: function () {
        return "";
    },

    /**
     * @method playVoice
     * @param {String} arg0
     * @return {int}
     */
    playVoice: function (str) {
        return 0;
    },

    /**
     * @method cacheGameSound
     * @param {String} arg0
     * @return {int}
     */
    cacheGameSound: function (str) {
        return 0;
    },

    /**
     * @method removeGameSound
     * @param {String} arg0
     * @return {int}
     */
    removeGameSound: function (str) {
        return 0;
    },

    /**
     * @method removeBackMusic
     * @return {int}
     */
    removeBackMusic: function () {
        cc.audioEngine.stopMusic(true);
        return 0;
    }

});
