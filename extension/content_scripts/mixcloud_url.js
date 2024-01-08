(async function () {
    // Windows doesn't really do accurate clocks, so we need to snag the time first
    let now = await fetch("https://dgc.drwil.co/v2/now")
        .then(response => response.json())
        .then(json => json.now);

    let htmlAudioPlayer = document.getElementsByTagName('audio')[0];

    // Use an Attribute Selector to find this, because the class name has random ids in it
    let playerContainer = document.querySelectorAll('[class*="PlayerContainer"]')[0];
    let showDetails = playerContainer.querySelectorAll('[class*="ShowDetails"]')[0];
    let plainLink = document.querySelectorAll('[class*="PlainLink"]')[0];
    if (plainLink === undefined) {
        throw new Error("unable to find plainLink");
    }
    let url = new URL(plainLink.href, document.URL);
    /*
     * `zero` is the time the user would have to have hit play to get
     * to the current time in the video right now, if they hadn't scrubbed
     * through the video at all.
     */
    let zero = now - Math.round(htmlAudioPlayer.currentTime);

    if (url.host == "www.mixcloud.com") {
        zero %= 1000000;
        url = "https://dgc.drwil.co/v2/" + zero + "/mixcloud" + url.pathname;
    } else {
        url = "https://dgc.drwil.co/v1/" + zero + "/" + encodeURIComponent(url.toString().split('#')[0]);
    }

    navigator.clipboard.writeText(url);
})();