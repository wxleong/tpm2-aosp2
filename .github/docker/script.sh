#!/usr/bin/env bash

# -e: exit when any command fails
# -x: all executed commands are printed to the terminal
# -o pipefail: prevents errors in a pipeline from being masked
set -exo pipefail

TEMP_FILE=.parse_${SCRIPT_NAME}

cd $WORKSPACE_DIR

# Mark generic commands
cat README.md | sed '/^ *```all.*$/,/^ *```$/ { s/^ *\$/_M_/; { :loop; /^_M_.*\\$/ { n; s/^/_M_/; t loop } } }' > ${TEMP_FILE}
# Mark commands that are dependent on the distro
sed -i '/^ *```.*'"${DOCKER_IMAGE}"'.*/,/^ *```$/ { s/^ *\$/_M_/; { :loop; /^_M_.*\\$/ { n; s/^/_M_/; t loop } } }' ${TEMP_FILE}
# Comment all lines without the marker
sed -i '/^_M_/! s/^/# /' ${TEMP_FILE}
# Remove the appended comment from all marked lines
sed -i '/^_M_/ s/<--.*//' ${TEMP_FILE}
# Remove the marker
sed -i 's/^_M_ //' ${TEMP_FILE}
# Remove sudo, it is not necessary in docker
sed -i 's/sudo //g' ${TEMP_FILE}

# Initialize an executable script
cat > ${SCRIPT_NAME} << EOF
#!/usr/bin/env bash
set -eufxo pipefail

EOF

cat ${TEMP_FILE} >> ${SCRIPT_NAME}
echo -e '\nexit 0' >> ${SCRIPT_NAME}

chmod a+x ${SCRIPT_NAME}
./${SCRIPT_NAME}

exit 0