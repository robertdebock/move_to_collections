#!/bin/sh

# A script to replace (short) Ansible module names to fully qualified
# collection names. (FQCNs)
# Run this script from within a role directory.

# This script ships with two seperate files that are stored in a directory
# alongisde this script. The following variables ensure that this script can
# find these accompanying files when it is symlinked to a different directory.

script_path=$(readlink -f "$0")
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
    grep -E "  +${from}: ${*}" > /dev/null && \
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
      if grep "${collection}" "${directory}"/*.yml > /dev/null 2>&1 ; then
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
  # A function to find all files to inspect.
  find ./tasks -name '*.yml'
  echo "handlers/main.yml"
  for scenario in molecule/* ; do
    echo "${scenario}/prepare.yml"
    echo "${scenario}/converge.yml"
    echo "${scenario}/verify.yml"
  done
}

# Loop over files, call 2 functions for each file.
# for file in tasks/*.yml handlers/main.yml molecule/*/prepare.yml molecule/*/converge.yml molecule/*/verify.yml ; do
finder | while read -r file ; do
  if [ -f "${file}" ] ; then
    for function in replace replace_flat ; do
      "${function}" "${file}"
    done
  fi
done

# Collect all listed collections.
collections=$(grep -v '#' "${script_dir}/from_to.txt" | grep -v 'ansible.builtin' | awk '{print $2}' | cut -d. -f1,2 | sort | uniq)

for collection in ${collections} ; do
  alter_requirements "${collection}"
  alter_collections "${collection}"
done
