#!/bin/sh

# A script to replace (short) Ansible module names to fully qualified
# collection names. (FQCNs)
# Run this script from within a role directory.

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

  grep -v '^#' "$(dirname $0)/from_to.txt" | while read from to ; do
    grep -E "  +${from}:$" ${files} > /dev/null && \
      echo "Replacing ${from} with ${to} in ${files}." && \
      sedder "s/^(  +)${from}:$/\1${to}:/" ${files} 
  done
}

replace_flat() {
  # A function to find "flat" short module names and advise.
  grep -v '^#' "$(dirname $0)/from_to_flat.txt" | while read from to ; do
    grep -E "  +${from}:" ${*} > /dev/null && \
      echo "Flat style detected, please manually replace ${from} with ${to} in ${*}."
  done
}

alter_requirements() {
  # A function to modify requirements.yml.
  for directory in tasks handlers ; do
    if [ -d "${directory}" ] ; then
      grep "${1}" "${directory}/*.yml" > /dev/null 2>&1
      if [ "$?" = 0 ] ; then
        grep "^collections:$" requirements.yml > /dev/null 2>&1
        if [ "$?" != 0 ] ; then
          echo "collections:" >> requirements.yml
        fi
        grep "${collection}" requirements.yml > /dev/null 2>&1
        if [ "$?" != 0 ] ; then
          echo "Adding collection ${collection} to requirements.yml."
          echo "  - name: ${1}" >> requirements.yml
        fi
      fi
    fi
  done
}

add_to_file() {
  # A function to add a pattern ($2) to a file ($1) when it's missing.
  file="${1}"
  pattern="${2}"

  if [ -f "${file}" ] ; then
    grep -- "${pattern}" "${file}" > /dev/null
    if [ $? != 0 ] ; then
      echo "${pattern}" >> "${file}"
    fi
  fi
}

alter_collections() {
  # A function to modify collections.yml.
  collection="${1}"

  for scenario in molecule/* ; do
    for file in "molecule/${scenario}/*" ; do
      for pattern in "---" "collections:" ; do
        add_to_file "${scenario}/collections.yml" "${pattern}"
      done
      # See if a collection is used, and optionally add it to collections.yml
      grep "${collection}" "${file}" > /dev/null
      if [ "${?}" == 0 ] ; then
        add_to_file "${scenario}/collections.yml"  "  - name: ${collection}"
      fi
    done
  done
}

# Loop over files, call 2 functions for each file.
for file in tasks/*.yml handlers/main.yml molecule/*/prepare.yml molecule/*/converge.yml molecule/*/verify.yml ; do
  if [ -f "${file}" ] ; then
    for function in replace replace_flat ; do
      "${function}" "${file}"
    done
  fi
done

# Collect all listed collections.
collections=$(grep -v '#' "$(dirname $0)/from_to.txt" | grep -v 'ansible.builtin' | awk '{print $2}' | cut -d. -f1,2 | sort | uniq)

for collection in "${collections}" ; do
  alter_requirements "${collection}"
  alter_collections "${collection}"
done
