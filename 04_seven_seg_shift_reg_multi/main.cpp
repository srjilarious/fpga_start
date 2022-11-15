#include "../support/TestBench.h"
#include "Vtop.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <SFML/Graphics.hpp>

#include "SevenSegDisplay.h"
#include "SerInParOutShiftReg.h"

#include <memory>

constexpr float AmountSimulationTicksPerFrame = 1 / 5.0f;

struct TB : public TestBench<Vtop>
{
    virtual ~TB() = default;

    // We overload the setClock signal method so we can reference different
    // clock signals for different FPGA boards.
    void setClock(uint8_t val) { mCore->CLK = val; }
};

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);
    TB tb;

    tb.openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("simulation");
    console->info("Seven Segment Shift Register Simulation!");

    auto renderWin = std::make_unique<sf::RenderWindow>(
        sf::VideoMode(800, 600), "Seven Segment Display Simulation");

    SevenSegDisplayTextures textures;
    textures.horzOff.loadFromFile("assets/horz_segment_off.png");
    textures.horzOn.loadFromFile("assets/horz_segment_on.png");
    textures.vertOff.loadFromFile("assets/vert_segment_off.png");
    textures.vertOn.loadFromFile("assets/vert_segment_on.png");
    textures.decimalOff.loadFromFile("assets/dp_segment_off.png");
    textures.decimalOn.loadFromFile("assets/dp_segment_on.png");

    const int NumSegments = 2;
    SerInParOutShiftReg<NumSegments> shiftReg;

    SevenSegDisplay segments[NumSegments] = { SevenSegDisplay(textures), SevenSegDisplay(textures)};

    sf::Vector2f pos = {250.0f, 100.0f};
    for(int idx = NumSegments-1; idx >= 0; idx--) {
        segments[idx].position = pos;
        pos.x -= 130.0f;
    }

    float simAmount = 0.0f;
    // Start the game loop
    while (renderWin->isOpen())
    {
        // Process events
        sf::Event event;
        while (renderWin->pollEvent(event))
        {
            // Close window: exit
            if (event.type == sf::Event::Closed)
                renderWin->close();
        }

        simAmount += AmountSimulationTicksPerFrame;
        while (simAmount > 1.0f)
        {
            tb.tick();

            // For every tick, we evaluate the pins in our shift register
            shiftReg.update(
                tb.mCore->PIN_1,
                tb.mCore->PIN_2,
                tb.mCore->PIN_3
            );

            if(tb.mCore->PIN_2) {
                printf("%d ", tb.mCore->PIN_1);
            }
            if (tb.mCore->PIN_3) {
                console->info(
                        "tick! seg_out={:016b}, our_reg={:08b} {:08b}", 
                        tb.mCore->o_seg_out, 
                        shiftReg.getSubByte(1),
                        shiftReg.getSubByte(0)
                    );
            }
            simAmount -= 1.0f;
        }

        // Clear screen
        renderWin->clear();

        for(int idx = 0; idx < NumSegments; idx++) {
            for(int ii = 0; ii < SegmentMax; ++ii) {
                auto whichBit = idx*SegmentMax+ii;
                segments[idx].setSegment(static_cast<Segment>(ii), shiftReg.getBitValue(whichBit));
            }

            segments[idx].draw(*renderWin.get());
        }

        // Update the window
        renderWin->display();
    }

    tb.closeTrace();
}
