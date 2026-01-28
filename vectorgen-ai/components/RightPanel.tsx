import React, { useState } from 'react';
import { VectorPath } from '../types';
import { parseSVGString } from '../utils/vectorUtils';
import { Upload, Info } from 'lucide-react';

interface RightPanelProps {
  onImport: (paths: VectorPath[]) => void;
}

const RightPanel: React.FC<RightPanelProps> = ({ onImport }) => {
  const [svgInput, setSvgInput] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleImport = () => {
    if (!svgInput.trim()) return;
    try {
      const paths = parseSVGString(svgInput);
      if (paths.length === 0) {
        setError("No valid <path> elements found.");
        return;
      }
      onImport(paths);
      setSvgInput('');
      setError(null);
    } catch (e) {
      console.error(e);
      setError("Failed to parse SVG code.");
    }
  };

  return (
    <div className="w-64 bg-[#2b2b2b] border-l border-[#3a3a3a] flex flex-col z-20">
        <div className="p-3 border-b border-[#3a3a3a] font-semibold text-xs text-[#a0a0a0] flex items-center gap-2">
            <Upload size={14} />
            <span>IMPORT SVG</span>
        </div>
        
        <div className="p-4 flex flex-col gap-3">
             <label className="text-xs text-[#888]">Paste SVG Code</label>
             <textarea
                value={svgInput}
                onChange={(e) => setSvgInput(e.target.value)}
                placeholder='<svg> <path d="..." /> </svg>'
                className="w-full h-48 bg-[#1a1a1a] border border-[#3a3a3a] rounded p-2 text-xs text-[#e0e0e0] font-mono focus:outline-none focus:border-[#0078d4] resize-none"
             />
             
             {error && (
                <div className="text-red-400 text-[10px] bg-red-900/20 p-2 rounded border border-red-900/50">
                    {error}
                </div>
             )}

             <button
                onClick={handleImport}
                disabled={!svgInput.trim()}
                className="bg-[#0078d4] hover:bg-[#006cbd] text-white text-xs py-2 rounded transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium shadow-sm"
             >
                Import Vectors
             </button>
        </div>
        
        <div className="flex-1 p-4">
             <div className="bg-[#1a1a1a] p-3 rounded border border-[#3a3a3a] text-[#777] text-[10px] space-y-2">
                 <div className="flex items-start gap-2">
                     <Info size={12} className="mt-0.5 shrink-0" />
                     <p>Supports importing standard SVG paths. Complex shapes like circles or rects must be converted to paths first.</p>
                 </div>
                 <p className="pl-5 italic">
                    Supported commands: M, L, C, Z
                 </p>
             </div>
        </div>
    </div>
  );
};

export default RightPanel;