#!/bin/bash

# === Step 1: Extract Boost ZIP ===
BOOST_ZIP="boost_1_84_0.zip"
BOOST_DIR="C:/Libraries/boost_1_84_0"

echo "Extracting $BOOST_ZIP to $BOOST_DIR..."

# Create the target directory if it doesn't exist
mkdir -p "$(cygpath -u "$BOOST_DIR")"

# Unzip (you must have unzip installed)
unzip -q "$BOOST_ZIP" -d "C:/Libraries"

# === Step 2: Check for cl.exe ===
echo "Checking for Visual Studio build tools..."
if ! command -v cl.exe &> /dev/null; then
  echo "Error: 'cl.exe' not found. Please run this script from a Developer Command Prompt or ensure Visual Studio Build Tools are on your PATH."
  exit 1
fi

# === Step 3: Run bootstrap.bat ===
echo "Running bootstrap.bat..."
cd "$(cygpath -u "$BOOST_DIR")"
/mnt/c/Windows/System32/cmd.exe /c "bootstrap.bat"

# === Step 4: Build Boost libraries ===
echo "Building Boost with b2..."
/mnt/c/Windows/System32/cmd.exe /c "b2 --build-type=complete stage"

echo "Boost has been built and is ready to use."
