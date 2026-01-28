import React from 'react';
import { VectorPath } from '../types';
import { Download, Sparkles } from 'lucide-react';

interface PropertyBarProps {
  selectedPath: VectorPath | null;
  onUpdatePath: (changes: Partial<VectorPath>) => void;
  onOpenAI: () => void;
  onExport: () => void;
}

const PropertyBar: React.FC<PropertyBarProps> = ({ selectedPath, onUpdatePath, onOpenAI, onExport }) => {
  return (
    <div className="h-12 bg-[#2b2b2b] border-b border-[#3a3a3a] flex items-center px-4 justify-between z-20">
      <div className="flex items-center space-x-4">
        <div className="flex items-center space-x-2">
           <span className="font-bold text-[#e0e0e0] tracking-wider text-sm mr-2">VectorGen</span>
           <span className="text-xs text-[#666] bg-[#1a1a1a] px-2 py-0.5 rounded border border-[#333]">BETA</span>
        </div>

        <div className="h-6 w-px bg-[#3a3a3a] mx-2" />

        {selectedPath ? (
          <>
            <div className="flex items-center space-x-2">
              <label className="text-xs text-[#a0a0a0]">Fill</label>
              <div className="relative group">
                 <input
                    type="color"
                    value={selectedPath.fill === 'none' ? '#ffffff' : selectedPath.fill}
                    onChange={(e) => onUpdatePath({ fill: e.target.value })}
                    className="w-6 h-6 p-0 border-0 rounded cursor-pointer bg-transparent"
                  />
                  {selectedPath.fill === 'none' && (
                     <div className="absolute inset-0 pointer-events-none flex items-center justify-center">
                        <div className="w-6 h-px bg-red-500 rotate-45 absolute" />
                     </div>
                  )}
              </div>
               <button 
                onClick={() => onUpdatePath({ fill: selectedPath.fill === 'none' ? '#cccccc' : 'none' })}
                className="text-xs px-2 py-1 bg-[#3a3a3a] rounded hover:bg-[#444]"
               >
                 {selectedPath.fill === 'none' ? 'Set' : 'None'}
               </button>
            </div>

            <div className="h-4 w-px bg-[#3a3a3a]" />

            <div className="flex items-center space-x-2">
              <label className="text-xs text-[#a0a0a0]">Stroke</label>
              <input
                type="color"
                value={selectedPath.stroke}
                onChange={(e) => onUpdatePath({ stroke: e.target.value })}
                className="w-6 h-6 p-0 border-0 rounded cursor-pointer bg-transparent"
              />
              <input
                type="number"
                min="0"
                max="100"
                value={selectedPath.strokeWidth}
                onChange={(e) => onUpdatePath({ strokeWidth: Number(e.target.value) })}
                className="w-12 bg-[#1a1a1a] border border-[#3a3a3a] rounded px-1 text-xs py-1 text-center"
              />
              <span className="text-xs text-[#666]">px</span>
            </div>
            
             <div className="h-4 w-px bg-[#3a3a3a]" />
             
             <div className="flex items-center space-x-2">
                <label className="flex items-center space-x-1 cursor-pointer select-none">
                    <input 
                        type="checkbox" 
                        checked={selectedPath.closed}
                        onChange={(e) => onUpdatePath({ closed: e.target.checked })}
                        className="form-checkbox h-3 w-3 text-blue-600 bg-[#1a1a1a] border-[#3a3a3a] rounded focus:ring-0" 
                    />
                    <span className="text-xs text-[#a0a0a0]">Close Path</span>
                </label>
             </div>
          </>
        ) : (
          <span className="text-xs text-[#555] italic">Select a path to edit properties</span>
        )}
      </div>

      <div className="flex items-center space-x-3">
        <button
          onClick={onOpenAI}
          className="flex items-center space-x-2 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white text-xs px-3 py-1.5 rounded-full transition-all shadow-lg shadow-purple-900/20"
        >
          <Sparkles size={14} />
          <span>Generate with Gemini</span>
        </button>

        <button
          onClick={onExport}
          className="flex items-center space-x-2 bg-[#3a3a3a] hover:bg-[#4a4a4a] text-white text-xs px-3 py-1.5 rounded transition-all"
        >
          <Download size={14} />
          <span>Export SVG</span>
        </button>
      </div>
    </div>
  );
};

export default PropertyBar;
