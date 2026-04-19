"""
Singleton model loader for sentence-transformers.
Lazy-loads on first use, then cached in memory.
Uses paraphrase-multilingual-MiniLM-L12-v2 (FREE, supports Vietnamese).
"""
import logging
import os

logger = logging.getLogger(__name__)

_model = None
_model_name = os.getenv(
    "EMBEDDING_MODEL", "paraphrase-multilingual-MiniLM-L12-v2"
)


def get_embedding_model():
    """Return cached SentenceTransformer model (lazy-loaded)."""
    global _model
    if _model is None:
        try:
            from sentence_transformers import SentenceTransformer

            logger.info("Loading embedding model: %s …", _model_name)
            _model = SentenceTransformer(_model_name)
            logger.info("Embedding model loaded successfully.")
        except Exception as exc:
            logger.warning("Failed to load embedding model: %s", exc)
            _model = None
    return _model


def is_model_loaded() -> bool:
    return _model is not None
