#!/bin/bash
# A small script to start codeocean and dockercontainerpool on two tmux panes in the same window.
# Must be called from within the vagrant VM.
sessionname='codeocean-session'
windowname='codeocean'
tmux new-session -d -s $sessionname
tmux new-window -n $windowname -t 0 -k 'cd /home/vagrant/dockercontainerpool && rails s -p 7100'
tmux split-window -h -b -t 0 'cd /home/vagrant/codeocean && rails s -b 0.0.0.0 -p 7000'
tmux set-option -t 0 remain-on-exit on
tmux attach -t $sessionname

