// CSCFLAGS=-delaysign+ -keyfile:FNA/abi/xna4.pub
using System;
using System.Reflection;
using System.Runtime.CompilerServices;

[assembly: AssemblyVersion("4.0.0.0")]

namespace Microsoft.Xna.Framework.Input
{
	public static class Keyboard
	{
		public static KeyboardState GetState() { return default; }
	}

	public struct KeyboardState
	{
		public bool IsKeyDown(Keys key) { return false; }
	}

	public enum Keys
	{
		C = 67
	}
}

