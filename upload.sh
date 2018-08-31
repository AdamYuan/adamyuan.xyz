#!/bin/bash
rm -rf ~/HugoBlog/public/ && \
hugo && \
git add * && \
git commit -m "update $(date)" && \
git push origin master && \
ssh root@adamyuan.xyz 'cd /var/www/adamyuan.xyz/ && git pull origin master'
