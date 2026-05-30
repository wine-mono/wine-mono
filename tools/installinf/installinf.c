/* installinf - Use setupapi to install a .inf file.
 *
 * We cannot use rundll32 for this because Wine Mono may be installed before it is created. */

#include <stdlib.h>
#include <wchar.h>
#include <windows.h>
#include <setupapi.h>

int wmain(int argc, wchar_t **argv)
{
	wchar_t* buf;
	const wchar_t* prefix = L"DefaultInstall 128 ";

	size_t prefix_len = wcslen(prefix);
	size_t arg_len = wcslen(argv[1]);

	if (arg_len > (SIZE_MAX / sizeof(wchar_t)) - prefix_len - 1)
		return 1;

	buf = calloc(prefix_len + arg_len + 1, sizeof(wchar_t));

	wcscpy(buf, prefix);
	wcscat(buf, argv[1]);

	InstallHinfSectionW(NULL, NULL, buf, 0);

	return 0;
}
