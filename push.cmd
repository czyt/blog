@echo off
pushd %~dp0
git pull origin  HEAD:main
git add .
git commit -m "update"
git push origin HEAD:main
timeout 3