import pandas as pd
import json
from tqdm import tqdm

def load_song(file_path):
    """Load a single song from a JSON file."""
    try:
        with open(file_path, 'r') as f:
            song = json.load(f)
        return song
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return None

def create_events(notes):
    """
    Given a list of notes, create a list of events (ie notes grouped by time)
    Each event is a dictionary with 'time' and 'notes' (list of notes at that time).
    """
    events_dict = {}
    for note in notes:
        time = note['time']
        if time not in events_dict:
            events_dict[time] = []
        events_dict[time].append(note)
    # Create a list of events, sorted by time
    events = [{'time': time, 'notes': events_dict[time]} for time in sorted(events_dict.keys())]
    return events

def chord_match(event1_notes, event2_notes, keys_to_match):
    """
    Compare two events (lists of notes) to see if they match, considering only specific keys.
    TODO update to have certain keys be a fuzzy rather than exact match, eg duration or velocity
    Parameters:
        event1_notes (list): List of notes from the song (at a given time).
        event2_notes (list): List of notes from the pattern (at a given time).
        keys_to_match (list): Keys to consider for matching.
        
    Returns:
    
        bool: True if the events match considering the specified keys, False otherwise.
    """
    if len(event1_notes) != len(event2_notes):
        return False

    # Sort notes by pitch (or another specified key for consistency in order)
    event1_notes_sorted = sorted(event1_notes, key=lambda n: n['pitch'])
    event2_notes_sorted = sorted(event2_notes, key=lambda n: n['pitch'])

    for note1, note2 in zip(event1_notes_sorted, event2_notes_sorted):
        for key in keys_to_match:
            if key not in note1 or key not in note2 or note1[key] != note2[key]:
                return False
    return True

def pattern_in_song(song_events, pattern_events):
    """
    Check if the pattern exists within the song's events - convolve
    Parameters:
        song_events (list): List of events (notes grouped by time)
        pattern_events (list): A pattern of notes (also grouped by time) to search for

    Returns:
        bool: True if the pattern exists in the song
    """
    pattern_length = len(pattern_events)
    for i in range(len(song_events) - pattern_length + 1):
        match = True
        for j in range(pattern_length):
            song_event_notes = song_events[i + j]['notes']
            pattern_event_notes = pattern_events[j]['notes']
            if not chord_match(song_event_notes, pattern_event_notes, ["pitch"]):
                match = False
                break
        if match:
            return True
    return False

def search_songs(paths_df, pattern_events):
    """
    Search for songs that contain the pattern of notes.

    Params:
        paths_df (dataframe): Df of all json file paths
        pattern_events (list): pattern of notes to search for

    Returns:
        matching_songs (list): a list of dicts each containing file path and song names
    """
    matching_songs = []
    for index, row in tqdm(paths_df.iterrows(), total=len(paths_df)):
        file_path = row['path']  # Assuming 'path' is the column name in your DataFrame
        file_path = "PDMX data" + file_path.lstrip(".")

        song = load_song(file_path)
        if song is None:
            continue  # Skip this file if it couldn't be loaded
        song_title = song.get('metadata', {}).get('title', 'Unknown Title')
        for track in song.get('tracks', []):
            track_notes = track.get('notes', [])
            song_events = create_events(track_notes)
            if pattern_in_song(song_events, pattern_events):
                matching_songs.append({file_path: song_title})
                break  # Stop searching this song if pattern is found
    return matching_songs

def combine_tracks(tracks):
    """
    Combine tracks from a song into one, eg bass and treble cleffs
    params:
        tracks (list): list of tracks, each containing a list of notes, chords etc
    
    Returns;
        combined_tracks (list): a list of notes, chords etc, of the entire song played in one go
    """
    combined_track = {
        '__class__.__name__': 'Track',
        'program': 0,  # Choose an appropriate value or handle dynamically
        'is_drum': False,
        'name': 'Combined Track',
        'notes': [],
        'chords': [],
        'lyrics': []
    }

    # Merge notes, chords, and lyrics
    for track in tracks:
        combined_track['notes'].extend(track.get('notes', []))
        combined_track['chords'].extend(track.get('chords', []))
        combined_track['lyrics'].extend(track.get('lyrics', []))

    # Sort the lists by time
    combined_track['notes'].sort(key=lambda x: x['time'])
    combined_track['chords'].sort(key=lambda x: x['time'])
    combined_track['lyrics'].sort(key=lambda x: x['time'])

    # Handle overlaps and conflicts if necessary
    # For example, adjust velocities or durations

    return combined_track

def display_track(song, part_to_display=None):
    """
    Display the bass and treble tracks of a song, or a single part if specified.
    
    Params:
        song (dict): The song data containing tracks.
        part_to_display (str): Optional, specify "treble" or "bass" to display only that part.
    """
    from music21 import stream, note, chord, duration

    # Create a score to hold the bass and treble parts
    score = stream.Score()
    bass_part = stream.Part(id='Bass')
    treble_part = stream.Part(id='Treble')

    TICKS_PER_QUARTER = 480  # Adjust this based on your time resolution

    # Separate the first track as treble and the rest as bass
    tracks = song.get('tracks', [])
    treble_track = tracks[0] if tracks else None
    bass_tracks = tracks[1:] if len(tracks) > 1 else []

    # Function to add notes to a part
    def add_notes_to_part(part, track):
        track_notes = track.get('notes', [])
        song_events = create_events(track_notes)
        data = song_events

        for item in data:
            notes_list = item['notes']
            if len(notes_list) > 1:
                pitches = []
                for n in notes_list:
                    midi_pitch = n['pitch']
                    m21_pitch = note.Note()
                    m21_pitch.pitch.midi = midi_pitch
                    pitches.append(m21_pitch.pitch)
                dur = notes_list[0]['duration']
                chord_notes = chord.Chord(pitches)
                chord_notes.duration = duration.Duration(dur / TICKS_PER_QUARTER)
                part.append(chord_notes)
            else:
                n = notes_list[0]
                midi_pitch = n['pitch']
                dur = n['duration']
                m21_note = note.Note()
                m21_note.pitch.midi = midi_pitch
                m21_note.duration = duration.Duration(dur / TICKS_PER_QUARTER)
                part.append(m21_note)

    # Handle single track input or specific part display
    if part_to_display == "treble":
        if treble_track:
            add_notes_to_part(treble_part, treble_track)
            treble_part.show()
        else:
            print("No treble track available to display.")
        return

    elif part_to_display == "bass":
        if bass_tracks:
            for track in bass_tracks:
                add_notes_to_part(bass_part, track)
            bass_part.show()
        elif treble_track:  # If only one track exists, treat it as bass
            add_notes_to_part(bass_part, treble_track)
            bass_part.show()
        else:
            print("No bass track available to display.")
        return

    # Default behavior: display both parts
    if treble_track:
        add_notes_to_part(treble_part, treble_track)

    for track in bass_tracks:
        add_notes_to_part(bass_part, track)

    score.append(treble_part)
    score.append(bass_part)

    # Display the score
    score.show()

def main():

    # import list of paths
    paths = pd.read_csv("PDMX data/subset_paths/all.txt")
    paths = paths[0:10000]

    print(len(paths))

    pattern_events = paths["path"][0]

    # Search for songs containing the pattern
    matching_songs = search_songs(paths, pattern_events)

    # Output the results
    print("Songs containing the pattern:")
    print(len(matching_songs))
    for song_title in matching_songs:
        print(song_title)

# main()