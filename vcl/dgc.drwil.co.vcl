sub vcl_recv {
  declare local var.time INTEGER;
  declare local var.site STRING;
  declare local var.path STRING;
  declare local var.location STRING;
  if (req.url.path == "/v2/now") {
    set var.time = now;
    error 700 var.time;
  }
  if (req.url.path ~ "/v2/([0-9]{1,6})/([^/]+)(/.*)?$") {
    set var.site = re.group.2;
    set var.path = re.group.3;
    # 6 digits covers 278ish hours, so that should be plenty.
    set var.time = now;
    set var.time -= std.atoi(re.group.1);
    # Usually takes at least a second to load stuff
    set var.time += 1;
    set var.time %= 1000000;
    if (var.site == "soundcloud") {
      set req.http.time = var.time;
      error 702 var.path;
    } else if (var.site == "mixcloud") {
      set req.http.time = var.time;
      error 701 var.path;
    } else if (var.site == "youtube") {
      set var.location = "https://www.youtube.com/watch?" + req.url.qs + "&t=" + var.time;
      error 302 var.location;
    } else if (var.site == "ytmusic") {
      set var.location = "https://music.youtube.com/watch?" + req.url.qs + "&t=" + var.time;
      error 302 var.location;
    } else if (var.site == "twitch") {
      declare local var.hours INTEGER;
      declare local var.minutes INTEGER;
      declare local var.seconds INTEGER;
      set var.hours = var.time;
      set var.hours /= 3600;
      set var.minutes = var.time;
      set var.minutes %= 3600;
      set var.minutes /= 60;
      set var.seconds = var.time;
      set var.seconds %= 60;
      set var.location = "https://www.twitch.tv/videos" + var.path + "?t="
                         + var.hours + "h" + var.minutes + "m" + var.seconds + "s"; 
      error 302 var.location;
    }
  }
  if (req.url.path ~ "/") {
    error 302 "https://github.com/docwilco/dagroovecync";
  }
  error 404;
  #FASTLY recv
}

sub vcl_error {
  declare local var.url STRING;

  if (obj.status == 700) {
    set obj.status = 200;
    set obj.http.Content-Type = "application/json";
    set obj.http.Access-Control-Allow-Origin = "*";
    synthetic {"{"now":"} + obj.response {"}
"};
    return(deliver);
  }
  if (obj.status == 302) {
    set obj.http.location = obj.response;
    set obj.response = "Found";
    return(deliver);
  }

  # MixCloud workaround
  if (obj.status == 701) {
    declare local var.iframe STRING;
    set var.url = obj.response;
    set obj.response = "OK";
    set obj.status = 200;

    synthetic {"
<html>
    <head>
        <title>DaGrooveSync - MixCloud Workaround</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta charset="utf-8">
        <style>
  body {
    background: #333;
    font-family: Verdana, Arial, Helvetica, sans-serif;
  }

  h3 {
    text-align: center;
    font-size: 24px;
    padding-top: 20px;
    color: #fff;
  }

  p {
    color: #ddd;
    text-align: center;
    font-size: 15px;
  }

  a {
    color: #52e992;
  }

  #volume-control {
    width: 350px;
    height: 50px;
    position: relative;
    margin: 0 auto;
    top: 10px;
  }
  #volume-control i {
    position: absolute;
    margin-top: -6px;
    color: #666;
  }
  #volume-control i.fa-volume-down {
    margin-left: -8px;
  }
  #volume-control i.fa-volume-up {
    margin-right: -8px;
    right: 0;
  }

  #volume {
    position: absolute;
    left: 24px;
    margin: 0 auto;
    height: 5px;
    width: 300px;
    background: #555;
    border-radius: 15px;
  }
  #volume .ui-slider-range-min {
    height: 5px;
    width: 300px;
    position: absolute;
    background: #909090;
    border: none;
    border-radius: 10px;
    outline: none;
  }
  #volume .ui-slider-handle {
    width: 20px;
    height: 20px;
    border-radius: 20px;
    background: #fff;
    position: absolute;
    margin-left: -8px;
    margin-top: -8px;
    cursor: pointer;
    outline: none;
  }
        </style>
    </head>
    <body>
        <h3>DaGrooveCync workaround player</h3>
        <p>
            Since MixCloud does not have any way to link to mixes on their site with a start time, like YouTube does,
an embedded player will have to suffice for now. Please let me know if this has changed!
        </p>
        <br>
        <hr>
        <script src="https://code.jquery.com/jquery-3.6.0.min.js" type="text/javascript"></script>
        <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" type="text/javascript"></script>
        <script src="https://kit.fontawesome.com/287885ebad.js" type="text/javascript"></script>
        <script src="https://widget.mixcloud.com/media/js/widgetApi.js" type="text/javascript"></script>
        <iframe
            id="my-widget-iframe"
            width="100%"
            height="250"
            src="https://www.mixcloud.com/widget/iframe/?autoplay=1&feed="} + urlencode(var.url) + {""
            frameborder="0"
            allow="autoplay"
        ></iframe>
        <!-- volume control based on https://codepen.io/emilcarlsson/pen/PPNLPy -->
        <div id="volume-control">
            <i class="fa fa-volume-down"></i>
            <div id="volume"></div>
            <i class="fa fa-volume-up"></i>
        </div>
        <hr>
        <p id="autoplay-text">
            Hit Play if Autoplay is blocked.
        </p>
        <p>
            Don't worry, if Autoplay was blocked and you manually hit Play, the player should still seek to the correct time.
        </p>
        <p>
            Remember to allow Autoplay if your browser has that capability.
        </p>
        <p>
            For instance in Firefox, set Autoplay to "Allow Audio and Video". You can find this setting in the URL bar under the settings button next to the lock icon.
        </p>
        <p>
            In Chrome just hit Play if it's not playing and after a couple of times of listening to music that way, Autoplay should start to work automatically.
            Do not reload to speed this process up, as you need to listen for a while before this works.
            See
            <a href="https://developer.chrome.com/blog/autoplay">this blog from Google</a>
            for more information.
        </p>
        <p>
            If you have manually paused the player and you want to sync back up with your friend, just reload this page.
        </p>
        <script type="text/javascript">
            function flashBackgroundWithFade(elementId, flashes, duration, flashColor) {
                const element = document.getElementById(elementId);
                if (!element) return;

                const originalColor = window.getComputedStyle(element).backgroundColor;

                // Create the keyframes dynamically
                const animationName = `flashFade_${Date.now()}`;
                const styleSheet = document.createElement('style');
                styleSheet.type = 'text/css';
                styleSheet.textContent = `
                    @keyframes ${animationName} {
                        0%, 100% { background-color: ${originalColor}; }
                        50% { background-color: ${flashColor}; }
                    }
                `;
                document.head.appendChild(styleSheet);

                // Apply the animation to the element
                element.style.animation = `${animationName} ${duration / 1000}s ease-in-out ${flashes}`;
                
                // Cleanup after the animation is done
                const totalDuration = flashes * duration;
                setTimeout(() => {
                    element.style.animation = ''; // Remove the animation
                    document.head.removeChild(styleSheet); // Clean up the dynamic style
                }, totalDuration);
            }

            // We let the CDN calculate this, as it has an accurate clock, and
            // the user might not. The CDN sets this in seconds.
            let seek_time = "} + req.http.time + {";
            // When autoplay is blocked, to resume at the right time after the
            // user hits play, we need to know the offset between loading the page
            // and when the user hits play. Then add to the seek time.
            let load_time = Date.now();
            let widget = Mixcloud.PlayerWidget(document.getElementById("my-widget-iframe"));
            widget.ready.then(function() {
                // Unlike SoundCloud, MixCloud does not emit a pause event if
                // the page is blocked from autoplaying. So just always seek
                // after Play is hit. For the blinking of the reminder to hit
                // Play, check if the player is paused after a second or two.
                function onPlay() {
                    // Only seek on Play once
                    widget.events.play.off(onPlay);
                    // Calculate new seek time based on the time it took to hit
                    // Play.
                    seek_time += (Date.now() - load_time) / 1000;
                    widget.seek(seek_time);
                }
                widget.events.play.on(onPlay);
                widget.setVolume(0.5);
                // Wait a second because paused is true immediately after ready,
                // even if Autoplay is not blocked.
                setTimeout(() => {
                    widget.getIsPaused().then(paused => {
                        if (paused) {
                            flashBackgroundWithFade('autoplay-text', 3, 1000, '#52e992');
                        }
                    });
                }, 1000);
            });
            $("#volume").slider({
                min: 0,
                max: 100,
                value: 50,
                    range: "min",
                slide: function(event, ui) {
                    widget.setVolume(ui.value / 100);
                }
            });
        </script>
    </body>
</html>

"};
    return(deliver);
  }

  # SoundCloud workaround
  if (obj.status == 702) {
    set var.url = obj.response;
    set obj.response = "OK";
    set obj.status = 200;

    synthetic {"
<html>
    <head>
        <title>DaGrooveSync - SoundCloud Workaround</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta charset="utf-8">
        <style>
  body {
    background: #333;
    font-family: Verdana, Arial, Helvetica, sans-serif;
  }

  h3 {
    text-align: center;
    font-size: 24px;
    padding-top: 20px;
    color: #fff;
  }

  p {
    color: #ddd;
    text-align: center;
    font-size: 15px;
  }

  a {
    color: #52e992;
  }

  #volume-control {
    width: 350px;
    height: 50px;
    position: relative;
    margin: 0 auto;
    top: 10px;
  }
  #volume-control i {
    position: absolute;
    margin-top: -6px;
    color: #666;
  }
  #volume-control i.fa-volume-down {
    margin-left: -8px;
  }
  #volume-control i.fa-volume-up {
    margin-right: -8px;
    right: 0;
  }

  #volume {
    position: absolute;
    left: 24px;
    margin: 0 auto;
    height: 5px;
    width: 300px;
    background: #555;
    border-radius: 15px;
  }
  #volume .ui-slider-range-min {
    height: 5px;
    width: 300px;
    position: absolute;
    background: #909090;
    border: none;
    border-radius: 10px;
    outline: none;
  }
  #volume .ui-slider-handle {
    width: 20px;
    height: 20px;
    border-radius: 20px;
    background: #fff;
    position: absolute;
    margin-left: -8px;
    margin-top: -8px;
    cursor: pointer;
    outline: none;
  }
        </style>
    </head>
    <body>
        <h3>DaGrooveCync workaround player</h3>
        <p>
            Since SoundCloud does not have any way to link to tracks on their site with a start time, like YouTube does,
an embedded player will have to suffice for now. Please let me know if this has changed!
        </p>
        <br>
        <hr>
        <div id="player"></div>
        <!-- volume control based on https://codepen.io/emilcarlsson/pen/PPNLPy -->
        <div id="volume-control">
            <i class="fa fa-volume-down"></i>
            <div id="volume"></div>
            <i class="fa fa-volume-up"></i>
        </div>
        <hr>
        <p id="autoplay-text">
            Hit Play if Autoplay is blocked.
        </p>
        <p>
            Don't worry, if Autoplay was blocked and you manually hit Play, the player should still seek to the correct time.
        </p>
        <p>
            Remember to allow Autoplay if your browser has that capability.
        </p>
        <p>
            For instance in Firefox, set Autoplay to "Allow Audio and Video". You can find this setting in the URL bar under the settings button next to the lock icon.
        </p>
        <p>
            In Chrome just hit Play if it's not playing and after a couple of times of listening to music that way, Autoplay should start to work automatically.
            Do not reload to speed this process up, as you need to listen for a while before this works.
            See
            <a href="https://developer.chrome.com/blog/autoplay">this blog from Google</a>
            for more information.
        </p>
        <p>
            If you have manually paused the player and you want to sync back up with your friend, just reload this page.
        </p>
        <script src="https://code.jquery.com/jquery-3.6.0.min.js" type="text/javascript"></script>
        <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" type="text/javascript"></script>
        <script src="https://kit.fontawesome.com/287885ebad.js" type="text/javascript"></script>
        <!-- This JS provides the Widget API to control the player -->
        <script src="https://w.soundcloud.com/player/api.js" type="text/javascript"></script>
        <script type="text/javascript">
            function flashBackgroundWithFade(elementId, flashes, duration, flashColor) {
                const element = document.getElementById(elementId);
                if (!element) return;

                const originalColor = window.getComputedStyle(element).backgroundColor;

                // Create the keyframes dynamically
                const animationName = `flashFade_${Date.now()}`;
                const styleSheet = document.createElement('style');
                styleSheet.type = 'text/css';
                styleSheet.textContent = `
                    @keyframes ${animationName} {
                        0%, 100% { background-color: ${originalColor}; }
                        50% { background-color: ${flashColor}; }
                    }
                `;
                document.head.appendChild(styleSheet);

                // Apply the animation to the element
                element.style.animation = `${animationName} ${duration / 1000}s ease-in-out ${flashes}`;
                
                // Cleanup after the animation is done
                const totalDuration = flashes * duration;
                setTimeout(() => {
                    element.style.animation = ''; // Remove the animation
                    document.head.removeChild(styleSheet); // Clean up the dynamic style
                }, totalDuration);
            }

            // We let the CDN calculate this, as it has an accurate clock, and
            // the user might not. The CDN sets this in seconds.
            let seek_time = "} + req.http.time + {" * 1000;
            // When autoplay is blocked, to resume at the right time after the
            // user hits play, we need to know the offset between loading the page
            // and when the user hits play. Then add to the seek time.
            let load_time = Date.now();
            let url = new URL(window.location.href);
            // Snip off the leading timestamp "directory"
            let path_components = url.pathname.split('/');
            // [0] is empty
            // [1] is 'v2'
            // [2] is the timestamp
            // [3] is 'soundcloud'
            // [4..] is the soundcloud URL path
            let soundcloud_path = path_components.slice(4).join('/');
            // Construct the SoundCloud URL for the track. Because of the join
            // above, it won't have the leading slash.
            let soundcloud_url = 'https://soundcloud.com/' + soundcloud_path;
            // Construct the oembed URL, so we can get the player URL. This is
            // the rest of the soundcloud API requires authentication. This does
            // not, and has all the info we need.
            let oembed_url = `https://soundcloud.com/oembed?format=json&url=${encodeURIComponent(soundcloud_url)}`;
            // Fetch the oembed data
            fetch(oembed_url)
                .then(response => response.json())
                .then(data => {
                    // The track URL is in the player URL query string in the
                    // HTML JSON field. We want to set other parameters, so we
                    // can't just use the player URL from the oembed data.
                    let parser = new DOMParser();
                    let embod_doc = parser.parseFromString(data.html, 'text/html');
                    let player_url = new URL(embod_doc.querySelector('iframe').src);
                    let track_url = player_url.searchParams.get('url');

                    // <Jester@CriticalRole> Technically... We could just use
                    // the player URL from the oembed data and override the
                    // params. But if they ever add a param we _don't_ want,
                    // then we would have to change this again.
                    let new_player_url = new URL('https://w.soundcloud.com/player/');
                    new_player_url.searchParams.set('url', track_url);
                    new_player_url.searchParams.set('color', '#52e992');
                    new_player_url.searchParams.set('auto_play', 'true');
                    new_player_url.searchParams.set('hide_related', 'false');
                    new_player_url.searchParams.set('show_comments', 'true');
                    new_player_url.searchParams.set('show_user', 'true');
                    new_player_url.searchParams.set('show_reposts', 'true');
                    new_player_url.searchParams.set('show_teaser', 'true');
                    new_player_url.searchParams.set('visual', 'true');
                    // Create the iframe
                    let iframe = document.createElement('iframe');
                    iframe.src = new_player_url;
                    iframe.width = '100%';
                    iframe.height = '200';
                    iframe.frameborder = 'no';
                    iframe.scrolling = 'no';
                    iframe.allow = 'autoplay';
                    // Add the iframe to the player div
                    document.getElementById('player').appendChild(iframe);
                    // Since we already have the iframe element, just pass that
                    // in directly.
                    let widget = SC.Widget(iframe);
                    // isPaused() doesn't work right off the bat to detect
                    // autoplay. It comes back false, even if autoplay is
                    // blocked by the browser. However it seems like PAUSE is
                    // fired immediately and first when autoplay is blocked, and
                    // PLAY is fired immediately and first when autoplay is
                    // allowed.
                    widget.bind(SC.Widget.Events.PLAY, function() {
                        widget.unbind(SC.Widget.Events.PLAY);
                        widget.unbind(SC.Widget.Events.PAUSE);
                    });
                    widget.bind(SC.Widget.Events.PAUSE, function() {
                        widget.unbind(SC.Widget.Events.PLAY);
                        widget.unbind(SC.Widget.Events.PAUSE);
                        flashBackgroundWithFade('autoplay-text', 3, 1000, '#52e992');
                        // If autoplay is blocked, we want to make sure to
                        // seek to the correct spot after the user has hit
                        // play.
                        widget.bind(SC.Widget.Events.PLAY, function() {
                            widget.unbind(SC.Widget.Events.PLAY);
                            let play_time = Date.now();
                            seek_time += play_time - load_time;
                            widget.seekTo(seek_time);
                        });
                    });
                    // Gotta wait for READY before we can do anything
                    widget.bind(SC.Widget.Events.READY, function() {
                        widget.seekTo(seek_time);
                        $("#volume").slider({
                            min: 0,
                            max: 100,
                            value: 50,
                            range: "min",
                            slide: function(event, ui) {
                                widget.setVolume(ui.value);
                            }
                        });
                        widget.setVolume(50);
                    });
                });
        </script>
    </body>
</html>
"};
    return(deliver);
  }
  #FASTLY error
}

sub vcl_deliver {
  set resp.http.VCL-Version = req.vcl.version;
  #FASTLY deliver
}
