@echo off
pushd %~dp0
git add .
git commit -m "update"
git push
timeout 3