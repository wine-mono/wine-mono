using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;

class CscWrapper
{

#if VERSION20
	const string VERSION_STRING = "2.0-api";
#elif VERSION40
	const string VERSION_STRING = "4.0-api";
#endif

	static string GetCorlibName()
	{
		Assembly corlib = Assembly.ReflectionOnlyLoad("mscorlib");
		return corlib.Location;
	}

	static int Main(string[] arguments)
	{
		var addStdlib = true;

		for (int i = 0; i< arguments.Length; i++)
		{
			if (arguments[i] == "/nostdlib" || arguments[i] == "-nostdlib")
			   addStdlib = false;
			arguments[i] = '"' + arguments[i] + '"';
		}

		string corlib = GetCorlibName();
		string current_lib = Path.GetDirectoryName(corlib);
		string api_lib = Path.Combine(Path.GetDirectoryName(current_lib), VERSION_STRING);
		string mcs_name = Path.Combine(current_lib, "mcs.exe");
		corlib = Path.Combine(api_lib, "mscorlib.dll");

		var versionArguments = "";
		if (addStdlib)
			versionArguments = String.Format("/nostdlib /r:{0} /lib:{1} ", corlib, api_lib);

		var process = new Process();
		process.StartInfo.FileName = mcs_name;
		process.StartInfo.Arguments = versionArguments + String.Join(" ", arguments);
		process.StartInfo.CreateNoWindow = true;
		process.StartInfo.UseShellExecute = false;
		process.StartInfo.RedirectStandardOutput = true;
		process.OutputDataReceived += (sender, args) => Console.WriteLine(args.Data);
		process.Start();
		process.BeginOutputReadLine();
		process.WaitForExit();
		return process.ExitCode;
	}
}

