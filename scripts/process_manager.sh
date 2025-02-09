#!/bin/bash

PYTHON311_PATH="/path/to/python3.11"
LANGFLOW_SCRIPT="src/scripts/run_langflow.py"
PID_FILE="/tmp/langflow.pid"

start_langflow() {
    if [ -f "$PID_FILE" ]; then
        echo "Langflow is already running"
        exit 1
    fi
    
    $PYTHON311_PATH $LANGFLOW_SCRIPT &
    echo $! > $PID_FILE
    echo "Langflow started with PID $(cat $PID_FILE)"
}

stop_langflow() {
    if [ -f "$PID_FILE" ]; then
        kill $(cat $PID_FILE)
        rm $PID_FILE
        echo "Langflow stopped"
    else
        echo "Langflow is not running"
    fi
}

case "$1" in
    start)
        start_langflow
        ;;
    stop)
        stop_langflow
        ;;
    restart)
        stop_langflow
        start_langflow
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac 