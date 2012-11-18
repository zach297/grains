import std.algorithm;
import std.array;
import std.stdio;
import std.file;
import std.string;

enum string PROJECT_NAME = "grains";
enum string[] LIBS = ["DerelictSDL2", "DerelictUtil"];

version (DigitalMars)
{
    enum string COMPILE_COMMAND = "dmd -c ";
    enum string LINK_COMMAND = "dmd -L-ldlgit";
}

version (GNU)
{
    enum string COMPILE_COMMAND = "gdc";
    enum string LINK_COMMAND = "ld";
}

version (Windows)
{

    enum string RM_COMMAND = "del";
    enum string OBJ_SUFFIX = ".obj";
    enum string LIB_SUFFIX = ".lib";
    enum string LIB_PREFIX = "";
    enum string EXE_SUFFIX = ".exe";
    void colorizeCommand(File makefile, string color, string text)
    {
        makefile.writeln("\t@build ", color, " \"", text, '"');
    }
}
version (Posix)
{
    enum string RM_COMMAND = "rm";
    enum string OBJ_SUFFIX = ".o";
    enum string LIB_SUFFIX = ".a";
    enum string LIB_PREFIX = "-L/usr/local/lib/lib";
    enum string EXE_SUFFIX = "";
    void colorizeCommand(File makefile, string color, string text)
    {
        string[string] colorMap;
        colorMap["red"]         = "1;31";
        colorMap["darkred"]     = "0;31";
        colorMap["green"]       = "1;32";
        colorMap["darkgreen"]   = "0;32";
        colorMap["blue"]        = "1;34";
        colorMap["darkblue"]    = "0;34";
        colorMap["yellow"]      = "1;33";
        colorMap["darkyellow"]  = "0;33";
        colorMap["magenta"]     = "1;35";
        colorMap["darkmagenta"] = "0;35";
        colorMap["cyan"]        = "1;36";
        colorMap["darkcyan"]    = "0;36";
        assert(color in colorMap);
        makefile.writeln("\t@echo -e \"\\e[", colorMap[color], "m", text, "\\e[0m\"");
    }
}

void buildMakefile()
{
    auto srcFilesRange = filter!("a != \"build\"")(map!("a.name.chomp(\".d\").chompPrefix(\"./\")")(dirEntries("./", "*.d", SpanMode.shallow)));

    /* Hack to evaluate the srcFilesRange into a real array */
    auto srcFilesAppender = appender!(string[])();
    foreach (srcFile; srcFilesRange)
    {
        srcFilesAppender.put(srcFile);
    }
    string[] srcFiles = srcFilesAppender.data();

    auto makefile = File("makefile", "w");
    makefile.writeln("PROJECT_NAME = ", PROJECT_NAME);
    makefile.writeln("COMPILE_COMMAND = ", COMPILE_COMMAND);
    makefile.writeln("LINK_COMMAND = ", LINK_COMMAND);
    makefile.writeln("RM_COMMAND = ", RM_COMMAND);
    makefile.writeln("COMPILE_OPTIONS = -g -gs");
    makefile.writeln("OBJ_SUFFIX = ", OBJ_SUFFIX);
    makefile.writeln("LIB_SUFFIX = ", LIB_SUFFIX);
    makefile.writeln("LIB_PREFIX = ", LIB_PREFIX);
    makefile.writeln("EXE_SUFFIX = ", EXE_SUFFIX);
    makefile.writeln("OBJS = ", joiner(map!("a ~ \"$(OBJ_SUFFIX)\"")(srcFiles), " "));
    makefile.writeln("\n");
    makefile.writeln("$(PROJECT_NAME): $(OBJS)");
    colorizeCommand(makefile, "cyan", "[Link]");
    makefile.writeln("\t@$(LINK_COMMAND) ", joiner(map!("\"$(LIB_PREFIX)\" ~ a ~ \"$(LIB_SUFFIX)\"")(LIBS), " "), " $(OBJS) -of$(PROJECT_NAME)$(EXE_SUFFIX)");
    makefile.writeln();
    makefile.writeln("clean:");
    makefile.writeln("\t$(RM_COMMAND) $(OBJS) $(PROJECT_NAME)$(EXE_SUFFIX)");
    makefile.writeln();
    foreach (srcFile; srcFiles)
    {
        makefile.writeln(srcFile, "$(OBJ_SUFFIX): ", srcFile, ".d");
        colorizeCommand(makefile, "green", "[" ~ srcFile ~ ".d]");
        makefile.writeln("\t@$(COMPILE_COMMAND) $(COMPILE_OPTIONS) ", srcFile, ".d");
        makefile.writeln();
    }
}

void colorOutput(string[] argv)
{
version (Windows)
{
    import std.c.windows.windows;
    WORD[string] colorMap;
    colorMap["red"]         = FOREGROUND_RED   | FOREGROUND_INTENSITY;
    colorMap["darkred"]     = FOREGROUND_RED;
    colorMap["green"]       = FOREGROUND_GREEN | FOREGROUND_INTENSITY;
    colorMap["darkgreen"]   = FOREGROUND_GREEN;
    colorMap["blue"]        = FOREGROUND_BLUE  | FOREGROUND_INTENSITY;
    colorMap["darkblue"]    = FOREGROUND_BLUE;
    colorMap["yellow"]      = FOREGROUND_RED   | FOREGROUND_GREEN | FOREGROUND_INTENSITY;
    colorMap["darkyellow"]  = FOREGROUND_RED   | FOREGROUND_GREEN;
    colorMap["magenta"]     = FOREGROUND_RED   | FOREGROUND_BLUE  | FOREGROUND_INTENSITY;
    colorMap["darkmagenta"] = FOREGROUND_RED   | FOREGROUND_BLUE;
    colorMap["cyan"]        = FOREGROUND_GREEN | FOREGROUND_BLUE  | FOREGROUND_INTENSITY;
    colorMap["darkcyan"]    = FOREGROUND_GREEN | FOREGROUND_BLUE;

    string colorArg = argv[1].toLower();
    if (colorArg in colorMap)
    {
        auto stdoutHandle = GetStdHandle(STD_OUTPUT_HANDLE);
        CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
        GetConsoleScreenBufferInfo(stdoutHandle, &consoleInfo);
        SetConsoleTextAttribute(stdoutHandle, colorMap[colorArg]);

        foreach (arg; argv[2..$])
        {
            write(arg);
            write(' ');
        }
        writeln();
        stdout.flush();
        SetConsoleTextAttribute(stdoutHandle, consoleInfo.wAttributes);
    }
}
}

void main(string[] argv)
{
    if (argv.length <= 1)
    {
        buildMakefile();
    }
    else
    {
        colorOutput(argv);
    }
}