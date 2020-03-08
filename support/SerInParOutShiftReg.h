/*
  A class to simulate a serial in parallel out shift register, templated on the size of the register, allowing us to simulate multiple 74HC595 8 bit shift registers chained together.
 */

#pragma once

#include <type_traits>
#include <cstdint>
#include <climits>

template<typename Storage>
class SerInParOutShiftReg
{
private:

    // We want to make sure we don't try to create a signed
    // shift register or one with float as the storage.
    static_assert(
        std::is_integral<Storage>::value &&
        std::is_unsigned<Storage>::value);

    Storage mShiftData, mLatched;
    bool mPrevDataClock, mPrevLatch;

public:
    SerInParOutShiftReg();

    void update(bool dataIn, bool dataClock, bool latch);

    bool getBitValue(unsigned int which) const;
    unsigned char getSubByte(unsigned int startBit) const;
    Storage getLatchedValue() const { return mLatched; }
};

template<typename Storage>
SerInParOutShiftReg<Storage>::SerInParOutShiftReg()
    : mShiftData{}, mLatched{}, mPrevDataClock(false)
{
}

template<typename Storage>
void
SerInParOutShiftReg<Storage>::update(
        bool dataIn, 
        bool dataClock, 
        bool latch
    )
{
    if(dataClock && !mPrevDataClock) {
        mShiftData >>= 1;
        mShiftData |= ((int)dataIn<<(sizeof(Storage)*CHAR_BIT - 1));
    }
    mPrevDataClock = dataClock;

    if(latch && !mPrevLatch) {
        mLatched = mShiftData;
    }
    mPrevLatch = latch;
}

template<typename Storage>
bool
SerInParOutShiftReg<Storage>::getBitValue(unsigned int which) const
{
    return (mLatched & (1 << which)) != 0;
}

template<typename Storage>
unsigned char 
SerInParOutShiftReg<Storage>::getSubByte(unsigned int startBit) const
{
    return (mLatched & (0xff << startBit)) >> startBit;
}