# fd2p
Repository dedicated to coursework development

Shiny components available:
https://shiny.posit.co/r/components/
Useful resources for shiny extensions:
https://github.com/nanxstats/awesome-shiny-extensions?tab=readme-ov-file#special-input

Dataset links:
https://zenodo.org/records/14004826


How to use:

assumes the PDMX dataset is extracted and present in the source folder as "PDMX data"

Install the couple dependancies





## What can we match people's music tastes on:
Rhythmic Complexity
    - steady, straightforward rhythms
    - intricacy with syncopation

Melodic Contour
    - Singable Melodies
    - Ornamentation and Virtuosity

Timbre and Instrumentation
	- Acoustic vs. Electronic
	- Vocal vs. Instrumental

Form and Structure
    - Repetitive Patterns
    - Unpredictability

Dynamics and Energy
	- High Energy
	- Subtlety

Tempo and Mood
	- Energetic/Upbeat
	- Relaxing/Somber

Chord progressions and moods
    - some keys and chords are sad, happy, pensive etc.

Harmonic Language
	- Consonance: consonant harmonies (pleasant, stable-sounding intervals) is common in pop, classical, and folk music.
	- Dissonance: Some listeners enjoy the tension and resolution of dissonant harmonies, as found in jazz, avant-garde, or experimental music.
    - Modal vs. Tonal: Fans of modal music (e.g., traditional folk or medieval music) enjoy different scales and modes, while tonal music adheres to traditional major/minor scales.


## Features to get from dataset:
	Melodic:
    - Note intervals and sequences.
    - Melodic contour (e.g., rising or falling patterns).
	
    Harmonic:
    - Chord progressions
    - Tonality (major/minor).
    
    Rhythmic:
    - Average note duration.
	- Syncopation or rhythmic complexity.
	
    Structural:
    - Repeated sections or patterns (e.g., verse/chorus structures).
    - Phrase lengths.

```
data = {
    'song_id': [song_id],
    'average_duration': [average_duration],
    'syncopation_rate': [syncopation_rate],
    'key': [str(song_key)],
    'num_repeated_patterns': [len(repeated_patterns)],
    'phrase_lengths': [phrase_lengths],
    # Add other features here
}
```



## Current Progress:
[.] View scores and snippets
