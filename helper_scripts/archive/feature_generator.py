import json
import numpy as np
from collections import Counter

def normalize_histogram(histogram, bins):
    """Normalize a histogram to a fixed number of bins."""
    result = [0] * bins
    total = sum(histogram.values())
    if total > 0:
        for key, count in histogram.items():
            if 0 <= key < bins:
                result[key] = count / total
    return result

def encode_song_features(features):
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

    return np.array(vector)

def extract_features(file_path, output_txt_path, output_vector_path):
    with open(file_path, 'r') as file:
        data = json.load(file)
    
    features = {}

    # Metadata
    title = data.get('metadata', {}).get('title', 'Unknown Title')
    creators = ", ".join(data.get('metadata', {}).get('creators', ['Unknown Creator']))
    features_text = [f"Title: {title}", f"Creators: {creators}"]

    # Melodic Features
    notes = data.get('tracks', [])[0].get('notes', [])
    pitch_classes = [note['pitch'] % 12 for note in notes]
    features['pitch_class_histogram'] = dict(Counter(pitch_classes))
    features['interval_histogram'] = [j - i for i, j in zip(pitch_classes[:-1], pitch_classes[1:])]
    features['melodic_contour'] = ["up" if i > 0 else "down" if i < 0 else "same" for i in features['interval_histogram']]
    features_text.append("\nMelodic Features:")
    features_text.append(f"- Pitch Class Histogram: {features['pitch_class_histogram']}")
    features_text.append(f"- Interval Histogram: {features['interval_histogram']}")
    features_text.append(f"- Melodic Contour: {features['melodic_contour']}")

    # Harmonic Features
    chords = data.get('tracks', [])[0].get('chords', [])
    features['chord_progressions'] = ['-'.join(chord['pitches_str']) for chord in chords]
    features['key_signature'] = data.get('key_signatures', [{}])[0].get('root_str', 'Unknown')
    features['mode'] = data.get('key_signatures', [{}])[0].get('mode', 'Unknown')
    features_text.append("\nHarmonic Features:")
    features_text.append(f"- Chord Progressions: {features['chord_progressions']}")
    features_text.append(f"- Key Signature: {features['key_signature']}")
    features_text.append(f"- Mode: {features['mode']}")

    # Rhythmic Features
    note_durations = [note['duration'] for note in notes]
    features['note_duration_histogram'] = dict(Counter(note_durations))
    features['average_duration'] = sum(note_durations) / len(note_durations) if note_durations else 0
    features['tempo'] = data.get('tempos', [{}])[0].get('qpm', 'Unknown')
    features_text.append("\nRhythmic Features:")
    features_text.append(f"- Note Duration Histogram: {features['note_duration_histogram']}")
    features_text.append(f"- Average Note Duration: {features['average_duration']}")
    features_text.append(f"- Tempo: {features['tempo']}")

    # Structural Features
    time_signatures = data.get('time_signatures', [])
    features['number_of_measures'] = len(data.get('barlines', []))
    features['time_signatures'] = [f"{ts.get('numerator')}/{ts.get('denominator')}" for ts in time_signatures]
    features_text.append("\nStructural Features:")
    features_text.append(f"- Number of Measures: {features['number_of_measures']}")
    features_text.append(f"- Time Signatures: {features['time_signatures']}")

    # Save text output
    with open(output_txt_path, 'w') as output_file:
        output_file.write("\n".join(features_text))
    
    # Generate vector and save
    vector = encode_song_features(features)
    np.savetxt(output_vector_path, vector, delimiter=',')
    print(f"Features extracted and saved to {output_txt_path}.")
    print(f"Vector saved to {output_vector_path}.")

# Replace with actual paths
input_file = "./Qma1a1L2c1vSEuGfdPVSEEWfuYAEoBmjpVESX1ok2imu4b.json"
output_txt_file = "song_features.txt"
output_vector_file = "song_features_vector.csv"

extract_features(input_file, output_txt_file, output_vector_file)