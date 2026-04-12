#!/bin/bash

"""true"

if which python3 >/dev/null; then
	exec python3 "$0" "$@"
else
	exec python "$0" "$@"
fi

"""

# Copy a directory recursively WITHOUT the race condition in cp -r.

# This also ignores symbolic links.

import errno
import os
import shutil
import sys

if sys.version_info.major >= 3:
	file_exists_error = FileExistsError
	def is_file_exists_error(e):
		return True
else:
	file_exists_error = OSError
	def is_file_exists_error(e):
		return e.errno == errno.EEXIST

def copy_recursive(src, destdir):
	dest = os.path.join(destdir, os.path.basename(src))
	if os.path.isdir(src):
		try:
			os.mkdir(dest)
		except file_exists_error as e:
			if not is_file_exists_error(e):
				raise
		for filename in os.listdir(src):
			path = os.path.join(src, filename)
			copy_recursive(path, dest)
	elif os.path.islink(src):
		shutil.copy(src, dest, follow_symlinks=False)
	elif os.path.isfile(src):
		shutil.copy(src, dest)
	else:
		raise Exception('unknown file type for: '+src)

def copy_files(srcs, destdir):
	for src in srcs:
		copy_recursive(src, destdir)

if len(sys.argv) < 3:
	print('Usage: copy_recursive.py FILE [FILE2 [...]] DIRECTORY')

copy_files(sys.argv[1:-1], sys.argv[-1])

