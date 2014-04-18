
#import "SymbolistBinaryEntry.h"

#include <cxxabi.h>


@implementation SymbolistBinaryEntry (Demangle)

- (void)setName:(const char *)string
{
	BOOL possiblyCPlusPlus = NO;
	
	// Ignore leading underscore.
	if (string[0] == '_') {
		string++; // Advance string by one.
		if (string[0] == '_' && string[1] == 'Z') {
			possiblyCPlusPlus = YES;
		}
	}
	
	// Process suffixes, which when removed will require a string copy.
	char *suffix;
	// If the name contains an extension (like .eh), we can only demangle the part which is recognisable as a function name.
	// 'suffix' is also used to remember the end location of the suffix, so it can be tacked back on again.
	suffix = strchr(string, '.');
	
	size_t nameLength;
	char *adjustedString;
	if (suffix != '\0' && suffix != string) {
		// Length up until beginning of suffix.
		nameLength = suffix - string;
		// Create a copy of the string.
		adjustedString = (char *)malloc((nameLength + 1) * sizeof(char));
		memcpy(adjustedString, string, nameLength * sizeof(char));
		adjustedString[nameLength] = '\0';
	}
	else {
		// Suffix could have been found to be the string beginning, so make suffix null.
		suffix = NULL;
		// Use the full length.
		nameLength = strlen(string);
		// Copy the whole string.
		adjustedString = strdup(string);
	}
	
	int status = 0;
	char *symbolName = NULL;
	if (possiblyCPlusPlus) {
		symbolName = abi::__cxa_demangle((const char *)adjustedString, NULL, NULL, &status);
	}
	// If a new string was created without fuss,
	if (status == 0 && symbolName) {
		// We don't need the old string anymore.
		free(adjustedString);
		
		_flags.isCPPSymbol = YES;
	}
	else {
		// Free ignores null values.
		free(symbolName);
		symbolName = adjustedString;
	}
	
	_name = symbolName;
	
	// Append suffix back on, if one was found.
	size_t suffixLen = suffix ? strlen(suffix) : 0;
	if (suffixLen > 0) {
		nameLength = strlen(_name);
		// Enlarge string to fit suffix.
		_name = (char *)reallocf(_name, nameLength + suffixLen + 1);
		// Copy suffix to end.
		strncpy(_name + nameLength, suffix, suffixLen + 1);
	}
}

//- (void)reloadName

+ (char *)demangledString:(const char *)string
{
	char *demangledString = NULL;
	int status;
	
	@try {
		demangledString = abi::__cxa_demangle(string, NULL, NULL, &status);
		if (status != 0) {
			free(demangledString);
			demangledString = NULL;
		}
	}
	@catch (NSException *exception) {
		demangledString = NULL;
	}
	@finally {
		if (!demangledString)
			demangledString = strdup(string);
	}
	
	return demangledString;
}

@end