import React, { useState } from 'react';
import { generatePathFromPrompt } from '../services/geminiService';
import { VectorPath } from '../types';
import { Sparkles, Loader2, X } from 'lucide-react';

interface AIPanelProps {
  isOpen: boolean;
  onClose: () => void;
  onGenerated: (path: VectorPath) => void;
}

const AIPanel: React.FC<AIPanelProps> = ({ isOpen, onClose, onGenerated }) => {
  const [prompt, setPrompt] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleGenerate = async () => {
    if (!prompt.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const result = await generatePathFromPrompt(prompt);
      if (result && result.nodes) {
        // Hydrate partial result into full VectorPath
        const newPath: VectorPath = {
            id: `ai-${Date.now()}`,
            name: result.name || 'AI Path',
            nodes: result.nodes,
            closed: !!result.closed,
            fill: result.fill || '#3b82f6',
            stroke: result.stroke || '#1d4ed8',
            strokeWidth: 2,
            isVisible: true,
            isLocked: false
        };
        onGenerated(newPath);
        onClose();
        setPrompt('');
      } else {
          setError("Could not generate a valid path from this prompt. Try simpler shapes.");
      }
    } catch (err: any) {
      setError(err.message || "Failed to generate.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
      <div className="bg-[#2b2b2b] border border-[#3a3a3a] rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
        <div className="p-4 border-b border-[#3a3a3a] flex justify-between items-center bg-[#252525]">
            <div className="flex items-center space-x-2 text-purple-400">
                <Sparkles size={18} />
                <h2 className="font-semibold text-white">Generate with Gemini AI</h2>
            </div>
            <button onClick={onClose} className="text-[#888] hover:text-white">
                <X size={18} />
            </button>
        </div>
        
        <div className="p-6 space-y-4">
            <p className="text-sm text-[#ccc]">
                Describe a shape, icon, or symbol, and Gemini will create an editable vector path for you.
            </p>
            
            <textarea
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="e.g., A simple lightning bolt, a heart shape, a crescent moon..."
                className="w-full h-32 bg-[#1a1a1a] border border-[#3a3a3a] rounded-lg p-3 text-white focus:ring-2 focus:ring-purple-500 focus:outline-none resize-none placeholder-gray-600"
            />
            
            {error && (
                <div className="bg-red-900/20 border border-red-900 text-red-300 px-3 py-2 rounded text-xs">
                    {error}
                </div>
            )}
            
            <button
                onClick={handleGenerate}
                disabled={loading || !prompt.trim()}
                className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-medium py-2.5 rounded-lg flex items-center justify-center space-x-2 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
                {loading ? <Loader2 size={18} className="animate-spin" /> : <Sparkles size={18} />}
                <span>{loading ? 'Thinking...' : 'Generate Vector'}</span>
            </button>
            
             <p className="text-[10px] text-[#555] text-center">
                Powered by Gemini 3 Flash Preview
            </p>
        </div>
      </div>
    </div>
  );
};

export default AIPanel;
