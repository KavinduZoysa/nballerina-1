#include <math.h>
#include <assert.h>
#include "../balrt.h"
#include "../hash.h"

HASH_DEFINE_KEY;

void validatDecToFloat(const char *decStr, double val) {
    assert(_bal_decimal_to_float(_bal_decimal_const(decStr)) == val);
}

void testDecToFloat() {
    validatDecToFloat("1", 1);
    validatDecToFloat("1.000000000000000000000000000000000", 1);
    validatDecToFloat("1.1", 1.1);
    validatDecToFloat("9.0", 9);
    validatDecToFloat("9.1", 9.1);
    validatDecToFloat("9.999999999999999999999999999999999", 10.0);
    validatDecToFloat("9.99999999999999999999999999999999", 10.0);
    validatDecToFloat("9.9999999999999999999999999999999", 10.0);
    validatDecToFloat("10.00000000000000000000000000", 10.0);
    validatDecToFloat("10.00000000000000000000000001", 10.0);
    validatDecToFloat("10.00000000000000000000000001", 10.0);
    validatDecToFloat("99.99999999999999999999999999999999", 100.0);
    validatDecToFloat("1e2", 1e2);
    validatDecToFloat("1.9e2", 1.9e2);
    validatDecToFloat("9.999999999999999999999999999999999e100", 1.0e101);
    validatDecToFloat("9999999999999999999999999999999999e100", 1.0e134);
    validatDecToFloat("1e308", 1.0e308);
    validatDecToFloat("1.7976931348623158e+308", 1.7976931348623158e+308);
    validatDecToFloat("1.79769313486231571e+308", 1.79769313486231571e+308);
    validatDecToFloat("1.79769313486231570e+308", 1.79769313486231570e+308);
    validatDecToFloat("1.7976931348623156e+308", 1.7976931348623156e+308);
    validatDecToFloat("-1.7976931348623157e+308", -1.7976931348623157e+308);
    validatDecToFloat("-1.79769313486231571e308", -1.79769313486231571e308);
    validatDecToFloat("-1.7976931348623158e308", -1.7976931348623158e308);
    validatDecToFloat("-1.7976931348623156e+308", -1.7976931348623156e+308);
    validatDecToFloat("0", 0.0);
    validatDecToFloat("1e-322", 1e-322);
    validatDecToFloat("1e-323", 1e-323);
    validatDecToFloat("1e-324", 0.0);
    validatDecToFloat("-1e-324", 0.0);
    validatDecToFloat("1e-6143", 0.0);
    validatDecToFloat("-1e-6143", 0.0);
    validatDecToFloat("1e309", INFINITY);
    validatDecToFloat("1.7976931348623156e+309", INFINITY);
    validatDecToFloat("9.999999999999999999999999999999999E6144", INFINITY);
    validatDecToFloat("-1e309", -INFINITY);
    validatDecToFloat("-2e309", -INFINITY);
    validatDecToFloat("-9.999999999999999999999999999999999E6144", -INFINITY);
    validatDecToFloat("-1.7976931348623156e+309", -INFINITY);
}

void validateDecToIntNonOverflow(const char *decStr, int64_t val) {
    DecToIntResult res = _bal_decimal_to_int(_bal_decimal_const(decStr));
    assert(res.val == val);
    assert(!res.overflow);
}

void validateDecToIntOverflow(const char *decStr) {
    DecToIntResult res = _bal_decimal_to_int(_bal_decimal_const(decStr));
    assert(res.overflow);
}

void testDecToInt() {
    validateDecToIntNonOverflow("1", 1);
    validateDecToIntNonOverflow("0", 0);
    validateDecToIntNonOverflow("-1", -1);
    validateDecToIntNonOverflow("0.5", 0);
    validateDecToIntNonOverflow("1.5", 2);
    validateDecToIntNonOverflow("2.5", 2);
    validateDecToIntNonOverflow("-0.5", 0);
    validateDecToIntNonOverflow("-1.5", -2);
    validateDecToIntNonOverflow("-2.5", -2);
    validateDecToIntNonOverflow("1e2", 100);
    validateDecToIntNonOverflow("1.5e2", 150);
    validateDecToIntNonOverflow("-1.5e2", -150);
    validateDecToIntNonOverflow("1.51e2", 151);
    validateDecToIntNonOverflow("1.513e2", 151);
    validateDecToIntNonOverflow("1.515e2", 152);
    validateDecToIntNonOverflow("9223372036854775807", 9223372036854775807);
    validateDecToIntNonOverflow("-9223372036854775808", -9223372036854775807L - 1);
    validateDecToIntNonOverflow("1E-6143", 0);
    validateDecToIntNonOverflow("-1E-6143", 0);
    validateDecToIntOverflow("9223372036854775808");
    validateDecToIntOverflow("-9223372036854775809");
    validateDecToIntOverflow("9.999999999999999999999999999999999E6144");
    validateDecToIntOverflow("-9.999999999999999999999999999999999E6144");
}

int main() {
    testDecToFloat();
    testDecToInt();
}
