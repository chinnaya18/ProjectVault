import os
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "ProjectVault AI Microservice"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1/ai"
    
    # Database Configuration
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_NAME: str = "projectvault"
    DB_USER: str = "postgres"
    DB_PASSWORD: str = "0608"
    DATABASE_URL: Optional[str] = None
    
    # AI Providers Configuration
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-1.5-flash"
    
    # Embedding Model Configuration
    EMBEDDING_MODEL_NAME: str = "sentence-transformers/all-MiniLM-L6-v2"
    EMBEDDING_DIMENSION: int = 384
    
    # Search & Retrieval Parameters
    SIMILARITY_THRESHOLD: float = 0.20
    DEFAULT_SEARCH_LIMIT: int = 5
    MAX_SEARCH_LIMIT: int = 20
    
    # Server Configuration
    AI_SERVICE_HOST: str = "0.0.0.0"
    AI_SERVICE_PORT: int = 8000
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="allow"
    )
    
    def get_database_url(self) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL
        return f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

settings = Settings()

