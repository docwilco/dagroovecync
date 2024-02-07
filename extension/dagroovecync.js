const delay = (time) => new Promise(resolve => setTimeout(resolve, time));

const setCopyIcon = () => chrome.action.setIcon({
    path: {
        16: "icons/copy-16.png",
        19: "icons/copy-19.png",
        32: "icons/copy-32.png",
        38: "icons/copy-38.png",
    }
});

const setRegularIcon = () => chrome.action.setIcon({
    path: {
        16: "icons/button-16.png",
        19: "icons/button-19.png",
        32: "icons/button-32.png",
        38: "icons/button-38.png",
    }
});

const setFailedIcon = () => chrome.action.setIcon({
    path: {
        16: "icons/failed-16.png",
        19: "icons/failed-19.png",
        32: "icons/failed-32.png",
        38: "icons/failed-38.png",
    }
});

chrome.action.onClicked.addListener(async (tab) => {
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
    try {
        let results = await chrome.scripting.executeScript({ target: { tabId: tab.id }, files: [`/content_scripts/${file}`] });
        console.log("script done");
        console.log(results);
        // results[0] is the result of the first script and we only have one script
        // Chrome doesn't seem to fill the error field, but doesn't hurt to leave this
        if (results[0].error !== undefined) {
            throw new Error(results[0].error.message);
        } else if (results[0].result !== null && results[0].result.startsWith("error: ")) {
            // remove the "error: " prefix
            throw new Error(results[0].result.slice(7));
        }
        await setCopyIcon(tab.id);
        await delay(500);
        await setRegularIcon(tab.id);
    } catch (error) {
        console.error(`Failed to execute ${file} content script: ${error.message}`);
        await setFailedIcon(tab.id);
        await delay(500);
        await setRegularIcon(tab.id);
    }
});

chrome.runtime.onInstalled.addListener(() => {
    // Disable by default
    chrome.action.disable();

    // Enable on supported sites
    chrome.declarativeContent.onPageChanged.removeRules(undefined, () => {
        chrome.declarativeContent.onPageChanged.addRules([{
            conditions: [
                new chrome.declarativeContent.PageStateMatcher({
                    pageUrl: { hostSuffix: 'youtube.com', pathPrefix: '/watch' },
                }),
                new chrome.declarativeContent.PageStateMatcher({
                    pageUrl: { hostEquals: 'music.youtube.com' },
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
            actions: [new chrome.declarativeContent.ShowAction()]
        }]);
    });
});
