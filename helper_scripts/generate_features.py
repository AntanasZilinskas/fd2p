import json
import numpy as np
import os
import multiprocessing
from collections import Counter
from supabase import create_client, Client
from transformers import AutoTokenizer, AutoModel
import torch
import os
from dotenv import load_dotenv

load_dotenv()

# Supabase configuration
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Load the gte-small model
tokenizer = AutoTokenizer.from_pretrained("thenlper/gte-small")
model = AutoModel.from_pretrained("thenlper/gte-small")

# Fixed chord vocabulary for roots and types
CHORD_ROOTS = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
CHORD_TYPES = ['', 'm', 'dim', 'aug', '7', 'maj7', 'min7', 'dim7']

# Fixed time signature vocabulary
TIME_SIGNATURES_VOCAB = ['4/4', '3/4', '6/8', '9/8', '2/4', '12/8']

def normalize_histogram(histogram, bins):
    """Normalize a histogram to a fixed number of bins."""
    result = [0] * bins
    total = sum(histogram) if isinstance(histogram, list) else sum(histogram.values())
    if total > 0:
        for key, count in (enumerate(histogram) if isinstance(histogram, list) else histogram.items()):
            if 0 <= key < bins:
                result[key] = count / total
    return result

def encode_song_features(features, vector_size=128):
    vector = []

    # Melodic Features
    pitch_histogram = normalize_histogram(features['pitch_class_histogram'], bins=12)
    interval_histogram = normalize_histogram(Counter(features['interval_histogram']), bins=12)
    contour_counts = Counter(features['melodic_contour'])
    total_contours = len(features['melodic_contour']) if features['melodic_contour'] else 1
    melodic_contour = [
        contour_counts.get('up', 0) / total_contours,
        contour_counts.get('down', 0) / total_contours,
        contour_counts.get('same', 0) / total_contours,
    ]
    vector.extend(pitch_histogram + interval_histogram + melodic_contour)

    # Harmonic Features
    # Root-based chord histogram
    root_chord_counts = {root: 0 for root in CHORD_ROOTS}
    chord_type_counts = {chord_type: 0 for chord_type in CHORD_TYPES}
    
    chord_counts = Counter(features['chord_progressions'])
    for chord, count in chord_counts.items():
        root = next((root for root in CHORD_ROOTS if chord.startswith(root)), None)
        if root:
            root_chord_counts[root] += count
        for chord_type in CHORD_TYPES:
            if chord.endswith(chord_type):
                chord_type_counts[chord_type] += count

    # Normalize and append to vector
    root_histogram = normalize_histogram(list(root_chord_counts.values()), bins=len(CHORD_ROOTS))
    type_histogram = normalize_histogram(list(chord_type_counts.values()), bins=len(CHORD_TYPES))
    vector.extend(root_histogram + type_histogram)

    # Key and Mode
    key_signature = [1 if features['key_signature'] == key else 0 for key in CHORD_ROOTS]
    mode = [1 if features['mode'] == 'major' else 0]
    vector.extend(key_signature + mode)

    # Rhythmic Features
    vector.extend(features['note_duration_histogram'])
    average_duration = features['average_duration'] / 1000  # Example scaling
    tempo = features['tempo'] / 300 if isinstance(features['tempo'], (int, float)) else 0
    vector.extend([average_duration, tempo])

    # Structural Features
    max_measures = 100
    measures = min(features['number_of_measures'], max_measures) / max_measures
    time_signatures = [1 if ts in features['time_signatures'] else 0 for ts in TIME_SIGNATURES_VOCAB]
    vector.extend([measures] + time_signatures)

    if len(vector) < vector_size:
        vector.extend([0] * (vector_size - len(vector)))
    else:
        vector = vector[:vector_size]
    return np.array(vector)

def generate_title_embedding(title):
    """Generate embedding for the song title using gte-small model."""
    inputs = tokenizer(title, return_tensors="pt", truncation=True, max_length=128)
    with torch.no_grad():
        outputs = model(**inputs)
    # Mean pooling
    embeddings = outputs.last_hidden_state.mean(dim=1).squeeze().numpy()
    return embeddings

def write_to_supabase(features, vector, title_embedding):
    """Write features and vector to Supabase."""
    data = {
        "title": features['title'],
        "creators": features.get("creators", []),
        "pitch_class_histogram": normalize_histogram(features.get("pitch_class_histogram", {}), bins=12),
        "interval_histogram": normalize_histogram(Counter(features.get("interval_histogram", [])), bins=12),
        "melodic_contour": [
            features['melodic_contour'].count("up") / len(features['melodic_contour']) if features['melodic_contour'] else 0,
            features['melodic_contour'].count("down") / len(features['melodic_contour']) if features['melodic_contour'] else 0,
            features['melodic_contour'].count("same") / len(features['melodic_contour']) if features['melodic_contour'] else 0,
        ],
        "chord_progressions": features.get("chord_progressions", []),
        "key_signature": features.get("key_signature", ""),
        "mode": features.get("mode", ""),
        "note_duration_histogram": features['note_duration_histogram'],
        "average_duration": features.get("average_duration", 0),
        "tempo": features.get("tempo", 0),
        "measures": features.get("number_of_measures", 0),
        "time_signatures": features.get("time_signatures", []),
        "feature_vector": vector.tolist(),
        "title_embedding": json.dumps(title_embedding.tolist()),
    }

    # Perform the insertion
    response = supabase.table("music_features").insert(data).execute()

    # Check the response
    if response.data:
        print(f"Data for '{features['title']}' successfully inserted into Supabase.")
    else:
        print(f"Error inserting data for '{features['title']}': {response.error}")

def extract_features_and_save(file_path):
    try:
        with open(file_path, "r") as file:
            data = json.load(file)
        
        features = {}
        features['title'] = data.get('metadata', {}).get('title')
        features['creators'] = data.get('metadata', {}).get('creators')

        # **Check if the title is usable**
        if not features['title'] or not features['title'].strip():
            print(f"Title is missing or invalid in file {file_path}. Skipping.")
            return

        # Check for necessary entries
        tracks = data.get('tracks')
        if not tracks:
            print(f"No 'tracks' found in file {file_path}. Skipping.")
            return

        first_track = tracks[0]
        notes = first_track.get('notes')
        if not notes:
            print(f"No 'notes' found in first track of file {file_path}. Skipping.")
            return

        if not all('pitch' in note for note in notes):
            print(f"Some notes missing 'pitch' in file {file_path}. Skipping.")
            return

        # Proceed with processing since necessary data is present
        pitch_classes = [note['pitch'] % 12 for note in notes]

        if len(pitch_classes) < 2:
            print(f"Not enough pitch data to calculate intervals in file {file_path}. Skipping.")
            return

        raw_intervals = [(j - i) % 12 for i, j in zip(pitch_classes[:-1], pitch_classes[1:])]

        # Continue extracting features
        interval_histogram = raw_intervals
        melodic_contour = [
            "up" if interval > 0 else "down" if interval < 0 else "same"
            for interval in raw_intervals
        ]
        features['pitch_class_histogram'] = dict(Counter(pitch_classes))
        features['interval_histogram'] = interval_histogram
        features['melodic_contour'] = melodic_contour

        # Check for chords
        chords = first_track.get('chords', [])
        features['chord_progressions'] = ['-'.join(chord.get('pitches_str', [])) for chord in chords]

        # Check for key signatures
        key_signatures = data.get('key_signatures')
        if not key_signatures:
            print(f"No 'key_signatures' found in file {file_path}. Skipping.")
            return

        key_signature_data = key_signatures[0]
        features['key_signature'] = key_signature_data.get('root_str')
        features['mode'] = key_signature_data.get('mode')

        if not features['key_signature'] or not features['mode']:
            print(f"Key signature or mode missing in file {file_path}. Skipping.")
            return

        # Check for note durations
        note_durations = [note['duration'] for note in notes if 'duration' in note]
        if not note_durations:
            print(f"No note durations found in file {file_path}. Skipping.")
            return

        # Proceed with the rest of the processing
        bin_edges = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
        binned_durations = np.digitize(note_durations, bins=bin_edges, right=True)
        duration_histogram = Counter(binned_durations)
        features['note_duration_histogram'] = [
            duration_histogram.get(i, 0) / len(note_durations) for i in range(1, len(bin_edges) + 1)
        ]
        features['average_duration'] = sum(note_durations) / len(note_durations)

        # Check for tempos
        tempos = data.get('tempos')
        if not tempos:
            print(f"No 'tempos' found in file {file_path}. Skipping.")
            return

        tempo_data = tempos[0]
        features['tempo'] = tempo_data.get('qpm', 0)

        # Check for time signatures and barlines
        time_signatures = data.get('time_signatures')
        barlines = data.get('barlines')
        if not time_signatures or not barlines:
            print(f"Time signatures or barlines missing in file {file_path}. Skipping.")
            return

        features['number_of_measures'] = len(barlines)
        features['time_signatures'] = [
            f"{ts.get('numerator', 'Unknown')}/{ts.get('denominator', 'Unknown')}" for ts in time_signatures
        ]

        # Generate the title embedding
        title_embedding = generate_title_embedding(features['title'])

        # Encode song features
        vector = encode_song_features(features)

        # Write to Supabase
        write_to_supabase(features, vector, title_embedding)
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")

def process_files_in_directory(directory):
    # Collect all JSON files
    json_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".json"):
                json_files.append(os.path.join(root, file))

    # Process files using multiprocessing for speed
    pool = multiprocessing.Pool(processes=multiprocessing.cpu_count())
    pool.map(extract_features_and_save, json_files)
    pool.close()
    pool.join()

if __name__ == "__main__":
    data_directory = "/Users/antanaszilinskas/Desktop/Imperial College London/D2P/Coursework/PDMX/data/" # Path to the data directory
    process_files_in_directory(data_directory)