using System;

class FloatConversionTest
{
	struct TestItem {
		public double r8;
		public float r4;
		public sbyte i1;
		public byte u1;
		public short i2;
		public ushort u2;
		public int i4;
		public uint u4;
		public long i8;
		public ulong u8;
		public TestItem(double r8, float r4, sbyte i1, byte u1, short i2, ushort u2, int i4, uint u4, long i8, ulong u8) {
			this.r8 = r8;
			this.r4 = r4;
			this.i1 = i1;
			this.u1 = u1;
			this.i2 = i2;
			this.u2 = u2;
			this.i4 = i4;
			this.u4 = u4;
			this.i8 = i8;
			this.u8 = u8;
		}
	}

	static bool DoTest (TestItem test)
	{
		bool result = true;
		if ((sbyte)test.r8 != test.i1)
		{
			Console.WriteLine($"double {test.r8} -> sbyte conversion failed, expected {test.i1}, got {(sbyte)test.r8}");
			result = false;
		}
		if ((byte)test.r8 != test.u1)
		{
			Console.WriteLine($"double {test.r8} -> byte conversion failed, expected {test.u1}, got {(byte)test.r8}");
			result = false;
		}
		if ((short)test.r8 != test.i2)
		{
			Console.WriteLine($"double {test.r8} -> short conversion failed, expected {test.i2}, got {(short)test.r8}");
			result = false;
		}
		if ((ushort)test.r8 != test.u2)
		{
			Console.WriteLine($"double {test.r8} -> ushort conversion failed, expected {test.u2}, got {(ushort)test.r8}");
			result = false;
		}
		if ((int)test.r8 != test.i4)
		{
			Console.WriteLine($"double {test.r8} -> int conversion failed, expected {test.i4}, got {(int)test.r8}");
			result = false;
		}
		if ((uint)test.r8 != test.u4)
		{
			Console.WriteLine($"double {test.r8} -> uint conversion failed, expected {test.u4}, got {(uint)test.r8}");
			result = false;
		}
		if ((long)test.r8 != test.i8)
		{
			Console.WriteLine($"double {test.r8} -> long conversion failed, expected {test.i8}, got {(long)test.r8}");
			result = false;
		}
		if ((ulong)test.r8 != test.u8)
		{
			Console.WriteLine($"double {test.r8} -> ulong conversion failed, expected {test.u8}, got {(ulong)test.r8}");
			result = false;
		}
		if ((sbyte)test.r4 != test.i1)
		{
			Console.WriteLine($"float {test.r4} -> sbyte conversion failed, expected {test.i1}, got {(sbyte)test.r4}");
			result = false;
		}
		if ((byte)test.r4 != test.u1)
		{
			Console.WriteLine($"float {test.r4} -> byte conversion failed, expected {test.u1}, got {(byte)test.r4}");
			result = false;
		}
		if ((short)test.r4 != test.i2)
		{
			Console.WriteLine($"float {test.r4} -> short conversion failed, expected {test.i2}, got {(short)test.r4}");
			result = false;
		}
		if ((ushort)test.r4 != test.u2)
		{
			Console.WriteLine($"float {test.r4} -> ushort conversion failed, expected {test.u2}, got {(ushort)test.r4}");
			result = false;
		}
		if ((int)test.r4 != test.i4)
		{
			Console.WriteLine($"float {test.r4} -> int conversion failed, expected {test.i4}, got {(int)test.r4}");
			result = false;
		}
		if ((uint)test.r4 != test.u4)
		{
			Console.WriteLine($"float {test.r4} -> uint conversion failed, expected {test.u4}, got {(uint)test.r4}");
			result = false;
		}
		if ((long)test.r4 != test.i8)
		{
			Console.WriteLine($"float {test.r4} -> long conversion failed, expected {test.i8}, got {(long)test.r4}");
			result = false;
		}
		if ((ulong)test.r4 != test.u8)
		{
			Console.WriteLine($"float {test.r4} -> ulong conversion failed, expected {test.u8}, got {(ulong)test.r4}");
			result = false;
		}
		return result;
	}

	static int Main()
	{
		var tests = new TestItem[] {
			new TestItem (2.0, 2.0f, 2, 2, 2, 2, 2, 2, 2, 2),
			new TestItem (-2.0, -2.0f, -2, 0xfe, -2, 0xfffe, -2, 0xfffffffe, -2, 0xfffffffffffffffe),
			new TestItem (0.9, 0.9f, 0, 0, 0, 0, 0, 0, 0, 0),
			new TestItem (-0.9, -0.9f, 0, 0, 0, 0, 0, 0, 0, 0),
			new TestItem (192.0, 192f, -64, 192, 192, 192, 192, 192, 192, 192),
			new TestItem (49152.0, 49152f, 0, 0, -16384, 49152, 49152, 49152, 49152, 49152),
			new TestItem (3221225472.0, 3221225472f, 0, 0, 0, 0, -2147483648, 3221225472, 3221225472, 3221225472),
			new TestItem (3221225472.0 * 4294967296.0, 3221225472.0f * 4294967296.0f, 0, 0, 0, 0, -2147483648, 0, -9223372036854775808, 13835058055282163712),
			new TestItem (-128.0, -128f, -128, 128, -128, 0xff80, -128, 0xffffff80, -128, 0xffffffffffffff80),
			new TestItem (-32768.0, -32768f, 0, 0, -32768, 0x8000, -32768, 0xffff8000, -32768, 0xffffffffffff8000),
			new TestItem (-2147483648.0, -2147483648f, 0, 0, 0, 0, -2147483648, 0x80000000, -2147483648, 0xffffffff80000000),
			new TestItem (-2147483648.0 * 4294967296.0, -2147483648f * 4294967296.0f, 0, 0, 0, 0, -2147483648, 0, -0x8000000000000000, 0x8000000000000000),
			new TestItem (double.PositiveInfinity, float.PositiveInfinity, 0, 0, 0, 0, -2147483648, 0, -0x8000000000000000, 0),
			new TestItem (double.NegativeInfinity, float.NegativeInfinity, 0, 0, 0, 0, -2147483648, 0, -0x8000000000000000, 0x8000000000000000),
			new TestItem (double.NaN, float.NaN, 0, 0, 0, 0, -2147483648, 0, -0x8000000000000000, 0),
			new TestItem (0.0, 0.0f, 0, 0, 0, 0, 0, 0, 0, 0)};
		bool success = true;

		foreach (var test in tests) {
			if (!DoTest(test))
				success = false;
		}

		return success ? 0 : 1;
	}
}

