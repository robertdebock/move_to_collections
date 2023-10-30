#!/bin/sh

# A script to replace (short) Ansible module names to fully qualified
# collection names. (FQCNs)
# Run this script from within a role directory.

# readlink is different on Linux and Mac OS X. This function replaces readlink.
readlink() {
  TARGET="${1}"
  cd "$(dirname "${TARGET}")" || exit
  TARGET=$(basename "${TARGET}")
  while [ -L "${TARGET}" ]
  do
      TARGET=$(readlink "${TARGET}")
      cd "$(dirname "${TARGET}")" || exit
      TARGET=$(basename "${TARGET}")
  done
  DIR=$(pwd -P)
  RESULT="${DIR}/${TARGET}"
  echo "${RESULT}"
}

# The `grep` utility uses regular expressions. Matching a pattern requires UNIX-
# formatted files. This functions tests if UNIX-formatted files are used.
test_unix_file() {
  file="${1}"
  file "${file}" | grep -vq "ASCII text, with CRLF line terminators" || (echo "The file $file is not UNIX-formatted, skipping." ; exit 1)
}

# This script ships with two seperate files that are stored in a directory
# alongisde this script. The following variables ensure that this script can
# find these accompanying files when it is symlinked to a different directory.

# script_path is the full absolute path the script. i.e. /bin/my_script.sh
script_path=$(readlink "$0")
# script_dir is the absolute path to the script. i.e. /bin
script_dir=$(dirname "${script_path}")

sedder() {
  # A function to run sed with the correct syntax based on the operating system.
  pattern="${1}"
  file="${2}"

  output="$(uname)"
  case "${output}" in
    Darwin):
      sed -Ei '' "${pattern}" "${file}"
    ;;
    *)
      sed -Ei "${pattern}" "${file}"
    ;;
  esac
}

replace() {
  # A function to find short module names and replace with the FQCN.
  files="${*}"

  grep -v '^#' "${script_dir}/from_to.txt" | while read -r from to ; do
    grep -E "  +${from}:$" "${files}" > /dev/null && \
      echo "Replacing ${from} with ${to} in ${files}." && \
      sedder "s/^(  +)${from}:$/\1${to}:/" "${files}"
  done
}

replace_flat() {
  # A function to find "flat" short module names and advise.
  grep -v '^#' "${script_dir}/from_to_flat.txt" | while read -r from to ; do
    grep -E "  +${from}:" "${*}" > /dev/null && \
      echo "Replacing ${from} with ${to} in ${files}." && \
      sedder "s/^(  +)${from}:(.*)$/\1${to}:\2/" "${files}"
  done
}

add_to_file() {
  # A function to add a pattern ($2) to a file ($1) when it's missing.
  file="${1}"
  pattern="${2}"

  if [ -f "${file}" ] ; then
    if ! grep -- "${pattern}" "${file}" > /dev/null ; then
      echo "Adding ${pattern} to ${file}."
      echo "${pattern}" >> "${file}"
    fi
  fi
}

alter_requirements() {
  # A function to modify requirements.yml.
  collection="${1}"

  for directory in tasks handlers ; do
    if [ -d "${directory}" ] ; then
      if grep -r "${collection}" --include \*.yml --include \*.yaml "${directory}" > /dev/null 2>&1 ; then
        # Ensure requirements.yml exists
        touch requirements.yml
        # Add a header to requirements.yml
        for pattern in "---" "collections:" ; do
          add_to_file requirements.yml "${pattern}"
        done
        add_to_file requirements.yml "  - name: $collection"
      fi
    fi
  done
}

alter_collections() {
  # A function to modify collections.yml.
  collection="${1}"

  for scenario in molecule/* ; do
    # Add the header to collections.yml.
    for pattern in "---" "collections:" ; do
      add_to_file "${scenario}/collections.yml" "${pattern}"
    done

    # See if a collection is used, and optionally add it to collections.yml
    for file in "${scenario}"/* ; do
      if [ -f "${file}" ] ; then
        if grep "${collection}" "${file}" > /dev/null ; then
          add_to_file "${scenario}/collections.yml"  "  - name: ${collection}"
        fi
      fi
    done

    # Add the collections found in the role to collections.yml too.
    for directory in tasks handlers ; do
      if [ -d "${directory}" ] ; then
        if grep "${collection}" ${directory}/*.yml > /dev/null 2>&1 ; then
          add_to_file "${scenario}/collections.yml"  "  - name: ${collection}"
        fi
      fi
    done
  done
}

finder() {
  # A function to find all YAML files to inspect.
  # https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#id2 reads main, main.yml and main.yaml are valid file names
  find ./tasks -name '*.yml' -o -name '*.yaml' -o -name 'main'
  # It's valid to split the main file into several files and include them
  if [ -d handlers ] ; then
    find ./handlers -name '*.yml' -o -name '*.yaml' -o -name 'main'
  fi
  for scenario in molecule/* ; do
    echo "${scenario}/prepare.yml"
    echo "${scenario}/converge.yml"
    echo "${scenario}/verify.yml"
  done
}

# Loop over found YAML files, call 2 functions for each file.
finder | while read -r file ; do
  if [ -f "${file}" ] ; then
    for function in test_unix_file replace replace_flat ; do
      "${function}" "${file}"
    done
  fi
done

# Collect all listed collections.
collections=$(grep -v '#' "${script_dir}/from_to.txt" | grep -v 'ansible.builtin' | awk '{print $2}' | cut -d. -f1,2 | sort | uniq)

for collection in ${collections} ; do
  alter_requirements "${collection}"
  # alter_collections "${collection}"
done
