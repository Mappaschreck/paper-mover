# paper-mover
This small script helps you to move your data from Paperwork to e.g. Paperless-ngx.

It searches your Paperwork working directory and extracts your data as follows:
1. if there is only one sheet, such as paper.1.jpg, it will be copied to the target directory as a JPG. 
2. if there are several sheets, such as paper.1.jpg and paper.2.jpg, these are converted into a PDF file via img2pdf and copied to the target directory.
3. if a PDF file such as doc.pdf exists, it is copied to the target directory as a PDF file.
4. if edited files such as paper.1.edited.jpg exist, this is preferred over paper.1.jpg.

All metafiles in the folders, such as
 *paper.1.thumb.jpg
paper.1.words
labels
are ignored.

All extracted files are given the name of the original folder in which they were contained so that the date at which it was sorted in Paperwork is retained.

After the copying process, the data is verified: It is compared whether all folder names in the source directory appear in the target directory as JPG or PDF files. Any discrepancies are displayed in the terminal.

You can now import the files relatively easily into for example Paperless-ngx: The date of receipt can be seen from the file name.

## Requirements:

image2pdf must be installed.
You can do this under Ubuntu, for example, by entering
```console
sudo apt install image2pdf
```

## Installation:
* Download the file paper-move_en.sh (English version) or paper-move_de.sh (German version)
* Make the script executable by using
```console
  chmod +x paper-mover_en.sh
```
(or chmod +x paper-mover_de.sh, if you are using the German version)

## Usage:
```console
bash paper-mover_en.sh
```
(or bash paper-mover_de.sh, if you are using the German version)
