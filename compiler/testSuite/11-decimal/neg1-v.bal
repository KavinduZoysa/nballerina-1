import ballerina/io;
public function main() {
    decimal d = 0d;
    io:println(-d); // @output 0

    d = 1d;
    io:println(-d); // @output -1

    d = -1d;
    io:println(-d); // @output 1

    d = 1E-6143d;
    io:println(-d); // @output -1E-6143

    d = 99999999999999999999999999999999999d;
    io:println(-d); // @output -1.000000000000000000000000000000000E+35

    d = 9.999999999999999999999999999999998E6144d;
    io:println(-d); // @output -9.999999999999999999999999999999998E+6144
}
