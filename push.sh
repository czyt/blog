#!/usr/bin/bash
echo pull latest
git pull
git add .
git commit -m "update"
git push
echo done
