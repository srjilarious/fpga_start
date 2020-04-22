#include "../support/TestBench.h"
#include "Vtop.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <SFML/Graphics.hpp>

#include "SevenSegDisplay.h"

#include <memory>

constexpr float AmountSimulationTicksPerFrame = 1/60.0f;

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vtop>>();

    // Uncomment if you want the waveform to be generated.
    //tb->openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("simulation");
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

        // Clear screen
        renderWin->clear();

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
