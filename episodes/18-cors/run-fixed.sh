#!/bin/sh
kill $(lsof -t -i:5001) 2>/dev/null; sleep 1
node api-fixed.js >/dev/null 2>&1 & sleep 1
node browser-sim.js
kill $(lsof -t -i:5001) 2>/dev/null
