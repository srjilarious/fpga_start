#include "../support/TestBench.h"
#include "Vtop.h"

#include <memory>
#include <chrono>
#include <thread>
#include <SFML/Graphics.hpp>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <memory>

// 640x480 timing constants:
// const int HorzPixelCount = 640;
// const int HorzFrontPorch = 16;
// const int HorzSyncPulse = 96;
// const int HorzBackPorch = 48;

// const int VertPixelCount = 480;
// const int VertFrontPorch = 10;
// const int VertSyncPulse = 2;
// const int VertBackPorch = 33;

// 800x600 @ 60Hz timing constants:
const int HorzPixelCount = 800;
const int HorzFrontPorch = 40;
const int HorzSyncPulse = 128;
const int HorzBackPorch = 88;
const int VertPixelCount = 600;
const int VertFrontPorch = 1;
const int VertSyncPulse = 4;
const int VertBackPorch = 23;

const int HorzScanLineCycles = HorzPixelCount + HorzFrontPorch + HorzSyncPulse + HorzBackPorch;
const int VertCycles = VertPixelCount + VertFrontPorch + VertSyncPulse + VertBackPorch;

// The number of cycles our module needs to run per frame to generate a frame.
const int NumSimulationTicksPerFrame = HorzScanLineCycles*VertCycles;

#define DUMP_SINGLE_FRAME 1

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<TestBench<Vtop>>();

    #if DUMP_SINGLE_FRAME
        tb->openTrace("trace.vcd");
    #endif

    auto console = spdlog::stdout_color_mt("simulation");
    console->info("Welcome to the sprite test!");

    sf::String name = "VGA Sprite Test";
    auto renderWin = std::make_shared<sf::RenderWindow>(
            sf::VideoMode(HorzPixelCount, VertPixelCount), 
            name
        );

    unsigned char *pixelArray = new unsigned char[HorzPixelCount*VertPixelCount*4];

    int frameCounter = 0;

    sf::Texture texture;
    texture.create(HorzPixelCount, VertPixelCount);

    sf::Sprite sprite;

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

        // Handle ticking our module the number of ticks per frame.
        int horzCounter = 0;
        int vertCounter = 0;
        int pixIdx = 0;
        for(int ii = 0; ii < NumSimulationTicksPerFrame; ii++)
        {
            tb->tick();

            if(horzCounter < HorzPixelCount && vertCounter < VertPixelCount) 
            {
                // Take the output and create a pixel from it.
                pixelArray[pixIdx] = (tb->m_core->PIN_3 << 7) | (tb->m_core->PIN_2 << 6) | (tb->m_core->PIN_1 << 5);
                pixelArray[pixIdx+1] = (tb->m_core->PIN_6 << 7) | (tb->m_core->PIN_5 << 6) | (tb->m_core->PIN_4 << 5);
                pixelArray[pixIdx+2] = (tb->m_core->PIN_8 << 7) | (tb->m_core->PIN_7 << 6);
                pixelArray[pixIdx+3] = 0xff;
                pixIdx+=4;
            }

            horzCounter++;
            if(horzCounter >= HorzScanLineCycles) {
                horzCounter = 0;
                vertCounter++;
                if(vertCounter >= VertCycles) {
                    vertCounter = 0;
                }
            }
        }

        // Clear screen
        renderWin->clear(sf::Color(128, 255, 255, 255));

        console->info("frame {}\n", frameCounter);
        frameCounter++;

        sf::Image img;
        img.create(HorzPixelCount, VertPixelCount, (sf::Uint8 *)pixelArray);
        texture.update(img);

        sprite.setTexture(texture);

        renderWin->draw(sprite);
        // Update the window
        renderWin->display();

        //std::this_thread::sleep_for (std::chrono::seconds(1));

        #if DUMP_SINGLE_FRAME
            break;
        #endif
    }

    #if DUMP_SINGLE_FRAME
        tb->closeTrace();
    #endif

    delete [] pixelArray;

    return 0;
}
