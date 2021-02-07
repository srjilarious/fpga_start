#include "../support/TestBench.h"
#include "Vtop.h"

#include <memory>
#include <chrono>
#include <thread>
#include <SFML/Graphics.hpp>
#include <SFML/Window/Keyboard.hpp>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <imgui.h>
#include <imgui_stdlib.h>
#include <imgui-SFML.h>

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

// We by default run less than a full frame of ticks so that our debugging gui has time
// to service events.
const int NumSimulationTicksPerFrame = 10000;

// The number of cycles our module needs to run per frame to generate a frame.
const int NumTicksForVGAFrame = HorzScanLineCycles*VertCycles;
//#define DUMP_SINGLE_FRAME 1

struct SimContext
{
    SimContext();
    ~SimContext();

    std::shared_ptr<sf::RenderWindow> renderWin;

    std::unique_ptr<TestBench<Vtop>> tb;
    bool advanceFrame = true;

    unsigned char *pixelArray = new unsigned char[HorzPixelCount*VertPixelCount*4];

    int frameCounter = 0;
    int subFrameCount = 0;

    sf::Texture texture;
    sf::Sprite sprite;

    bool spaceDown = false;

    sf::Clock deltaClock;
    bool paused = false;
    bool optionsOpen = true;

    // Handle ticking our module the number of ticks per frame.
    int horzCounter = 0;
    int vertCounter = 0;
    int pixIdx = 0;

    std::shared_ptr<spdlog::logger> console;

    bool update();
    void render();
};


SimContext::SimContext()
{
    tb = std::make_unique<TestBench<Vtop>>();

    console = spdlog::stdout_color_mt("simulation");
    console->info("Welcome to the tile screen test!");

    sf::String name = "VGA Tile Screen Test";
    renderWin = std::make_shared<sf::RenderWindow>(
            sf::VideoMode(HorzPixelCount, VertPixelCount), 
            name
        );

    texture.create(HorzPixelCount, VertPixelCount);

    ImGui::SFML::Init(*renderWin);
}


SimContext::~SimContext()
{
    delete [] pixelArray;
}


bool 
SimContext::update()
{
    ImGui::SFML::Update(*renderWin, deltaClock.restart());

    if(!spaceDown && sf::Keyboard::isKeyPressed(sf::Keyboard::Key::Space)) {
        advanceFrame = !advanceFrame;
        spaceDown = true;
    }
    else if(spaceDown && !sf::Keyboard::isKeyPressed(sf::Keyboard::Key::Space)) {
        spaceDown = false;
    }
        

    if(advanceFrame && !paused) 
    {
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

            subFrameCount++;
            if(subFrameCount >= NumTicksForVGAFrame) {
                subFrameCount = 0;
                horzCounter = 0;
                vertCounter = 0;
                pixIdx = 0;

                console->info("frame {}\n", frameCounter);
                frameCounter++;

                texture.update((sf::Uint8 *)pixelArray, HorzPixelCount, VertPixelCount, 0, 0);

                sprite.setTexture(texture);

                return true;
            }
        }
    }

    return false;
}

void 
SimContext::render()
{
    // begin debugger GUI window
    ImGui::Begin("Simulation Options##ToolWin", &optionsOpen); 
        
        if (ImGui::Button("Toggle Pause")) {
            console->info("!!!! PAUSED !!!");
            paused = !paused;
        }
        
    ImGui::End();

    // Clear screen
    renderWin->clear(sf::Color(128, 255, 255, 255));
    renderWin->draw(sprite);
        
    renderWin->resetGLStates();
    ImGui::SFML::Render();

    // Update the window
    renderWin->display();
}


int 
main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);
    
    #if DUMP_SINGLE_FRAME
        tb->openTrace("trace.vcd");
    #endif

    SimContext ctxt;
    
    // Start the game loop
    while (ctxt.renderWin->isOpen())
    {
        // Process events
        sf::Event event;
        while (ctxt.renderWin->pollEvent(event))
        {
            ImGui::SFML::ProcessEvent(event);

            // Close window: exit
            if (event.type == sf::Event::Closed)
                ctxt.renderWin->close();
        }

        ctxt.update();
        ctxt.render();

        #if DUMP_SINGLE_FRAME
            break;
        #endif
    }

    #if DUMP_SINGLE_FRAME
        tb->closeTrace();

        while (renderWin->isOpen())
        {
            // Leave frame displayed, but wait for close event.
            sf::Event event;
            while (renderWin->pollEvent(event))
            {
                // Close window: exit
                if (event.type == sf::Event::Closed)
                    renderWin->close();
            }
        }
    #endif


    return 0;
}
