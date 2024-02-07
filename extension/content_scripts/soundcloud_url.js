(async function () {
    // Chrome still can't do error throwing from content scripts, so we need to
    // wrap the whole thing in a try/catch block.
    try {
        // Windows doesn't really do accurate clocks, so we need to snag the time first
        let now = await fetch("https://dgc.drwil.co/v2/now")
            .then(response => response.json())
            .then(json => json.now);

        let titleLink = document.getElementsByClassName("playbackSoundBadge__titleLink")[0];
        if (titleLink === undefined) {
            throw new Error("unable to find titleLink");
        }
        let url = new URL(titleLink.href, document.URL);
        /*
         * `zero` is the time the user would have to have hit play to get
         * to the current time in the audio right now, if they hadn't scrubbed
         * through the audio at all.
         */
        let timePassed = document.getElementsByClassName("playbackTimeline__timePassed")[0];
        if (timePassed === undefined) {
            throw new Error("unable to find timePassed");
        }
        let current = timePassed.children[1].innerHTML;
        let currentSecs = 0;
        current.split(":").forEach(n => {
            currentSecs *= 60;
            currentSecs += parseInt(n);
        });
        let zero = now - Math.round(currentSecs);

        if (url.host == "soundcloud.com") {
            zero %= 1000000;
            url = "https://dgc.drwil.co/v2/" + zero + "/soundcloud" + url.pathname;
        } else {
            url = "https://dgc.drwil.co/v1/" + zero + "/" + encodeURIComponent(url.toString().split('#')[0]);
        }

        navigator.clipboard.writeText(url);
    } catch (error) {
        return "error: " + error.message;
    }
})();