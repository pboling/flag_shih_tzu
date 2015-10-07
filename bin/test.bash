#!/bin/bash --login

gem_installed() {
    num=$(gem list $1 | grep -e "^$1 " | wc -l)
    if [ $num -eq "1" ]; then
      echo "already installed $1"
    else
      gem install $1
    fi
    return 0
}

# First run the tests of all versions supported on Ruby 1.9.3
COMPATIBLE_VERSIONS=(2.3.x 3.0.x 3.1.x 3.2.x)
count=0
while [ "x${COMPATIBLE_VERSIONS[count]}" != "x" ]
do
  version=${COMPATIBLE_VERSIONS[count]}
  rvm use 1.9.3@flag_shih_tzu-$version --create
  gem_installed "bundler"
  BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle update --quiet
  NOCOVER=true BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle exec rake test
  count=$(( $count + 1 ))
done

# Then run the tests of all versions supported on Ruby 2.0.0
COMPATIBLE_VERSIONS=(3.0.x 3.1.x 3.2.x 4.0.x 4.1.x)
count=0
while [ "x${COMPATIBLE_VERSIONS[count]}" != "x" ]
do
  version=${COMPATIBLE_VERSIONS[count]}
  rvm use 2.0.0@flag_shih_tzu-$version --create
  gem_installed "bundler"
  BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle install --quiet
  NOCOVER=true BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle exec rake test
  count=$(( $count + 1 ))
done

# Then run the tests of all versions supported on Ruby 2.1.5
COMPATIBLE_VERSIONS=(3.2.x 4.0.x 4.1.x 4.2.x)
count=0
while [ "x${COMPATIBLE_VERSIONS[count]}" != "x" ]
do
  version=${COMPATIBLE_VERSIONS[count]}
  rvm use 2.1.5@flag_shih_tzu-$version --create
  gem_installed "bundler"
  BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle install --quiet
  NOCOVER=true BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle exec rake test
  count=$(( $count + 1 ))
done

# Then run the tests of all versions supported on Ruby 2.2.3
COMPATIBLE_VERSIONS=(3.2.x 4.0.x 4.1.x 4.2.x)
count=0
while [ "x${COMPATIBLE_VERSIONS[count]}" != "x" ]
do
  version=${COMPATIBLE_VERSIONS[count]}
  rvm use 2.2.3@flag_shih_tzu-$version --create
  gem_installed "bundler"
  BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle install --quiet
  NOCOVER=true BUNDLE_GEMFILE="gemfiles/Gemfile.activerecord-$version" bundle exec rake test
  count=$(( $count + 1 ))
done
