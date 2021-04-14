(function() {
    try {
        var htmlVideoPlayer = document.getElementsByTagName('video')[0];
        if (htmlVideoPlayer === undefined) {
            throw new Error("no video player");
        }
        var url = new URL(htmlVideoPlayer.baseURI);
        /*
         * get rid of query string, since that can have a timing parameter (t) 
         */
        url.search = "";

        var now = Math.round(Date.now() / 1000);
        /*
         * `zero` is the time the user would have to have hit play to get
         * to the current time in the video right now, if they hadn't scrubbed
         * through the video at all.
         */
        var zero = now - Math.round(htmlVideoPlayer.currentTime);

        if ((url.host == "twitch.tv" || url.host == "www.twitch.tv") && url.pathname.startsWith("/videos")) {
            zero %= 1000000;
            /* slice(7) to chop off /videos */
            url = "https://dgc.drwil.co/v2/" + zero + "/twitch" + url.pathname.slice(7);
        } else {
            return `error: URL does not start with (www.)twitch.tv/videos`;
        }
        navigator.clipboard.writeText(url);
        /*
         * Chrome is unable to throw an error from here to the caller of executeScript,
         * so we try/catch and return an appropriate string
         */
        return "success";
    } catch (error) {
        return `error: ${error.message}`;
    }
})();