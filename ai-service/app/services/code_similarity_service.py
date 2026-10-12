import re
import ast
import logging
from typing import Optional, List, Dict, Set, Any
from urllib.parse import urlparse

logger = logging.getLogger("ai_service.code_similarity")

class CodeSimilarityService:

    def normalize_repo_url(self, url: Optional[str]) -> Optional[str]:
        """
        Normalize git repository URLs to standard canonical form (owner/repo).
        Handles:
          - https://github.com/owner/repo.git
          - git@github.com:owner/repo.git
          - https://gitlab.com/owner/repo/tree/main
          - git@github.com:owner/repo/tree/main
          - http://github.com/owner/repo/
        """
        if not url or not url.strip():
            return None

        clean = url.strip().lower()
        # Strip git@ and host prefix (e.g. git@github.com: -> "")
        clean = re.sub(r"^git@[\w\.\-]+:", "", clean)
        # Strip https://, http://, git:// and domain
        clean = re.sub(r"^(?:https?|git)://[\w\.\-]+/", "", clean)

        # Remove leading/trailing slashes
        clean = clean.strip("/")
        
        # Split path segments and filter out branch/tree markers
        parts = [p for p in clean.split("/") if p and p not in ("tree", "blob", "src", "raw", "main", "master")]
        if len(parts) >= 2:
            owner = parts[0]
            repo = parts[1].removesuffix(".git")
            return f"{owner}/{repo}"
        elif len(parts) == 1:
            return parts[0].removesuffix(".git")
        return clean

    def check_repo_exact_match(self, repo1: Optional[str], repo2: Optional[str]) -> bool:
        """Check if two repository URLs point to the same codebase or fork."""
        norm1 = self.normalize_repo_url(repo1)
        norm2 = self.normalize_repo_url(repo2)
        if not norm1 or not norm2:
            return False
        return norm1 == norm2

    def extract_python_ast_features(self, code_text: str) -> Set[str]:
        """
        Extract normalized Abstract Syntax Tree (AST) structure from Python code.
        Strips variable names, comments, and docstrings to detect structural clones.
        """
        features: Set[str] = set()
        try:
            tree = ast.parse(code_text)
            for node in ast.walk(tree):
                node_type = type(node).__name__
                if isinstance(node, ast.FunctionDef):
                    arg_count = len(node.args.args)
                    features.add(f"FuncDef(args={arg_count})")
                elif isinstance(node, ast.ClassDef):
                    features.add("ClassDef")
                elif isinstance(node, ast.Call):
                    if isinstance(node.func, ast.Name):
                        features.add(f"Call({node.func.id})")
                    elif isinstance(node.func, ast.Attribute):
                        features.add(f"CallAttr({node.func.attr})")
                elif isinstance(node, (ast.For, ast.While, ast.If, ast.Try, ast.With)):
                    features.add(f"ControlFlow({node_type})")
                elif isinstance(node, ast.Import):
                    for name in node.names:
                        features.add(f"Import({name.name})")
                elif isinstance(node, ast.ImportFrom):
                    module = node.module or ""
                    for name in node.names:
                        features.add(f"ImportFrom({module}.{name.name})")
        except Exception as e:
            # Fallback to regex tokenization if syntax errors exist
            features = self._fallback_structural_tokens(code_text)
        return features

    def _fallback_structural_tokens(self, code_text: str) -> Set[str]:
        """Extract language-agnostic structural tokens (imports, control keywords, function patterns)."""
        tokens: Set[str] = set()
        # Remove single-line and multi-line comments
        no_comments = re.sub(r"(#.*$|//.*$|/\*[\s\S]*?\*/|\"\"\"[\s\S]*?\"\"\")", "", code_text, flags=re.MULTILINE)
        
        # Extract imports / includes
        for m in re.finditer(r"(?:import|from|include|require)\s+([a-zA-Z0-9_\.\-]+)", no_comments):
            tokens.add(f"imp:{m.group(1)}")
            
        # Extract function headers (e.g. def foo, function bar, void baz)
        for m in re.finditer(r"(?:def|function|void|int|class|async\s+def)\s+([a-zA-Z0-9_]+)", no_comments):
            tokens.add(f"decl:{m.group(1)}")
            
        # Extract control flow structure
        for m in re.finditer(r"\b(if|else|for|while|try|catch|except|switch|case|return|yield|await)\b", no_comments):
            tokens.add(f"ctrl:{m.group(1)}")
            
        return tokens

    def compute_jaccard_similarity(self, set1: Set[str], set2: Set[str]) -> float:
        """Compute Jaccard similarity coefficient between two feature sets."""
        if not set1 or not set2:
            return 0.0
        intersection = len(set1.intersection(set2))
        union = len(set1.union(set2))
        if union == 0:
            return 0.0
        return float(intersection / union)

    def compare_code_snippets(self, code1: str, code2: str, language: str = "python") -> float:
        """Compare two source code files/snippets using structural AST and token Jaccard similarity."""
        if not code1 or not code2 or not code1.strip() or not code2.strip():
            return 0.0

        # Exact match check
        if code1.strip() == code2.strip():
            return 1.0

        if language.lower() == "python":
            feat1 = self.extract_python_ast_features(code1)
            feat2 = self.extract_python_ast_features(code2)
        else:
            feat1 = self._fallback_structural_tokens(code1)
            feat2 = self._fallback_structural_tokens(code2)

        return round(self.compute_jaccard_similarity(feat1, feat2), 4)

    def compare_tech_manifests(self, list1: List[str], list2: List[str]) -> float:
        """Compare dependencies or tech stack lists (e.g., package.json / requirements.txt)."""
        if not list1 or not list2:
            return 0.0
        s1 = {t.strip().lower() for t in list1 if t.strip()}
        s2 = {t.strip().lower() for t in list2 if t.strip()}
        return round(self.compute_jaccard_similarity(s1, s2), 4)

    async def fetch_github_repo_content(self, repo_url: str, token: Optional[str] = None) -> Dict[str, Any]:
        """
        Fetch source code from a GitHub repository (public or private with Personal Access Token).
        Extracts representative source files (.py, .java, .js, .ts, .cpp, .cs) for AST analysis.
        """
        canonical = self.normalize_repo_url(repo_url)
        if not canonical or "/" not in canonical:
            return {"success": False, "error": f"Invalid GitHub repository URL: {repo_url}"}

        owner, repo = canonical.split("/", 1)
        api_url = f"https://api.github.com/repos/{owner}/{repo}/zipball"

        headers = {
            "Accept": "application/vnd.github+json",
            "User-Agent": "ProjectVault-MCA-Auditor/2.0"
        }
        if token and token.strip():
            headers["Authorization"] = f"Bearer {token.strip()}"

        try:
            import httpx
            import zipfile
            import io

            async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
                res = await client.get(api_url, headers=headers)

                if res.status_code == 200:
                    code_snippets: List[str] = []
                    valid_exts = {".py", ".java", ".js", ".ts", ".tsx", ".jsx", ".cpp", ".c", ".cs", ".go", ".php"}
                    total_bytes = 0
                    file_count = 0

                    with zipfile.ZipFile(io.BytesIO(res.content)) as z:
                        for name in z.namelist():
                            if any(name.lower().endswith(ext) for ext in valid_exts):
                                if any(ignore in name.lower() for ignore in ["node_modules", "target", "build", "dist", ".git", "venv"]):
                                    continue
                                try:
                                    content = z.read(name).decode("utf-8", errors="ignore")
                                    if content.strip():
                                        code_snippets.append(content[:10000]) # cap per file
                                        total_bytes += len(content)
                                        file_count += 1
                                        if file_count >= 50 or total_bytes > 500000:
                                            break
                                except Exception:
                                    continue

                    combined = "\n\n".join(code_snippets)
                    logger.info(f"Successfully fetched {file_count} source files from GitHub repo {owner}/{repo}")
                    return {
                        "success": True,
                        "owner_repo": f"{owner}/{repo}",
                        "source_code": combined,
                        "files_analyzed": file_count,
                        "is_private": bool(token)
                    }

                elif res.status_code in (401, 403, 404):
                    logger.warning(f"GitHub repo {owner}/{repo} returned status {res.status_code}. Private or unauthorized.")
                    return {
                        "success": False,
                        "is_private": True,
                        "status_code": res.status_code,
                        "error": (
                            f"Repository '{owner}/{repo}' is private or inaccessible (Status {res.status_code}). "
                            "To analyze code from a private repository, provide a GitHub Personal Access Token (PAT) "
                            "with 'repo:read' permission, or upload the project ZIP archive directly."
                        )
                    }
                else:
                    return {
                        "success": False,
                        "error": f"GitHub API responded with HTTP status {res.status_code}"
                    }

        except Exception as ex:
            logger.error(f"Error fetching GitHub repository {owner}/{repo}: {ex}")
            return {
                "success": False,
                "error": f"Failed to download repository: {str(ex)}"
            }

code_similarity_service = CodeSimilarityService()

