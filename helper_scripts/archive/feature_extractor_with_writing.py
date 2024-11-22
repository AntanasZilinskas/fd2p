import json
import numpy as np
from collections import Counter
from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "https://dvplamwokfwyvuaskgyk.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2cGxhbXdva2Z3eXZ1YXNrZ3lrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjI5NjE0NiwiZXhwIjoyMDQ3ODcyMTQ2fQ.Gsu1OOTI2qfkeXCywm1Q5CLD3Igd5jOuUCYUoW_KYZo"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def normalize_histogram(histogram, bins):
    """Normalize a histogram to a fixed number of bins."""
    result = [0] * bins
    total = sum(histogram.values())
    if total > 0:
        for key, count in histogram.items():
            if 0 <= key < bins:
                result[key] = count / total
    return result

def encode_song_features(features, vector_size=128):
    vector = []

    # Melodic Features
    pitch_histogram = normalize_histogram(features['pitch_class_histogram'], bins=12)
    interval_histogram = normalize_histogram(Counter(features['interval_histogram']), bins=21)  # -10 to +10
    contour_counts = Counter(features['melodic_contour'])
    melodic_contour = [
        contour_counts.get('up', 0) / len(features['melodic_contour']) if features['melodic_contour'] else 0,
        contour_counts.get('down', 0) / len(features['melodic_contour']) if features['melodic_contour'] else 0,
        contour_counts.get('same', 0) / len(features['melodic_contour']) if features['melodic_contour'] else 0,
    ]
    vector.extend(pitch_histogram + interval_histogram + melodic_contour)

    # Harmonic Features
    chord_vocab = {}  # Map chords to indices
    chord_counts = Counter(features['chord_progressions'])
    for chord in chord_counts:
        if chord not in chord_vocab:
            chord_vocab[chord] = len(chord_vocab)
    chord_histogram_bins = len(chord_vocab)
    chord_histogram_values = {chord_vocab[chord]: count for chord, count in chord_counts.items()}
    chord_histogram = normalize_histogram(chord_histogram_values, bins=chord_histogram_bins)
    key_signature = [1 if features['key_signature'] == key else 0 for key in ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']]
    mode = [1 if features['mode'] == 'major' else 0]
    vector.extend(chord_histogram + key_signature + mode)

    # Rhythmic Features
    note_duration_hist = normalize_histogram(features['note_duration_histogram'], bins=10)
    average_duration = features['average_duration'] / 1000  # Example scaling
    tempo = features['tempo'] / 300 if isinstance(features['tempo'], (int, float)) else 0  # Assuming max tempo is 300 bpm
    vector.extend(note_duration_hist + [average_duration, tempo])

    # Structural Features
    max_measures = 100  # Normalize by max measures
    measures = min(features['number_of_measures'], max_measures) / max_measures
    time_signatures = [1 if ts in features['time_signatures'] else 0 for ts in ['4/4', '3/4', '6/8', '9/8']]
    vector.extend([measures] + time_signatures)

    # Ensure vector is exactly vector_size dimensions
    if len(vector) < vector_size:
        vector.extend([0] * (vector_size - len(vector)))  # Pad with zeros
    else:
        vector = vector[:vector_size]  # Truncate if necessary

    return np.array(vector)

def write_to_supabase(features, vector):
    """Write features and vector to Supabase."""
    data = {
        "title": features.get("title", "Unknown Title"),
        "creators": features.get("creators", []),
        "pitch_class_histogram": list(features.get("pitch_class_histogram", {}).values()),  # Convert histogram to array
        "interval_histogram": features.get("interval_histogram", []),
        "melodic_contour": [
            features['melodic_contour'].count("up") / len(features['melodic_contour']) if features['melodic_contour'] else 0,
            features['melodic_contour'].count("down") / len(features['melodic_contour']) if features['melodic_contour'] else 0,
            features['melodic_contour'].count("same") / len(features['melodic_contour']) if features['melodic_contour'] else 0,
        ],
        "chord_progressions": features.get("chord_progressions", []),
        "key_signature": features.get("key_signature", ""),
        "mode": features.get("mode", ""),
        "note_duration_histogram": list(features.get("note_duration_histogram", {}).values()),
        "average_duration": features.get("average_duration", 0),
        "tempo": features.get("tempo", 0),
        "measures": features.get("number_of_measures", 0),  # Match `measures` in the schema
        "time_signatures": features.get("time_signatures", []),
        "feature_vector": vector.tolist(),  # Convert the numpy array to a JSON-compatible list
    }
    # Insert data into Supabase
    response = supabase.table("music_features").insert(data).execute()

    # Check for success
    if response.data:
        print("Data successfully inserted into Supabase.")
    elif response.error:
        print(f"Error inserting data: {response.error}")

def extract_features_and_save(file_path):
    with open(file_path, "r") as file:
        data = json.load(file)
    
    features = {}

    # Metadata
    features['title'] = data.get('metadata', {}).get('title', 'Unknown Title')
    features['creators'] = data.get('metadata', {}).get('creators', ['Unknown Creator'])

    # Melodic Features
    notes = data.get('tracks', [])[0].get('notes', [])
    pitch_classes = [note['pitch'] % 12 for note in notes]
    features['pitch_class_histogram'] = dict(Counter(pitch_classes))
    features['interval_histogram'] = [j - i for i, j in zip(pitch_classes[:-1], pitch_classes[1:])]
    features['melodic_contour'] = ["up" if i > 0 else "down" if i < 0 else "same" for i in features['interval_histogram']]

    # Harmonic Features
    chords = data.get('tracks', [])[0].get('chords', [])
    features['chord_progressions'] = ['-'.join(chord['pitches_str']) for chord in chords]
    features['key_signature'] = data.get('key_signatures', [{}])[0].get('root_str', 'Unknown')
    features['mode'] = data.get('key_signatures', [{}])[0].get('mode', 'Unknown')

    # Rhythmic Features
    note_durations = [note['duration'] for note in notes]
    features['note_duration_histogram'] = dict(Counter(note_durations))
    features['average_duration'] = sum(note_durations) / len(note_durations) if note_durations else 0
    features['tempo'] = data.get('tempos', [{}])[0].get('qpm', 0)

    # Structural Features
    time_signatures = data.get('time_signatures', [])
    features['number_of_measures'] = len(data.get('barlines', []))
    features['time_signatures'] = [f"{ts.get('numerator')}/{ts.get('denominator')}" for ts in time_signatures]

    # Encode vector
    vector = encode_song_features(features)

    # Write to Supabase
    write_to_supabase(features, vector)
    print(features, vector)

# Example usage
file_path = "./Qma1a1L2c1vSEuGfdPVSEEWfuYAEoBmjpVESX1ok2imu4b.json"
extract_features_and_save(file_path)