#!/bin/bash

###
# Prepare a Pantheon site environment for the Behat test suite, by pushing the
# requested upstream branch to the environment. This script is architected
# such that it can be run a second time if a step fails.
###

set -ex

if [ -z "$TERMINUS_SITE" ] || [ -z "$TERMINUS_ENV" ]; then
	echo "TERMINUS_SITE and TERMINUS_ENV environment variables must be set"
	exit 1
fi

# Duisable PasswordAuthentication on *.drush.in
echo "Host *.drush.in
	PasswordAuthentication no" >> ~/.ssh/config

terminus auth:login --machine-token=$TERMINUS_TOKEN

# Apply any upstream updates (update WP core)
terminus upstream:updates:apply $TERMINUS_SITE.dev --accept-upstream

###
# Switch to SFTP mode so the site can install plugins and themes
###
terminus connection:set $TERMINUS_SITE.dev sftp

# Update plugins and themes to make sure we're 100% up-to-date.
terminus wp -- $TERMINUS_SITE.dev plugin update --all
terminus wp -- $TERMINUS_SITE.dev theme update --all
# Commit the changes to the fixture.
terminus env:commit $TERMINUS_SITE.dev --message="Update WordPress core, plugins and themes"

###
# Create a new environment for this particular test run.
###
terminus env:create $TERMINUS_SITE.dev $TERMINUS_ENV
terminus env:wipe $SITE_ENV --yes

###
# Get all necessary environment details.
###
PANTHEON_GIT_URL=$(terminus connection:info $SITE_ENV --field=git_url)
PANTHEON_SITE_URL="$TERMINUS_ENV-$TERMINUS_SITE.pantheonsite.io"
PREPARE_DIR="/tmp/$TERMINUS_ENV-$TERMINUS_SITE"
BASH_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

rm -rf $PREPARE_DIR
# git clone -b $TERMINUS_ENV $PANTHEON_GIT_URL $PREPARE_DIR
