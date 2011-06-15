#!/bin/sh

# Control script for the git_http daemon

PIDFILE=pids/git_http.pid
if [ "$JRUBY" = "" ]; then JRUBY="/usr/bin/env jruby"; fi
SCRIPT="$JRUBY git_http_servlet.rb"

if [ "$JRUBY" = "" ]; then
    echo "Please set $JRUBY to point to your jruby executable to run this script"
    exit
fi

create_pid_dir() {
    if [ ! -d "pids" ]; then
        mkdir pids
    fi
}

start() {
    run >> git_http.out 2>&1 &
}

run() {
    echo "Starting..."
    create_pid_dir
    $SCRIPT
}

stop() {
    kill `cat $PIDFILE`
    echo "Stopping"
}

case "$1" in
    run)
        run
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
esac