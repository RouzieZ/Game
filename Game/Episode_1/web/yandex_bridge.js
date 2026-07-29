// Optional Yandex Games bridge. The same bridge is embedded in the custom HTML shell.
window.pzYandexBridge = {
  ysdk: null,
  player: null,
  initPromise: null,
  readyRequested: false,
  gameplayActive: false,

  init() {
    if (this.initPromise) return this.initPromise;
    if (!window.YaGames) return Promise.resolve(false);

    this.initPromise = window.YaGames.init()
      .then(async (ysdk) => {
        this.ysdk = ysdk;
        try {
          this.player = await ysdk.getPlayer({ scopes: false });
        } catch (error) {
          console.warn("Yandex player is unavailable; local saves remain active.", error);
        }
        if (this.readyRequested) this.ysdk.features.LoadingAPI?.ready();
        if (this.gameplayActive) this.ysdk.features.GameplayAPI?.start();
        return true;
      })
      .catch((error) => {
        console.error("Yandex Games SDK initialization failed.", error);
        return false;
      });
    return this.initPromise;
  },

  gameReady() {
    this.readyRequested = true;
    if (this.ysdk) this.ysdk.features.LoadingAPI?.ready();
  },

  gameplayStart() {
    this.gameplayActive = true;
    if (this.ysdk) this.ysdk.features.GameplayAPI?.start();
  },

  gameplayStop() {
    this.gameplayActive = false;
    if (this.ysdk) this.ysdk.features.GameplayAPI?.stop();
  },

  showFullscreenAd() {
    if (!this.ysdk?.adv) return;
    this.gameplayStop();
    this.ysdk.adv.showFullscreenAdv({
      callbacks: { onClose: () => this.gameplayStart(), onError: () => this.gameplayStart() }
    });
  },

  showRewardedAd() {
    if (!this.ysdk?.adv) return;
    this.gameplayStop();
    this.ysdk.adv.showRewardedVideo({
      callbacks: { onClose: () => this.gameplayStart(), onError: () => this.gameplayStart() }
    });
  },

  async saveData(data) {
    if (!this.player) return false;
    await this.player.setData(data, true);
    return true;
  },

  async requestData() {
    if (!this.player) return null;
    return await this.player.getData();
  }
};
