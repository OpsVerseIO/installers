#!/bin/bash

for file_to_patch in /etc/init.d/opsverse* /etc/init.d/node_export* /etc/init.d/prom-*; do
  if grep -q pidof $file_to_patch; then
    echo "$file_to_patch already contains patch"
  else
    if grep -q opsverse $file_to_patch; then
      echo "patching $file_to_patch..."
      initscript=$(grep touch $file_to_patch | awk '{print $2}' | xargs basename)
      procname=$(grep killproc $file_to_patch | awk '{print $2}')

      sed -E -i "s/(\ttouch.*)/\1\n\techo \$(pidof ${procname}) > \/var\/run\/${initscript}.pid/" $file_to_patch
      sed -E -i "s/(\trm -f \/var\/lock.*)/\1\n\trm -f \/var\/run\/${initscript}.pid/" $file_to_patch
      echo "done."
    fi
  fi
done
