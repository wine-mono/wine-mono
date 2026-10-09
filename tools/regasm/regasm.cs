//
// Minimal RegAsm-compatible assembly registration tool for Wine Mono.
//
// Copyright 2026 YJBeetle
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//

using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

class RegAsm
{
	const int ErrorExitCode = 100;

	static bool unregister;
	static bool codeBase;
	static bool silent;
	static bool noLogo;
	static bool showHelp;
	static string assemblyFile;
	static readonly string[] optionNames = {
		"codebase", "unregister", "silent", "nologo", "help",
		"tlb", "regfile", "registered", "asmpath", "verbose"
	};

	static int Main (string[] arguments)
	{
		try {
			ParseArguments (arguments);
			if (showHelp) {
				PrintUsage ();
				return 0;
			}
			if (assemblyFile == null)
				throw new ArgumentException ("No assembly file was specified.");

			if (!noLogo && !silent)
				Console.WriteLine ("Wine Mono Assembly Registration Tool");

			string path = Path.GetFullPath (assemblyFile);
			Assembly assembly = Assembly.LoadFrom (path);
			RegistrationServices services = new RegistrationServices ();
			bool registered;
			if (unregister)
				registered = services.UnregisterAssembly (assembly);
			else
				registered = services.RegisterAssembly (assembly, codeBase ?
					AssemblyRegistrationFlags.SetCodeBase : AssemblyRegistrationFlags.None);

			if (!silent) {
				if (!registered)
					Console.WriteLine (unregister ? "No types were unregistered" : "No types were registered");
				else
					Console.WriteLine (unregister ?
						"Types unregistered successfully" : "Types registered successfully");
			}
			return 0;
		} catch (Exception exception) {
			Console.Error.WriteLine ("RegAsm : error RA0000 : {0}", GetMessage (exception));
			return ErrorExitCode;
		}
	}

	static void ParseArguments (string[] arguments)
	{
		foreach (string argument in arguments) {
			if (argument.Length == 0)
				throw new ArgumentException ("An empty argument was specified.");
			if (argument[0] != '/' && argument[0] != '-') {
				if (assemblyFile != null)
					throw new ArgumentException ("More than one assembly file was specified.");
				assemblyFile = argument;
				continue;
			}

			string option = argument.Substring (1);
			int separator = option.IndexOf (':');
			if (separator >= 0)
				option = option.Substring (0, separator);
			option = ResolveOption (option);
			if (option == "tlb" || option == "regfile" || option == "registered" ||
				option == "asmpath" || option == "verbose")
				throw new NotSupportedException ("The /" + option + " option is not implemented.");
			if (separator >= 0)
				throw new ArgumentException ("The /" + option + " option does not accept a value.");

			if (option == "unregister")
				unregister = true;
			else if (option == "codebase")
				codeBase = true;
			else if (option == "silent")
				silent = true;
			else if (option == "nologo")
				noLogo = true;
			else if (option == "help")
				showHelp = true;
		}
	}

	static string ResolveOption (string option)
	{
		if (option == "?")
			return "help";
		if (option.Length == 0)
			throw new ArgumentException ("An empty option was specified.");
		string match = null;
		foreach (string name in optionNames) {
			if (!name.StartsWith (option, StringComparison.OrdinalIgnoreCase))
				continue;
			if (match != null)
				throw new ArgumentException ("Ambiguous option: /" + option);
			match = name;
		}
		if (match == null)
			throw new ArgumentException ("Unknown option: /" + option);
		return match;
	}

	static string GetMessage (Exception exception)
	{
		while (exception is TargetInvocationException && exception.InnerException != null)
			exception = exception.InnerException;

		ReflectionTypeLoadException loadException = exception as ReflectionTypeLoadException;
		if (loadException != null && loadException.LoaderExceptions != null &&
			loadException.LoaderExceptions.Length != 0)
			foreach (Exception loaderException in loadException.LoaderExceptions)
				if (loaderException != null)
					return loadException.Message + " " + loaderException.Message;
		return exception.Message;
	}

	static void PrintUsage ()
	{
		Console.WriteLine ("Usage: regasm assemblyFile [options]");
		Console.WriteLine ("  /codebase          Record the assembly path in the registry");
		Console.WriteLine ("  /unregister, /u    Unregister the assembly");
		Console.WriteLine ("  /silent, /s        Suppress success messages");
		Console.WriteLine ("  /nologo            Suppress the startup banner");
		Console.WriteLine ("  /help, /?          Display this help");
		Console.WriteLine ("Options are case insensitive and may be abbreviated when unambiguous.");
		Console.WriteLine ("Type library export and .reg file generation are not implemented.");
	}
}
