#include <ripext>

int fTimes;
static Handle g_h_Timer = null;
char g_szLocalFilePath[PLATFORM_MAX_PATH];
ArrayList g_aMapList;

public Plugin myinfo = {
    name = "dump map md5",
    author = "neko aka bklol",
    description = "什？这里竟然是大鸟转转转酒吧？",
    version = "0.1",
    url = "https://github.com/bklol"
};

public void OnPluginStart()
{
	char szLocalFileFolder[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szLocalFileFolder, sizeof(szLocalFileFolder), "data/neko/md5");
	BuildPath(Path_SM, g_szLocalFilePath, sizeof(g_szLocalFilePath), "data/neko/md5/md5.json");
	if(!DirExists(szLocalFileFolder))
	{
		CreateDirectory(szLocalFileFolder, 511);
	}
	g_aMapList = new ArrayList( ByteCountToCells(PLATFORM_MAX_PATH) );
	RegConsoleCmd("sm_md5",Dump_MD5File);
}

public Action Dump_MD5File(int client, int arg)
{
	g_aMapList.Clear();	
	fTimes = 0;	
	Dump();

}

stock void Dump()
{
	char FileName[64];
	Handle Dir = OpenDirectory("maps");
	FileType Type;
	JSONArray Md5_Array = new JSONArray();
	while(ReadDirEntry(Dir, FileName,PLATFORM_MAX_PATH, Type))
	{
		if(Type == FileType_File)
		{
			if(StrContains(FileName,".bsp") != -1)
			{
				Format(FileName, sizeof(FileName), "maps/%s",FileName);
				g_aMapList.PushString(FileName);
				//MD5_File(FileName, buffer, sizeof(buffer));
			}
			continue;
		}
	}
	PrintToServer("DUMP %i MapFile",g_aMapList.Length);
	g_h_Timer = CreateTimer(1.0, CreateMd5, Md5_Array, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action CreateMd5(Handle timer,JSONArray Md5_Array)
{
	char md5[128],FileName[128],Url[1024],FileTime[128],iFileSize[64];
	
	g_aMapList.GetString(fTimes,  FileName,  sizeof(FileName));
	MD5_File(FileName, md5, sizeof(md5));
	Format(Url,sizeof(Url),"http://down.ncyxx.cn/%s.bzp2",FileName);
	FormatTime(FileTime, sizeof(FileTime), "%Y-%m-%d %H:%M:%S",GetFileTime(FileName, FileTime_LastChange));
	new filesize = FileSize(FileName);
	float kbFileSize = float(filesize)/1024.0;
	float mbFileSize = kbFileSize /1024.0;	
	if(mbFileSize < 1)
		Format(iFileSize,sizeof(iFileSize),"%0.1f K", kbFileSize);
	else
		Format(iFileSize,sizeof(iFileSize),"%0.1f M", mbFileSize);
	JSONObject 	JSF  = new JSONObject();
	JSF.SetString("url",Url);
	JSF.SetString("lastModify",FileTime);
	JSF.SetString("size",iFileSize);
	JSF.SetString("md5",md5);
	Md5_Array.Push(view_as<JSON>(JSF));
	PrintToServer("DUMP %i MapFile\n FileName :%s \nMD5: %s \n URL : %s\n FileTime_LastChange: %s \n FileSize: %s",fTimes,md5,FileName,Url,FileTime,iFileSize);
	fTimes += 1;
	if(fTimes >= g_aMapList.Length)
	{
		KillTimer(g_h_Timer);
		PrintToServer("ALL MAP File Has Been Dumped");
		BackupJson(Md5_Array);
		delete Md5_Array;
	}
}

public void BackupJson(JSON json)
{
	PrintToServer("Creating local backup file!");
	File fLocalFile = null;
	if (fLocalFile == null)
	{
		if(FileExists(g_szLocalFilePath))
		{
			DeleteFile(g_szLocalFilePath);
		}
		fLocalFile = OpenFile(g_szLocalFilePath, "w+");
	}

	JSONObject jRoot = view_as<JSONObject>(json);

	jRoot.ToFile(g_szLocalFilePath, JSON_COMPACT);
	delete fLocalFile;
	fLocalFile = null;
	PrintToServer("Backup created!");
}

//-----------------------MD5 STOCK----------------------------------
stock bool MD5_File(const char[] path, char[] md5final, int maxsize)
{
    int buffer[512]; // 512 to be safe.
    if(!FileExists(path))
        return false;
    
    File f = OpenFile(path, "rb");
    Handle md5 = MD5Init();

    int len;
    while(!f.EndOfFile())
    {
        len = f.Read(buffer, 512, 1);
        MD5Update(md5, len, "", buffer);
    }
    MD5Final(md5, md5final, maxsize); 
    delete f;
    return true;
}

stock Handle MD5Init()
{
    int x[2];
    int buf[4];
    int input[64];
    int update[16];
    
    // MD5Init
    x[0] = x[1] = 0;
    buf[0] = 0x67452301;
    buf[1] = 0xefcdab89;
    buf[2] = 0x98badcfe;
    buf[3] = 0x10325476;
    
    StringMap map = CreateTrie();
    map.SetArray("x", x, 2);
    map.SetArray("buf", buf, 4);
    map.SetArray("input", input, 64);
    map.SetArray("update", update, 16); 
    return view_as<Handle>(map);
}

stock void MD5Update(Handle maph, int len, char[] str, int[] inputfromfile)
{
    StringMap map = view_as<StringMap>(maph);
    // MD5Update
    int x[2]; map.GetArray("x", x, 2);
    int buf[4]; map.GetArray("buf", buf, 4);
    int input[64]; map.GetArray("input", input, 64);
    int update[16]; map.GetArray("update", update, 16);
    int i, ii;

    update[14] = x[0];
    update[15] = x[1];

    int mdi = (x[0] >>> 3) & 0x3F;

    if ((x[0] + (len << 3)) < x[0]) {
        x[1] += 1;
    }

    x[0] += len << 3;
    x[1] += len >>> 29;

    int c = 0;
    while (len--) {
        if(StrEqual(str, ""))
            input[mdi] = inputfromfile[c];
        else
            input[mdi] = str[c];
        mdi += 1;
        c += 1;

        if (mdi == 0x40) {

            for (i = 0, ii = 0; i < 16; ++i, ii += 4)
            {
                update[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
            }

            // Transform
            MD5Transform(buf, update);

            mdi = 0;
        }
    }

    map.SetArray("x", x, 2);
    map.SetArray("buf", buf, 4);
    map.SetArray("input", input, 64);
    map.SetArray("update", update, 16);
}

stock void MD5Final(Handle maph, char[] md5, int maxlen)
{
    StringMap map = view_as<StringMap>(maph);
    // MD5Final
    int x[2]; map.GetArray("x", x, 2);
    int buf[4]; map.GetArray("buf", buf, 4);
    int input[64]; map.GetArray("input", input, 64);
    int update[16]; map.GetArray("update", update, 16);
    int i, ii;
    
    int padding[64] = {
        0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };

    int inx[16];
    inx[14] = x[0];
    inx[15] = x[1];

    int mdi = (x[0] >>> 3) & 0x3F;

    int len = (mdi < 56) ? (56 - mdi) : (120 - mdi);
    update[14] = x[0];
    update[15] = x[1];

    mdi = (x[0] >>> 3) & 0x3F;

    if ((x[0] + (len << 3)) < x[0]) {
        x[1] += 1;
    }

    x[0] += len << 3;
    x[1] += len >>> 29;

    int c = 0;
    while (len--) {
        input[mdi] = padding[c];
        mdi += 1;
        c += 1;

        if (mdi == 0x40) {

            for (i = 0, ii = 0; i < 16; ++i, ii += 4) {
                update[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
                
            }

            // Transform
            MD5Transform(buf, update);

            mdi = 0;
        }
    }

    for (i = 0, ii = 0; i < 14; ++i, ii += 4) {
        inx[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
    }

    MD5Transform(buf, inx);
    
    int digest[16];
    for (i = 0, ii = 0; i < 4; ++i, ii += 4) {
        digest[ii] = (buf[i]) & 0xFF;
        digest[ii + 1] = (buf[i] >>> 8) & 0xFF;
        digest[ii + 2] = (buf[i] >>> 16) & 0xFF;
        digest[ii + 3] = (buf[i] >>> 24) & 0xFF;
    }

    FormatEx(md5, maxlen, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
        digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
        digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]);
}

static stock void MD5Transform_FF(int &a, int &b, int &c, int &d, int x, int s, int ac)
    {
    a += (((b) & (c)) | ((~b) & (d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

static stock void MD5Transform_GG(int &a, int &b, int &c, int &d, int x, int s, int ac)
    {
    a += (((b) & (d)) | ((c) & (~d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

static stock void MD5Transform_HH(int &a, int &b, int &c, int &d, int x, int s, int ac)
    {
    a += ((b) ^ (c) ^ (d)) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

static stock void MD5Transform_II(int &a, int &b, int &c, int &d, int x, int s, int ac)
{
    a += ((c) ^ ((b) | (~d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

static stock void MD5Transform(int[] buf, int[] input){
    int a = buf[0];
    int b = buf[1];
    int c = buf[2];
    int d = buf[3];

    MD5Transform_FF(a, b, c, d, input[0], 7, 0xd76aa478);
    MD5Transform_FF(d, a, b, c, input[1], 12, 0xe8c7b756);
    MD5Transform_FF(c, d, a, b, input[2], 17, 0x242070db);
    MD5Transform_FF(b, c, d, a, input[3], 22, 0xc1bdceee);
    MD5Transform_FF(a, b, c, d, input[4], 7, 0xf57c0faf);
    MD5Transform_FF(d, a, b, c, input[5], 12, 0x4787c62a);
    MD5Transform_FF(c, d, a, b, input[6], 17, 0xa8304613);
    MD5Transform_FF(b, c, d, a, input[7], 22, 0xfd469501);
    MD5Transform_FF(a, b, c, d, input[8], 7, 0x698098d8);
    MD5Transform_FF(d, a, b, c, input[9], 12, 0x8b44f7af);
    MD5Transform_FF(c, d, a, b, input[10], 17, 0xffff5bb1);
    MD5Transform_FF(b, c, d, a, input[11], 22, 0x895cd7be);
    MD5Transform_FF(a, b, c, d, input[12], 7, 0x6b901122);
    MD5Transform_FF(d, a, b, c, input[13], 12, 0xfd987193);
    MD5Transform_FF(c, d, a, b, input[14], 17, 0xa679438e);
    MD5Transform_FF(b, c, d, a, input[15], 22, 0x49b40821);

    MD5Transform_GG(a, b, c, d, input[1], 5, 0xf61e2562);
    MD5Transform_GG(d, a, b, c, input[6], 9, 0xc040b340);
    MD5Transform_GG(c, d, a, b, input[11], 14, 0x265e5a51);
    MD5Transform_GG(b, c, d, a, input[0], 20, 0xe9b6c7aa);
    MD5Transform_GG(a, b, c, d, input[5], 5, 0xd62f105d);
    MD5Transform_GG(d, a, b, c, input[10], 9, 0x02441453);
    MD5Transform_GG(c, d, a, b, input[15], 14, 0xd8a1e681);
    MD5Transform_GG(b, c, d, a, input[4], 20, 0xe7d3fbc8);
    MD5Transform_GG(a, b, c, d, input[9], 5, 0x21e1cde6);
    MD5Transform_GG(d, a, b, c, input[14], 9, 0xc33707d6);
    MD5Transform_GG(c, d, a, b, input[3], 14, 0xf4d50d87);
    MD5Transform_GG(b, c, d, a, input[8], 20, 0x455a14ed);
    MD5Transform_GG(a, b, c, d, input[13], 5, 0xa9e3e905);
    MD5Transform_GG(d, a, b, c, input[2], 9, 0xfcefa3f8);
    MD5Transform_GG(c, d, a, b, input[7], 14, 0x676f02d9);
    MD5Transform_GG(b, c, d, a, input[12], 20, 0x8d2a4c8a);

    MD5Transform_HH(a, b, c, d, input[5], 4, 0xfffa3942);
    MD5Transform_HH(d, a, b, c, input[8], 11, 0x8771f681);
    MD5Transform_HH(c, d, a, b, input[11], 16, 0x6d9d6122);
    MD5Transform_HH(b, c, d, a, input[14], 23, 0xfde5380c);
    MD5Transform_HH(a, b, c, d, input[1], 4, 0xa4beea44);
    MD5Transform_HH(d, a, b, c, input[4], 11, 0x4bdecfa9);
    MD5Transform_HH(c, d, a, b, input[7], 16, 0xf6bb4b60);
    MD5Transform_HH(b, c, d, a, input[10], 23, 0xbebfbc70);
    MD5Transform_HH(a, b, c, d, input[13], 4, 0x289b7ec6);
    MD5Transform_HH(d, a, b, c, input[0], 11, 0xeaa127fa);
    MD5Transform_HH(c, d, a, b, input[3], 16, 0xd4ef3085);
    MD5Transform_HH(b, c, d, a, input[6], 23, 0x04881d05);
    MD5Transform_HH(a, b, c, d, input[9], 4, 0xd9d4d039);
    MD5Transform_HH(d, a, b, c, input[12], 11, 0xe6db99e5);
    MD5Transform_HH(c, d, a, b, input[15], 16, 0x1fa27cf8);
    MD5Transform_HH(b, c, d, a, input[2], 23, 0xc4ac5665);

    MD5Transform_II(a, b, c, d, input[0], 6, 0xf4292244);
    MD5Transform_II(d, a, b, c, input[7], 10, 0x432aff97);
    MD5Transform_II(c, d, a, b, input[14], 15, 0xab9423a7);
    MD5Transform_II(b, c, d, a, input[5], 21, 0xfc93a039);
    MD5Transform_II(a, b, c, d, input[12], 6, 0x655b59c3);
    MD5Transform_II(d, a, b, c, input[3], 10, 0x8f0ccc92);
    MD5Transform_II(c, d, a, b, input[10], 15, 0xffeff47d);
    MD5Transform_II(b, c, d, a, input[1], 21, 0x85845dd1);
    MD5Transform_II(a, b, c, d, input[8], 6, 0x6fa87e4f);
    MD5Transform_II(d, a, b, c, input[15], 10, 0xfe2ce6e0);
    MD5Transform_II(c, d, a, b, input[6], 15, 0xa3014314);
    MD5Transform_II(b, c, d, a, input[13], 21, 0x4e0811a1);
    MD5Transform_II(a, b, c, d, input[4], 6, 0xf7537e82);
    MD5Transform_II(d, a, b, c, input[11], 10, 0xbd3af235);
    MD5Transform_II(c, d, a, b, input[2], 15, 0x2ad7d2bb);
    MD5Transform_II(b, c, d, a, input[9], 21, 0xeb86d391);

    buf[0] += a;
    buf[1] += b;
    buf[2] += c;
    buf[3] += d;
}











