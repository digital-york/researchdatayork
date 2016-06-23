#!/usr/bin/env bash
################
# Ruby / Rails #
################

echo 'Installing Rails and Ruby'

# add ppa's for ruby and ffmpeg
if ! grep -q brightbox/ruby-ng /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    sudo apt-add-repository -y ppa:brightbox/ruby-ng
else
	echo "ppa:brightbox/ruby-ng is in place"
fi
if ! grep -q mc3man/trusty-media /etc/apt/sources.list /etc/apt/sources.list.d/*; then
	sudo add-apt-repository -y ppa:mc3man/trusty-media
	# sudo apt-get dist-upgrade -y
else
	echo "ppa:mc3man/trusty-media is in place"
fi

# install various things
sudo apt-get update -y
sudo apt-get -y install git build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev sqlite3 libsqlite3-dev

# install ruby
sudo apt-get install -y ruby2.1
sudo apt-get install -y ruby2.1-dev

# install rails
gem install rails
