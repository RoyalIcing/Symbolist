Symbolist
=========

View Mac App binary symbols, and Objective-C runtime symbols.

## Mac App binary symbols, lightely similar to what `nm` outputs.

Works by parsing the executable mach binary. I am not an expert in what all this stuff means.
Primarily I found it interesting to see what classes and functions certain apps used.

Just drag-and-drop an app onto Symbolist’s Dock icon, and you should see its symbols.

## Objective-C runtime viewer

In the menu bar, go to `List > New Objective-C Runtime Viewer…` to open a new viewer.

Just lists all classes and protocols that the Symbolist app can see from AppKit, Foundation, Core Animation, etc.
Browse how these frameworks are constructed, to get inspiration for your own classes.

## This was a project to put myself in the deep-end

It is circa 2007–2009. It taught me a lot back then. I’ve fixed it up to work with the latest Objective-C runtime.
There could be quite a few bugs, all of what it does is read-only though so it won't affect anything.
