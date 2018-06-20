#!/bin/bash

# Only items to change, the plugin name (also the directory name)
plugin="dradis-yournamehere"

# Path to Plugin: Generally should be the path below
pluginpath="/opt/dradispro/dradispro/current/tmp/$plugin"

# Path to dradis: you should have a shared folder and a symlink for current
dradispath="/opt/dradispro/dradispro"



# Don't monkey with things past here.
buildlocal=0
shopt -s nocasematch
if [ "$plugin" = "dradis-yournamehere" ]; then
	echo "You really need to set your plugin (directory) name in the script."
	echo ""
	exit
fi


if [[ "$#" -eq 1 && "$1" = "local" ]]; then
	buildlocal=1
elif [[ "$#" -eq 1 && "$1" =~ [h\?] ]]; then
	echo "The only argument accepted is 'local', which will be used in bundle install --local"
	echo ""
	exit
fi

echo "Building the $plugin plugin."


base="$dradispath/current"
addons="$dradispath/shared/addons/cache"
cd "$pluginpath"
rakeout=`rake build`

echo "Package built: $rakeout"

version=$(echo $rakeout | awk '{print $2}')
filebase=$(echo $rakeout | awk '{print $1}')
filename="$filebase-$version.gem"

echo "Moving $filename"

copied=`cp pkg/$filename $addons/`

cd $base

oldversion=`cat $base/Gemfile.plugins | grep $plugin | sed -En "s/(.*)','(.*)'/\2/p"`

if [ -z $oldversion ]; then
  echo "Adding $plugin version $version"
  echo "gem '$plugin','$version'" >> $base/Gemfile.plugins
else
  echo "Replacing version $oldversion with $version"
  updategemplugin=`sed -i s/\'$plugin\'\,\'$oldversion\'/\'$plugin\'\,\'$version\'/ Gemfile.plugins`
fi

cd "$base/vendor/cache/"

rm -f $plugin*

ln -s $addons/$filename

cd $base
if [ "$buildlocal" == "1" ]; then
	bundle install --local
else
	bundle install
fi

god restart dradispro-unicorn

