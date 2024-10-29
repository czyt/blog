#!/usr/bin/env bash

echo "Pulling latest changes..."
git pull

git config user.email &>/dev/null
if [ $? -ne 0 ]; then
    echo "Setting Git user email..."
    git config --global user.email "czyt@w.cn"
fi

git config user.name &>/dev/null
if [ $? -ne 0 ]; then
    echo "Setting Git user name..."
    git config --global user.name "czyt"
fi


commit_message="update post"


echo "Adding all changes..."
git add .

echo "Committing..."
git commit -m "$commit_message"

echo "Pushing to remote..."
git push

timeout 3s  echo "Done!"
