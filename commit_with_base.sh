#!/bin/bash

echo "Committing files individually with 'base' in commit messages..."

# Add all changes first
git add .

# Commit individual files with "base" in the message
git commit -m "base README.md updated"
git commit -m "base PROJECT_README.md updated" 
git commit -m "base SUBMISSION_SUMMARY.md updated"
git commit -m "base TROUBLESHOOTING.md updated"
git commit -m "base COMPLETE_SOLUTION.md updated"
git commit -m "base batch_separate.py updated"
git commit -m "base demo_separation.py updated"
git commit -m "base python_backend folder updated"
git commit -m "base demo_web folder updated"
git commit -m "base lib folder updated"
git commit -m "base android folder updated"
git commit -m "base setup scripts updated"
git commit -m "base configuration files updated"

echo "All files committed with base messages"
