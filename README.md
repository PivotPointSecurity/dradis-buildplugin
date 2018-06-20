# dradis-buildplugin
A bash script to run all the command needed to build and install a dradis plugin (like a new upload plugin, etc).

The easiest way to use it is to copy the script into the base directory of your plugin. Then edit the variable "plugin" to match your plugin.

Chmod +x build-plugin.sh

Then run it to build and install your plugin into dradis.

---
It runs rake build

Then copies the gem from ./pkg to addons/cache

It adds/updates the gem in the Gemfile.plugins file

Removes the old version from vendor/cache

Symlinks the new version to vendor/cache

Does a bundle install (or bundle install --local)

Then god restart dradispro-unicorn