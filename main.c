#include <stdio.h>
//#include <stdlib.h>

// Declaring MyFloat struct
struct MyFloat {
    unsigned int fraction;
    unsigned int exponent;
    unsigned int sign;
};

// functions prototype
struct MyFloat toMyFloat(float f);
struct MyFloat MyFloatAdder (struct MyFloat input1, struct MyFloat input2);


int main(void) {
    float a = -12.75f;
    float b = 15.5f;

    struct MyFloat mf1 = toMyFloat(a);
    struct MyFloat mf2 = toMyFloat(b);

    struct MyFloat result = MyFloatAdder(mf1, mf2);

    // Print result
    printf("Result - Sign: %u, Exponent: %u, Fraction: %u\n", result.sign, result.exponent, result.fraction);

    return 0;
}

//functions implementation
struct MyFloat toMyFloat(float f){
    struct MyFloat xs;
    unsigned int* binary = (unsigned int *) &f;
    xs.fraction = *binary & 0x7FFFFF;       //masking the first 23 bit
    xs.exponent = (*binary >>23) & 0xFF;   // masking the exponent (8 bits) after shifting it 23 times
    xs.sign = (*binary>>31) & 1;           // masking the sign (1 bit) after shifting it 31 times
    return xs;
}

struct MyFloat MyFloatAdder (struct MyFloat input1, struct MyFloat input2){
    struct MyFloat sum;
    int dif = input1.exponent - input2.exponent;
    struct MyFloat largest = input1, smallest = input2;
    if(dif < 0 || (dif==0 && ((input2.sign > input1.sign) || ((input2.sign == input1.sign) && (input2.fraction> input1.fraction))))){
        largest = input2;
        smallest = input1;
    }
    if (!largest.fraction && !largest.exponent && !largest.sign)
        largest.fraction = largest.fraction & 0x80000;
    if (!smallest.fraction && !smallest.exponent && !smallest.sign)
        smallest.fraction = smallest.fraction & 0x80000;
    if (largest.sign == smallest.sign){

        if (largest.sign)

    }
    sum.exponent = smallest.exponent + dif;

    sum.exponent = largest.exponent;
    if((sum.fraction >> 24)> 0)
        exit(1);




}

