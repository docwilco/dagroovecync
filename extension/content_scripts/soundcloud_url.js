(function() {
    try {
        var titleLink = document.getElementsByClassName("playbackSoundBadge__titleLink")[0];
        if (titleLink === undefined) {
            throw new Error("unable to find titleLink");
        }
        var url = new URL(titleLink.href, document.URL);

        var now = Math.round(Date.now() / 1000);
        /*
         * `zero` is the time the user would have to have hit play to get
         * to the current time in the audio right now, if they hadn't scrubbed
         * through the audio at all.
         */
        var timePassed = document.getElementsByClassName("playbackTimeline__timePassed")[0];
        if (timePassed === undefined) {
            throw new Error("unable to find timePassed");
        }
        var current = timePassed.children[1].innerHTML;
        var currentSecs = 0;
        current.split(":").forEach(n => {
            currentSecs *= 60;
            currentSecs += parseInt(n);
        });
        var zero = now - Math.round(currentSecs);

        url = "https://dgc.drwil.co/v1/" + zero + "/" + encodeURIComponent(url.toString().split('#')[0]);
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