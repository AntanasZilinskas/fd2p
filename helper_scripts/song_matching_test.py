import numpy as np
from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "https://dvplamwokfwyvuaskgyk.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2cGxhbXdva2Z3eXZ1YXNrZ3lrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjI5NjE0NiwiZXhwIjoyMDQ3ODcyMTQ2fQ.Gsu1OOTI2qfkeXCywm1Q5CLD3Igd5jOuUCYUoW_KYZo"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def find_similar_songs(input_titles, top_n=5):
    """
    Find the most similar songs based on feature_vector similarity using Supabase.

    Args:
        input_titles (list): List of song titles to query.
        top_n (int): Number of similar songs to return.

    Returns:
        list: List of dictionaries containing the details of the most similar songs.
    """
    query_payload = {
        "input_titles": input_titles,
        "top_n": top_n
    }
    # Call the Supabase RPC function
    response = supabase.rpc("find_similar_songs_by_titles", query_payload).execute()

    if not response.data:
        raise ValueError("No similar songs found or invalid input titles.")

    return response.data

# Example usage
input_titles = ["Christmas"]
similar_songs = find_similar_songs(input_titles, top_n=5)
for song in similar_songs:
    print(song)