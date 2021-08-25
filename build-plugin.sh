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

# Find gem_version.rb file
versionfile=`find . -name gem_version.rb`

# Get current version
cmajor=`grep -n 'MAJOR ' ${versionfile} | awk {'print $4'}`
cminor=`grep -n 'MINOR ' ${versionfile} | awk {'print $4'}`
ctiny=`grep -n 'TINY ' ${versionfile} | awk {'print $4'}`
cpre=`grep -n 'PRE ' ${versionfile} | awk {'print $4'}`
if [ "$cpre" == "nil" ]; then
  cpre=0
fi

# Prompt for version number
read -ep "Version: " -i "${cmajor}.${cminor}.${ctiny}.${cpre}" nversion

# parse new version
IFS='.'
read -a versionparts <<< "$nversion"
IFS=' '

nmajor="${versionparts[0]}"
nminor="${versionparts[1]}"
ntiny="${versionparts[2]}"
npre="${versionparts[3]}"

# Update gem_version.rb
sed -i "s/MAJOR\ =.*/MAJOR\ =\ ${nmajor}/g" ${versionfile}
sed -i "s/MINOR\ =.*/MINOR\ =\ ${nminor}/g" ${versionfile}
sed -i "s/TINY\ =.*/TINY\ =\ ${ntiny}/g" ${versionfile}
sed -i "s/PRE\ =.*/PRE\ =\ ${npre}/g" ${versionfile}


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

while true; do
    read -p "Do you wish to restart unicorn now? " yn
    case $yn in
        [Yy]* ) god restart dradispro-unicorn; break;;
        * ) echo "Be sure to restart it later:  god restart dradispro-unicorn"; break;;
    esac
done

