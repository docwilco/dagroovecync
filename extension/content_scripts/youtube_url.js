(function() {
    try {
        var vid;
        var docurl = new URL(document.URL);
        // YT Music and regular YouTube both use <video> elements
        var htmlVideoPlayer = document.getElementsByTagName('video')[0];
        if (htmlVideoPlayer === undefined) {
            throw new Error("no video player");
        }
        if (docurl.host == "music.youtube.com") {
            // YT Music doesn't always have the "video" (track) ID in the
            // URL bar, we need to get track URL from an element that has
            // these two classes. Try both for resilience.
            var elements = Array.from(document.getElementsByClassName('ytp-title-link'));
            elements = elements.concat(Array.from(document.getElementsByClassName('yt-uix-sessionlink')));
            for (element of elements) {
                try {
                    var titleurl = new URL(element.href);
                    console.log(`url: ${url}`);
                    var params = new URLSearchParams(titleurl.search);
                    vid = params.get('v');
                    break;
                } catch {}
            }
        } else {
            /*
             * Both the t parameter and the playlist parameters interfere with
             * what we're trying to do, so removing everything except the v
             * parameter.
             */
            var params = new URLSearchParams(docurl.search);
            vid = params.get('v');
        }

        var now = Math.round(Date.now() / 1000);
        /*
         * `zero` is the time the user would have to have hit play to get
         * to the current time in the video right now, if they hadn't scrubbed
         * through the video at all.
         */
        var zero = now - Math.round(htmlVideoPlayer.currentTime);
        zero %= 1000000;

        console.log(`zero: ${zero}  vid: ${vid} url: ${url}`);
        var url;
        /*
         * Don't look for /watch path on YT music, because the user can be browsing
         * all sorts of parts of the site while listening, and the URL will reflect
         * what they're looking at, not what they're listening to.
         */
        if (docurl.host == "music.youtube.com") {
            url = "https://dgc.drwil.co/v2/" + zero + "/ytmusic?v=" + vid;
        } else if (docurl.host == "www.youtube.com" && docurl.pathname == "/watch") {
            url = "https://dgc.drwil.co/v2/" + zero + "/youtube?v=" + vid;
        } else {
            return "error: could not find a \"video\" id";
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