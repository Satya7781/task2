#!/bin/bash

echo "Adding 'base' prefix to files and folders..."

# Rename main files
mv README.md base_README.md 2>/dev/null
mv PROJECT_README.md base_PROJECT_README.md 2>/dev/null
mv SUBMISSION_SUMMARY.md base_SUBMISSION_SUMMARY.md 2>/dev/null
mv TROUBLESHOOTING.md base_TROUBLESHOOTING.md 2>/dev/null
mv COMPLETE_SOLUTION.md base_COMPLETE_SOLUTION.md 2>/dev/null
mv REAL_VS_DEMO.md base_REAL_VS_DEMO.md 2>/dev/null

# Rename Python scripts
mv batch_separate.py base_batch_separate.py 2>/dev/null
mv batch_process.py base_batch_process.py 2>/dev/null
mv demo_separation.py base_demo_separation.py 2>/dev/null
mv demo.py base_demo.py 2>/dev/null
mv test_api.py base_test_api.py 2>/dev/null
mv test_audio_fix.py base_test_audio_fix.py 2>/dev/null

# Rename shell scripts
mv setup.sh base_setup.sh 2>/dev/null
mv start_demo.sh base_start_demo.sh 2>/dev/null
mv start_real_ai.sh base_start_real_ai.sh 2>/dev/null
mv switch_to_demo.sh base_switch_to_demo.sh 2>/dev/null
mv switch_to_real_ai.sh base_switch_to_real_ai.sh 2>/dev/null
mv restart_api.sh base_restart_api.sh 2>/dev/null
mv debug_and_fix.sh base_debug_and_fix.sh 2>/dev/null
mv test_separation.sh base_test_separation.sh 2>/dev/null

# Rename directories
mv python_backend base_python_backend 2>/dev/null
mv demo_web base_demo_web 2>/dev/null
mv lib base_lib 2>/dev/null
mv android base_android 2>/dev/null
mv ios base_ios 2>/dev/null
mv web base_web 2>/dev/null
mv linux base_linux 2>/dev/null
mv macos base_macos 2>/dev/null
mv windows base_windows 2>/dev/null
mv test base_test 2>/dev/null

echo "Renaming completed!"
echo "Files and folders now have 'base' prefix"
