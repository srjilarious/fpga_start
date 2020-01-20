#include "../support/TestBench.h"
#include "obj_dir/Vtop.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <SFML/Graphics.hpp>

#include "SevenSegDisplay.h"

#include <memory>

// In simulation we have the states change every 64 ticks, so we have a 
// relatively low number of overall ticks to see if our circuit is working.
constexpr float AmountSimulationTicksPerFrame = 1/60.0f;

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vtop>>();

    tb->openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("game");
    console->info("Seven Segment Parallel Simulation!");

    auto renderWin = std::make_unique<sf::RenderWindow>(
                sf::VideoMode(800, 600), "Seven Segment Display Simulation");

    SevenSegDisplayTextures textures;
    textures.horzOff.loadFromFile("assets/horz_segment_off.png");
    textures.horzOn.loadFromFile("assets/horz_segment_on.png");
    textures.vertOff.loadFromFile("assets/vert_segment_off.png");
    textures.vertOn.loadFromFile("assets/vert_segment_on.png");
    textures.decimalOff.loadFromFile("assets/dp_segment_off.png");
    textures.decimalOn.loadFromFile("assets/dp_segment_on.png");

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
        while(simAmount > 1.0f)
        {
            tb->tick();
            console->info(".");

            simAmount -= 1.0f;
        }


        //sf::Color clearColor = sf::Color( 64, tb->m_core->LED ? 128 : 64, 64, 255);

        // Clear screen
        renderWin->clear();// clearColor);

        seg.setSegment(Segment::A, tb->m_core->PIN_1);
        seg.setSegment(Segment::B, tb->m_core->PIN_2);
        seg.setSegment(Segment::C, tb->m_core->PIN_3);
        seg.setSegment(Segment::D, tb->m_core->PIN_4);
        seg.setSegment(Segment::E, tb->m_core->PIN_5);
        seg.setSegment(Segment::F, tb->m_core->PIN_6);
        seg.setSegment(Segment::G, tb->m_core->PIN_7);
        seg.setSegment(Segment::DP, tb->m_core->PIN_8);

        seg.draw(*renderWin.get());

        // Update the window
        renderWin->display();
    }

    tb->closeTrace();
}
