/*
  A class to simulate a serial-in parallel-out shift register, templated on 
  the size of the register, allowing us to simulate multiple 74HC595 8 bit 
  shift registers chained together.
 */

#pragma once

#include <type_traits>
#include <cstdint>
#include <climits>
#include <bitset>

template<std::size_t NumRegs>
class SerInParOutShiftReg
{
private:

    constexpr static const std::size_t NumBits = NumRegs*8;
    using ShiftReg = std::bitset<NumBits>;
    ShiftReg mShiftData, mLatched;
    bool mPrevDataClock, mPrevLatch;

public:
    SerInParOutShiftReg();

    void update(bool dataIn, bool dataClock, bool latch);

    bool getBitValue(std::size_t which) const;
    unsigned char getSubByte(std::size_t startByte) const;
    ShiftReg getLatchedValue() const { return mLatched; }
};

template<std::size_t NumRegs>
SerInParOutShiftReg<NumRegs>::SerInParOutShiftReg()
    : mShiftData{}, mLatched{}, mPrevDataClock(false)
{
}

template<std::size_t NumRegs>
void
SerInParOutShiftReg<NumRegs>::update(
        bool dataIn, 
        bool dataClock, 
        bool latch
    )
{
    if(dataClock && !mPrevDataClock) {
        mShiftData <<= 1;

        // Set the lowest bit to the incoming value.
        mShiftData.set(0, dataIn);
    }
    mPrevDataClock = dataClock;

    if(latch && !mPrevLatch) {
        mLatched = mShiftData;
    }
    mPrevLatch = latch;
}

template<std::size_t NumRegs>
bool
SerInParOutShiftReg<NumRegs>::getBitValue(std::size_t which) const
{
    return mLatched[which];
}

template<std::size_t NumRegs>
unsigned char 
SerInParOutShiftReg<NumRegs>::getSubByte(std::size_t startByte) const
{
    unsigned char val = 0;
    for(std::size_t ii = 0; ii < 8; ii++) {
        val |= (int)(mLatched[(startByte*8)+ii]) << ii;
    }
    return val;
}