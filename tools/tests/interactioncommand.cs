// CSCFLAGS=-r:Microsoft.VisualBasic.dll
using System;
using System.Diagnostics;
using System.Reflection;
using Microsoft.VisualBasic;

public class InteractionCommandTest
{
	public static void TestCommand (string cmd)
	{
		var process = new Process();
		process.StartInfo.FileName = Assembly.GetExecutingAssembly().Location;
		process.StartInfo.Arguments = cmd;
		process.StartInfo.UseShellExecute = false;
		process.StartInfo.EnvironmentVariables.Add ("EXPECTED_INTERACTION_COMMAND", "_" + cmd);
		process.Start ();
		process.WaitForExit ();
		if (process.ExitCode != 0)
		{
			Environment.Exit (1);
		}
	}

	public static int Main (string[] args)
	{
		if (Environment.GetEnvironmentVariable ("EXPECTED_INTERACTION_COMMAND") != null)
		{
			if (Environment.GetEnvironmentVariable ("EXPECTED_INTERACTION_COMMAND").Substring (1) != Interaction.Command ())
			{
				Console.WriteLine ("Expected '{0}' got '{1}'",
					Environment.GetEnvironmentVariable ("EXPECTED_INTERACTION_COMMAND").Substring (1),
					Interaction.Command ());
				return 1;
			}
		}
		else
		{
			TestCommand ("");
			TestCommand ("\"\"");
			TestCommand ("\"test with quotes\"");
			TestCommand ("test without quotes");
		}

		return 0;
	}
}
