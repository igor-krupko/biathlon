# Audio Setup for Biathlon App

This document explains how to set up audio files for the biathlon app to provide realistic shooting sounds and crowd reactions.

## Audio Files Required

Place the following audio files in the `assets/audio/` directory:

### Shooting Sounds
- `shooting_sound.wav` - Rifle shooting sound effect
- `crowd_hit.wav` - Crowd cheering when a target is hit
- `crowd_miss.wav` - Crowd reaction when a target is missed
- `crowd_perfect.wav` - Special crowd reaction for perfect shooting rounds (5/5 hits)
- `background_ambience.wav` - Background stadium/venue ambience

## Audio Features

### 1. Shooting Sounds
- Plays when a shot is fired
- Can be enabled/disabled in settings
- Volume controlled by master volume slider

### 2. Crowd Reactions
- **Hit Sound**: Plays when a target is successfully hit
- **Miss Sound**: Plays when a target is missed
- **Perfect Round Sound**: Special celebration when all 5 targets are hit
- Can be enabled/disabled independently in settings

### 3. Background Ambience
- Plays during races to create atmosphere
- Loops continuously during the race
- Stops automatically when leaving the race screen
- Can be enabled/disabled in settings

## Settings Controls

The app provides granular audio controls in the Settings screen:

- **Master Sound Toggle**: Enable/disable all sounds
- **Shooting Sounds**: Enable/disable rifle shooting sounds
- **Crowd Reactions**: Enable/disable crowd cheers and reactions
- **Background Ambience**: Enable/disable background stadium sounds
- **Volume Slider**: Control overall sound volume (0-100%)

## Audio File Recommendations

### Shooting Sound
- Duration: 0.5-1 second
- Format: WAV, 44.1kHz, 16-bit
- Should be a realistic rifle shot sound

### Crowd Sounds
- Duration: 1-3 seconds
- Format: WAV, 44.1kHz, 16-bit
- **Hit**: Cheering, applause
- **Miss**: Disappointed murmurs, gasps
- **Perfect**: Extended celebration, loud cheers

### Background Ambience
- Duration: 30-60 seconds (will loop)
- Format: WAV, 44.1kHz, 16-bit
- Should be subtle stadium/venue background noise
- Avoid sudden loud sounds that could be jarring

## Implementation Notes

- Audio files are loaded asynchronously
- Missing audio files are handled gracefully (errors logged but app continues)
- Audio settings are persisted using SharedPreferences
- Background ambience automatically stops when leaving race screen
- All audio respects the master volume setting
- **Realistic timing**: Shooting sound plays immediately, crowd reactions follow after a 300ms delay
- **Perfect round timing**: Special celebration plays after a 500ms delay for dramatic effect
- **Visual feedback**: Flash animation on misses is synchronized with crowd reaction timing
- **Completion delay**: 800ms delay after last shot before returning to race

## Testing Audio

1. Start a race
2. Go to shooting phase
3. Take shots and listen for:
   - Shooting sound on each shot
   - Crowd reaction for hits/misses
   - Special sound for perfect rounds
4. Check background ambience during race
5. Test volume controls in settings

## Troubleshooting

If audio doesn't work:
1. Check that audio files are in the correct location
2. Verify file names match exactly
3. Check device volume settings
4. Ensure audio settings are enabled in the app
5. Check console logs for audio loading errors 