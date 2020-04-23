#!/bin/sh

if [ $# -lt 1 ] ; then
    echo "usage : `basename $0` 0.3.0";
    exit -1
fi

VERSION=$1
TAG=$VERSION

echo "Have you updated the changelog for version $VERSION ? (ctrl-c to go update it)"
read

set -e

echo "Creating tag $TAG and pushing it to github"
git tag $TAG
git push --tags

