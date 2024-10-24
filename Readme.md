# LaTeX Dockerized Compilation Tool

> .tex and .ms files

This project provides a Docker-based environment for compiling LaTeX and Markdown documents. It allows you to easily manage dependencies and keep a clean local environment by using Docker. The project supports custom *.sty* files, automatic rebuilds on file changes, and different document types such as *.tex* and *.md*.

## Features

- Docker-based: No local LaTeX installation is required.
- Custom .sty file support: Easily use custom style files from a designated folder.
- Automatic Rebuild: Automatically compiles the document upon file changes.
- Markdown to PDF: Supports both LaTeX and Markdown documents.

## Prerequisites (for the host)

- Docker: Make sure Docker is installed on your system.
- inotify-tools: For automatic rebuilds on Linux (install with `sudo apt install inotify-tools`)

## Usage

To compile a LaTeX or Markdown document, use the compile.sh script. The script will automatically check if the Docker container is running and start it if needed. It will also compile the document.

```bash
./compile.sh <filename>
```

For example:

```bash
./compile.sh document.tex   # Compiles a LaTeX document
./compile.sh report.md      # Compiles a Markdown document
```

### Use Custom .sty Files

Place your custom .sty files in the sty/ directory along the main document to convert. The container is configured to automatically recognize these files. Include them in your LaTeX document like this:

```latex
\usepackage{custom}    % For sty/custom.sty
\usepackage{another}   % For sty/another.sty
```

If needed, the `--tlmgr` option of the latexer script allows adding texlive extensions to the container.

### Automatic Rebuilds on File Changes

To automatically rebuild the document on file changes, the *latexer.sh* script uses file-watching tools (inotifywait). The script watches the specified file and re-compiles it if changes are detected after 5 seconds of no modifications.

### Accessing Output Files

Compiled PDF files are saved in the directory containing the input document.

### Customizing Dockerfile and Dependencies

You can add additional LaTeX packages or dependencies to the Dockerfile if needed. For example:

```dockerfile
RUN tlmgr install package-name   # To install additional LaTeX packages
```
