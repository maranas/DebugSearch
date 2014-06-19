DebugSearch for Xcode
=====================

Allows filtering of debug output in Xcode.

Installation
============
Clone, build, then restart Xcode

>Usage:
>    # Type this into the debug console while you aren't debugging yet:
>    /set_filter="<filter string>"

Where <filter string> is the string to filter the log messages by. All messages satisfying the filter will be displayed; the other messages will be hidden.

Limitations
===========      
- No reg-ex yet.
- Once a user starts debugging interactively, filters are ignored.

This plugin uses the XCode plugin project template Copyright (c) 2013 Delisa Mason and contributors
Get it at https://github.com/kattrali/Xcode5-Plugin-Template

LICENSE
======
Copyright (c) 2014 Moises Anthony Aranas
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

