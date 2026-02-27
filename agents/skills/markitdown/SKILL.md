---
name: markitdown
description: Convert files (PDF, DOCX, PPTX, XLSX, HTML, images, audio, etc.) to Markdown using Microsoft's markitdown CLI. Use when the user wants to extract text content from documents, convert files for LLM processing, or read non-text file formats.
metadata: {"openclaw":{"requires":{"bins":["markitdown"]}}}
user-invocable: true
---

# MarkItDown

## Purpose

Convert a wide variety of file formats into Markdown text using Microsoft's [markitdown](https://github.com/microsoft/markitdown) CLI. Useful for extracting text from documents for LLM analysis, summarization, or ingestion into knowledge bases.

## Supported Formats

| Category | Formats |
|----------|---------|
| Documents | PDF, DOCX, PPTX, XLSX, XLS |
| Web & Data | HTML, CSV, JSON, XML |
| Media | Images (EXIF + OCR), Audio (metadata + transcription) |
| eBooks | EPub |
| Archives | ZIP (iterates over contents) |
| Other | YouTube URLs, Outlook messages |

## Basic Usage

```bash
# Convert a file (output to stdout)
markitdown path/to/file.pdf

# Save output to a file
markitdown path/to/file.pdf -o output.md

# Pipe from stdin
cat path/to/file.pdf | markitdown
```

## Options

| Flag | Description |
|------|-------------|
| `-o <file>` | Write output to a file instead of stdout |
| `-d` | Use Azure Document Intelligence for conversion |
| `-e "<endpoint>"` | Azure Document Intelligence endpoint URL |
| `--use-plugins` | Enable third-party plugins |
| `--list-plugins` | Show installed plugins |

## Workflow

### Single File Conversion

```bash
# Convert and capture the result
result=$(markitdown document.pdf)

# Convert and save
markitdown document.pdf -o document.md
```

### Batch Conversion

```bash
# Convert all PDFs in a directory
for f in *.pdf; do
  markitdown "$f" -o "${f%.pdf}.md"
done
```

### Pipe into Other Tools

```bash
# Convert and count words
markitdown document.pdf | wc -w

# Convert and search for a term
markitdown document.pdf | grep -i "search term"
```

## Agent Usage Notes

- Output goes to stdout by default. Capture it in a variable or redirect to a file.
- For large files, prefer saving to a file with `-o` rather than capturing stdout.
- Image conversion extracts EXIF metadata and OCR text. For richer image descriptions, use the Python API with an LLM client instead.
- ZIP files are automatically extracted and each contained file is converted.
- If conversion fails for a format, check that the corresponding optional dependency is installed (e.g., `markitdown[pdf]` for PDF support).
