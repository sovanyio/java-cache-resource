#!/bin/sh

set -eu

_main() {
  repo=https://github.com/concourse/git-resource.git
  version=master

  tmpdir="$(mktemp -d git_resource_install.XXXXXX)"
  cd "$tmpdir"
  git clone "${repo}" .
  git checkout "${version}"
  mkdir -p /opt/resource/git
  cp -r assets/* /opt/resource/git
  chmod +x /opt/resource/git/*
}

_main "$@"
