using System;
using System.Threading;
using System.Runtime.InteropServices;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using System.Windows.Forms;

public class TestGame : Game
{
	[UnmanagedFunctionPointerAttribute(CallingConvention.StdCall)]
	private delegate IntPtr WndProcCallback(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

	private WndProcCallback _wndProc;
	private IntPtr _prevWndProc = IntPtr.Zero;
	private bool _keyAUp;
	private bool _charA;
	private bool _charB;
	private bool _focus;
	private bool _sent;

	public bool ASuccess {
		get { return _keyAUp && !_charA; }
	}

	public bool BSuccess {
		get { return _charB; }
	}

	public TestGame()
	{
		var g = new GraphicsDeviceManager(this);
	}

	[DllImport("user32.dll", CharSet = CharSet.Unicode)]
	public static extern IntPtr CallWindowProc(IntPtr lpPrevWndFunc, IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

	[DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	public static extern IntPtr SetWindowLongW(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

	[DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	public static extern IntPtr SetWindowLongPtrW(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

	public static IntPtr SetWindowLong(IntPtr hWnd, int nIndex, IntPtr dwNewLong)
	{
		if (IntPtr.Size == 8)
			return SetWindowLongPtrW(hWnd, nIndex, dwNewLong);
		return SetWindowLongW(hWnd, nIndex, dwNewLong);
	}

	public enum Msg : uint
	{
		WM_SETFOCUS		= 0x0007,
		WM_GETDLGCODE	= 0x0087,
		WM_KEYUP		= 0x0101,
		WM_CHAR			= 0x0102,
	}

	public const int DLGC_WANTALLKEYS = 4;
	public const int GWLP_WNDPROC = -4;

	private IntPtr WndProc(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam)
	{
		if (msg == (uint) Msg.WM_KEYUP && wParam == (IntPtr) 'A')
			_keyAUp = true;
		else if (msg == (uint) Msg.WM_CHAR && wParam == (IntPtr) 'A')
			_charA = true;
		else if (msg == (uint) Msg.WM_CHAR && wParam == (IntPtr) 'B')
			_charB = true;
		else if (msg == (uint) Msg.WM_SETFOCUS)
			_focus = true;
		else if (msg == (uint) Msg.WM_GETDLGCODE && _keyAUp)
			return (IntPtr) DLGC_WANTALLKEYS;

		return CallWindowProc(_prevWndProc, hWnd, msg, wParam, lParam);
	}

	protected override void Initialize()
	{
		_wndProc = WndProc;
		_prevWndProc = SetWindowLong(this.Window.Handle, GWLP_WNDPROC, Marshal.GetFunctionPointerForDelegate((Delegate)_wndProc));
	}

	protected override void Update(GameTime time)
	{
		if (_focus && !_sent)
		{
			SendKeys.SendWait("A");
			SendKeys.SendWait("B");
			_sent = true;

			InputForm.Test ();

			Exit();
		}

		base.Update(time);
	}
}

public class InputForm : Form
{
	public static bool success;

	public static void Test ()
	{
		var form = new InputForm();

		form.Show();

		System.Windows.Forms.Application.DoEvents();
	}

	protected override void OnGotFocus(EventArgs e)
	{
		SendKeys.SendWait("C");
		base.OnGotFocus(e);
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		if (e.KeyCode == System.Windows.Forms.Keys.C)
		{
			success = Keyboard.GetState().IsKeyDown(Microsoft.Xna.Framework.Input.Keys.C);
		}
		base.OnKeyDown(e);
	}
}

public class XnaTest
{
	public static int Main()
	{
		using (var game = new TestGame())
		{
			game.Run();
			if (!game.ASuccess || !game.BSuccess)
				return 1;
			if (!InputForm.success)
				return 2;
		}

		return 0;
	}
}
