(function() {
    var htmlAudioPlayer = document.getElementsByTagName('audio')[0];

    var url = new URL(
        document.querySelectorAll('[class^="PlayerControls__PlainLink"]')[0].href,
        htmlAudioPlayer.baseURI
    );
    var now = Math.round(Date.now() / 1000);
    /*
     * `zero` is the time the user would have to have hit play to get
     * to the current time in the video right now, if they hadn't scrubbed
     * through the video at all.
     */
    var zero = now - Math.round(htmlAudioPlayer.currentTime);

    url = "https://dgc.drwil.co/v1/" + zero + "/" + encodeURIComponent(url.toString().split('#')[0]);
    navigator.clipboard.writeText(url);
})();