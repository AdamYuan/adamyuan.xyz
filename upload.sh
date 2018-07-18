#!/bin/bash
git add * && \
git commit -m "update $(date)" && \
git push origin master && \
ssh root@adamyuan.xyz './update_site.sh'
