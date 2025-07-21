#!/bin/bash
set -eux
git add .
git commit -m "deploy remote memory deps"
git push