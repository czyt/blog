@echo off
pushd %~dp0
git pull origin main
git add .
git commit -m "update"
git push origin main
timeout 3