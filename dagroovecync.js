browser.pageAction.onClicked.addListener((tab) => {
    url = new URL(tab.url);
    if (url.host.endsWith("youtube.com")) {
        browser.tabs
            .executeScript(tab.id, { file: "/content_scripts/youtube_url.js" })
            .catch((error) => {
                console.error(`Failed to execute youtube_url.js content script: ${error.message}`);
            });
    } else if (url.host.endsWith("mixcloud.com")) {
        browser.tabs
            .executeScript(tab.id, { file: "/content_scripts/mixcloud_url.js" })
            .catch((error) => {
                console.error(`Failed to execute mixcloud_url.js content script: ${error.message}`);
            });
    } else if (url.host.endsWith("soundcloud.com")) {
        browser.tabs
            .executeScript(tab.id, { file: "/content_scripts/soundcloud_url.js" })
            .catch((error) => {
                console.error(`Failed to execute soundcloud_url.js content script: ${error.message}`);
            });
    }
});