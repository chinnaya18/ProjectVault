/**
 * Utility functions for respectful user naming, faculty salutations (Mr./Ms.), and role representation
 */

const FEMALE_FACULTY_NAMES = new Set([
  'geetha',
  'gayathri',
  'priya',
  'kavitha',
  'anitha',
  'lakshmi',
  'shanthi',
  'deepa',
  'sudha',
  'meena',
  'revathi',
  'uma',
  'saranya',
  'swetha',
  'divya',
  'nandhini',
  'ramya',
  'radha',
  'bhuvaneswari',
  'subhashini'
]);

/**
 * Determines appropriate salutation (Mr. / Ms.) for faculty members
 */
export function getFacultySalutation(name?: string | null): string {
  if (!name) return 'Prof.';
  const trimmed = name.trim();
  const lower = trimmed.toLowerCase();

  // If already prefixed with a title, don't double add
  if (
    lower.startsWith('mr.') ||
    lower.startsWith('ms.') ||
    lower.startsWith('mrs.') ||
    lower.startsWith('dr.') ||
    lower.startsWith('prof.')
  ) {
    return '';
  }

  const firstToken = lower.split(/[\s.]+/)[0];
  if (
    FEMALE_FACULTY_NAMES.has(firstToken) ||
    firstToken.endsWith('a') ||
    firstToken.endsWith('i') ||
    firstToken.endsWith('ee') ||
    firstToken.endsWith('thi')
  ) {
    return 'Ms.';
  }

  return 'Mr.';
}

/**
 * Formats a faculty member's name with Mr./Ms. salutation (e.g., "Ms. Geetha", "Mr. Manavalan")
 */
export function formatFacultyName(name?: string | null): string {
  if (!name) return 'Faculty Guide';
  const trimmed = name.trim();
  if (
    trimmed.startsWith('Mr.') ||
    trimmed.startsWith('Ms.') ||
    trimmed.startsWith('Mrs.') ||
    trimmed.startsWith('Dr.') ||
    trimmed.startsWith('Prof.')
  ) {
    return trimmed;
  }
  const salutation = getFacultySalutation(trimmed);
  return salutation ? `${salutation} ${trimmed}` : trimmed;
}

/**
 * Returns formatted user name respecting role (Faculty gets Mr./Ms., Students get clean name)
 */
export function formatUserNameByRole(name?: string | null, role?: string | null): string {
  if (!name) return '';
  if (role?.toUpperCase() === 'FACULTY') {
    return formatFacultyName(name);
  }
  return name.trim();
}

export function formatStudentName(name?: string | null): string {
  if (!name) return 'Student';
  return name.trim();
}

export function formatUserDisplayName(name?: string | null, email?: string | null, role?: string | null): string {
  if (name && name.trim()) {
    return formatUserNameByRole(name, role);
  }
  if (email) return email.split('@')[0];
  return 'Anonymous';
}

export function getRoleBadgeClass(role?: string | null): string {
  switch (role?.toUpperCase()) {
    case 'ADMIN':
      return 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300 border border-purple-200 dark:border-purple-800';
    case 'FACULTY':
      return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800';
    case 'STUDENT':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300 border border-blue-200 dark:border-blue-800';
    default:
      return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300 border border-slate-200 dark:border-slate-700';
  }
}

export function getRoleLabel(role?: string | null): string {
  switch (role?.toUpperCase()) {
    case 'ADMIN':
      return 'Admin';
    case 'FACULTY':
      return 'Faculty';
    case 'STUDENT':
      return 'Student';
    default:
      return role || 'User';
  }
}
