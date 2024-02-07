# DaGrooveCync

Ever want to listen to a mix on the internet with a friend, and keep having to do things like "OK, hit play in 5
4
3" or "What timestamp are you at?"?

Then this plugin is for you!

For YouTube, Twitch, MixCloud, and SoundCloud, a button will show up in the URL bar, which will create a URL and put it in your clipboard. You can then paste this URL to your friend and they will get redirected in such a way that they will sync up with you. Well, give or take a second or two, depending on how long the page takes for them to load.

Note: make sure your clock is synced! If your clock is off, it will affect how well your friends will sync up.
Note 2: Currently MixCloud isn't quite working yet, because they don't support having a timestamp in the URL, but I hope to fix that by serving a page with a widget in the near future.

How it works: when you hit the button, the URL of the currently playing video/audio is extracted, along with the current timestamp. The plugin then calculates a "zero" time by subtracting the current timestamp from the current time according to your clock. That zero time and the URL are encoded into the URL you can share. When someone clicks on the URL, the server will subtract the zero time from the current time, and append to the URL the difference so that the music will start playing at that offset.

# Installing

## From browser marketplaces

### Firefox
https://addons.mozilla.org/firefox/addon/dagroovecync/

### Chrome
https://chrome.google.com/webstore/detail/dagroovecync/inkjphjnkcigofagibfjfnhilnklgemj

## Manually

### Firefox
Download the latest XPI from https://github.com/docwilco/dagroovecync/releases, then go to `about:debugging`, click This Firefox and add as a temporary plugin.

### Chrome
Downloud the latest source from https://github.com/docwilco/dagroovecync/releases, unpack and use "load unpacked" under "manage extensions".

# Building

Throw everything under `extension` into zip file and change the extension from `zip` to `xpi`. For Chrome, check out the `chrome` branch.

# Credits

Thanks Martijn Bogaard for the icons, motivation and ideas!

# Changelog

## 1.0.1-chrome 2024-02-07

* Adjust things to make Chrome happy
* Fix MixCloud support for real this time

## 1.0.0 2024-01-07

* Update Browser Extension Polyfill
* Update Manifest to V3

## 0.1.12 - 2024-01-05

* Fix MixCloud support
