#!/bin/bash

# Check if a folder path was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <folder_path>"
  exit 1
fi

FOLDER_PATH=$1

# Check if the specified folder exists
if [ ! -d "$FOLDER_PATH" ]; then
  echo "Error: Specified folder does not exist"
  exit 1
fi

# Navigate to the specified folder
cd "$FOLDER_PATH"

# Function to display licenses in red if they are non-permissive
display_license() {
  LICENSE=$1
  case "$LICENSE" in
    "MIT"|"Apache-2.0"|"BSD-2-Clause"|"BSD-3-Clause"|"ISC")
      echo "$LICENSE"
      ;;
    *)
      echo -e "\e[31m$LICENSE\e[0m"
      ;;
  esac
}

# Function to check licenses for npm projects
check_node_licenses() {
  if [ -f "package.json" ]; then
    echo "Checking licenses for npm project..."
    # Install license-checker if it is not already installed
    if ! command -v license-checker &> /dev/null; then
      echo "license-checker not found. Installing..."
      npm install -g license-checker
    fi
    # Run license-checker
    license-checker --json > licenses-node.json
    cat licenses-node.json | jq -r 'to_entries[] | "\(.key): \(.value.licenses)"' | while read -r line; do
      DEP=$(echo "$line" | cut -d: -f1)
      LIC=$(echo "$line" | cut -d: -f2 | xargs)
      echo -n "$DEP: "
      display_license "$LIC"
    done
    echo "License check complete. Results saved to licenses-node.json"
  else
    echo "No package.json found. Skipping npm license check."
  fi
}

# Function to check licenses for Maven projects
check_maven_licenses() {
  if [ -f "pom.xml" ]; then
    echo "Checking licenses for Maven project..."
    # Install license-maven-plugin if it is not already installed
    if ! mvn help:evaluate -Dexpression=license-maven-plugin.version &> /dev/null; then
      echo "license-maven-plugin not found. Installing..."
      mvn org.codehaus.mojo:license-maven-plugin:download-licenses
    fi
    # Run license-maven-plugin
    mvn license:aggregate-download-licenses
    mvn license:download-licenses
    # Display licenses
    find target/generated-resources/licenses -name "*.xml" -exec cat {} \; | grep -oP '(?<=<licenses>).*?(?=</licenses>)' | while read -r line; do
      display_license "$line"
    done
    echo "License check complete. Results saved to target/generated-resources/licenses"
  else
    echo "No pom.xml found. Skipping Maven license check."
  fi
}

# Function to check licenses for Python projects
check_python_licenses() {
  if [ -f "requirements.txt" ]; then
    echo "Checking licenses for Python project..."
    # Install pip-licenses if it is not already installed
    if ! command -v pip-licenses &> /dev/null; then
      echo "pip-licenses not found. Installing..."
      pip install pip-licenses
    fi
    # Run pip-licenses
    pip-licenses --format=json > licenses-python.json
    cat licenses-python.json | jq -r '.[] | "\(.Name): \(.License)"' | while read -r line; do
      DEP=$(echo "$line" | cut -d: -f1)
      LIC=$(echo "$line" | cut -d: -f2 | xargs)
      echo -n "$DEP: "
      display_license "$LIC"
    done
    echo "License check complete. Results saved to licenses-python.json"
  else
    echo "No requirements.txt found. Skipping Python license check."
  fi
}

# Check licenses for all project types
check_node_licenses
check_maven_licenses
check_python_licenses

echo "All license checks completed."
