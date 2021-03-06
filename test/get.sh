#!/bin/bash
set -e

source $(dirname $0)/helpers.sh

# tests

it_needs_folders_to_run() {
  local dest=$TMPDIR/destination
  result=0
  jq -n "{
    source: {
    }
  }" | ${resource_dir}/in $dest | tee /dev/stderr || result=$?
  if [ $result -eq 0 ]; then
    echo "in script accepted empty folders"
    exit 1;
  fi
}

it_needs_source_folder_to_run() {
  local dest=$TMPDIR/destination
  result=0
  jq -n "{
    source: {
      folders: [
        {
          destination: \"foo\"
        }
      ]
    }
  }" | ${resource_dir}/in $dest | tee /dev/stderr || result=$?
  if [ $result -eq 0 ]; then
    echo "in script accepted empty folders"
    exit 1;
  fi
}

it_needs_destination_folder_to_run() {
  local dest=$TMPDIR/destination
  result=0
  jq -n "{
    source: {
      folders: [
        {
          source: \"foo\"
        }
      ]
    }
  }" | ${resource_dir}/in $dest | tee /dev/stderr || result=$?
  if [ $result -eq 0 ]; then
    echo "in script accepted empty folders"
    exit 1;
  fi
}

it_needs_each_folder_to_have_source_and_destination() {
  local dest=$TMPDIR/destination
  result=0
  jq -n "{
    source: {
      folders: [
        {
          source: \"foo\",
          destination: \"bar\"
        },
        {
          source: \"baz\"
        },
        {
          destination: \"bing\"
        }
      ]
    }
  }" | ${resource_dir}/in $dest | tee /dev/stderr || result=$?
  if [ $result -eq 0 ]; then
    echo "in script accepted source/destination folder mismatch"
    exit 1;
  fi
}

it_needs_commands_to_run() {
  local dest=$TMPDIR/destination
  result=0
  jq -n "{
    source: {
      folders: [
        {
          \"source\" : \"foo\",
          \"destination\" : \"bar\"
        }
      ]
    }
  }" | ${resource_dir}/in $dest | tee /dev/stderr || result=$?
  if [ $result -eq 0 ]; then
    echo "in script accepted empty commands"
    exit 1;
  fi
}

it_runs_the_commands() {
  local repo=$(init_repo)
  mkdir -p $repo/a/b
  local ref=$(make_commit_to_file $repo file)
  local dest=$TMPDIR/destination
  local sourcecache=$TMPDIR/source/cache
  result=0
  jq -n "{
    source: {
      uri: \"${repo}\",
      folders: [
        {
          \"source\" : \"${sourcecache}\",
          \"destination\" : \"destcache\"
        }
      ],
      commands: [\"touch ${sourcecache}/file\"]
    }
  }" | ${resource_dir}/in ${dest} | tee /dev/stderr | jq -e "
      .version == {ref: $(echo $ref | jq -R .)}"
  test "$(git -C $repo rev-parse HEAD)" = $ref
  if [ ! -f $TMPDIR/destination/destcache/file ]; then
    echo "$TMPDIR/destination/destcache/file does not exist"
    exit 1;
  fi
}

it_cleans_up_specified_patterns() {
  local repo=$(init_repo)
  mkdir -p $repo/a/b
  local dest=$TMPDIR/destination
  local sourcecache=$TMPDIR/source/cache
  result=0
  jq -n "{
    source: {
      uri: \"${repo}\",
      folders: [
        {
          \"source\" : \"${sourcecache}\",
          \"destination\" : \"destcache\"
        }
      ],
      commands: [\"touch ${sourcecache}/file\", \"touch ${sourcecache}/file-SNAPSHOT\"],
      cleanup: [\".*SNAPSHOT\"]
    }
  }" | ${resource_dir}/in ${dest} | tee /dev/stderr
  if [ -f $TMPDIR/destination/destcache/file-SNAPSHOT ]; then
    echo "$TMPDIR/destination/destcache/file-SNAPSHOT not deleted"
    exit 1;
  fi
}

it_does_nothing_if_pattern_not_found() {
  local repo=$(init_repo)
  mkdir -p $repo/a/b
  local dest=$TMPDIR/destination
  local sourcecache=$TMPDIR/source/cache
  result=0
  jq -n "{
    source: {
      uri: \"${repo}\",
      folders: [
        {
          \"source\" : \"${sourcecache}\",
          \"destination\" : \"destcache\"
        }
      ],
      commands: [\"touch ${sourcecache}/file-SNAPSHOT\"],
      cleanup: [\".*WRONGPATTERN\"]
    }
  }" | ${resource_dir}/in ${dest} | tee /dev/stderr
  if [ ! -f $TMPDIR/destination/destcache/file-SNAPSHOT ]; then
    echo "$TMPDIR/destination/destcache/file-SNAPSHOT accidentally deleted"
    exit 1;
  fi
}

it_cleans_up_specified_directory() {
  local repo=$(init_repo)
  mkdir -p $repo/a/b
  local dest=$TMPDIR/destination
  local sourcecache=$TMPDIR/source/cache
  result=0
  jq -n "{
    source: {
      uri: \"${repo}\",
      folders: [
        {
          \"source\" : \"${sourcecache}\",
          \"destination\" : \"destcache\"
        }
      ],
      commands: [\"mkdir ${sourcecache}/foo\", \"touch ${sourcecache}/foo/file-SNAPSHOT\"],
      cleanup: [\"foo\"]
    }
  }" | ${resource_dir}/in ${dest} | tee /dev/stderr
  if [ -d $TMPDIR/destination/destcache/foo ]; then
    echo "$TMPDIR/destination/destcache/foo not deleted"
    exit 1;
  fi
}

# helpers

# test suite

run it_needs_folders_to_run
run it_needs_source_folder_to_run
run it_needs_destination_folder_to_run
run it_needs_each_folder_to_have_source_and_destination
run it_needs_commands_to_run
run it_runs_the_commands
run it_cleans_up_specified_patterns
run it_does_nothing_if_pattern_not_found
run it_cleans_up_specified_directory
