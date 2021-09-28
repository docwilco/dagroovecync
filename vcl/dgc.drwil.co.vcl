sub vcl_recv {
  declare local var.time INTEGER;
  declare local var.site STRING;
  declare local var.path STRING;
  declare local var.location STRING;
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
      set var.location = "https://soundcloud.com" + var.path + "#t=" + var.time;
      error 302 var.location;
    } else if (var.site == "mixcloud") {
      set req.http.time = var.time;
      error 200 var.path;
    } else if (var.site == "youtube") {
      set var.location = "https://www.youtube.com/watch?" + req.url.qs + "#t=" + var.time;
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
  if (req.url.path ~ "/v1/([0-9]+)/(.*)") {
    set var.time = now;
    set var.time -= std.atoi(re.group.1);
    # Usually takes at least a second to load stuff
    set var.time += 1;
    set var.location = urldecode(re.group.2);
    if (var.location ~ "^https://www.mixcloud.com(/.*)$") {
      set req.http.time = var.time;
      error 200 re.group.1;
    }
    set var.location = var.location + "#t=" + var.time;
    error 302 var.location;
  }
  if (req.url.path ~ "/") {
    error 302 "https://github.com/docwilco/dagroovecync";
  }
  error 404;
  #FASTLY recv
}

sub vcl_error {
  if (obj.status == 302) {
    set obj.http.location = obj.response;
    set obj.response = "Found";
    return(deliver);
  }
  if (obj.status == 200) {
    declare local var.url STRING;
    declare local var.iframe STRING;
    set var.url = obj.response;
    set obj.response = "OK";
    # Classic widget is 120px height, Picture widget is 400px, but switches
    # to a < 200px player that's more elaborate than Picture. Autoplay skips
    # the cover pic, so use 200px to get the elaborate player. 
    set var.iframe = {"<iframe id="my-widget-iframe" width="100%" height="200" src="https://www.mixcloud.com/widget/iframe/?autoplay=1&feed="} + urlencode(var.url) + {"" frameborder="0" allow="autoplay"></iframe>"};
    synthetic {"
<html>
<head>
<title>DaGrooveSync - MixCloud Workaround</title>
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
<p>Since MixCloud does not have any way to link to mixes on their site with a start time, like YouTube and SoundCloud do,
an embedded player will have to suffice for now. Please let me know if this has changed!</p>
<br>

<hr>

<script src="https://code.jquery.com/jquery-3.6.0.min.js" type="text/javascript"></script>
<script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" type="text/javascript"></script>
<script src="https://kit.fontawesome.com/287885ebad.js" type="text/javascript"></script>

<script src="https://widget.mixcloud.com/media/js/widgetApi.js" type="text/javascript"></script>
"} + var.iframe + {"
<!-- volume control based on https://codepen.io/emilcarlsson/pen/PPNLPy -->
<div id="volume-control">
  <i class="fa fa-volume-down"></i>
  <div id="volume"></div>
  <i class="fa fa-volume-up"></i>
</div>

<hr>

<p>Remember to allow auto-play if your browser has the capability. If it doesn't, hitting play and then reloading the page might work.</p>
<script type="text/javascript">
    var widget = Mixcloud.PlayerWidget(document.getElementById("my-widget-iframe"));
    widget.ready.then(function() {
        widget.seek("} + req.http.time + {");
        widget.setVolume(0.5);
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
"};
    return(deliver);
  }
  #FASTLY error
}