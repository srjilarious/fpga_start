#include "../support/TestBench.h"
#include "Vstate_machine.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <SFML/Graphics.hpp>

#include <memory>

struct TB : public TestBench<Vstate_machine>
{
    virtual ~TB() = default;

    // We overload the setClock signal method so we can reference different
    // clock signals for different FPGA boards.
    void setClock(uint8_t val) { mCore->i_clk = val; }
};

// In simulation we have the states change every 64 ticks, so we have a 
// relatively low number of overall ticks to see if our circuit is working.
constexpr float AmountSimulationTicksPerFrame = 1/60.0f;

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    TB tb;

    // For this example we won't worry about generating a wave trace.
    //tb->openTrace("trace.vcd");

    auto console = spdlog::stdout_color_mt("simulation");
    console->info("SFML State Machine Example!");

    auto renderWin = std::make_unique<sf::RenderWindow>(
                sf::VideoMode(800, 600), "Seven Segment Display Simulation");


    float simAmount = 0.0f;

    // Start the simulation loop
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
            tb.tick();
            console->info(".");
            simAmount -= 1.0f;
        }


        sf::Color clearColor = sf::Color( 64, tb.mCore->o_led ? 128 : 64, 64, 255);

        // Clear screen
        renderWin->clear( clearColor);

        // Update the window
        renderWin->display();
    }

    tb.closeTrace();
}
