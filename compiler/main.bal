import wso2/nballerina.types as t;
import wso2/nballerina.bir;
import wso2/nballerina.front;
import wso2/nballerina.nback;
import wso2/nballerina.err;

import ballerina/io;
import ballerina/file;

type CompileError err:Any|io:Error|file:Error;

public type Options record {
    boolean testJsonTypes = false;
    boolean showTypes = false;
    int? debugLevel;
    // outDir also implies treating each file as a separate module
    string? outDir = ();
    string? expectOutDir = ();
    string? gc = ();
    *OutputOptions;
};

const DEFAULT_ROOT_MODULE_NAME = "root";
final bir:ModuleId DEFAULT_ROOT_MODULE_ID = { org: "", names: [DEFAULT_ROOT_MODULE_NAME] };

const SOURCE_EXTENSION = ".bal";
const TEST_EXTENSION = ".balt";
public function main(string[] filenames, *Options opts) returns error? {
    if filenames.length() == 0 {
        return error("no input files");
    }
    if opts.testJsonTypes {
        if filenames.length() > 1 {
            return error("multiple input files not supported with --testJsonTypes");
        }
        check testJsonTypes(filenames[0]);
        return;
    }
    if opts.showTypes {
        if filenames.length() > 1 {
            return error("multiple input files not supported with --showTypes");
        }
        check showTypes([{ filename: filenames[0] }]);
        return;
    }
    nback:Options nbackOptions = {
        gcName: check nback:validGcName(opts.gc),
        debugLevel: check nback:validDebugLevel(opts.debugLevel)
    };
    foreach string filename in filenames {
        var [basename, ext] = basenameExtension(filename);
        if ext == SOURCE_EXTENSION {
            check compileBalFile(filename, basename, check chooseOutputBasename(basename, opts.outDir), nbackOptions, opts);
        }
        else if ext == TEST_EXTENSION {
            check compileBalt(filename, opts.outDir ?: check file:parentPath(filename), nbackOptions, opts);
        }
        else {
            return error(unknownExtensionMessage(ext));
        }
    }
}

function unknownExtensionMessage(string? ext) returns string {
    if ext == () {
        return "input filename must have a .bal or .balt extension";
    }
    else {
        return err:format(`unsupported extension ${ext}`);
    }
}

function compileBalt(string filename, string outDir, nback:Options nbackOptions, Options options) returns error? {
    BaltTestCase[] tests = check parseBalt(filename);
    foreach var [i, t] in tests.enumerate() {
        if t.header.Test\-Case == "error" || t.header["Fail-Issue"] != () {
            continue;
        }
        string outBasename = chooseBaltCaseOutputFilename(t, i);
        string outFilename = check file:joinPath(outDir, outBasename) + OUTPUT_EXTENSION;
        string[] lines = t.content;
        check compileAndOutputModule(DEFAULT_ROOT_MODULE_ID, [{ lines }], nbackOptions, options, outFilename);
        string? expectOutDir = options.expectOutDir;
        string expectFilename = check file:joinPath(expectOutDir ?: outDir, outBasename) + ".txt";
        check io:fileWriteLines(expectFilename, expect(t.content));
    }
}

function compileModule(bir:ModuleId modId, front:SourcePart[] sources, nback:Options nbackOptions) returns LlvmModule|CompileError {
    t:Env env = new;
    front:ScannedModule scanned = check front:scanModule(sources, modId);
    bir:Module birMod = check front:resolveModule(scanned, env, []);
    LlvmContext context = new;
    return nback:buildModule(birMod, context, nbackOptions);
}

function compileAndOutputModule(bir:ModuleId modId, front:SourcePart[] sources, nback:Options nbackOptions, OutputOptions outOptions, string? outFilename) returns CompileError? {
    LlvmModule llMod = check compileModule(modId, sources, nbackOptions);
    if outFilename != () {
        check outputModule(llMod, outFilename, outOptions);
    }
}


function chooseOutputFilename(string sourceFilename, string? outDir = ()) returns string|error? {
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
    return base + OUTPUT_EXTENSION;
}

// Basename here means filename without extension
function chooseOutputBasename(string sourceBasename, string? outDir = ()) returns string|error {
    if outDir == () {
        return sourceBasename;
    }
    else {
        return check file:joinPath(outDir, check file:basename(sourceBasename));
    }
}

// Note that this converts extension to lower case
function basenameExtension(string filename) returns [string, string?] {
    int? extIndex = filename.lastIndexOf(".");
    if extIndex is int {
        return [filename.substring(0, extIndex), filename.substring(extIndex).toLowerAscii()];
    }
    return [filename, ()];
}
