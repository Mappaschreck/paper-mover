#!/bin/bash

# Automatisch das Home-Verzeichnis des Benutzers ermitteln
USER_HOME=$(eval echo ~)

# Interaktive Eingabe für Quell- und Zielverzeichnisse
read -p "Bitte geben Sie das Quellverzeichnis an (Standard: $USER_HOME/papers): " SOURCE_DIR
SOURCE_DIR=${SOURCE_DIR:-"$USER_HOME/papers"}

read -p "Bitte geben Sie das Zielverzeichnis an (Standard: $USER_HOME/paper-mover): " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-"$USER_HOME/paper-mover"}

# Überprüfen, ob das Zielverzeichnis existiert, und erstellen, falls nicht
if [ ! -d "$TARGET_DIR" ]; then
    echo "Zielverzeichnis $TARGET_DIR existiert nicht. Erstelle das Verzeichnis..."
    mkdir -p "$TARGET_DIR"
    if [ $? -eq 0 ]; then
        echo "Verzeichnis erfolgreich erstellt."
    else
        echo "Fehler: Konnte das Verzeichnis $TARGET_DIR nicht erstellen."
        exit 1
    fi
fi

# Überprüfen, ob img2pdf installiert ist
if ! command -v img2pdf &> /dev/null; then
    echo "img2pdf ist nicht installiert. Bitte installiere es mit 'sudo apt install img2pdf'."
    exit 1
fi

# Alle Unterordner im Quellverzeichnis durchlaufen
for folder in "$SOURCE_DIR"/*/; do
    # Den Ordnernamen extrahieren (ohne den Pfad)
    folder_name=$(basename "$folder")

    # Prüfen, ob es eine doc.pdf im Ordner gibt
    pdf_file="$folder/doc.pdf"
    if [[ -f "$pdf_file" ]]; then
        echo "doc.pdf gefunden in $folder_name, kopiere als ${folder_name}.pdf"
        
        # Kopiere die doc.pdf als Ordnername.pdf
        cp "$pdf_file" "$TARGET_DIR/${folder_name}.pdf"
        
        # Springe zur nächsten Schleifeniteration (da wir die doc.pdf priorisieren)
        continue
    fi

    # Alle .jpg-Dateien im aktuellen Ordner finden und filtern
    jpg_files=()

    # Schleife über alle .jpg-Dateien im Ordner, aber keine .thumb.jpg oder .words
    for jpg_file in "$folder"*.jpg; do
        # Ignoriere .thumb.jpg Dateien
        if [[ "$jpg_file" == *".thumb.jpg" ]]; then
            continue
        fi

        # Ersetze .jpg durch .edited.jpg, falls vorhanden und füge nur eine Version hinzu
        base_name="${jpg_file%.jpg}"  # Base name without .jpg
        edited_file="${base_name}.edited.jpg"

        # Wenn .edited.jpg existiert, benutze es, ansonsten nimm die .jpg Datei
        if [[ -f "$edited_file" ]]; then
            # Füge die .edited.jpg Datei hinzu und ignoriere das Original
            jpg_files+=("$edited_file")
        elif [[ ! "$jpg_file" == *".edited.jpg" ]]; then
            # Füge die .jpg Datei nur hinzu, wenn keine .edited.jpg existiert
            jpg_files+=("$jpg_file")
        fi
    done

    # Sortieren des jpg_files-Arrays mit natürlicher (numerischer) Sortierung
    IFS=$'\n' jpg_files=($(printf "%s\n" "${jpg_files[@]}" | sort -V))
    unset IFS
    
    # Zählen, wie viele interessante .jpg-Dateien vorhanden sind
    file_count=${#jpg_files[@]}

    if [ $file_count -eq 0 ]; then
        echo "Keine validen JPG- oder PDF-Dateien in $folder_name gefunden, überspringe diesen Ordner."
        continue
    fi

    # Wenn nur eine Datei vorhanden ist, diese als .jpg kopieren
    if [ $file_count -eq 1 ]; then
        echo "Kopiere ${jpg_files[0]} als ${folder_name}.jpg"
        cp "${jpg_files[0]}" "$TARGET_DIR/${folder_name}.jpg"
    else
        # Wenn mehrere Dateien vorhanden sind, als PDF zusammenfügen
        echo "Erstelle PDF aus mehreren JPG-Dateien als $folder_name.pdf"
        img2pdf "${jpg_files[@]}" -o "$TARGET_DIR/${folder_name}.pdf"
    fi
done

# Nur Fehler bei der Überprüfung ausgeben
echo "Verifiziere extrahierte Dateien..."
for folder in "$SOURCE_DIR"/*/; do
    folder_name=$(basename "$folder")
    
    # Überprüfen, ob eine PDF oder JPG mit demselben Namen im Zielordner existiert
    if [[ ! -f "$TARGET_DIR/$folder_name.pdf" && ! -f "$TARGET_DIR/$folder_name.jpg" ]]; then
        echo "Fehler: Keine PDF- oder JPG-Datei für Ordner '$folder_name' gefunden."
    fi
done

echo "Konvertierung und Überprüfung abgeschlossen!"
