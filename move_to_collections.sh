#!/bin/sh

# A script to replace (short) Ansible module names to fully qualified collection names.
# Run this script from within a role directory.

replace() {
  # A function to find short module names and replace with the FQCN.
  grep -v '^#' "$(dirname $0)/from_to.txt" | while read from to ; do
    grep -E "^  ${from}:" ${*} > /dev/null && echo "Replacing ${from} with ${to}."
    sed -i "s/^  ${from}:/  ${to}:/" ${*}
  done
}

alter_requirements() {
  # A function to modify requirements.yml.
  grep ${1} tasks/*.yml handlers/*.yml > /dev/null 2>&1
  if [ $? = 0 ] ; then
    grep "^collections:$" requirements.yml > /dev/null 2>&1
    if [ $? != 0 ] ; then
      echo "collections:" >> requirements.yml
    fi
    grep "${collection}" requirements.yml > /dev/null 2>&1
    if [ $? != 0 ] ; then
      echo "Adding collection ${collection} to requirements.yml."
      echo "  - name: ${1}" >> requirements.yml
    fi
  fi
}

echo "Inspecting module names in tasks/*.yml."
replace tasks/*.yml

if [ -f handlers/main.yml ] ; then
  echo "Inspecting module names in handlers/main.yml."
  replace handlers/main.yml
fi

collections=$(grep -v '#' "$(dirname $0)/from_to.txt" | grep -v 'ansible.builtin' | awk '{print $2}' | cut -d. -f1,2 | sort | uniq)
for collection in ${collections} ; do
  alter_requirements ${collection}
done
