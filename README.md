# zapwhite

[![Build Status](https://api.travis-ci.com/realityforge/zapwhite.svg?branch=master)](http://travis-ci.org/realityforge/zapwhite)

A simple tool to normalize whitespace in git repositories. The tool:

* removes trailing whitespace from each line
* ensures files end with a new line
* ensure files are in ASCII format with no invalid UTF sequences
* ensures dos files use dos line endings and all other files do not.

Files that are part of the repository are candidates for normalization.
(It is sufficient for the file to be staged). Files are matched against
patterns supplied either in the command line or in the `.gitattributes`
file associated with the repository.

The tool will ensure files annotated with `text` will be processed and
files with the `eol=crlf` attribute will be treated as dos files. If the
file has an `encoding` attribute, the tool will not try to convert to
ASCII. The tool will also scan and remove duplicate new lines if any file
has a attribute `-dupnl`. The tool will not enforce end of file new
lines if attribute `-eofnl` is set.
