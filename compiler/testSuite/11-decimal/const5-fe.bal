import ballerina/io;
public function main() {
    decimal d = 10e6144d; // @error
    io:println(d);
}
