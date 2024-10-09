#!/bin/bash

# Automatically detect the user's home directory
USER_HOME=$(eval echo ~)

# Interactive input for source and target directories
read -p "Please enter the source directory (default: $USER_HOME/papers): " SOURCE_DIR
SOURCE_DIR=${SOURCE_DIR:-"$USER_HOME/papers"}

read -p "Please enter the target directory (default: $USER_HOME/paper-mover): " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-"$USER_HOME/paper-mover"}

# Check if the target directory exists, and create it if it doesn't
if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory $TARGET_DIR does not exist. Creating the directory..."
    mkdir -p "$TARGET_DIR"
    if [ $? -eq 0 ]; then
        echo "Directory successfully created."
    else
        echo "Error: Failed to create the directory $TARGET_DIR."
        exit 1
    fi
fi

# Check if img2pdf is installed
if ! command -v img2pdf &> /dev/null; then
    echo "img2pdf is not installed. Please install it with 'sudo apt install img2pdf'."
    exit 1
fi

# Loop through all subdirectories in the source directory
for folder in "$SOURCE_DIR"/*/; do
    # Extract the folder name (without the path)
    folder_name=$(basename "$folder")

    # Check if there is a doc.pdf file in the folder
    pdf_file="$folder/doc.pdf"
    if [[ -f "$pdf_file" ]]; then
        echo "doc.pdf found in $folder_name, copying as ${folder_name}.pdf"
        
        # Copy the doc.pdf file as folder_name.pdf
        cp "$pdf_file" "$TARGET_DIR/${folder_name}.pdf"
        
        # Skip to the next iteration (since we prioritize doc.pdf)
        continue
    fi

    # Find all .jpg files in the current folder and filter them
    jpg_files=()

    # Loop through all .jpg files in the folder, but ignore .thumb.jpg and .words
    for jpg_file in "$folder"*.jpg; do
        # Ignore .thumb.jpg files
        if [[ "$jpg_file" == *".thumb.jpg" ]]; then
            continue
        fi

        # Replace .jpg with .edited.jpg if available, and only add one version
        base_name="${jpg_file%.jpg}"  # Base name without .jpg
        edited_file="${base_name}.edited.jpg"

        # If .edited.jpg exists, use it; otherwise, use the .jpg file
        if [[ -f "$edited_file" ]]; then
            # Add the .edited.jpg file and ignore the original
            jpg_files+=("$edited_file")
        elif [[ ! "$jpg_file" == *".edited.jpg" ]]; then
            # Only add the .jpg file if no .edited.jpg exists
            jpg_files+=("$jpg_file")
        fi
    done

    # Count how many valid .jpg files exist
    file_count=${#jpg_files[@]}

    if [ $file_count -eq 0 ]; then
        echo "No valid JPG or PDF files found in $folder_name, skipping this folder."
        continue
    fi

    # If only one file exists, copy it as a .jpg
    if [ $file_count -eq 1 ]; then
        echo "Copying ${jpg_files[0]} as ${folder_name}.jpg"
        cp "${jpg_files[0]}" "$TARGET_DIR/${folder_name}.jpg"
    else
        # If multiple files exist, merge them into a PDF
        echo "Creating PDF from multiple JPG files as $folder_name.pdf"
        img2pdf "${jpg_files[@]}" -o "$TARGET_DIR/${folder_name}.pdf"
    fi
done

# Only show errors during verification
echo "Verifying extracted files..."
for folder in "$SOURCE_DIR"/*/; do
    folder_name=$(basename "$folder")
    
    # Check if a PDF or JPG with the same name exists in the target directory
    if [[ ! -f "$TARGET_DIR/$folder_name.pdf" && ! -f "$TARGET_DIR/$folder_name.jpg" ]]; then
        echo "Error: No PDF or JPG file found for folder '$folder_name'."
    fi
done

echo "Conversion and verification completed!"
