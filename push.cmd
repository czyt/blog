@echo off
setlocal enabledelayedexpansion

pushd %~dp0
git pull origin main

REM 获取变更的文件列表和差异
set "diff_output="
for /f "tokens=*" %%a in ('git diff --name-only --staged') do (
    set "diff_output=!diff_output!%%a, "
)

REM 移除最后的逗号和空格
if defined diff_output set "diff_output=!diff_output:~0,-2!"

REM 检查是否有变更
if "!diff_output!"=="" (
    echo No changes to commit.
    exit /b 0
)

REM 生成提交消息
set "commit_message=Auto-commit: Files changed: !diff_output!"

git add .
git commit -m "!commit_message!"
git push origin main

echo Commit message: !commit_message!
timeout 3

popd
endlocal