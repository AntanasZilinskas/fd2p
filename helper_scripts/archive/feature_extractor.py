import json
from collections import Counter  # Import Counter to count pitch classes

def extract_features(file_path, output_path):
    with open(file_path, 'r') as file:
        data = json.load(file)
    
    features = []

    # Metadata
    title = data.get('metadata', {}).get('title', 'Unknown Title')
    creators = ", ".join(data.get('metadata', {}).get('creators', ['Unknown Creator']))
    features.append(f"Title: {title}")
    features.append(f"Creators: {creators}")

    # Melodic Features
    features.append("\nMelodic Features:")
    notes = data.get('tracks', [])[0].get('notes', [])
    pitch_classes = [note['pitch'] % 12 for note in notes]
    pitch_class_histogram = dict(Counter(pitch_classes))  # Create histogram as a dictionary
    interval_histogram = [j - i for i, j in zip(pitch_classes[:-1], pitch_classes[1:])]
    melodic_contour = ["up" if i > 0 else "down" if i < 0 else "same" for i in interval_histogram]

    features.append(f"- Pitch Class Histogram: {pitch_class_histogram}")
    features.append(f"- Interval Histogram: {interval_histogram}")
    features.append(f"- Melodic Contour: {melodic_contour}")

    # Harmonic Features
    features.append("\nHarmonic Features:")
    chords = data.get('tracks', [])[0].get('chords', [])
    chord_progressions = [chord['pitches_str'] for chord in chords]
    key_signature = data.get('key_signatures', [{}])[0].get('root_str', 'Unknown')
    mode = data.get('key_signatures', [{}])[0].get('mode', 'Unknown')

    features.append(f"- Chord Progressions: {chord_progressions}")
    features.append(f"- Key Signature: {key_signature}")
    features.append(f"- Mode: {mode}")

    # Rhythmic Features
    features.append("\nRhythmic Features:")
    note_durations = [note['duration'] for note in notes]
    average_duration = sum(note_durations) / len(note_durations) if note_durations else 0
    tempo = data.get('tempos', [{}])[0].get('qpm', 'Unknown')

    features.append(f"- Note Duration Histogram: {note_durations}")
    features.append(f"- Average Note Duration: {average_duration}")
    features.append(f"- Tempo: {tempo}")

    # Structural Features
    features.append("\nStructural Features:")
    time_signatures = data.get('time_signatures', [])
    measures = len(data.get('barlines', []))

    features.append(f"- Number of Measures: {measures}")

    # Create a list of time signature strings
    time_signature_strings = [f"{ts.get('numerator')}/{ts.get('denominator')}" for ts in time_signatures]

    # Append the formatted time signatures
    features.append(f"- Time Signatures: {time_signature_strings}")

    # Save to file
    with open(output_path, 'w') as output_file:
        output_file.write("\n".join(features))

# Replace with actual paths
input_file = "./Qma1a1L2c1vSEuGfdPVSEEWfuYAEoBmjpVESX1ok2imu4b.json"
output_file = "song_features.txt"
extract_features(input_file, output_file)
print(f"Features extracted and saved to {output_file}.")