(function() {
    var url = new URL(
        document.getElementsByClassName("playbackSoundBadge__titleLink")[0].href,
        document.URL
    );

    var now = Math.round(Date.now() / 1000);
    /*
     * `zero` is the time the user would have to have hit play to get
     * to the current time in the audio right now, if they hadn't scrubbed
     * through the audio at all.
     */
    var current = document.getElementsByClassName("playbackTimeline__timePassed")[0].children[1].innerHTML;
    var currentSecs = 0;
    current.split(":").forEach(n => {
        currentSecs *= 60;
        currentSecs += parseInt(n);
    });
    var zero = now - Math.round(currentSecs);

    url = "https://dgc.drwil.co/v1/" + zero + "/" + encodeURIComponent(url.toString().split('#')[0]);
    navigator.clipboard.writeText(url);
})();