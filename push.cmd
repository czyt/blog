@echo off
pushd %~dp0
git pull origin  main

REM 获取变更的文件列表和差异
for /f "tokens=*" %%a in ('git diff --staged') do (
    set "diff_output=!diff_output!%%a^

"
)

REM 检查是否有变更
if "!diff_output!"=="" (
    echo No changes to commit.
    exit /b 0
)

REM 生成提交消息
set "commit_message=Auto-commit: Files changed and diffs^

!diff_output!"

git add .
git commit -m "!commit_message!"
git push origin main
timeout 3