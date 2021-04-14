(function() {
    try {
        var htmlVideoPlayer = document.getElementsByTagName('video')[0];
        if (htmlVideoPlayer === undefined) {
            throw new Error("no video player");
        }
        var url = new URL(htmlVideoPlayer.baseURI);
        /*
         * Both the t parameter and the playlist parameters interfere with
         * what we're trying to do, so removing everything except the v
         * parameter.
         */
        var params = new URLSearchParams(url.search);
        var vid = params.get('v')

        var now = Math.round(Date.now() / 1000);
        /*
         * `zero` is the time the user would have to have hit play to get
         * to the current time in the video right now, if they hadn't scrubbed
         * through the video at all.
         */
        var zero = now - Math.round(htmlVideoPlayer.currentTime);

        if (url.host == "www.youtube.com" && url.pathname == "/watch") {
            zero %= 1000000;
            url = "https://dgc.drwil.co/v2/" + zero + "/youtube?v=" + vid;
        } else {
            url = "https://dgc.drwil.co/v1/" + zero + "/" + encodeURIComponent(url.toString().split('#')[0]);
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