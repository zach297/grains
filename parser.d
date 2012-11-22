import std.algorithm;
import std.ascii;
import std.stdio;
import std.stream;
import std.string;

enum lexer_state_type
{
    NONE,
    IDENTIFIER,
    NUMBER,
    STRING,
    ESCAPED_STRING,
}

class lexer_t
{
    void identifier_callback(string identifier)
    {
        writeln("Found Identifier: \"", identifier, "\"");
    }
    
    void number_callback(string number)
    {
        writeln("Found Number: \"", number, "\"");
    }

    void string_callback(string str)
    {
        writeln("Found String: \"", str, "\"");
    }

    void begin_block_callback()
    {
        writeln("Begin Block");
    }

    void end_block_callback()
    {
        writeln("End Block");
    }

    void begin_list_callback()
    {
        writeln("Begin List");
    }

    void end_list_callback()
    {
        writeln("End List");
    }

    void invalid_callback(string buffer)
    {
        writeln("Invalid Input: \"", buffer, "\"");
    }
}

pure nothrow @safe bool isIdentifier(dchar c)
{
    return (c == '_' || c == '$' || c == '.' || isAlphaNum(c));
}

void parse(string filename)
{
    InputStream file_stream = new std.stream.File(filename, FileMode.In);
    lexer_t lex = new lexer_t();

    lexer_state_type state = lexer_state_type.NONE;
    string buffer = "";
    dchar string_delim = 0;

    while (!file_stream.eof())
    {
        char c = file_stream.getc();
        if (state == lexer_state_type.NONE)
        {
            if (isWhite(c))
            {
                
            }
            else if (c == '{')
            {
                lex.begin_block_callback();
            }
            else if (c == '}')
            {
                lex.end_block_callback();
            }
            else if (c == '[')
            {
                lex.begin_list_callback();
            }
            else if (c == ']')
            {
                lex.end_list_callback();
            }
            else if (c == '-' || c== '+' || isDigit(c))
            {
                state = lexer_state_type.NUMBER;
                buffer ~= c;
            }
            else if (isIdentifier(c))
            {
                state = lexer_state_type.IDENTIFIER;
                buffer ~= c;
            }
            else if (c == '"' || c == '\'')
            {
                state = lexer_state_type.STRING;
                string_delim = c;
            }
            else
            {
                lex.invalid_callback("" ~ c);
                break;
            }
        }
        else if (state == lexer_state_type.IDENTIFIER)
        {
            if (isIdentifier(c))
            {
                buffer ~= c;
            }
            else
            {
                lex.identifier_callback(buffer);
                buffer = "";
                file_stream.ungetc(c);
                state = lexer_state_type.NONE;
            }
        }
        else if (state == lexer_state_type.NUMBER)
        {
            if (c == '.' || isDigit(c))
            {
                buffer ~= c;

            }
            else if (isIdentifier(c))
            {
                buffer ~= c;
                if (canFind(buffer, '-') || canFind(buffer, '+'))
                {
                    lex.invalid_callback(buffer);
                    break;
                }
                state = lexer_state_type.IDENTIFIER;
            }
            else
            {
                lex.number_callback(buffer);
                buffer = "";
                file_stream.ungetc(c);
                state = lexer_state_type.NONE;
            }
        }
        else if (state == lexer_state_type.STRING)
        {
            if (c == '\\')
            {
                state = lexer_state_type.ESCAPED_STRING;
            }
            else if (c == string_delim)
            {
                lex.string_callback(buffer);
                buffer = "";
                state = lexer_state_type.NONE;
            }
            else
            {
                buffer ~= c;
            }
        }
        else if (state == lexer_state_type.ESCAPED_STRING)
        {
            if (c == '\'' || c == '"' || c == '\\')
            {
                buffer ~= c;
                state = lexer_state_type.STRING;
            }
            else if (c == 'n')
            {
                buffer ~= '\n';
                state = lexer_state_type.STRING;
            }
            else if (c == 't')
            {
                buffer ~= '\t';
                state = lexer_state_type.STRING;
            }
            else if (c == 'r')
            {
                buffer ~= '\r';
                state = lexer_state_type.STRING;
            }
            else
            {
                lex.invalid_callback(buffer);
                break;
            }
        }
    }
}