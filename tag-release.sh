#!/bin/sh

if [ $# -lt 1 ] ; then
    echo "usage : `basename $0` 0.3.0";
    exit -1
fi

VERSION=$1
TAG=v$VERSION

echo "Have you updated the changelog for version $VERSION ? (ctrl-c to go update it)"
read

set -e

carthage build --no-skip-current && carthage archive SwiftiumTestingKit

echo "Creating tag $TAG and pushing it to github"
git tag $TAG
git push --tags

echo "You can now upload SwiftiumTestingKit.framework.zip and edit release notes from https://github.com/openium/SwiftiumTestingKit/releases/edit/$TAG"

