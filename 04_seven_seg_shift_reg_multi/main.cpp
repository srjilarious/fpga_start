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
constexpr float AmountSimulationTicksPerFrame = 1 / 10.0f;

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vtop>>();

    tb->openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("sim");
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

    SerInParOutShiftReg<unsigned char> shiftReg;

    SevenSegDisplay seg(textures);
    seg.position = sf::Vector2f(100.0f, 100.0f);

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
            tb->tick();

            // For every tick, we evaluate the pins in our shift register
            shiftReg.update(
                tb->m_core->PIN_1,
                tb->m_core->PIN_2,
                tb->m_core->PIN_3
            );

            if(tb->m_core->PIN_2) {
                printf("%d ", tb->m_core->PIN_1);
            }
            if (tb->m_core->PIN_3) {
                console->info(
                        "tick! num={:x}, seg_out={:x}, our_reg={:x}", 
                        tb->m_core->o_num, 
                        tb->m_core->o_seg_out, 
                        shiftReg.getLatchedValue()
                    );
            }
            simAmount -= 1.0f;
        }

        //sf::Color clearColor = sf::Color( 64, tb->m_core->LED ? 128 : 64, 64, 255);

        // Clear screen
        renderWin->clear();// clearColor);

        for(int ii = 0; ii < SegmentMax; ++ii) {
            seg.setSegment(static_cast<Segment>(ii), shiftReg.getBitValue(ii));
        }

        seg.draw(*renderWin.get());

        // Update the window
        renderWin->display();
    }

    tb->closeTrace();
}
