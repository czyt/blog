@echo off
pushd %~dp0
git pull
git add .
git commit -m "update"
git push
timeout 3