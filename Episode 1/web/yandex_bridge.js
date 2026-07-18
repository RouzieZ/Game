// Safe optional bridge for Yandex Games.
// Include this file from the custom HTML template after the Yandex Games SDK script.
window.pzYandexBridge = {
  ysdk: null,
  player: null,

  async init() {
    if (!window.YaGames || this.ysdk) {
      return Boolean(this.ysdk);
    }

    this.ysdk = await window.YaGames.init();

    try {
      this.player = await this.ysdk.getPlayer({ scopes: false });
    } catch (error) {
      console.warn("Yandex player is unavailable, local fallback will be used.", error);
    }

    return true;
  },

  gameReady() {
    if (this.ysdk && this.ysdk.features && this.ysdk.features.LoadingAPI) {
      this.ysdk.features.LoadingAPI.ready();
    }
  },

  gameplayStart() {
    if (this.ysdk && this.ysdk.features && this.ysdk.features.GameplayAPI) {
      this.ysdk.features.GameplayAPI.start();
    }
  },

  gameplayStop() {
    if (this.ysdk && this.ysdk.features && this.ysdk.features.GameplayAPI) {
      this.ysdk.features.GameplayAPI.stop();
    }
  },

  showFullscreenAd() {
    if (this.ysdk && this.ysdk.adv) {
      this.ysdk.adv.showFullscreenAdv({});
    }
  },

  showRewardedAd() {
    if (this.ysdk && this.ysdk.adv) {
      this.ysdk.adv.showRewardedVideo({});
    }
  },

  async saveData(data) {
    if (!this.player) {
      return false;
    }

    await this.player.setData(data, true);
    return true;
  },

  async requestData() {
    if (!this.player) {
      return null;
    }

    return await this.player.getData();
  }
};
