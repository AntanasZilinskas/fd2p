from music21 import stream, note, chord
import pygame
import time
import chord_search
import pandas as pd
import json

def play_notes_timed(notes):
    """
    Plays a sequence of notes or chords with timing.

    Parameters:
        notes (list): A list of tuples with (offset, notes).
                      Offset is the timing in beats or milliseconds.
                      Notes are single notes (e.g., 'C4') or chords (lists of notes, e.g., ['C4', 'E4', 'G4']).
    """
    # Create a music21 stream
    s = stream.Stream()

    # Add notes or chords to the stream at specified offsets
    for offset, n in notes:
        if isinstance(n, list):  # If it's a chord
            chord_notes = [note.Note(p) for p in n]
            c = chord.Chord(chord_notes)
            c.offset = offset
            s.append(c)
        else:  # It's a single note
            n_note = note.Note(n)
            n_note.offset = offset
            s.append(n_note)

    # Write the stream to a MIDI file
    midi_file = "output_timed.mid"
    s.write('midi', fp=midi_file)

    # Initialize pygame mixer
    pygame.mixer.init()

    # Load the MIDI file
    pygame.mixer.music.load(midi_file)

    # Play the MIDI file
    print("Playing...")
    pygame.mixer.music.play()

    # Wait until the playback is done
    while pygame.mixer.music.get_busy():
        time.sleep(0.1)

    print("Done playing.")


def midi_to_note_name(pitch):
    """Convert a MIDI pitch value to a note name with an octave."""
    note_names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    octave = (pitch // 12) - 1
    note = note_names[pitch % 12]
    return f"{note}{octave}"


def convert_notes_to_timed_format(notes_dict):
    """
    Convert a dictionary of notes into a list of timed notes and chords.

    Parameters:
        notes_dict (dict): Input dictionary containing note information.

    Returns:
        list: A list of tuples with (offset, notes).
    """
    notes = notes_dict['notes']
    grouped_notes = {}

    # Group notes by their time
    for note in notes:
        time = note['time'] / 1000  # Convert time from ms to seconds
        note_name = midi_to_note_name(note['pitch'])
        if time not in grouped_notes:
            grouped_notes[time] = []
        grouped_notes[time].append(note_name)

    # Create the output format: (offset, notes)
    result = []
    for time in sorted(grouped_notes):
        note_group = grouped_notes[time]
        if len(note_group) == 1:
            result.append((time, note_group[0]))  # Single note
        else:
            result.append((time, note_group))    # Chord

    return result


def play_notes_from_json(json_in):
    timed_notes = convert_notes_to_timed_format(json_in)
    print(timed_notes)
    play_notes_timed(timed_notes)


def play_from_file(path):
    # given a music file (formatted as PDMX does), play it out
    
    with open(path, 'r') as file:
        data = json.load(file)

    tracks = chord_search.combine_tracks(data["tracks"])

    play_notes_from_json(tracks)
    
# EXAMPLE: play from a given json of notes
# notes_input = {'notes': [{'__class__.__name__': 'Note', 'time': 20040, 'pitch': 64, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 14, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 20040, 'pitch': 71, 'duration': 120, 'velocity': 64, 'pitch_str': 'B', 'measure': 14, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 20160, 'pitch': 64, 'duration': 480, 'velocity': 64, 'pitch_str': 'E', 'measure': 15, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 20160, 'pitch': 75, 'duration': 480, 'velocity': 64, 'pitch_str': 'D#', 'measure': 15, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 20640, 'pitch': 64, 'duration': 480, 'velocity': 64, 'pitch_str': 'E', 'measure': 15, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 20640, 'pitch': 73, 'duration': 480, 'velocity': 64, 'pitch_str': 'C#', 'measure': 15, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 21120, 'pitch': 64, 'duration': 360, 'velocity': 64, 'pitch_str': 'E', 'measure': 15, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 21120, 'pitch': 69, 'duration': 360, 'velocity': 64, 'pitch_str': 'A', 'measure': 15, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 21480, 'pitch': 61, 'duration': 120, 'velocity': 64, 'pitch_str': 'C#', 'measure': 15, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 21480, 'pitch': 66, 'duration': 120, 'velocity': 64, 'pitch_str': 'F#', 'measure': 15, 'is_grace': False}]}
# notes_input = {'notes': [{'__class__.__name__': 'Note', 'time': 0, 'pitch': 52, 'duration': 360, 'velocity': 64, 'pitch_str': 'E', 'measure': 1, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 0, 'pitch': 56, 'duration': 360, 'velocity': 64, 'pitch_str': 'G#', 'measure': 1, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 360, 'pitch': 52, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 1, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 360, 'pitch': 57, 'duration': 120, 'velocity': 64, 'pitch_str': 'A', 'measure': 1, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 1440, 'pitch': 52, 'duration': 840, 'velocity': 64, 'pitch_str': 'E', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 1440, 'pitch': 59, 'duration': 840, 'velocity': 64, 'pitch_str': 'B', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2280, 'pitch': 52, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2280, 'pitch': 59, 'duration': 120, 'velocity': 64, 'pitch_str': 'B', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2400, 'pitch': 52, 'duration': 360, 'velocity': 64, 'pitch_str': 'E', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2400, 'pitch': 61, 'duration': 360, 'velocity': 64, 'pitch_str': 'C#', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2760, 'pitch': 52, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2760, 'pitch': 59, 'duration': 120, 'velocity': 64, 'pitch_str': 'B', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2880, 'pitch': 52, 'duration': 480, 'velocity': 64, 'pitch_str': 'E', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2880, 'pitch': 58, 'duration': 480, 'velocity': 64, 'pitch_str': 'A#', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 3360, 'pitch': 52, 'duration': 480, 'velocity': 64, 'pitch_str': 'E', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 3360, 'pitch': 59, 'duration': 480, 'velocity': 64, 'pitch_str': 'B', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 3840, 'pitch': 52, 'duration': 360, 'velocity': 64, 'pitch_str': 'E', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 3840, 'pitch': 59, 'duration': 360, 'velocity': 64, 'pitch_str': 'B', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 4200, 'pitch': 52, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 4200, 'pitch': 59, 'duration': 120, 'velocity': 64, 'pitch_str': 'B', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 0, 'pitch': 64, 'duration': 360, 'velocity': 64, 'pitch_str': 'E', 'measure': 1, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 0, 'pitch': 64, 'duration': 360, 'velocity': 64, 'pitch_str': 'E', 'measure': 1, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 360, 'pitch': 64, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 1, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 360, 'pitch': 66, 'duration': 120, 'velocity': 64, 'pitch_str': 'F#', 'measure': 1, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 1440, 'pitch': 64, 'duration': 840, 'velocity': 64, 'pitch_str': 'E', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 1440, 'pitch': 68, 'duration': 840, 'velocity': 64, 'pitch_str': 'G#', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2280, 'pitch': 64, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2280, 'pitch': 68, 'duration': 120, 'velocity': 64, 'pitch_str': 'G#', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2400, 'pitch': 64, 'duration': 360, 'velocity': 64, 'pitch_str': 'E', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2400, 'pitch': 69, 'duration': 360, 'velocity': 64, 'pitch_str': 'A', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2760, 'pitch': 64, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2760, 'pitch': 68, 'duration': 120, 'velocity': 64, 'pitch_str': 'G#', 'measure': 2, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2880, 'pitch': 66, 'duration': 480, 'velocity': 64, 'pitch_str': 'F#', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 2880, 'pitch': 73, 'duration': 480, 'velocity': 64, 'pitch_str': 'C#', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 3360, 'pitch': 68, 'duration': 480, 'velocity': 64, 'pitch_str': 'G#', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 3360, 'pitch': 71, 'duration': 480, 'velocity': 64, 'pitch_str': 'B', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 3840, 'pitch': 68, 'duration': 360, 'velocity': 64, 'pitch_str': 'G#', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 3840, 'pitch': 76, 'duration': 360, 'velocity': 64, 'pitch_str': 'E', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 4200, 'pitch': 68, 'duration': 120, 'velocity': 64, 'pitch_str': 'G#', 'measure': 3, 'is_grace': False}, {'__class__.__name__': 'Note', 'time': 4200, 'pitch': 76, 'duration': 120, 'velocity': 64, 'pitch_str': 'E', 'measure': 3, 'is_grace': False}]}
# pattern = notes_input["notes"]
# chord_print = {'tracks': [{'notes': pattern}]}
# # mvp_chordmatch.display_track(chord_print)
# play_notes_from_json(notes_input)


# EXAMPLE: Play from PDMX json file
paths = pd.read_csv("PDMX data/subset_paths/all.txt")
path = paths["path"][0]
path = "PDMX data" + path.lstrip(".")
path = "PDMX data/data/b/r/QmbrFo56yuFBSFwKJFzjsSh2m2EXAcV3jTmW4z8ZPrU4vp.json"

play_from_file(path)