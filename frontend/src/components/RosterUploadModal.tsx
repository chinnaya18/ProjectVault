import React, { useState, useRef } from 'react';
import * as XLSX from 'xlsx';
import { Department, StudentRosterBulkPayload, StudentRosterItemPayload } from '../types';
import api, { getErrorMessage } from '../api/client';
import { 
  X, 
  Upload, 
  FileSpreadsheet, 
  CheckCircle2, 
  AlertCircle, 
  Download, 
  Layers, 
  Building2, 
  Check 
} from 'lucide-react';

interface RosterUploadModalProps {
  isOpen: boolean;
  onClose: () => void;
  departments: Department[];
  onSuccess: (count: number) => void;
}

export const RosterUploadModal: React.FC<RosterUploadModalProps> = ({
  isOpen,
  onClose,
  departments,
  onSuccess,
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [selectedDeptId, setSelectedDeptId] = useState<number>(() => {
    const mca = departments.find(d => d.code === 'MCA');
    return mca ? mca.id : (departments[0]?.id || 1);
  });
  const [batch, setBatch] = useState<string>('2025-2027');
  
  const [fileName, setFileName] = useState<string | null>(null);
  const [parsedStudents, setParsedStudents] = useState<StudentRosterItemPayload[]>([]);
  const [parseErrors, setParseErrors] = useState<string[]>([]);
  const [isParsing, setIsParsing] = useState(false);
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState<string | null>(null);

  if (!isOpen) return null;

  // Handle Drag & Drop / File Change
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      processFile(file);
    }
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    const file = e.dataTransfer.files?.[0];
    if (file) {
      processFile(file);
    }
  };

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
  };

  // Parse Excel or CSV using SheetJS
  const processFile = async (file: File) => {
    setFileName(file.name);
    setIsParsing(true);
    setParseErrors([]);
    setSubmitError(null);
    setSubmitSuccess(null);

    try {
      const data = await file.arrayBuffer();
      const workbook = XLSX.read(data, { type: 'array' });
      
      const firstSheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[firstSheetName];
      
      // Convert sheet to json array of arrays
      const rawRows = XLSX.utils.sheet_to_json<any[]>(worksheet, { header: 1 });
      
      if (!rawRows || rawRows.length < 2) {
        setParseErrors(['The selected file is empty or does not contain data rows.']);
        setParsedStudents([]);
        setIsParsing(false);
        return;
      }

      // Detect header column indices
      const headers = rawRows[0].map((h: any) => String(h || '').toLowerCase().trim());
      
      let rollIdx = -1;
      let nameIdx = -1;
      let emailIdx = -1;

      headers.forEach((h: string, idx: number) => {
        if (h.includes('roll') || h.includes('reg') || h.includes('register') || h.includes('roll number')) {
          rollIdx = idx;
        } else if (h.includes('name') || h.includes('student name') || h.includes('candidate')) {
          nameIdx = idx;
        } else if (h.includes('email') || h.includes('mail')) {
          emailIdx = idx;
        }
      });

      // Fallback heuristics if standard headers not found
      if (rollIdx === -1) {
        if (headers.length >= 3 && headers[0].includes('s') && !headers[1].includes('name')) {
          rollIdx = 1;
        } else {
          rollIdx = 0;
        }
      }
      if (nameIdx === -1) {
        nameIdx = rollIdx === 0 ? 1 : 2;
      }

      const students: StudentRosterItemPayload[] = [];
      const errors: string[] = [];
      const seenRolls = new Set<string>();

      for (let r = 1; r < rawRows.length; r++) {
        const row = rawRows[r];
        if (!row || row.length === 0) continue;

        const rawRoll = row[rollIdx];
        const rawName = row[nameIdx];
        const rawEmail = emailIdx !== -1 ? row[emailIdx] : null;

        if (!rawRoll && !rawName) continue; // skip trailing empty rows

        if (!rawRoll) {
          errors.push(`Row ${r + 1}: Missing roll number.`);
          continue;
        }
        if (!rawName) {
          errors.push(`Row ${r + 1} (${rawRoll}): Missing student name.`);
          continue;
        }

        const rollNo = String(rawRoll).trim().toUpperCase();
        const name = String(rawName).trim();
        
        if (seenRolls.has(rollNo)) {
          errors.push(`Row ${r + 1}: Duplicate roll number '${rollNo}' detected in file. Only first occurrence will be processed.`);
          continue;
        }
        seenRolls.add(rollNo);

        // Auto-generate or sanitize official email
        let email = rawEmail ? String(rawEmail).trim().toLowerCase() : '';
        if (!email || !email.includes('@')) {
          email = `${rollNo.toLowerCase()}@psgtech.ac.in`;
        }

        students.push({
          rollNo,
          name,
          email,
          batch,
          departmentId: selectedDeptId,
          isEligible: true
        });
      }

      setParsedStudents(students);
      setParseErrors(errors);
    } catch (err: any) {
      console.error('Error parsing spreadsheet:', err);
      setParseErrors([`Failed to parse spreadsheet: ${err.message || 'Unknown error'}`]);
      setParsedStudents([]);
    } finally {
      setIsParsing(false);
    }
  };

  // Submit parsed students in bulk to ProjectVault API
  const handleSubmit = async () => {
    if (parsedStudents.length === 0) {
      setSubmitError('No valid student records found to ingest.');
      return;
    }

    setIsSubmitting(true);
    setSubmitError(null);
    setSubmitSuccess(null);

    const payload: StudentRosterBulkPayload = {
      students: parsedStudents.map(s => ({
        ...s,
        batch,
        departmentId: selectedDeptId
      })),
      defaultBatch: batch,
      defaultDepartmentId: selectedDeptId
    };

    try {
      const res = await api.post('/roster/bulk', payload);
      const resData = res.data?.data;
      const count = resData?.totalProcessed || parsedStudents.length;
      setSubmitSuccess(`Success! Ingested ${count} students into nominal roll whitelist.`);
      onSuccess(count);
      setTimeout(() => {
        onClose();
      }, 1400);
    } catch (err: any) {
      setSubmitError(getErrorMessage(err, 'Failed to ingest student roster'));
    } finally {
      setIsSubmitting(false);
    }
  };

  // Generate and download a sample excel template
  const handleDownloadTemplate = () => {
    const templateData = [
      ['S.No', 'Roll Number', 'Name', 'Email'],
      [1, '25MX101', 'BALAJI K', '25mx101@psgtech.ac.in'],
      [2, '25MX102', 'BALASUBRAMANIAM S', '25mx102@psgtech.ac.in'],
      [3, '25MX103', 'BARATHVIKRAMAN S K', '25mx103@psgtech.ac.in']
    ];

    const ws = XLSX.utils.aoa_to_sheet(templateData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Roster_Template');
    XLSX.writeFile(wb, 'psgtech_student_roster_template.xlsx');
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white w-full max-w-3xl rounded-2xl shadow-2xl border border-slate-200 overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Modal Header */}
        <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/70">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 text-white flex items-center justify-center shadow-md">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-slate-900">Ingest Student Nominal Roll</h3>
              <p className="text-xs text-slate-500">
                Upload student Excel list to update registration whitelist and dynamic email generation
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Content */}
        <div className="p-6 space-y-5 max-h-[75vh] overflow-y-auto">
          {/* Target Department and Batch Row */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5 flex items-center space-x-1.5">
                <Building2 className="w-3.5 h-3.5 text-indigo-600" />
                <span>Academic Department *</span>
              </label>
              <select
                value={selectedDeptId}
                onChange={(e) => setSelectedDeptId(Number(e.target.value))}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm font-medium text-slate-800 bg-white"
              >
                {departments.map((dept) => (
                  <option key={dept.id} value={dept.id}>
                    {dept.name} ({dept.code})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5 flex items-center space-x-1.5">
                <Layers className="w-3.5 h-3.5 text-indigo-600" />
                <span>Academic Batch *</span>
              </label>
              <input
                type="text"
                value={batch}
                onChange={(e) => setBatch(e.target.value)}
                placeholder="e.g. 2025-2027"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm font-medium text-slate-800"
              />
            </div>
          </div>

          {/* Drag & Drop Upload Zone */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5 flex items-center justify-between">
              <span>Select Excel (.xlsx, .xls) or CSV Document *</span>
              <button
                type="button"
                onClick={handleDownloadTemplate}
                className="text-xs text-indigo-600 hover:text-indigo-800 font-semibold flex items-center space-x-1 hover:underline"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Download Sample Template</span>
              </button>
            </label>
            <div
              onDrop={handleDrop}
              onDragOver={handleDragOver}
              onClick={() => fileInputRef.current?.click()}
              className="border-2 border-dashed border-indigo-200 hover:border-indigo-500 bg-indigo-50/30 hover:bg-indigo-50/60 rounded-2xl p-6 text-center cursor-pointer transition-all duration-150 flex flex-col items-center justify-center space-y-2.5"
            >
              <input
                ref={fileInputRef}
                type="file"
                accept=".xlsx, .xls, .csv"
                onChange={handleFileChange}
                className="hidden"
              />
              <div className="w-12 h-12 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center shadow-inner">
                <Upload className="w-6 h-6" />
              </div>
              <div className="space-y-0.5">
                <p className="text-sm font-semibold text-slate-800">
                  {fileName ? (
                    <span className="text-indigo-700 font-bold">{fileName}</span>
                  ) : (
                    'Click to browse or drag and drop Excel document'
                  )}
                </p>
                <p className="text-xs text-slate-500">
                  Supports Nominal Roll Excel sheets containing <code className="text-indigo-600 font-semibold">Roll Number</code> and <code className="text-indigo-600 font-semibold">Name</code>
                </p>
              </div>
            </div>
          </div>

          {/* Feedback & Parsing State */}
          {isParsing && (
            <div className="p-3 rounded-xl bg-slate-100 text-slate-600 text-sm flex items-center space-x-2">
              <div className="w-4 h-4 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin" />
              <span>Analyzing spreadsheet and extracting students...</span>
            </div>
          )}

          {parseErrors.length > 0 && (
            <div className="p-3.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-800 text-xs space-y-1">
              <div className="flex items-center space-x-1.5 font-bold">
                <AlertCircle className="w-4 h-4 text-amber-600" />
                <span>Notice regarding uploaded file:</span>
              </div>
              <ul className="list-disc pl-5 space-y-0.5">
                {parseErrors.slice(0, 3).map((err, idx) => (
                  <li key={idx}>{err}</li>
                ))}
                {parseErrors.length > 3 && (
                  <li>...and {parseErrors.length - 3} more warnings.</li>
                )}
              </ul>
            </div>
          )}

          {submitError && (
            <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm flex items-start space-x-2">
              <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
              <span>{submitError}</span>
            </div>
          )}

          {submitSuccess && (
            <div className="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm flex items-center space-x-2">
              <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
              <span>{submitSuccess}</span>
            </div>
          )}

          {/* Live Pre-Ingestion Data Preview Table */}
          {parsedStudents.length > 0 && (
            <div className="space-y-2 border border-slate-200 rounded-xl p-3.5 bg-slate-50/50">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                  <span className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    Extracted Roster Preview ({parsedStudents.length} Students)
                  </span>
                </div>
                <span className="text-xs text-indigo-700 font-semibold bg-indigo-50 px-2 py-0.5 rounded-md border border-indigo-100">
                  Batch {batch}
                </span>
              </div>

              <div className="overflow-x-auto max-h-48 border border-slate-200 rounded-lg bg-white">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-100 text-slate-600 uppercase font-semibold sticky top-0">
                    <tr>
                      <th className="px-3 py-2">#</th>
                      <th className="px-3 py-2">Roll Number</th>
                      <th className="px-3 py-2">Student Name</th>
                      <th className="px-3 py-2">Generated Institutional Email</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {parsedStudents.slice(0, 10).map((s, idx) => (
                      <tr key={idx} className="hover:bg-slate-50/80">
                        <td className="px-3 py-1.5 text-slate-400 font-mono">{idx + 1}</td>
                        <td className="px-3 py-1.5 font-bold font-mono text-slate-900">{s.rollNo}</td>
                        <td className="px-3 py-1.5 text-slate-800 font-medium">{s.name}</td>
                        <td className="px-3 py-1.5 text-indigo-600 font-mono">{s.email}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {parsedStudents.length > 10 && (
                <p className="text-[11px] text-slate-500 text-center italic">
                  Showing first 10 of {parsedStudents.length} students. All {parsedStudents.length} students will be ingested into the nominal roll.
                </p>
              )}
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-800 hover:bg-slate-100 rounded-xl transition-colors"
          >
            Cancel
          </button>
          
          <button
            type="button"
            disabled={parsedStudents.length === 0 || isSubmitting || isParsing}
            onClick={handleSubmit}
            className="px-6 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-bold shadow-lg shadow-indigo-600/20 disabled:opacity-50 disabled:pointer-events-none flex items-center space-x-2 transition-all duration-150"
          >
            {isSubmitting ? (
              <>
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                <span>Ingesting Roster...</span>
              </>
            ) : (
              <>
                <Check className="w-4 h-4" />
                <span>Confirm & Ingest {parsedStudents.length > 0 ? `${parsedStudents.length} Students` : 'Roster'}</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
