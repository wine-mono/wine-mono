// CSCFLAGS=-r:System.Windows.Forms.dll -r:Microsoft.VisualBasic.dll
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Windows.Forms;
using Microsoft.VisualBasic.ApplicationServices;

namespace vbstartup
{
	class VbStartupTest : WindowsFormsApplicationBase
	{
		static List<string> log = new List<string> ();

		static string[] expected_log = new string[] {
			"enter Main",
			"Main calling Run",
			"base OnInitialize",
			"base OnCreateSplashScreen",
			"exit OnCreateSplashScreen",
			"exit OnInitialize",
			"base OnStartup",
			"Startup event",
			"exit OnStartup",
			"base OnRun",
			"base OnCreateMainForm",
			"our OnCreateMainForm",
			"exit OnCreateMainForm",
			"Form Shown event",
			"Form closed",
			"exit OnRun",
			"base OnShutdown",
			"Shutdown event",
			"exit OnShutdown"
			};

		public static void LogEvent (string str)
		{
			Console.WriteLine (str);
			log.Add (str);
		}

		public static int Main (string[] args)
		{
			LogEvent("enter Main");
			var app = new VbStartupTest ();
			app.Shutdown += new ShutdownEventHandler(app.ShutdownEH);
			app.Startup += new StartupEventHandler(app.StartupEH);
			app.StartupNextInstance += new StartupNextInstanceEventHandler(app.StartupNextInstanceEH);

			LogEvent("Main calling Run");
			app.Run(args);

			if (log.Count != expected_log.Length)
				return 1;
			for (int i=0; i < log.Count; i++)
			{
				if (log[i] != expected_log[i])
					return i+2;
			}
			return 0;
		}

		private void FormShownEH(object sender, EventArgs e)
		{
			LogEvent("Form Shown event");
			((Form)sender).Close();
			LogEvent("Form closed");
		}

		protected override void OnCreateMainForm ()
		{
			LogEvent("base OnCreateMainForm");
			base.OnCreateMainForm ();
			LogEvent("our OnCreateMainForm");
			MainForm = new Form ();
			MainForm.Shown += FormShownEH;
			LogEvent("exit OnCreateMainForm");
		}

		protected override void OnCreateSplashScreen ()
		{
			LogEvent("base OnCreateSplashScreen");
			base.OnCreateSplashScreen ();
			LogEvent("exit OnCreateSplashScreen");
		}

		protected override bool OnInitialize (ReadOnlyCollection<string> args)
		{
			LogEvent("base OnInitialize");
			base.OnInitialize (args);
			LogEvent("exit OnInitialize");
			return true;
		}

		protected override void OnRun ()
		{
			LogEvent("base OnRun");
			base.OnRun ();
			LogEvent("exit OnRun");
		}

		protected override void OnShutdown ()
		{
			LogEvent("base OnShutdown");
			base.OnShutdown ();
			LogEvent("exit OnShutdown");
		}

		protected override bool OnStartup (StartupEventArgs args)
		{
			LogEvent("base OnStartup");
			base.OnStartup (args);
			LogEvent("exit OnStartup");
			return true;
		}

		protected override void OnStartupNextInstance (StartupNextInstanceEventArgs args)
		{
			LogEvent("base OnStartupNextInstance");
			base.OnStartupNextInstance (args);
			LogEvent("exit OnStartupNextInstance");
		}

		public void ShutdownEH(object sender, EventArgs e)
		{
			LogEvent("Shutdown event");
		}

		public void StartupEH(object sender, StartupEventArgs e)
		{
			LogEvent("Startup event");
		}

		public void StartupNextInstanceEH(object sender, StartupNextInstanceEventArgs e)
		{
			LogEvent("StartupNextInstance event");
		}
	}
}
