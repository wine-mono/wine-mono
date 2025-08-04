using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Xml;

class RunTests
{
	string ExePath;
	string BasePath;

	string passing_output_path;
	string failing_output_path;

	// expected results
	HashSet<string> pass_list = new HashSet<string> ();
	HashSet<string> fail_list = new HashSet<string> ();
	Dictionary<string, List<string>> skip_list = new Dictionary<string, List<string>> ();
	Dictionary<string, List<string>> run_list = new Dictionary<string, List<string>> ();
	List<string> skip_categories = new List<string> ();

	int timeout = 300;
	bool timeout_specified;

	// actual results
	List<string> passing_tests = new List<string> ();
	List<string> failing_tests = new List<string> ();

	bool test_timed_out;

	bool nodefaults;

	RunTests ()
	{
		ExePath = Environment.GetCommandLineArgs()[0];
		BasePath = Path.GetDirectoryName(ExePath);
	}

	void process_mono_test_output(object o)
	{
		var t = (Tuple<Process,string,bool>)o;
		Process p = t.Item1;
		string test_assembly = t.Item2;
		bool any_skips = t.Item3;
		string line;
		string current_test = null;
		bool any_passed = false;
		bool any_failed = false;
		bool comparison_failed = false;
		List<string> lines = new List<string>();

		while ((line = p.StandardOutput.ReadLine ()) != null)
		{
			lines.Add(line);
			Console.WriteLine(line);
			if (line.StartsWith("Running '") && line.EndsWith("' ..."))
			{
				if (current_test != null)
				{
					passing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
					any_passed = true;
				}
				current_test = line.Substring(9, line.Length - 14);
			}
			else if (line.StartsWith(String.Format("{0} failed: got ", current_test)))
			{
				failing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
				current_test = null;
				any_failed = true;
			}
			else if (line.StartsWith("Regression tests: ") &&
				line.Contains(" ran, ") && line.Contains(" failed in "))
			{
				if (current_test != null)
				{
					passing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
					any_passed = true;
					current_test = null;
				}
			}
		}

		if (current_test != null)
		{
			p.WaitForExit();
			failing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
			any_failed = true;
		}

		if (File.Exists(p.StartInfo.FileName + ".expected")) {
			var expected_lines = new List<string>(File.ReadLines(p.StartInfo.FileName + ".expected"));

			if (expected_lines.Count != lines.Count)
				comparison_failed = true;
			else {
				for (int i=0; i<lines.Count; i++) {
					if (lines[i] != expected_lines[i]) {
						comparison_failed = true;
						break;
					}
				}
			}
		}

		if (test_timed_out)
		{
			failing_tests.Add(test_assembly);
			Console.WriteLine("Test timed out: {0}", test_assembly);
		}
		else if (comparison_failed)
		{
			failing_tests.Add(test_assembly);
			Console.WriteLine("Test failed(output did not match .exe.expected file): {0}", test_assembly);
		}
		else if (any_skips)
		{
			if (any_passed || any_failed)
				Console.WriteLine("Some tests skipped: {0}", test_assembly);
			else	
				Console.WriteLine("All tests skipped: {0}", test_assembly);
		}
		else if (p.ExitCode == 0 && !any_failed)
		{
			passing_tests.Add(test_assembly);
			Console.WriteLine("Test succeeded: {0}", test_assembly);
		}
		else if (any_passed)
		{
			Console.WriteLine("Some tests succeeded: {0}", test_assembly);
		}
		else
		{
			failing_tests.Add(test_assembly);
			Console.WriteLine("Test failed({0}): {1}", p.ExitCode, test_assembly);
		}
	}

	void run_mono_test_exe(string path, string arch)
	{
		string testname = Path.GetFileNameWithoutExtension(path);
		string fulltestname = String.Format("{0}.{1}", arch, testname);
		bool any_skips = false;
		test_timed_out = false;

		List<string> runs = new List<string> ();
		if (run_list.Count != 0)
		{
			bool run=false;
			if (run_list.ContainsKey(testname))
			{
				run = true;
				if (run_list[testname] != null)
				{
					runs.AddRange(run_list[testname]);
				}
			}
			if (run_list.ContainsKey(fulltestname))
			{
				run = true;
				if (run_list[fulltestname] != null)
				{
					runs.AddRange(run_list[fulltestname]);
				}
			}
			if (!run)
				return;
		}

		List<string> skips = new List<string> ();
		if (skip_list.ContainsKey(testname))
		{
			if (skip_list[testname] == null)
			{
				Console.WriteLine("Skipping {0}", fulltestname);
				return;
			}
			skips.AddRange(skip_list[testname]);
		}
		if (skip_list.ContainsKey(fulltestname))
		{
			if (skip_list[fulltestname] == null)
			{
				Console.WriteLine("Skipping {0}", fulltestname);
				return;
			}
			skips.AddRange(skip_list[fulltestname]);
		}

		Console.WriteLine("Starting test: {0}", fulltestname);
		Process p = new Process ();
		p.StartInfo = new ProcessStartInfo (path);
		p.StartInfo.Arguments = "--verbose";
		foreach (string test in skips)
		{
			p.StartInfo.Arguments = String.Format("{0} --exclude-test \"{1}\"",
				p.StartInfo.Arguments, test);
			any_skips = true;
		}
		foreach (string test in runs)
		{
			p.StartInfo.Arguments = String.Format("{0} --run-only \"{1}\"",
				p.StartInfo.Arguments, test);
			any_skips = true;
		}
		p.StartInfo.UseShellExecute = false;
		p.StartInfo.RedirectStandardOutput = true;
		p.StartInfo.WorkingDirectory = Path.GetDirectoryName(path);
		p.Start();
		Thread t = new Thread(process_mono_test_output);
		t.Start(Tuple.Create(p, fulltestname, any_skips));
		p.WaitForExit(timeout * 1000);
		if (!p.HasExited)
		{
			test_timed_out = true;
			p.Kill();
		}
		t.Join(10 * 1000);
		if (t.IsAlive)
		{
			p.StandardOutput.Close();
			t.Join();
		}
	}

	void run_mono_test_dir(string path, string arch)
	{
		foreach (string filename in Directory.EnumerateFiles(path, "*.exe"))
		{
			run_mono_test_exe(filename, arch);
		}
	}

	string get_nunit_lite_console(string arch)
	{
		string basename;
		if (arch == "x86")
			basename = "nunit-lite-console32.exe";
		else
			basename = "nunit-lite-console.exe";

		return Path.Combine(BasePath, "tests-clr", basename);
	}

	List<Tuple<string, List<string>>> get_clr_test_fixtures(string fulltestname, string filename, string arch)
	{
		var fixtures = new List<Tuple<string, List<string>>>();

		using (var reader = XmlReader.Create(filename + ".testlist"))
		{
			List<string> testlist = null;
			while (reader.Read())
			{
				if (reader.NodeType == XmlNodeType.Element &&
					reader.Name == "test-suite" &&
					reader["type"] != "Assembly")
				{
					testlist = new List<string>();
					fixtures.Add(Tuple.Create(reader["fullname"], testlist));
				}
				else if (reader.NodeType == XmlNodeType.EndElement &&
					reader.Name == "test-suite")
				{
					testlist = null;
				}
				else if (reader.NodeType == XmlNodeType.Element &&
					reader.Name == "test-case" &&
					testlist != null)
				{
					testlist.Add(reader["name"]);
				}
			}
		}

		return fixtures;
	}

	bool should_run_fixture(string fixture, string arch, bool run_all)
	{
		bool result = (run_all || run_list.Count == 0);

		int pos=-1;
		while ((pos = fixture.IndexOf('.', pos+1)) != -1)
		{
			string prefix = fixture.Substring(0, pos);
			if (run_list.ContainsKey(prefix) ||
				run_list.ContainsKey(String.Format("{0}.{1}", arch, prefix)))
				result = true;
			if (skip_list.ContainsKey(prefix) ||
				skip_list.ContainsKey(String.Format("{0}.{1}", arch, prefix)))
				result = false;
		}

		if (run_list.ContainsKey(fixture))
			result = true;

		if (skip_list.ContainsKey(fixture) && skip_list[fixture] == null)
			result = false;

		string fullfixture = String.Format("{0}.{1}", arch, fixture);

		if (run_list.ContainsKey(fullfixture))
			return true;

		if (skip_list.ContainsKey(fullfixture) && skip_list[fullfixture] == null)
			return false;

		return result;
	}

	void run_clr_test_list(string testname, string filename, string arch, List<string> to_run, ref bool any_passed, ref bool any_failed, ref bool any_skipped)
	{
		string fulltest = String.Format("{0}.{1}", arch, testname);
		string outputfile = Path.GetTempFileName();

		try
		{
			using (Process p = new Process())
			{
				p.StartInfo = new ProcessStartInfo(get_nunit_lite_console(arch));
				p.StartInfo.Arguments = String.Format("{0} -labels -format:nunit3 \"-result:{1}\"", Path.GetFileName(filename), outputfile);
				var testlist = Path.GetTempFileName();
				var sw = new StreamWriter(testlist);
				try
				{
					using (sw)
					{
						foreach (string test in to_run)
						{
							sw.WriteLine(test);
						}
					}
					p.StartInfo.Arguments += String.Format(" -testlist:\"{0}\"", testlist);
					foreach (string cat in skip_categories)
					{
						p.StartInfo.Arguments += String.Format(" -exclude:{0}", cat);
					}
					p.StartInfo.UseShellExecute = false;
					p.StartInfo.WorkingDirectory = Path.GetDirectoryName(filename);
					p.Start();
					p.WaitForExit(timeout * 1000);
				}
				finally
				{
					File.Delete(testlist);
				}
				if (!p.HasExited)
				{
					p.Kill();
					Console.WriteLine("Test timed out: {0}", fulltest);
					failing_tests.Add(fulltest);
					any_failed = true;
					return;
				}
				int num_tests_run = 0;
				try
				{
					using (var reader = XmlReader.Create(outputfile))
					{
						bool in_failure = false;
						string fullfixture = null;
						while (reader.Read())
						{
							if (reader.NodeType == XmlNodeType.Element && 
								reader.Name == "test-suite")
							{
								fullfixture = string.Format("{0}.{1}", arch, reader["fullname"]);
							}
							else if (reader.NodeType == XmlNodeType.Element &&
								reader.Name == "test-case")
							{
								if (reader["result"] == "Passed")
								{
									any_passed = true;
									num_tests_run++;
									passing_tests.Add(String.Format("{0}:{1}", fullfixture, reader["name"]));
								}
								else if (reader["result"] == "Failed")
								{
									any_failed = true;
									in_failure = true;
									num_tests_run++;
									failing_tests.Add(String.Format("{0}:{1}", fullfixture, reader["name"]));
									Console.WriteLine("{0}:{1} failed:", fullfixture, reader["name"]);
								}
							}
							else if (reader.NodeType == XmlNodeType.EndElement &&
									 reader.Name == "test-case")
							{
								in_failure = false;
							}
							else if (in_failure &&
									 (reader.NodeType == XmlNodeType.Text ||
									  reader.NodeType == XmlNodeType.CDATA))
							{
								Console.WriteLine(reader.Value);
							}
						}
					}
				}
				catch (XmlException)
				{
					failing_tests.Add(fulltest);
					Console.WriteLine("Test failed(couldn't read test results): {0}", fulltest);
					return;
				}
				if (num_tests_run < to_run.Count)
					any_skipped = true;
				if (!any_failed && p.ExitCode != 0)
				{
					failing_tests.Add(fulltest);
					Console.WriteLine("Test failed({0}): {1}", p.ExitCode, fulltest);
					any_failed = true;
				}
			}
		}
		finally
		{
			File.Delete(outputfile);
		}
	}

	void collect_clr_tests(string filename, string fixture, string arch, List<string> testlist, bool run_all, List<string> to_run)
	{
		string fullfixture = String.Format("{0}.{1}", arch, fixture);

		List<string> runs = new List<string> ();
		if (run_list.ContainsKey(fixture) && run_list[fixture] != null)
			runs.AddRange(run_list[fixture]);
		if (run_list.ContainsKey(fullfixture) && run_list[fullfixture] != null)
			runs.AddRange(run_list[fullfixture]);

		if (runs.Count == 0)
			run_all = true;

		List<string> skips = new List<string> ();
		if (skip_list.ContainsKey(fixture) && skip_list[fixture] != null)
			skips.AddRange(skip_list[fixture]);
		if (skip_list.ContainsKey(fullfixture) && skip_list[fullfixture] != null)
			skips.AddRange(skip_list[fullfixture]);

		foreach (string test in testlist)
		{
			if ((run_all || runs.Contains(test)) && !skips.Contains(test))
			{
				to_run.Add(String.Format("{0}.{1}", fixture, test));
			}
		}
	}

	void run_clr_tests(string testname, string filename, string arch, List<string> to_run)
	{
		string fulltest = String.Format("{0}.{1}", arch, filename);

		Console.WriteLine("Running {0}", fulltest);

		bool any_passed = false;
		bool any_failed = false;
		bool any_skipped = false;

		run_clr_test_list(testname, filename, arch, to_run, ref any_passed, ref any_failed, ref any_skipped);

		if (any_passed)
		{
			if (!any_failed && !any_skipped)
			{
				Console.WriteLine("Test succeeded: {0}", fulltest);
			}
			else
			{
				Console.WriteLine("Some tests succeeded: {0}", fulltest);
			}
		}
		else if (any_failed)
		{
			Console.WriteLine("Some tests failed: {0}", fulltest);
		}
		else
		{
			Console.WriteLine("All tests skipped: {0}", fulltest);
		}
	}

	void run_clr_test_dll(string filename, string arch)
	{
		string basename = Path.GetFileNameWithoutExtension(filename);
		string testname = basename.Substring(8, basename.LastIndexOf('_') - 8);
		string fulltestname = String.Format("{0}.{1}", arch, testname);
		bool run_all;
		List<string> tests_to_run = new List<string>();
		
		if (skip_list.ContainsKey(testname) ||
			skip_list.ContainsKey(fulltestname))
		{
			Console.WriteLine("Skipping {0}", fulltestname);
			return;
		}

		run_all = (run_list.ContainsKey(testname) || run_list.ContainsKey(fulltestname));

		var fixtures = get_clr_test_fixtures(fulltestname, filename, arch);

		if (fixtures == null)
			return;

		string nunitlite_config = filename+".nunitlite.config";
		string exe_config = null;

		foreach (var t in fixtures)
		{
			string testfixture = t.Item1;
			var testlist = t.Item2;

			if (should_run_fixture(testfixture, arch, run_all))
				collect_clr_tests(filename, testfixture, arch, testlist, run_all, tests_to_run);
		}

		if (tests_to_run.Count == 0) {
			return;
		}

		bool copied_config = false;

		if (File.Exists(nunitlite_config))
		{
			exe_config = get_nunit_lite_console(arch)+".config";
			File.Copy(nunitlite_config, exe_config, true);
			copied_config = true;
		}

		run_clr_tests(testname, filename, arch, tests_to_run);

		if (copied_config) {
			File.Delete(exe_config);
		}
	}

	void run_clr_test_dir(string path, string arch)
	{
		foreach (string filename in Directory.EnumerateFiles(path, "net_4_x_*_test.dll"))
		{
			run_clr_test_dll(filename, arch);
		}
		foreach (string filename in Directory.EnumerateFiles(path, "net_4_x_*_vbtest.dll"))
		{
			run_clr_test_dll(filename, arch);
		}
	}

	void add_to_testlist(string str, Dictionary<string, List<string>> testlist)
	{
		if (str.Contains(":"))
		{
			int index = str.IndexOf(':');
			string assembly = str.Substring(0, index);
			string test = str.Substring(index+1);
			List <string> l;
			if (!testlist.TryGetValue(assembly, out l) || l == null)
			{
				l = testlist[assembly] = new List<string>();
			}
			l.Add(test);
		}
		else
		{
			if (!testlist.ContainsKey(str))
				testlist.Add(str, null);
		}
	}

	void read_testlist(string filename, Dictionary<string, List<string>> testlist)
	{
		using (StreamReader sr = new StreamReader(filename))
		{
			string line;
			while ((line = sr.ReadLine()) != null)
			{
				if (line.Contains("#"))
				{
					line = line.Substring(0, line.IndexOf('#'));
				}
				foreach (string test in line.Split(new char[] {' '}))
				{
					string trtest = test.Trim();
					if (trtest != "")
						add_to_testlist(trtest, testlist);
				}
			}
		}
	}

	void read_stringlist(string filename, HashSet<string> testlist)
	{
		using (StreamReader sr = new StreamReader(filename))
		{
			string line;
			while ((line = sr.ReadLine()) != null)
			{
				if (line.Contains("#"))
				{
					line = line.Substring(0, line.IndexOf('#'));
				}
				foreach (string test in line.Split(new char[] {' '}))
				{
					string trtest = test.Trim();
					if (trtest != "")
						testlist.Add(trtest);
				}
			}
		}
	}

	static bool IsRunningOnWindows()
	{
		return Environment.OSVersion.Platform == PlatformID.Win32NT;
	}

	[DllImport ("kernel32", CallingConvention=CallingConvention.StdCall)]
	extern static IntPtr GetModuleHandleW([MarshalAs(UnmanagedType.LPWStr)] string name);

	[DllImport ("kernel32", CallingConvention=CallingConvention.StdCall)]
	extern static IntPtr GetProcAddress(IntPtr module, [MarshalAs(UnmanagedType.LPStr)] string procname);

	static bool IsRunningOnWine()
	{
		if (!IsRunningOnWindows())
			return false;

		return IntPtr.Zero != GetProcAddress(GetModuleHandleW("ntdll"), "wine_get_version");
	}

	[DllImport ("shell32", CallingConvention=CallingConvention.StdCall)]
	extern static bool IsUserAnAdmin();

	[DllImport ("ntdll", CallingConvention=CallingConvention.Cdecl)]
	extern static string wine_get_version();

	[DllImport ("ntdll", CallingConvention=CallingConvention.Cdecl)]
	extern static void wine_get_host_version(out string sysname, out string release);

	int process_arguments(string[] arguments)
	{
		foreach (string argument in arguments)
		{
			if (argument.StartsWith("-write-passing:"))
				passing_output_path = argument.Substring(15);
			else if (argument.StartsWith("-write-failing:"))
				failing_output_path = argument.Substring(15);
			else if (argument.StartsWith("-skip:"))
				add_to_testlist(argument.Substring(6), skip_list);
			else if (argument.StartsWith("-skip-list:"))
				read_testlist(argument.Substring(11), skip_list);
			else if (argument.StartsWith("-skip-category:"))
				skip_categories.Add(argument.Substring(15));
			else if (argument.StartsWith("-run:"))
				add_to_testlist(argument.Substring(5), run_list);
			else if (argument.StartsWith("-run-list:"))
				read_testlist(argument.Substring(10), run_list);
			else if (argument.StartsWith("-pass-list:"))
				read_stringlist(argument.Substring(11), pass_list);
			else if (argument.StartsWith("-fail-list:"))
				read_stringlist(argument.Substring(11), fail_list);
			else if (argument.StartsWith("-timeout:"))
			{
				timeout = int.Parse(argument.Substring(9));
				timeout_specified = true;
			}
			else if (argument == "-nodefaults")
				nodefaults = true;
			else if (!argument.StartsWith("-"))
				add_to_testlist(argument, run_list);
			else
			{
				Console.WriteLine("Unrecognized argument: {0}", argument);
				return 1;
			}
		}
		return 0;
	}

	int main(string[] arguments)
	{
		int result;

		result = process_arguments(arguments);
		if (result != 0)
			return result;

		if (!nodefaults && IsRunningOnWindows())
		{
			read_testlist(Path.Combine(BasePath, "skip-always.txt"), skip_list);

			if (IsRunningOnWine())
			{
				read_testlist(Path.Combine(BasePath, "windows-failing.txt"), skip_list);
				read_testlist(Path.Combine(BasePath, "skip-wine.txt"), skip_list);
				read_stringlist(Path.Combine(BasePath, "wine-passing.txt"), pass_list);
				read_stringlist(Path.Combine(BasePath, "wine-failing.txt"), fail_list);
				switch (wine_get_version())
				{
				case "6.7":
					// Winehq bug 51067
					fail_list.Add("x86_64.MonoTests.Microsoft.Build.Utilities.ToolTaskTest:Execute_2");
					fail_list.Add("x86_64.MonoTests.Microsoft.Build.Utilities.ToolTaskTest");
					break;
				case "6.12":
					// Winehq bug 51366
					fail_list.Add("MonoTests.System.Net.HttpWebRequestTest:TestTimeoutWithEndpointThatDoesntExistThrowsConnectFailureBeforeTimeout");
					add_to_testlist("MonoTests.System.Net.Sockets.SocketTest:ConnectFailAsync", skip_list);
					add_to_testlist("MonoTests.System.Net.Sockets.SocketTest:BogusEndConnect", skip_list);
					fail_list.Add("MonoTests.System.Net.Sockets.SocketTest:BeginConnectMultiple");
					fail_list.Add("MonoTests.System.Net.WebRequestTest:TestFailedConnection");
					break;
				case "7.4":
				case "7.5":
					// Winehq bug 52672
					fail_list.Add("x86.wpfclipboard");
					fail_list.Add("x86.MonoTests.System.Windows.DependencyObjectTest");
					fail_list.Add("x86.MonoTests.System.Windows.DependencyObjectTypeTest");
					fail_list.Add("x86.MonoTests.System.Windows.Threading.DispatcherTest");
					fail_list.Add("x86.MonoTests.System.Windows.Threading.DispatcherTimerTest");
					break;
				default:
					break;
				}
				wine_get_host_version(out var sysname, out var release);
				switch (sysname)
				{
				case "Linux":
					read_stringlist(Path.Combine(BasePath, "wine-linux-passing.txt"), pass_list);
					read_stringlist(Path.Combine(BasePath, "wine-linux-failing.txt"), fail_list);
					read_testlist(Path.Combine(BasePath, "skip-linux.txt"), skip_list);
					break;
				case "Darwin": // macOS
					read_stringlist(Path.Combine(BasePath, "wine-macos-passing.txt"), pass_list);
					read_stringlist(Path.Combine(BasePath, "wine-macos-failing.txt"), fail_list);
					read_testlist(Path.Combine(BasePath, "skip-macos.txt"), skip_list);
					if (!timeout_specified)
						timeout = 600;
					break;
				default:
					Console.WriteLine($"unknown host OS: {sysname}");
					break;
				}
			}
			else
			{
				read_stringlist(Path.Combine(BasePath, "windows-passing.txt"), pass_list);
				read_stringlist(Path.Combine(BasePath, "windows-failing.txt"), fail_list);
				if (IsUserAnAdmin())
					read_stringlist(Path.Combine(BasePath, "windows-admin.txt"), pass_list);
				else
					read_stringlist(Path.Combine(BasePath, "windows-admin.txt"), fail_list);
				read_testlist(Path.Combine(BasePath, "skip-windows.txt"), skip_list);
			}
		}

		run_mono_test_dir(Path.Combine(BasePath, "tests-x86"), "x86");
		run_mono_test_dir(Path.Combine(BasePath, "tests-x86_64"), "x86_64");
		run_clr_test_dir(Path.Combine(BasePath, "tests-clr"), "x86");
		run_clr_test_dir(Path.Combine(BasePath, "tests-clr"), "x86_64");

		result = failing_tests.Count;

		if (!String.IsNullOrEmpty(passing_output_path))
		{
			using (var f = new StreamWriter(passing_output_path))
			{
				foreach (string name in passing_tests)
					f.WriteLine(name);
			}
		}

		if (!String.IsNullOrEmpty(failing_output_path))
		{
			using (var f = new StreamWriter(failing_output_path))
			{
				foreach (string name in failing_tests)
					f.WriteLine(name);
			}
		}

		if (pass_list.Count != 0)
		{
			var unexpected_pass = new List<string> ();
			foreach (string name in passing_tests)
				if (!pass_list.Contains(name) &&
					!pass_list.Contains(name.Split(new char[]{'.'}, 2)[1]))
					unexpected_pass.Add(name);
			if (unexpected_pass.Count != 0)
			{
				Console.WriteLine("The following tests passed but were not in pass-list:");
				Console.WriteLine();
				foreach (string name in unexpected_pass)
					Console.WriteLine(name);
				Console.WriteLine();
			}
		}

		if (fail_list.Count != 0)
		{
			var unexpected_fail = new List<string> ();
			foreach (string name in failing_tests)
				if (!fail_list.Contains(name) &&
					!fail_list.Contains(name.Split(new char[]{'.'}, 2)[1]))
					unexpected_fail.Add(name);
			if (unexpected_fail.Count != 0)
			{
				Console.WriteLine("The following tests failed but were not in fail-list:");
				Console.WriteLine();
				foreach (string name in unexpected_fail)
					Console.WriteLine(name);
				Console.WriteLine();
			}
			result = unexpected_fail.Count;
		}

		Console.WriteLine("{0} tests passed, {1} tests failed",
			passing_tests.Count, failing_tests.Count);

		if (passing_tests.Count == 0 && failing_tests.Count == 0)
		{
			Console.WriteLine("No tests were run.");
			result = 1;
		}

		if (result > 255)
			result = 255;

		return result;
	}

	static int Main(string[] arguments)
	{
		RunTests instance = new RunTests();
		return instance.main(arguments);
	}
}
