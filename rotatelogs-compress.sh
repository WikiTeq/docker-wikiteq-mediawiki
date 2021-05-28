#!/bin/bash
file_to_compress="${2}"
compress_exit_code=0

if [[ "${file_to_compress}" ]]; then
    if [[ -f  "${file_to_compress}" ]]; then
        echo "Compressing ${file_to_compress} ..."
        tar --gzip --create --remove-files --transform 's/.*\///g' --file "${file_to_compress}.tar.gz" "${file_to_compress}"

        compress_exit_code=${?}

        if [[ ${compress_exit_code} == 0 ]]; then
            echo "File ${file_to_compress} was compressed."
        else
            echo "Error compressing file ${file_to_compress} (tar exit code: ${compress_exit_code})."
        fi
    else
        echo "File ${file_to_compress} does not exist".
    fi
fi

exit ${compress_exit_code}
