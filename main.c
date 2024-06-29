#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>

// Declaring MyFloat struct
struct MyFloat {
    unsigned int fraction;
    unsigned int exponent;
    unsigned int sign;
};

// Function prototypes
struct MyFloat toMyFloat(float f);
struct MyFloat MyFloatAdder(struct MyFloat input1, struct MyFloat input2);
float toFloat(struct MyFloat mf);
float random_float_range(float min, float max);



int main(void) {

    srand(time(NULL));
    for (int i = 0; i < 10; i++) {
        float a = random_float_range(-1e30f, 1e30f); // Random float between -1e30 and 1e30
        float b = random_float_range(-1e30f, 1e30f); // Random float between -1e30 and 1e30

        struct MyFloat mf1 = toMyFloat(a);
        struct MyFloat mf2 = toMyFloat(b);

        struct MyFloat result = MyFloatAdder(mf1, mf2);
        float resultFloat = toFloat(result);
        float expected = a + b;

        printf("Test %d:\n", i + 1);
        printf("a: %e, b: %e\n", a, b);
        printf("MyFloat Result - Sign: %u, Exponent: %u, Fraction: %u\n", result.sign, result.exponent, result.fraction);
        printf("MyFloat as float: %e\n", resultFloat);
        printf("Expected Result: %e\n", expected);
    }

    return 0;
}

// Function to convert float to MyFloat struct
struct MyFloat toMyFloat(float f) {
    struct MyFloat xs;
    unsigned int* binary = (unsigned int*)&f;
    xs.fraction = *binary & 0x7FFFFF;       // masking the first 23 bits
    xs.exponent = (*binary >> 23) & 0xFF;   // masking the exponent (8 bits) after shifting it 23 times
    xs.sign = (*binary >> 31) & 1;          // masking the sign (1 bit) after shifting it 31 times
    return xs;
}

// Function to add two MyFloat structs
struct MyFloat MyFloatAdder(struct MyFloat input1, struct MyFloat input2) {
    struct MyFloat result;

    // Zero cases
    if (input1.exponent == 0 && input1.fraction == 0) {
        return input2;
    }
    if (input2.exponent == 0 && input2.fraction == 0) {
        return input1;
    }

    int fraction1 = input1.fraction | 0x800000; // Implicit leading 1
    int fraction2 = input2.fraction | 0x800000; // Implicit leading 1

    // Align exponents
    if (input1.exponent > input2.exponent) {
        int shift = input1.exponent - input2.exponent;
        fraction2 >>= shift;
        input2.exponent = input1.exponent;
    } else if (input2.exponent > input1.exponent) {
        int shift = input2.exponent - input1.exponent;
        fraction1 >>= shift;
        input1.exponent = input2.exponent;
    }

    // Add mantissas considering the signs
    if (input1.sign) {
        fraction1 = -fraction1;
    }
    if (input2.sign) {
        fraction2 = -fraction2;
    }

    int fractionSum = fraction1 + fraction2;

    // Determine the sign of the result
    if (fractionSum < 0) {
        result.sign = 1;
        fractionSum = -fractionSum;
    } else {
        result.sign = 0;
    }

    // Normalize the result
    result.exponent = input1.exponent;

    if (fractionSum & 0x1000000) { // Check for overflow
        fractionSum >>= 1;
        result.exponent++;
    }
    while (fractionSum && (fractionSum & 0x800000) == 0) {
        fractionSum <<= 1;
        result.exponent--;
    }

    if (result.exponent >= 255) {          // Exponent overflow
        result.exponent = 255;
        result.fraction = 0;              // Represent as inf
    } else if (result.exponent <= 0) {    // Exponent underflow
        if (result.exponent < -23) {      // Too small to be represented as a subnormal number
            result.exponent = 0;
            result.fraction = 0;
        } else {                          // Subnormal number
            result.fraction = fractionSum >> (1 - result.exponent);
            result.exponent = 0;
        }
    } else {
        result.fraction = fractionSum & 0x7FFFFF;
    }
    return result;
}

// Function to convert MyFloat struct to float
float toFloat(struct MyFloat mf) {
    unsigned int binary = (mf.sign << 31) | (mf.exponent << 23) | (mf.fraction & 0x7FFFFF);
    float* f = (float*)&binary;
    return *f;
}

// Function to give a random float
float random_float_range(float min, float max) {
    float scale = rand() / (float) RAND_MAX; // [0, 1.0]
    return min + scale * (max - min); // [min, max]
}