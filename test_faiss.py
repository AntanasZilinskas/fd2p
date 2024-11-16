from sentence_transformers import SentenceTransformer
import faiss
import numpy as np

model = SentenceTransformer('all-MiniLM-L6-v2')
faiss_index = faiss.read_index("data/songs.faiss")

query = "I shall"
query_embedding = model.encode([query])
query_embedding = np.ascontiguousarray(query_embedding.astype('float32'))

D, I = faiss_index.search(query_embedding, 10)
print("Distances:", D)
print("Indices:", I)
