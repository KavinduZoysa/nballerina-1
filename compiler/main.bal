import wso2/nballerina.bir;
import wso2/nballerina.front;
import wso2/nballerina.nback;
import wso2/nballerina.err;

import ballerina/io;
import ballerina/file;
import ballerina/regex;

type CompileError err:Any?|io:Error;

public type Options record {|
    boolean testJsonTypes = false;
    boolean showTypes = false;
    string? outDir = ();
    string? gc = ();
|};

const GC_NAME_REGEX = "[A-Za-z]+[-_][A-Za-z]+";

const SOURCE_EXTENSION = ".bal";
public function main(string[] filenames, *Options opts) returns error? {
    if !isValidGCName(opts.gc) {
        return error("Invalid GC strategy " + <string>opts.gc);
    }

    foreach string filename in filenames {
        if opts.testJsonTypes {
            check testJsonTypes(filename);
            continue;
        }
        if opts.showTypes {
            check showTypes(filename);
            continue;
        }
        check compileFile(filename, check chooseOutputFilename(filename, opts.outDir), opts.gc);
    }  
}

function isValidGCName(string? gcName) returns boolean {
    if (gcName is ()) {
        return true;
    } else {
        return regex:matches(gcName, GC_NAME_REGEX);
    }
}

//  outputFilename of () means don't output anything
function compileFile(string filename, string? outputFilename, string? gcName) returns CompileError {
    bir:ModuleId id = {
       names: [filename],
       organization: "dummy"
    };
    bir:Module module = check front:loadModule(filename, id);
    check nback:compileModule(module, outputFilename, gcName);
}

function chooseOutputFilename(string sourceFilename, string? outDir) returns string|error? {
    string filename;
    if outDir == () {
        filename = sourceFilename;
    }
    else {
        filename = check file:joinPath(outDir, check file:basename(sourceFilename));
    }
    var [base, extension] = basenameExtension(filename);
    if extension != SOURCE_EXTENSION {
        return error("filename must end with " + SOURCE_EXTENSION);
    }
    return base + nback:OUTPUT_EXTENSION;
}

// Note that this converts extension to lower case
function basenameExtension(string filename) returns [string, string?] {
    int? extIndex = filename.lastIndexOf(".");
    if extIndex is int {
        return [filename.substring(0, extIndex), filename.substring(extIndex).toLowerAscii()];
    }
    return [filename, ()];
}
