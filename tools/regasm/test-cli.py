#!/usr/bin/env python3
"""Black-box RegAsm CLI tests; the fixture has no COM-visible types."""

import argparse
import pathlib
import shutil
import subprocess
import tempfile
import unittest


class RegAsmTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="regasm-cli-")
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.directory = pathlib.Path(cls.temporary.name)
        cls.assembly = "No COM types.dll"
        shutil.copyfile(OPTIONS.assembly, cls.directory / cls.assembly)
        (cls.directory / "invalid.dll").write_text("Not a managed assembly")

    def invoke(self, arguments, expected=0):
        result = subprocess.run(
            COMMAND + arguments, cwd=self.directory, capture_output=True,
            text=True, errors="replace", timeout=30,
        )
        self.assertEqual(result.returncode, expected,
                         (arguments, result.stdout, result.stderr))
        return result

    def error(self, arguments, message):
        result = self.invoke(arguments, 100)
        self.assertIn(message, result.stderr)
        self.assertNotIn("successfully", result.stdout)
        return result

    def test_help(self):
        for option in ("/?", "/help", "-HELP", "/h"):
            with self.subTest(option=option):
                result = self.invoke([option])
                self.assertIn("Usage:", result.stdout)
                self.assertEqual(result.stderr, "")

    def test_missing_and_empty_arguments(self):
        self.error([], "No assembly file")
        self.error([""], "empty argument")
        self.error(["/"], "empty option")
        self.error(["-"], "empty option")

    def test_multiple_assemblies(self):
        self.error([self.assembly, "another.dll"], "More than one assembly")

    def test_unknown_and_ambiguous_options(self):
        self.error([self.assembly, "/unknown"], "Unknown option")
        for option in ("/r", "/reg"):
            with self.subTest(option=option):
                self.error([self.assembly, option], "Ambiguous option")

    def test_flag_values_are_rejected(self):
        for option in ("/codebase:ignored", "/u:ignored", "/s:ignored",
                       "/nologo:", "/help:ignored"):
            with self.subTest(option=option):
                self.error([self.assembly, option], "does not accept a value")

    def test_unsupported_options(self):
        for option in ("/tlb", "/t:output.tlb", "/regfile:output.reg",
                       "/registered", "/asmpath:references", "/verbose"):
            with self.subTest(option=option):
                self.error([self.assembly, option], "not implemented")
        self.assertFalse((self.directory / "output.tlb").exists())
        self.assertFalse((self.directory / "output.reg").exists())

    def test_missing_and_invalid_files(self):
        self.error(["missing.dll", "/nologo"], "RegAsm : error")
        self.error(["invalid.dll", "/nologo"], "RegAsm : error")

    def test_no_types(self):
        result = self.invoke([self.assembly, "/nologo"])
        self.assertIn("No types were registered", result.stdout)
        self.assertNotIn("successfully", result.stdout)
        self.assertEqual(result.stderr, "")
        result = self.invoke(["/unregister", self.assembly, "/nologo"])
        self.assertIn("No types were unregistered", result.stdout)
        self.assertNotIn("successfully", result.stdout)

    def test_case_prefixes_and_argument_order(self):
        result = self.invoke(["-N", "-C", self.assembly])
        self.assertIn("No types were registered", result.stdout)
        result = self.invoke(["/UN", self.assembly, "/NO"])
        self.assertIn("No types were unregistered", result.stdout)

    def test_silent_and_nologo(self):
        result = self.invoke([self.assembly])
        self.assertIn("Wine Mono Assembly Registration Tool", result.stdout)
        result = self.invoke([self.assembly, "/nologo"])
        self.assertNotIn("Wine Mono Assembly Registration Tool", result.stdout)
        result = self.invoke(["/S", self.assembly])
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")
        self.error(["/silent", "missing.dll"], "RegAsm : error")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assembly", type=pathlib.Path, required=True)
    parser.add_argument("command", nargs=argparse.REMAINDER,
                        help="[--] [mono or wine] /absolute/path/to/regasm.exe")
    OPTIONS = parser.parse_args()
    COMMAND = OPTIONS.command
    if COMMAND and COMMAND[0] == "--":
        COMMAND = COMMAND[1:]
    if not COMMAND:
        parser.error("a RegAsm command is required")
    # Tests change the child working directory; preserve executable paths.
    COMMAND = [str(pathlib.Path(arg).resolve()) if pathlib.Path(arg).is_file()
               else arg for arg in COMMAND]
    unittest.main(argv=[__file__], verbosity=2)
