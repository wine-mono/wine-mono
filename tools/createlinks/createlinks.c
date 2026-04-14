/* createlinks - Create symlinks when installing the runtime msi */

#include <stdlib.h>
#include <wchar.h>
#include <windows.h>
#include <msiquery.h>

UINT WINAPI create_links(MSIHANDLE hInst) {
	MSIHANDLE db, view, record;
	UINT ret;
	WCHAR directory[MAX_PATH], path[MAX_PATH], basename[MAX_PATH], link_abs[MAX_PATH];
	WCHAR target_directory[MAX_PATH], target_path[MAX_PATH], target_basename[MAX_PATH], target_abs[MAX_PATH];
	DWORD size;

	db = MsiGetActiveDatabase(hInst);

	if (db)
	{
		ret = MsiDatabaseOpenViewW(db, L"SELECT * FROM `Symlinks`", &view);

		if (ret == ERROR_SUCCESS)
		{
			ret = MsiViewExecute(view, 0);

			while (ret == ERROR_SUCCESS &&
				(ret=MsiViewFetch(view, &record)) == ERROR_SUCCESS &&
				record)
			{
				size = MAX_PATH;
				ret = MsiRecordGetStringW(record, 2, basename, &size);

				size = MAX_PATH;
				if (ret == ERROR_SUCCESS)
					ret = MsiRecordGetStringW(record, 3, directory, &size);

				size = MAX_PATH;
				if (ret == ERROR_SUCCESS)
					ret = MsiGetTargetPathW(hInst, directory, path, &size);

				if (ret == ERROR_SUCCESS)
				{
					swprintf_s(link_abs, MAX_PATH, L"%s%s", path, basename);

					size = MAX_PATH;
					ret = MsiRecordGetStringW(record, 4, target_basename, &size);
				}

				size = MAX_PATH;
				if (ret == ERROR_SUCCESS)
					ret = MsiRecordGetStringW(record, 5, target_directory, &size);

				size = MAX_PATH;
				if (ret == ERROR_SUCCESS)
					ret = MsiGetTargetPathW(hInst, target_directory, target_path, &size);

				if (ret == ERROR_SUCCESS)
				{
					swprintf_s(target_abs, MAX_PATH, L"%s%s", target_path, target_basename);

					if (!CreateSymbolicLinkW(link_abs, target_abs, 0))
						ret = ERROR_INSTALL_FAILURE;
				}

				MsiCloseHandle(record);
			}

			if (ret == ERROR_NO_MORE_ITEMS)
				ret = ERROR_SUCCESS;

			MsiCloseHandle(view);
		}

		MsiCloseHandle(db);
	}

	return ret == ERROR_SUCCESS ? ERROR_SUCCESS : ERROR_INSTALL_FAILURE;
}
