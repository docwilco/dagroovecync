const delay = time => result => new Promise(resolve => setTimeout(resolve, time, result));

const setCopyIcon = (id) => () => browser.pageAction.setIcon({
    tabId: id,
    path: {
        16: "icons/copy-16.png",
        19: "icons/copy-19.png",
        32: "icons/copy-32.png",
        38: "icons/copy-38.png",
    }
});

const setRegularIcon = id => () => browser.pageAction.setIcon({
    tabId: id,
    path: {
        16: "icons/button-16.png",
        19: "icons/button-19.png",
        32: "icons/button-32.png",
        38: "icons/button-38.png",
    }
});

const setFailedIcon = (id, file) => error => {
    console.error(`Failed to execute ${file} content script: ${error.message}`);
    browser.pageAction.setIcon({
        tabId: id,
        path: {
            16: "icons/failed-16.png",
            19: "icons/failed-19.png",
            32: "icons/failed-32.png",
            38: "icons/failed-38.png",
        }
    })
};

browser.pageAction.onClicked.addListener((tab) => {
    var url = new URL(tab.url);
    var file;
    if (url.host.endsWith("youtube.com")) {
        file = "youtube_url.js";
    } else if (url.host.endsWith("twitch.tv")) {
        file = "twitch.js";
    } else if (url.host.endsWith("mixcloud.com")) {
        file = "mixcloud_url.js";
    } else if (url.host.endsWith("soundcloud.com")) {
        file = "soundcloud_url.js";
    } else {
        throw new Error('internal error: unknown site');
    }
    browser.tabs
        .executeScript(tab.id, { file: `/content_scripts/${file}` })
        .then(result => {
            /*
             * Since Chrome is unable to throw errors from the content script to here,
             * the scripts just try/catch and return an appropriate string. Here we
             * throw an error if the returned string was not "success" so .then() makes
             * the right choice.
             */
            if (result[0] !== "success") {
                throw new Error(result[0]);
            }
        })
        .then(setCopyIcon(tab.id), setFailedIcon(tab.id, file))
        .then(delay(500))
        .then(setRegularIcon(tab.id));
});

if (chrome.declarativeContent !== undefined) {
    chrome.runtime.onInstalled.addListener(function() {
        chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
            chrome.declarativeContent.onPageChanged.addRules([{
                conditions: [
                    new chrome.declarativeContent.PageStateMatcher({
                        pageUrl: { hostSuffix: 'youtube.com', pathPrefix: '/watch' },
                    }),
                    new chrome.declarativeContent.PageStateMatcher({
                        pageUrl: { hostSuffix: 'twitch.tv', pathPrefix: '/videos' },
                    }),
                    new chrome.declarativeContent.PageStateMatcher({
                        pageUrl: { hostSuffix: 'soundcloud.com' },
                    }),
                    new chrome.declarativeContent.PageStateMatcher({
                        pageUrl: { hostSuffix: 'mixcloud.com' },
                    })
                ],
                actions: [new chrome.declarativeContent.ShowPageAction()]
            }]);
        });
    });
}