from flask import Flask, request, jsonify
import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer
from annoy import AnnoyIndex

app = Flask(__name__)

# Load data and model once when the app starts
print("Loading data and model...")
songs_df = pd.read_csv('data/songs_with_ids.csv')
song_titles = songs_df['title'].tolist()
embeddings = np.load('data/song_embeddings.npy').astype('float32')

# Build the Annoy index
embedding_dim = embeddings.shape[1]
index = AnnoyIndex(embedding_dim, 'angular')  # 'angular' is suitable for cosine similarity
for i, vector in enumerate(embeddings):
    index.add_item(i, vector)
index.build(10)  # Number of trees can be adjusted
print("Annoy index built successfully.")

# Load the SentenceTransformer model
model = SentenceTransformer('all-MiniLM-L6-v2')
print("Model loaded successfully.")

@app.route('/search', methods=['GET'])
def search():
    query = request.args.get('query', '')
    max_results = int(request.args.get('max_results', 10))
    if len(query) < 2:
        return jsonify([])

    # Compute query embedding
    query_embedding = model.encode([query], show_progress_bar=False)[0].astype('float32')

    # Perform similarity search
    indices = index.get_nns_by_vector(query_embedding, max_results)
    results = [song_titles[i] for i in indices]

    return jsonify(results)

if __name__ == '__main__':
    app.run(port=5000, debug=True) 