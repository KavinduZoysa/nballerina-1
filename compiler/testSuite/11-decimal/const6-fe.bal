import ballerina/io;
public function main() {
    decimal d = 1e-6144d; // @error
    io:println(d);
}
