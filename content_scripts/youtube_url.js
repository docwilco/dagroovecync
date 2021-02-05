(function() {
    var htmlVideoPlayer = document.getElementsByTagName('video')[0];
    url = new URL(htmlVideoPlayer.baseURI);
    params = new URLSearchParams(url.search);
    /*
     * sometimes YouTube URLs have a `t` query string parameter, which
     * can interfere with what we're trying to do. Get rid of it.
     */
    params.delete('t')
    url = new URL("?" + params.toString(), url);

    now = Math.round(Date.now() / 1000);
    /*
     * `zero` is the time the user would have to have hit play to get
     * to the current time in the video right now, if they hadn't scrubbed
     * through the video at all.
     */
    zero = now - Math.round(htmlVideoPlayer.currentTime);

    url = "https://dgc.drwil.co/v1/" + zero + "/" + encodeURIComponent(url.toString().split('#')[0]);
    navigator.clipboard.writeText(url);
})();