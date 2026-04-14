using Mono.Unix;
using System;
using System.IO;
using System.Security.Cryptography;

class GetFileHashes
{
    static int ConvertInt32(byte[] buffer, int index) {
        return(buffer[index] | (buffer[index+1] << 8) |
               (buffer[index+2] << 16) | (buffer[index+3] << 24));
    }

    static string FormatMd5Hash(string path)
    {
        byte[] hashvalue;

        using (MD5 hashalg = MD5.Create())
        {
            using (var stream = new FileStream(path, FileMode.Open))
            {
                hashvalue = hashalg.ComputeHash(stream);
            }
        }

        return string.Format("{0}\t{1}\t{2}\t{3}",
            ConvertInt32(hashvalue, 0),
            ConvertInt32(hashvalue, 4),
            ConvertInt32(hashvalue, 8),
            ConvertInt32(hashvalue, 12));
    }

    static void ScanPath(UnixDirectoryInfo dirinfo, string prefix)
    {
        foreach (var fileinfo in dirinfo.GetFileSystemEntries())
        {
            string id = string.Concat(prefix, fileinfo.Name);
			if (id.EndsWith(".pdb"))
				continue;
            switch (fileinfo.FileType)
            {
            case FileTypes.RegularFile:
                string hash;

                if (fileinfo.Length == 0)
                    hash = "0\t0\t0\t0";
                else
                    hash = FormatMd5Hash(fileinfo.FullName);

                Console.WriteLine("{0}\t0\t{1}", id, hash);
                break;
            case FileTypes.Directory:
                ScanPath((UnixDirectoryInfo)fileinfo, string.Concat(id, "\\"));
                break;
            case FileTypes.SymbolicLink:
            default:
                break;
            }
        }
    }

    static void Main()
    {
        var dirinfo = new UnixDirectoryInfo(".");
        ScanPath(dirinfo, "");
    }
}

