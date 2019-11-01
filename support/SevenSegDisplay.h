/*
  A class to simulate the display of a seven segment display.
 */

#pragma once

#include <array>
#include <SFML/Graphics.hpp>

enum class Segment 
{
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    DP
};

constexpr size_t SegmentMax = (int)Segment::DP + 1;

struct SevenSegDisplayTextures {
    sf::Texture horzOff, horzOn;
    sf::Texture vertOff, vertOn;
    sf::Texture decimalOff, decimalOn;
};

class SevenSegDisplay
{
public:
    SevenSegDisplay(const SevenSegDisplayTextures& textures);

    void setSegment(Segment, bool on);

    void draw(sf::RenderWindow& window) const;

    sf::Vector2f position;

private:
    std::array<sf::Sprite, SegmentMax> mSegments;
    const SevenSegDisplayTextures& mTextures;
};
