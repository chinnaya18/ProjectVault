import axios from 'axios';
import { SemanticSearchResponse, AskQuestionResponse } from '../types';

// AI Microservice base client
// Proxied via Vite config at /api/ai or direct fallback to port 8000
const aiApi = axios.create({
  baseURL: '/api/ai',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

export interface SearchParams {
  query: string;
  limit?: number;
  threshold?: number;
  departmentId?: number;
  academicYear?: string;
  projectType?: string;
}

export interface AskParams {
  question: string;
  limit?: number;
  departmentId?: number;
  academicYear?: string;
  projectType?: string;
}

/**
 * Executes a semantic vector search against the ProjectVault AI Microservice.
 */
export const searchProjectsSemantically = async (params: SearchParams): Promise<SemanticSearchResponse> => {
  const payload: any = {
    query: params.query.trim(),
    limit: params.limit || 8,
  };
  if (params.threshold !== undefined) payload.threshold = params.threshold;
  if (params.departmentId) payload.department_id = params.departmentId;
  if (params.academicYear) payload.academic_year = params.academicYear;
  if (params.projectType) payload.project_type = params.projectType;

  try {
    const res = await aiApi.post<SemanticSearchResponse>('/search', payload);
    return res.data;
  } catch (err: any) {
    // If proxied route fails, attempt direct call to localhost:8000 as resilient fallback
    if (err.code === 'ERR_NETWORK' || err.response?.status === 404) {
      const directRes = await axios.post<SemanticSearchResponse>('http://localhost:8000/api/ai/search', payload);
      return directRes.data;
    }
    throw err;
  }
};

/**
 * Fetches AI Topic Viability Analysis & Guidance for a project topic idea.
 */
export const fetchTopicFeedback = async (query: string): Promise<any> => {
  try {
    const res = await aiApi.get(`/topic-feedback?query=${encodeURIComponent(query)}`);
    return res.data;
  } catch (err: any) {
    const directRes = await axios.get(`http://localhost:8000/api/ai/topic-feedback?query=${encodeURIComponent(query)}`);
    return directRes.data;
  }
};

/**
 * Asks the AI Assistant a question grounded in ProjectVault project records (RAG).
 */
export const askAiAssistant = async (params: AskParams): Promise<AskQuestionResponse> => {
  const payload: any = {
    question: params.question.trim(),
    limit: params.limit || 5,
  };
  if (params.departmentId) payload.department_id = params.departmentId;
  if (params.academicYear) payload.academic_year = params.academicYear;
  if (params.projectType) payload.project_type = params.projectType;

  try {
    const res = await aiApi.post<AskQuestionResponse>('/ask', payload);
    return res.data;
  } catch (err: any) {
    if (err.code === 'ERR_NETWORK' || err.response?.status === 404) {
      const directRes = await axios.post<AskQuestionResponse>('http://localhost:8000/api/ai/ask', payload);
      return directRes.data;
    }
    throw err;
  }
};

/**
 * Checks AI microservice health status.
 */
export const checkAiHealth = async (): Promise<boolean> => {
  try {
    const res = await axios.get('http://localhost:8000/health', { timeout: 3000 });
    return res.status === 200;
  } catch {
    return false;
  }
};

export default {
  searchProjectsSemantically,
  askAiAssistant,
  checkAiHealth,
};
