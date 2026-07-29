// Sets the architecture of a .exe to the given CPU, mostly for testing purposes.

using System;
using System.Collections.Generic;

using Mono.Cecil;
using Mono.Cecil.Cil;

class FixupArch
{
	public static void Main (string[] args)
	{
		TargetArchitecture arch;
		switch (args[0]) {
		case "x86":
			arch = TargetArchitecture.I386;
			break;
		case "x86_64":
			arch = TargetArchitecture.AMD64;
			break;
		case "arm":
			arch = TargetArchitecture.ARMv7;
			break;
		case "arm64":
			arch = TargetArchitecture.ARM64;
			break;
		default:
			Console.WriteLine("fixuparch: Unknown architecture");
			return;
		}
		ReaderParameters mode = new ReaderParameters();
		mode.ReadWrite = true;

		for (int i=1; i<args.Length; i++)
		{
			string filename = args[i];
			var assembly = AssemblyDefinition.ReadAssembly(filename, mode);
			var module = assembly.MainModule;

			if (arch == TargetArchitecture.I386)
				module.Attributes |= ModuleAttributes.Required32Bit;
			module.Architecture = arch;
			module.Runtime = TargetRuntime.Net_4_0;

			assembly.Write();
		}
	}
}
