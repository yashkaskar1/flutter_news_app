from fastapi import FastAPI, Query
import requests
import pandas as pd
from fastapi.middleware.cors import CORSMiddleware
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

NEWS_API_KEY = "68ef3fe2eb624cd8a93453290932582d"

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

articles_df = pd.DataFrame()

@app.get("/articles")
def get_trending_news(category: str = Query("general", title="News Category")):
    url = f"https://newsapi.org/v2/top-headlines?country=us&category={category}&pageSize=50&apiKey={NEWS_API_KEY}"
    response = requests.get(url)

    if response.status_code == 200:
        news_data = response.json()
        global articles_df
        articles_df = pd.DataFrame(news_data["articles"])
        articles_df["id"] = articles_df.index

        return {"articles": articles_df.to_dict(orient="records")}
    else:
        return {"error": "Failed to fetch news"}


@app.get("/recommend/{article_id}")
def recommend_articles(article_id: int, top_n: int = 5):
    global articles_df

    if articles_df.empty:
        return {"error": "No news articles found. Fetch news first!"}

    if article_id >= len(articles_df) or article_id < 0:
        return {"error": "Invalid article ID"}

    required_columns = ["title", "description", "content"]
    for col in required_columns:
        if col not in articles_df.columns:
            return {"error": f"Missing column: {col}"}

    articles_df.fillna({"title": "", "description": "", "content": ""}, inplace=True)

    articles_df["text"] = articles_df["title"] * 2 + " " + articles_df["description"] + " " + articles_df["content"]

    try:
        # Compute TF-IDF similarity
        tfidf_vectorizer = TfidfVectorizer(stop_words="english")
        tfidf_matrix = tfidf_vectorizer.fit_transform(articles_df["text"])
        cosine_sim = cosine_similarity(tfidf_matrix, tfidf_matrix)

        # Get similar articles
        similar_scores = list(enumerate(cosine_sim[article_id]))
        similar_scores = sorted(similar_scores, key=lambda x: x[1], reverse=True)

        # Get Top N Recommended Articles
        top_articles = [articles_df.iloc[i[0]].to_dict() for i in similar_scores[1:top_n+1]]

        return top_articles
    except Exception as e:
        return {"error": f"Failed to compute recommendations: {str(e)}"}

import uvicorn

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
