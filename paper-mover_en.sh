#!/bin/bash

# Automatically determine the user's home directory
USER_HOME=$(eval echo ~)

# Interactive input for source and target directories
read -p "Please enter the source directory (default: $USER_HOME/papers): " SOURCE_DIR
SOURCE_DIR=${SOURCE_DIR:-"$USER_HOME/papers"}

read -p "Please enter the target directory (default: $USER_HOME/paper-mover): " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-"$USER_HOME/paper-mover"}

# Check whether img2pdf is installed
if ! command -v img2pdf &> /dev/null; then
    echo "img2pdf is not installed. Please install it with 'sudo apt install img2pdf'."
    exit 1
fi

# Cycle through all subfolders in the source directory
for folder in "$SOURCE_DIR"/*/; do
    # Extract the folder name (without the path)
    folder_name=$(basename "$folder")

    # Check if there is a doc.pdf in the folder
    pdf_file="$folder/doc.pdf"
    if [[ -f "$pdf_file" ]]; then
        echo "doc.pdf found in $folder_name, copy as ${folder_name}.pdf"
        
        # Copy doc.pdf as folder_name.pdf
        cp "$pdf_file" "$TARGET_DIR/${folder_name}.pdf"
        
        # Skip to the next loop iteration (as we prioritize the doc.pdf)
        continue
    fi

    # Find and filter all .jpg files in the current folder
    jpg_files=()

# Loop over all .jpg files in the folder, but no .thumb.jpg or .words
for jpg_file in "$folder"*.jpg; do
        # Ignore .thumb.jpg files
        if [[ "$jpg_file" == *".thumb.jpg" ]]; then
            continue
        fi

        # Replace .jpg with .edited.jpg if available and add only one version
        base_name="${jpg_file%.jpg}"  # Base name without .jpg
        edited_file="${base_name}.edited.jpg"

        # If .edited.jpg exists, use it, otherwise use the .jpg file
        if [[ -f "$edited_file" ]]; then
            # Add the .edited.jpg file and ignore the original
            jpg_files+=("$edited_file")
        elif [[ ! "$jpg_file" == *".edited.jpg" ]]; then
            # Add the .jpg file only if no .edited.jpg exists
            jpg_files+=("$jpg_file")
        fi
    done

    # Count how many interesting .jpg files exist
    file_count=${#jpg_files[@]}

    if [ $file_count -eq 0 ]; then
        “No valid JPG or PDF files found in $folder_name, skip this folder.”
        continue
    fi

    # If only one file exists, copy it as .jpg
    if [ $file_count -eq 1 ]; then
        echo "Copy ${jpg_files[0]} as ${folder_name}.jpg"
        cp "${jpg_files[0]}" "$TARGET_DIR/${folder_name}.jpg"
    else
        # If several files are available, merge as PDF
        echo “Create PDF from multiple JPG files as $folder_name.pdf”
        img2pdf "${jpg_files[@]}" -o "$TARGET_DIR/${folder_name}.pdf"
    fi
done

# Only display errors during the check
echo “Verify extracted files...”
for folder in "$SOURCE_DIR"/*/; do
    folder_name=$(basename "$folder")
    
    # Check whether a PDF or JPG with the same name exists in the destination folder
    if [[ ! -f "$TARGET_DIR/$folder_name.pdf" && ! -f "$TARGET_DIR/$folder_name.jpg" ]]; then
        echo “Error: No PDF or JPG file found for folder '$folder_name'.”
    fi
done

echo "Conversion and verification completed!"
