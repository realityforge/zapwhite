# zapwhite

[![Build Status](https://secure.travis-ci.org/realityforge/zapwhite.png?branch=master)](http://travis-ci.org/realityforge/zapwhite)

A simple tool to normalize whitespace in git repositories. The tool:

* removes trailing whitespace from each line
* ensures files end with a new line
* ensure files are in UTF-8 format with no invalid UTF sequences
* ensures dos files use dos line endings and all other files do not.

Files that are part of the repository are candidates for normalization.
(It is sufficient for the file to be staged). Files are matched against
patterns supplied either in the command line or in the `.gitattributes`
file associated with the repository.

The tool will ensure files annotated with `text` will be processed and
files with the `crlf` flag as true will be treated as dos files. If the
file has an `encoding` attribute, the tool will not try to convert to
UTF-8.
