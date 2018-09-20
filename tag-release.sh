#!/bin/sh

VERSION=$(/usr/libexec/PlistBuddy SwiftiumTestingKit/Info.plist -c "print CFBundleShortVersionString")

TAG=v$VERSION

echo "Have you updated the changelog for version $VERSION ? (ctrl-c to go update it)"
read

set -e

carthage build --no-skip-current && carthage archive SwiftiumTestingKit

echo "Creating tag $TAG and pushing it to github"
git tag $TAG
git push --tags
git tag -f latest
git push --tags -f

echo "You can now upload SwiftiumTestingKit.framework.zip and edit release notes from https://github.com/openium/SwiftiumiTestingKit/releases/edit/$TAG"

