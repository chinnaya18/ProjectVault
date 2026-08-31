# Re-export settings for flexible import paths (from app.config or from app.core.config)
from app.core.config import settings, Settings

__all__ = ["settings", "Settings"]
