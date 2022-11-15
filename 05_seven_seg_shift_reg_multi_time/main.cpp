#include "../support/TestBench.h"
#include "Vtop.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <SFML/Graphics.hpp>

#include "SevenSegDisplay.h"
#include "SerInParOutShiftReg.h"

#include <memory>

// In simulation we have the states change every 64 ticks, so we have a 
// relatively low number of overall ticks to see if our circuit is working.
constexpr float AmountSimulationTicksPerFrame = 4.0f;

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

    const int NumShiftRegs = 2;
    SerInParOutShiftReg<NumShiftRegs> shiftReg;

    const int NumSegments = 3;
    SevenSegDisplay segments[NumSegments] = { 
            SevenSegDisplay(textures), 
            SevenSegDisplay(textures),
            SevenSegDisplay(textures)
        };

    sf::Vector2f pos = {100.0f, 100.0f};
    for(int idx = NumSegments-1; idx >= 0; --idx) {
        segments[idx].position = pos;
        pos.x += 130.0f;
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
                        //"tick! num={:x}, seg_out={:x}, our_reg={:x}", 
                        "tick! curr seg = {:08b}, seg display = {:02x}", 
                        shiftReg.getSubByte(1),
                        shiftReg.getSubByte(0)
                    );
            }
            simAmount -= 1.0f;
        }

        // Clear screen
        renderWin->clear();

        auto currSegmentOneHot = shiftReg.getSubByte(0);
        decltype(currSegmentOneHot) currSegment = 0;

        switch(currSegmentOneHot) {
            case 0b001: 
                currSegment = 0;
                break;

            case 0b010: 
                currSegment = 1;
                break;

            case 0b100: 
                currSegment = 2;
                break;

            default: 
                currSegment = 0;
                break;
        }

        for(int idx = 0; idx < NumSegments; ++idx) {
            if(shiftReg.getSubByte(1) != 0) {    
                for(int ii = 0; ii < SegmentMax; ++ii) {
                    if(idx == currSegment) {
                        segments[currSegment].setSegment(static_cast<Segment>(ii), shiftReg.getBitValue(ii+8));
                    }
                    else {
                        //segments[idx].setSegment(static_cast<Segment>(ii), false);
                    }
                }
            }
                
            segments[idx].draw(*renderWin.get());
        }

        // Update the window
        renderWin->display();
    }

    tb.closeTrace();
}
