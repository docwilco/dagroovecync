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
    } else if (var.site == "twitch") {
      set var.location = "https://www.twitch.tv/videos" + var.path + "?t=" + var.time + "s";
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
    set var.url = obj.response;
    set obj.response = "OK";
    synthetic {"
<html>
<head>
<title>DaGrooveSync - MixCloud Workaround</title>
<style>
body {
    background-color: #222;
    color: #e6e6e6;
    font: 75% Verdana, Arial, Helvetica, sans-serif;
}
</style>
</head>
<body>
<h3>DaGrooveCync workaround player</h3>
Since MixCloud does not have any way to link to mixes on their site with a start time, like YouTube and SoundCloud do,
an embedded player will have to suffice for now. Please let me know if this has changed!
<br>
<hr>
<script src="https://widget.mixcloud.com/media/js/widgetApi.js" type="text/javascript"></script>
<iframe id="my-widget-iframe" width="100%" height="120" src="https://www.mixcloud.com/widget/iframe/?hide_cover=1&autoplay=1&feed="} + urlencode(var.url) + {"" frameborder="0" allow="autoplay"></iframe>
<hr>
Remember to allow auto-play if your browser has the capability. If it doesn't, hitting play and then reloading the page might work.
<script type="text/javascript">
    var widget = Mixcloud.PlayerWidget(document.getElementById("my-widget-iframe"));
    widget.ready.then(function() {
        widget.seek("} + req.http.time + {");
    });
</script>
</body>
"};
    return(deliver);
  }
  #FASTLY error
}