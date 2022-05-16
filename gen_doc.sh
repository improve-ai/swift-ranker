#!/bin/bash
appledoc --project-name ImproveAI --project-company ImproveAI --no-create-docset --no-install-docset --no-publish-docset .
cp -R html docs
