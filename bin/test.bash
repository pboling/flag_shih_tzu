#!/bin/bash --login

# First run the tests of all versions supported on Ruby 1.9.3
rvm use 1.9.3
bundle install --quiet
COMPATIBLE_VERSIONS=(2.3.x 3.0.x 3.1.x 3.2.x 4.0.x)
count=0
while [ "x${COMPATIBLE_VERSIONS[count]}" != "x" ]
do
  version=${COMPATIBLE_VERSIONS[count]}
  BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle install --quiet
  NOCOVER=true BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle exec rake test
  count=$(( $count + 1 ))
done

# Then run the tests of all versions supported on Ruby 2.1.2
rvm use 2.1.2
bundle install --quiet
COMPATIBLE_VERSIONS=(3.2.x 4.0.x 4.1.x)
count=0
while [ "x${COMPATIBLE_VERSIONS[count]}" != "x" ]
do
  version=${COMPATIBLE_VERSIONS[count]}
  BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle install --quiet
  NOCOVER=true BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle exec rake test
  count=$(( $count + 1 ))
done
