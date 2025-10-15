// CSCFLAGS=-delaysign+ -keyfile:FNA/abi/xna4.pub
using System;
using System.Reflection;
using System.Runtime.CompilerServices;

[assembly: AssemblyVersion("4.0.0.0")]

namespace Microsoft.Xna.Framework
{
	public abstract class GameWindow
	{
		public abstract IntPtr Handle { get; }
	}

	public class GraphicsDeviceManager
	{
		public GraphicsDeviceManager (Game game)
		{
		}
	}

	public class Game : IDisposable
	{
		public void Dispose()
		{
		}

		public void Exit()
		{
		}

		public void Run()
		{
		}

		public GameWindow Window { get; }

		protected virtual void Initialize ()
		{
		}

		protected virtual void Update (GameTime gameTime)
		{
		}
	}

	public class GameTime
	{
	}
}

