(async function() {
    // Windows doesn't really do accurate clocks, so we need to snag the time first
    let now = await fetch("https://dgc.drwil.co/v2/now")
        .then(response => response.json())
        .then(json => json.now);

    let htmlVideoPlayer = document.getElementsByTagName('video')[0];
    if (htmlVideoPlayer === undefined) {
        throw new Error("no video player");
    }
    let url = new URL(htmlVideoPlayer.baseURI);
    /*
     * get rid of query string, since that can have a timing parameter (t) 
     */
    url.search = "";
    /*
     * `zero` is the time the user would have to have hit play to get
     * to the current time in the video right now, if they hadn't scrubbed
     * through the video at all.
     */
    let zero = now - Math.round(htmlVideoPlayer.currentTime);

    if ((url.host == "twitch.tv" || url.host == "www.twitch.tv") && url.pathname.startsWith("/videos")) {
        zero %= 1000000;
        /* slice(7) to chop off /videos */
        url = "https://dgc.drwil.co/v2/" + zero + "/twitch" + url.pathname.slice(7);
    } else {
        throw new Error("URL does not start with (www.)twitch.tv/videos");
    }
    navigator.clipboard.writeText(url);
})();