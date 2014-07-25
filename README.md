DebugSearch for Xcode
=====================

Allows filtering of debug output in Xcode, and also per-line highlighting.

Installation
============
Clone, build, then restart Xcode

Usage
====
There will be a text field added on top of your debug console view in the Xcode IDE. Just enter a string there and the output will be filtered accordingly.

Highlighting
============
The plugin can also highlight lines of output. The highlighting definitions are saved in a plist in the current user's home directory:

    ~/.dbgSearch/dbgHighlightConf.plist

The file is a simple plist that contains a dictionary with strings as keys, and float values for R, G, B and alpha parameters (will be passed to NSColor). E.g. to color messages containing the string "ERROR" with red, your plist will look like this:

    <plist version="1.0">
        <dict>
            <key>ERROR</key>
                <array>
                    <real>1.0</real> # red
                    <real>0</real>   # green
                    <real>0</real>   # blue
                    <real>1.0</real> # alpha
                </array>
        </dict>
    </plist>


Limitations
===========      
- No reg-ex yet.
- Once a user starts debugging interactively, filters are ignored.

This plugin uses the XCode plugin project template Copyright (c) 2013 Delisa Mason and contributors
Get it at https://github.com/kattrali/Xcode5-Plugin-Template

