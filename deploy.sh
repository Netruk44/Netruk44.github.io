#! /bin/bash

hugo --minify
rclone sync ./public/ storage:/home/nginx/personal_site/ --progress
