
#include <SFML/Graphics.hpp>

#include "SevenSegDisplay.h"

SevenSegDisplay::SevenSegDisplay(
        const SevenSegDisplayTextures& textures
    ) : mTextures(textures)
{
    for(int ii = 0; ii < SegmentMax; ++ii) {
        setSegment((Segment)ii, false);
    }

    // Move the individual segments into position
    mSegments[(int)Segment::A].setPosition(48, 0);
    mSegments[(int)Segment::B].setPosition(160, 64);
    mSegments[(int)Segment::C].setPosition(160, 256);
    mSegments[(int)Segment::D].setPosition(48, 384);
    mSegments[(int)Segment::E].setPosition(0, 256);
    mSegments[(int)Segment::F].setPosition(48, 192);
    mSegments[(int)Segment::G].setPosition(0, 64);
    mSegments[(int)Segment::DP].setPosition(222, 404);
}

void 
SevenSegDisplay::setSegment(
        Segment which, bool on
    )
{
    switch(which) 
    {
        // Vertical segments:
        case Segment::B:
        case Segment::C:
        case Segment::E:
        case Segment::G:
            mSegments[(int)which].setTexture(on ?
                mTextures.vertOn : mTextures.vertOff
            );
            break;

        // Horizontal segments:
        case Segment::A:
        case Segment::D:
        case Segment::F:
            mSegments[(int)which].setTexture(on ?
                mTextures.horzOn : mTextures.horzOff
            );
            break;

        // Decimal point:
        case Segment::DP:
            mSegments[(int)which].setTexture(on ?
                mTextures.decimalOn : mTextures.decimalOff
            );
            break;

        default:
            break;
    }
}

void 
SevenSegDisplay::draw(sf::RenderWindow& window) const
{
    sf::Transform translation;
    translation.translate(position);
	translation.scale(0.5f, 0.5f);
    for(int ii = 0; ii < SegmentMax; ++ii) {
        window.draw(mSegments[ii], translation);
    }
}
