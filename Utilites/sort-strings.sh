#!/usr/bin/env bash

if [[ "${CI}" == "true" || "${ENABLE_PREVIEWS}" == "YES" ]]; then
    echo "Skip strings sorting since we're on CI"
    exit 0
fi

echo "Sorting strings..."
find . -name 'Localizable.strings' -not -path './Pods/*' -exec sort {} -o {} \;
